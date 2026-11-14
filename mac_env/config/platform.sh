# Homebrew supports Apple Silicon and Intel installations.
if [ -x /opt/homebrew/bin/brew ]; then
    case ":$PATH:" in *:/opt/homebrew/bin:*) ;; *) export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" ;; esac
elif [ -x /usr/local/bin/brew ]; then
    case ":$PATH:" in *:/usr/local/bin:*) ;; *) export PATH="/usr/local/bin:/usr/local/sbin:$PATH" ;; esac
fi

export TERMINAL="$HOME/.local/bin/space-terminal"

# Use Homebrew's modern terminfo database without hiding system fallbacks.
for space_brew_prefix in /opt/homebrew /usr/local; do
    if [ -d "$space_brew_prefix/opt/ncurses/share/terminfo" ]; then
        case ":${TERMINFO_DIRS:-}:" in
            *":$space_brew_prefix/opt/ncurses/share/terminfo:"*) ;;
            *) export TERMINFO_DIRS="$space_brew_prefix/opt/ncurses/share/terminfo:${TERMINFO_DIRS:-}" ;;
        esac
        break
    fi
done
unset space_brew_prefix
