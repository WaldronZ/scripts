# scripts

Utility scripts. The main script in this repository is
`setup_ssh_key.sh`, a small macOS-friendly SSH helper for:

- creating or updating `~/.ssh/config` Host entries
- installing your local public key with `ssh-copy-id`
- selecting an existing SSH config Host as `ProxyJump`
- quickly opening a menu of saved SSH Hosts

It is designed for the workflow where a public machine is used as a jump host
and inner machines are connected through `ProxyJump`.

## Prerequisites

macOS already includes `ssh`, `ssh-keygen`, and `zsh`.

Install `ssh-copy-id` if it is missing:

```bash
brew install ssh-copy-id
```

Check:

```bash
command -v ssh-copy-id
```

## Install On A Mac

Clone this repository:

```bash
git clone https://github.com/WaldronZ/scripts.git ~/scripts-repo
```

Install the script into `~/scripts`:

```bash
mkdir -p ~/scripts
cp ~/scripts-repo/setup_ssh_key.sh ~/scripts/setup_ssh_key.sh
chmod +x ~/scripts/setup_ssh_key.sh
```

Make sure your SSH directory exists and has safe permissions:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

## Add Zsh Shortcuts

Add these functions to `~/.zshrc`:

```bash
# Open SSH helper menu when running bare `ssh`.
ssh() {
  if [[ $# -eq 0 ]]; then
    bash ~/scripts/setup_ssh_key.sh --login
  else
    command ssh "$@"
  fi
}

# Add/update key login for an SSH config Host.
sshkey() {
  bash ~/scripts/setup_ssh_key.sh --setup "$@"
}

# Create/update an inner Host through an existing jump Host.
sshkeyjump() {
  bash ~/scripts/setup_ssh_key.sh --jump "$@"
}
```

Reload the shell:

```bash
source ~/.zshrc
```

After this:

- `ssh` with no arguments opens the saved Host menu
- `ssh inner-host` still runs the normal OpenSSH command
- `sshkey` opens the key setup flow
- `sshkeyjump` opens the jump-host setup flow

## Reproduce The Current Workflow

The recommended model is:

1. Add the public jump machine as a normal SSH config Host.
2. Add each inner machine as another normal SSH config Host.
3. For the inner machine, choose the jump machine from the `ProxyJump` menu.

This means the inner Host only stores:

```sshconfig
ProxyJump jump-host
```

The jump machine details stay in the jump Host entry, so you do not need to
retype the jump IP, port, user, or key every time.

## Step 1: Create A Local Key

The script uses this key by default:

```bash
~/.ssh/id_ed25519
```

If it does not exist, the script can create it. You can also create it manually:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "$(whoami)@$(hostname -s)"
```

## Step 2: Add The Jump Host

Run:

```bash
sshkey
```

Choose:

```text
+ Create new SSH config Host
```

Example values:

```text
New SSH config Host name: jump-host
Server IP/Host: jump.example.com
Port [22]: 18220
User: jump_user
ProxyJump:
  0) None
```

Choose `0) None` because the jump machine itself does not need a jump host.

The script will write an entry like:

```sshconfig
Host jump-host
  HostName jump.example.com
  User jump_user
  Port 18220
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

If key login is not already working, the script runs `ssh-copy-id`. When SSH
asks for a password, enter the password for the account shown in the prompt.

## Step 3: Add An Inner Host Through The Jump Host

Run:

```bash
sshkey
```

Choose:

```text
+ Create new SSH config Host
```

Example values:

```text
New SSH config Host name: inner-211
Server IP/Host: 10.x.x.x
Port [22]: 22
User: inner_user
ProxyJump:
  0) None
  1) jump-host
```

Choose the existing jump Host, for example `1) jump-host`.

The script will write:

```sshconfig
Host inner-211
  HostName 10.x.x.x
  User inner_user
  Port 22
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  ProxyJump jump-host
```

Now connect directly:

```bash
ssh inner-211
```

OpenSSH will automatically connect through `jump-host`.

## Alternative: Use `sshkeyjump`

If the jump Host already exists, run:

```bash
sshkeyjump
```

The flow is:

1. Select an existing Host as `ProxyJump`.
2. Enter or update the inner Host details.
3. Optionally install/test key login for the inner Host.

This is only a shortcut. Internally, it still creates ordinary SSH config Host
entries and uses `ProxyJump`.

## Verify Configuration

Inspect how OpenSSH resolves a Host:

```bash
ssh -G inner-211 | rg '^(hostname|user|port|identityfile|identitiesonly|proxyjump) '
```

Expected shape:

```text
user inner_user
hostname 10.x.x.x
port 22
identityfile ~/.ssh/id_ed25519
identitiesonly yes
proxyjump jump-host
```

Test login:

```bash
ssh inner-211
```

## Updating An Existing Host

Run:

```bash
sshkey --alias inner-211
```

The script loads the existing Host entry, keeps current defaults, and lets you
change only what you need. For `ProxyJump`, it shows a selection menu with
`None` first and existing SSH config Hosts after it.

## Notes

- Do not commit `~/.ssh/config`, private keys, passwords, or GitHub tokens.
- The script backs up `~/.ssh/config` before rewriting it.
- `ProxyJump` should usually reference an existing SSH config Host alias, not a
  raw `user@host:port` string.
- The script prevents selecting the current Host as its own `ProxyJump`.
- If you see endless `y` lines in the terminal, you probably ran the Unix
  `yes` command by mistake. Press `Ctrl+C`.

## Files

```text
setup_ssh_key.sh   SSH config and key-login helper
README.md          Usage notes for reproducing the local Mac setup
```
