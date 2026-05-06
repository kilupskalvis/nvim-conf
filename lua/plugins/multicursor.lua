return {
  "jake-stewart/multicursor.nvim",
  keys = {
    {
      "<C-d>",
      function() require("multicursor-nvim").matchAddCursor(1) end,
      mode = { "n", "v" },
      desc = "Add cursor on next match",
    },
    {
      "<C-S-d>",
      function() require("multicursor-nvim").matchAddCursor(-1) end,
      mode = { "n", "v" },
      desc = "Add cursor on prev match",
    },
    {
      "<C-S-l>",
      function() require("multicursor-nvim").matchAllAddCursors() end,
      mode = { "n", "v" },
      desc = "Add cursors on all matches",
    },
    {
      "<Esc>",
      function()
        local mc = require("multicursor-nvim")
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        elseif mc.hasCursors() then
          mc.clearCursors()
        else
          vim.cmd("nohlsearch")
        end
      end,
      desc = "Clear cursors / nohl",
    },
  },
  config = function()
    require("multicursor-nvim").setup()
  end,
}
