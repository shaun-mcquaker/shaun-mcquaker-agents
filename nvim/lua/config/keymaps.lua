-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Buffers
map("n", "<leader>x", function()
  if vim.bo.buftype ~= "" then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local bufs = vim.tbl_filter(function(b)
    return vim.bo[b].buflisted and b ~= buf
  end, vim.api.nvim_list_bufs())
  if #bufs > 0 then
    vim.cmd("bp")
  else
    vim.cmd("enew")
  end
  vim.api.nvim_buf_delete(buf, { force = false })
end, { desc = "Close buffer" })

map("n", "<leader>w", function()
  if vim.bo.buftype ~= "" then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].modified then
    vim.cmd("write")
  end
  local bufs = vim.tbl_filter(function(b)
    return vim.bo[b].buflisted and b ~= buf
  end, vim.api.nvim_list_bufs())
  if #bufs > 0 then
    vim.cmd("bp")
  else
    vim.cmd("enew")
  end
  vim.api.nvim_buf_delete(buf, { force = false })
end, { desc = "Save and close buffer" })

-- Quit
map("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit all" })

-- Better indenting (stay in visual mode)
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Horizontal mouse scroll
map({"n", "i", "v"}, "<ScrollWheelLeft>",  "4zh", { desc = "Scroll left" })
map({"n", "i", "v"}, "<ScrollWheelRight>", "4zl", { desc = "Scroll right" })
