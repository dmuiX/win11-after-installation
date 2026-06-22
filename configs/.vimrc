" Standard vim settings
set number
nnoremap <F3> :set number!<CR>
set smartindent
set autoindent
set shiftwidth=2
set tabstop=2
set pastetoggle=<F2>
set expandtab
set backspace=indent,eol,start
set clipboard=unnamedplus
set termguicolors

syntax on
highlight Normal ctermbg=None
highlight LineNr ctermfg=DarkGrey

" vim-plug Setup
let s:plug_path = has('win32') ? '~/vimfiles/autoload/plug.vim' : '~/.vim/autoload/plug.vim'
if empty(glob(s:plug_path))
  silent execute '!curl -fLo ' . s:plug_path . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'farmergreg/vim-lastplace'
    Plug 'elzr/vim-json'
call plug#end()
