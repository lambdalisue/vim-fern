if exists('g:fern#loaded')
  finish
endif
let g:fern#loaded = 1

command! -bar -nargs=*
      \ -complete=customlist,fern#command#fern#complete
      \ Fern
      \ call fern#command#fern#command(<q-mods>, <q-args>)

command! -bar -nargs=?
      \ -complete=customlist,fern#command#focus#complete
      \ FernFocus
      \ call fern#command#focus#command(<q-mods>, <q-args>)

function! s:BufReadCmd() abort
  call fern#internal#viewer#init()
        \.catch({ e -> fern#logger#error(e) })
endfunction

augroup fern_internal
  autocmd! *
  autocmd BufReadCmd fern://* ++nested call s:BufReadCmd()
augroup END
