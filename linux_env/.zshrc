# Preserve login environment for non-login xterms too.
. "$HOME/.config/zsh/environment.sh"
typeset -U path PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git sudo colored-man-pages)
zstyle ':omz:update' mode reminder
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    autoload -Uz compinit; compinit
fi
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init - zsh)"
    (( $+commands[pyenv-virtualenv-init] )) && eval "$(pyenv virtualenv-init - zsh)"
fi
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
if command -v ruby >/dev/null 2>&1; then
    path=("$(ruby -r rubygems -e 'puts Gem.user_dir')/bin" $path)
fi
[[ -r "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"
if [[ -r "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    source "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
    source "$HOME/.config/zsh/p10k.zsh"
else
    PROMPT='%F{blue}%~%f %# '
fi
if [[ $OSTYPE == darwin* ]]; then
    alias ll='ls -lahG'
else
    alias ll='ls -lah --color=auto'
fi
alias vim=nvim
# Built-in paste widget inserts text literally, without per-character plugins.
zle -A .bracketed-paste bracketed-paste
bindkey -M emacs '^[[200~' bracketed-paste
bindkey -M viins '^[[200~' bracketed-paste
# Standout/reverse video makes pasted text dark in xterm's navy palette.
# Keep other ZLE highlights and show pasted input in bright white.
typeset -ga zle_highlight
zle_highlight=("${(@)zle_highlight:#paste:*}" 'paste:fg=15')
[[ -r "$HOME/.config/space/platform.zsh" ]] && source "$HOME/.config/space/platform.zsh"

# macOS Screen Sharing shortcuts (see ~/.local/bin/mac-screen)
for _h in bain kindest endeavor; do
  alias vnc-$_h="nohup mac-screen $_h >/dev/null 2>&1 &!"
done
unset _h
