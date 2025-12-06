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

