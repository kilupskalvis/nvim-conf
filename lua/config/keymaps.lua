-- Window navigation with arrow keys
vim.keymap.set("n", "<leader>w<Left>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<leader>w<Down>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<leader>w<Up>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<leader>w<Right>", "<C-w>l", { desc = "Go to right window" })

-- Window resizing (Option+Shift+Arrow)
vim.keymap.set("n", "<A-S-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
vim.keymap.set("n", "<A-S-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
vim.keymap.set("n", "<A-S-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
vim.keymap.set("n", "<A-S-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Disable hjkl
vim.keymap.set("n", "h", "<Nop>")
vim.keymap.set("n", "j", "<Nop>")
vim.keymap.set("n", "k", "<Nop>")
vim.keymap.set("n", "l", "<Nop>")

-- Buffer navigation
vim.keymap.set("n", "<leader><Left>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader><Right>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Make Ctrl+Z undo
vim.keymap.set("n", "<C-z>", "u", { noremap = true })

-- Make Ctrl+Y redo
vim.keymap.set("n", "<C-y>", "<C-r>", { noremap = true })

vim.api.nvim_create_user_command("Dashboard", function()
  require("snacks.dashboard").open()
end, {})

-- Claude Code
vim.keymap.set("n", "<leader>cc", "<cmd>split | terminal claude<cr>", { desc = "Claude Code" })

-- Exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
