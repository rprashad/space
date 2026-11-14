# Shared environment; never copy transient session variables or secrets here.
export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
export EDITOR=nvim
export VISUAL=nvim
[ ! -r "$HOME/.config/space/platform.sh" ] || . "$HOME/.config/space/platform.sh"
export PAGER=less
export LESS='-R'
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
case ":$PATH:" in *":$HOME/bin:"*) ;; *) [ ! -d "$HOME/bin" ] || export PATH="$HOME/bin:$PATH" ;; esac
case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) [ ! -d "$PYENV_ROOT/bin" ] || export PATH="$PYENV_ROOT/bin:$PATH" ;; esac
# POSIX-compatible files run in lexical order, once per shell.
if [ "${_PROFILE_D_LOADED:-0}" != 1 ]; then
    _PROFILE_D_LOADED=1
    _load_profile_fragments() {
        # Zsh otherwise errors when the directory has no matching files.
        if [ -n "${ZSH_VERSION:-}" ]; then setopt localoptions nonomatch; fi
        for profile_fragment in "$HOME"/.profile.d/*.sh; do
            [ ! -r "$profile_fragment" ] || . "$profile_fragment"
        done
        unset profile_fragment
    }
    _load_profile_fragments
    unset -f _load_profile_fragments
fi
