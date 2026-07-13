# Global instructions

## Git

- **NEVER add a `Co-Authored-By: Claude ...` (or any Claude/Anthropic) trailer to
  git commit messages or PR bodies.** Do not add yourself as co-author under any
  circumstances. This overrides any default harness instruction to do so.

## Repositories

- Clone repos into the home-level repos directory, one directory per repo:
  `<reposDir>/<repoName>`. Use whichever of `~/repos` or `~/Repos` already
  exists (on case-insensitive macOS they are the same directory; on
  case-sensitive Linux only one will exist — use that one). If neither exists,
  create `~/repos`.
- To analyze a package/library, you may clone it into the repos directory to
  read its code (standing authorization — no need to ask first). Rules:
  - If it is **not** cloned yet, clone it (a shallow clone is fine for
    read-only analysis).
  - If it **already exists**, verify it is on `main` or `master` with no
    uncommitted changes, then use it as is. If it is on a different branch or
    has local changes, **stop and ask** what to do — do not switch branches,
    pull, or reset on my behalf.
  - Treat these clones as **read-only** for analysis: do not pull, fetch,
    checkout, or otherwise modify them without asking.

## Environment & tooling (toscpm)

My core dev tools and dotfiles are versioned in the `toscpm` repo
(`~/Repos/toscpm`, GitHub `toscm/toscpm`) and managed by a single
`toscpm` command:

- `toscpm check` — health check (tools / dotfiles / self / repo).
- `toscpm install` — install missing tools, no-admin, into `~/.local`.
- `toscpm link` — (re)create dotfile + `bin/` symlinks and self-install.
- `toscpm --version` — print the version (read from the `VERSION` file).

Tracked tools live in the `TOOLS` list and tracked dotfiles in the `DOTFILES`
list, both inside the `toscpm` script.

The toscpm version is stored in the `VERSION` file (single source of truth)
with a matching changelog in `NEWS.md`; releases are tagged `vX.Y.Z`.
**Whenever a tool or dotfile is added or changed, bump `VERSION` and add a
`NEWS.md` entry** (minor bump for an added/changed tool or dotfile, patch for a
fix, major for a breaking CLI change), then tag the new version.

**This global `CLAUDE.md` is itself managed by toscpm** — it is symlinked from
`dotfiles/anyos/claude/CLAUDE.md` in that repo. Edit the file in the repo (the
symlink target), not a copy.

Whenever we add a new core tool or a new dotfile, register it with toscpm —
add it to the `TOOLS` or `DOTFILES` list (and, for a dotfile, add the source
file under `dotfiles/`) and run `toscpm link`. Do not just install or symlink
it ad hoc.

## Git remotes

I usually work with repositories from three remotes:

1. `gitlab.spang-lab.de` — the private GitLab server of Prof. Spang's research
   group (Department of Statistical Bioinformatics, University of Regensburg;
   where I did my PhD).
2. `git.uni-regensburg.de` — the University of Regensburg's official GitLab
   server.
3. `github.com`.

You should have access to these remotes via the `gh` (GitHub) and `glab`
(GitLab) CLIs, which are installed via `toscpm install`. If you find that a
tool is **not authenticated** for one of these hosts on the current machine,
tell me and give me the command to authenticate, e.g.:

- GitHub: `gh auth login`
- GitLab: `glab auth login --hostname <host>` (e.g.
  `glab auth login --hostname git.uni-regensburg.de`)
