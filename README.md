# SSH Key Helper

Small macOS/Linux shell helper for creating SSH config hosts, installing public
keys with `ssh-copy-id`, and selecting an existing SSH config host as
`ProxyJump`.

## Usage

```bash
bash setup_ssh_key.sh
bash setup_ssh_key.sh --login
bash setup_ssh_key.sh --alias inner-211
bash setup_ssh_key.sh --host example.com --port 22 --user alice
```

The script stores host entries in `~/.ssh/config`. For jump hosts, create the
jump machine as a normal SSH config `Host`, then select it from the `ProxyJump`
menu when creating or updating the inner host.

## Install

```bash
mkdir -p ~/scripts
cp setup_ssh_key.sh ~/scripts/setup_ssh_key.sh
chmod +x ~/scripts/setup_ssh_key.sh
```

Optional zsh helpers:

```bash
sshkey() {
  bash ~/scripts/setup_ssh_key.sh --setup "$@"
}

sshkeyjump() {
  bash ~/scripts/setup_ssh_key.sh --jump "$@"
}
```
