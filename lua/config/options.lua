vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local o = vim.opt
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.autoindent = true
o.number = true
o.relativenumber = true

o.cursorline = true
o.termguicolors = true
o.laststatus = 3
o.showmode = false
o.showcmd = false
o.cmdheight = 0
o.signcolumn = "no"
o.shortmess:append("Ic") 
o.completeopt = "menuone,noinsert,fuzzy"
