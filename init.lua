-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("hasanweb_todo")

-- to make tailwind works properly
require("lspconfig").tailwindcss.setup({})
