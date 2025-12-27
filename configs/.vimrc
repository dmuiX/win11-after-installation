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
if has('win32') && empty(glob('~/vimfiles/autoload/plug.vim'))
  let s:command = 'powershell -Command "iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim | ni $HOME/vimfiles/autoload/plug.vim -Force"'
  call system(s:command)
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'farmergreg/vim-lastplace'
    Plug 'elzr/vim-json'
call plug#end()
