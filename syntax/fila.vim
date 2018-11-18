if exists('b:current_syntax')
  finish
endif

syntax match FilaRoot   /\%1l.*/
syntax match FilaLeaf   /^\s*|  /
syntax match FilaBranch /^\s*|[+-] .*/
syntax match FilaMarked /^* .*/

function! s:define_highlights() abort
  highlight default link FilaRoot   Directory
  highlight default link FilaLeaf   Directory
  highlight default link FilaBranch Directory
  highlight default link FilaMarked Title
endfunction

augroup fila_syntax_changes_internal
  autocmd! *
  autocmd ColorScheme * call s:define_highlights()
augroup END

call s:define_highlights()

let b:current_syntax = 'fila'
