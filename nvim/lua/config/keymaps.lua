-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

local function open_current_file_in_chrome()
  if vim.bo.buftype ~= "" then
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return
  end

  if vim.bo.modified then
    vim.cmd("write")
  end

  vim.fn.jobstart({ "open", "-a", "Google Chrome", path }, { detach = true })
end

vim.api.nvim_create_user_command("OpenInChrome", open_current_file_in_chrome, {})
vim.cmd([[amenu PopUp.Open\ in\ Chrome :OpenInChrome<CR>]])

local function copy_visual_selection_to_clipboard()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" then
    return
  end

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3] - 1

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  if mode == "V" then
    local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
    vim.fn.setreg("+", lines, "V")
    return
  end

  local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col + 1, {})
  vim.fn.setreg("+", table.concat(lines, "\n"), "v")
end

local function close_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end

  local current = vim.api.nvim_get_current_buf()
  if current == buf then
    local bufs = vim.tbl_filter(function(b)
      return vim.bo[b].buflisted and b ~= buf
    end, vim.api.nvim_list_bufs())

    if #bufs > 0 then
      vim.cmd("bp")
    else
      vim.cmd("enew")
    end
  end

  vim.api.nvim_buf_delete(buf, { force = false })
end

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
  close_buffer()
end, { desc = "Close buffer" })

map("n", "<leader>mp", open_current_file_in_chrome, { desc = "Open file in Chrome" })

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

vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved" }, {
  callback = function()
    vim.schedule(copy_visual_selection_to_clipboard)
  end,
})

-- Horizontal mouse scroll
map({"n", "i", "v"}, "<ScrollWheelLeft>",  "4zh", { desc = "Scroll left" })
map({"n", "i", "v"}, "<ScrollWheelRight>", "4zl", { desc = "Scroll right" })
