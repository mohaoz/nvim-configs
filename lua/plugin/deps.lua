local data = vim.fn.stdpath("data")
local mini_path = data .. "/site/pack/deps/start/mini.nvim"
local treesitter_root_dir = data .. "/treesitter"
local nvim_treesitter_path = data .. "/site/pack/deps/pack/deps/opt/nvim-treesitter"
local uv = vim.uv or vim.loop
local sysname = uv.os_uname().sysname or ""
local is_macos = sysname == "Darwin"
local is_msys = sysname:find("^MINGW") ~= nil or sysname:find("^MSYS") ~= nil or vim.env.MSYSTEM ~= nil
local is_windows = vim.fn.has("win32") == 1 or sysname == "Windows_NT" or is_msys
local is_termux = vim.fn.stdpath("config"):find("com.termux", 1, true) ~= nil
  or (vim.env.PREFIX or ""):find("com.termux", 1, true) ~= nil

if not vim.g.mohao_safe_notify_fast_event then
  vim.g.mohao_safe_notify_fast_event = true

  local unpack = table.unpack or unpack
  local notify = vim.notify

  vim.notify = function(...)
    if not vim.in_fast_event() then
      return notify(...)
    end

    local argc = select("#", ...)
    local args = { ... }
    vim.schedule(function()
      notify(unpack(args, 1, argc))
    end)
  end
end

local function fs_exists(path)
  return type(path) == "string" and path ~= "" and uv.fs_stat(path) ~= nil
end

local function executable_path(command)
  if command == nil or command == "" then
    return nil
  end

  if command:find("[/\\]") ~= nil then
    return fs_exists(command) and command or nil
  end

  local path = vim.fn.exepath(command)
  return path ~= "" and path or nil
end

local function first_executable(candidates)
  for _, command in ipairs(candidates) do
    local path = executable_path(command)
    if path ~= nil then
      return path
    end
  end
end

local msys_prefixes = {
  "C:/msys64/ucrt64",
  "C:/msys64/mingw64",
  "C:/msys64/clang64",
  "/ucrt64",
  "/mingw64",
  "/clang64",
}

if vim.env.MSYSTEM_PREFIX ~= nil and vim.env.MSYSTEM_PREFIX ~= "" then
  table.insert(msys_prefixes, 1, vim.env.MSYSTEM_PREFIX)
end

if vim.env.MINGW_PREFIX ~= nil and vim.env.MINGW_PREFIX ~= "" then
  table.insert(msys_prefixes, 1, vim.env.MINGW_PREFIX)
end

local function msys_bin_candidates(executable)
  local candidates = {}
  for _, prefix in ipairs(msys_prefixes) do
    if prefix ~= nil and prefix ~= "" then
      table.insert(candidates, prefix .. "/bin/" .. executable)
    end
  end
  return candidates
end

local function cpp_compiler_candidates()
  if is_windows then
    local candidates = msys_bin_candidates("g++.exe")
    vim.list_extend(candidates, { "g++.exe", "g++" })
    return candidates
  end

  if is_macos then
    return {
      "/opt/homebrew/bin/g++-15",
      "/usr/local/bin/g++-15",
      "g++-15",
      "/opt/homebrew/bin/g++-14",
      "/usr/local/bin/g++-14",
      "g++-14",
      "g++",
    }
  end

  return { "g++-15", "g++-14", "g++-13", "g++" }
end

local git = first_executable(vim.list_extend({
  "git",
  "git.exe",
  "C:/msys64/usr/bin/git.exe",
  "/usr/bin/git.exe",
}, msys_bin_candidates("git.exe"))) or "git"
local cpp_compiler = first_executable(cpp_compiler_candidates()) or "g++"

if not fs_exists(mini_path) then
  vim.fn.system({ git, "clone", "--filter=blob:none", "https://github.com/echasnovski/mini.nvim", mini_path })
end

do
  local mini_files_path = mini_path .. "/lua/mini/files.lua"
  local ok, lines = pcall(vim.fn.readfile, mini_files_path)
  local original = "H.is_windows = vim.loop.os_uname().sysname == 'Windows_NT'"
  local patched = "do local sysname = vim.loop.os_uname().sysname; H.is_windows = sysname == 'Windows_NT' or sysname:find('^MINGW') ~= nil or sysname:find('^MSYS') ~= nil end"

  if is_msys and ok then
    for i, line in ipairs(lines) do
      if line == patched then
        break
      end

      if line == original then
        lines[i] = patched
        vim.fn.writefile(lines, mini_files_path)
        break
      end
    end
  end
end

vim.opt.rtp:prepend(mini_path)

local MiniDeps = require("mini.deps")
MiniDeps.setup({
  path = {
    package = data .. "/site/pack/deps",
    state = data .. "/deps",
  },
})

vim.opt.runtimepath:prepend(treesitter_root_dir)
vim.opt.runtimepath:append(nvim_treesitter_path)

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

local function apply_transparent_background()
  local groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "FloatTitle",
    "SignColumn",
    "LineNr",
    "CursorLine",
    "CursorLineNr",
    "EndOfBuffer",
    "StatusLine",
    "StatusLineNC",
    "TabLine",
    "TabLineFill",
    "WinBar",
    "WinBarNC",
    "MiniFilesNormal",
    "MiniFilesBorder",
    "MiniFilesTitle",
  }

  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "NONE" })
  end
end

add({ source = "catppuccin/nvim", name = "catppuccin" })
now(function()
  require("catppuccin").setup({
    flavour = "frappe",
    transparent_background = true,
    integrations = {
      mini = true,
      treesitter = true,
    },
  })
  vim.cmd.colorscheme("catppuccin")
  apply_transparent_background()

  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = apply_transparent_background,
  })
end)

later(function()
  require("mini.statusline").setup()
end)

now(function()
  require("mini.files").setup({
    windows = {
      preview = true,
      width_focus = 40,
      width_nofocus = 30,
    },
  })
end)

now(function()
  require("mini.clue").setup({
    triggers = {
      { mode = "n", keys = "<Leader>" },
      { mode = "n", keys = "<C-w>" },
    },
    window = {
      config = {
        width = 50,
      },
    },
  })
end)

add({ source = "echasnovski/mini.pairs" })
now(function()
  require("mini.pairs").setup()
end, { source = "echasnovski/mini.pairs" })

add({
  source = "mohaoz/fastolympiccoding.nvim",
  depends = {
    {
      source = "mbrea-c/fibrous.nvim",
      checkout = "a6042fec23ba12340589cd33c6ba3c717125e7c5",
    },
  },
})
now(function()
  require("fastolympiccoding").setup()
end)

add({ source = "mohaoz/fastolympiccoding-hook.nvim" })
now(function()
  require("fastolympiccoding_hook").setup()
end)

if not is_termux then
  add({ source = "mistricky/codesnap.nvim" })
  now(function()
    require("codesnap").setup({
      watermark = {
        content = "",
      },
      save_path = vim.fn.expand("~/Pictures/CodeSnap"),
      show_workspace = false,
      snapshot_config = {
        code_config = {
          breadcrumbs = {
            enable = false,
          },
        },
      },
    })
    require("config.codesnap").setup()
  end, { source = "mistricky/codesnap.nvim" })
end

now(function()
  vim.diagnostic.config({
    virtual_text = {
      prefix = ">",
      spacing = 4,
    },
    signs = false,
    underline = true,
    update_in_insert = false,
  })

  require("mini.completion").setup({
    delay = {
      completion = 50,
      info = 50,
      signature = 25,
    },
    lsp_completion = {
      source_func = "omnifunc",
      auto_setup = false,
      process_items = function(items, base)
        return MiniCompletion.default_process_items(items, base, {
          filtersort = "fuzzy",
        })
      end,
    },
    window = {
      info = { border = "rounded" },
      signature = { border = "rounded" },
    },
  })

  local capabilities = require("mini.completion").get_lsp_capabilities()

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
      vim.bo[ev.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
    end,
  })

  local clangd = first_executable({ "clangd", "clangd.exe" })
  if clangd ~= nil then
    vim.lsp.config["clangd"] = {
      capabilities = capabilities,
      filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
      cmd = {
        clangd,
        "--header-insertion=never",
        "--query-driver=" .. cpp_compiler,
      },
    }
    vim.lsp.enable("clangd")
  end

  vim.g.zig_fmt_parse_errors = 0
  vim.g.zig_fmt_autosave = 0
  if vim.fn.exepath("zls") ~= "" then
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.zig", "*.zon" },
      callback = function(ev)
        vim.lsp.buf.format({ bufnr = ev.buf })
      end,
    })

    vim.lsp.config["zls"] = {
      cmd = { "zls" },
      filetypes = { "zig" },
      root_markers = { "build.zig" },
      settings = {
        zls = {
          zig_exe_path = vim.fn.exepath("zig"),
        },
      },
    }
    vim.lsp.enable("zls")
  end

  if vim.fn.exepath("pyright-langserver") ~= "" then
    vim.lsp.config["pyright"] = {
      capabilities = capabilities,
      cmd = { "pyright-langserver", "--stdio" },
      filetypes = { "python" },
      root_markers = {
        "pyproject.toml",
        "pyrightconfig.json",
        "requirements.txt",
        ".git",
      },
      settings = {
        pyright = {
          disableOrganizeImports = false,
        },
        python = {
          analysis = {
            typeCheckingMode = "basic",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
          },
        },
      },
    }
    vim.lsp.enable("pyright")
  end
end)
