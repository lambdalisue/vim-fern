function! fila#scheme#file#BufReadCmd() abort
  let path = matchstr(expand('<afile>'), 'fila:file://\zs.*')
  call fila#viewer#BufReadCmd({ -> s:create_root(path) })
endfunction

function! s:create_root(path) abort
  let root = fila#scheme#file#node#new(a:path)
  let root.parent = fila#scheme#file#node#new(fnamemodify(a:path, ':p:h:h'))
  return root
endfunction

function! s:action_define() abort
  let action = fila#action#get()
  call fila#scheme#file#action#define(action)

  nmap <buffer><nowait> ff  <Plug>(fila-action-cd-tcd)
  nmap <buffer><nowait> fi  <Plug>(fila-action-new-file)
  nmap <buffer><nowait> fo  <Plug>(fila-action-new-directory)
  nmap <buffer><nowait> fm  <Plug>(fila-action-move)
  nmap <buffer><nowait> fc  <Plug>(fila-action-copy)
  nmap <buffer><nowait> fp  <Plug>(fila-action-paste)
  nmap <buffer><nowait> fd  <Plug>(fila-action-delete)
endfunction

augroup fila_scheme_file_internal
  autocmd! *
  autocmd User FilaActionDefine call s:action_define()
augroup END
