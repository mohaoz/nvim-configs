vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.opt_local.cindent = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "python", "zig" },
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
