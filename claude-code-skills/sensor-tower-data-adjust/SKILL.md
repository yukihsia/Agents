---
name: sensor-tower-data-adjust
description: "Use when the user wants to apply the in-house investment-evaluation adjustment formulas to a Sensor Tower export (Downloads / Revenue / DAU / RPD / ARPDAU recalibration with CN region uplifts), OR run the first-year per-game extraction workflow (launch-date web verification → first 12 months filter → adjust → Excel with Incomplete flag). Triggers: 'ST 数据口径调整 / 调整 Sensor Tower 源数据 / Sensor Tower 数据处理 / 处理 ST 数据 / 投资估值口径调整 / sensor tower adjust / ST adjust / 中国区下载量*4 / 收入除以0.7 / 重算 RPD ARPDAU / 上线首年数据 / 截取首年 / first-year ST data / 按上线月切 12 月 / 多游戏首年横评'. Reads a Sensor Tower CSV/TSV (auto-detects UTF-8 / UTF-16 and tab / comma) and writes a multi-sheet Excel."
---

# Sensor Tower 数据投资口径调整

本 skill 支持两种模式：

- **A. 整份调整** (`build.py`) — 整张 ST 表全部按口径调整，输出 Excel。
- **B. 上线首年模式** (`first_year_workflow.py`) — 多游戏横评的标准流程：先联网核验每款游戏全球上线月、用户确认后按 launch month + 11 月截取首年，再跑 A 的口径调整，并在「按App汇总」sheet 加 `Months_Covered` / `Incomplete` 标记（不足 12 月的游戏整行染红）。

两种模式共用下面的口径表。

## 何时调用

用户想把一份 **Sensor Tower 导出** 的 App 数据按公司内部投资评估口径修正，再拿去做估值/对比/汇报。规则是固定的：

| 字段 | Country/Region == CN | 其他地区 |
|---|---|---|
| `Downloads_adj` | `Downloads × 4` | `Downloads`（不变） |
| `Revenue_adj ($)` | `Revenue / 0.7 × 2.2` | `Revenue / 0.7` |
| `DAU_adj`（如有 DAU 列） | `DAU × 3` | `DAU`（不变） |
| `RPD_adj ($)` | `Revenue_adj / Downloads_adj` | 同左 |
| `ARPDAU_adj ($)`（如有 DAU 列） | `Revenue_adj / DAU_adj` | 同左 |

口径含义：
- `/0.7`：还原 Apple/Google 平台 30% 分成。
- CN 区的 `×4 / ×2.2 / ×3`：基于 ST CN 区数据系统性偏低的经验值上修。

## 不要用本 skill 当

- 用户要做的是模型搭建（用 `pc-game-seq-model` / `pc-game-par-model` / `pc-game-fundpriority-model`）。
- 用户要校验已有 Excel 投资模型（用 `excel-finance-checker`）。
- 数据不来自 Sensor Tower，列名差异巨大（先帮用户人肉对齐再说）。

## 输入

Sensor Tower 导出的 CSV/TSV。脚本会自动识别：

- **编码**: UTF-16 LE / UTF-8 / UTF-8-BOM
- **分隔符**: Tab / Comma
- **关键列**（容忍空格 / 大小写 / 标点差异）:
  - `Country / Region` (或 `Country/Region`, `Country`)
  - `Downloads`
  - `Revenue ($)` (或 `Revenue`)
  - `DAU` (可选；存在时自动启用 DAU/ARPDAU 调整)

其他列原样保留。

## 输出

Excel 文件，3 张 sheet：

| Sheet | 内容 |
|---|---|
| **明细** | 原始所有列 + `Is_CN` + `Downloads_adj` + `Revenue_adj ($)` + `RPD_adj ($)` (+ `DAU_adj` + `ARPDAU_adj ($)` 如有 DAU) |
| **按App汇总** | 按 `Unified Name` (或 `App Name`) 聚合：sum Downloads_adj / sum Revenue_adj / 加权 RPD_blended / 行数；按 Revenue_adj 降序 |
| **按地区汇总** | 按 `Country / Region` 聚合：同上 |

数字格式：Downloads 千分位整数；Revenue/$ 千分位 2 位小数；RPD/ARPDAU 4 位小数。所有 sheet 第一行冻结。

## 调用步骤（模式 A：整份调整）

1. **必须先确认 Python 依赖** —— 脚本依赖 `pandas` 和 `openpyxl`。如果用户系统是 macOS 自带 Python 3.9，可能没装。先试跑：

   ```bash
   python3 -c "import pandas, openpyxl" 2>&1
   ```

   若报错，建一个 venv：

   ```bash
   python3 -m venv ~/.claude/skills/sensor-tower-data-adjust/.venv
   ~/.claude/skills/sensor-tower-data-adjust/.venv/bin/pip install --quiet pandas openpyxl
   ```

   后续用这个 venv 的 python 跑（路径 `~/.claude/skills/sensor-tower-data-adjust/.venv/bin/python`）。

2. **跑脚本**：

   ```bash
   python3 ~/.claude/skills/sensor-tower-data-adjust/scripts/build.py "<input_csv>" ["<output_xlsx>"]
   ```

   - `<input_csv>` 必填。
   - `<output_xlsx>` 可选，默认在输入同目录、文件名加 `_adjusted.xlsx`。

3. **核对控制台 QA 输出**：脚本会打印
   - 总行数 / 检测到的列名映射 / 是否检测到 DAU
   - CN 行数
   - 按地区合计（Downloads_adj / Revenue_adj / RPD_blended）
   - Top 5 App（按 Revenue_adj）
   - Revenue 调整后/原始 比率（**没有 CN 时应约等于 1.4286 = 1/0.7**；有 CN 时会更高）
   - Downloads 调整后/原始 比率（**没有 CN 时应 = 1.0**；有 CN 时 > 1）

4. **打开 Excel** 让用户人工 review：

   ```bash
   open -a "Microsoft Excel" "<output_xlsx>"
   ```

## 调用步骤（模式 B：上线首年模式）

用于「多游戏首年横评」场景：用户给一份含多款游戏的 ST 数据，想按每款游戏 launch month 起截取首年 12 月，跑口径调整后做横评。

### 核心原则

- **联网核验必须在脚本前完成**（脚本只接受 JSON 配置，不联网）。
- **永远先呈现 Markdown 表格 + 权威 URL 给用户确认**，再写 launches.json。绝不要自作主张直接用知识库里的日期跑。
- 不足 12 月的游戏（如刚上线的）默认 **保留 + 加 Incomplete=Y 标记**，不要 silent drop。

### 步骤

**Step 1: 探查 CSV，列出所有游戏**

```bash
~/.claude/skills/sensor-tower-data-adjust/.venv/bin/python -c "
import pandas as pd
df = pd.read_csv('<input.csv>', encoding='utf-16', sep='\t')
for name, g in df.groupby('Unified Name'):
    print(f'{name}: rows={len(g)}, first_date={g[\"Date\"].min()}, last_date={g[\"Date\"].max()}')
"
```

记下每款游戏的 CSV 首月，后面要和联网核验的「全球上线月」交叉验证。

**Step 2: 并行联网核验每款游戏的全球上线日期**

对每款游戏并行用 `WebSearch`（一条消息多个 tool calls）查询，prompt 形如：
> `<game name> global release date launch <year>`

倾向用 Wikipedia / Games Press / Game8 / 官方公告 / IGN / Polygon 作为来源。
- 优先「全球上线」日期；若用户先前明确要 CN 上线则用 CN。
- CSV 首月应 = 核验的上线月，若不一致 flag 出来让用户决定。

**Step 3: 呈现 Markdown 确认表给用户**

格式：

```markdown
| 游戏 | 全球上线日期 | 上线月 | 来源 | CSV 首月 | 一致? |
|---|---|---|---|---|---|
| Genshin Impact | 2020-09-28 | 2020-09 | [Wikipedia](url) / [Game8](url) | 2020-09 | ✓ |
| ... | | | | | |
```

同步标注哪些游戏会是 `Incomplete=Y`（首年取不满 12 月的）。**等用户回复「go / 确认」再进 Step 4**。

**Step 4: 写 launches.json**

放在输入 CSV 同目录或 skill 临时目录都行。格式：

```json
{
  "window_months": 12,
  "launches": {
    "Genshin Impact": "2020-09-28",
    "Honkai: Star Rail": "2023-04-26"
  }
}
```

- key 必须**字符精确等于** CSV 里的 Unified Name（注意全角符号、空格、特殊后缀如 `- 2nd Anniv.`）。
- value 用「全球上线日期」字符串（脚本会 floor 到月初）。
- `window_months` 可选，默认 12。

**Step 5: 跑首年工作流脚本**

```bash
~/.claude/skills/sensor-tower-data-adjust/.venv/bin/python \
  ~/.claude/skills/sensor-tower-data-adjust/scripts/first_year_workflow.py \
  "<input.csv>" "<launches.json>" ["<output.xlsx>"]
```

输出默认在输入同目录，文件名加 `_首年_adjusted.xlsx`。

**Step 6: 控制台 QA + 抽查 Excel**

脚本会打印每款游戏取到的月数 / 行数 / Incomplete 状态。检查：
- 总行数 = sum(每游戏 rows)
- `Incomplete=Y` 的游戏数 = 你 Step 3 标注的数
- CN 行数 > 0（如果输入数据含 CN）
- Revenue 调整后/原始 > 1.4286 当有 CN 时（CN ×2.2 上修）
- 抽 1 条 CN 行手算 `Downloads_adj = orig × 4`, `Revenue_adj = orig / 0.7 × 2.2`

Excel `按App汇总` sheet 末两列会是 `Months_Covered` 和 `Incomplete`，Incomplete=Y 的行**整行染红**便于一眼识别。

## 常见排查

- **读 CSV 报编码错** → 检查文件实际编码：`file <path>`。Sensor Tower 默认导 UTF-16 LE TSV（即便扩展名是 .csv）。
- **找不到 Country / Revenue 列** → 脚本会列出实际列名，让用户确认列名变体（如 `Revenue (USD)`、`Country Code`）；改 `find_col()` 的 candidates 列表。
- **Revenue 调整比率 < 1.4286** → 数据里有 `Revenue` 为负或为空的行（异常），需先排查源数据。
- **CN 行数与预期不符** → ST 有时用 `China` 而非 `CN`；脚本可在 `CN_CODES` 里加同义码。
- **首年模式：launches.json 里某游戏被 silent skip** → 控制台会打 `[skip] '...' not in launches.json — dropped`。检查 launches.json 的 key 是不是和 CSV 里 Unified Name 字符精确一致（注意 ST 偶尔会给游戏名加 `- 2nd Anniv.` 之类的后缀）。
- **首年模式：CSV 首月 ≠ 联网核验上线月** → 通常是 ST 把上线前的 beta 数据也归到这个 App 下，或者 App 改名后历史数据被合并。需要让用户决定是按 CSV 首月还是核验上线月切。

## 本 skill 不做的事

- 不改公式系数（×4 / ×2.2 / ×3 / ÷0.7 是写死的口径）。如果哪天要调，编辑 `scripts/build.py` 顶部常量后重跑。
- 不做时间序列趋势 sheet、不出图表（如需，再单独开 skill）。
- 不动源 CSV。
