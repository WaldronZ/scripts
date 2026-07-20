# claude-code

在多个第三方 Anthropic 兼容供应商（Kimi、中转 Opus 等）之间切换运行 Claude Code
的一套配置。裸运行 `claude` 会弹出一个 ssh 风格的方向键菜单来选择模型 profile；
`claude <任意参数>` 则跳过菜单，直接运行真正的 claude 二进制。

## 思路

- 在 `~/.zshrc` 里定义一个 `claude()` 函数：无参数时调用
  `claude_model_menu.sh`，有参数时透传给真正的 `claude`（用 `command claude`
  绕过函数本身）。实现方式与本仓库的 `ssh()` 助手完全一致。
- 菜单脚本扫描 `~/.claude/profiles/*.env`，每个 `.env` 就是一个供应商 profile。
  选中后 `source` 该文件（导出其中的环境变量），再 `exec` 真正的 claude 二进制。
- 每个供应商就是一个 `.env` 文件，菜单会自动发现，新增供应商无需改脚本。

## 接 API 的思路

每个 profile 通过环境变量把 Claude Code 指向某个 Anthropic 兼容的接口：

- `ANTHROPIC_BASE_URL` — 供应商的 API 地址。
- `ANTHROPIC_API_KEY` — 该供应商的密钥（**切勿提交真实值**）。
- `ANTHROPIC_MODEL` — 该供应商暴露的模型名。
- 四个 `ANTHROPIC_DEFAULT_{FABLE,OPUS,SONNET,HAIKU}_MODEL` 槽位 —— 全部指向同一个
  `ANTHROPIC_MODEL`，这样无论 Claude Code 请求哪一档模型都落到该供应商的实际模型上。
- `CLAUDE_CODE_SUBAGENT_MODEL` — 子代理也用同一个模型。
- `CLAUDE_CODE_MAX_CONTEXT_TOKENS` / `CLAUDE_CODE_AUTO_COMPACT_WINDOW` —— 与该供应商
  真实上下文窗口匹配（示例里是 1M）。

参见 `profiles/` 下的两个示例：

- `kimi.env.example` — Kimi 的 `api.kimi.com/coding`，模型 `k3[1m]`。
- `opus.env.example` — autodl.art 中转，模型 `claude-opus-4-8-cc`。

## 安装

```bash
git clone https://github.com/WaldronZ/scripts.git ~/scripts-repo
mkdir -p ~/scripts/claude-code
cp ~/scripts-repo/claude-code/claude_model_menu.sh ~/scripts/claude-code/
chmod +x ~/scripts/claude-code/claude_model_menu.sh
```

创建 profile 目录（权限收紧，因为里面是 API key）：

```bash
mkdir -p ~/.claude/profiles
chmod 700 ~/.claude/profiles
```

从示例复制出真实 profile 并填入密钥：

```bash
cp ~/scripts-repo/claude-code/profiles/kimi.env.example ~/.claude/profiles/kimi.env
cp ~/scripts-repo/claude-code/profiles/opus.env.example ~/.claude/profiles/opus.env
chmod 600 ~/.claude/profiles/*.env
# 编辑每个文件，把 sk-REPLACE_ME 换成真实 key
```

把 `zshrc-snippet.sh` 的内容加进 `~/.zshrc`，然后 `source ~/.zshrc`。

## 用法

- `claude` （无参数）打开 profile 选择菜单：↑/↓/←/→ 移动，Enter/空格 确认，q 退出。
- `claude <任意参数>` 跳过菜单，直接运行真正的 claude。
- `CLAUDE_BIN` 环境变量可覆盖 claude 二进制路径（主要用于测试）。

## 文件

```text
claude_model_menu.sh       裸 `claude` 触发的 profile 选择菜单
zshrc-snippet.sh           要加进 ~/.zshrc 的 claude() 函数
profiles/kimi.env.example  Kimi 供应商 profile 示例
profiles/opus.env.example  中转 Opus 供应商 profile 示例
```

## 安全

- 真实的 `~/.claude/profiles/*.env` 含有 API key，**绝不能提交**。仓库里只放
  `*.env.example` 占位版本。
- `profiles/` 目录设为 700、`.env` 文件设为 600。
