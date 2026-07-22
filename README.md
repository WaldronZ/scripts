# scripts

个人常用脚本合集（macOS / zsh）。每个子目录是一类工具，各自带独立的 README。

## 目录

| 目录 | 作用 | 裸命令 |
| --- | --- | --- |
| [`claude-code/`](claude-code/README.md) | 在多个 Anthropic 兼容供应商（Kimi、中转 Opus 等）间切换运行 Claude Code 的模型 profile 选择菜单 | `claude` 弹出菜单 |
| [`ssh/`](ssh/README.md) | macOS SSH 助手：管理 `~/.ssh/config`、`ssh-copy-id` 装公钥、`ProxyJump` 跳板机菜单 | `ssh` 弹出 Host 菜单 |
| [`remote-lab-workflow/`](remote-lab-workflow/README.md) | 「本地优先 + 远程实验」工作流的 Claude Code 模板：强制实验日志、git 风险分层、rsync 同步 / ssh -tt 远程执行 / 结果拉回本地分析 | 拷入项目作 `CLAUDE.md` |

## 思路

`claude-code/` 和 `ssh/` 是同一个模式：在 `~/.zshrc` 里把裸命令（`claude` /
`ssh`）包成一个函数——无参数时弹出方向键选择菜单，有参数时用 `command` 透传给
真正的二进制。菜单脚本本身放在本仓库对应子目录下，各自的 README 有安装和用法
说明。

`remote-lab-workflow/` 是另一类——不是脚本，而是给 Claude Code 的工作流模板
（一份 `CLAUDE.md`）：拷进项目、改好配置即用，细节见其 README。

## 安全

- 不提交任何密钥、密码、`~/.ssh/config`、GitHub token。
- `claude-code/profiles/` 只放 `*.env.example` 占位版本；真实的 `*.env`（含 API
  key）由 `.gitignore` 排除，绝不入库。
