export PATH="$HOME/.cargo/bin:$PATH"

alias ls='eza --icons=always --group-directories-first'
alias ll='eza --icons=always --group-directories-first -l'
alias la='eza --icons=always --group-directories-first -la'
alias lt='eza --icons=always --group-directories-first --tree'

eval "$(starship init zsh)"

# herdr-automatic-rename shell hook (linked from local checkout, not a remote install)
[ -r "$HOME/.local/share/herdr-plugins/herdr-automatic-rename/shell/hook.zsh" ] && \
  source "$HOME/.local/share/herdr-plugins/herdr-automatic-rename/shell/hook.zsh"
