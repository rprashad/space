-- Works with Debian's Neovim 0.10, without plugin downloads.
vim.g.mapleader = ' '
-- Servers installed by the setup process must also work from GUI terminals.
vim.env.PATH = vim.fn.expand('~/.local/bin') .. ':' .. vim.fn.expand('~/.cargo/bin') .. ':' .. vim.env.PATH
-- GUI terminals may start without NVM's Node.js directory in PATH.
if vim.fn.executable('node') == 0 then
  local nodes = vim.fn.glob(vim.fn.expand('~/.nvm/versions/node/*/bin/node'), false, true)
  if #nodes > 0 then vim.env.PATH = vim.fs.dirname(nodes[#nodes]) .. ':' .. vim.env.PATH end
end
vim.opt.number = true
vim.opt.relativenumber = true
-- Terminal.app uses the palette fallback; tmux can downconvert RGB itself.
vim.opt.termguicolors = vim.env.TERM_PROGRAM ~= 'Apple_Terminal' or vim.env.TMUX ~= nil
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.scrolloff = 5
vim.opt.undofile = true
vim.opt.completeopt = {'menu', 'menuone', 'noselect'}
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.cmd.colorscheme('navy-clear')
vim.opt.laststatus = 3
vim.opt.statusline = ' %<%F %m%r%=%y  %l:%c  %p%% '
vim.opt.pumheight = 12
vim.opt.pumblend = 0
vim.opt.winblend = 0
vim.opt.fillchars:append({eob = ' ', vert = '│'})
vim.g.clipboard = {
  name = 'System clipboard',
  copy = {['+'] = {vim.fn.expand('~/.local/bin/clipboard-copy')}, ['*'] = {vim.fn.expand('~/.local/bin/clipboard-copy')}},
  paste = {['+'] = {vim.fn.expand('~/.local/bin/clipboard-paste')}, ['*'] = {vim.fn.expand('~/.local/bin/clipboard-paste')}},
  cache_enabled = 0,
}
-- Terraform variables share Terraform syntax; all Terragrunt HCL uses its own server.
vim.filetype.add({extension = {tf = 'terraform', tfvars = 'terraform', hcl = 'hcl'}})
local warned_missing = {}
local servers = {
  terraform = {cmd = {'terraform-ls', 'serve'}, markers = {'.terraform', '.terraform.lock.hcl', '.git'}},
  hcl = {cmd = {'terragrunt-ls'}, markers = {'terragrunt.hcl', 'root.hcl', '.git'}},
  python = {cmd = {'pyright-langserver', '--stdio'}, markers = {'pyproject.toml', 'setup.py', '.git'}},
  javascript = {cmd = {'typescript-language-server', '--stdio'}, markers = {'package.json', '.git'}},
  javascriptreact = {cmd = {'typescript-language-server', '--stdio'}, markers = {'package.json', '.git'}},
  typescript = {cmd = {'typescript-language-server', '--stdio'}, markers = {'tsconfig.json', 'package.json', '.git'}},
  typescriptreact = {cmd = {'typescript-language-server', '--stdio'}, markers = {'tsconfig.json', 'package.json', '.git'}},
  rust = {cmd = {'rust-analyzer'}, markers = {'Cargo.toml', '.git'}},
  ruby = {cmd = {'ruby-lsp'}, markers = {'Gemfile', '.git'}},
  json = {cmd = {'vscode-json-language-server', '--stdio'}, markers = {'package.json', '.git'}},
  jsonc = {cmd = {'vscode-json-language-server', '--stdio'}, markers = {'package.json', '.git'}},
  yaml = {cmd = {'yaml-language-server', '--stdio'}, markers = {'.git'}},
}
vim.api.nvim_create_autocmd('FileType', {
  callback = function(event)
    local ft = vim.bo[event.buf].filetype
    if ft == 'python' then vim.bo[event.buf].shiftwidth = 4; vim.bo[event.buf].tabstop = 4 end
    local s = servers[ft]
    if not s then return end
    if vim.fn.executable(s.cmd[1]) == 0 then
      if not warned_missing[s.cmd[1]] then
        warned_missing[s.cmd[1]] = true
        vim.schedule(function()
          vim.notify('Completion unavailable for ' .. ft .. ': missing ' .. s.cmd[1]
            .. '. Install the server listed in space/windows_env/README.md, then restart Neovim.', vim.log.levels.WARN)
        end)
      end
      return
    end
    local file = vim.api.nvim_buf_get_name(event.buf)
    local marker = vim.fs.find(s.markers, {path = vim.fs.dirname(file), upward = true})[1]
    local root = marker and vim.fs.dirname(marker) or vim.fn.getcwd()
    vim.lsp.start({
      name = s.cmd[1], cmd = s.cmd, root_dir = root,
      on_attach = function(_, buf)
        vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
        local o = {buffer = buf}
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, o)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, o)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, o)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, o)
        vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({async = true}) end, o)
      end,
    })
  end,
})
local function completion_keys()
  return #vim.lsp.get_clients({bufnr = 0}) > 0 and '<C-x><C-o>' or '<C-n>'
end
vim.keymap.set('i', '<C-Space>', completion_keys, {expr = true})
vim.keymap.set('i', '<C-@>', completion_keys, {expr = true})
vim.keymap.set('i', '<Tab>', function() return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>' end, {expr = true})
vim.keymap.set('i', '<S-Tab>', function() return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>' end, {expr = true})
vim.keymap.set('i', '<CR>', function() return vim.fn.pumvisible() == 1 and vim.fn.complete_info().selected ~= -1 and '<C-y>' or '<CR>' end, {expr = true})
-- Trigger LSP completion after two word characters; Ctrl+Space also works.
vim.api.nvim_create_autocmd('TextChangedI', {callback = function()
  if vim.fn.pumvisible() == 1 then return end
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = vim.api.nvim_get_current_line():sub(1, col)
  if before:match('[%w_][%w_]$') or before:match('[%.:]$') then
    local keys = vim.api.nvim_replace_termcodes(completion_keys(), true, false, true)
    vim.api.nvim_feedkeys(keys, 'n', false)
  end
end})
vim.api.nvim_create_user_command('LspStatus', function()
  local lines = {}
  for ft, s in pairs(servers) do
    lines[#lines+1] = ft .. ': ' .. (vim.fn.executable(s.cmd[1]) == 1 and 'available' or 'MISSING ' .. s.cmd[1])
  end
  table.sort(lines); print(table.concat(lines, '\n'))
  print('Active servers in this buffer: ' .. #vim.lsp.get_clients({bufnr = 0}))
end, {})
vim.diagnostic.config({virtual_text = false, severity_sort = true, float = {border = 'rounded'}})
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
