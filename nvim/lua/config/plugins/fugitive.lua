return {
  "tpope/vim-fugitive",
  cmd = { "Git", "Gvdiffsplit", "Gread", "Gwrite" },
  keys = {
    { "<leader>gg", "<cmd>Git<cr>", desc = "Git status" },
    { "<leader>gl", "<cmd>Git log --oneline<cr>", desc = "Git log" },
  },
}
