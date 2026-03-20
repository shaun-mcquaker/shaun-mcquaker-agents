return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  lazy = false,
  config = function()
    local highlights = {
      { name = "IndentRed", fg = "#66303f" },
      { name = "IndentYellow", fg = "#665735" },
      { name = "IndentBlue", fg = "#355466" },
      { name = "IndentOrange", fg = "#664335" },
      { name = "IndentGreen", fg = "#3d6635" },
      { name = "IndentViolet", fg = "#4e3d66" },
      { name = "IndentCyan", fg = "#356666" },
    }

    for _, hl in ipairs(highlights) do
      vim.api.nvim_set_hl(0, hl.name, { fg = hl.fg })
    end

    require("ibl").setup({
      indent = {
        char = "│",
        highlight = vim.tbl_map(function(hl) return hl.name end, highlights),
      },
      scope = {
        enabled = true,
        show_start = false,
        show_end = false,
      },
    })
  end,
}
