return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  config = function()
    -- Track double-click state for closing buffers
    local last_click_time = 0
    local last_click_buf = nil
    local double_click_threshold = 300 -- milliseconds

    require("bufferline").setup({
      options = {
        offsets = {
          { filetype = "neo-tree", text = "File Explorer", separator = true },
        },
        diagnostics = "nvim_lsp",
        show_close_icon = false,
        show_buffer_close_icons = false,
        separator_style = "thin",
        close_command = "bdelete! %d",
        left_mouse_command = function(bufnr)
          local now = vim.loop.now()
          if last_click_buf == bufnr and (now - last_click_time) < double_click_threshold then
            -- Double-click: close the buffer
            vim.cmd("bdelete! " .. bufnr)
            last_click_time = 0
            last_click_buf = nil
          else
            -- Single click: switch to the buffer
            vim.api.nvim_set_current_buf(bufnr)
            last_click_time = now
            last_click_buf = bufnr
          end
        end,
      },
    })
  end,
}
