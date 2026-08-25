# launchpad

My terminal setup, in one script. macOS only.

- [starship](https://starship.rs) prompt with per-project icons (Python 🐍, PHP 🐘,
  Drupal 💧, Java ☕, Ruby 💎, R 📊, Bash 🐚, Node ⬢, Rust 🦀, Go 🐹) and a custom
  color palette borrowed from [Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots)
- [eza](https://github.com/eza-community/eza) for icon-based `ls`/`ll`/`la`/`lt`
- [Neovim](https://neovim.io) + [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim),
  the official minimal starter config
- A Nerd Font ([Hack Nerd Font Mono](https://www.nerdfonts.com)) wired into Terminal.app
- A curated set of [herdr](https://herdr.dev) plugins — see below

## Install

```sh
git clone https://github.com/<you>/launchpad.git
cd launchpad
./install.sh
```

Flags: `--skip-herdr`, `--skip-nvim`, `--skip-font`. Safe to re-run — every step
checks for existing state before touching it, and it backs up your existing
`~/.config/starship.toml` if one differs from the one in this repo.

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

Use `--skip-herdr` to get the prompt/`eza`/Neovim setup without touching any
of this.

## What it doesn't do

It won't overwrite an existing `~/.config/nvim`, and it won't silently
clobber a `~/.config/starship.toml` that differs from this repo's (it backs
it up first). It has no uninstaller — everything it touches is listed above,
so removal is manual.
