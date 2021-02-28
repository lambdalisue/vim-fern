function! fern#helper#new(...) abort
  let bufnr = a:0 ? a:1 : bufnr('%')
  let fern = getbufvar(bufnr, 'fern', v:null)
  if fern is# v:null
    throw printf('the buffer %s is not properly initialized for fern', bufnr)
  endif
  let helper = extend({
        \ 'fern': fern,
        \ 'bufnr': bufnr,
        \ 'winid': bufnr('%') == bufnr ? win_getid() : bufwinid(bufnr),
        \}, s:helper)
  let helper.sync = fern#helper#sync#new(helper)
  let helper.async = fern#helper#async#new(helper)
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
