#!/usr/bin/env bash
# Starts the pannello dev server and answers the interactive environment
# prompt of `bun start` (a `prompts` select; the repo can't be modified).
# Waits until the prompt is rendered, then presses Enter to pick the first
# choice: development. For another environment, send Down before Enter,
# e.g. `tmux send-keys -t "$TMUX_PANE" Down Down Enter` for emulator.
(
  for _ in $(seq 1 120); do
    if tmux capture-pane -p -t "$TMUX_PANE" | grep -q 'Environment'; then
      tmux send-keys -t "$TMUX_PANE" Enter
      break
    fi
    sleep 0.5
  done
) &
bun  start
