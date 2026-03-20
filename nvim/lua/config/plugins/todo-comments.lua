return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = false,
  opts = {},
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO comment" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO comment" },
    { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
  },
}
