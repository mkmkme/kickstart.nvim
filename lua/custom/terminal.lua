local M = {}
local terminal_buf

function M.toggle()
  local windows = vim.api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(windows) do
    if vim.api.nvim_win_get_buf(win) == terminal_buf then
      if #windows == 1 then
        vim.cmd 'enew'
      else
        vim.api.nvim_win_hide(win)
      end
      return
    end
  end

  local height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight - 1) * 0.2))
  vim.cmd 'botright split'
  vim.api.nvim_win_set_height(0, height)

  if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
    vim.api.nvim_win_set_buf(0, terminal_buf)
  else
    terminal_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[terminal_buf].bufhidden = 'hide'
    vim.api.nvim_win_set_buf(0, terminal_buf)
    local fish = vim.fn.exepath('fish')
    local shell = fish ~= '' and fish or vim.o.shell
    vim.fn.jobstart({ shell }, { term = true })
  end

  vim.cmd 'startinsert'
end

return M
