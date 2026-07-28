# toscpm changelog

All notable changes to toscpm. Versions follow [semver](https://semver.org):
bump the **minor** version when a tool or dotfile is added or changed, the
**patch** version for fixes, and the **major** version for breaking changes to
the CLI. The current version lives in the [`VERSION`](VERSION) file (the single
source of truth); tag each release `vX.Y.Z` to match.

## 1.10.0

- Strip the decoration out of delta's diff output. `hunk-header-style =
  omit` drops the boxed `┌───┐ / 42: / └───┘` banner that delta printed
  before every hunk, and `file-decoration-style = none` drops the
  full-width rule under each filename. The filename stays, in bold, so
  files are still easy to tell apart. With `line-numbers = true` the
  hunk banner was pure redundancy anyway — the gutter already says
  which lines you are looking at.

- Drop `syntax-theme = auto`. There is no such theme, so bat printed
  `Unknown theme 'auto', using default` above every single diff. Delta
  already picks a sensible default; run `delta --list-syntax-themes` to
  choose an explicit one. (This corrects the 1.9.0 note below, which
  described the setting as working.)

## 1.9.0

- Set the neovim colorscheme to GitHub Dark Default via a new
  `dotfiles/anyos/nvim/lua/plugins/colorscheme.lua`, which adds the
  `projekt0n/github-nvim-theme` plugin and points LazyVim at it. The
  previous LazyVim default, `tokyonight-moon`, has a fairly light grey
  background (`#222436`); GitHub Dark Default is `#0d1117` and matches
  the theme I use in VS Code.

- Switch delta back to a unified (non-side-by-side) diff and turn on line
  numbers, hyperlinks, unlimited wrapping and automatic syntax-theme
  detection. Side-by-side halves the usable width, which hurts on a
  narrow terminal.

## 1.8.0

- Add the eza `ls`/`ll`/`la`/`l`/`lt` aliases to the PowerShell profile, so
  all three shells now share the same ls family. They fall back to the
  previous `la` = `Get-ChildItem` when eza is not installed.

  Note that `toscpm install` has no Windows recipe for eza yet, so on
  Windows the aliases stay dormant until eza is installed by hand.

## 1.7.0

- Manage zsh on Linux, not just on macOS. Previously `~/.zshrc` was only
  symlinked on macOS, so on a Linux box with zsh as the login shell none of
  the toscpm config applied — the `ls` -> `eza` alias lived in
  `dotfiles/linux/bash_aliases`, which only bash reads.

- Split the zsh config into a portable `dotfiles/anyos/zshrc` plus thin
  per-OS files (`dotfiles/macos/zshrc`, new `dotfiles/linux/zshrc`) that
  source it. The shared part holds completion, history, prompt, keybindings,
  the zoxide/fzf/yazi/clifm integrations and the aliases; each per-OS file
  keeps only what is genuinely OS-specific. All optional tools are now
  guarded by `command -v`, so the config works on a machine where they are
  not installed yet.

- Drop hardcoded `/Users/tobi` paths from the macOS zshrc in favour of
  `$HOME`, and make the zsh-autocomplete plugin opt-in via
  `$ZSH_AUTOCOMPLETE_PLUGIN` instead of a hardcoded checkout path.

- Give zsh the same eza alias set as bash (`ls`/`ll`/`la`/`l`/`lt`) with a
  coreutils fallback when eza is absent, and a root-aware prompt (red for
  root, blue otherwise) on both platforms.

## 1.6.0

- Update the git `lg1` alias in the `gitconfig` dotfile and add `lg2` and
  `lg` (= `lg1`): compact and expanded graph log formats over all refs.

## 1.5.1

- Add a "Markdown and plain-text docs" section to the global `CLAUDE.md`:
  use bold/italics sparingly, blank-line-separate multiline list items,
  prefer listings over tables wider than ~70 characters, and wrap prose at
  ~66 characters.

## 1.5.0

- Add the `ptree` bin script (Linux): processes as a memory-sorted tree,
  grouped by user, with per-user and grand-total memory summaries. Symlinked
  into `~/.local/bin` by `toscpm link` on Linux, like `deepsleep` on macOS.

## 1.4.0

- On Linux, alias `ls` to `eza` (matching macOS) when `eza` is installed, with
  eza-native `ll`/`la`/`l`/`lt` aliases; fall back to coreutils `ls --color`
  and its flag set when `eza` is absent.

## 1.3.1

- Fix `install` verification on Windows/macOS: `winget`/`brew` put tools on the
  system PATH, not in `~/.local/bin`, so verify by resolving the tool through
  PATH instead of the fixed `~/.local/bin/<tool>` location (which only holds the
  Linux no-admin binaries).
- On Windows, rebuild PATH from the registry (machine + user) before running
  each step so a tool `winget` just installed is visible to the same-run
  verification instead of failing on the current process's stale PATH.

## 1.3.0

- Add a `VERSION` file and this `NEWS.md` as the single source of truth for the
  toscpm version. `toscpm --version` prints it and `toscpm check` shows it on
  the Self line.

## 1.2.0

- Add `typst` (typesetting system) and `tidy` (HTML Tidy, needed by
  `R CMD check` to validate a package's HTML manual).
- Add the `GhDeb` recipe for tools whose only prebuilt Linux artifact is a
  Debian package; it is unpacked no-admin via `dpkg-deb` (falling back to
  `ar` + `tar`), reusing the `GhBin` basename-based install path.

## 1.1.1

- Add `glab` (GitLab CLI) Linux/Windows recipes and a remotes health check.

## 1.1.0

- Rename `check.py` to `toscpm` with an `install` subcommand and `bin/`
  PATH-linking.
- Track `yazi`, the global `CLAUDE.md` and `glab`; fix symlink detection.
- Install `claude` via its native installer instead of npm.
- Various dotfile updates (tmux, nvim/LazyVim, bash, PowerShell, Rprofile).

## 1.0.0

- Initial release: dotfiles plus a single `toscpm` command to verify, install,
  and set up the dev environment on macOS, Linux, and Windows.
