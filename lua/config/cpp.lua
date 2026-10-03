local M = {}

function M.setup(clangd, compiler, capabilities)
  vim.lsp.config("clangd", {
    capabilities = capabilities,
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = {
      { ".clangd", "compile_commands.json", "compile_flags.txt" },
      { "CMakeLists.txt", "Makefile", "meson.build" },
      ".git",
    },
    cmd = {
      clangd,
      "--background-index",
      "--clang-tidy",
      "--completion-style=detailed",
      "--header-insertion=never",
      "--query-driver=" .. compiler,
    },
    on_attach = function(client, bufnr)
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end
      map("gd", vim.lsp.buf.definition, "LSP: definition")
      map("gD", vim.lsp.buf.declaration, "LSP: declaration")
      map("gr", vim.lsp.buf.references, "LSP: references")
      map("gi", vim.lsp.buf.implementation, "LSP: implementation")
      map("K", vim.lsp.buf.hover, "LSP: hover")
      map("<leader>rn", vim.lsp.buf.rename, "LSP: rename")
      map("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
      map("<leader>cf", function()
        vim.lsp.buf.format({ bufnr = bufnr, id = client.id, timeout_ms = 3000 })
      end, "C/C++: format")
      map("<leader>cd", vim.diagnostic.open_float, "Diagnostics: details")
      map("<leader>cq", vim.diagnostic.setqflist, "Diagnostics: quickfix")
      map("<leader>ch", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
      end, "C/C++: toggle inlay hints")
      local function switch_header()
        client:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(bufnr),
          function(err, uri)
            if err then
              vim.notify(err.message, vim.log.levels.ERROR)
            elseif not uri or uri == "" then
              vim.notify("No corresponding source/header found", vim.log.levels.INFO)
            elseif vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() == bufnr then
              vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(uri)))
            end
          end, bufnr)
      end
      map("<leader>cs", switch_header, "C/C++: switch source/header")
      vim.api.nvim_buf_create_user_command(bufnr, "ClangdSwitchSourceHeader", switch_header, {})
    end,
  })
  vim.lsp.enable("clangd")
end

return M
