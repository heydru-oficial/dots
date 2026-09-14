#!/usr/bin/env bash
# dots: eduardo's terminal setup (starship + eza + neovim + herdr plugins).
# Idempotent — safe to re-run. Read this before you run it; it edits your
# shell rc file and installs software.
#
# Supports macOS (via Homebrew) and Linux/Ubuntu (via rustup + cargo + official
# installers, no Homebrew required). On Linux, the ONLY step that can need sudo
# is a one-time bootstrap of curl/git/a C compiler if your system doesn't
# already have them — you'll be shown the exact command and asked to confirm
# before anything runs as root. Nothing else in this script uses sudo.
set -euo pipefail

SKIP_HERDR=0
SKIP_NVIM=0
SKIP_FONT=0
SKIP_GHOSTTY=0
SKIP_AGENTS=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --skip-herdr) SKIP_HERDR=1 ;;
    --skip-nvim) SKIP_NVIM=1 ;;
    --skip-font) SKIP_FONT=1 ;;
    --skip-ghostty) SKIP_GHOSTTY=1 ;;
    --skip-agents) SKIP_AGENTS=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help)
      echo "Usage: $0 [--skip-herdr] [--skip-nvim] [--skip-font] [--skip-ghostty] [--skip-agents] [--yes]"
      echo "  --skip-herdr   don't touch herdr plugins (unvetted community registry)"
      echo "  --skip-nvim    don't install Neovim / kickstart.nvim"
      echo "  --skip-font    don't install Hack Nerd Font Mono (macOS only)"
      echo "  --skip-ghostty don't install Ghostty (macOS only)"
      echo "  --skip-agents  don't install Claude Code / Codex CLIs"
      echo "  --yes          don't ask before running the one sudo step on Linux"
      exit 0
      ;;
  esac
done

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
MARK_BEGIN="# >>> dots >>>"
MARK_END="# <<< dots <<<"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux) OS=linux ;;
  *) echo "dots only supports macOS and Linux." >&2; exit 1 ;;
esac

# So a tool installed earlier in this same run (rustup, herdr, ...) is
# immediately usable later in the same run, without waiting for a new shell.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

append_once() {
  local file="$1" snippet_file="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -qF "$MARK_BEGIN" "$file" 2>/dev/null; then
    log "$file already has the dots block, leaving it alone"
    return
  fi
  {
    echo ""
    echo "$MARK_BEGIN"
    cat "$snippet_file"
    echo "$MARK_END"
  } >> "$file"
  log "appended dots block to $file"
}

if [[ "$OS" == "macos" ]]; then
  if ! command -v brew >/dev/null; then
    echo "Homebrew is required on macOS: https://brew.sh" >&2
    exit 1
  fi
else
  # Linux: bootstrap curl/git/a C toolchain if missing. This is the ONLY
  # place this script can touch sudo, and it asks first (unless --yes).
  missing=()
  command -v curl >/dev/null || missing+=(curl)
  command -v git >/dev/null || missing+=(git)
  { command -v cc >/dev/null || command -v gcc >/dev/null; } || missing+=(build-essential)
  [[ -f /etc/ssl/certs/ca-certificates.crt ]] || missing+=(ca-certificates)
  if [[ ${#missing[@]} -gt 0 ]] && command -v apt-get >/dev/null; then
    warn "Missing: ${missing[*]}. Installing these needs: sudo apt-get install -y ${missing[*]}"
    if [[ "$ASSUME_YES" -eq 0 ]]; then
      read -r -p "Run that now? [y/N] " reply
      [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborting — install ${missing[*]} yourself and re-run." >&2; exit 1; }
    fi
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${missing[@]}"
  elif [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing: ${missing[*]}, and no apt-get found. Install these yourself and re-run." >&2
    exit 1
  fi
fi

log "Ensuring a Rust toolchain (rustup, no sudo)"
if ! command -v cargo >/dev/null; then
  if [[ "$OS" == "macos" ]]; then
    brew install rust >/dev/null
  else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y -q
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi
else
  log "cargo already present, leaving it alone"
fi

if [[ "$OS" == "macos" ]]; then
  log "Installing starship, eza, ripgrep, fd via Homebrew"
  brew install starship eza ripgrep fd >/dev/null

  if [[ "$SKIP_GHOSTTY" -eq 0 ]]; then
    if [[ -d /Applications/Ghostty.app ]] || command -v ghostty >/dev/null; then
      log "Ghostty already installed, leaving it alone"
    else
      log "Installing Ghostty as the local terminal layer"
      brew install --cask ghostty >/dev/null
    fi
  fi
else
  log "Installing starship, eza, ripgrep, fd via cargo (this compiles from source, a few minutes)"
  cargo install starship eza ripgrep fd-find --locked >/dev/null 2>&1 \
    || cargo install starship eza ripgrep fd-find
fi

if [[ "$OS" == "macos" ]]; then
  log "Installing a Nerd Font (Hack Nerd Font Mono) if missing"
  brew list --cask font-hack-nerd-font >/dev/null 2>&1 || brew install --cask font-hack-nerd-font
else
  log "Skipping Nerd Font install — on a remote/Linux box the font needs to live on the machine running your terminal (the one you SSH FROM), not here. Install one from nerdfonts.com locally and select it in your terminal profile."
fi

if [[ "$SKIP_AGENTS" -eq 0 ]]; then
  if command -v claude >/dev/null; then
    log "claude already on PATH ($(command -v claude)), leaving it alone"
  else
    log "Installing Claude Code (official installer, no sudo)"
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  if command -v codex >/dev/null; then
    log "codex already on PATH ($(command -v codex)), leaving it alone"
  else
    log "Installing Codex (official installer, no sudo)"
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
  fi
fi

log "Writing ~/.config/starship.toml"
mkdir -p ~/.config
if [[ -f ~/.config/starship.toml ]] && ! diff -q ~/.config/starship.toml "$REPO_DIR/starship.toml" >/dev/null 2>&1; then
  cp ~/.config/starship.toml ~/.config/starship.toml.bak
  log "backed up your existing starship.toml to starship.toml.bak"
fi
cp "$REPO_DIR/starship.toml" ~/.config/starship.toml

if [[ "$OS" == "macos" ]] || command -v zsh >/dev/null; then
  append_once ~/.zshrc "$REPO_DIR/zshrc-snippet.sh"
fi
if [[ "$OS" == "linux" ]]; then
  append_once ~/.bashrc "$REPO_DIR/bashrc-snippet.sh"
fi

if [[ "$SKIP_NVIM" -eq 0 ]]; then
  log "Installing Neovim + kickstart.nvim"
  if [[ "$OS" == "macos" ]]; then
    brew install neovim tree-sitter-cli >/dev/null
  else
    arch="$(uname -m)"
    if ! command -v nvim >/dev/null; then
      case "$arch" in
        x86_64) nvim_asset="nvim-linux-x86_64" ;;
        aarch64|arm64) nvim_asset="nvim-linux-arm64" ;;
        *) nvim_asset="" ;;
      esac
      if [[ -n "$nvim_asset" ]]; then
        mkdir -p ~/.local/share
        curl -fsSL -o /tmp/nvim.tar.gz \
          "https://github.com/neovim/neovim/releases/latest/download/${nvim_asset}.tar.gz"
        tar -xzf /tmp/nvim.tar.gz -C ~/.local/share
        rm -rf ~/.local/share/nvim-linux
        mv ~/.local/share/"$nvim_asset" ~/.local/share/nvim-linux
        mkdir -p ~/.local/bin
        ln -sf ~/.local/share/nvim-linux/bin/nvim ~/.local/bin/nvim
        rm -f /tmp/nvim.tar.gz
      else
        warn "no prebuilt Neovim for architecture $arch — install it yourself"
      fi
    else
      log "nvim already on PATH, leaving it alone"
    fi
    if ! command -v tree-sitter >/dev/null; then
      case "$arch" in
        x86_64) ts_asset="tree-sitter-linux-x64" ;;
        aarch64|arm64) ts_asset="tree-sitter-linux-arm64" ;;
        *) ts_asset="" ;;
      esac
      if [[ -n "$ts_asset" ]]; then
        mkdir -p ~/.local/bin
        curl -fsSL -o /tmp/tree-sitter.gz \
          "https://github.com/tree-sitter/tree-sitter/releases/latest/download/${ts_asset}.gz"
        gunzip -c /tmp/tree-sitter.gz > ~/.local/bin/tree-sitter
        chmod +x ~/.local/bin/tree-sitter
        rm -f /tmp/tree-sitter.gz
      else
        warn "no prebuilt tree-sitter-cli for architecture $arch — install it yourself"
      fi
    fi
  fi
  if [[ ! -d ~/.config/nvim ]]; then
    git clone --depth 1 https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
    PATH="$HOME/.local/bin:$PATH" nvim --headless "+TSUpdate" "+lua vim.wait(15000)" +qa >/dev/null 2>&1 || true
  else
    log "~/.config/nvim already exists, leaving it alone"
  fi
fi

if [[ "$SKIP_HERDR" -eq 0 ]]; then
  if [[ "$OS" == "macos" ]] && ! command -v terminal-browser >/dev/null; then
    log "Installing terminal-browser for browser panes inside herdr"
    curl -fsSL https://terminal-browser.sh/install | bash
  fi
  if ! command -v herdr >/dev/null; then
    log "Installing herdr (official installer, no sudo)"
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
  if ! command -v herdr >/dev/null; then
    warn "herdr install didn't land on PATH — skipping plugins. Open a new shell and re-run to pick it up."
  else
    log "Linking herdr plugins from $REPO_DIR/herdr/plugins.txt"
    log "These come from herdr's UNVETTED community registry — review herdr/plugins.txt before trusting this step"
    PLUGIN_ROOT=~/.local/share/herdr-plugins
    mkdir -p "$PLUGIN_ROOT"
    while IFS= read -r line; do
      [[ -z "$line" || "$line" == \#* ]] && continue
      repo="${line%%:*}"
      subpath=""
      [[ "$line" == *:* ]] && subpath="${line#*:}"
      if [[ "$OS" != "macos" && "$repo" == "zenbu-labs/terminal-browser" ]]; then
        log "skipping terminal-browser plugin on a headless Linux host"
        continue
      fi
      name="${repo#*/}"
      dest="$PLUGIN_ROOT/$name"
      patched=0
      if [[ ! -d "$dest" ]]; then
        git clone --depth 1 "https://github.com/$repo" "$dest" >/dev/null 2>&1 \
          || { warn "clone failed for $repo, skipping"; continue; }
        patch_file="$REPO_DIR/herdr/patches/$name.patch"
        if [[ -f "$patch_file" ]]; then
          if (cd "$dest" && git apply "$patch_file") 2>/dev/null; then
            patched=1
            log "applied local patch to $repo"
          else
            warn "patch for $repo didn't apply cleanly (upstream moved on?) — using it unpatched"
          fi
        fi
      fi
      manifest_dir="$dest"
      [[ -n "$subpath" ]] && manifest_dir="$dest/$subpath"
      herdr plugin link "$manifest_dir" >/dev/null 2>&1 \
        || { warn "link failed for $repo, skipping"; continue; }
      if [[ "$patched" -eq 1 ]]; then
        # A patched checkout must be BUILT, not fetched — the plugin's own
        # fetch-or-build.sh would happily download the unpatched official
        # prebuilt binary and silently undo the patch.
        (cd "$manifest_dir" && cargo build --release) >/dev/null 2>&1 \
          || warn "building the patched $repo failed"
      else
        for build_cmd in "sh scripts/fetch-or-build.sh" "bash herdr/install.sh" "cargo build --release"; do
          if (cd "$manifest_dir" && eval "$build_cmd") >/dev/null 2>&1; then
            break
          fi
        done
      fi
      log "linked $repo"
    done < "$REPO_DIR/herdr/plugins.txt"

    cargo install ghzinga --locked >/dev/null 2>&1 || warn "couldn't install the gzg CLI for ghzinga"
    append_once ~/.config/herdr/config.toml "$REPO_DIR/herdr/config-snippet.toml"

    if herdr status 2>/dev/null | grep -q "status: running"; then
      # configure --apply injects its own [ui.sidebar.agents] table with a
      # verbose default (topic/cache/5h/weekly rows). We only want a single
      # compact row per agent, and TOML forbids a second [ui.sidebar.agents]
      # table — so rewrite what it just wrote instead of appending our own.
      herdr plugin action invoke herdr-agent-quota.configure >/dev/null 2>&1 \
        && python3 "$REPO_DIR/herdr/compact_agent_rows.py" ~/.config/herdr/config.toml
      herdr server reload-config >/dev/null 2>&1 || true
    else
      warn "herdr isn't running yet, so the agent-quota sidebar rows and this new config can't be applied live."
      warn "Run 'herdr' once to start it, then run:"
      warn "  herdr plugin action invoke herdr-agent-quota.configure && python3 $REPO_DIR/herdr/compact_agent_rows.py ~/.config/herdr/config.toml && herdr server reload-config"
    fi
  fi
fi

if [[ "$OS" == "macos" ]]; then
  log "Done. Open Ghostty and run herdr to see it all together."
else
  log "Done. Open a new terminal window to see it all together."
fi
