AUTOLOAD_DIR="$HOME/.vim/autoload"
PLUGIN_DIR="$HOME/.vim/bundle"
declare -A PLUGINS
PLUGINS=(
          ["nerdtree"]="https://github.com/scrooloose/nerdtree"
          ["vim-rails"]="git://github.com/tpope/vim-rails.git"
          ["vim-bundler"]="git://github.com/tpope/vim-bundler.git"
          ["vim-ruby"]="git://github.com/vim-ruby/vim-ruby.git"
          ["vim-fugitive"]="git://github.com/tpope/vim-fugitive.git"
          ["vim-javascript"]="https://github.com/pangloss/vim-javascript.git"
          ["vim-go"]="https://github.com/fatih/vim-go.git"
          ["jedi-vim"]="https://github.com/davidhalter/jedi-vim.git"
)

function fetch_plugin {
  plugin_name=$1
  plugin_gitrepo=$2
  plugin_path="${PLUGIN_DIR}/${plugin_name}"

  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p $plugin_path
    echo "Adding VIM Plugin: ${plugin_name}"
    cd $PLUGIN_DIR
    git clone $plugin_gitrepo
    echo "#################################"
  fi

}

function load_pathogen {
  if [[ ! -d "$AUTOLOAD_DIR" ]]; then
    mkdir -p $AUTOLOAD_DIR
    echo "Adding Pathogen"
    curl -LSso $AUTOLOAD_DIR/pathogen.vim https://tpo.pe/pathogen.vim
  fi
}

function load_plugins {
  for plugin in "${!PLUGINS[@]}"; do
    fetch_plugin $plugin "${PLUGINS[$plugin]}"
  done

}

load_pathogen
load_plugins
