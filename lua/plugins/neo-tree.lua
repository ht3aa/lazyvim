return {

  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({
          toggle = true,
          source = "filesystem",
          position = "right",
        })
      end,
      desc = "Explorer NeoTree (Root Dir)",
      remap = true,
    },
  },
}
