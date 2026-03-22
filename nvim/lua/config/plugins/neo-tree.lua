return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = false, -- load on startup
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file tree" },
    { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in tree" },
  },
  opts = {
    open_on_setup = false, -- we handle this via init below
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,        -- show dotfiles (dimmed)
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    window = {
      width = 35,
      mappings = {
        ["<space>"] = "none", -- don't conflict with leader
        ["<2-LeftMouse>"] = function(state)
          local node = state.tree:get_node()
          if node.type == "directory" then
            local fs = require("neo-tree.sources.filesystem")
            fs.toggle_directory(state, node)
          else
            require("neo-tree.sources.filesystem.commands").open(state)
          end
        end,
      },
    },
  },
  init = function()
    local function refresh_neo_tree_git()
      local ok, manager = pcall(require, "neo-tree.sources.manager")
      if not ok then
        return
      end

      manager.refresh("filesystem")
      manager.refresh("git_status")
    end

    -- Open neo-tree on startup
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.cmd("Neotree show")
      end,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
      pattern = "neo-tree *",
      callback = function()
        vim.cmd.stopinsert()
      end,
    })

    vim.api.nvim_create_autocmd({ "FocusGained", "ShellCmdPost", "VimResume" }, {
      callback = refresh_neo_tree_git,
    })
  end,
}
