if exists('g:fila_loaded')
  finish
endif
let g:fila_loaded = 1

augroup fila_internal
  autocmd! *
  autocmd BufReadCmd fila://file://* nested call fila#scheme#file#BufReadCmd()
augroup END

command! -nargs=* -complete=dir Fila call fila#command(<q-mods>, <q-args>)

" Deprecated
function! s:FilaDrawer(qargs) abort
  call fila#command('', '-drawer ' . a:qargs)
        \.finally({ -> fila#message#warning(':FilaDrawer is deprecated. Use :Fila -drawer instead.') })
endfunction
command! -nargs=* -complete=dir FilaDrawer call s:FilaDrawer(<q-args>)
