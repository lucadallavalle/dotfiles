local M = {
  {
    "williamboman/mason.nvim",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    -- By default it auto-enables installed servers in Nvim 0.11+.
    -- ensure_installed makes sure binaries are present.
    opts = {
      ensure_installed = { "lua_ls" },
      -- automatic_enable = true, -- (default) leave it on
    },
    dependencies = { "neovim/nvim-lspconfig" },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Define server config (no enable here)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      -- Optional: your keymaps / LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local k = require("../keymaps")
          local opts = { buffer = ev.buf }

          -- 💬 Hover and signature help
          k.nmap("K", vim.lsp.buf.hover, opts)
          k.nmap("<C-k>", vim.lsp.buf.signature_help, opts)

          -- 🧭 Go to
          k.nmap("gd", vim.lsp.buf.definition, opts)
          k.nmap("gD", vim.lsp.buf.declaration, opts)
          k.nmap("gi", vim.lsp.buf.implementation, opts)
          k.nmap("gr", vim.lsp.buf.references, opts) -- show references
          k.nmap("<leader>D", vim.lsp.buf.type_definition, opts)

          -- 🪄 Code actions & formatting
          k.mode_map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
          k.nmap("<leader>rn", vim.lsp.buf.rename, opts) -- rename symbol
          k.nmap("<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)

          -- 🧭 Diagnostics navigation
          k.nmap("[d", vim.diagnostic.goto_prev, opts)
          k.nmap("]d", vim.diagnostic.goto_next, opts)
          k.nmap("<leader>e", vim.diagnostic.open_float, opts)
          k.nmap("<leader>q", vim.diagnostic.setloclist, opts)

          -- 🧰 Optional: workspace actions
          k.nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
          k.nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
          k.nmap("<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
        end,
      })
    end,
  },
}

return M
