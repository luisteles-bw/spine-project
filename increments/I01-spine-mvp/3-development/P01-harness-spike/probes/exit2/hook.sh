#!/usr/bin/env bash
# PreToolUse probe hook. Reads the tool-call JSON on stdin; if the Bash command contains the string
# PROBE_MARKER, it exits with the code in ~/spine-harness-probe/hooks/exit-code (default 2); any other
# command is allowed (exit 0). The file-based code lets you re-test exit 2 vs 1 WITHOUT relaunching
# claude (the script is re-read each call); only changing the settings hook command needs a relaunch.
input="$(cat)"
if printf '%s' "$input" | grep -q 'PROBE_MARKER'; then
  code="$(cat "${HOME}/spine-harness-probe/hooks/exit-code" 2>/dev/null || echo 2)"
  echo "probe hook: PROBE_MARKER seen; exiting ${code}" >&2
  exit "${code}"
fi
exit 0
