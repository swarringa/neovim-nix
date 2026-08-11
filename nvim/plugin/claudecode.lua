if vim.g.did_load_claudecode_plugin then
  return
end
vim.g.did_load_claudecode_plugin = true

require('claudecode').setup {
  terminal = {
    split_width_percentage = 0.5,
    -- Don't force terminal/insert mode just because the window gained focus
    -- (e.g. via <C-w> navigation) -- stay in normal mode until asked.
    auto_insert = false,
  },
}

vim.keymap.set('n', '<leader>ac', '<cmd>ClaudeCode<cr>', { desc = '[a]i [c]laude toggle' })
vim.keymap.set('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', { desc = '[a]i claude [f]ocus' })
vim.keymap.set('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', { desc = '[a]i claude [r]esume' })
vim.keymap.set('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', { desc = '[a]i claude [C]ontinue' })
vim.keymap.set('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', { desc = '[a]i claude select [m]odel' })
vim.keymap.set('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = '[a]i claude add [b]uffer' })
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = '[a]i claude [s]end selection' })
vim.keymap.set('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = '[a]i claude diff [a]ccept' })
vim.keymap.set('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = '[a]i claude diff [d]eny' })
