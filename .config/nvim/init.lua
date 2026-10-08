vim.opt.termguicolors = true
vim.opt.number = true

vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')

require('lazy').setup({
  {
    'RRethy/base16-nvim',
    config = function()
      require('matugen').setup()
    end,
  },
})
