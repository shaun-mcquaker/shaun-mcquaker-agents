-- Order matters: set leader before lazy loads keymaps
require("config.keymaps")
require("config.options")

-- Load plugins via lazy.nvim
require("lazy").setup("config.plugins")
