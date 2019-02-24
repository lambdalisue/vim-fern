if exists('g:fila_provider_file_loaded')
  finish
endif
let g:fila_provider_file_loaded = 1

" function! s:BufReadCmd() abort
"   let resource_uri = fnamemodify(expand('<amatch>'), ':p:gs?\\?/?')
"   let resource_uri = fila#tree#item#uri(resource_uri)
"   execute 'file fila:///' . resource_uri
"   let provider = fila#provider#file#new()
"   let options = {
"        \ 'resource_uri': resource_uri,
"        \}
"   call fila#ui#viewer#init(provider, options)
"        \.then({ h -> h.redraw() })
"        \.then({ h -> fila#ui#notifier#notify(h.bufnr) })
"   setlocal filetype=fila
" endfunction
"
" function! s:hijack(bufname) abort
"   if a:bufname ==# ''
"     return
"   elseif !isdirectory(a:bufname)
"     return
"   endif
"   augroup FileExplorer
"     autocmd!
"   augroup END
"   call s:BufReadCmd()
" endfunction
"
" augroup fila_provider_file_internal
"   autocmd! *
"   autocmd BufNew * call s:hijack(expand('<amatch>'))
" augroup END
"
" augroup FileExplorer
"   autocmd!
" augroup END
function! s:BufReadCmd() abort
  let resource_uri = matchstr(expand('<afile>'), '^fila://file2://\zs.*')
  let resource_uri = fila#tree#item#uri(resource_uri)
  let provider = fila#provider#file#new()
  let options = {
        \ 'resource_uri': resource_uri,
        \}
  call fila#ui#viewer#init(provider, options)
        \.then({ h -> h.redraw() })
        \.then({ h -> fila#ui#notifier#notify(h.bufnr) })
  setlocal filetype=fila
endfunction

augroup fila_provider_file_internal
  autocmd! *
  autocmd BufReadCmd fila://file2://* nested call s:BufReadCmd()
augroup END
