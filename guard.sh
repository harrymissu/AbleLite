#!/usr/bin/env bash
# guard.sh — PreToolUse guard for Claude Code.
# Reads the pending Bash tool call from stdin (JSON) and blocks destructive
# commands by exiting with code 2. Exit 0 = allow. Requires: jq.
#
# guard.sh — Claude Code 的 PreToolUse 守卫。
# 从 stdin(JSON)读取待执行的 Bash 命令,用退出码 2 拦截破坏性操作。
# 退出码 0 = 放行。依赖:jq。
#
# Wire it up in .claude/settings.json under hooks.PreToolUse (matcher "Bash").
# 在 .claude/settings.json 的 hooks.PreToolUse(matcher "Bash")中接线。

set -euo pipefail

# Extract the command string from the tool input. / 取出待执行命令。
cmd="$(jq -r '.tool_input.command // empty')"

# Add your own forbidden patterns here. / 在此添加你自己的禁止模式。
DENY='rm -rf|git push --force|git push -f|git reset --hard|sudo rm|mkfs|dd if='

if printf '%s' "$cmd" | grep -Eq "$DENY"; then
  # stderr is shown back to the model so it can suggest a safer alternative.
  # stderr 会回传给模型,使其改用更安全的做法。
  echo "Blocked by guard.sh (destructive command): $cmd" >&2
  exit 2   # 2 = block the action / 拦截操作
fi

exit 0     # 0 = allow / 放行
