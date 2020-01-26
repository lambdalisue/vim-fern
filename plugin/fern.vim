if exists('g:fern_loaded')
  finish
endif
let g:fern_loaded = 1

command! -nargs=*
      \ -complete=customlist,fern#command#fern#complete
      \ Fern
      \ call fern#command#fern#command(<q-mods>, <q-args>)

command! -nargs=*
      \ -complete=customlist,fern#command#focus#complete
      \ FernFocus
      \ call fern#command#focus#command(<q-mods>, <q-args>)

function! s:BufReadCmd() abort
  call fern#internal#viewer#init()
        \.catch({ e -> fern#message#error(e) })
endfunction

augroup fern_internal
  autocmd! *
  autocmd BufReadCmd fern:* nested call s:BufReadCmd()
  autocmd BufReadCmd fern:*/* nested call s:BufReadCmd()
augroup END

let g:fern_debug = get(g:, 'fern_debug', 0)
let g:fern_sample_tree = {
      \ 'shallow': {
      \   'alpha': {},
      \   'beta': {},
      \   'gamma': 'value',
      \ },
      \ 'deep': {
      \   'alpha': {
      \     'beta': {
      \       'gamma': 'value',
      \     },
      \   },
      \ },
      \ 'leaf': 'value',
      \}
