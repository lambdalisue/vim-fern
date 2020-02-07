if exists('g:fern#loaded')
  finish
endif
let g:fern#loaded = 1

command! -bar -nargs=*
      \ -complete=customlist,fern#internal#command#fern#complete
      \ Fern
      \ call fern#internal#command#fern#command(<q-mods>, [<f-args>])

command! -bar -nargs=*
      \ -complete=customlist,fern#internal#command#focus#complete
      \ FernFocus
      \ call fern#internal#command#focus#command(<q-mods>, [<f-args>])

function! s:BufReadCmd() abort
  call fern#internal#viewer#init()
        \.catch({ e -> fern#logger#error(e) })
endfunction

augroup fern_internal
  autocmd! *
  autocmd BufReadCmd fern://* ++nested call s:BufReadCmd()
augroup END
