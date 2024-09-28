-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- to make tailwind works properly
require("lspconfig").tailwindcss.setup({})

-- Add LazyGit command on file save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*",
  callback = function()
    vim.notify("Don't forget to commit", vim.log.levels.ERROR)
  end,
})
