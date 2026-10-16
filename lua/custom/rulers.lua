vim.pack.add { 'https://github.com/lukas-reineke/virt-column.nvim' }

require('virt-column').setup {
  char = '│',
  virtcolumn = '80,120',
  highlight = { 'Ruler80', 'Ruler120' },
  exclude = {
    filetypes = { 'neo-tree', 'NeogitStatus' },
  },
}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-commit-ruler', { clear = true }),
  pattern = { 'gitcommit', 'NeogitCommitMessage' },
  callback = function(event)
    require('virt-column').setup_buffer(event.buf, {
      virtcolumn = '72',
      highlight = 'Ruler120',
    })
  end,
})
