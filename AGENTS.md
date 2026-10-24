# AGENTS.md

Project rules for AI agents working in this repository.

## What this repository is

A Quickshell (Qt6 / QML) network control panel for the Waybar bar in
[Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots).

- The code is **alpha**. It is untested, incomplete and expected to change
  shape. Do not describe it as working, stable or ready.
- The widget is **specific to Hyprland-Dots**. It relies on that project's
  config layout, wallust pipeline and helper scripts. Do not generalise it into
  a standalone widget, and do not add fallbacks for other desktops.
- Hyprland-Dots is usually checked out as a sibling directory at
  `../Hyprland-Dots`. Read it before assuming how anything on the Dots side
  works. Do not edit it from this repository.

## Source layout

- `src/quickshell/` — the widget: QML components, services, theme loader.
- `src/wallust/` — wallust template and config that emit the palette the widget
  reads.
- `template/` — early LLM-generated sketches, kept only as a design guide.

Rules that follow from that layout:

- Write real code in `src/`, never in `template/`.
- Treat `template/` as untested reference. It is not wired up, it is not a
  starting point to extend, and it should be expected to diverge or be deleted.
  Review it before borrowing anything from it; do not trust it.
- Git does not track empty directories. `src/quickshell/` and `src/wallust/`
  carry a `.gitkeep` so the tree shows up on GitHub. Keep the placeholder until
  a real file lands in the directory, then delete it in the same commit.

## Shell environment

The user's interactive shell is **zsh** (currently 5.9.2). This governs every
command an agent hands over to be run by hand.

- It applies to commands the user runs: their terminal, `ssh host '...'` triage,
  test systems.
- It does **not** apply to this repo's own scripts, which are bash
  (`#!/usr/bin/env bash`). Do not rewrite them for zsh.
- `ssh host 'cmd'` runs the remote **login shell**, so it is zsh on the test
  systems.
- The dangerous failure mode is not a loud error. Several bash-isms run happily
  in zsh and return **wrong data**, which then corrupts the analysis or the
  script built on top of it.
- Prefer the portable subset of both shells. When a snippet is genuinely
  bash-specific, force bash and say so.
- When a result matters, confirm the shell first: `echo $ZSH_VERSION` or
  `ps -p $$ -o comm=`.
- Get it right the first time. Generating a bash-ism, watching it fail, then
  re-issuing it for zsh wastes a round trip and risks a wrong conclusion in
  between.

### Never hand these over for a zsh shell

- `for x in $var` — zsh does not word-split, so it loops once over the whole
  string.
  - Use `while IFS= read -r x; do ... done <<<"$var"`.
- `${arr[0]}` — empty in zsh, arrays are 1-indexed. Use `${arr[1]}` or
  `"${arr[@]}"`.
- `**/` globs — recursive in zsh, but only with `shopt -s globstar` in bash.
  Same command, different file set.
- An unmatched glob — fatal in zsh (`no matches found`). Use `find`, or
  `setopt null_glob`.
- `shopt`, `mapfile`, `readarray` — bash-only. `read -p` and `BASH_REMATCH`
  mean something else, or nothing at all.
- `echo` with escapes — zsh's `echo` interprets them. Use `printf`.
- `status` — read-only in zsh, it is `$?`. `$path` — tied to `PATH` in zsh.
- `cmd | while read x` — the loop runs in the current shell in zsh, so variables
  it sets survive; in bash they do not. The same script reports different
  results.
- `set -e` / `pipefail` — close enough to be tempting, not close enough to rely
  on for exact error paths.

### Reliable escapes

- Force bash for a one-liner: `bash -c '...'`.
- Force bash over ssh without quoting games: `ssh host 'bash -s' <<'EOF' ... EOF`.
- Prefer tools that parse their own input (`find`, `grep -r`, `awk`, `jq`) over
  shell loops and globs.
- If output is empty, a single blob, or a suspiciously short list, suspect a
  shell mismatch before concluding the system is in that state.

### Commands the widget runs

- Backends are `nmcli`, `bluetoothctl` and `rfkill`. Use them directly, not
  through a shell.
- Do not build `sh -c` pipelines in QML. Every one is a shell-portability trap
  and an injection surface, and the panel has to work under whatever shell the
  session provides.
- Ask the tool for the field you want (`nmcli -t -f ...`, `--terse`) instead of
  grepping or `awk`-ing its human output.
- Never parse a command's output in QML with a regex that assumes English
  labels; the labels are localised.
- Prefer Quickshell's own service objects over spawning a process when one
  exists.

## Theming

- Colours come from wallust. Never hardcode a palette in QML, and never ship a
  second colour file alongside the one wallust writes.
- Hyprland-Dots already emits a Quickshell palette from its own wallust
  template. Read `../Hyprland-Dots/config/hypr/wallust/wallust.toml` and the
  templates under `../Hyprland-Dots/config/hypr/wallust/templates/` and consume
  that output. Do not invent new keys and do not rename existing ones.
- When wallust regenerates the palette, the panel must pick it up without a
  restart. Watch the file, do not poll it.
- Generated palette files are install output, not source. Do not commit them.

## Branch hygiene

- `git fetch --prune` and pull the current branch before editing. Never start
  work on a stale branch.
- Stash or commit local edits first, so the pull cannot fail or conflict.
- This repository currently has only `main`, so work lands on `main`.
  - Hyprland-Dots uses a `development` branch and targets it with pull
    requests. If this repo adopts the same two-branch flow, PRs target
    `development`, not `main`.
- Say which branch and commit the work started from.

## Changelog

`CHANGELOG.md` is the source of truth for user-facing changes.

- **Every entry is one line.** One top-level bullet per change: one short line,
  no trailing period, no wrapped sentences.
- Details, when they are genuinely needed, are nested bullets (`  - `). One
  short sentence per line. One idea per line.
- Keep every line under ~80 characters so it does not wrap when pasted.
- Markdown only. No prose paragraphs, no tables.
- Section headings keep the colon: `## Added:`, `## Fixed:`, `## Updated:`,
  `## Removed:`.
- Backtick code, paths, settings and keys.
- Add the entry as the change lands, under a heading at the top of the file.
  Never edit a section for a version that is already released.
- An entry that came from an issue or a PR ends with a link to it:
  `  - Issue: [#12](<url>)` or `  - PR: [#13](<url>)`.

For more detail on the format, and for the released-version and wiki-sync rules
that go with it, review:

- `../Hyprland-Dots/CHANGELOG.md`
- `../Hyprland-Dots/AGENTS.md`

Shape:

```markdown
## Added:

- `<thing>` `<one line summary>`
  - `<detail>`
  - PR: [#13](https://github.com/LinuxBeginnings/qs-network-widget/pull/13)
- `<second change>` `<one line summary>`
```

## Commit messages

- Short subject line, then an optional short body. Do not narrate the root
  cause.
- Reference files by basename, not full paths: `NetworkMenu.qml`,
  `wallust.toml`.
- One line per change, no paragraphs re-explaining the changelog entry.
- Example: `src: connect to a Wi-Fi network from the panel`

## Verifying work

- There is no test suite and no CI yet. Do not claim a change works because it
  parses.
- QML has no compiler pass, so a syntax error only shows at load. Load the panel
  through Quickshell and read its log output before saying a change is done.
- When a change touches `nmcli`, `bluetoothctl` or `rfkill` behaviour, run the
  command by hand first and check the output shape the code assumes.
- State plainly what was and was not verified. Untested code in an alpha repo is
  expected; a claim of testing that did not happen is not.

## Scope

- Do not commit changes to `../Hyprland-Dots`. It is a separate repository with
  its own rules.
- Do not add packaging, installers or dependency files that nothing consumes.
- Do not add licence headers, badges or generated documentation unless asked.
