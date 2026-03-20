/**
 * Shopify Proxy Plugin for OpenCode
 *
 * Features:
 * - Automatic token refresh
 * - Dynamic model discovery from proxy API
 * - Config management tools
 */

import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"
import { z } from "zod"
import fs from "fs/promises"
import path from "path"
import os from "os"

const TOKEN_HELPER = "/opt/dev/bin/user/devx"
const PROXY_API_BASE = "https://proxy.shopify.ai"
const CONFIG_PATH = path.join(os.homedir(), ".config/opencode/opencode.jsonc")
const REFRESH_INTERVAL = 5 * 60 * 1000 // 5 minutes
const EXPIRY_BUFFER = 5 * 60 // 5 minutes

let tokenRefreshInterval: Timer | null = null

interface ShopifyToken {
  id: string
  mode: string
  email: string
  expiry: number
}

interface ProxyModel {
  id: string
  alias?: string
  owned_by: string
  type: "virtual_model" | "provider_model"
  config: {
    strategy: {
      mode: string
      type?: string
      on_status_codes?: number[]
    }
    targets: Array<{
      model: string
      vendor: string
      endpoint?: string
      model_info: {
        context_window: number
        max_output_tokens: number
        stats?: {
          cost?: {
            input_cost_per_token: number
            output_cost_per_token: number
          }
          response_time_ms?: {
            avg: number
            p75: number
          }
        }
      }
    }>
  }
}

interface Provider {
  id: string
  name: string
  vendor: string
  models: string[]
}

interface ModelConfig {
  name: string
  limit: { context: number; output: number }
  cost: { input: number; output: number; cache_read?: number; cache_write?: number }
  headers?: Record<string, string>
}

interface ProviderConfig {
  npm: string
  name: string
  options: {
    apiKey: string
    baseURL: string
    headers: Record<string, string>
  }
  models: Record<string, ModelConfig>
}

// ============================================================================
// Token Management
// ============================================================================

async function fetchToken($: any): Promise<string> {
  try {
    const result = await $`${TOKEN_HELPER} llm-gateway print-token --key`.text()
    return result.trim()
  } catch (error) {
    console.error("Failed to fetch Shopify proxy token:", error)
    throw error
  }
}

function parseToken(token: string): ShopifyToken | null {
  try {
    const jsonPart = token.replace(/^shopify-/, "").split("-")[0]
    const decoded = atob(jsonPart)
    return JSON.parse(decoded)
  } catch {
    return null
  }
}

function shouldRefreshToken(token: string): boolean {
  const parsed = parseToken(token)
  if (!parsed) return true
  const now = Math.floor(Date.now() / 1000)
  return parsed.expiry - now < EXPIRY_BUFFER
}

async function refreshTokenIfNeeded($: any): Promise<void> {
  const currentToken = process.env.OPENAI_API_KEY
  if (!currentToken || shouldRefreshToken(currentToken)) {
    const newToken = await fetchToken($)
    process.env.OPENAI_API_KEY = newToken
    const parsed = parseToken(newToken)
    if (parsed) {
      const expiryDate = new Date(parsed.expiry * 1000)
      console.log(`[Shopify Proxy] Token refreshed, expires at ${expiryDate.toLocaleTimeString()}`)
    }
  }
}

// ============================================================================
// Proxy API Interaction
// ============================================================================

async function fetchModelsFromProxy(): Promise<ProxyModel[]> {
  const token = process.env.OPENAI_API_KEY
  if (!token) throw new Error("OPENAI_API_KEY not set")

  const response = await fetch(`${PROXY_API_BASE}/v1/models`, {
    headers: { "X-Api-Key": token }
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch models: ${response.statusText}`)
  }

  const data = await response.json() as { data: ProxyModel[] }
  return data.data
}

async function fetchProvidersFromProxy(): Promise<Provider[]> {
  const token = process.env.OPENAI_API_KEY
  if (!token) throw new Error("OPENAI_API_KEY not set")

  const response = await fetch(`${PROXY_API_BASE}/v1/providers`, {
    headers: { "X-Api-Key": token }
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch providers: ${response.statusText}`)
  }

  const data = await response.json() as { data: Provider[] }
  return data.data
}

function parseModelId(modelId: string): { vendor: string; model: string } | null {
  // Handle different formats:
  // - "anthropic/claude-opus-4-5"
  // - "openai/gpt-5.1-codex"
  // - "googlevertexai-global:gemini-3-pro"

  if (modelId.includes("/")) {
    const [vendor, model] = modelId.split("/")
    return { vendor, model }
  }

  if (modelId.includes(":")) {
    const [vendor, model] = modelId.split(":")
    return { vendor, model }
  }

  return null
}

function extractModelSpecs(model: ProxyModel): ModelConfig | null {
  const target = model.config.targets[0]
  if (!target) return null

  const { model_info } = target
  const stats = model_info.stats

  const cost = stats?.cost ? {
    input: stats.cost.input_cost_per_token * 1_000_000,
    output: stats.cost.output_cost_per_token * 1_000_000
  } : { input: 1.0, output: 5.0 }

  const lower = model.id.toLowerCase()
  const is1M = lower.includes("1m") || lower.includes("1000000")

  return {
    name: model.id,
    limit: {
      context: model_info.context_window,
      output: model_info.max_output_tokens
    },
    cost,
    headers: is1M && lower.includes("claude")
      ? { "anthropic-beta": "context-1m-2025-08-07" }
      : undefined
  }
}

function convertModelsToConfig(models: ProxyModel[]): Record<string, ProviderConfig> {
  const providers: Record<string, ProviderConfig> = {}

  for (const model of models) {
    const parsed = parseModelId(model.id)
    if (!parsed) continue

    const { vendor, model: modelName } = parsed
    const providerKey = `shopify-${vendor}`

    // Initialize provider if not exists
    if (!providers[providerKey]) {
      const npmPackage = vendor === "anthropic" ? "@ai-sdk/anthropic"
        : vendor === "openai" ? "@ai-sdk/openai"
        : "@ai-sdk/openai-compatible"

      const baseURL = vendor === "googlevertexai-global" || vendor.includes("google")
        ? `${PROXY_API_BASE}/v1/`
        : `${PROXY_API_BASE}/vendors/${vendor}/v1`

      providers[providerKey] = {
        npm: npmPackage,
        name: "Shopify",
        options: {
          apiKey: "shopify",
          baseURL,
          headers: { "Authorization": "Bearer {env:OPENAI_API_KEY}" }
        },
        models: {}
      }
    }

    const specs = extractModelSpecs(model)
    if (specs) {
      providers[providerKey].models[modelName] = specs
    }
  }

  return providers
}

// ============================================================================
// Config File Management
// ============================================================================

async function readConfig(): Promise<any> {
  try {
    const content = await fs.readFile(CONFIG_PATH, "utf-8")
    // Strip comments and parse JSONC
    const stripped = content.replace(/\/\/.*$/gm, "").replace(/\/\*[\s\S]*?\*\//g, "")
    return JSON.parse(stripped)
  } catch (error) {
    throw new Error(`Failed to read config: ${error}`)
  }
}

async function writeConfig(config: any): Promise<void> {
  const formatted = JSON.stringify(config, null, 2)
  await fs.writeFile(CONFIG_PATH, formatted, "utf-8")
}

// ============================================================================
// Plugin Definition
// ============================================================================

export const ShopifyProxyPlugin: Plugin = async ({ $, client }) => {
  // Initial token refresh
  await refreshTokenIfNeeded($)

  // Set up periodic refresh
  tokenRefreshInterval = setInterval(async () => {
    await refreshTokenIfNeeded($)
  }, REFRESH_INTERVAL)

  return {
    // Token refresh hooks
    "tool.execute.before": async () => {
      await refreshTokenIfNeeded($)
    },

    "session.created": async () => {
      await refreshTokenIfNeeded($)
    },

    "session.deleted": async () => {
      if (tokenRefreshInterval) {
        clearInterval(tokenRefreshInterval)
        tokenRefreshInterval = null
      }
    },

    // Custom tools for model management
    tool: {
      list_shopify_models: tool({
        description: "List all models available from the Shopify LLM proxy. Shows model IDs, providers, and basic information.",
        args: {
          provider: z.string().optional().describe("Filter by provider (e.g., 'anthropic', 'openai', 'google')")
        },
        async execute({ provider }) {
          try {
            const models = await fetchModelsFromProxy()

            let filtered = models
            if (provider) {
              const lowerProvider = provider.toLowerCase()
              filtered = models.filter(m => m.id.toLowerCase().includes(lowerProvider))
            }

            const grouped: Record<string, string[]> = {}
            for (const model of filtered) {
              const parsed = parseModelId(model.id)
              const vendor = parsed?.vendor || "unknown"
              if (!grouped[vendor]) grouped[vendor] = []
              grouped[vendor].push(model.id)
            }

            let output = `Found ${filtered.length} models from Shopify proxy:\n\n`
            for (const [vendor, modelIds] of Object.entries(grouped)) {
              output += `\n## ${vendor.toUpperCase()}\n`
              for (const id of modelIds) {
                output += `  - ${id}\n`
              }
            }

            output += `\n\nUse show_shopify_model to see details for a specific model.`
            return output
          } catch (error) {
            return `Error fetching models: ${error}`
          }
        }
      }),

      show_shopify_model: tool({
        description: "Show detailed specifications for a specific model from the Shopify proxy, including context limits, output limits, pricing, and performance stats.",
        args: {
          modelId: z.string().describe("The model ID (e.g., 'anthropic/claude-sonnet-4-5')")
        },
        async execute({ modelId }) {
          try {
            const models = await fetchModelsFromProxy()
            const model = models.find(m => m.id === modelId)

            if (!model) {
              return `Model '${modelId}' not found. Use list_shopify_models to see available models.`
            }

            const specs = extractModelSpecs(model)
            if (!specs) {
              return `Could not determine specs for ${model.id}`
            }

            const target = model.config.targets[0]
            const stats = target?.model_info.stats

            let output = `# ${model.id}\n\n` +
              `**Type:** ${model.type}\n` +
              `**Owner:** ${model.owned_by}\n` +
              (model.alias ? `**Alias:** ${model.alias}\n` : "") +
              `\n## Limits\n` +
              `- Context: ${specs.limit.context.toLocaleString()} tokens\n` +
              `- Output: ${specs.limit.output.toLocaleString()} tokens\n\n` +
              `## Pricing (per 1M tokens)\n` +
              `- Input: $${specs.cost.input.toFixed(2)}\n` +
              `- Output: $${specs.cost.output.toFixed(2)}\n`

            if (specs.cost.cache_read) {
              output += `- Cache Read: $${specs.cost.cache_read.toFixed(2)}\n`
            }
            if (specs.cost.cache_write) {
              output += `- Cache Write: $${specs.cost.cache_write.toFixed(2)}\n`
            }

            if (stats?.response_time_ms) {
              output += `\n## Performance\n` +
                `- Avg Response Time: ${stats.response_time_ms.avg.toFixed(0)}ms\n` +
                `- P75 Response Time: ${stats.response_time_ms.p75.toFixed(0)}ms\n`
            }

            if (target) {
              output += `\n## Target\n` +
                `- Vendor: ${target.vendor}\n` +
                `- Model: ${target.model}\n`
              if (target.endpoint) {
                output += `- Endpoint: ${target.endpoint}\n`
              }
            }

            output += `\n## Strategy\n` +
              `- Mode: ${model.config.strategy.mode}\n`
            if (model.config.strategy.type) {
              output += `- Type: ${model.config.strategy.type}\n`
            }

            return output
          } catch (error) {
            return `Error fetching model details: ${error}`
          }
        }
      }),

      list_shopify_providers: tool({
        description: "List all providers available from the Shopify LLM proxy. Shows provider IDs, names, vendors, and model counts.",
        args: {},
        async execute() {
          try {
            const providers = await fetchProvidersFromProxy()

            let output = `Found ${providers.length} providers from Shopify proxy:\n\n`

            for (const provider of providers) {
              output += `## ${provider.name} (${provider.vendor})\n`
              output += `- ID: ${provider.id}\n`
              output += `- Models: ${provider.models.length}\n\n`
            }

            output += `Use show_shopify_provider to see details for a specific provider.`
            return output
          } catch (error) {
            return `Error fetching providers: ${error}`
          }
        }
      }),

      show_shopify_provider: tool({
        description: "Show detailed information for a specific provider from the Shopify proxy, including all available models.",
        args: {
          providerId: z.string().describe("The provider ID (e.g., 'anthropic', 'openai')")
        },
        async execute({ providerId }) {
          try {
            const providers = await fetchProvidersFromProxy()
            const provider = providers.find(p => p.id === providerId || p.vendor === providerId)

            if (!provider) {
              return `Provider '${providerId}' not found. Use list_shopify_providers to see available providers.`
            }

            let output = `# ${provider.name}\n\n`
            output += `**ID:** ${provider.id}\n`
            output += `**Vendor:** ${provider.vendor}\n`
            output += `**Total Models:** ${provider.models.length}\n\n`
            output += `## Available Models\n`

            for (const modelId of provider.models) {
              output += `- ${modelId}\n`
            }

            output += `\nUse show_shopify_model to see detailed specs for any model.`
            return output
          } catch (error) {
            return `Error fetching provider details: ${error}`
          }
        }
      }),

      sync_shopify_models: tool({
        description: "Fetch the latest models from Shopify proxy and update the OpenCode configuration file. This will overwrite the provider section in your config.",
        args: {},
        async execute() {
          try {
            // Fetch models from proxy
            const models = await fetchModelsFromProxy()
            const newProviders = convertModelsToConfig(models)

            // Read existing config
            const config = await readConfig()

            // Backup provider config
            const oldProviderCount = Object.keys(config.provider || {}).length

            // Update providers
            config.provider = newProviders

            // Write back
            await writeConfig(config)

            const newProviderCount = Object.keys(newProviders).length
            const modelCount = Object.values(newProviders).reduce(
              (sum, p) => sum + Object.keys(p.models).length, 0
            )

            return `✅ Successfully synced models from Shopify proxy!\n\n` +
              `**Updated:** ${CONFIG_PATH}\n` +
              `**Providers:** ${oldProviderCount} → ${newProviderCount}\n` +
              `**Models:** ${modelCount} total\n\n` +
              `**To apply changes:**\n` +
              `1. Exit OpenCode (Ctrl+C or type 'exit')\n` +
              `2. Restart: \`opencode\`\n\n` +
              `Use list_shopify_models to see what's now available.`
          } catch (error) {
            return `❌ Error syncing models: ${error}\n\n` +
              `Make sure ${CONFIG_PATH} exists and is writable.`
          }
        }
      })
    }
  }
}

export default ShopifyProxyPlugin
