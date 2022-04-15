" Vundle plugins
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Vundle
Plugin 'VundleVim/Vundle.vim'

" language support
Plugin 'vim-syntastic/syntastic'
Plugin 'pangloss/vim-javascript'
Plugin 'MaxMEllon/vim-jsx-pretty'
Plugin 'leafgarland/typescript-vim'
Plugin 'peitalin/vim-jsx-typescript'
Plugin 'cespare/vim-toml'
Plugin 'rust-lang/rust.vim'

" ui
Plugin 'chriskempson/base16-vim'
Plugin 'JuliaEditorSupport/julia-vim'
Plugin 'preservim/nerdcommenter'
Plugin 'preservim/nerdtree'
Plugin 'vim-airline'
Plugin 'vim-airline/vim-airline-themes'

" ux
Plugin 'joom/latex-unicoder.vim'

call vundle#end()
filetype plugin indent on

" fish correction
set shell=/usr/local/bin/fish

" pathogen
execute pathogen#infect()

" syntax enabling
syntax enable
filetype plugin indent on

" colorscheme
set t_Co=256
let base16colorspace=256 
colorscheme base16-ashes
hi Normal ctermbg=NONE guibg=NONE
let g:airline_theme='base16_ashes'

" mouse scrolling
set mouse=a
nmap <LeftMouse> <nop>
imap <LeftMouse> <nop>
vmap <LeftMouse> <nop>

" syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_quiet_messages = { "!level": "errors" }
let g:syntastic_enable_balloons = 1
let g:syntastic_loc_list_height = 5

" local vimrc
let g:localvimrc_sandbox=0
let g:localvimrc_ask=0

" buffer control
set showcmd
set timeoutlen=1000
set ttimeoutlen=100
set wildmenu

" numbering
set number relativenumber
set numberwidth=4
highlight LineNr ctermfg=gray ctermbg=233
highlight! link SignColumn LineNr

" nonstandard filetypes
au BufNewFile,BufRead *.cls set filetype=tex
au BufNewFile,BufRead *.sty set filetype=tex
au BufNewFile,BufRead *.tex set filetype=tex
au BufNewFile,BufRead *.mdx set filetype=markdown
au BufNewFile,BufRead *.ts set filetype=typescriptreact

" indenting
set tabstop=2
set shiftwidth=2
set softtabstop=2
setlocal autoindent
setlocal cindent
setlocal smartindent
set shiftround
set expandtab
set smarttab

" line @ 80
set colorcolumn=81
highlight ColorColumn ctermbg=233

" no highlight on search
set nohlsearch

" latex-to-unicode
let g:unicoder_cancel_normal = 1
let g:unicoder_cancel_insert = 1
let g:unicoder_cancel_visual = 1
nnoremap <C-l> :call unicoder#start(0)<CR>
inoremap <C-l> <Esc>:call unicoder#start(1)<CR>
vnoremap <C-l> :<C-u>call unicoder#selection()<CR>

" NERDTree
nnoremap <C-f> :NERDTreeToggle<CR>
let NERDTreeMapActivateNode = 'l'

" tabs
nnoremap <C-d> :q<CR>
nnoremap <S-N> :tabnew<CR>
nnoremap <S-H> :tabprev<CR>
nnoremap <S-L> :tabnext<CR>
