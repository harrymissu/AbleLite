# Project rules for Claude Code / Claude Code 项目规则
# Keep this file lean (target 80–120 lines) — long files get rules dropped.
# 保持精简(建议 80–120 行)——过长会被丢规则。

## Engineering task rules / 工程任务规则

1. Read the project layout and relevant files before editing; first state in one
   line: the goal, which files you'll touch, and the risks.
   先读懂项目结构和相关文件再动手;先用一句话说清:目标、会改哪些文件、风险点。

2. Make one well-defined change at a time; do not refactor unrelated code, add
   features beyond the task, or introduce abstractions just to look "elegant".
   一次只做一个明确改动;不顺手重构、不加任务外功能、不为"更优雅"引入多余抽象。

3. After editing, report four things: which files changed / why / how to verify /
   any risks.
   改完必须报告四件事:改了哪些文件 / 为什么这么改 / 怎么验证 / 有无风险。

4. Run tests, lint, and build if possible; if not, say why and give manual
   verification steps.
   能跑就跑 test、lint、build;跑不了要说明原因,并给出可手动验证的步骤。

5. Before delivering, self-review: did anything break existing behavior?
   交付前自查一遍:有没有破坏原有逻辑。

6. Always optimize for "runnable, maintainable, minimal diff" first.
   始终以"能运行、好维护、改动最小"为最高目标。

## Execution style / 执行风格

- Run in "lightweight Fable 5" style: explore then model, do more / ask less,
  deliver a finished artifact, self-check at the end.
  按"轻量级 Fable 5 风格"执行:先探索再建模,少问多做,直接给可交付成品,最后自检。

# Note: this file is guidance, not a hard lock. Irreversible actions
# (rm -rf, force-push) are blocked by .claude/guard.sh, not by these rules.
# 注意:本文件是引导而非硬锁。不可逆操作由 .claude/guard.sh 拦截,而非靠这些规则。
