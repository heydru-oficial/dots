# dots

My terminal setup, in one script. **macOS and Linux/Ubuntu** (including a bare VPS).

- [starship](https://starship.rs) prompt with per-project icons (Python 🐍, PHP 🐘,
  Drupal 💧, Java ☕, Ruby 💎, R 📊, Bash 🐚, Node ⬢, Rust 🦀, Go 🐹) and a custom
  color palette borrowed from [Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots)
- [eza](https://github.com/eza-community/eza) for icon-based `ls`/`ll`/`la`/`lt`
- [Neovim](https://neovim.io) + [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim),
  the official minimal starter config
- A Nerd Font ([Hack Nerd Font Mono](https://www.nerdfonts.com)) wired into Terminal.app — **macOS only**, see below
- [Claude Code](https://claude.com/claude-code) and [Codex](https://github.com/openai/codex) CLIs
- A curated set of [herdr](https://herdr.dev) plugins — see below

## Install

```sh
git clone https://github.com/heydru-oficial/dots.git
cd dots
./install.sh
```

Flags: `--skip-herdr`, `--skip-nvim`, `--skip-font`, `--skip-agents`, `--yes`. Safe to
re-run — every step checks for existing state before touching it, and it backs up your
existing `~/.config/starship.toml` if one differs from the one in this repo.

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

**Not installed on Linux:** the Nerd Font and the Terminal.app font-binding step. A
remote box has no terminal of its own — the font needs to live on the machine you're
*viewing* the terminal from (your laptop's SSH client), not the server. Install a Nerd
Font locally from [nerdfonts.com](https://www.nerdfonts.com) and select it in whatever
terminal app you SSH with.

## About the herdr plugins

[herdr](https://herdr.dev) is a terminal/workspace manager built for running
several AI coding agents (Claude Code, Codex, Copilot, etc.) side by side.
`herdr/plugins.txt` lists nine community plugins this setup links in — a git
sidebar, an nvim sidebar, an agent quota monitor, tab auto-naming, and a few
others (one, `herdr-flock`, is pure novelty — pixel-art sheep for your agents).

**herdr's plugin registry is unvetted.** Anyone can publish a plugin by
tagging a GitHub repo `herdr-plugin`; nothing in the list is reviewed by
herdr itself. Before running this against your own machine, open
`herdr/plugins.txt` and skim each linked repo. `install.sh` links plugins
locally (`herdr plugin link`) rather than through herdr's own remote
installer, so you always have the exact cloned source on disk at
`~/.local/share/herdr-plugins/` to read.

`install.sh` doesn't install herdr itself — get it from
[herdr.dev](https://herdr.dev) first (`curl -fsSL https://herdr.dev/install.sh | sh`,
works on macOS and Linux). Without herdr on `PATH`, this whole section is skipped.

Use `--skip-herdr` to get the prompt/`eza`/Neovim setup without touching any of this.

## What it doesn't do

It won't overwrite an existing `~/.config/nvim`, and it won't silently
clobber a `~/.config/starship.toml` that differs from this repo's (it backs
it up first). It has no uninstaller — everything it touches is listed above,
so removal is manual.
