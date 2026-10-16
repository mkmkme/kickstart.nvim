vim.pack.add { 'https://github.com/NeogitOrg/neogit' }

require('neogit').setup {
  highlight = {
    red = '#fb4934',
  },
}

vim.keymap.set('n', '<leader>gg', '<cmd>Neogit<CR>', { desc = 'Open Neogit' })
