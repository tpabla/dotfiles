set nocompatible               " be iMproved
filetype off                   " required!

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
" required!
Bundle 'gmarik/vundle'

" original repos on github
Bundle 'scrooloose/nerdtree'
Bundle 'kien/ctrlp.vim'


filetype plugin indent on     " required!


set autoindent
set backspace=4
set clipboard=unnamed
set noswapfile
set encoding=utf-8
set expandtab
set ignorecase
set incsearch
set number
set shiftwidth=4
set smartcase
set softtabstop=4
set tabstop=8
set wildmenu
set wildmode=longest,list,full

set mouse=a
if exists('$TMUX')  " Support resizing in tmux
  set ttymouse=xterm2
endif

" keyboard shortcuts
let mapleader = ','
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
nmap <leader>b :CtrlPBuffer<CR>
nmap <leader>d :NERDTreeToggle<CR>
nmap <leader>f :NERDTreeFind<CR>
nmap <leader>t :CtrlP<CR>
nmap <leader>T :CtrlPClearCache<CR>:CtrlP<CR>

let g:ctrlp_match_window = 'order:ttb,max:20'
let g:NERDSpaceDelims=1
let g:gitgutter_enabled = 0

autocmd VimResized * :wincmd =
