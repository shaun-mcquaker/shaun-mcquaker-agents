return {
  "nvim-telescope/telescope.nvim",
  branch = "master",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    { "nvim-telescope/telescope-frecency.nvim", dependencies = { "kkharji/sqlite.lua" } },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("fzf")
    telescope.load_extension("frecency")
  end,
  opts = {
    defaults = {
      file_ignore_patterns = {},
    },
    pickers = {
      find_files = {
        hidden = true,
      },
    },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope frecency workspace=CWD<cr>", desc = "Find files (frecency)" },
    { "<leader>fF", "<cmd>Telescope find_files<cr>", desc = "Find files (all)" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>fc", "<cmd>Telescope colorscheme enable_preview=true<cr>", desc = "Colorschemes" },
  },
}
