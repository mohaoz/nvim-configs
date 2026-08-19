local M = {}

local uv = vim.uv or vim.loop

local function is_wsl()
  return uv.os_uname().sysname == "Linux"
    and (vim.env.WSL_DISTRO_NAME ~= nil or vim.env.WSL_INTEROP ~= nil)
end

local function executable(name)
  local path = vim.fn.exepath(name)
  return path ~= "" and path or nil
end

local function shell_single_quote(value)
  return "'" .. value:gsub("'", "''") .. "'"
end

local function wsl_to_windows_path(path, wslpath)
  local result = vim.fn.system({ wslpath, "-w", path })
  if vim.v.shell_error ~= 0 then
    error("wslpath failed: " .. vim.trim(result))
  end

  return vim.trim(result)
end

local function copy_image_to_windows_clipboard(path, powershell, wslpath)
  local windows_path = wsl_to_windows_path(path, wslpath)
  local quoted_path = shell_single_quote(windows_path)
  local script = table.concat({
    "$ErrorActionPreference = 'Stop'",
    "Add-Type -AssemblyName System.Drawing",
    "Add-Type -AssemblyName System.Windows.Forms",
    "$bytes = [System.IO.File]::ReadAllBytes(" .. quoted_path .. ")",
    "$stream = New-Object System.IO.MemoryStream(,$bytes)",
    "$image = [System.Drawing.Image]::FromStream($stream)",
    "try { [System.Windows.Forms.Clipboard]::SetImage($image) } finally { $image.Dispose(); $stream.Dispose() }",
  }, "; ")

  local result = vim.fn.system({
    powershell,
    "-NoLogo",
    "-NoProfile",
    "-NonInteractive",
    "-Sta",
    "-ExecutionPolicy",
    "Bypass",
    "-Command",
    script,
  })

  if vim.v.shell_error ~= 0 then
    error("PowerShell clipboard copy failed: " .. vim.trim(result))
  end
end

function M.setup()
  if not is_wsl() then
    return
  end

  local powershell = executable("powershell.exe") or executable("pwsh.exe")
  local wslpath = executable("wslpath")

  if powershell == nil or wslpath == nil then
    vim.notify("CodeSnap WSL image clipboard fallback is unavailable", vim.log.levels.WARN)
    return
  end

  local module = require("codesnap.module")
  local generator = module.load_generator()

  generator.copy = function(config)
    local snapshot_path = vim.fn.tempname() .. ".png"

    local ok, err = xpcall(function()
      generator.save(snapshot_path, config)
      copy_image_to_windows_clipboard(snapshot_path, powershell, wslpath)
    end, debug.traceback)

    vim.fn.delete(snapshot_path)

    if not ok then
      error(err)
    end
  end
end

return M
