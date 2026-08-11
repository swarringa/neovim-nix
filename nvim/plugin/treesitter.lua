if vim.g.did_load_treesitter_plugin then
  return
end
vim.g.did_load_treesitter_plugin = true

vim.g.skip_ts_context_commentstring_module = true

-- nvim-treesitter no longer auto-enables highlighting; do it per-buffer,
-- skipping large files and filetypes without an installed parser.
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local max_filesize = 100 * 1024 -- 100 KiB
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > max_filesize then
      return
    end
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- Tree-sitter based folding
-- vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

require('nvim-treesitter-textobjects').setup {
  select = {
    -- Automatically jump forward to textobject, similar to targets.vim
    lookahead = true,
    selection_modes = {
      ['@parameter.outer'] = 'v', -- charwise
      ['@function.outer'] = 'V', -- linewise
      ['@class.outer'] = '<c-v>', -- blockwise
    },
  },
  move = {
    set_jumps = true, -- whether to set jumps in the jumplist
  },
}

local select = require('nvim-treesitter-textobjects.select')
local move = require('nvim-treesitter-textobjects.move')
local swap = require('nvim-treesitter-textobjects.swap')

local function select_textobject(query)
  return function()
    select.select_textobject(query, 'textobjects')
  end
end

local textobject_keymaps = {
  ['af'] = '@function.outer',
  ['if'] = '@function.inner',
  ['ac'] = '@class.outer',
  ['ic'] = '@class.inner',
  ['aC'] = '@call.outer',
  ['iC'] = '@call.inner',
  ['a#'] = '@comment.outer',
  ['i#'] = '@comment.outer',
  ['ai'] = '@conditional.outer',
  ['ii'] = '@conditional.outer',
  ['al'] = '@loop.outer',
  ['il'] = '@loop.inner',
  ['aP'] = '@parameter.outer',
  ['iP'] = '@parameter.inner',
}
for lhs, query in pairs(textobject_keymaps) do
  vim.keymap.set({ 'x', 'o' }, lhs, select_textobject(query))
end

vim.keymap.set('n', '<leader>a', function()
  swap.swap_next '@parameter.inner'
end)
vim.keymap.set('n', '<leader>A', function()
  swap.swap_previous '@parameter.inner'
end)

vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
  move.goto_next_start('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, ']P', function()
  move.goto_next_start('@parameter.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
  move.goto_previous_start('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[P', function()
  move.goto_previous_start('@parameter.outer', 'textobjects')
end)

require('treesitter-context').setup {
  max_lines = 3,
}

require('ts_context_commentstring').setup()
