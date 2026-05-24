#!/usr/bin/env python3
"""Check development tools, dotfile symlinks, and repo status."""

import argparse
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent
HOME = Path.home()
LOCAL_BIN = HOME / ".local" / "bin"

OK = "✓"
FAIL = "✗"


def get_os():
    system = platform.system().lower()
    if system == "darwin":
        return "macos"
    if system == "linux":
        return "linux"
    if system == "windows":
        return "windows"
    sys.exit(f"Unsupported OS: {system}")


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

# (display_name, check_cmd, {os: install_cmd})
# check_cmd: str, or {os: str, "default": str} when the binary name differs.
# Missing OS key = tool not available on that OS.
TOOLS = [
    ("git",     "git",     {"macos": "brew install git",       "linux": "sudo apt install -y git",      "windows": "winget install Git.Git"}),
    ("gh",      "gh",      {"macos": "brew install gh",        "linux": "sudo apt install -y gh",       "windows": "winget install GitHub.cli"}),
    ("delta",   "delta",   {"macos": "brew install git-delta", "linux": "cargo install git-delta",      "windows": "winget install dandavison.delta"}),
    ("lazygit", "lazygit", {"macos": "brew install lazygit",   "linux": "go install github.com/jesseduffield/lazygit@latest", "windows": "winget install JesseDuffield.Lazygit"}),
    ("nvim",    "nvim",    {"macos": "brew install neovim",    "linux": "sudo apt install -y neovim",   "windows": "winget install Neovim.Neovim"}),
    ("micro",   "micro",   {"macos": "brew install micro",     "linux": "sudo apt install -y micro",    "windows": "winget install zyedidia.micro"}),
    ("tmux",    "tmux",    {"macos": "brew install tmux",      "linux": "sudo apt install -y tmux"}),
    ("zoxide",  "zoxide",  {"macos": "brew install zoxide",    "linux": "curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh", "windows": "winget install ajeetdsouza.zoxide"}),
    ("fzf",     "fzf",     {"macos": "brew install fzf",       "linux": "sudo apt install -y fzf",      "windows": "winget install junegunn.fzf"}),
    ("yazi",    "yazi",    {"macos": "brew install yazi",      "linux": "cargo install --locked yazi-fm yazi-cli", "windows": "winget install sxyazi.yazi"}),
    ("fd",      "fd",      {"macos": "brew install fd",        "linux": "sudo apt install -y fd-find",  "windows": "winget install sharkdp.fd"}),
    ("rg",      "rg",      {"macos": "brew install ripgrep",   "linux": "sudo apt install -y ripgrep",  "windows": "winget install BurntSushi.ripgrep.MSVC"}),
    ("bat",     {"default": "bat", "linux": "batcat"}, {"macos": "brew install bat", "linux": "sudo apt install -y bat", "windows": "winget install sharkdp.bat"}),
    ("eza",     "eza",     {"macos": "brew install eza",       "linux": "cargo install eza"}),
    ("tree",    "tree",    {"macos": "brew install tree",      "linux": "sudo apt install -y tree"}),
    ("python3", {"default": "python3", "windows": "python"}, {"macos": "brew install python", "linux": "sudo apt install -y python3", "windows": "winget install Python.Python.3.12"}),
    ("R",       "R",       {"macos": "brew install r",         "linux": "sudo apt install -y r-base",   "windows": "winget install RProject.R"}),
    ("node",    "node",    {"macos": "brew install node",      "linux": "sudo apt install -y nodejs",   "windows": "winget install OpenJS.NodeJS"}),
    ("curl",    "curl",    {"macos": "brew install curl",      "linux": "sudo apt install -y curl",     "windows": "winget install cURL.cURL"}),
    ("wget",    "wget",    {"macos": "brew install wget",      "linux": "sudo apt install -y wget",     "windows": "winget install JernejSimoncic.Wget"}),
    ("pandoc",  "pandoc",  {"macos": "brew install pandoc",    "linux": "sudo apt install -y pandoc",   "windows": "winget install JohnMacFarlane.Pandoc"}),
    ("claude",  "claude",  {"macos": "npm i -g @anthropic-ai/claude-code", "linux": "npm i -g @anthropic-ai/claude-code", "windows": "npm i -g @anthropic-ai/claude-code"}),
]


def check_tools(current_os):
    installed = []
    missing = []

    for name, check, installs in TOOLS:
        cmd = installs.get(current_os)
        if cmd is None:
            continue
        bin_name = check.get(current_os, check["default"]) if isinstance(check, dict) else check
        (installed if shutil.which(bin_name) else missing).append((name, cmd))

    n_ok, n_miss = len(installed), len(missing)
    names = ", ".join(n for n, _ in missing)

    if n_miss == 0:
        print(f"{OK} Tools      {n_ok} installed")
    else:
        print(f"{FAIL} Tools      {n_ok} installed, {n_miss} missing: {names}")

    return missing


def print_install_commands(missing):
    groups = {}
    standalone = []
    for _, cmd in missing:
        for prefix in ("brew install ", "sudo apt install -y ", "winget install "):
            if cmd.startswith(prefix):
                groups.setdefault(prefix.rstrip(), []).append(cmd[len(prefix):])
                break
        else:
            standalone.append(cmd)

    print()
    for prefix, pkgs in groups.items():
        print(f"  {prefix} {' '.join(pkgs)}")
    for cmd in standalone:
        print(f"  {cmd}")


# ---------------------------------------------------------------------------
# Dotfiles
# ---------------------------------------------------------------------------

# (symlink_path, repo_source_relative, os_filter_or_None)
DOTFILES = [
    ("~/.gitconfig",                  "dotfiles/anyos/gitconfig",             None),
    ("~/.Rprofile",                   "dotfiles/anyos/Rprofile",              None),
    ("~/.lintr",                      "dotfiles/anyos/lintr",                 None),
    ("~/.config/micro/bindings.json", "dotfiles/anyos/micro_bindings.json",   None),
    ("~/.config/nvim/init.lua",       "dotfiles/anyos/nvim_init.lua",         None),
    ("~/.zshrc",                      "dotfiles/macos/zshrc",                 "macos"),
    ("~/.bashrc",                     "dotfiles/linux/bashrc",                "linux"),
    ("~/.bash_aliases",               "dotfiles/linux/bash_aliases",          "linux"),
    ("~/.inputrc",                    "dotfiles/linux/inputrc",               "linux"),
    ("~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1",
     "dotfiles/windows/powershell_profile.ps1", "windows"),
]


def check_dotfiles(current_os):
    ok, broken = 0, []

    for symlink_path, repo_rel, target_os in DOTFILES:
        if target_os is not None and target_os != current_os:
            continue
        link = Path(symlink_path).expanduser()
        source = (REPO_DIR / repo_rel).resolve()

        if link.is_symlink() and link.resolve() == source:
            ok += 1
        else:
            reason = "not a symlink" if link.exists() else "missing"
            broken.append((symlink_path, reason))

    total = ok + len(broken)
    if not broken:
        print(f"{OK} Dotfiles   {total}/{total} symlinked")
    else:
        details = ", ".join(f"{p} ({r})" for p, r in broken)
        print(f"{FAIL} Dotfiles   {ok}/{total} symlinked: {details}")

    return len(broken) == 0


def link_dotfiles(current_os):
    for symlink_path, repo_rel, target_os in DOTFILES:
        if target_os is not None and target_os != current_os:
            continue
        link = Path(symlink_path).expanduser()
        source = REPO_DIR / repo_rel

        if not source.exists():
            print(f"  skip {symlink_path} (source missing)")
            continue
        if link.is_symlink() and link.resolve() == source.resolve():
            print(f"  {OK}    {symlink_path}")
            continue

        link.parent.mkdir(parents=True, exist_ok=True)
        if link.exists() or link.is_symlink():
            backup = link.with_suffix(link.suffix + ".bak")
            link.rename(backup)
            print(f"  back {symlink_path} -> {backup.name}")

        link.symlink_to(source)
        print(f"  link {symlink_path} -> {repo_rel}")


# ---------------------------------------------------------------------------
# Self-install
# ---------------------------------------------------------------------------

def check_self_install():
    check_bin = LOCAL_BIN / "check"
    script = REPO_DIR / "check.py"
    ok = (
        check_bin.is_symlink()
        and check_bin.resolve() == script.resolve()
        and str(LOCAL_BIN) in os.environ.get("PATH", "").split(os.pathsep)
    )
    if ok:
        print(f"{OK} Self       check -> ~/.local/bin/check")
    else:
        problems = []
        if not check_bin.is_symlink() or check_bin.resolve() != script.resolve():
            problems.append("not linked")
        if str(LOCAL_BIN) not in os.environ.get("PATH", "").split(os.pathsep):
            problems.append("~/.local/bin not in PATH")
        print(f"{FAIL} Self       {', '.join(problems)} (run: check --link)")
    return ok


def link_self():
    LOCAL_BIN.mkdir(parents=True, exist_ok=True)
    check_bin = LOCAL_BIN / "check"
    script = REPO_DIR / "check.py"

    if check_bin.is_symlink() and check_bin.resolve() == script.resolve():
        print(f"  {OK}    ~/.local/bin/check")
        return
    if check_bin.exists() or check_bin.is_symlink():
        check_bin.rename(check_bin.with_suffix(".bak"))
    check_bin.symlink_to(script)
    print(f"  link ~/.local/bin/check -> check.py")


# ---------------------------------------------------------------------------
# Repo status
# ---------------------------------------------------------------------------

def check_repo():
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=REPO_DIR, capture_output=True, text=True,
        )
    except FileNotFoundError:
        print(f"{FAIL} Repo       git not found")
        return True

    lines = [l for l in result.stdout.strip().splitlines() if l]
    if not lines:
        print(f"{OK} Repo       clean")
        return True

    print(f"{FAIL} Repo       {len(lines)} uncommitted change(s) in {REPO_DIR}")
    return False


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        prog="check",
        description="Check development tools, dotfile symlinks, and repo status.",
    )
    parser.add_argument("--link", action="store_true",
                        help="create symlinks for dotfiles and install 'check' into ~/.local/bin")
    parser.add_argument("--tools", action="store_true", help="only check tools")
    parser.add_argument("--dotfiles", action="store_true", help="only check dotfiles")
    parser.add_argument("--repo", action="store_true", help="only check repo status")
    args = parser.parse_args()

    current_os = get_os()

    if args.link:
        link_dotfiles(current_os)
        link_self()
        return

    show_all = not (args.tools or args.dotfiles or args.repo)

    missing_tools = []
    if args.tools or show_all:
        missing_tools = check_tools(current_os)
    if args.dotfiles or show_all:
        check_dotfiles(current_os)
    if show_all:
        check_self_install()
    if args.repo or show_all:
        check_repo()
    if missing_tools:
        print_install_commands(missing_tools)


if __name__ == "__main__":
    main()
