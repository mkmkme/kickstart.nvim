local M = {}
local generations = {}
local guarded_clients = {}

M.config = {
  filetypes = { 'c', 'cpp', 'python', 'rust', 'sh', 'bash', 'yaml', 'dockerfile', 'lua', 'cmake', 'markdown', 'json', 'jsonc', 'toml' },
  root_dir = function(bufnr, on_dir)
    local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
    if
      vim.bo[bufnr].buftype ~= ''
      or name:match('^%.env')
      or name:match('%.pem$')
      or name:match('%.key$')
      or name == 'id_rsa'
      or name == 'id_dsa'
      or name == 'id_ecdsa'
      or name == 'id_ed25519'
    then
      return
    end
    on_dir(vim.fs.root(bufnr, '.git'))
  end,
  settings = {
    telemetry = { telemetryLevel = 'off' },
  },
}

local function sync(bufnr)
  local state = vim.b[bufnr]
  if state.copilot_enabled == nil then return end
  local enabled = state.copilot_enabled
  if enabled == vim.lsp.inline_completion.is_enabled { bufnr = bufnr } then return end
  generations[bufnr] = (generations[bufnr] or 0) + 1
  vim.lsp.inline_completion.enable(enabled, { bufnr = bufnr })
end

local function guard_inline_responses(client)
  if guarded_clients[client.id] then return end
  guarded_clients[client.id] = true
  local request = client.request
  client.request = function(self, method, params, handler, bufnr)
    if method ~= 'textDocument/inlineCompletion' or not handler then return request(self, method, params, handler, bufnr) end
    bufnr = bufnr and bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
    local generation = generations[bufnr]
    -- Native inline completion can receive replies after its state was destroyed.
    -- Ignore replies from before a disable/re-enable cycle, even if cancellation raced.
    return request(self, method, params, function(...)
      if not vim.api.nvim_buf_is_valid(bufnr) or not vim.lsp.buf_is_attached(bufnr, self.id) or generations[bufnr] ~= generation then return end
      if not vim.lsp.inline_completion.is_enabled { bufnr = bufnr } then return end
      handler(...)
    end, bufnr)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('custom-copilot', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client or client.name ~= 'copilot' then return end
      guard_inline_responses(client)
      if vim.b[event.buf].copilot_enabled == nil then vim.b[event.buf].copilot_enabled = true end
      sync(event.buf)
      vim.keymap.set('n', '<leader>ta', function()
        vim.b[event.buf].copilot_enabled = not vim.b[event.buf].copilot_enabled
        sync(event.buf)
        vim.notify('AI suggestions ' .. (vim.b[event.buf].copilot_enabled and 'enabled' or 'disabled'))
      end, { buffer = event.buf, desc = '[T]oggle [A]I suggestions' })
    end,
  })
end

return M
