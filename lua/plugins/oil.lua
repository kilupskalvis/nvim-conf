return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  opts = {
    default_file_explorer = true,
    float = {
      padding = 2,
      max_width = 0.8,
      max_height = 0.8,
    },
    keymaps = {
      ["q"] = { callback = function() require("oil").close() end, desc = "Close oil" },
      ["<CR>"] = {
        callback = function()
          local oil = require("oil")
          local entry = oil.get_cursor_entry()
          if entry and entry.type == "file" then
            local dir = oil.get_current_dir()
            local filepath = vim.fn.fnamemodify(dir .. entry.name, ":p")
            oil.close()
            -- Switch to existing buffer if already open, otherwise edit
            local buf = vim.fn.bufnr(filepath)
            if buf ~= -1 then
              vim.api.nvim_set_current_buf(buf)
            else
              vim.cmd.edit(filepath)
            end
          else
            oil.select()
          end
        end,
        desc = "Open file or enter directory",
      },
    },
    view_options = {
      show_hidden = true,
    },
  },
  keys = {
    { "<leader>e", function() require("oil").open_float() end, desc = "File Explorer (oil)" },
  },
}
