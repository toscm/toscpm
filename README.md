# Installers

Dotfiles and a single `check` command to verify and set up my dev
environment on macOS, Linux, and Windows.

## Installation

```bash
git clone https://github.com/toscm/installers.git ~/repos/installers
~/repos/installers/check.py --link
```

This symlinks all dotfiles for the current OS into place (existing files
are backed up as `.bak`) and links `check.py` to `~/.local/bin/check`.

## Usage

Run `check` for a status overview of tools (installed?), dotfiles
(symlinked?), self (`check` on PATH?), and repo (clean?). Missing tools
get ready-to-paste install commands. Use `--tools`, `--dotfiles`, or
`--repo` for single sections. `check --link` is idempotent.

## Scripts

Executables in `bin/` are symlinked into `~/.local/bin` by `check --link`,
so they land on PATH. `deepsleep` keeps a clamshell MacBook asleep with an
external display/mouse attached by re-issuing `pmset sleepnow` every 10
minutes; stop it with Ctrl-C to actually use the machine.

Helper scripts in `scripts/` (`configure_git`, `create_keypair`,
`create_user`) are run directly; legacy Ubuntu 22 install scripts in
`ubuntu22/`.
