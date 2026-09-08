# toscpm changelog

All notable changes to toscpm. Versions follow [semver](https://semver.org):
bump the **minor** version when a tool or dotfile is added or changed, the
**patch** version for fixes, and the **major** version for breaking changes to
the CLI. The current version lives in the [`VERSION`](VERSION) file (the single
source of truth); tag each release `vX.Y.Z` to match.

## 1.23.0

- Disable nvim's Node, Perl, Python 3 and Ruby providers (`vim.g.loaded_*_provider = 0`).
  No plugin in the config is a remote plugin written in those languages, so the providers were only ever probed for and reported as missing by `:checkhealth`.

- Turn off luarocks support in lazy.nvim (`rocks = { enabled = false }`).
  No plugin needs luarocks, but lazy.nvim still looked for a hererocks-built Lua 5.1 and luarocks and flagged their absence as an error in `:checkhealth`.

## 1.22.0

- Show absolute line numbers in nvim instead of LazyVim's default relative ones (`relativenumber = false`); `<leader>uL` toggles relative numbers back for a session.

- Silence nvim's "Locale does not support UTF-8" health error on Windows by setting the C runtime's ctype locale to `en_US.UTF-8` from `options.lua`.
  The Windows build of nvim never calls `setlocale(LC_CTYPE, "")`, so `v:ctype` stays `C` unless `LANG` or `LC_ALL` is set, and `:checkhealth` flags it even though nvim is UTF-8 internally and the console code page is already 65001.
  The setting is guarded by `has("win32")`, so macOS and Linux keep taking the locale from the environment.

## 1.21.0

- Track a C compiler as the new `cc` tool: `xcode-select --install` on macOS, `build-essential` on Linux, and the WinLibs GCC (`winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e`) on Windows, where the tool is checked as `gcc`.
  LazyVim's treesitter check wants `cc`, `cl`, or on Windows a `gcc` on PATH, and nvim-treesitter's main branch builds parsers through the tree-sitter CLI, which spawns the compiler as a real executable; without one nvim opens with a "C compiler" error every start.
  RTools' gcc is deliberately not reused: it lives off PATH in a per-R-release directory (`C:
tools45`), the toolchain directory drags 170 executables (tidy, jq, sqlite3, cmake, ...) onto PATH, and a symlinked gcc.exe cannot find its own `as` and `cc1`, because gcc resolves them relative to its launch path.
  The WinLibs winget manifest declares `ArchiveBinariesDependOnPath`, so winget puts its `mingw64\bin` on the user PATH itself, exactly as it does for the other winget-installed tools.

## 1.20.0

- Show dates in ISO format (`yyyy-MM-dd`) in `Get-ChildItem` and eza output.
  The en-DE culture's short date pattern is `dd/MM/yyyy`, which cannot be told apart from the US `MM/dd/yyyy` by looking at it: `04/03/2026` is either 4 March or 3 April depending on a setting that appears nowhere in the output.
  The culture is cloned and only `ShortDatePattern` is overridden, so number formatting stays German (`1.234,50`), and the replacement is the same 10 characters wide, so the `Get-ChildItem` column does not shift.
  `ShortTimePattern` was already 24-hour and is left alone.

  eza formats its own dates and ignores the .NET culture, so it is set separately through `TIME_STYLE=long-iso`, its GNU-ls-compatible equivalent.

## 1.19.0

- Mark directories in `ls` output with reverse video on bright blue (`7;94`), replacing PowerShell's default `e[44;1m`.
  The default sets a blue background but no foreground, so directory names keep the scheme's normal foreground: on the light scheme that is #475365 on #3c60dd, a contrast ratio of 1.45:1, and unreadable.
  A fixed foreground/background pair from the palette cannot fix it either, because Monospace Light is built so that all 16 entries are readable on its near-white background, which makes all 16 of them dark -- the best pair it can form is 4.34:1.
  Reverse video is not a fixed pair: it makes the text the terminal's own background colour, so the contrast equals the palette entry's contrast against the background, which is the property a colour scheme already guarantees (4.95:1 on Campbell, 12.21:1 on Monospace Light).
  Being resolved at render time, it also follows the automatic light/dark scheme switch mid-session, which a value baked in at profile load cannot.
  The style is set on both `$PSStyle.FileInfo.Directory` and `EZA_COLORS`, so `ls` looks the same whether it resolves to eza or falls back to `Get-ChildItem`.

- Install eza on Windows via `winget install eza-community.eza`.
  Its `TOOLS` entry had recipes only for macOS and Linux, and toscpm treats a missing recipe as "this tool does not apply to this OS", so eza was silently absent from both `toscpm install` and `toscpm check` -- which is why check reported "22 installed" with nothing missing while eza was nowhere on the machine.
  The two entries that remain Windows-less, tmux and tree, now carry a comment saying why: tmux has no native Windows build and is used under WSL, and Windows already ships tree as `System32	ree.com`.

## 1.18.0

- Link the nvim and yazi configs to the directories those tools actually read on Windows: `%LOCALAPPDATA%/nvim` and `%APPDATA%/yazi/config`.
  Both were linked to `~/.config/...` on every OS, which Windows nvim and yazi ignore unless `XDG_CONFIG_HOME` is set, so `nvim` started as plain Neovim without LazyVim and yazi ran with none of its config.
  `toscpm check` reported them as linked the whole time, because the symlink it checked did exist.
  The two entries are now per-OS in `DOTFILES`; the config itself stays shared under `dotfiles/anyos/`.
  micro needs no such split: it looks in `~/.config/micro` on every OS.

## 1.17.0

- Install `tidy` on Windows from the upstream GitHub zip into `~/.local/bin` instead of through winget.
  The winget package `HTACG.tidy` unpacks into a versioned `C:\Program Files\tidy <ver>\bin` and puts nothing on `PATH`, so `tidy` stayed invisible to `toscpm check` and to `R CMD check` (which needs it to validate the HTML manual), and every `toscpm install` retried the winget install and failed with "Found an existing package already installed".
  A tool can now carry a `user_windows` recipe (`GhZip`) next to `user_linux`; it is downloaded and unpacked in-process, since cmd.exe has no dependable curl/unzip/install equivalents.
  For tidy that means `tidy.exe` plus the `tidy.dll` it is linked against, which Windows resolves next to the executable.

## 1.16.1

- Install an extensionless `toscpm` shell shim next to `toscpm.bat` on Windows, so the command is also found in Git Bash and other POSIX shells.
  Those shells do not resolve the `.bat` suffix, so `toscpm install` failed there with "command not found" even though the launcher was installed.
  The shell shim is written with LF line endings, since `/bin/sh` chokes on CRLF.
  `toscpm link` now also removes the stale `check.bat` launcher left over from the old `check` name, which it previously only did for the POSIX `check` symlink.

## 1.16.0

- Add a three-state word wrap cycle on Alt-Z in `dotfiles/anyos/nvim/lua/plugins/wrap-cycle.lua`, mirroring the word wrap status bar item vstosc adds to VS Code: off, on (wrap at the window edge), and bounded at column 80.
  Vim has no native bounded soft wrap, so the bounded state uses the `rickhowe/wrapwidth` plugin, which wraps virtually at a column via inline virtual text without touching the buffer.
  The current state is shown in lualine as "Wrap: off", "Wrap: on" or "Wrap: 80".
  `linebreak` stays off, so wrapped lines break mid-word at the window edge or column.
  The plugin is pinned in `dotfiles/anyos/nvim/lazy-lock.json`.

## 1.15.0

- Put `~/.cargo/bin` on `PATH` in `dotfiles/linux/bashrc`, `dotfiles/linux/zshrc` and `dotfiles/macos/zshrc`.
  Binaries from `cargo install` and toolchains managed by rustup are then found without sourcing `~/.cargo/env` in every shell.
  The entry goes behind `~/.local/bin`, so a tool tracked by toscpm still wins over a cargo-installed one of the same name.
  All three are guarded on the directory existing, so shells on machines without Rust are unaffected.

## 1.14.0

- Switch the Neovim colorscheme in `dotfiles/anyos/nvim/lua/plugins/colorscheme.lua` from `github_dark_default` to Neovim's built-in `default`.
  The `projekt0n/github-nvim-theme` plugin stays installed, so `<leader>uC` still previews the GitHub themes.

- Disable spell checking.
  `vim.opt.spell = false` in `lua/config/options.lua` turns it off globally.
  That alone does not hold, because LazyVim force-enables `spell` for text, markdown, gitcommit, plaintex and typst buffers, so `lua/config/autocmds.lua` now deletes its `lazyvim_wrap_spell` autocmd group and re-adds a `wrap_no_spell` group carrying only the soft-wrap half of that behaviour.
  Spell checking is still available per buffer via `<leader>us`.

- Update the pinned plugin commits in `dotfiles/anyos/nvim/lazy-lock.json`, covering 10 plugins including LazyVim itself.

## 1.13.0

- Show the current user and git branch in the tmux status bar, and drop the clock and date to make room.
  The right side of the bar now reads `user  path  branch`, where the branch part is empty outside a git repo and falls back to the short commit SHA on a detached HEAD.

- Define the status bar once as the `@status_right` user option in `dotfiles/anyos/tmux.conf`.
  The three places that set `status-right` (startup and the two MOVE MODE exit bindings) now reference it as `#{E:@status_right}` instead of repeating the whole format string.
  Also raise `status-right-length` from its 40-character default to 100, so the longer bar is not truncated.

- Lower `status-interval` from 15 to 5 seconds in `dotfiles/anyos/tmux.conf`.
  The branch is produced by an `#()` shell call, which tmux only re-runs on that interval, so a `cd` into another repo used to take up to 15 seconds to show up.

## 1.12.0

- Set `options(languageserver.nested_packages_depth = 1)` in `dotfiles/anyos/Rprofile`, so the R language server indexes R packages that live in sub-directories of the opened folder.
  Without it, opening `~/repos` gives no workspace symbols at all, because the server only indexes a folder that is itself an R package.
  The option sits outside the `if (interactive())` guard on purpose: the language server starts via `R --no-echo -e "languageserver::run()"`, which is not interactive, so anything inside that guard never reaches it.
  The setting requires the patched `languageserver` from the fork at `toscm/languageserver` (version `0.3.18.7056`); on stock CRAN `languageserver` it is simply ignored.

## 1.11.0

- Replace the "wrap prose at ~66 characters" markdown rule in
  `dotfiles/anyos/claude/CLAUDE.md` with "always write one sentence per
  line (no character limit)". Editors soft-wrap anyway, and one sentence
  per line greps and diffs far better: rewording a sentence touches
  exactly one line instead of reflowing a whole paragraph.

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
