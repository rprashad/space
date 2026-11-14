-- Lighter navy surfaces with explicit, high-contrast selections and menus.
vim.cmd('highlight clear')
vim.o.background = 'dark'
vim.g.colors_name = 'navy-clear'
local c = {
  bg = '#34465f', fg = '#f3f6fc', panel = '#293b53', raised = '#405671',
  muted = '#c3cedd', blue = '#b9d8ff', green = '#bce7bc', yellow = '#ffe1a3',
  red = '#ffb4b8', purple = '#e0c4ff', cyan = '#a9e9e2', ink = '#203149',
}
-- Native Terminal.app needs explicit cterm colors when RGB is unavailable.
local ansi = {'#23334b', '#ffb4b8', '#bce7bc', '#ffe1a3', '#b9d8ff', '#e0c4ff', '#a9e9e2', '#dbe4f1',
  '#b8c6da', '#ffc5c8', '#cdf3cd', '#ffedc3', '#cee5ff', '#eddbff', '#c4f5ef', '#ffffff'}
local function rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end
local indexed = {}
for i, value in ipairs(ansi) do indexed[i - 1] = {rgb(value)} end
local levels = {0, 95, 135, 175, 215, 255}
for r = 0, 5 do for g = 0, 5 do for b = 0, 5 do
  indexed[16 + 36 * r + 6 * g + b] = {levels[r + 1], levels[g + 1], levels[b + 1]}
end end end
for i = 0, 23 do indexed[232 + i] = {8 + 10 * i, 8 + 10 * i, 8 + 10 * i} end
local color_cache = {}
local function nearest(hex)
  if color_cache[hex] then return color_cache[hex] end
  local r, g, b = rgb(hex)
  local best, distance = 0, math.huge
  for i = 0, 255 do
    local value = indexed[i]
    local d = (r - value[1]) ^ 2 + (g - value[2]) ^ 2 + (b - value[3]) ^ 2
    if d < distance then best, distance = i, d end
  end
  color_cache[hex] = best
  return best
end
local function hi(group, opts)
  if not vim.o.termguicolors then
    if opts.fg then opts.ctermfg = nearest(opts.fg) end
    if opts.bg then opts.ctermbg = opts.bg == c.bg and 'NONE' or nearest(opts.bg) end
  end
  vim.api.nvim_set_hl(0, group, opts)
end
local function many(groups, opts)
  for group in groups:gmatch('%S+') do hi(group, opts) end
end
many('Normal NormalNC EndOfBuffer SignColumn', {fg = c.fg, bg = c.bg})
many('NormalFloat Pmenu', {fg = c.fg, bg = c.panel})
many('FloatBorder FloatTitle', {fg = c.blue, bg = c.panel})
hi('CursorLine', {bg = c.raised})
hi('CursorColumn', {bg = c.raised})
hi('ColorColumn', {bg = c.raised})
hi('LineNr', {fg = '#aabbd1', bg = c.bg})
hi('CursorLineNr', {fg = c.yellow, bg = c.raised, bold = true})
many('Cursor lCursor', {fg = c.ink, bg = c.yellow})
many('Visual VisualNOS PmenuSel WildMenu', {fg = c.ink, bg = c.blue, bold = true})
hi('PmenuSbar', {bg = c.raised})
hi('PmenuThumb', {bg = c.blue})
hi('PmenuKind', {fg = c.cyan, bg = c.panel})
hi('PmenuExtra', {fg = c.muted, bg = c.panel})
many('PmenuKindSel PmenuExtraSel', {fg = c.ink, bg = c.blue})
hi('Search', {fg = c.ink, bg = c.yellow})
many('IncSearch CurSearch', {fg = c.ink, bg = '#ffc08c', bold = true})
hi('MatchParen', {fg = c.ink, bg = c.cyan, bold = true})
hi('StatusLine', {fg = c.ink, bg = c.blue, bold = true})
many('StatusLineNC TabLine TabLineFill WinBarNC', {fg = c.muted, bg = c.panel})
many('TabLineSel WinBar', {fg = c.fg, bg = c.raised, bold = true})
many('WinSeparator VertSplit', {fg = '#a9bbd3', bg = c.bg})
many('Folded', {fg = c.blue, bg = c.panel})
hi('FoldColumn', {fg = c.blue, bg = c.bg})
many('Comment NonText SpecialKey Conceal', {fg = c.muted})
many('Constant Number Boolean Float', {fg = c.yellow})
many('String Character', {fg = c.green})
many('Identifier Function', {fg = c.blue})
many('Statement Conditional Repeat Label Operator Keyword Exception', {fg = c.purple})
many('PreProc Include Define Macro PreCondit', {fg = c.cyan})
many('Type StorageClass Structure Typedef', {fg = c.cyan})
many('Special SpecialChar Tag Delimiter Debug', {fg = c.yellow})
many('Title Directory', {fg = c.blue, bold = true})
many('Underlined', {fg = c.blue, underline = true})
many('Error ErrorMsg NvimInternalError', {fg = c.ink, bg = c.red, bold = true})
hi('WarningMsg', {fg = c.yellow, bold = true})
many('MoreMsg Question', {fg = c.green})
hi('Todo', {fg = c.ink, bg = c.yellow, bold = true})
hi('DiffAdd', {fg = c.green, bg = '#2d4b43'})
hi('DiffChange', {fg = c.blue, bg = '#304f70'})
hi('DiffDelete', {fg = c.red, bg = '#583b4b'})
hi('DiffText', {fg = c.ink, bg = c.blue, bold = true})
many('LspReferenceText LspReferenceRead LspReferenceWrite', {bg = c.raised, underline = true})
hi('LspInlayHint', {fg = c.muted, bg = c.panel})
for severity, color in pairs({Error = c.red, Warn = c.yellow, Info = c.blue, Hint = c.cyan, Ok = c.green}) do
  for _, suffix in ipairs({'', 'Sign', 'Floating', 'VirtualText'}) do
    hi('Diagnostic' .. suffix .. severity, {fg = color})
  end
  hi('DiagnosticUnderline' .. severity, {sp = color, undercurl = true})
end
for _, group in ipairs({'SpellBad', 'SpellCap', 'SpellRare', 'SpellLocal'}) do
  hi(group, {sp = c.yellow, undercurl = true})
end
-- Semantic and Tree-sitter tokens retain the same readable syntax palette.
for group, target in pairs({
  ['@variable'] = 'Normal', ['@variable.parameter'] = 'Identifier',
  ['@property'] = 'Identifier', ['@function'] = 'Function',
  ['@function.method'] = 'Function', ['@keyword'] = 'Keyword',
  ['@type'] = 'Type', ['@string'] = 'String', ['@comment'] = 'Comment',
  ['@lsp.type.variable'] = 'Identifier', ['@lsp.type.parameter'] = 'Identifier',
  ['@lsp.type.property'] = 'Identifier', ['@lsp.type.function'] = 'Function',
  ['@lsp.type.method'] = 'Function', ['@lsp.type.class'] = 'Type',
}) do hi(group, {link = target}) end
