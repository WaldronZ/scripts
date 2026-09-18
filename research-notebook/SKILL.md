---
name: research-notebook
description: "单文件 HTML 研究笔记本的建站与写作规范：多页静态站点（index.html 目录页 + 每章一个独立 HTML）、内联 CSS 设计系统（琥珀主色、本章摘要框、节色条、卡片、KV 表、流程链、callout、状态徽章、分数条、样例框）、图片处理约定（框架图一律手写内联 SVG、论文截图等位图一律 base64 内嵌）、实验台账（EXP-xxx）与章摘要写作约定。用户让你新建研究笔记本、给笔记本新增章节/实验台账/调研页、把研究进展或论文分析整理成 HTML 页面、或复刻某个已有笔记本（如 omni-agent）的样式风格时使用。"
---

# Research Notebook —— 单文件 HTML 研究笔记本

把一项研究（论文复现、benchmark 调研、方法拆解、实验台账、idea 选型、进展汇报）整理成一套**多页静态 HTML 笔记本**。原型：`~/Desktop/omni-agent/`（OmniAgent 研究笔记本，7 章）。

核心特征：**每个 HTML 单文件自包含**——CSS 全部内联 `<style>`、零外部依赖、零 JS、图片要么手写内联 SVG 要么 base64 内嵌，双击即可在浏览器阅读，可整目录拷走/同步 OSS 镜像。

## 何时使用

- 开展新研究项目，要建一个可持续更新的研究笔记本；
- 给已有笔记本新增章节（调研 / benchmark / 方法拆解 / 实验台账 / idea 选型 / 进展汇报）；
- 把实验记录、调研结论、论文分析整理成可浏览的 HTML 页面；
- 用户说「整理成笔记本」「做成 HTML 页面」「复刻 omni-agent 那种风格」。

## 站点架构

```
<项目目录>/
  index.html        ← 目录页（唯一入口）
  <chapter>.html    ← 每章一个独立页，小写下划线命名（benchmarks / methods / experiments / models_survey / ideas / data_survey / progress）
```

- **index.html**：kicker「RESEARCH NOTEBOOK」+ h1 + sub（论文/代码/数据/路径链接行）→ `.vision` 研究愿景框 → `.glance` 项目一页知 + `.assets` 资源清单 → 章节目录（每章一张 `a.chapter` 卡片：`.num` 第 N 章 / h3 标题+`点击进入 →` / `.sum` 摘要 / `.tags` 数字标签）→ footer（**维护约定** + 更新日期）。规划中章节用 `a.chapter.soon`（虚线半透明，不可点）。
- **章节页骨架（顺序固定）**：`nav.topnav`（← 返回目录 + 面包屑）→ `header`（h1 + sub 出处）→ **`.chsummary` 本章摘要（每章必有）** → 若干 `h2.sec` 节 → `footer`（返回链接 + 出处/维护约定 + 「第 N 章 · 更新日期：YYYY-MM-DD」）。
- 维护约定（写进 index footer 并真的遵守）：**新增内容 = 新增一章独立 HTML（带本章摘要 + 返回目录链接），并在 index 登记卡片**；每次改动刷新相关页的更新日期。

## 快速开始

1. `templates/index.html` → 新项目 `index.html`，替换 `{{...}}` 占位符。
2. 每加一章：`templates/chapter.html` → `<chapter>.html`，替换占位符、按需删留示例组件、填内容；回 `index.html` 登记一张 `.chapter` 卡片并刷新两处更新日期。
3. 章节页 CSS 已按组件分组并带注释，**用不到的组件整块删掉**（原型各页也只保留自己用的组件）；但设计令牌（`:root` 变量、body、wrap、topnav、header、chsummary、footer）不动。
4. 宽表页（如实验台账）把 `.wrap` 的 `max-width` 从 1080px 改成 1180px（模板里有注释标明）。

## 设计令牌（所有页面一致）

```css
:root {
  --c-main: #b45309;  /* 琥珀主色：kicker/摘要框/公式强调 */
  --c-s1: #2563eb;    /* 蓝 */  --c-s2: #7c3aed;    /* 紫 */
  --c-s3: #059669;    /* 绿 */  --c-s4: #dc2626;    /* 红 */
  --bg: #f8fafc; --card: #ffffff; --ink: #1e293b; --ink2: #64748b; --line: #e2e8f0;
}
body { font-family: -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif; line-height: 1.7~1.75; }
.wrap { max-width: 1080px; margin: 0 auto; padding: 24px 20px 80px; }  /* 宽表页 1180px */
```

头部固定：`<html lang="zh-CN">` + UTF-8 + viewport；`<title>` 格式「第 N 章 · 标题 — 项目名研究笔记本」（目录页直接「项目名研究笔记本」）。

## 组件速查（完整 CSS 见 templates/chapter.html，全部内联）

| 组件 | 用法与约定 |
|---|---|
| `.chsummary` | **本章摘要，每章必有**。琥珀渐变框（`linear-gradient(135deg,#fffbeb,#fef3c7)` + `#fde68a` 边），h2 色 `#92400e`，`li::before` 自动 ▸。摘要必须**自足且数字密集**：不读正文也知道本章结论，关键数字（n、Δ、p 值、耗时）直接写进来。 |
| `h2.sec.s1~s4` + `.secdesc` | 节标题，左 5px 色条按 s1蓝→s2紫→s3绿→s4红循环；`.secdesc` 是节下灰色出处/说明行（论文 §、代码路径）。 |
| `.card` | 白色圆角 12px 内容卡，正文基本单位；宽表格卡片加 `overflow-x:auto`。 |
| `table.kv` / 裸 `table` | KV 表用于参数/对照；实验台账等宽表用裸 table + `th` 灰底。复现对照行用 `tr.repro`（黄底）；分组隔行 `tr.grp`；最优行 `tr.best`（绿底）。 |
| `.flow` | 流程链：`.node.n1~n4`（顶边色循环）+ `.arrow`（→），适合 ≤6 节点的简单流程；复杂流程用 SVG。 |
| `.callout` | 警示/结论框：默认琥珀，变体 `.blue/.red/.green`。关键结论、客观性说明、口径警告用它。 |
| `details.fld` | **可折叠 callout**：长篇决策记录/诘问固化默认折叠（summary ▸/▾ 自动切换），保持正文流干净。变体 `.blue/.green`。 |
| `.pill` / `.ibadge` | 小标签（默认红、`.blue` 蓝）用于挂局限/证据编号；`.ibadge` 大徽章（默认紫，`.g/.b/.r` 变体）用于 Idea/Thesis 编号标题。 |
| `.tag.pos/.neg/.mid/.no` | 结果定性小方签：正绿 / 负红 / 中琥珀 / 无灰。 |
| `.st.*` | 实验状态徽章（胶囊）：`planned` 灰 / `submitted` 蓝 / `running` 黄 / `done` 绿 / `failed` 红。 |
| `.formula` | 等宽公式块（SF Mono），行尾 `<span class="tag">// 注释</span>` 标出处；公式用 `<sub>` 下标，不引 MathJax。 |
| `pre.codebox` | 深色代码/JSON 块（`#0f172a` 底），关键片段 `<span class="hl">` 高亮。 |
| `.score` 分数条 | `.bar-row > .lbl + .track > .fill.agent（琥珀→红渐变）/.fill.base（灰）+ .val`，尾部 Δ 行用 `.delta`（绿）。用于 benchmark 分数对比。 |
| `.sample` | 虚线样例框：`.tag`（来源标注，如「论文附录 D 原样例」「示意样例（按数据集格式构造）」）+ `.q` 题干 + `.opts`（正确项 `.ans` 绿 ✓）+ `.note` 解读。 |
| `.svgbox` + `.figcap` | SVG 容器卡（`overflow-x:auto`）+ 图题「图 N · 说明」（居中小字，紧跟图后）。 |

## 图片处理（两条硬规则）

### 规则一：示意图 / 框架图 / 流程图 = 手写内联 SVG，不用任何绘图工具产物

```html
<div class="svgbox">
<svg viewBox="0 0 1040 H" width="100%" style="min-width:900px"
     font-family="-apple-system,'PingFang SC','Microsoft YaHei',sans-serif">
  <defs><!-- 每种颜色一个箭头 marker --></defs>
  ...
</svg>
</div>
<p class="figcap">图 N · 一句话说清这张图怎么看。</p>
```

约定（与页面令牌同色系，抄自模板示例）：

- 画布 `viewBox="0 0 1040 H"`（高按内容定），`width:100%` + `min-width:900px`（窄屏横向滚动不变形）。
- 箭头在 `<defs>` 里每色定义一个 marker：`viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"`，path `M0,0 L10,5 L0,10 z`，fill 用六色之一：琥珀 `#b45309` / 蓝 `#2563eb` / 绿 `#059669` / 紫 `#7c3aed` / 红 `#dc2626` / 灰 `#64748b`。
- 组件框：圆角 rect（`rx="8~10"`），浅底 + 同色描边 1.5px——琥珀 `#fffbeb/#b45309`、蓝 `#eff6ff/#2563eb`、绿 `#ecfdf5/#059669`、紫 `#faf5ff/#7c3aed`、灰 `#f8fafc/#64748b`；嵌套小框用白底。
- 文字：框标题 15px/700/同色系深色；正文 11.5–12px `#334155`；注释 10.5px `#64748b`；居中加 `text-anchor="middle"`。
- **红色虚线路径**（`stroke="#dc2626" stroke-dasharray="5 4"`）表示焚毁/负向/问题路径。
- **红色圆形徽章**（`circle r="14" fill="#dc2626"` + 白色粗体编号文字）把局限/问题编号钉在组件上，图内附图例。
- 图即证据：图上标注的数字必须能在正文/台账查到出处。

### 规则二：位图（论文原图、截图、照片）= base64 data URI 内嵌

```html
<img src="data:image/jpeg;base64,/9j/4AAQ..." style="max-width:100%">
```

- 生成：`base64 -i figure.jpg | tr -d '\n'`；截图太大先压：`sips -Z 1400 -s format jpeg -s formatOptions 70 in.png --out fig.jpg`。
- 截图/照片用 JPEG（控制每张几百 KB 量级）；带透明底的简单图形可 PNG。
- 图前给一句出处说明（如「论文 Figure 1 原图（arXiv:xxxx 第 2 页）」），图后配我们的解读。
- **禁止**：外链本地相对路径图片（破坏单文件自包含）、热链外部 URL（会失效）。

## 内容写作约定

- **本章摘要自足**：3–8 条，每条一个结论，数字密集；大章（>5 节）配「本章导读」表（节 / 内容 / 回答的问题）。
- **每个 claim 带锚点**：论文（§/页码/表号）、代码（`file:line`）、实验（EXP-xxx）至少其一；负结果、口径错配、记录在案的偏差如实写进 callout。
- **实验台账章**：EXP-xxx / DOC-xxx / DATA-xxx 编号，状态用 `.st` 徽章，集群任务登记 task_id + logview 链接；流水表倒序追加（最新在上），表尾放登记模板 callout。
- 界面文案中文（「本章摘要」「← 返回目录」「更新日期」），术语保留英文原词；行内代码/路径/参数用 `<code>`。
- 不堆 emoji（📌🎯 级别点缀即可）；不改设计令牌换主题色。
- 每页 footer 必标「更新日期：YYYY-MM-DD」，改了内容就刷。

## 参考实现

原型站 `~/Desktop/omni-agent/`：`index.html`（目录页范式）、`experiments.html`（台账/宽表/状态徽章/repro 行范式）、`benchmarks.html`（分数条/样例框范式）、`methods.html`（公式/流程链范式）、`ideas.html`（SVG 框架图/折叠决策记录/徽章范式）、`progress.html`（base64 位图内嵌范式）。写新页面前可对照最接近的一页抄结构。
