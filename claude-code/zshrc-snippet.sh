# ~/.zshrc 片段：裸运行 `claude` 时弹出模型 profile 选择菜单。
# `claude <任意参数>` 会跳过菜单，直接运行真正的 claude 二进制。
# 实现方式与本仓库的 ssh() 助手完全一致。

claude() {
  if [[ $# -eq 0 ]]; then
    bash ~/scripts/claude-code/claude_model_menu.sh
  else
    command claude "$@"
  fi
}
