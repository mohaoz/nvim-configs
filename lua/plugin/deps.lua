local data = vim.fn.stdpath("data")
local mini_path = data .. "/site/pack/deps/start/mini.nvim"
local treesitter_root_dir = data .. "/treesitter"
local nvim_treesitter_path = data .. "/site/pack/deps/pack/deps/opt/nvim-treesitter"
local is_windows = vim.fn.has("win32") == 1
local ucrt_bin = "C:/msys64/ucrt64/bin"
local msys_bin = "C:/msys64/usr/bin"
local git = is_windows and (msys_bin .. "/git.exe") or "git"
local cpp_compiler = is_windows and (ucrt_bin .. "/g++.exe")
  or (vim.fn.exepath("g++") ~= "" and vim.fn.exepath("g++") or "/opt/homebrew/bin/g++-15")

if not (vim.uv or vim.loop).fs_stat(mini_path) then
  vim.fn.system({ git, "clone", "--filter=blob:none", "https://github.com/echasnovski/mini.nvim", mini_path })
end

do
  local mini_files_path = mini_path .. "/lua/mini/files.lua"
  local lines = vim.fn.readfile(mini_files_path)
  local original = "H.is_windows = vim.loop.os_uname().sysname == 'Windows_NT'"
  local patched = "do local sysname = vim.loop.os_uname().sysname; H.is_windows = sysname == 'Windows_NT' or sysname:find('^MINGW') ~= nil or sysname:find('^MSYS') ~= nil end"

  for i, line in ipairs(lines) do
    if line == original then
      lines[i] = patched
      vim.fn.writefile(lines, mini_files_path)
      break
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
  source = "xeluxee/competitest.nvim",
  depends = { "MunifTanjim/nui.nvim" },
})
now(function()
  require("competitest").setup({
    template_file = {
      cpp = vim.fn.expand("~/code/.template.cpp"),
    },
    compile_command = {
      cpp = {
        exec = cpp_compiler,
        args = {
          "-Wall",
          "$(FNAME)",
          "-o",
          "$(FNOEXT)",
          "-std=gnu++23",
          "-lstdc++exp",
        },
      },
    },
  })
end, { source = "xeluxee/competitest.nvim" })

if not vim.fn.stdpath("config"):find("com.termux") then
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
    lsp_completion = {
      source_func = "omnifunc",
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

  vim.lsp.config["clangd"] = {
    capabilities = capabilities,
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    cmd = {
      "clangd",
      "--header-insertion=never",
      "--query-driver=" .. cpp_compiler,
    },
  }
  vim.lsp.enable("clangd")

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
