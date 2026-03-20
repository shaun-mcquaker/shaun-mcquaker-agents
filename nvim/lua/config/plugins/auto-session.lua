return {
  "rmagatti/auto-session",
  lazy = false,
  opts = {
    -- Store sessions per working directory
    auto_save = true,
    auto_restore = true,
    -- Avoid restoring sessions when nvim is opened with file arguments
    -- (e.g. `nvim foo.lua` should just open that file, not the full session)
    args_allow_single_directory = true,
    args_allow_files_auto_save = false,
    -- Keep neo-tree and other sidebars from causing restore weirdness
    pre_save_cmds = { "Neotree close" },
  },
}
