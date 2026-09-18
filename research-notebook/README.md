# research-notebook

一个 agent skill：把一项研究（论文复现、benchmark 调研、方法拆解、实验台账、idea
选型、进展汇报）整理成一套**多页静态 HTML 研究笔记本**——一个 `index.html`
目录页 + 每章一个独立 HTML。每个页面**单文件自包含**：CSS 全部内联、零外部依赖、
零 JS，示意图手写内联 SVG，位图 base64 内嵌，双击即可在浏览器阅读，可整目录拷走。

## 有什么内容

- `SKILL.md`——规范本体：
  - **站点架构**：index 目录页（研究愿景框 / 项目一页知 / 章节目录卡片 / 维护约定）
    + 每章一页（返回导航 → 标题 → 「本章摘要」琥珀框 → 正文 → 页脚更新日期）；
  - **设计令牌**：琥珀主色 `#b45309` + 蓝/紫/绿/红四辅色，统一字体栈与卡片语言；
  - **组件目录**：本章摘要框、节色条、KV 表、流程链、callout 四变体、可折叠决策
    记录、状态徽章（planned/running/done/failed）、分数条形图、样例框、公式块、
    深色代码块、SVG 图容器；
  - **图片处理两条硬规则**：框架图一律手写内联 SVG（六色箭头 marker、浅底同色
    描边圆角框、红虚线表负向路径、红色圆形徽章钉局限编号）；论文截图等位图一律
    base64 data URI 内嵌（保持单文件自包含）；
  - **写作约定**：摘要自足且数字密集、每个 claim 带锚点（论文 §/代码 file:line/
    实验编号）、实验台账 EXP-xxx 倒序追加、页脚必标更新日期。
- `templates/index.html`——目录页骨架，`{{占位符}}` 待填。
- `templates/chapter.html`——章节页骨架，内联完整设计系统 + 全部组件的示例
  用法，用不到的组件整块删掉即可。

## 安装

```sh
mkdir -p ~/.agents/skills
cp -R research-notebook ~/.agents/skills/
```

（Claude Code 对应目录为 `~/.claude/skills/`。）

## 用法

对 agent 说「建个研究笔记本」「把这次调研整理成 HTML 笔记本」「给笔记本加一章
实验台账」即触发。流程：复制 `templates/index.html` → 替换占位符；每加一章复制
`templates/chapter.html` → 填内容 → 回 index 登记章节卡片。
