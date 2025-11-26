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

local add, now = MiniDeps.add, MiniDeps.now

add({ source = "folke/tokyonight.nvim" })
now(function()
  vim.cmd.colorscheme("tokyonight")
end, { source = "folke/tokyonight.nvim" })

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
    ensure_installed = { "cpp" },
    highlight = {
      enable = true,
    },
    indent = {
      enable = true,
    },
  })
  pcall(vim.cmd, "TSUpdate")
end, { source = "nvim-treesitter/nvim-treesitter" })

add({
  source = "xeluxee/competitest.nvim",
  depends = { "MunifTanjim/nui.nvim" },
})
now(function()
  require("competitest").setup({
    template_file = {
      cpp = "~/Code/.template.cpp",
    },
    compile_command = {
      cpp = {
        exec = "g++-15",
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

add({
  source = "neovim/nvim-lspconfig",
})
now(function()
  require("mini.completion").setup({
    lsp_completion = { source_func = "omnifunc" },
    window = {
      info = { border = "rounded" },
      signature = { border = "rounded" },
    },
  })

  local capabilities = vim.lsp.protocol.make_client_capabilities()

  vim.lsp.config["clangd"] = {
    capabilities = capabilities,
    cmd = {
      "clangd",
      "--header-insertion=never",
    },
  }
  vim.lsp.enable("clangd")
end, { source = "neovim/nvim-lspconfig" })
