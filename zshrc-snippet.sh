export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Quick project session shortcuts on the Contabo VPS. This override of the
# `herdr` command is INTENTIONAL, not drift — leave it in place. It maps a
# project name (or its domain / stylized brand form) to a persistent herdr
# session on the box, always as the `eduardo` user (never root — if root is
# ever needed, `sudo` inside the session instead of a separate root
# connection; smaller blast radius if this account is ever compromised):
#   herdr heydru            -> session "heydru"       (also: heydru!, heydru.com)
#   herdr eduardotelaya     -> session "eduardotelaya" (also: eduardotelaya.com)
#   herdr derecho           -> session "derecho"       (also: derecho.eduardotelaya.com)
# Anything not matching one of these names passes straight through to the
# real herdr CLI untouched.
herdr() {
  local session=""
  case "$1" in
    heydru|heydru!|heydru.com) session="heydru" ;;
    eduardotelaya|eduardotelaya.com) session="eduardotelaya" ;;
    derecho|derecho.eduardotelaya.com) session="derecho" ;;
  esac
  if [[ -n "$session" ]]; then
    command herdr --remote ssh-contabo-eduardo --session "$session" "${@:2}"
  else
    command herdr "$@"
  fi
}

alias ls='eza --icons=always --group-directories-first'
alias ll='eza --icons=always --group-directories-first -l'
alias la='eza --icons=always --group-directories-first -la'
alias lt='eza --icons=always --group-directories-first --tree'

eval "$(starship init zsh)"

# herdr-automatic-rename shell hook (linked from local checkout, not a remote install)
[ -r "$HOME/.local/share/herdr-plugins/herdr-automatic-rename/shell/hook.zsh" ] && \
  source "$HOME/.local/share/herdr-plugins/herdr-automatic-rename/shell/hook.zsh"
