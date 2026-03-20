return {
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      -- Register Jinja filetypes
      vim.filetype.add({
        extension = {
          jinja = "jinja",
          jinja2 = "jinja",
          j2 = "jinja",
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",        -- Python
          "ts_ls",          -- TypeScript / JavaScript
          "ruby_lsp",       -- Ruby / Rails
          "jsonls",         -- JSON
          "marksman",       -- Markdown
          -- sqruff & jinja_lsp installed externally, not managed by Mason
          "yamlls",         -- YAML
        },
        automatic_installation = true,
      })

      -- Build capabilities (merge nvim-cmp if available)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
      end

      -- Servers with native nvim-lspconfig support
      local servers = {
        pyright = {},
        ts_ls = {},
        ruby_lsp = {},
        jsonls = {},
        marksman = {},
        jinja_lsp = {},
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
              },
            },
          },
        },
      }

      for name, opts in pairs(servers) do
        vim.lsp.config(name, vim.tbl_deep_extend("force", { capabilities = capabilities }, opts))
      end
      vim.lsp.enable(vim.tbl_keys(servers))

      -- sqruff: not in lspconfig's registry, configure manually
      vim.lsp.config("sqruff", {
        cmd = { "sqruff", "lsp" },
        filetypes = { "sql" },
        root_markers = { ".sqruff", ".git" },
        capabilities = capabilities,
      })
      vim.lsp.enable("sqruff")

      -- Suppress diagnostics and detach sqruff in dbt files (Jinja confuses the parser)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local path = vim.api.nvim_buf_get_name(args.buf)
          if path:match("/dbt/") then
            vim.diagnostic.enable(false, { bufnr = args.buf })
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.name == "sqruff" then
              vim.schedule(function()
                vim.lsp.buf_detach_client(args.buf, args.data.client_id)
              end)
            end
          end
        end,
      })

      -- Keymaps (set when an LSP attaches to a buffer)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "References")
          map("gI", vim.lsp.buf.implementation, "Go to implementation")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
        end,
      })
    end,
  },
}
