return {
  { "folke/flash.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
  { "folke/tokyonight.nvim", enabled = false },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>e", function() Snacks.explorer({ cwd = LazyVim.root() }) end, desc = "File Explorer (root)" },
      { "<leader>E", function() Snacks.explorer() end, desc = "File Explorer (cwd)" },
      -- Disable snacks_picker's <leader>gd so diffview can handle it
      { "<leader>gd", false },
      -- Also disable <leader>gf since diffview maps it to DiffviewFileHistory
      { "<leader>gf", false },
    },
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
        },
      },
      scroll = { enabled = true },
      explorer = {
        hidden = true,
        ignored = true,
      },
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = true,
          },
          grep = {
            hidden = true,
            ignored = true,
          },
          explorer = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
