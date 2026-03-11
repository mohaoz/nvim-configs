local k = vim.keymap
local opts = {
  silent = true,
  noremap = true,
}

k.set("n", "<leader>e", function()
  require("mini.files").open(vim.api.nvim_buf_get_name(0))
end, opts)
k.set("n", "<leader>r", ":CompetiTest run<CR>", opts)

k.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true})
k.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true})

k.set("n", "<C-h>", "<C-w>h", opts)
k.set("n", "<C-j>", "<C-w>j", opts)
k.set("n", "<C-k>", "<C-w>k", opts)
k.set("n", "<C-l>", "<C-w>l", opts)
-- lua/config/keymaps.lua

-- ... 原有的 leader e/r 映射保持不变

-- --- 核心改进：VS Code 风格 Tab 补全 ---
-- 如果补全菜单可见，Tab 直接执行 <C-y> (确认补全)
k.set("i", "<Tab>", [[pumvisible() ? "\<C-y>" : "\<Tab>"]], { expr = true, silent = true })
-- S-Tab 可以用来手动呼出补全或者反向选择 (可选)
k.set("i", "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { expr = true, silent = true })

-- ... 原有的 j/k 和窗口跳转保持不变
