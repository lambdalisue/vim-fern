if exists('g:fila_loaded')
  finish
endif
let g:fila_loaded = 1

augroup fila_internal
  autocmd! *
  autocmd BufReadCmd fila://file://* nested call fila#scheme#file#BufReadCmd()
augroup END

command! -nargs=? -complete=dir Fila call fila#open(<q-args>)
command! -nargs=? -complete=dir FilaDrawer call fila#drawer(<q-args>)
