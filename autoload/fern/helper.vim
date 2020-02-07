function! fern#helper#new(...) abort
  let bufnr = a:0 ? a:1 : bufnr('%')
  let fern = getbufvar(bufnr, 'fern', v:null)
  if fern is# v:null
    throw printf('the buffer %s is not properly initialized for fern', bufnr)
  endif
  let helper = extend({
        \ 'fern': fern,
        \ 'bufnr': bufnr,
        \ 'winid': bufwinid(bufnr),
        \}, s:helper)
  let helper.sync = fern#helper#sync#new(helper)
  let helper.async = fern#helper#async#new(helper)
  " Add deprecated methods
  for name in keys(helper.sync)
    if name[:0] ==# '_'
      continue
    endif
    let helper[name] = funcref('s:sync_method', [name])
  endfor
  for name in keys(helper.async)
    if name[:0] ==# '_'
      continue
    endif
    let helper[name] = funcref('s:async_method', [name])
  endfor
  return helper
endfunction

function! fern#helper#call(fn, ...) abort
  return call(a:fn, [fern#helper#new()] + a:000)
endfunction

let s:helper = {
      \ 'STATUS_NONE': g:fern#STATUS_NONE,
      \ 'STATUS_COLLAPSED': g:fern#STATUS_COLLAPSED,
      \ 'STATUS_EXPANDED': g:fern#STATUS_EXPANDED,
      \}

function! s:sync_method(name, ...) abort dict
  call fern#util#deprecated(
        \ printf('helper.%s()', a:name),
        \ printf('helper.sync.%s()', a:name),
        \)
  return call(self.sync[a:name], a:000, self.sync)
endfunction

function! s:async_method(name, ...) abort dict
  call fern#util#deprecated(
        \ printf('helper.%s()', a:name),
        \ printf('helper.async.%s()', a:name),
        \)
  return call(self.async[a:name], a:000, self.async)
endfunction
