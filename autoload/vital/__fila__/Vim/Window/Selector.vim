function! s:_vital_depends() abort
  return ['Prompt']
endfunction

function! s:_vital_loaded(V) abort
  let s:Prompt = a:V.import('Prompt')
endfunction

function! s:select(winnrs, ...) abort
  let options = extend({
        \ 'auto_select': 0,
        \}, a:0 ? a:1 : {})
  if options.auto_select && len(a:winnrs) <= 1
    call win_gotoid(len(a:winnrs) ? win_getid(a:winnrs[0]) : win_getid())
    return 0
  endif
  let length = len(a:winnrs)
  let store = {}
  for winnr in a:winnrs
    let store[winnr] = getwinvar(winnr, '&statusline')
  endfor
  try
    call map(keys(store), { k, v -> setwinvar(v, '&statusline', s:_statusline(v, k + 1)) })
    redrawstatus
    let n = s:Prompt.select(
          \ printf('choose number [1-%d]: ', length),
          \ len(length . ''),
          \)
    redraw | echo
    if n is# v:null
      return 1
    endif
    call win_gotoid(win_getid(a:winnrs[n - 1]))
  finally
    call map(keys(store), { _, v -> setwinvar(v, '&statusline', store[v]) })
    redrawstatus
  endtry
endfunction

function! s:_statusline(winnr, n) abort
  let width = winwidth(a:winnr) - len(a:winnr . '') - 6
  let leading = repeat(' ', width / 2)
  return printf(
        \ '%%#NonText#%s%%#DiffText#   %d   %%#NonText#',
        \ leading, a:n,
        \)
endfunction
