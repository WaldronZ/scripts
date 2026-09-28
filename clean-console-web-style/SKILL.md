---
name: clean-console-web-style
description: 生成内部测试数据网站、模型评测页、对话式调试台和控制台类 Web 页面（HTML/CSS/JS）时使用的简洁后台风格设计系统，可按参考站 1:1 复刻。当用户要求做工具页、评测页、对话页、后台 dashboard，或提到“测试站风格”“控制台风格”时使用。
---

# 清爽控制台风格（Clean Console Style）— 完整复刻规范

来源：通用内部测试数据网站参考（含登录、评测、对话、对比和反馈页面）。
整体气质：浅色灰底 + 白色面板 + 单一蓝色强调色，无渐变、无阴影装饰（仅登录卡和揭示条有轻投影）、信息密度高的"内部工具"审美。

## 复刻方式（重要）

本 skill 目录下的 **`reference.css` 是原站样式表原样备份（1960 行）**。复刻时最可靠的做法：

1. 把 `reference.css` 整体拷进新页面（单文件交付就内联进 `<style>`），用不到的区块（admin / monitor / data-collection）可删；
2. HTML 严格沿用本文第 3 节的骨架与 class 命名；
3. JS 交互按第 5 节实现。

本文档 = 结构 + 行为规范；`reference.css` = 像素级样式真源。两者冲突时以 `reference.css` 为准。

## 1. 设计 Token 与全局规则

```css
* { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg: #f4f5f7;               /* 页面灰底 */
  --panel: #ffffff;            /* 面板/卡片白 */
  --border: #e2e5ea;           /* 全站统一描边 */
  --text: #1f2430;             /* 主文字 */
  --muted: #6b7280;            /* 次要文字/label/空态 */
  --accent: #2563eb;           /* 唯一强调色（蓝） */
  --accent-hover: #1d4ed8;
  --user-bubble: #2563eb;      /* 用户气泡 = 强调色 */
  --assistant-bubble: #eef1f6; /* 助手气泡/次按钮/chip 底 */
}

html, body { height: 100%; overflow: hidden; }   /* 滚动只发生在面板内部 */
body {
  font-family: -apple-system, "Segoe UI", "PingFang SC", Roboto, sans-serif;
  color: var(--text); background: var(--bg);
}
[hidden] { display: none !important; }            /* 页签/元素切换全靠它 */
```

**圆角阶梯**：6px（小按钮/小输入/评分按钮）→ 7px（session-action）→ 8px（输入框/按钮/列表项）→ 10px（多行输入/表格容器/揭示条）→ 12px（卡片/对比列）→ 14px（登录卡/聊天气泡）→ 999px（chip / badge / metric pill）

**语义色**（只用于状态与评分，绝不用于装饰）：

| 语义 | 主色 | 文字色 | 底色 |
|---|---|---|---|
| 成功 / A 更好 / 赞 | `#059669` | `#047857` | `#ecfdf5` |
| 警告 / 中 / loading | `#d97706` | `#b45309` | `#fff7ed` |
| 错误 / 差 / 踩 / 停止 | `#dc2626` | `#b91c1c` / `#c0392b` | `#fef2f2` |
| B 更好（评分专用） | `#ea580c` | — | — |
| 都好（评分专用） | `#7c3aed` | — | — |
| 评分结果标签 | — | `#4338ca` | `#eef2ff` |
| 选中/激活浅底 | — | `var(--accent)` | `#e7edfb`（列表项）/ `#f5f7fb`（导航） |

**等宽字体**：`ui-monospace, Menlo, monospace`（行内 code、数据表列开关、指标）

## 2. 页面级布局

- 应用外壳 `.app-shell`：`height:100%; display:flex; flex-direction:column; overflow:hidden`
- **顶部导航 `.top-nav`**：`height:58px; flex:0 0 58px; padding:0 22px; gap:20px`，白底 + `border-bottom:1px solid var(--border)`
  - `.top-brand`：17px / 700，左侧
  - `.top-tabs`：`position:absolute; left:50%; transform:translateX(-50%)`，页签整体居中，高 100%、gap 4px
  - `.top-tab`：透明底、muted、14px/600、`padding:0 16px`、`border-bottom:3px solid transparent`、圆角 0；hover 和 active 都是：底 `#f5f7fb` + 字 accent + 底边条 accent
  - `.top-user`：`margin-left:auto`，14px muted 用户名 + link-btn "退出"
- **页面容器 `.app-page`**：`flex:1; min-height:0`，chat/eval 页内部再 `display:flex`（侧边栏 + 主区）
- **侧边栏 `.sidebar`**：`width:350px; flex-shrink:0; padding:20px; gap:16px`，白底 + 右描边，纵向 flex、`overflow-y:auto`；内容顺序固定：
  1. 主操作按钮（"+ 新建会话 / + 新建盲评"，默认主按钮样式）
  2. `fieldset.scene-group`（描边 8px 圆角，legend 12px muted）包一组 `.scene-tab`
  3. `.conv-list` 会话列表（`flex:1; min-height:40px`，自滚动）
  4. `.panel` 参数面板（label 13px muted + 控件，`gap:8px`）
  5. 可选：底部备注 `.eval-identity-note`（12px muted，line-height 1.6）
- **主区**：灰底；内容卡片一律"白底 + 1px var(--border) + 12px 圆角"
- **响应式** `@media (max-width:800px)`：导航折行、`.top-brand` 隐藏、页签横向滚动、eval 双列回答塌成单列

## 3. HTML 骨架（class 名即契约）

```html
<!-- 登录视图：整屏居中 -->
<div id="login-view" class="login-view">
  <form id="login-form" class="login-card">
    <h1>产品名</h1>
    <p class="login-sub">输入用户名进入对话</p>
    <input id="login-username" placeholder="用户名（花名）" maxlength="64" autocomplete="username" />
    <button id="login-btn" type="submit">进入</button>
    <div id="login-error" class="login-error"></div>
  </form>
</div>

<div id="app-view" class="app-shell" hidden>
  <header class="top-nav">
    <div class="top-brand">产品名</div>
    <nav class="top-tabs">
      <button class="top-tab active" data-view="eval">模型盲评</button>
      <button class="top-tab" data-view="chat">模型对话</button>
      <a class="top-tab" href="..." target="_blank" rel="noopener noreferrer">使用说明</a>
    </nav>
    <div class="top-user"><span id="current-user" class="user-name"></span>
      <button id="logout-btn" class="link-btn">退出</button></div>
  </header>

  <!-- 对话页 / 盲评页共用：sidebar + main -->
  <section class="app-page chat-page">
    <aside class="sidebar">
      <button id="new-conv-btn">+ 新建会话</button>
      <fieldset class="scene-group"><legend>标签</legend>
        <div class="scene-tabs">
          <button class="scene-tab active">日常问答</button><button class="scene-tab">常识</button>…
        </div>
      </fieldset>
      <div class="conv-list"></div>
      <div class="panel">
        <label>模型</label><select></select>
        <div class="field-row">
          <div class="field-col"><label>最大生成长度</label><input type="number" value="1024"></div>
          <div class="field-col"><label>Temperature</label><input type="number" value="0.8" step="0.1"></div>
        </div>
        <div class="field-error" hidden></div>
      </div>
    </aside>
    <main class="chat">
      <div class="messages"><div class="empty-hint">新建或选择一个会话，开始对话。</div></div>
      <div class="composer-error" hidden></div>
      <form class="composer">
        <textarea rows="1" placeholder="输入消息，Enter 发送，Shift+Enter 换行"></textarea>
        <button type="submit">发送</button>
      </form>
      <div class="examples" hidden></div>   <!-- 示例问题 chip 横排 -->
    </main>
  </section>
</div>
```

盲评页（eval）主区结构：

```html
<main class="eval-main">
  <div class="arena-error" hidden></div>
  <div class="eval-rounds">
    <div class="eval-reveal-summary" hidden></div>  <!-- sticky 揭示结果条 -->
    <!-- 每轮： -->
    <article class="eval-round">
      <div class="eval-prompt">用户问题（靠右蓝气泡）</div>
      <div class="eval-answers">
        <div class="eval-answer">
          <div class="eval-answer-head">模型 A <span class="eval-reveal">真实模型名</span></div>
          <div class="bubble markdown">…回答…</div>
          <div class="eval-rating">
            <span class="feedback-label">评价：</span>
            <button class="eval-rate-btn" data-value="a_better">A 更好</button>
            <button class="eval-rate-btn" data-value="b_better">B 更好</button>
            <button class="eval-rate-btn" data-value="both_good">都好</button>
            <button class="eval-rate-btn" data-value="both_bad">都差</button>
            <span class="eval-rating-hint" hidden>请先完成本轮评价</span>
          </div>
        </div>
        …B 卡相同…
      </div>
    </article>
  </div>
  <form class="arena-composer">
    <textarea rows="1"></textarea>
    <button type="submit">发送</button>
    <button class="session-action" type="button" disabled>揭示模型</button>
  </form>
</main>
```

## 4. 组件完整配方（状态全覆盖；数值与 reference.css 一致）

### 4.1 登录卡 `.login-card`
- 登录视图本身必须占满应用外壳宽度：`width:100%; flex:1 1 auto`；当外壳使用横向 flex 时，仅设置 `align-items:center; justify-content:center` 不足以保证卡片在整页居中。
- 父容器整屏 flex 居中、灰底；卡片 `width:320px; padding:28px 24px; radius:14px; gap:10px`，白底 + 描边 + **全站仅有的装饰投影** `0 8px 30px rgba(0,0,0,.06)`
- h1 24px/700 居中；`.login-sub` 14px muted 居中；输入 `padding:11px 12px; 15px`；错误 `.login-error` 13px `#b91c1c`、`min-height:16px` 占位防抖动

### 4.2 按钮族（全局 `button` 默认即主按钮）
```css
button { padding:10px 12px; border:none; border-radius:8px; background:var(--accent);
         color:#fff; font-size:14px; font-weight:600; cursor:pointer; margin-top:6px; }
button:hover { background:var(--accent-hover); }
button:disabled { opacity:.55; cursor:not-allowed; }
button.secondary { background:#eef1f6; color:var(--text); }       /* 次按钮 */
button.secondary:hover { background:#e2e6ee; }
.link-btn { background:none; color:var(--accent); font-size:13px; font-weight:500; padding:0; }
.link-btn:hover { text-decoration:underline; }                     /* 修改/取消/退出 */
.session-action { border:1px solid #d97706; border-radius:7px; background:#fff7ed;
                  color:#b45309; font-size:13px; padding:7px 14px; } /* 会话级操作 */
.session-action:hover { background:#d97706; color:#fff; }
.composer button.stop, .arena-composer button.stop { background:#dc2626; }  /* 停止生成 */
```

### 4.3 表单
- 控件统一：`padding:9px 10px; border:1px solid var(--border); border-radius:8px; font-size:14px; background:#fff; font-family:inherit`；focus：`outline:none; border-color:var(--accent)`（**从无发光 ring**）
- label：13px muted；并排参数 `.field-row{display:flex;gap:8px} > .field-col{flex:1}`
- 禁用态：`background:#f1f3f5; color:#868e96; border-color:#dee2e6; opacity:1`（不发虚）
- 校验：非法输入描边 `#dc2626`（`.invalid`）+ 就近红字 `.field-error`（12px `#b91c1c`）；工具条内用 `.field-error-abs{position:absolute;top:100%}` 防止撑开布局
- checkbox：`accent-color:var(--accent)`

### 4.4 列表项 `.conv-item`
- `padding:9px 10px; radius:8px; 14px`，标题单行省略；hover 底 `#f1f2f4`；active 底 `#e7edfb` + accent + 600
- 删除钮 `.conv-del`：20×20、**平时 `display:none`、hover 列表项才显示**；hover 自身底 `#e2e5ea`、字 `#c0392b`
- 徽章 `.label-badge`：底 `#e7edfb`、accent、11px/600、999px、`padding:1px 8px`

### 4.5 场景页签 / chip / 示例
- `.scene-tab`：`flex:1 1 28%`（一行约 3 个自动换行）、白底描边、13px muted、`padding:7px 4px`；hover 边变 accent；active 实色 accent + 600
- `.model-chip`：`#eef1f6` 底、999px、`padding:5px 12px`、13px；selected 实色 accent；内部 checkbox `display:none`
- `.example-chip`：白底描边 999px、12px muted、单行省略；hover 边/字变 accent、底 `#f5f8ff`

### 4.6 对话气泡与消息区
- `.messages`：`padding:24px; gap:16px`；空态 `.empty-hint` 整区 `margin:auto` 居中 15px muted
- `.bubble`：`padding:12px 16px; radius:14px; 15px; line-height:1.6; white-space:pre-wrap`
- 用户：右对齐、max-width 80%、accent 底白字、`border-bottom-right-radius:4px`
- 助手：左对齐、宽 90%、`--assistant-bubble` 底、`border-bottom-left-radius:4px`
- 流式光标 `.cursor`：`display:inline-block; width:7px; animation:blink 1s steps(2,start) infinite`
- 指标 `.metric`：`#eef1f6` 底 + 描边 + 999px、`padding:3px 9px`、12px；`em` 标签 muted、`b` 数值 600

### 4.7 输入区 `.composer` / `.arena-composer`
- 白底 + 顶描边、`padding:14px 20px`（arena 版 `12px 18px 16px`）、`align-items:flex-end`
- textarea：`flex:1; resize:none; radius:10px; padding:11px 12px; 15px; max-height:160px`，**JS 随输入自动增高**
- 发送按钮：`height:44px; padding:0 22px; margin:0`
- 错误条 `.composer-error`：顶描边 + `#fef2f2` 底 + 13px 红字，内联不弹窗

### 4.8 盲评（eval）专属
- `.eval-rounds`：`padding:16px 20px`，每轮 `.eval-round{max-width:1320px; margin:0 auto 18px}`
- `.eval-prompt`：靠右、`max-width:70%`、accent 底白字、圆角 `12px 12px 2px 12px`、`padding:10px 14px`
- `.eval-answers`：`grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:14px`（≤800px 单列）
- `.eval-answer`：白卡 12px 圆角 `padding:12px`；头 `.eval-answer-head` accent 700；卡内 bubble 透明底零内边距（卡片即容器）
- `.eval-rate-btn`：`height:30px; padding:0 14px; 13px/500; background:#fff; border:1.5px solid #c8cdd6; radius:6px`；hover 底 `#f1f3f7` 边 `#9aa2af`；**选中按 data-value 着语义色**：`a_better→#059669`、`b_better→#ea580c`、`both_good→#7c3aed`、`both_bad→#dc2626`（底边同色、字白）
- `.eval-rating-result`：已提交结果标签，底 `#eef2ff` 字 `#4338ca` 13px/700
- `.eval-reveal-summary`：`position:sticky; top:0; z-index:2`、居中横排 gap 18px、`max-width:900px`、**2px `#10b981` 边 + `#ecfdf5` 底 + 投影 `0 4px 14px rgba(5,150,105,.12)`**；项内 span 绿 700 + strong 主文字色

### 4.9 状态条 / 统计卡 / 表格 / 图表
- `.status`：`padding:8px 10px; radius:8px; 13px`；idle `#f1f2f4`/muted，loading `#fff7ed`/`#b45309`，ok `#ecfdf5`/`#047857`，error `#fef2f2`/`#b91c1c`
- `.stat` / `.live-card`：白卡 12px 圆角居中，`min-width:110~130px`；数字 `.stat-num` 24px/700 accent；标签 12px muted
- 表格：13px、`border-collapse`；th 底 `#f7f8fa`、muted/600；单元格 `padding:8px 10px`、底描边、`max-width:260px` 省略；可点行 hover 底 `#eef2fb`；容器 `.grid-wrap` 白卡 10px 圆角，thead `position:sticky; top:0`
- 迷你柱状图 `.chart`：`height:140px; align-items:flex-end; gap:2px`，bar flex:1、accent 底、顶部 2px 圆角，hover 加深

### 4.10 Markdown 渲染（`.bubble.markdown`）
- `white-space:normal`；首尾子元素去 margin；段落 `margin:8px 0`；h1–h4 `margin:12px 0 6px`（1.3/1.2/1.1em）
- 行内 code：`background:rgba(0,0,0,.06); padding:1px 5px; radius:4px; 0.9em` 等宽
- **代码块：深色 `#0f172a` 底 + `#e2e8f0` 字、8px 圆角、`padding:12px 14px` —— 全站唯一深色元素，视觉焦点**
- 引用：左 `3px solid var(--border)` 竖线 + muted；链接 accent + 下划线；表格细描边 `padding:4px 8px`；KaTeX display 横向滚动

### 4.11 反馈页
- 居中窄栏 `max-width:820px; padding:28px`；说明 13px muted；textarea 6 行 maxlength 4000
- 历史反馈 `.feedback-item` 白卡 8px；官方回复 `.feedback-reply`：左 3px accent 竖线 + `#eff6ff` 底 + 6px 圆角

## 5. JS 交互规范（风格的一部分，照做）

- **路由**：hash 路由。切页签 `history.replaceState(null,"","#"+view)`，监听 `hashchange` 切 `.app-page` 的 `hidden`；默认 view 为第一个页签
- **登录**：POST `/api/login {username}`，空用户名在 `.login-error` 显示"请输入用户名"，登录中按钮 disabled；刷新后 `/api/me` 恢复会话
- **textarea 自动增高**：`input` 事件里 `el.style.height="auto"; el.style.height=Math.min(el.scrollHeight,160)+"px"`
- **发送键**：`keydown` 里 `Enter && !shiftKey` → preventDefault + 提交；发送中按钮变 `.stop`（红底"停止"）
- **流式渲染**：fetch + ReadableStream 逐 chunk 追加，末尾挂 `.cursor` 闪烁块，结束移除；`messages.scrollTop = scrollHeight` 自动滚底
- **Markdown**：marked 渲染 → DOMPurify 消毒 → KaTeX 公式（原站用 `/vendor/marked.min.js + purify.min.js + katex.min.js`）
- **参数校验**：如最大生成长度 16–4096，越界即加 `.invalid` + `.field-error` 文案并禁用发送
- **评价流**：四个评分按钮互斥 toggle；未评完当前轮点"揭示模型"时显示 `.eval-rating-hint` 红字；全部评完提交后渲染 `.eval-reveal-summary` sticky 绿条 + 每卡头部 `.eval-reveal` 显示真实模型名
- **删除**：全部走 `confirm()` 原生确认，无自定义弹窗

## 6. 复刻检查清单

- [ ] 只有灰/白/蓝三色体系 + 语义色，无渐变、无多余投影（登录卡、揭示条除外）
- [ ] 所有 focus 只变描边色，无 outline 发光
- [ ] 圆角符合阶梯，卡片统一 12px、白底 1px `#e2e5ea`
- [ ] 页面级 `overflow:hidden`，滚动都在面板内
- [ ] 空态、错误、加载都有就近内联提示，无弹窗（确认删除除外）
- [ ] active 态三件套统一：浅蓝底 `#e7edfb`/`#f5f7fb` + accent 字 (+ 必要时 600)
- [ ] 代码块深色 `#0f172a`，是全页唯一深色区域

## 7. 适用边界

适合"工具 / 数据 / 评测 / 对话"类功能页面。论文笔记、报告类 HTML 仍用 AGENTS.md 指定的 hero + KPI 卡片风格（参考 `ZGCM-1_论文笔记.html`），两套风格不混用。
