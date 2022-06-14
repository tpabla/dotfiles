" Specify a directory for plugins (for Neovim: ~/.local/share/nvim/plugged)
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

Plug 'tpope/vim-commentary'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tpope/vim-surround'
Plug 'haya14busa/incsearch.vim'
"Plug 'tpope/vim-rails'
"Plug 'tell-k/vim-autopep8'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'christoomey/vim-tmux-navigator'

"Built in common lspconfigs
Plug 'neovim/nvim-lspconfig'

" Telescope for fzf
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

Plug 'tpabla/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

" Vim Table Mode
Plug 'dhruvasagar/vim-table-mode'

call plug#end()

" Required:
filetype plugin indent on

set autoindent
set backspace=2
set clipboard=unnamed " copy to the system clipboard
set noswapfile
set encoding=utf-8
set expandtab
set ignorecase
set number
set shiftwidth=2
set smartcase
set softtabstop=2
set wildmenu
set wildmode=longest,list,full
" set omnifunc=syntaxcomplete#Complete
syntax on
set wildignore+=*.pyc
set undofile
set undodir=~/.vimundo
set confirm
filetype plugin on

" incsearch
set hlsearch
let g:incsearch#auto_nohlsearch = 1
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

" airline
let g:airline#extensions#tabline#enabled = 1

" keyboard shortcuts
let mapleader = ','
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
nmap <leader>b :CtrlPBuffer<CR>
"nmap <leader>d :NERDTreeToggle<CR>
nmap <leader>t :CtrlP<CR>
nmap <leader>T :CtrlPClearCache<CR>:CtrlP<CR>
nmap <leader><Space> :StripWhitespace<CR>
nmap <leader>p :MarkdownPreview<CR>
nmap <leader>s :setlocal spell spelllang=en_us<CR>:.

let hostname = substitute(system('hostname'), '\n', '', '')
if hostname == "ep-vm-aws.taran.devvm.easypo.net"
  let g:python_host_prog = expand('/opt/python3.8/bin/python3')
  let g:python3_host_prog = expand('/opt/python3.8/bin/python3')
  let g:python2_host_prog = expand('/opt/python2.7/bin/python2.7')
end

let g:ctrlp_match_window = 'order:ttb,max:20'
let g:NERDSpaceDelims=1
let g:gitgutter_enabled = 0
let g:ctrlp_max_files=0
let g:ctrlp_max_depth=40
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git|client/lib|*.pyc'

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

" Esc
inoremap ;; <Esc>

" Transparent background
hi Normal guibg=NONE ctermbg=NONE

autocmd FileType text,markdown,tex setlocal textwidth=80

" Telescope
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
