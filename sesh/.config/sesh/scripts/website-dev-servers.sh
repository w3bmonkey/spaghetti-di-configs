#!/usr/bin/env bash
# Starts the website dev server and answers the interactive prompts of
# `bun start` (a `prompts` select; the repo can't be modified). Unlike
# pannello, website asks TWO sequential selects: first "App", then
# "Environment". We must answer each as it renders — pressing Enter on
# "App" picks the first choice (web), which then triggers the
# "Environment" prompt; Enter there picks the first choice (development).
# Sending both Enters at once fails because the second prompt hasn't
# rendered yet. For another choice, send Down before Enter, e.g.
# `tmux send-keys -t "$TMUX_PANE" Down Down Enter`.
wait_for() {
  # $1: text to wait for in the pane before returning success
  for _ in $(seq 1 120); do
    if tmux capture-pane -p -t "$TMUX_PANE" | grep -q "$1"; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}
(
  # Answer "App" -> web
  wait_for 'App' && tmux send-keys -t "$TMUX_PANE" Enter || exit
  # Answer "Environment" -> development (only appears after App is answered)
  wait_for 'Environment' && tmux send-keys -t "$TMUX_PANE" Enter
) &
yarn start
