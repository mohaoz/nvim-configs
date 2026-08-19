vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local o = vim.opt

do
  local uv = vim.uv or vim.loop
  local sysname = uv.os_uname().sysname or ""
  local is_msys = sysname:find("^MINGW") ~= nil or sysname:find("^MSYS") ~= nil or vim.env.MSYSTEM ~= nil
  local is_windows = vim.fn.has("win32") == 1 or sysname == "Windows_NT" or is_msys
  local shell = (vim.o.shell or ""):lower()
  local is_powershell = shell:find("powershell", 1, true) ~= nil or shell:find("pwsh", 1, true) ~= nil

  if is_windows and is_powershell then
    -- MSYS Nvim can inherit PowerShell while keeping cmd.exe flags, which breaks :!.
    o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    o.shellquote = ""
    o.shellxquote = ""
    o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  end
end

o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.autoindent = true
o.smartindent = true
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
o.completeopt = "menuone,noinsert,popup,fuzzy"
