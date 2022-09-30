scriptencoding=utf-8

"compile with CTRL+T
nmap <C-T> :!pdflatex % <CR>

"bibtex with CTRL+B
nmap <C-B> :!bibtex %:r <CR>

"open pdf with CTRL+U
nmap <C-P> :!xdg-open %:r.pdf &>/dev/null & disown <CR>

"word wrap nicely
set breakindent
set wrap
set linebreak
set cc=

let g:syntastic_tex_checkers=[]
