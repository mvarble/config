scriptencoding=utf-8

"compile with \t
nmap \t :!pdflatex % <CR>

"bibtex with \b
nmap \b :!bibtex %:r <CR>

"open pdf with \p
nmap \p :!xdg-open %:r.pdf &>/dev/null & disown <CR>

"word wrap nicely
set breakindent
set wrap
set linebreak
set cc=

let g:syntastic_tex_checkers=[]
