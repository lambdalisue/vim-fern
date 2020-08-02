if exists('g:loaded_fern') || ( !has('nvim') && v:version < 801 )
  finish
endif
let g:loaded_fern = 1
let g:fern_loaded = 1 " Obsolete: For backward compatibility

command! -bar -nargs=*
      \ -complete=customlist,fern#internal#command#fern#complete
      \ Fern
      \ call fern#internal#command#fern#command(<q-mods>, [<f-args>])

command! -bar -nargs=*
      \ -complete=customlist,fern#internal#command#do#complete
      \ FernDo
      \ call fern#internal#command#do#command(<q-mods>, [<f-args>])

function! s:BufReadCmd() abort
  if exists('b:fern')
    return
  endif
  call fern#internal#viewer#init()
        \.catch({ e -> fern#logger#error(e) })
endfunction

augroup fern_internal
  autocmd! *
  autocmd BufReadCmd fern://* ++nested call s:BufReadCmd()
  autocmd SessionLoadPost fern://* ++nested call s:BufReadCmd()
augroup END
