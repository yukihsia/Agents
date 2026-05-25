# Agents

Curated AI agent collection for **OpenClaw** and **Claude Code**, fork-curated from [`agency-agents-zh`](https://github.com/...) with personal selections.

94 role-based domain expert agents covering finance, engineering, design, product, marketing, legal, and more.

## Repo layout

```
.
├── openclaw/          # OpenClaw format (1 dir per agent, 6 .md files)
│   ├── finance-investment-researcher/
│   │   ├── IDENTITY.md     # 中文身份 + 简短描述
│   │   ├── AGENTS.md       # Session 启动流程 + heartbeat 协议
│   │   ├── SOUL.md         # 性格、关键规则、沟通风格
│   │   ├── TOOLS.md        # 可用工具与边界
│   │   ├── HEARTBEAT.md    # 心跳任务配置
│   │   └── USER.md         # 用户信息模板
│   ├── engineering-feishu-integration-developer/
│   └── ... (94 total)
│
├── agents/            # Claude Code single-file format with YAML frontmatter
│   ├── finance-investment-researcher.md
│   ├── engineering-feishu-integration-developer.md
│   └── ... (94 total)
│
└── README.md
```

## Categories (94 agents total)

| Category | Count | Examples |
|---|---|---|
| `engineering-*` | 28 | feishu-integration / ai-engineer / backend-architect / git-workflow / data-engineer |
| `marketing-*` | 11 | daily-news-briefing / douyin / cross-border-ecommerce / xiaohongshu (operator + specialist) / zhihu |
| `design-*` | 8 | brand-guardian / ui-designer / ux-architect / ux-researcher |
| `finance-*` | 8 | investment-researcher / financial-analyst / fpa-analyst / tax-strategist |
| `testing-*` | 2 | tool-evaluator / workflow-optimizer |
| `specialized-*` | 7 | mcp-builder / chief-of-staff / meeting-assistant / document-generator |
| `project-*` | 6 | project-shepherd / studio-producer / sprint-prioritizer |
| `product-*` | 5 | product-manager / feedback-synthesizer / trend-researcher |
| `support-*` | 2 | analytics-reporter / executive-summary-generator |
| `legal-*` | 3 | contract-reviewer / document-review / policy-writer |
| `academic-*` | 3 | historian / narratologist / psychologist |
| game dev (general) | 5 | game-designer / game-audio-engineer / level-designer / narrative-designer / technical-artist |
| translator | 2 | language-translator / technical-translator-agent |
| 单点 | ~14 | zk-steward (Zettelkasten) / prompt-engineer / agents-orchestrator / mcp-builder ... |

## Installation

### For OpenClaw

```bash
# 1. Clone or pull
git clone git@github.com:yukihsia/Agents.git ~/projects/agents

# 2. Copy openclaw format into ~/.openclaw/agency-agents/
cp -r ~/projects/agents/openclaw/* ~/.openclaw/agency-agents/

# 3. Register each in openclaw.json agents.list (or use the openclaw CLI)
#    Each entry shape:
#    { "id": "<agent-name>", "name": "<agent-name>", "workspace": "...",
#      "agentDir": "/Users/<you>/.openclaw/agents/<agent-name>", "model": "..." }
```

### For Claude Code

```bash
# Single-file agents are loaded from ~/.claude/agents/
mkdir -p ~/.claude/agents
cp ~/projects/agents/agents/*.md ~/.claude/agents/

# Restart Claude Code or call /agents to confirm they're discovered.
```

Note: Claude Code single-file agents use YAML frontmatter:
```yaml
---
name: <agent-slug>
description: <when to use this agent>
---
```
plus a markdown system prompt body. Inherits no tools by default — adjust the frontmatter to add `tools:` if you want a restricted toolset.

## Source

These agents originated from the open-source `agency-agents-zh` repository (Chinese role-based agent collection), filtered down from ~215 to 94 based on relevance:

- Removed: vertical-specific (real estate, healthcare, hospitality, gaokao, etc.), HR/recruitment, B2B sales, paid advertising, supply chain, embedded/IoT/hardware, Web3/blockchain, game engine development (Unity/Unreal/Godot/Roblox/XR), Apple native dev, DingTalk integration, Filament PHP, redundant duplicates.
- Kept: anything potentially useful for investment / fund management / game industry research / Feishu automation / general engineering / design / product / project management.

## License

Per upstream `agency-agents-zh` license (likely MIT, verify upstream).
