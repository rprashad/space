# Native macOS clipboard is also used by Neovim and tmux.
alias ccopy=clipboard-copy
alias cpaste=clipboard-paste
function clipcopy() { clipboard-copy "$@"; }
function clippaste() { clipboard-paste "$@"; }
