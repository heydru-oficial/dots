#!/usr/bin/env bash
# dots: eduardo's terminal setup (starship + eza + neovim + herdr plugins).
# Idempotent — safe to re-run. Read this before you run it; it edits your
# shell rc file and installs software via Homebrew/cargo.
set -euo pipefail

SKIP_HERDR=0
SKIP_NVIM=0
SKIP_FONT=0
for arg in "$@"; do
  case "$arg" in
    --skip-herdr) SKIP_HERDR=1 ;;
    --skip-nvim) SKIP_NVIM=1 ;;
    --skip-font) SKIP_FONT=1 ;;
    -h|--help)
      echo "Usage: $0 [--skip-herdr] [--skip-nvim] [--skip-font]"
      echo "  --skip-herdr  don't touch herdr plugins (unvetted community registry)"
      echo "  --skip-nvim   don't install Neovim / kickstart.nvim"
      echo "  --skip-font   don't touch Terminal.app's font setting"
      exit 0
      ;;
  esac
done

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
MARK_BEGIN="# >>> dots >>>"
MARK_END="# <<< dots <<<"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "dots currently only supports macOS." >&2
  exit 1
fi
if ! command -v brew >/dev/null; then
  echo "Homebrew is required: https://brew.sh" >&2
  exit 1
fi

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

log "Installing Homebrew packages (eza, ripgrep, fd, rust)"
brew install eza ripgrep fd rust >/dev/null

log "Installing a Nerd Font (Hack Nerd Font Mono) if missing"
brew list --cask font-hack-nerd-font >/dev/null 2>&1 || brew install --cask font-hack-nerd-font

log "Writing ~/.config/starship.toml"
mkdir -p ~/.config
if [[ -f ~/.config/starship.toml ]] && ! diff -q ~/.config/starship.toml "$REPO_DIR/starship.toml" >/dev/null 2>&1; then
  cp ~/.config/starship.toml ~/.config/starship.toml.bak
  log "backed up your existing starship.toml to starship.toml.bak"
fi
cp "$REPO_DIR/starship.toml" ~/.config/starship.toml

append_once ~/.zshrc "$REPO_DIR/zshrc-snippet.sh"

if [[ "$SKIP_FONT" -eq 0 && "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]; then
  log "Pointing Terminal.app's Basic profile at HackNFM-Regular"
  osascript -e 'tell application "Terminal" to set font name of settings set "Basic" to "HackNFM-Regular"' >/dev/null 2>&1 \
    || warn "couldn't set Terminal.app font automatically; set it manually in Terminal > Settings > Profiles > Text"
fi

if [[ "$SKIP_NVIM" -eq 0 ]]; then
  log "Installing Neovim + kickstart.nvim"
  brew install neovim tree-sitter-cli >/dev/null
  if [[ ! -d ~/.config/nvim ]]; then
    git clone --depth 1 https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
    nvim --headless "+TSUpdate" "+lua vim.wait(15000)" +qa >/dev/null 2>&1 || true
  else
    log "~/.config/nvim already exists, leaving it alone"
  fi
fi

if [[ "$SKIP_HERDR" -eq 0 ]]; then
  if ! command -v herdr >/dev/null; then
    warn "herdr isn't installed (https://herdr.dev) — skipping plugins"
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
      name="${repo#*/}"
      dest="$PLUGIN_ROOT/$name"
      if [[ ! -d "$dest" ]]; then
        git clone --depth 1 "https://github.com/$repo" "$dest" >/dev/null 2>&1 \
          || { warn "clone failed for $repo, skipping"; continue; }
      fi
      manifest_dir="$dest"
      [[ -n "$subpath" ]] && manifest_dir="$dest/$subpath"
      herdr plugin link "$manifest_dir" >/dev/null 2>&1 \
        || { warn "link failed for $repo, skipping"; continue; }
      for build_cmd in "sh scripts/fetch-or-build.sh" "bash herdr/install.sh" "cargo build --release"; do
        if (cd "$manifest_dir" && eval "$build_cmd") >/dev/null 2>&1; then
          break
        fi
      done
      log "linked $repo"
    done < "$REPO_DIR/herdr/plugins.txt"

    if command -v cargo >/dev/null; then
      cargo install ghzinga --locked >/dev/null 2>&1 || warn "couldn't install the gzg CLI for ghzinga"
    fi

    append_once ~/.config/herdr/config.toml "$REPO_DIR/herdr/config-snippet.toml"
    herdr server reload-config >/dev/null 2>&1 || true
  fi
fi

log "Done. Open a new terminal window to see it all together."
