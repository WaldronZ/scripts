#!/usr/bin/env bash
# Claude Code 模型配置选择菜单。
# 裸运行 `claude` 时（由 ~/.zshrc 里的 claude() 函数触发）弹出此菜单；
# 选中后加载 ~/.claude/profiles/<名字>.env 并 exec 真正的 claude。
# CLAUDE_BIN 环境变量可覆盖 claude 路径（主要用于测试）。
set -euo pipefail

PROFILES_DIR="${HOME}/.claude/profiles"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || true)}"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  GREEN=$'\033[32m'
  RESET=$'\033[0m'
else
  GREEN=""
  RESET=""
fi

success() {
  printf "%b✅ %s%b\n" "$GREEN" "$*" "$RESET"
}

profiles=()
while IFS= read -r f; do
  [[ -n "$f" ]] && profiles+=("$(basename "$f" .env)")
done < <(find "$PROFILES_DIR" -maxdepth 1 -name '*.env' 2>/dev/null | sort)

if [[ "${#profiles[@]}" -eq 0 ]]; then
  echo "No model profiles found in $PROFILES_DIR" >&2
  exit 1
fi

if [[ -z "$CLAUDE_BIN" ]]; then
  echo "claude binary not found in PATH" >&2
  exit 1
fi

model_of() {
  grep -E '^ANTHROPIC_MODEL=' "$PROFILES_DIR/$1.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"'
}

label_of() {
  local m
  m="$(model_of "$1")"
  if [[ -n "$m" ]]; then
    printf '%s (%s)' "$1" "$m"
  else
    printf '%s' "$1"
  fi
}

launch() {
  local profile="$1"
  success "Starting Claude Code: $(label_of "$profile")"
  set -a
  # shellcheck disable=SC1090
  source "$PROFILES_DIR/$profile.env"
  set +a
  exec "$CLAUDE_BIN"
}

SELECTED_PROFILE=""

choose_profile_menu() {
  local total=${#profiles[@]}
  local selected=0
  local rendered=0
  local menu_lines=$((total + 3))
  local key rest index label mark prefix input

  render_menu() {
    if [[ "$rendered" -eq 1 ]]; then
      printf "\033[%dA\033[J" "$menu_lines"
    fi
    rendered=1

    printf "Claude Code model profiles:\n"
    for ((index = 0; index < total; index++)); do
      label="$(label_of "${profiles[$index]}")"
      mark="[ ]"
      [[ "$selected" -eq "$index" ]] && mark="[✓]"
      prefix=" "
      [[ "$selected" -eq "$index" ]] && prefix=">"

      if [[ "$selected" -eq "$index" ]]; then
        printf "%s %s \033[7m%s\033[0m\n" "$prefix" "$mark" "$label"
      else
        printf "%s %s %s\n" "$prefix" "$mark" "$label"
      fi
    done
    printf "\nUse ↑/↓/←/→ to move, Enter/Space to confirm, q to quit.\n"
  }

  if [[ ! -t 0 || ! -t 1 ]]; then
    echo "Claude Code model profiles:"
    for ((index = 0; index < total; index++)); do
      printf "  %d) %s\n" "$((index + 1))" "$(label_of "${profiles[$index]}")"
    done
    read -r -p "Select profile [1]: " input
    input="${input:-1}"
    case "$input" in
      q|Q) echo "Canceled."; exit 0 ;;
      *[!0-9]*) echo "Invalid selection: $input" >&2; exit 2 ;;
    esac
    if (( input < 1 || input > total )); then
      echo "Invalid selection: $input" >&2
      exit 2
    fi
    SELECTED_PROFILE="${profiles[$((input - 1))]}"
    return 0
  fi

  trap 'printf "\033[?25h"; exit 130' INT TERM
  printf "\033[?25l"
  render_menu
  while true; do
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        IFS= read -rsn2 -t 1 rest || true
        case "$rest" in
          "[A"|"OA"|"[D"|"OD")
            selected=$(((selected + total - 1) % total))
            ;;
          "[B"|"OB"|"[C"|"OC")
            selected=$(((selected + 1) % total))
            ;;
        esac
        ;;
      " "|"")
        break
        ;;
      q|Q)
        printf "\033[?25h\nCanceled.\n"
        exit 0
        ;;
    esac
    render_menu
  done
  printf "\033[?25h\n"
  trap - INT TERM

  SELECTED_PROFILE="${profiles[$selected]}"
}

choose_profile_menu
launch "$SELECTED_PROFILE"
