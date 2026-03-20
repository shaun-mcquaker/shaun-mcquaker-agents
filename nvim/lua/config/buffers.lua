local M = {}

function M.close_buffer(buf)
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

return M
