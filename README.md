# toscpm

Dotfiles and a single `toscpm` command to verify, install, and set up my
dev environment on macOS, Linux, and Windows.

## Installation

```bash
git clone https://github.com/toscm/toscpm.git ~/repos/toscpm
~/repos/toscpm/toscpm link
```

This symlinks all dotfiles for the current OS into place (existing files
are backed up as `.bak`) and links `toscpm` into `~/.local/bin`.

## Usage

```bash
toscpm                  # health check: tools / dotfiles / self / repo
toscpm check            # same as above
toscpm install          # install missing tools, no-admin, into ~/.local
toscpm install rg fd    # install specific tools
toscpm install --all    # (re)install every tracked tool
toscpm install -n       # dry-run: print the no-admin commands (with live latest versions)
toscpm install -n --admin   # print the admin commands (apt/brew/winget) instead
toscpm link             # (re)create dotfile symlinks + self-install
```

`toscpm check` reports tools (installed?), dotfiles (symlinked?), self
(`toscpm` on PATH?), and repo (clean?).

`toscpm install` installs without admin rights — ideal for ephemeral
containers where `~` is mounted but system installs don't persist. On
Linux it fetches prebuilt static binaries (preferring musl) straight into
`~/.local`, resolving the latest release automatically via GitHub's
`releases/latest` redirect — no pinned versions, no API token. On macOS
and Windows it uses `brew` / `winget`, which are already non-privileged.

Tools with no sane no-admin path (`git`, `tmux`, `R`, `curl`, `wget`,
`python3`, `tree`) are skipped on Linux; run `toscpm install -n --admin`
to see their system commands.

## Scripts

Executables in `bin/` are symlinked into `~/.local/bin` by `toscpm link`,
so they land on PATH. Each is linked only on the OS it targets.

- `deepsleep` (macOS) keeps a clamshell MacBook asleep with an external
  display/mouse attached by re-issuing `pmset sleepnow` every 10 minutes;
  stop it with Ctrl-C to actually use the machine.
- `ptree` (Linux) shows processes as a memory-sorted tree, grouped by user
  (system users hidden by default). Flags: `-u` (current user only), `-a`
  (include system/service users), `-L N` (max depth), `-w N` (command
  width), `--hide` (drop vscode-cli / R-languageserver subtrees).

Helper scripts in `scripts/` (`configure_git`, `create_keypair`,
`create_user`) are run directly; legacy Ubuntu 22 install scripts in
`ubuntu22/`.
