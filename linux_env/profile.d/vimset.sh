if [[ ! -d "$HOME/.vim/autoload" ]]; then
  echo "Adding Pathogen"
  mkdir -p ~/.vim/autoload ~/.vim/bundle && \
  curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
fi

if [[ ! -d "$HOME/.vim/bundle/nerdtree" ]]; then
  echo "Adding NERDTree"
  cd $HOME/.vim/bundle
  git clone https://github.com/scrooloose/nerdtree.git
fi
