return {
  {
    "garymjr/nvim-snippets",
    enabled = false,
  },
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.mapping = opts.mapping or {}
      opts.mapping["<CR>"] = LazyVim.cmp.confirm({
        select = true,
        behavior = cmp.ConfirmBehavior.Replace,
      })
      opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          LazyVim.cmp.confirm({
            select = true,
            behavior = cmp.ConfirmBehavior.Replace,
          })(fallback)
        elseif vim.snippet.active({ direction = 1 }) then
          vim.snippet.jump(1)
        else
          fallback()
        end
      end, { "i", "s" })
    end,
  },
}
