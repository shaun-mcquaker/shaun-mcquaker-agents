local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Whitespace visualization
opt.list = true
opt.listchars = { multispace = "·", tab = "→ ", trail = "·", nbsp = "␣" }

-- Display
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = true
opt.linebreak = true
opt.breakindent = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Undo / backup
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- Navigation
opt.whichwrap:append("<>[]")

-- Misc
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.updatetime = 250
opt.timeoutlen = 300

-- Jinja template files: use jinja filetype so treesitter highlights the
-- Jinja blocks and no JS/SQL LSP attaches to spam diagnostics.
-- Host-language highlighting (JS/SQL) is absent — no injection grammar exists yet.
vim.filetype.add({
  pattern = {
    [".*%.jinja%.js"] = "jinja",
    [".*%.jinja%.sql"] = "jinja",
  },
})

-- Trim trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[%s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, pos)
  end,
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lines = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lines then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})
