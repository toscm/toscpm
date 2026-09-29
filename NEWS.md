# toscpm changelog

All notable changes to toscpm. Versions follow [semver](https://semver.org):
bump the **minor** version when a tool or dotfile is added or changed, the
**patch** version for fixes, and the **major** version for breaking changes to
the CLI. The current version lives in the [`VERSION`](VERSION) file (the single
source of truth); tag each release `vX.Y.Z` to match.

## 1.46.0

- `tmux.conf`: tmux and everything running in it now follow Windows Terminal between light and dark.
  Apps ask tmux for the background colour (OSC 11), and tmux answers from a copy it reads from the terminal on attach and refreshes only when the terminal reports a theme change via mode 2031.
  Windows Terminal never sends that report, so after a toggle bat, delta and nvim kept seeing the old background until the next attach.
  A `client-focus-in` hook (with `focus-events on`) now asks the terminal for its colours again whenever it regains focus; tmux takes the reply, updates its copy and notifies panes that subscribed to mode 2031.
  The query is written to the client tty directly, since making tmux re-query via SIGWINCH redraws the whole screen and flickers on every focus change.
  An already attached client only starts sending focus events after it reattaches.

- `tmux.conf`: the status bar is the terminal's default colours reversed (`fg=default,bg=default,reverse`) instead of green, so the terminal recolours it the moment the scheme flips.
  tmux 3.7c exposes no format for the terminal background, so a status style cannot pick colours per theme itself.
  MOVE MODE now restores this style from `@status_style` instead of unsetting it, which reverted it to tmux's default green.

- `nvim`: the colorscheme also asks for the terminal background on `FocusGained`, now and again after 500 ms, so a toggle is picked up without `:ThemeSync`.
  The second ask covers the tmux case, where the refreshed colours arrive just after the focus event.

## 1.45.1

- The `totalcmd-ini` git filter also pins `ShowHiddenSystem` and `IgnoreListFileEnabled` in `wincmd-shared.ini` to their committed values.
  Total Commander saves both whenever you toggle hidden/system files or the ignore list, which left the repo dirty and made `toscpm check` report a changed dotfile.
  To change either default, edit the filter in `GIT_FILTERS`, not the ini.

## 1.45.0

- New command `toscpm update`: pulls the repo, then runs `toscpm link` and `toscpm check` with the pulled script.
  It installs no tools; `check` lists the missing ones, and `toscpm install` installs them.
  It only fast-forwards and stops with instructions on uncommitted changes, unpushed commits or a diverged history, since a rebase can make `VERSION`, `NEWS.md` and the tags of two machines collide.

- `toscpm check` fetches the repo and reports unpushed commits and commits behind upstream, suggesting `toscpm update` when that is all there is to do.
  Offline, it reports the local state and notes that it could not compare with upstream.

## 1.44.0

- New dotfile `bat/config`: `--theme-light="GitHub"` and `--theme-dark="Monokai Extended"`.
  bat 0.25 and newer ask the terminal for its background colour at startup and pick one of the two, so bat follows the terminal between light and dark.

- `bat` no longer counts as installed when only Ubuntu's `batcat` is present.
  Ubuntu 22.04 ships batcat 0.12, which predates that detection and always uses a dark theme; `toscpm install bat` now installs the current release instead.

- `nvim`: the colorscheme follows the terminal background, `github_light_default` on light and `github_dark_default` on dark.
  Neovim ignores the terminal's answer once a colorscheme has set 'background', so the config reads the answer itself; `:ThemeSync` asks again after a toggle.

## 1.43.0

- `gitconfig`: `delta.hyperlinks = false`.
  delta wraps every line number in an OSC 8 link, and `less` passes those through only from version 566 on; Ubuntu 22.04 ships 551, which shows them as raw `8;;file:///...` text in every `git diff`.

## 1.42.0

- New tool recipe for `tmux`: built from the latest release tarball into `~/.local` instead of installed with apt.
  Ubuntu 20.04 ships 3.0a, which discards OSC 8 hyperlinks (they arrived in 3.4) and rejects the `window-size latest` already in `tmux.conf` (3.1).
  The build needs a compiler and the libevent and ncurses headers; the recipe checks for those and names the package to install, since only that part needs admin.

- `tmux.conf`: `set -as terminal-features ",*:hyperlinks"`.
  tmux emits OSC 8 only for terminals it believes support them, and believes that of almost no TERM value, so Windows Terminal and iTerm2 have to be told explicitly.
  Without this line even tmux 3.7 swallows the link.

- `code`: in a plain SSH session it now lists the VS Code windows currently connected to this host and offers to open the path in one of them, falling back to the link when none is running, when the offer is declined, or when stdin is not a terminal.
  Windows are found by connecting to each `vscode-ipc-*.sock` in the runtime directory, and labelled with the address of the machine that opened them, read from the `SSH_CLIENT` of the process listening on the socket.
  Set `CODE_OPEN=never` to always get the link.
  The link is now emitted as an OSC 8 hyperlink under tmux 3.4 and newer, and as a bare URL under older ones.

## 1.41.1

- `code`: a tmux pane that outlived the VS Code window it was started in now prints the link instead of failing with `Unable to connect to VS Code server`.
  Such a pane keeps the stale `VSCODE_IPC_HOOK_CLI` of the old window, and the socket file it names often lingers as well, so the variable is no longer trusted on its own: the shim connects to the socket first and treats a refused connection like a plain SSH session.

## 1.41.0

- New bin script `code` (Linux only): in a plain SSH session it prints a `vscode://vscode-remote/ssh-remote+<host>/<path>` link instead of failing.
  Ctrl-clicking it in Windows Terminal, or Cmd-clicking it in iTerm2, opens that path in the local VS Code over Remote-SSH; Terminal.app and tmux 3.0 cannot linkify it, so there the URL has to be copied by hand.
  Inside a VS Code terminal it passes every argument on to the real `code` CLI from `~/.vscode-server`, so nothing changes there.
  The host name in the link defaults to the short hostname and can be overridden with `CODE_SSH_HOST` when the local ssh config uses a different alias.

## 1.40.0

- "Copy as Linux path": Alt+C in Total Commander and a new Explorer context menu entry copy paths with forward slashes, one per line.
  On an SSHFS-Win drive the drive letter becomes `/` for a root mount (`\\sshfs.kr\...`) or `~` for a home mount (`\\sshfs.k\...`), looked up per drive with `WNetGetConnectionW`, so `R:\data\x` becomes `/data/x`.
  Every other path keeps its drive letter, `C:\Users\x` becomes `C:/Users/x` and `\\srv\share` becomes `//srv/share`, which Windows tools, R, Python and git all accept.

- New linked files in `dotfiles/windows/totalcmd`: `copy_as_linux_path.py` does the conversion, and `usercmd.ini` defines `em_CopyAsLinuxPath`, which runs `pythonw.exe copy_as_linux_path.py --list %UL` with the start folder `%COMMANDER_INI%\..`.
  The script uses only the standard library, and `pythonw` has no console window, so nothing flashes and a press takes about 0.1 s.
  It writes any error to `%TEMP%\copy_as_linux_path.log`, since `pythonw` has nowhere to show one.
  The start folder is what locates the script: TC does not expand environment variables in `param=` and reads the `%A` of `%APPDATA%` as its own placeholder.

- `toscpm link` registers the context menu entry under `HKCU\Software\Classes\AllFilesystemObjects\shell\CopyAsLinuxPath`, for files and folders, without admin rights.
  The command stores the full path of `pythonw.exe` found on PATH at link time, because the shell does not search PATH for verb commands; rerun `toscpm link` if that Python moves.
  The entry is hidden when several items are selected, because Explorer would start one process per item and each would overwrite the clipboard; Alt+C handles a whole selection.

- Alt+C used to open TC's "Commands" menu; F10 still opens the menu bar.

## 1.39.0

- `gitconfig`: `https://git.uni-regensburg.de` uses the generic credential provider, like Overleaf already did.
  Git Credential Manager then asks for username and token instead of attempting GitLab's browser login; machines without GCM ignore the setting.

- Update the pinned plugin commits in `dotfiles/anyos/nvim/lazy-lock.json`, covering 10 plugins including LazyVim itself.

## 1.38.0

- New Windows dotfiles for Total Commander in `dotfiles/windows/totalcmd`, linked into `%APPDATA%\GHISLER`.
  `wincmd.ini` itself stays local because it also holds machine-specific state (directory hotlist, history, panel paths, window positions, plugin paths).
  Instead, its `[Configuration]`, `[Layout]`, `[Shortcuts]` and `[Colors]` sections each contain only `RedirectSection=%COMMANDER_INI%\..\wincmd-shared.ini`, and TC reads and writes those sections in the linked `wincmd-shared.ini`.
  On a new machine, add these four lines to the local `wincmd.ini` once, by hand.

- Total Commander: a colour filter greys out dotfiles and dot directories (`ColorFilter1=.* .*\`, with separate normal and dark mode colours), so they stand out even while the ignore list is off.

- Total Commander: Ctrl+. (`C+OEM_.=cm_SwitchIgnoreList`) toggles the ignore list, and the linked `ignore.txt` lists `.*` and `.*\`, so the toggle hides dotfiles and dot directories without touching the hidden and system attributes.
  The ignore list starts disabled: while it is on, TC also leaves ignored items out when copying a folder, so copying a repo would silently drop `.git`.

- Total Commander: F4 opens files in VS Code via its full path (`Editor="%ProgramFiles%\Microsoft VS Code\Code.exe" "%1"`).
  A bare `code.exe` failed with "File not found", because only `bin\code.cmd` is on PATH, not `Code.exe`.

- Total Commander: F2 renames the file under the cursor in place (`F2=cm_RenameOnly`, the same as Shift+F6), like in Explorer.
  This replaces TC's default F2 action of rereading the panel, which Ctrl+R still does.

- `toscpm link` now registers the git filters named in `.gitattributes`.
  The first one, `totalcmd-ini`, strips TC's `firstmnu` start counter from `wincmd-shared.ini`, which TC bumps on every launch and would otherwise leave the repo dirty.

## 1.37.0

- tmux: the status bar now shows the current time (`%H:%M`) at the far right, after the git branch.
  The shared `@status_right` option is now referenced with `#{T:...}` instead of `#{E:...}`, because only `T:` applies strftime to the expanded text.

## 1.36.0

- Every recipe that installs Python packages now goes through uv.
  `pauk` installs itself with `uv pip install --python <venv> -e`, and piper's Windows recipe uses `uv tool install piper-tts` instead of `pip install piper-tts`, so the command lands in its own environment rather than in whatever Python happens to be first on PATH.
  pauk's venv keeps `--seed`, because `pauk update` reinstalls with `python -m pip`.

## 1.35.0

- New tool `python`: `uv python install 3.13 --default` puts a managed Python 3.13 and the commands `python`, `python3` and `python3.13` into `~/.local/bin`, which comes before `/usr/bin` on PATH.
  New shells therefore start 3.13 instead of the system Python.
  The system `python3` is untouched, so apt and other tools with a `/usr/bin/python3` shebang keep working, and `sudo` does not use this PATH at all.
  Note that uv's interpreters are marked externally managed: `python3 -m pip install <pkg>` refuses to install outside a virtual environment, so use a venv or `uv tool install`.

## 1.34.0

- New tool `uv` (Python package and interpreter manager), installed without admin rights by the official installer into `~/.local/bin`.

- `pauk`: the venv is now created with `uv venv --seed --managed-python --python ">=3.10"` instead of `python3 -m venv`.
  The old recipe failed on Ubuntu 20.04, whose `python3` is 3.8 (pauk needs 3.10 or newer) and lacks `ensurepip` without the admin-only `python3-venv` package.
  `--seed` keeps pip in the venv, so `pauk update` still works.

## 1.33.0

- `dotfiles/anyos/nvim`: the arrow keys select entries in the command line completion menu.
  blink.cmp's `cmdline` keymap preset only binds `<Tab>`/`<S-Tab>` and `<C-n>`/`<C-p>`, so `<Up>` and `<Down>` are added in `lua/plugins/completion.lua`.
  With the menu closed they still recall the previous or next command line, as before.

## 1.32.0

- `dotfiles/anyos/nvim`: notification boxes size themselves to the message again, between 40 columns and the full width, instead of always being full width.
  Snacks right-aligns them, so a short message hugs the right gutter and only a long one reaches column 3.

- `dotfiles/anyos/nvim`: notifications stay for five seconds instead of three, errors stay until dismissed with `<leader>un`, and `height.max` goes from 60% to 75% of the editor.
  A message too tall even for that is not cut silently: the footer says how many lines are left and `<leader>n` shows the full text.

- `dotfiles/anyos/nvim`: `winblend` for notification windows goes from 5 to 0, so the text no longer blends into what is behind the box.

## 1.31.0

- `dotfiles/anyos/nvim`: new `lua/plugins/notifier.lua` makes notifications readable.
  The box spans the editor width minus a two column gutter on each side (line 3, column 3 to column n-2) instead of the default right-aligned 40%, which left about 20 usable columns on a narrow terminal, and long lines now wrap instead of being cut off.

## 1.30.0

- `dotfiles/anyos/nvim`: colorscheme back to `github_dark_default` instead of Neovim's built-in default.
  `<leader>uC` still previews the others for the running session.

## 1.29.0

- `dotfiles/anyos/nvim`: lualine again instead of the native statusline, with the nerd font symbols taken out.
  `lua/plugins/lualine.lua` now re-enables lualine and strips LazyVim's icons: the diagnostic glyphs become `E:`/`W:`/`I:`/`H:`, the git diff glyphs `+`/`~`/`-`, the pending updates glyph the word `updates`, and the filetype, root directory, readonly, symbol kind and clock icons are dropped.
  `lua/config/statusline.lua` is gone.

- `dotfiles/anyos/nvim`: the word wrap state is a lualine item again, shown as `off`, `on` or `80` (not `Wrap: off`) and still clickable for the wrap menu.

## 1.28.0

- `dotfiles/anyos/nvim`: plain native statusline instead of lualine.
  lualine is disabled (new `lua/plugins/lualine.lua`) and `lua/config/statusline.lua` sets 'statusline' to one colour, no icons and no separators: mode, file name, word wrap state, git branch, count of plugins with pending updates, then position as percentage and line:column.
  The word wrap item is clickable and opens a menu (vim.ui.select) to choose off / on / 80 columns.

- `dotfiles/anyos/nvim`: word wrap state logic moved from `lua/plugins/wrap-cycle.lua` into the new `lua/config/wrap.lua`, shared by the Alt-Z cycle and the statusline menu.

- `dotfiles/anyos/nvim`: `<F1>` and `<leader>p` open the keymaps picker (`Snacks.picker.keymaps`), the closest thing to VS Code's command palette; `<leader>sk` still works.

## 1.27.0

- `dotfiles/anyos/nvim`: new `lua/plugins/completion.lua`.
  blink.cmp no longer opens the completion menu on its own in markdown, text and gitcommit buffers; `<A-\>` (as in VS Code) or `<C-Space>` opens it on demand.

## 1.26.0

- `dotfiles/anyos/tmux.conf`: set `window-size latest`, so the terminal is sized after the most recently active client instead of the smallest attached one (a forgotten client on another machine no longer caps the height).

## 1.25.0

- Add `ffmpeg` (with `ffprobe`) to `TOOLS`.
  The no-admin Linux path installs the johnvansickle static build rather than a GitHub release, because BtbN's asset names carry a build hash and cannot be templated.

- Add `piper` (neural text-to-speech) to `TOOLS`, installed by the new `scripts/install_piper`.
  piper ships as a binary plus shared libraries, espeak phoneme data and a separate voice model, so the tree goes to `~/.local/share/piper` and `~/.local/bin/piper` is a wrapper that sets `LD_LIBRARY_PATH` and defaults to the voice named by `PIPER_VOICE` (`en_GB-alan-medium` unless set).

- `dotfiles/anyos/gitconfig`: `core.editor` is `nvim` instead of `code --wait`.

## 1.24.0

- Add pauk, the flashcard CLI (github.com/toscm/pauk), as a tracked tool.
  The no-admin recipe clones the repo into the repos dir, installs the CLI editable into cli/.venv, and symlinks the entry point into ~/.local/bin.
  Updates are handled by `pauk update` (git pull + reinstall), so toscpm only needs to guarantee presence.

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
