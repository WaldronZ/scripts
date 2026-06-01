#!/usr/bin/env bash
set -euo pipefail

KEY_PATH="${HOME}/.ssh/id_ed25519"
SSH_CONFIG="${HOME}/.ssh/config"
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
HOST_ALIAS=""
HOST=""
PORT=""
USER_NAME=""
PROXY_JUMP=""
PROXY_JUMP_PROVIDED=0
CREATE_NEW_HOST=0
SELECTED_HOST_CHOICE=""
ACTION=""

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

confirm_yes() {
  local prompt="$1"
  local answer

  while true; do
    read -r -p "$prompt" answer
    case "$answer" in
      ""|y|Y|yes|YES|Yes)
        return 0
        ;;
      n|N|no|NO|No)
        return 1
        ;;
      *)
        echo "Please type y or n."
        ;;
    esac
  done
}

usage() {
  cat <<'USAGE'
Usage:
  setup_ssh_key.sh
  setup_ssh_key.sh --login
  setup_ssh_key.sh --jump
  setup_ssh_key.sh --alias <ssh-config-host>
  setup_ssh_key.sh --host <ip-or-host> --port <port> --user <user>

Options:
  --login         Pick an existing SSH config Host and connect.
  --jump          Configure an inner host using an existing Host as ProxyJump.
  --setup         Add or update SSH key login. This is used automatically with host options.
  --alias, -a     SSH config Host alias to use or create.
  --host, -H      Server IP or hostname.
  --port, -p      SSH port. Default: 22.
  --user, -u      SSH username.
  --key, -k       Local private key path. Default: ~/.ssh/id_ed25519.
  --proxy-jump, -J
                  ProxyJump value. Prefer an existing SSH config Host alias.
  --help          Show this help.

Example:
  setup_ssh_key.sh
  setup_ssh_key.sh --login
  setup_ssh_key.sh --jump
  setup_ssh_key.sh --alias Mac-studio
  setup_ssh_key.sh --host example.com --port 22 --user alice
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --login)
      ACTION="login"
      shift
      ;;
    --jump)
      ACTION="jump"
      shift
      ;;
    --setup)
      ACTION="setup"
      shift
      ;;
    --alias|-a)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --host|-H)
      HOST="${2:-}"
      shift 2
      ;;
    --port|-p)
      PORT="${2:-}"
      shift 2
      ;;
    --user|-u)
      USER_NAME="${2:-}"
      shift 2
      ;;
    --proxy-jump|-J)
      PROXY_JUMP="${2:-}"
      PROXY_JUMP_PROVIDED=1
      shift 2
      ;;
    --key|-k)
      KEY_PATH="${2:-}"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

host_alias_exists() {
  local alias="$1"
  [[ -f "$SSH_CONFIG" ]] || return 1
  awk -v target="$alias" '
    BEGIN { found = 1 }
    /^[[:space:]]*[Hh][Oo][Ss][Tt][[:space:]]+/ {
      for (i = 2; i <= NF; i++) {
        if ($i == target) {
          found = 0
          exit
        }
      }
    }
    END { exit found }
  ' "$SSH_CONFIG"
}

print_known_hosts() {
  [[ -f "$SSH_CONFIG" ]] || return 0
  awk '
    /^[[:space:]]*[Hh][Oo][Ss][Tt][[:space:]]+/ {
      for (i = 2; i <= NF; i++) {
        if ($i !~ /[*?!]/) {
          print "  " $i
        }
      }
    }
  ' "$SSH_CONFIG"
}

list_known_hosts() {
  [[ -f "$SSH_CONFIG" ]] || return 0
  awk '
    /^[[:space:]]*[Hh][Oo][Ss][Tt][[:space:]]+/ {
      for (i = 2; i <= NF; i++) {
        if ($i !~ /[*?!]/) {
          print $i
        }
      }
    }
  ' "$SSH_CONFIG"
}

choose_host_menu() {
  local include_create="${1:-yes}"
  local hosts=()
  local item
  local selected=0
  local total
  local rendered=0
  local menu_lines
  local key rest index label mark prefix

  while IFS= read -r item; do
    [[ -n "$item" ]] && hosts+=("$item")
  done < <(list_known_hosts || true)

  if [[ "$include_create" == "yes" ]]; then
    total=$((${#hosts[@]} + 1))
  else
    total=${#hosts[@]}
  fi
  if [[ "$total" -eq 0 ]]; then
    echo "No SSH config hosts found in $SSH_CONFIG."
    SELECTED_HOST_CHOICE=""
    return 1
  fi
  menu_lines=$((total + 3))

  render_menu() {
    if [[ "$rendered" -eq 1 ]]; then
      printf "\033[%dA\033[J" "$menu_lines"
    fi
    rendered=1

    printf "Existing SSH config hosts:\n"
    for ((index = 0; index < total; index++)); do
      if [[ "$index" -lt "${#hosts[@]}" ]]; then
        label="${hosts[$index]}"
      else
        label="+ Create new SSH config Host"
      fi

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
    if [[ "${#hosts[@]}" -gt 0 ]]; then
      echo "Existing SSH config hosts:"
      print_known_hosts
      echo
    fi
    if [[ "$include_create" == "yes" ]]; then
      read -r -p "SSH config Host name (existing or new, e.g. mac-studio): " SELECTED_HOST_CHOICE
    else
      read -r -p "SSH config Host to connect: " SELECTED_HOST_CHOICE
    fi
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

  if [[ "$selected" -lt "${#hosts[@]}" ]]; then
    SELECTED_HOST_CHOICE="${hosts[$selected]}"
  else
    SELECTED_HOST_CHOICE=""
  fi
}

choose_proxy_jump_menu() {
  local current_alias="${1:-}"
  local default_choice="${2:-}"
  local hosts=()
  local item
  local selected=0
  local default_index=0
  local total
  local rendered=0
  local menu_lines
  local key rest index label mark prefix input

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    [[ -n "$current_alias" && "$item" == "$current_alias" ]] && continue
    hosts+=("$item")
  done < <(list_known_hosts || true)

  total=$((${#hosts[@]} + 1))
  menu_lines=$((total + 3))

  if [[ -n "$default_choice" ]]; then
    for ((index = 0; index < "${#hosts[@]}"; index++)); do
      if [[ "${hosts[$index]}" == "$default_choice" ]]; then
        selected=$((index + 1))
        default_index="$selected"
        break
      fi
    done
  fi

  render_proxy_jump_menu() {
    if [[ "$rendered" -eq 1 ]]; then
      printf "\033[%dA\033[J" "$menu_lines"
    fi
    rendered=1

    printf "ProxyJump:\n"
    for ((index = 0; index < total; index++)); do
      if [[ "$index" -eq 0 ]]; then
        label="None"
      else
        label="${hosts[$((index - 1))]}"
      fi

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
    echo "ProxyJump:"
    printf "  0) None\n"
    for ((index = 0; index < "${#hosts[@]}"; index++)); do
      printf "  %d) %s\n" "$((index + 1))" "${hosts[$index]}"
    done
    echo

    read -r -p "Select ProxyJump [${default_index}]: " input
    input="${input:-$default_index}"

    case "$input" in
      y|Y|yes|YES|Yes)
        if (( default_index >= 1 && default_index <= ${#hosts[@]} )); then
          PROXY_JUMP="${hosts[$((default_index - 1))]}"
        else
          PROXY_JUMP=""
        fi
        ;;
      0|none|None|NONE|no|No|NO)
        PROXY_JUMP=""
        ;;
      ''|*[!0-9]*)
        PROXY_JUMP="$input"
        ;;
      *)
        if (( input >= 1 && input <= ${#hosts[@]} )); then
          PROXY_JUMP="${hosts[$((input - 1))]}"
        else
          echo "Invalid ProxyJump selection: $input" >&2
          return 1
        fi
        ;;
    esac
    return 0
  fi

  trap 'printf "\033[?25h"; exit 130' INT TERM
  printf "\033[?25l"
  render_proxy_jump_menu
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
    render_proxy_jump_menu
  done
  printf "\033[?25h\n"
  trap - INT TERM

  if [[ "$selected" -eq 0 ]]; then
    PROXY_JUMP=""
  else
    PROXY_JUMP="${hosts[$((selected - 1))]}"
  fi
}

choose_action_menu() {
  local actions=("SSH login to existing Host" "Add/update key login")
  local selected=0
  local total=2
  local rendered=0
  local menu_lines=5
  local key rest index mark prefix label

  render_action_menu() {
    if [[ "$rendered" -eq 1 ]]; then
      printf "\033[%dA\033[J" "$menu_lines"
    fi
    rendered=1

    printf "Choose action:\n"
    for ((index = 0; index < total; index++)); do
      label="${actions[$index]}"
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
    printf "\nEnter/Space confirms current choice. Use ↑/↓/←/→ to move, q to quit.\n"
  }

  if [[ ! -t 0 || ! -t 1 ]]; then
    echo "1) SSH login to existing Host"
    echo "2) Add/update key login"
    read -r -p "Choose action [1]: " ACTION_CHOICE
    ACTION_CHOICE="${ACTION_CHOICE:-1}"
    case "$ACTION_CHOICE" in
      1) ACTION="login" ;;
      2) ACTION="setup" ;;
      *) echo "Invalid action: $ACTION_CHOICE" >&2; exit 2 ;;
    esac
    return 0
  fi

  trap 'printf "\033[?25h"; exit 130' INT TERM
  printf "\033[?25l"
  render_action_menu
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
    render_action_menu
  done
  printf "\033[?25h\n"
  trap - INT TERM

  if [[ "$selected" -eq 0 ]]; then
    ACTION="login"
  else
    ACTION="setup"
  fi
}

sanitize_alias() {
  local alias="$1"
  alias="${alias#*@}"
  alias="${alias//:/-}"
  alias="${alias//\//-}"
  alias="${alias// /-}"
  printf "%s" "$alias"
}

config_value_for_alias() {
  local alias="$1"
  local key="$2"
  [[ -f "$SSH_CONFIG" ]] || return 0
  awk -v target="$alias" -v want="$key" '
    BEGIN { in_block = 0 }
    /^[[:space:]]*[Hh][Oo][Ss][Tt][[:space:]]+/ {
      in_block = 0
      for (i = 2; i <= NF; i++) {
        if ($i == target) {
          in_block = 1
        }
      }
      next
    }
    in_block && tolower($1) == tolower(want) {
      print $2
      exit
    }
  ' "$SSH_CONFIG"
}

would_create_proxy_jump_cycle() {
  local source_alias="$1"
  local jump_alias="$2"
  local cursor next

  [[ -n "$source_alias" && -n "$jump_alias" ]] || return 1

  cursor="${jump_alias%%,*}"
  while host_alias_exists "$cursor"; do
    if [[ "$cursor" == "$source_alias" ]]; then
      return 0
    fi

    next="$(config_value_for_alias "$cursor" ProxyJump)"
    [[ -n "$next" ]] || return 1
    cursor="${next%%,*}"
  done

  return 1
}

write_ssh_config() {
  local tmp backup
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  tmp="$(mktemp)"
  awk -v target="$HOST_ALIAS" '
    /^[[:space:]]*[Hh][Oo][Ss][Tt][[:space:]]+/ {
      skip = 0
      for (i = 2; i <= NF; i++) {
        if ($i == target) {
          skip = 1
        }
      }
    }
    !skip { print }
  ' "$SSH_CONFIG" > "$tmp"

  {
    printf "\n"
    printf "Host %s\n" "$HOST_ALIAS"
    printf "  HostName %s\n" "$HOST"
    printf "  User %s\n" "$USER_NAME"
    printf "  Port %s\n" "$PORT"
    printf "  IdentityFile %s\n" "$KEY_PATH"
    printf "  IdentitiesOnly yes\n"
    if [[ -n "$PROXY_JUMP" ]]; then
      printf "  ProxyJump %s\n" "$PROXY_JUMP"
    fi
  } >> "$tmp"

  backup="${SSH_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
  local suffix=1
  while [[ -e "$backup" ]]; do
    backup="${SSH_CONFIG}.bak.$(date +%Y%m%d%H%M%S).${suffix}"
    suffix=$((suffix + 1))
  done
  cp "$SSH_CONFIG" "$backup"
  mv "$tmp" "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  success "Updated SSH config: $SSH_CONFIG"
  echo "Backup: $backup"
}

print_done() {
  echo
  echo "Done. Use these values in Codex or SSH clients:"
  echo "  SSH config Host: ${HOST_ALIAS}"
  echo "  Host: ${USER_NAME}@${HOST}"
  echo "  Port: ${PORT}"
  echo "  Identity file: ${KEY_PATH}"
  if [[ -n "$PROXY_JUMP" ]]; then
    echo "  ProxyJump: ${PROXY_JUMP}"
  fi
}

test_ssh_config_alias() {
  echo "Testing SSH config Host alias..."
  ssh \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    "$HOST_ALIAS" \
    "echo ok" >/dev/null
  success "SSH config Host alias works: $HOST_ALIAS"
}

test_key_login() {
  if host_alias_exists "$HOST_ALIAS"; then
    ssh \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "$HOST_ALIAS" \
      "echo ok" >/dev/null
  else
    ssh \
      -i "$KEY_PATH" \
      -o IdentitiesOnly=yes \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      -p "$PORT" \
      "${USER_NAME}@${HOST}" \
      "echo ok" >/dev/null
  fi
}

load_host_config() {
  local alias="$1"
  HOST="$(config_value_for_alias "$alias" HostName)"
  USER_NAME="$(config_value_for_alias "$alias" User)"
  PORT="$(config_value_for_alias "$alias" Port)"
  KEY_PATH="$(config_value_for_alias "$alias" IdentityFile)"
  PROXY_JUMP="$(config_value_for_alias "$alias" ProxyJump)"
}

prompt_with_default() {
  local prompt="$1"
  local default_value="$2"
  local input
  if [[ -n "$default_value" ]]; then
    read -r -p "${prompt} [${default_value}]: " input
    printf "%s" "${input:-$default_value}"
  else
    read -r -p "${prompt}: " input
    printf "%s" "$input"
  fi
}

setup_alias_if_requested() {
  local alias="$1"
  local label="$2"
  if confirm_yes "Set up/test key login for ${label} (${alias}) now? [Y/n]: "; then
    bash "$SCRIPT_PATH" --setup --alias "$alias"
  else
    echo "Skipped key setup for ${alias}."
  fi
}

run_jump_setup() {
  local jump_alias
  local inner_alias inner_host inner_user inner_port inner_key inner_proxy

  echo "SSH jump setup"
  echo "Pick an existing SSH config Host as ProxyJump, then create/update the inner Host."
  echo

  if [[ -f "$SSH_CONFIG" ]]; then
    echo "Existing SSH config hosts:"
    print_known_hosts
    echo
  fi

  PROXY_JUMP=""
  choose_proxy_jump_menu "" ""
  jump_alias="$PROXY_JUMP"
  if [[ -z "$jump_alias" ]]; then
    echo "Choose an existing Jump Host first. You can add the jump machine as a normal SSH config Host, then rerun --jump." >&2
    exit 2
  fi

  echo
  inner_alias="$(prompt_with_default "Inner SSH config Host name" "inner-213")"
  if [[ -z "$inner_alias" ]]; then
    echo "Inner Host name is required." >&2
    exit 2
  fi

  HOST_ALIAS="$inner_alias"
  HOST=""
  USER_NAME=""
  PORT=""
  PROXY_JUMP=""
  KEY_PATH="${HOME}/.ssh/id_ed25519"

  if host_alias_exists "$inner_alias"; then
    HOST="$(config_value_for_alias "$inner_alias" HostName)"
    USER_NAME="$(config_value_for_alias "$inner_alias" User)"
    PORT="$(config_value_for_alias "$inner_alias" Port)"
    inner_key="$(config_value_for_alias "$inner_alias" IdentityFile)"
    inner_proxy="$(config_value_for_alias "$inner_alias" ProxyJump)"
    [[ -n "$inner_key" ]] && KEY_PATH="$inner_key"
    [[ -n "$inner_proxy" ]] && PROXY_JUMP="$inner_proxy"
    echo "Found inner Host: $inner_alias"
  fi

  inner_host="$(prompt_with_default "Inner IP/HostName" "$HOST")"
  inner_user="$(prompt_with_default "Inner user" "${USER_NAME:-$(whoami)}")"
  inner_port="$(prompt_with_default "Inner port" "${PORT:-22}")"
  inner_key="$(prompt_with_default "Inner IdentityFile" "${KEY_PATH:-${HOME}/.ssh/id_ed25519}")"
  inner_proxy="$jump_alias"

  if [[ -z "$inner_host" || -z "$inner_user" || -z "$inner_port" || -z "$inner_key" || -z "$inner_proxy" ]]; then
    echo "Inner HostName, user, port, key, and ProxyJump are required." >&2
    exit 2
  fi

  HOST_ALIAS="$inner_alias"
  HOST="$inner_host"
  USER_NAME="$inner_user"
  PORT="$inner_port"
  KEY_PATH="${inner_key/#\~/$HOME}"
  PROXY_JUMP="$inner_proxy"

  if [[ "$PROXY_JUMP" == "$HOST_ALIAS" ]] || would_create_proxy_jump_cycle "$HOST_ALIAS" "$PROXY_JUMP"; then
    echo "Invalid ProxyJump: it would make a loop with Host ${HOST_ALIAS}." >&2
    exit 2
  fi

  echo
  echo "Inner host config:"
  echo "  Host: ${HOST_ALIAS}"
  echo "  HostName: ${HOST}"
  echo "  User: ${USER_NAME}"
  echo "  Port: ${PORT}"
  echo "  IdentityFile: ${KEY_PATH}"
  echo "  IdentitiesOnly: yes"
  echo "  ProxyJump: ${PROXY_JUMP}"
  write_ssh_config
  setup_alias_if_requested "$inner_alias" "inner host"

  echo
  success "Jump setup finished."
  echo "Use:"
  echo "  ssh ${inner_alias}"
}

if [[ -n "$HOST_ALIAS" || -n "$HOST" || -n "$PORT" || -n "$USER_NAME" || -n "$PROXY_JUMP" ]]; then
  ACTION="${ACTION:-setup}"
fi

if [[ -z "$ACTION" ]]; then
  choose_action_menu
fi

if [[ "$ACTION" == "login" ]]; then
  echo "SSH helper -- run sshkey to add/update key login"
elif [[ "$ACTION" == "jump" ]]; then
  echo "SSH helper -- jump host setup"
else
  echo "SSH helper"
fi
echo

case "$ACTION" in
  login)
    if [[ -z "$HOST_ALIAS" ]]; then
      if [[ -n "$HOST" ]]; then
        HOST_ALIAS="$HOST"
      else
        choose_host_menu "no" || exit 1
        HOST_ALIAS="$SELECTED_HOST_CHOICE"
      fi
    fi

    if [[ -z "$HOST_ALIAS" ]]; then
      echo "No SSH config Host selected." >&2
      exit 1
    fi

    if ! host_alias_exists "$HOST_ALIAS"; then
      echo "SSH config Host not found: $HOST_ALIAS" >&2
      exit 1
    fi

    success "Connecting to SSH config Host: $HOST_ALIAS"
    exec ssh "$HOST_ALIAS"
    ;;
  setup)
    ;;
  jump)
    run_jump_setup
    exit 0
    ;;
  *)
    echo "Invalid action: $ACTION" >&2
    exit 2
    ;;
esac

if [[ -z "$HOST_ALIAS" && -z "$HOST" ]]; then
  choose_host_menu
  if [[ -n "$SELECTED_HOST_CHOICE" ]]; then
    HOST_ALIAS="$SELECTED_HOST_CHOICE"
  else
    CREATE_NEW_HOST=1
    read -r -p "New SSH config Host name: " HOST_ALIAS
  fi
fi

if [[ -n "$HOST" && -z "$HOST_ALIAS" ]] && host_alias_exists "$HOST"; then
  HOST_ALIAS="$HOST"
fi

if [[ -n "$HOST_ALIAS" ]] && host_alias_exists "$HOST_ALIAS"; then
  CONFIG_HOSTNAME="$(config_value_for_alias "$HOST_ALIAS" HostName)"
  CONFIG_USER="$(config_value_for_alias "$HOST_ALIAS" User)"
  CONFIG_PORT="$(config_value_for_alias "$HOST_ALIAS" Port)"
  CONFIG_KEY_PATH="$(config_value_for_alias "$HOST_ALIAS" IdentityFile)"
  CONFIG_PROXY_JUMP="$(config_value_for_alias "$HOST_ALIAS" ProxyJump)"

  HOST="${CONFIG_HOSTNAME:-$HOST_ALIAS}"
  USER_NAME="${USER_NAME:-$CONFIG_USER}"
  PORT="${PORT:-$CONFIG_PORT}"
  if [[ -n "$CONFIG_KEY_PATH" ]]; then
    KEY_PATH="$CONFIG_KEY_PATH"
  fi
  if [[ -n "$CONFIG_PROXY_JUMP" && "$PROXY_JUMP_PROVIDED" -eq 0 ]]; then
    PROXY_JUMP="$CONFIG_PROXY_JUMP"
  fi
  echo "Found SSH config Host: $HOST_ALIAS"
else
  if [[ -z "$HOST" && "$CREATE_NEW_HOST" -eq 0 ]]; then
    HOST="$HOST_ALIAS"
  fi

  if [[ "$HOST" == *@* ]]; then
    if [[ -z "$USER_NAME" ]]; then
      USER_NAME="${HOST%@*}"
    fi
    HOST="${HOST##*@}"
  fi

  DEFAULT_ALIAS="$(sanitize_alias "$HOST")"
  if [[ -z "$HOST_ALIAS" ]]; then
    read -r -p "New SSH config Host name [${DEFAULT_ALIAS}]: " HOST_ALIAS
    HOST_ALIAS="${HOST_ALIAS:-$DEFAULT_ALIAS}"
  fi

  if [[ -n "$HOST" ]]; then
    read -r -p "Server IP/Host [${HOST}]: " HOST_INPUT
    HOST="${HOST_INPUT:-$HOST}"
  else
    read -r -p "Server IP/Host: " HOST
  fi
fi

if [[ -z "$PORT" ]]; then
  read -r -p "Port [22]: " PORT
  PORT="${PORT:-22}"
fi

if [[ -z "$USER_NAME" ]]; then
  read -r -p "User [$(whoami)]: " USER_NAME
  USER_NAME="${USER_NAME:-$(whoami)}"
fi

if [[ "$PROXY_JUMP_PROVIDED" -eq 0 ]]; then
  choose_proxy_jump_menu "$HOST_ALIAS" "$PROXY_JUMP"
fi

if [[ -n "$PROXY_JUMP" ]]; then
  if [[ "$PROXY_JUMP" == "$HOST_ALIAS" ]] || would_create_proxy_jump_cycle "$HOST_ALIAS" "$PROXY_JUMP"; then
    echo "Invalid ProxyJump: it would make a loop with Host ${HOST_ALIAS}." >&2
    exit 2
  fi
fi

if [[ -z "$HOST" || -z "$USER_NAME" ]]; then
  echo "Host and user are required." >&2
  exit 2
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
  echo "Invalid port: $PORT" >&2
  exit 2
fi

if ! command -v ssh-copy-id >/dev/null 2>&1; then
  cat >&2 <<'ERR'
This script needs "ssh-copy-id" to install the public key reliably.
On macOS, install it with:
  brew install ssh-copy-id
ERR
  exit 1
fi

echo
echo "Connection:"
echo "  SSH config Host: ${HOST_ALIAS}"
echo "  Host: ${USER_NAME}@${HOST}"
echo "  Port: ${PORT}"
echo "  IdentityFile: ${KEY_PATH}"
echo "  IdentitiesOnly: yes"
if [[ -n "$PROXY_JUMP" ]]; then
  echo "  ProxyJump: ${PROXY_JUMP}"
fi
if ! confirm_yes "Continue? [Y/n]: "; then
  echo "Canceled."
  exit 0
fi

TEST_KEY_PATH="${KEY_PATH/#\~/$HOME}"
if [[ -f "$TEST_KEY_PATH" ]]; then
  echo "Checking existing key login..."
  KEY_PATH="$TEST_KEY_PATH"
  if test_key_login >/dev/null 2>&1; then
    KEY_PATH="$TEST_KEY_PATH"
    write_ssh_config
    test_ssh_config_alias
    success "Key login already works. No password needed."
    print_done
    exit 0
  fi
fi

DEFAULT_KEY_PATH="$KEY_PATH"
read -r -p "Identity key path [${DEFAULT_KEY_PATH}] (press Enter to keep): " KEY_PATH_INPUT
case "$KEY_PATH_INPUT" in
  y|Y|yes|YES|Yes)
    echo "Keeping default identity key path."
    KEY_PATH_INPUT=""
    ;;
esac
KEY_PATH="${KEY_PATH_INPUT:-$DEFAULT_KEY_PATH}"

KEY_PATH="${KEY_PATH/#\~/$HOME}"
PUB_PATH="${KEY_PATH}.pub"

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

if [[ ! -f "$KEY_PATH" ]]; then
  echo "Creating Ed25519 key: $KEY_PATH"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$(whoami)@$(hostname -s)" -N ""
else
  echo "Using existing key: $KEY_PATH"
fi

if [[ ! -f "$PUB_PATH" ]]; then
  echo "Public key not found: $PUB_PATH" >&2
  exit 1
fi

chmod 600 "$KEY_PATH"
chmod 644 "$PUB_PATH"

if [[ -n "$PROXY_JUMP" ]] && ! host_alias_exists "$HOST_ALIAS"; then
  echo "Writing SSH config before key install so ProxyJump can be used..."
  write_ssh_config
fi

echo "Installing public key on ${USER_NAME}@${HOST}:${PORT}"
echo "If prompted, enter the password for the account shown by ssh-copy-id."

if host_alias_exists "$HOST_ALIAS"; then
  echo "Using SSH config Host alias: ${HOST_ALIAS}"
  ssh-copy-id \
    -i "$PUB_PATH" \
    "$HOST_ALIAS"
else
  ssh-copy-id \
    -i "$PUB_PATH" \
    -o StrictHostKeyChecking=accept-new \
    -o PubkeyAuthentication=no \
    -o PreferredAuthentications=keyboard-interactive,password \
    -p "$PORT" \
    "${USER_NAME}@${HOST}"
fi
success "Public key installed on ${USER_NAME}@${HOST}:${PORT}"

echo "Testing key login..."
test_key_login
success "Key login test passed with IdentityFile: ${KEY_PATH}"

write_ssh_config
test_ssh_config_alias
print_done
