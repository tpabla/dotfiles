" Specify a directory for plugins (for Neovim: ~/.local/share/nvim/plugged)
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" Any valid git URL is allowed
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

Plug 'scrooloose/nerdtree'
Plug 'kien/ctrlp.vim'
Plug 'marijnh/tern_for_vim'
Plug 'groenewege/vim-less'
Plug 'rust-lang/rust.vim'
Plug 'klen/python-mode'
Plug 'tpope/vim-commentary'
Plug 'ntpeters/vim-better-whitespace'
Plug 'Lokaltog/vim-powerline'
Plug 'jmcantrell/vim-virtualenv'
Plug 'tpope/vim-surround'
Plug 'fatih/vim-go'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'haya14busa/incsearch.vim'

call plug#end()
color dracula

let g:tern_show_argument_hints = 'on_move'

" Required:
filetype plugin indent on


set autoindent
set backspace=2
set clipboard=unnamed " copy to the system clipboard
set noswapfile
set encoding=utf-8
set expandtab
set ignorecase
set incsearch
set number
set shiftwidth=2
set smartcase
set softtabstop=2
set wildmenu
set wildmode=longest,list,full
set omnifunc=syntaxcomplete#Complete
syntax on
set wildignore+=*.pyc
set undofile
set undodir=~/.vimundo
set confirm
filetype plugin on

set mouse=a
if has("mouse_sgr")
    set ttymouse=sgr
else
    set ttymouse=xterm2
end

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
nmap <leader><Space> :StripWhitespace<CR>

let g:ctrlp_match_window = 'order:ttb,max:20'
let g:NERDSpaceDelims=1
let g:gitgutter_enabled = 0
let g:ctrlp_max_files=0
let g:ctrlp_max_depth=40
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git|client/lib|*.pyc'
let g:pymode_rope_lookup_project = 0
let g:pymode_rope = 0

" Go Stuff
let g:go_disable_autoinstall = 0

" Highlight
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

let g:airline_powerline_fonts = 1

" incsearch settings
" :h g:incsearch#auto_nohlsearch
set hlsearch
let g:incsearch#auto_nohlsearch = 1
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)"

inoremap ;; <Esc>
