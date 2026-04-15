local data = vim.fn.stdpath("data")
local mini_path = data .. "/site/pack/deps/start/mini.nvim"

if not (vim.uv or vim.loop).fs_stat(mini_path) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/echasnovski/mini.nvim", mini_path })
end

vim.opt.rtp:prepend(mini_path)

local MiniDeps = require("mini.deps")
MiniDeps.setup({
  path = {
    package = data .. "/site/pack/deps",
    state = data .. "/deps",
  },
})

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

add({ source = "catppuccin/nvim", name = "catppuccin" })
now(function()
  require("catppuccin").setup({
    flavour = "frappe",          
    transparent_background = true,
    integrations = {
      mini = true,               
      treesitter = true,        
    }
  })
  vim.cmd.colorscheme("catppuccin")
end)

later(function()
  require('mini.statusline').setup()
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
  local clues = {
    { mode = "n", keys = "<Leader>" },
    { mode = "n", keys = "<C-w>" },
  }

  require("mini.clue").setup({
    triggers = clues,
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
  source = "nvim-treesitter/nvim-treesitter",
  checkout = "master",
})
now(function()
  require("nvim-treesitter.configs").setup({
    ensure_installed = { "cpp" , "zig", "python"},
    highlight = {
      enable = true,
    },
    indent = {
      enable = true,
    },
  })
end, { source = "nvim-treesitter/nvim-treesitter" })

add({
  source = "xeluxee/competitest.nvim",
  depends = { "MunifTanjim/nui.nvim" },
})
now(function()
  require("competitest").setup({
    template_file = {
      cpp = "~/code/.template.cpp",
    },
    compile_command = {
      cpp = {
        exec = "/opt/homebrew/bin/g++-15",
        args = {
          "-Wall",
          "$(FNAME)",
          "-o",
          "$(FNOEXT)",
          "-std=gnu++23",
        },
      },
    },
  })
end, { source = "xeluxee/competitest.nvim" })

if not vim.fn.stdpath("config"):find("com.termux") then
  add({
    source = "mistricky/codesnap.nvim",
    hooks = {
      post_checkout = function(path)
        if path then
          vim.system({ "make" }, { cwd = path }):wait()
        end
      end,
    },
  })
  now(function()
    require("codesnap").setup({
      watermark = "",
    })
  end, { source = "mistricky/codesnap.nvim" })
end

now(function()
  vim.diagnostic.config({
    virtual_text = {
      prefix = '●', 
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

  local capabilities = vim.lsp.protocol.make_client_capabilities()

  vim.lsp.config["clangd"] = {
    capabilities = capabilities,
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    cmd = {
      "clangd",
      "--header-insertion=never",
      "--query-driver=/opt/homebrew/bin/g++-15"
    },
  }
  vim.lsp.enable("clangd")
  vim.g.zig_fmt_parse_errors = 0
  vim.g.zig_fmt_autosave = 0
  vim.api.nvim_create_autocmd('BufWritePre',{
    pattern = {"*.zig", "*.zon"},
    callback = function(ev)
      vim.lsp.buf.format()
    end
  })

  vim.lsp.config['zls'] = {
    cmd = { '/opt/homebrew/bin/zls' },
    filetypes = { 'zig' },
    root_markers = { 'build.zig' },
    settings = {
      zls = {
        zig_exe_path = '/opt/homebrew/bin/zig'
      }
    },
  }
  vim.lsp.enable('zls')

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
end)

