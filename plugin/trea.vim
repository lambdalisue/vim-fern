if exists('g:trea_loaded')
  finish
endif
let g:trea_loaded = 1

command! -nargs=*
      \ -complete=customlist,trea#command#trea#complete
      \ Trea
      \ call trea#command#trea#command(<q-mods>, <q-args>)

command! -nargs=*
      \ -complete=customlist,trea#command#focus#complete
      \ TreaFocus
      \ call trea#command#focus#command(<q-mods>, <q-args>)

augroup trea_internal
  autocmd! *
  autocmd BufReadCmd trea:*/* nested call trea#internal#viewer#init()
augroup END

let g:trea_debug = get(g:, 'trea_debug', 0)
