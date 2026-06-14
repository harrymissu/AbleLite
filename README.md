<!--
  Pushing Claude Opus 4.8 toward a "Lightweight Fable 5"
  Bilingual (EN / 中文) engineering guide.
  License: MIT
-->

# Pushing Claude Opus 4.8 toward a "Lightweight Fable 5"<br>用 Prompt 让 Claude Opus 4.8 逼近「轻量级 Fable 5」

> **EN** — Stop stuffing one giant "smart" prompt. Stabilize the output with **Goal + Constraints + Acceptance + Self-check**, then enforce the hard parts with hooks.
>
> **中文** — 不靠堆一大段聪明的 prompt，而是用 **目标 + 约束 + 验收标准 + 自检** 稳住输出，再用 hooks 把硬性规则锁死。

[![For](https://img.shields.io/badge/for-Claude%20Code-blue)](https://code.claude.com)
[![Model](https://img.shields.io/badge/model-Opus%204.8-orange)]()
[![License](https://img.shields.io/badge/license-MIT-green)](#license)

**Contents / 目录**: [TL;DR](#tldr) · [Why / 背景](#why--背景) · [The Model / 方法论](#the-model--方法论) · [Quick Start / 快速开始](#quick-start--快速开始) · [How CLAUDE.md Loads / 加载机制](#how-claudemd-loads--加载机制) · [Hard Enforcement / 硬性约束](#hard-enforcement-with-hooks--用-hooks-硬性约束) · [Pick the Right Layer / 选对工具层](#pick-the-right-layer--选对工具层) · [Per-Task / 每次任务](#per-task--每次任务) · [When to Use Fable 5 / 何时直接上-fable-5](#when-to-just-use-fable-5--何时直接上-fable-5) · [Verify / 验证与失败模式](#verify--验证与失败模式) · [Rationale / 设计依据](#rationale--设计依据) · [References / 参考](#references--参考) · [License](#license)

---

## TL;DR

**EN** — Paste the 6-rule block into `CLAUDE.md`, prefix each task with one style line, and gate the irreversible actions with a `PreToolUse` hook. That gets Opus 4.8 to *explore → model → ship → self-check* — close to how Fable 5 behaves, without paying Fable 5 rates for routine work.

**中文** — 把 6 条规则粘进 `CLAUDE.md`，每次任务前加一句执行风格，再用 `PreToolUse` hook 锁住不可逆操作。这样 Opus 4.8 会 *先探索 → 建模 → 交付 → 自检*，接近 Fable 5 的体验，又不必为日常任务付 Fable 5 的费用。

---

## Why / 背景

**EN** — Claude Fable 5 (released June 2026) is a Mythos-class model positioned **above** Opus 4.8, built for long-horizon, autonomous coding and knowledge work. Its notable trait: it explores the environment, figures out the files and constraints, then builds — without narrating much. Opus 4.8 is already a strong long-horizon coding model; it just isn't that autonomous by default. Explicit boundaries + verification push it there.

**中文** — Claude Fable 5（2026 年 6 月发布）是定位在 Opus 4.8 **之上** 的 Mythos 级模型，为长程、自主的 coding 与知识工作而造。它的特点是：先探索环境、摸清文件和约束、再开始构建，且很少长篇叙述。Opus 4.8 本身已是很强的长程 coding 模型，只是默认不那么"自主"——用明确边界 + 验证就能把它推过去。

> The point isn't to make the model *sound* smart — it's to make it *finish and verify*.<br>
> 精髓不是让模型显得聪明，而是让它**干完并自检**。

---

## The Model / 方法论

| Element / 要素 | Purpose / 作用 | Maps to / 对应 |
|---|---|---|
| **Goal** 目标 | State intent before touching code / 先说清要做什么 | Rule 1 |
| **Constraints** 约束 | Block scope creep & over-design / 防乱改、防过度设计 | Rule 2 |
| **Acceptance** 验收 | Non-experts can judge correctness / 不懂代码也能判断对错 | Rules 3–4 |
| **Self-check** 自检 | Catch breakage before delivery / 交付前自己抓错 | Rule 5 + style line |

---

## Quick Start / 快速开始

### 1) Put the rules in `CLAUDE.md` / 把规则放进 `CLAUDE.md`

**English version**

```text
Engineering task rules:
1. Read the project layout and relevant files before editing; first state in one line: the goal, which files you'll touch, and the risks.
2. Make one well-defined change at a time; do not refactor unrelated code, add features beyond the task, or introduce abstractions just to look "elegant".
3. After editing, report four things: which files changed / why / how to verify / any risks.
4. Run tests, lint, and build if possible; if not, say why and give manual verification steps.
5. Before delivering, self-review: did anything break existing behavior?
6. Always optimize for "runnable, maintainable, minimal diff" first.
```

**中文版本**

```text
工程任务规则:
1. 先读懂项目结构和相关文件再动手;先用一句话说清:目标、会改哪些文件、风险点。
2. 一次只做一个明确改动;不顺手重构、不加任务外功能、不为"更优雅"引入多余抽象。
3. 改完必须报告四件事:改了哪些文件 / 为什么这么改 / 怎么验证 / 有无风险。
4. 能跑就跑 test、lint、build;跑不了要说明原因,并给出可手动验证的步骤。
5. 交付前自查一遍:有没有破坏原有逻辑。
6. 始终以"能运行、好维护、改动最小"为最高目标。
```

**What each rule prevents / 每条防什么**

| Rule / 规则 | Prevents / 防止的问题 |
|---|---|
| Read first / 先读懂再动手 | Editing before understanding / 没看懂就乱改 |
| One change / 一次一个改动 | "Helpful" edits to unrelated code / 顺手改一堆无关代码 |
| Report 4 things / 报告四件事 | You can't tell if it's right / 你无法判断对错 |
| Run checks / 跑测试 | Eyeballing instead of machine-checking / 靠肉眼而非机器抓错 |
| Self-review / 交付前自查 | New code breaking old code / 新功能弄坏旧功能 |
| Minimal diff / 最小改动 | Complexity-for-show / 为显高级而复杂化 |

### 2) Prefix each task / 每次任务加一句

```text
EN: Run in "lightweight Fable 5" style: explore then model, do more / ask less, deliver a finished artifact, self-check at the end.
中文: 请按"轻量级 Fable 5 风格"执行:先探索再建模,少问多做,直接给可交付成品,最后自检。
```

### 3) Or clone this repo / 或直接克隆本仓库

**EN** — This repo ships the config as real files, not just snippets. Drop them into your project root:

**中文** — 本仓库把配置做成了真实文件，不只是片段。直接放进你的项目根目录即可：

```text
your-project/
├─ CLAUDE.md              # the 6 engineering rules / 6 条工程规则
└─ .claude/
   ├─ settings.json       # PreToolUse hook wiring / hook 接线
   └─ guard.sh            # blocks rm -rf, force-push (exit 2) / 拦截危险命令
```

```bash
# 30-second setup / 30 秒接入
cp CLAUDE.md  /path/to/your-project/
cp -r .claude /path/to/your-project/
chmod +x /path/to/your-project/.claude/guard.sh
# then open Claude Code there and run /hooks /memory to verify
# 然后在该目录打开 Claude Code,用 /hooks /memory 核对
```

---

## How CLAUDE.md Loads / 加载机制

**EN** — `CLAUDE.md` is **context, not enforced configuration** — the model usually follows it, but it isn't a hard lock. Know the loading rules before you rely on it:

**中文** — `CLAUDE.md` 是**上下文，不是强制配置**——模型通常会遵守，但不是硬锁。依赖它之前先搞清加载规则：

| Location / 位置 | Scope / 范围 | Loaded / 何时加载 |
|---|---|---|
| Root `CLAUDE.md` / 根目录 | Shared team conventions / 团队共享约定 | Walks up from cwd at session start / 启动时从工作目录向上逐级加载 |
| Subdir `CLAUDE.md` / 子目录 | Component-specific rules / 组件级规则 | Lazily, when files there are read / 读到该目录文件时才加载 |
| `CLAUDE.local.md` | Personal, gitignored / 个人,不提交 | Same as root, not shared / 同根目录,但不共享 |

> **Context budget / 上下文预算** — Models reliably follow ~150–200 instructions; Claude Code's own system prompt eats ~50. Keep a high-signal `CLAUDE.md` to **80–120 lines** — past that, rules start getting dropped. Run `/memory` to see what's actually loaded.<br>
> 模型可靠遵守约 150–200 条指令，Claude Code 自身系统提示占约 50 条。高信噪比的 `CLAUDE.md` 控制在 **80–120 行**，超出后规则会被丢弃。用 `/memory` 查看实际加载了什么。

---

## Hard Enforcement with Hooks / 用 Hooks 硬性约束

**EN** — For rules that must *never* be bypassed (no `rm -rf`, no force-push), don't rely on the prompt. Use a `PreToolUse` hook: **exit code 2 blocks the action**, exit 0 allows it. Config lives in `.claude/settings.json` (committed, team-shared) or `~/.claude/settings.json` (personal).

**中文** — 对绝不能被绕过的规则（禁止 `rm -rf`、禁止 force-push），别指望 prompt。用 `PreToolUse` hook：**退出码 2 拦截操作**，退出码 0 放行。配置放在 `.claude/settings.json`（提交、团队共享）或 `~/.claude/settings.json`（个人）。

`.claude/settings.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "./.claude/guard.sh" }
        ]
      }
    ]
  }
}
```

`.claude/guard.sh`  (`chmod +x`)

```bash
#!/usr/bin/env bash
# Read the pending tool call from stdin, block destructive commands.
# 从 stdin 读取待执行命令,拦截破坏性操作。
cmd="$(jq -r '.tool_input.command // empty')"
if printf '%s' "$cmd" | grep -Eq 'rm -rf|git push --force|git push -f'; then
  echo "Blocked by guard.sh: $cmd" >&2   # stderr is shown to the model / stderr 会回传给模型
  exit 2                                  # 2 = block / 拦截
fi
exit 0                                    # 0 = allow / 放行
```

> Use absolute paths in production and verify with `/hooks`. Exit **1** only logs a warning — every real guard must use exit **2**.<br>
> 生产环境用绝对路径，并用 `/hooks` 核对。退出码 **1** 只记录警告——真正的拦截必须用退出码 **2**。

---

## Pick the Right Layer / 选对工具层

| Need / 需求 | Use / 用 | Why / 原因 |
|---|---|---|
| Steer behavior, conventions / 引导行为、约定 | `CLAUDE.md` | Soft, cheap, readable / 软约束、低成本 |
| Auto-format / lint after edits / 改完自动格式化 | `PostToolUse` hook | Runs after success / 成功后触发 |
| Truly block an action / 真正阻止某动作 | `PreToolUse` hook (exit 2) | Cannot be bypassed / 无法绕过 |
| Coarse allow / ask / deny / 粗粒度许可 | `permissions` in settings | Simpler than a script / 比脚本简单 |

---

## Per-Task / 每次任务

| Scenario / 场景 | Add this line / 补这一句 |
|---|---|
| Slides / 长图 PPT | EN: *Output a presentation-ready version — structure, copy, colors — not an outline.*<br>中文：直接产出可演示成品版，结构、文案、配色都给全，不要只给提纲。 |
| Report / 报告 | EN: *Deliver a complete, client-ready report: conclusion first, key points, sources.*<br>中文：输出可直接交付的完整报告，结论先行、要点、数据来源。 |
| Analysis / 投资·数据分析 | EN: *Model first, then conclude; list assumptions, key numbers, risks.*<br>中文：先建模再给结论，列出假设、关键数字、风险。 |
| Agent project review / 评估 Agent 项目 | EN: *Give an actionable call: do it or not, why, key risks, minimal validation.*<br>中文：给出可执行判断：做不做、为什么、关键风险、最小验证方案。 |

---

## When to Just Use Fable 5 / 何时直接上 Fable 5

**EN** — Prompting Opus 4.8 well covers most day-to-day work. Reach for Fable 5 when the task is **genuinely long-horizon and underspecified** — large migrations, multi-day autonomous sessions, exploring an unfamiliar codebase before building. For renaming variables, small helpers, or stack-trace explanations, Fable 5 is overkill and Opus 4.8 is the better cost/latency choice.

**中文** — 把 Opus 4.8 调好，足以覆盖绝大多数日常工作。当任务**真的是长程且需求不明确**——大型迁移、多日自主会话、先探索陌生代码库再构建——再上 Fable 5。改变量名、写小工具、解释报错栈这类，Fable 5 属于杀鸡用牛刀，Opus 4.8 在成本/延迟上更划算。

---

## Verify / 验证与失败模式

| Symptom / 现象 | Likely cause / 可能原因 | Fix / 处理 |
|---|---|---|
| Rules ignored / 规则被忽略 | Nested `CLAUDE.md` not loaded / 嵌套文件未加载 | Run `/memory` / 用 `/memory` 检查 |
| Drops rules randomly / 偶尔丢规则 | File too long / 文件过长 | Trim to 80–120 lines / 精简到 80–120 行 |
| Still runs blocked cmd / 仍执行被禁命令 | Hook used exit 1 / hook 用了退出码 1 | Switch to exit 2 / 改成退出码 2 |
| Over-refactors / 过度重构 | Style line missing / 漏了执行风格句 | Re-add per-task prefix / 补回任务前缀 |

---

## Rationale / 设计依据

**EN** — Three evidence-based corrections behind this guide:
1. **No "smart-sounding" filler.** Official guidance: specific + concise instructions are followed more reliably; lines like "think step by step" / "act as a senior engineer" don't prevent concrete mistakes because the model already does them.
2. **Keep `CLAUDE.md` short.** Practical ceiling for a high-signal file is ~80–120 lines before rules get dropped.
3. **It's guidance, not a lock.** `CLAUDE.md` is treated as context; to truly block an action, use a `PreToolUse` hook and keep human spot-checks on critical steps.

**中文** — 本指南背后三处基于证据的修正：
1. **去掉"显聪明"的废话。** 官方指出：具体 + 简洁的指令被更稳定地遵守；"think step by step""当资深工程师"这类话防不了具体错误，因为模型本就在做。
2. **`CLAUDE.md` 要短。** 高信噪比文件实际上限约 80–120 行，超出就开始丢规则。
3. **它是引导不是硬锁。** `CLAUDE.md` 被当作上下文；要真正阻止某动作得用 `PreToolUse` hook，并对关键步骤保留人工抽查。

---

## References / 参考

- Anthropic — Claude Fable 5 / Mythos 5: <https://www.anthropic.com/news/claude-fable-5-mythos-5>
- Anthropic — Claude Fable: <https://www.anthropic.com/claude/fable>
- Claude Code Docs — Memory & CLAUDE.md: <https://code.claude.com/docs/en/memory>
- Claude Code Docs — Hooks reference: <https://code.claude.com/docs/en/hooks>
- GitHub Changelog — Fable 5 on Copilot: <https://github.blog/changelog/2026-06-09-claude-fable-5-is-generally-available-for-github-copilot/>

> Models and policies change fast / 模型与政策更新较快 — defer to the official links above before publishing.

---

## License

MIT. Free to copy, modify, redistribute / 自由复制、修改、再分发。

**Disclaimer / 免责声明** — Community guide, not official Anthropic documentation. "Claude", "Opus", and "Fable" are trademarks of Anthropic. / 社区性质整理，非 Anthropic 官方文档；相关名称为 Anthropic 商标。
