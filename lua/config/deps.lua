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

-- lua/config/deps.lua

-- ... 在 catppuccin 配置之后添加
now(function()
  local statusline = require('mini.statusline')
  statusline.setup({
    content = {
      -- 重新定义活跃窗口的状态栏内容，让它更轻盈、高端
      active = function()
        local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
        local git           = statusline.section_git({ trunc_width = 75 })
        local diff          = statusline.section_diff({ trunc_width = 75 })
        local diagnostics   = statusline.section_diagnostics({ trunc_width = 75 })
        local lsp           = statusline.section_lsp({ trunc_width = 75 })
        local filename      = statusline.section_filename({ trunc_width = 140 })
        local fileinfo      = statusline.section_fileinfo({ trunc_width = 120 })
        local location      = statusline.section_location({ trunc_width = 75 })

        return statusline.combine_groups({
          { hl = mode_hl,                  strings = { mode } },
          { hl = 'MiniStatuslineDevinfo',  strings = { git, diff, diagnostics, lsp } },
          '%<', -- 截断点
          { hl = 'MiniStatuslineFilename', strings = { filename } },
          '%=', -- 左右对齐切换点
          { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
          { hl = mode_hl,                  strings = { location } },
        })
      end
    },
    set_vim_settings = false, -- 我们已经在 options.lua 里手动设过了
  })
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
    ensure_installed = { "cpp" },
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

now(function()
  vim.diagnostic.config({
    virtual_text = {
      prefix = '●', -- 虚拟文本前的符号，可以用 '■', '●', '󰅚 ' 等
      spacing = 4,  -- 符号与代码行末尾的间距
    },
    signs = false,     -- 显式禁用左侧符号栏图标（双重保险）
    underline = true,  -- 保留代码下方的错误/警告波浪线
    update_in_insert = false, -- 只有退出插入模式时才更新报错，避免打字时视觉干扰
  })
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
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" }, -- 只在这些文件类型中启动
    cmd = {
      "clangd",
      "--header-insertion=never",
    },
  }
  vim.lsp.enable("clangd")
end)
