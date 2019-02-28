if exists('g:fila_file_loaded')
  finish
endif
let g:fila_file_loaded = 1

function! s:BufReadCmd() abort
  let path = matchstr(expand('<afile>'), 'fila://\%(file://\)\?\zs.*')
  let root = fila#scheme#file#node(path)
  let root.parent = fila#scheme#file#node(fnamemodify(path, ':p:h:h'))
  call fila#viewer#BufReadCmd({ -> root })
endfunction

augroup fila_file_internal
  autocmd! *
  autocmd BufReadCmd  fila://file://* nested call s:BufReadCmd()
  autocmd BufReadPre  fila://file://* :
  autocmd BufReadPost fila://file://* :
augroup END
