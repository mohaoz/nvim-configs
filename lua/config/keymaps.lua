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

_G.cr_action = function()
  if vim.fn.complete_info({ "selected" }).selected ~= -1 then
    return "\25"
  end

  if _G.MiniPairs then
    return MiniPairs.cr()
  end

  return "\r"
end

k.set("i", "<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]], { expr = true, silent = true })
k.set("i", "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { expr = true, silent = true })
k.set("i", "<CR>", "v:lua.cr_action()", { expr = true, silent = true })
k.set("i", "<C-Space>", "<C-x><C-o>", opts)
