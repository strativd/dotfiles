# Power management for the golf bot MacBook (docs/deployment/local-laptop.md).
# This Mac (Apple Silicon) does not support disablesleep/autorestart —
# `pmset -g cap` exposes only sleep, displaysleep, disksleep. wakeup keeps the
# system awake with the lid OPEN; lid-close sleep cannot be prevented via pmset
# (use an external display / clamshell mode if you need lid-closed operation).
#
# Gotcha: an older `pmset -a disablesleep 1` persists SleepDisabled=true in
# /Library/Preferences/com.apple.PowerManagement.plist, which kills ALL sleep
# (idle and clamshell) even after pmset stops advertising disablesleep. wakedown
# therefore always attempts `disablesleep 0` (capability or not) and verifies;
# if the flag survives, fall back to the plutil fix + reboot.

alias wakeup='sudo pmset -a sleep 0; pmset -g cap | grep -q disablesleep && sudo pmset -a disablesleep 1; true'
alias wakedown='sudo pmset -a sleep 1; sudo pmset -a disablesleep 0 >/dev/null 2>&1; if pmset -g | grep -q "SleepDisabled.*1"; then echo "warning: SleepDisabled still 1 — run: sudo plutil -replace SleepDisabled -bool false /Library/Preferences/com.apple.PowerManagement.plist && sudo reboot"; fi'
alias wakecheck='pmset -g | grep -E "^ *sleep |SleepDisabled"; pmset -g cap | grep -q disablesleep && pmset -g | grep -i disablesleep || echo "disablesleep: unsupported on this Mac (lid-open operation only)"; pmset -g assertions | grep -E "pid.*(PreventUserIdleSystemSleep|PreventSystemSleep)" | head -5; true'

# Recovery: clear a stuck SleepDisabled flag and restore the wake baseline.
wakereset() {
  sudo pmset -a disablesleep 0 >/dev/null 2>&1
  sudo plutil -replace SleepDisabled -bool false /Library/Preferences/com.apple.PowerManagement.plist
  sudo pmset -a sleep 1 displaysleep 15
  if pmset -g | grep -q "SleepDisabled.*1"; then
    echo "SleepDisabled still 1 — reboot to load the cleared plist: sudo reboot"
  else
    echo "SleepDisabled cleared; baseline restored (sleep 1, displaysleep 15)."
  fi
}