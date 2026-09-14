# dots

My terminal setup, in one script. **macOS and Linux/Ubuntu** (including a bare VPS).

- [starship](https://starship.rs) prompt with per-project icons (Python 🐍, PHP 🐘,
  Drupal 💧, Java ☕, Ruby 💎, R 📊, Bash 🐚, Node ⬢, Rust 🦀, Go 🐹) and a custom
  color palette borrowed from [Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots)
- [eza](https://github.com/eza-community/eza) for icon-based `ls`/`ll`/`la`/`lt`
- [Neovim](https://neovim.io) + [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim),
  the official minimal starter config
- [Ghostty](https://ghostty.org) as the local terminal layer on macOS, with
  [terminal-browser](https://github.com/zenbu-labs/terminal-browser) and Kitty
  graphics support for browser panes inside herdr
- A Nerd Font ([Hack Nerd Font Mono](https://www.nerdfonts.com)) — **macOS only**, see below
- [Claude Code](https://claude.com/claude-code) and [Codex](https://github.com/openai/codex) CLIs
- [herdr](https://herdr.dev) itself, plus a curated set of its plugins — see below

## Install

```sh
git clone https://github.com/heydru-oficial/dots.git
cd dots
./install.sh
```

Flags: `--skip-herdr`, `--skip-nvim`, `--skip-font`, `--skip-ghostty`,
`--skip-agents`, `--yes`. Safe to
re-run — every step checks for existing state before touching it, and it backs up your
existing `~/.config/starship.toml` if one differs from the one in this repo.

On macOS, launch `herdr` from Ghostty. Apple Terminal does not support the Kitty
graphics protocol used by terminal-browser; unsupported graphics frames appear as
raw `Ga=...` text instead of a browser. Ghostty works without extra configuration.

## macOS vs. Linux

**macOS** installs everything through Homebrew, same as always.

**Linux** (tested against a fresh Ubuntu 24.04 container, non-root user with `sudo`)
installs a Rust toolchain via [rustup](https://rustup.rs) and uses `cargo install` for
`starship`/`eza`/`ripgrep`/`fd`, downloads official prebuilt binaries for Neovim and
`tree-sitter-cli`, and uses Claude Code's and Codex's own official install scripts —
**none of this needs sudo**, everything lands under `~/.cargo`, `~/.local`, or
`~/.codex`.

The **only** step that can need sudo is a one-time bootstrap: if your system is missing
`curl`, `git`, a C compiler, or `ca-certificates` (true of a bare Docker/cloud image,
usually already present on a real VPS), the script prints the exact
`sudo apt-get install -y ...` command it wants to run and **asks before running it**.
Pass `--yes` to skip that confirmation for unattended/automated runs.

Both `~/.zshrc` (if `zsh` is installed) and `~/.bashrc` get the alias/prompt block on
Linux, since a bare Ubuntu box ships bash only.

**Not installed on Linux:** Ghostty and the Nerd Font. A
remote box has no terminal of its own — the font needs to live on the machine you're
*viewing* the terminal from (your laptop's SSH client), not the server. Install a Nerd
Font and a Kitty-graphics-capable terminal locally. This setup uses Ghostty on macOS.

## About the herdr plugins

[herdr](https://herdr.dev) is a terminal/workspace manager built for running
several AI coding agents (Claude Code, Codex, Copilot, etc.) side by side.
`herdr/plugins.txt` lists ten community plugins this setup links in — a git
sidebar, an nvim sidebar, an agent quota monitor, tab auto-naming, and a few
others, including terminal-browser (one, `herdr-flock`, is pure novelty — pixel-art
sheep for your agents).

**herdr's plugin registry is unvetted.** Anyone can publish a plugin by
tagging a GitHub repo `herdr-plugin`; nothing in the list is reviewed by
herdr itself. Before running this against your own machine, open
`herdr/plugins.txt` and skim each linked repo. `install.sh` links plugins
locally (`herdr plugin link`) rather than through herdr's own remote
installer, so you always have the exact cloned source on disk at
`~/.local/share/herdr-plugins/` to read.

`install.sh` installs herdr itself too, via its
[official installer](https://herdr.dev) (`curl -fsSL https://herdr.dev/install.sh | sh`,
no sudo, works on macOS and Linux) — skipped if `herdr` is already on `PATH`.

**On a machine where herdr has never been run**, plugin *linking* still works (it's just
file/registry setup), but `herdr-agent-quota`'s sidebar rows can't be configured until
herdr's server is actually running — that step needs a live process to talk to. If
`install.sh` prints a warning about this, run `herdr` once (just start it up), then run
the one-line command it printed to finish that part.

### Local patches

`herdr/patches/` holds small source patches applied to a plugin right after it's cloned,
before it's built — for bugs/gaps found in a plugin that are worth fixing without waiting
on upstream. Currently just `herdr-sidebar.patch`: it makes the "hide dotfiles" toggle
(`.` key, or the ⚙ Settings modal) actually persist. Upstream, that setting lived only on
the in-memory tree and reset to shown-by-default on every rebuild (e.g. whenever
"follow pane folder" re-roots the tree) — this patch moves it into the plugin's own
persisted settings file, the same place `color_theme`/`sidebar_width`/etc. already live,
so it now survives exactly what it always claimed to. Verified against a fresh upstream
clone: patch applies cleanly, all 196 tests pass (one new one added), `cargo clippy -- -D
warnings` clean.

If a patch fails to apply (upstream moved past what it expects), `install.sh` warns and
falls back to the plugin unpatched rather than failing the whole run.

Use `--skip-herdr` to skip herdr and all of this — the prompt/`eza`/Neovim setup doesn't
depend on any of it.

## What it doesn't do

It won't overwrite an existing `~/.config/nvim`, and it won't silently
clobber a `~/.config/starship.toml` that differs from this repo's (it backs
it up first). It has no uninstaller — everything it touches is listed above,
so removal is manual.
