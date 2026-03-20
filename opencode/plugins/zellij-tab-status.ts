/**
 * Zellij Tab Status Plugin
 *
 * Signals agent activity in the Zellij tab bar by renaming the tab:
 *   ⚙ <name>  — agent is working            (U+2699)
 *   ⚡ <name>  — agent needs user attention   (U+26A1)
 *   ⌁ <name>  — agent finished               (U+2301)
 *   <name>    — idle / user is present        (restored when user starts typing)
 *
 * Only active in `work` sessions where ZELLIJ_TAB_NAME is set.
 *
 * Uses `zellij pipe` to send rename requests to the tab-titler WASM
 * plugin, which can rename any tab by pane ID without stealing focus.
 * This replaces the old `zellij action rename-tab` approach, which
 * always targeted the focused tab.
 */

import type { Plugin } from "@opencode-ai/plugin"

type TabState = "idle" | "busy" | "attention" | "done"

const PLUGIN_PATH = "file:~/.config/zellij/plugins/tab-titler.wasm"

export const ZellijTabStatus: Plugin = async ({ $ }) => {
  const baseName = process.env.ZELLIJ_TAB_NAME
  if (!process.env.ZELLIJ || !baseName) return {}

  let state: TabState = "idle"
  let pending: Promise<void> | null = null

  const setTab = async (next: TabState) => {
    if (pending) await pending
    if (next === state) return

    const label =
      next === "busy"      ? `⚙ ${baseName}` :
      next === "attention" ? `⚡ ${baseName}` :
      next === "done"      ? `⌁ ${baseName}` :
                             baseName

    const work = (async () => {
      try {
        const payload = `${baseName}\t${label}`
        await $`zellij pipe --plugin ${PLUGIN_PATH} --name set_tab_title -- ${payload}`
        state = next
      } catch {
        // zellij or plugin unavailable — leave state unchanged
      }
    })()
    pending = work
    await work
    if (pending === work) pending = null
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.status") {
        await setTab("busy")
      }

      if (event.type === "permission.asked") {
        await setTab("attention")
      }

      if (event.type === "session.idle" && state !== "attention") {
        await setTab("done")
      }

      if (event.type === "tui.prompt.append" && state !== "idle") {
        await setTab("idle")
      }
    },

    "tool.execute.before": async (input, _output) => {
      if (input.tool === "question") {
        await setTab("attention")
      }
    },
  }
}
