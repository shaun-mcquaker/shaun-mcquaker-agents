return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  config = function()
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
        close_command = function(bufnr)
          close_buffer(bufnr)
        end,
        left_mouse_command = function(bufnr)
          local now = vim.loop.now()
          if last_click_buf == bufnr and (now - last_click_time) < double_click_threshold then
            close_buffer(bufnr)
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
