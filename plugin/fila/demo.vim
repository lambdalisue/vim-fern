if exists('g:fila_provider_demo_loaded')
  finish
endif
let g:fila_provider_demo_loaded = 1

function! s:BufReadCmd() abort
  let resource_uri = matchstr(expand('<afile>'), '^fila://demo://\zs.*')
  let resource_uri = fila#tree#item#uri(resource_uri)
  let provider = fila#provider#dict#new({
        \ 'Users': {
        \   'Alice': {
        \     'Documents': {},
        \     '.bashrc': 0,
        \   },
        \   'Bob': {
        \     'Documents': {},
        \     '.bashrc': 0,
        \   },
        \   'Catherin': {
        \     'Documents': {},
        \     '.bashrc': 0,
        \   },
        \ },
        \ 'Volumes': {},
        \})
  let options = {
        \ 'resource_uri': resource_uri,
        \}
  call fila#ui#viewer#init(provider, options)
        \.then({ h -> h.redraw() })
        \.then({ h -> fila#ui#notifier#notify(h.bufnr) })
  setlocal filetype=fila
endfunction

augroup fila_provider_demo_internal
  autocmd! *
  autocmd BufReadCmd fila://demo://* nested call s:BufReadCmd()
augroup END
