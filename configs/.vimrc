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

" vim-plug (installed by win11-post-setup.ps1)
let s:plug_path = has('win32') ? '~/vimfiles/autoload/plug.vim' : '~/.vim/autoload/plug.vim'
if !empty(glob(s:plug_path))
    call plug#begin('~/.vim/plugged')
        Plug 'vim-airline/vim-airline'
        Plug 'vim-airline/vim-airline-themes'
        Plug 'farmergreg/vim-lastplace'
        Plug 'elzr/vim-json'
    call plug#end()
endif
