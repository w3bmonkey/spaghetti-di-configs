return {
  "laytan/cloak.nvim",
  event = "BufRead",
  opts = {
    enabled = true,
    cloak_character = "*",
    highlight_group = "Comment",
    patterns = {
      {
        file_pattern = ".env*",
        cloak_pattern = "=.+",
        replace = nil, -- keeps the "=" visible, masks everything after
      },
      {
        file_pattern = "envs.ts",
        cloak_pattern = { ":%s*.+", "=%s*.+" },
        replace = nil,
      },
    },
  },
  keys = {
    { "<leader>uc", "<cmd>CloakToggle<cr>", desc = "Toggle Cloak" },
  },
}
