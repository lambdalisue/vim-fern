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
        \.catch({ e -> fern#logger#error(e) })
endfunction

augroup fern_internal
  autocmd! *
  autocmd BufReadCmd fern://* nested call s:BufReadCmd()
augroup END

let g:fern_debug = get(g:, 'fern_debug', 0)

" fern#profile
let g:fern_profile = get(g:, 'fern_profile', 0)

" fern#logger
let g:fern_logfile = get(g:, 'fern_logfile', v:null)
let g:fern_loglevel = get(g:, 'fern_loglevel', g:fern#logger#ERROR)

" fern#command#fern
let g:fern_opener = get(g:, 'fern_opener', 'edit')

" fern#internal#mapping
let g:fern_disable_default_mappings = get(g:, 'fern_disable_default_mappings', 0)

" fern#internal#core
let g:fern_default_hidden = get(g:, 'fern_default_hidden', 0)
let g:fern_default_include = get(g:, 'fern_default_include', '')
let g:fern_default_exclude = get(g:, 'fern_default_exclude', '')
let g:fern_renderer = get(g:, 'fern_renderer', 'default')
let g:fern_comparator = get(g:, 'fern_comparator', 'default')
