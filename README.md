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
toscpm update           # pull the latest toscpm (fast-forward only), then link + check
```

`toscpm check` reports tools (installed?), dotfiles (symlinked?), self
(`toscpm` on PATH?), and repo (clean? pushed? behind upstream?).
Tools with a `min_version` (nvim, tmux, the terminal emulators) are also reported when they are too old for the dotfiles, and `toscpm install` updates them.
Terminal emulators (Windows Terminal, iTerm2, Ghostty) are only tracked on a machine with a desktop, not on a headless server or in an ssh session.
On macOS, `toscpm link` also installs the iTerm2 dynamic profile `toscpm` (`dotfiles/macos/iterm2/toscpm.json`), which inherits from the profile `Default` and makes both Option keys act as Alt (Esc+), so nvim's and tmux's Alt bindings work; set it as the default profile once in iTerm2's settings.

`toscpm update` brings a machine up to date: it pulls the repo, links the dotfiles and runs `check`, which lists any tools that are now missing.
Install those with `toscpm install` when convenient.
It only fast-forwards: with uncommitted changes, unpushed commits or a diverged history it stops and says what to do, since merging two machines' releases can make `VERSION`, `NEWS.md` and the tags collide.

`toscpm install` installs without admin rights — ideal for ephemeral
containers where `~` is mounted but system installs don't persist. On
Linux it fetches prebuilt static binaries (preferring musl) straight into
`~/.local`, resolving the latest release automatically via GitHub's
`releases/latest` redirect — no pinned versions, no API token. On macOS
and Windows it uses `brew` / `winget`, which are already non-privileged.

Tools with no sane no-admin path (`git`, `tmux`, `R`, `curl`, `wget`,
`python3`, `tree`, `cc`) are skipped on Linux; run `toscpm install -n --admin`
to see their system commands.

## Scripts

Executables in `bin/` are symlinked into `~/.local/bin` by `toscpm link`,
so they land on PATH. Each is linked only on the OS it targets.
Windows cannot run a script through a symlink, so there `toscpm link` installs two shims per script instead, `<name>.bat` (cmd, PowerShell) and an extensionless sh script (Git Bash).

- `deepsleep` (macOS) keeps a clamshell MacBook asleep with an external
  display/mouse attached by re-issuing `pmset sleepnow` every 10 minutes;
  stop it with Ctrl-C to actually use the machine.
- `ft` (all OSes) prints a compact tree of a directory: folders (bold blue) as branches and the files of each folder on one wrapped line, ordered as ALL_CAPS files (README, NEWS.md, LICENSE, DESCRIPTION, ...), normal files, then dimmed config files (Makefile, Dockerfile, codecov.yml, cran-comments.md, ...), `_` files and dot files.
  It honours `.gitignore` inside git repos and summarises folders below `-L N` (default 2) as `name/ (N files)`; `-a` includes ignored files.
  Generated or binary files (Rd, rds, rda, pdf, png, svg, pyc, ...) are not listed by name but counted next to their folder, so an R package's `man/` shows as `man/ (24 Rd)`; `-f` lists them by name.
- `port` (all OSes) lists the ssh client connections of this machine and the ports each one forwards, with their source (command line, `~/.ssh/config` or added at runtime) and whether they really listen.
  The list is grouped under the hosts of `~/.ssh/config` (connections to any other host come last, under "others"), one line per connection and one per forward, so it stays readable in a narrow terminal.
  ProxyJump helpers show as "via" of their connection, and a port that several processes bind (Windows allows that) is flagged.
  `port forward 8765 myserver` starts a detached tunnel from local port 8765 to 127.0.0.1:8765 on myserver (`port forward LOCAL HOST[:RPORT] [RPORT | RHOST:RPORT]`), and `port cancel 8765` stops it again.
  `cancel` only kills `ssh -N` tunnels; for a forward of an interactive session it explains how to remove it there (`~C`, then `-KL 8765`).
  `port ls --json` prints the same as JSON for other tools; `port -h` documents the fields.
  Tunnels use BatchMode, so they need key authentication via a running ssh-agent; otherwise they fail with ssh's error instead of prompting.
- `ptree` (Linux) shows processes as a memory-sorted tree, grouped by user
  (system users hidden by default). Flags: `-u` (current user only), `-a`
  (include system/service users), `-L N` (max depth), `-w N` (command
  width), `--hide` (drop vscode-cli / R-languageserver subtrees).

Helper scripts in `scripts/` (`configure_git`, `create_keypair`,
`create_user`) are run directly; legacy Ubuntu 22 install scripts in
`ubuntu22/`.

## Autostart (Windows)

AutoHotkey scripts are not started from the Startup folder but from Task Scheduler tasks that `toscpm link` registers (list: `AUTOSTART` in `toscpm`).
Each task starts its script at logon and restarts it at every unlock, since a script running for weeks can silently stop receiving its hotkeys.
If a hotkey stops working anyway, lock and unlock the screen (Win+L), or run `schtasks /Run /TN toscpm-umlaute`.

- `toscpm-umlaute` runs `dotfiles/windows/autohotkey/umlaute.ahk`: Alt+a/o/u/s types ä/ö/ü/ß, with Shift the capitals.

- `toscpm-screensync` runs `dotfiles/windows/autohotkey/screensync.ahk`: copies each new screenshot in `Pictures\Screenshots` to `R:\home\toscm\pictures\screenshots` and `S:\home\tschmidt\pictures\screenshots` (those that exist, i.e. whose SSHFS drive is mounted) and puts its server path, `~/pictures/screenshots/<name>`, into the clipboard.
  A screenshot overwritten later (e.g. drawn into and saved again) is copied again.
  A server whose drive is dead or does not answer within 10 seconds is named in the notification (e.g. "rhskl2 not reachable") instead of blocking the script.
  Its tray icon is a picture; a click opens the screenshots folder.

- `toscpm-capman` runs `capman/capman.ahk` from the [capman](https://github.com/toscm/capman) repo, if it is cloned next to toscpm.
