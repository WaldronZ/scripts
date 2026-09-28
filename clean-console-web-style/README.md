# Clean Console Web Style

Trismind-AI 人工评测页使用的清爽控制台样式 skill，作为**测试样式设计参考**保存。

这套样式用于验证内部工具、模型评测和 RAG 对话页面的视觉与交互方向。它不是财税业务规范，也不是生产组件库；接入其他项目时，应保留业务自己的信息架构和数据边界，只复用已经验证过的通用页面语言。

## 文件说明

- [`SKILL.md`](SKILL.md)：样式设计系统、HTML 骨架、交互约定和复刻规则。
- [`reference.css`](reference.css)：参考站的完整 CSS 样式真源，适合直接复制后按页面删减。

## 当前验证范围

这版样式已在 Trismind-AI 本地人工评测页验证：

- 登录页品牌和用户名入口居中；
- 白色顶栏、居中测试页签、左侧上下文侧栏和灰底对话区；
- 用户/助手消息气泡、示例问题 chip、自动增高输入框；
- RAG 检索证据、trace 展开以及好/坏人工反馈；
- 桌面宽度和窄屏布局；
- 登录、提问、反馈保存和返回首页流程。

## 来源与维护

- 来源项目：[`WaldronZ/trismind-ai`](https://github.com/WaldronZ/trismind-ai)
- 参考版本：`clean-console-web-style`，同步自 Trismind-AI 本地已验证版本。
- 维护方式：通用视觉规则更新在 `SKILL.md` 和 `reference.css`；业务项目中的财税专用组件留在业务仓库，不在此处混入。
- 用途标记：测试样式设计（test style design），后续可根据更多页面实验继续迭代。
