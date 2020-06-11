let s:Promise = vital#fern#import('Async.Promise')
let s:hooks = {}

function! fern#hook#add(name, callback, ...) abort
  let options = extend({
        \ 'id': sha256(localtime()),
        \ 'once': v:false,
        \}, a:0 ? a:1 : {},
        \)
  let s:hooks[a:name] = add(get(s:hooks, a:name, []), {
        \ 'callback': a:callback,
        \ 'options': options,
        \})
endfunction

function! fern#hook#remove(name, ...) abort
  let id = a:0 ? a:1 : v:null
  if id is# v:null
    let s:hooks[a:name] = []
    return
  endif
  let hooks = get(s:hooks, a:name, [])
  let keeps = []
  for hook in hooks
    if hook.options.id !=# id
      call add(keeps, hook)
    endif
  endfor
  let s:hooks[a:name] = keeps
endfunction

function! fern#hook#emit(name, ...) abort
  let hooks = get(s:hooks, a:name, [])
  let keeps = []
  for hook in hooks
    try
      call call(hook.callback, a:000)
      if !hook.options.once
        call add(keeps, hook)
      endif
    catch
      call fern#logger#error(v:exception)
      call fern#logger#debug(v:throwpoint)
    endtry
  endfor
  let s:hooks[a:name] = keeps
endfunction

function! fern#hook#promise(name) abort
  return s:Promise.new({ r -> fern#hook#add(a:name, r, { 'once': v:true }) })
endfunction
