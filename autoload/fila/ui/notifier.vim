function! fila#ui#notifier#notify(bufnr) abort
  if bufnr('%') is# a:bufnr
    call s:notify_on_local()
  elseif bufwinid(a:bufnr) isnot# -1
    call s:notify_on_window(a:bufnr)
  else
    call s:notify_on_hidden(a:bufnr)
  endif
endfunction

function! s:notify_on_local() abort
  let notifier = get(b:, 'fila_notifier', v:null)
  if notifier isnot# v:null
    let b:fila_notifier = v:null
    call notifier.notify()
  endif
  doautocmd <nomodeline> User FilaViewerReady
endfunction

function! s:notify_on_window(bufnr) abort
  let winid = win_getid()
  try
    call win_gotoid(bufwinid(a:bufnr))
    call s:notify_on_local()
  finally
    call win_gotoid(winid)
  endtry
endfunction

function! s:notify_on_hidden(bufnr) abort
  let bufnr = bufnr('%')
  let bufhidden = &bufhidden
  try
    setlocal bufhidden=hide
    silent execute printf('keepjumps keepalt %dbuffer', a:bufnr)
    call s:notify_on_local()
  finally
    silent execute printf('keepjumps keepalt %dbuffer', bufnr)
    let &bufhidden = bufhidden
  endtry
endfunction
