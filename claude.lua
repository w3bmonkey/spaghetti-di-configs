return {
  -- Full Claude Code terminal integration
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      {
        "<C-k>",
        function()
          if vim.g.claude_job_id and vim.g.claude_job_id > 0 then
            vim.fn.jobstop(vim.g.claude_job_id)
            vim.g.claude_job_id = nil
            vim.notify("Claude cancelled", vim.log.levels.WARN)
          end
        end,
        desc = "Cancel Claude request",
      },
      {
        "<C-k>",
        function()
          -- If a job is already running, cancel it
          if vim.g.claude_job_id and vim.g.claude_job_id > 0 then
            vim.fn.jobstop(vim.g.claude_job_id)
            vim.g.claude_job_id = nil
            vim.notify("Claude cancelled", vim.log.levels.WARN)
            return
          end

          -- Grab visual selection before exiting visual mode
          local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
          local code = table.concat(lines, "\n")
          local filetype = vim.bo.filetype
          local filename = vim.fn.expand("%:t")
          local start_line = vim.fn.line("v")
          local end_line = vim.fn.line(".")

          -- Exit visual mode
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

          -- Open floating input prompt
          vim.ui.input({ prompt = "Claude > " }, function(instruction)
            if not instruction or instruction == "" then
              return
            end

            local prompt = string.format(
              "File: %s (lines %d-%d), language: %s\n\nSelected code:\n%s\n\nInstruction: %s\n\nReturn ONLY the modified code, no markdown fences, no explanation.",
              filename, start_line, end_line, filetype, code, instruction
            )

            -- Write prompt to temp file
            local tmpfile = vim.fn.tempname()
            vim.fn.writefile(vim.split(prompt, "\n"), tmpfile)

            vim.notify("Claude is thinking... (Ctrl-k to cancel)", vim.log.levels.INFO)

            local output = {}
            local error_output = {}
            local s = math.min(start_line, end_line)
            local e = math.max(start_line, end_line)

            vim.g.claude_job_id = vim.fn.jobstart("unset CLAUDECODE; cat " .. vim.fn.shellescape(tmpfile) .. " | claude -p", {
              stdout_buffered = true,
              stderr_buffered = true,
              on_stdout = function(_, data)
                for _, line in ipairs(data) do
                  if line ~= "" then
                    table.insert(output, line)
                  end
                end
              end,
              on_stderr = function(_, data)
                for _, line in ipairs(data) do
                  if line ~= "" then
                    table.insert(error_output, line)
                  end
                end
              end,
              on_exit = function(_, exit_code)
                vim.g.claude_job_id = nil
                vim.fn.delete(tmpfile)
                vim.schedule(function()
                  if exit_code ~= 0 then
                    vim.notify(
                      "Claude failed (exit " .. exit_code .. "): " .. table.concat(error_output, "\n"),
                      vim.log.levels.ERROR
                    )
                    return
                  end

                  local result = table.concat(output, "\n")

                  -- Strip markdown code fences if present
                  result = result:match("```[%w_%-]*\n(.-)\n```") or result:match("```\n(.-)\n```") or result

                  -- Show result in a floating preview window
                  local result_lines = vim.split(result, "\n")
                  local buf = vim.api.nvim_create_buf(false, true)
                  vim.api.nvim_buf_set_lines(buf, 0, -1, false, result_lines)
                  vim.bo[buf].filetype = filetype

                  local width = math.min(100, math.floor(vim.o.columns * 0.8))
                  local height = math.min(#result_lines + 2, math.floor(vim.o.lines * 0.6))
                  local win = vim.api.nvim_open_win(buf, true, {
                    relative = "editor",
                    width = width,
                    height = height,
                    col = math.floor((vim.o.columns - width) / 2),
                    row = math.floor((vim.o.lines - height) / 2),
                    style = "minimal",
                    border = "rounded",
                    title = " Claude — [y] accept  [n] reject ",
                    title_pos = "center",
                  })

                  local function close()
                    if vim.api.nvim_win_is_valid(win) then
                      vim.api.nvim_win_close(win, true)
                    end
                    if vim.api.nvim_buf_is_valid(buf) then
                      vim.api.nvim_buf_delete(buf, { force = true })
                    end
                  end

                  vim.keymap.set("n", "y", function()
                    close()
                    vim.api.nvim_buf_set_lines(0, s - 1, e, false, result_lines)
                    vim.notify("Claude edit applied", vim.log.levels.INFO)
                  end, { buffer = buf, nowait = true })

                  vim.keymap.set("n", "n", function()
                    close()
                    vim.notify("Claude edit rejected", vim.log.levels.INFO)
                  end, { buffer = buf, nowait = true })

                  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
                  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
                end)
              end,
            })
          end)
        end,
        mode = "v",
        desc = "Claude inline edit",
      },
    },
  },
}
