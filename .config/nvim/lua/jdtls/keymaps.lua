-- NOTE: Java specific keymaps with which key
vim.cmd "command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)"
vim.cmd "command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_set_runtime JdtSetRuntime lua require('jdtls').set_runtime(<f-args>)"
vim.cmd "command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()"
vim.cmd "command! -buffer JdtJol lua require('jdtls').jol()"
vim.cmd "command! -buffer JdtBytecode lua require('jdtls').javap()"
vim.cmd "command! -buffer JdtJshell lua require('jdtls').jshell()"

local map = function(mode, keys, func, description)
  vim.keymap.set(mode, keys, func, description)

  local ok, which_key = pcall(require, 'which-key')
  if ok then
    which_key.add {
      { '<leader>' .. keys, func, desc = description.desc, mode = mode },
    }
  end
end

map('n', 'cJo', "<Cmd>lua require'jdtls'.organize_imports()<CR>", { desc = '[O]rganize Imports' })
map('n', 'cJv', "<Cmd>lua require('jdtls').extract_variable()<CR>", { desc = '[E]xtract Variable' })
map('n', 'cJc', "<Cmd>lua require('jdtls').extract_constant()<CR>", { desc = '[E]xtract Constant' })
map('n', 'cJt', "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", { desc = '[T]est Method' })
map('n', 'cJT', "<Cmd>lua require'jdtls'.test_class()<CR>", { desc = '[T]est Class' })
map('n', 'cJu', '<Cmd>JdtUpdateConfig<CR>', { desc = '[U]pdate Config' })
map('v', 'cJv', "<Cmd>lua require('jdtls').extract_constant()<CR>", { desc = '[E]xtract Variable' })
map('v', 'cJc', "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", { desc = '[E]xtract Constant' })
map('v', 'cJm', "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", { desc = '[E]xtract Method' })
