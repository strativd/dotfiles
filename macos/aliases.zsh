# Power management for the golf bot MacBook (docs/deployment/local-laptop.md).
# This Mac (Apple Silicon) does not support disablesleep/autorestart —
# `pmset -g cap` exposes only sleep, displaysleep, disksleep. wakeup keeps the
# system awake with the lid OPEN; lid-close sleep cannot be prevented via pmset
# (use an external display / clamshell mode if you need lid-closed operation).

alias wakeup='sudo pmset -a sleep 0; if pmset -g cap | grep -q disablesleep; then sudo pmset -a disablesleep 1; else echo "pmset: disablesleep unsupported on this Mac — lid-open operation only"; fi'
alias wakedown='sudo pmset -a sleep 1; if pmset -g cap | grep -q disablesleep; then sudo pmset -a disablesleep 0; fi'
alias wakecheck='pmset -g | grep -E "^ *sleep "; if pmset -g cap | grep -q disablesleep; then pmset -g | grep disablesleep; else echo "disablesleep: unsupported on this Mac (lid-open operation)"; fi'