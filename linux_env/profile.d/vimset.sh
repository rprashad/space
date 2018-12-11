if [[ "$BASH_VERSION" =~ ^4 ]]; then
  PLUGIN_DIR="$HOME/.vim/plugins/start"
  declare -A PLUGINS
  PLUGINS=(

            ["rust-vim"]="https://github.com/rust-lang/rust.vim.git"
            ["vim-fugitive"]="git://github.com/tpope/vim-fugitive.git"
            ["vim-javascript"]="https://github.com/pangloss/vim-javascript.git"
            ["ale"]="https://github.com/w0rp/ale.git"
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

  function load_plugins {
    for plugin in "${!PLUGINS[@]}"; do
      fetch_plugin $plugin "${PLUGINS[$plugin]}"
    done

  }

  load_plugins
fi
