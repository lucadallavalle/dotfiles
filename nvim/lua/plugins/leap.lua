local M = {
  "https://codeberg.org/andyg/leap.nvim",
  version = "*",
  opts = {},
  config = function()
    local k = require("../keymaps")

    k.mode_map({ "n", "x", "o" }, "s", function()
      require("leap").leap({ target_windows = { vim.api.nvim_get_current_win() } })
    end)
  end,
}

return M
