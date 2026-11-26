#!/usr/bin/env bash
# PreToolUse probe hook for T04. Two jobs, then always exit 0 (never blocks):
#   1. Append the raw tool-call JSON (one line) to a log, so we can inspect whether each firing carries
#      an `agent_type` field (present for subagent calls; absent/sentinel for the main session).
#   2. AC-5: try to WRITE into the denyWrite state/ dir. Hooks run UNSANDBOXED, so this must succeed even
#      though an agent Bash call to the same path is blocked.
LOG="${HOME}/spine-harness-probe/hooks/agent-type.log"
STATE="${HOME}/spine-harness-probe/state"
input="$(cat)"
printf '%s\n' "$input" >> "$LOG"
if echo "hook wrote at $(date +%s)" >> "${STATE}/hook-unsandboxed.txt" 2>/dev/null; then
  printf '{"_probe_hook_write":"ok"}\n' >> "$LOG"
else
  printf '{"_probe_hook_write":"blocked"}\n' >> "$LOG"
fi
exit 0
