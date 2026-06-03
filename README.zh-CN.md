🌐 [English](README.md) · **中文**

# docs-discipline

**给你的 AI 项目一份能跨 session 存活的记忆。**

![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-7C3AED)
![Version](https://img.shields.io/badge/version-0.7.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)

每开一个新的 AI 编程 session，都是从零开始。上一次的决策、踩过的坑、那句*“我们做到哪了？”*——全没了。与此同时，你的文档还在悄悄和代码脱节。在长周期、探索型的工作里，这尤其要命：每个 session 你都要花头二十分钟，重新把上次 agent 早就想明白的上下文再讲一遍。

**docs-discipline 把每个 session 的收尾，变成一个 60 秒的仪式。** 一条命令——`/docs-discipline:codify`——把这次 session 学到的东西沉淀成持久的文档，顺手做一遍漂移体检，再（可选）写一份交接，让*下一个* session 能从你离开的地方接着干。

---

## 为什么你会想用它

- 🧠 **跨 session 的记忆。** 发现和决策会以真实文件的形式落进你的仓库——于是新 session 是在*续上*上一个，而不是从头再来。这就是它的核心价值。
- 🔔 **它会主动提醒你。** 初始化时会在你的 `CLAUDE.md` 里写入一行习惯锚点，于是你的编程 agent 会在 session 收尾时自己提议这个仪式。无需配置，也不用你记着。
- ⏱️ **一条命令收尾整个 session。** codify → 自动文档体检 → 可选交接计划，一趟走完。
- 🛰️ **漂移雷达。** 揪出失效链接、过期时间戳、没人引用的孤儿文档，以及同一个“事实”在五个地方各说一遍——这正是文档开始撒谎的根源。
- 🪶 **零绑定。** 没有模板，不强制目录结构。它永远不会偷偷改写你的文档——它只*提议*，由你拍板。每一次写入都归你掌控。
- 🎯 **为最需要它的工作而生。** 跨周的 spike、调研、架构设计——这些大颗粒、探索型的任务里，session 之间断了线，代价最大。

> 那个“魔法时刻”：你收掉一个 session，一周后开一个全新的，你的 agent 已经知道当初定了什么、什么做了一半、下一步是什么——因为这些都写下来了，而不是困在那个早已消失的上下文窗口里。

## 快速上手（30 秒）

Claude Code 通过 marketplace 安装插件。这个仓库本身就是一个单插件 marketplace，所以两条命令即可装好：

```
/plugin marketplace add circlecrystal/docs-discipline
/plugin install docs-discipline@docs-discipline
```

（`<plugin-name>@<marketplace-name>`——这里两者恰好都叫 `docs-discipline`。）

然后，在每个 session 收尾时，运行：

```
/docs-discipline:codify
```

就这样。第一次运行会自动把你的项目初始化好（见下方 Phase 0）——没有额外的 init 步骤。

之后要更新：

```
/plugin marketplace update docs-discipline
```

## 一个核心思路：A/B 分层

几乎所有文档漂移都只有一个根因：**昨天那条“当时如此”的笔记，被当成了今天的事实来读。** docs-discipline 的解法，是把你的文档分成两层。

- **A 层——制品（artifacts）。** 不可变、带日期。一次写成，之后永不修改。每一篇都记录某个时间点的发现、决策或 session 产出（一份 ADR、一份 spike 报告、一条调研笔记）。
- **B 层——SSOT（唯一事实源）。** 一小撮持续维护的“当前状态”文档（README、状态页、路线图）。B 层的每一条断言，都回指向支撑它的那篇 A 层制品。

一旦 A 和 B 分开，漂移就从“看不见”变成“一眼看穿”：某条“当前状态”和它带日期的源头对不上时，会格外扎眼。整个心智模型就这么简单——而且它是通用的。至于 A 和 B 在*你的*项目里**长什么样**（路径、命名、约定），完全由你定；插件不做任何假设。

## 命令

两条命令。**`codify`** 是你每个 session 都跑的唯一入口——它自举初始化、沉淀、体检，并提议交接。**`review`** 是一个独立的随手体检（也会在 codify 里被自动跑一遍）。没有单独的 `/init`——codify 把初始化吸收成了它的 Phase 0。

### `/docs-discipline:codify`

在每个 session 收尾时运行。自举、幂等，而且**绝不静默写入**——它按顺序跑四个阶段：

- **Phase 0 —— 初始化（自动）。** 首次运行时把项目装好：缺 `CLAUDE.md` 就创建一个最小版（一段简短的 docs-discipline 声明 + 两个空的 A/B 槽位）；已有 `CLAUDE.md` 则只追加那段声明块，不动你原有的治理内容。把 `drift-check.sh` 拷进 `scripts/`。如果项目已经装好，它只说一句“已初始化”就过。它始终如实汇报：创建了什么、追加了什么、拷贝了什么、跳过了什么。
- **Phase 1 —— 沉淀。** 读取你的 A/B 地图，观察你的文档结构，产出一份清单：这次 session 的发现该落到哪里——分类为 A（新的不可变制品）或 B（SSOT 更新），每条都附一段具体的 diff 草图。如果 A/B 槽位是空的，它只问**一次**——填进去（推荐）、仅本次使用建议、或直接跳过。要应用、部分应用、全跳过、还是把这次标记为探索型 session，都由你定。没有你的点头，什么都不会被写入。
- **Phase 2 —— 体检（自动）。** 紧接着进入文档健康体检（漂移 + SSOT + 一屏小结）。它总会跑，且只做分诊（triage）——只把候选项摆出来，绝不自动修。
- **Phase 3 —— 交接（可选）。** 提议写一份自包含的交接文档——目标、决策、当前状态、下一步、各种指针——让你能在新 session 里接着干。它会问你放哪，不强加位置。随时可以拒。

### `/docs-discipline:review`

一个随时可跑的文档健康体检，有没有 session 改动都行。它读取你的 A/B 地图，跑漂移扫描，做一遍 SSOT 一致性检查，并打印一屏小结。按意图自适应：

- **`/docs-discipline:review`** → 全面体检（A/B 状态 + 漂移 + SSOT + 结构）
- **`/docs-discipline:review for drift`** → 仅漂移扫描
- **`/docs-discipline:review A/B`** → 仅 A/B 评估 + 补缺
- **`/docs-discipline:review SSOT`** → 仅 SSOT 一致性扫描

**SSOT 扫描**会找出那些散落在多个 B 层文件里、被反复陈述的原子事实——状态、版本号、决策、进度数字。同一个事实出现在多处，意味着某次修改迟早会漏掉一处；漂移就是这么诞生的。它把候选项摆出来、标出不一致；**由你**判断哪些是有意的复述、哪些是真漂移，以及哪个文件才是权威源。

## 设计原则

**像 `git`，而不像 `create-react-app`。** 这个插件只给你原语，加上唯一一条共识——*持久文档受益于把不可变制品（A）和活的 SSOT（B）分开*——然后就让开，不挡你的路。

**它*主张*的：**

- ✅ 一个习惯锚点：“在每个 session 收尾时运行 `/docs-discipline:codify`”
- ✅ A/B 分层作为一条通用原则
- ✅ 当项目缺了某一层或两层时，它能察觉，并温和地提议补上
- ✅ 通用的漂移检测（失效链接、过期时间戳、孤儿文档、重复 H1）

**它*不主张*的：**

- ❌ **不**假设你的 A/B 层放在特定路径或遵循特定命名
- ❌ **不**附带 SSOT 地图、状态符号体系、治理白皮书或文档模板
- ❌ **不**提供参考范例——范例会隐性地强加结构
- ❌ **不**逼你填 A/B。“暂时跳过”永远是一个选项。

**硬约束。** 这个插件不会长出模板、范例，或关于 A/B 在你项目里*该长什么样*的意见。它唯一的意见是：A/B 这个模式是通用的。除此之外，你的项目是你的项目。

## 自动化（CI / cron）

漂移结论来自 `scripts/drift-check.sh`——一个确定性的、可脚本化的接口（失效链接、过期时间戳、孤儿文档、重复 H1；返回退出码 + stdout）。纯 CI 或每周 cron 场景，直接调它即可，无需 agent。

## 许可

MIT © Wang Heng · [github.com/circlecrystal/docs-discipline](https://github.com/circlecrystal/docs-discipline)
