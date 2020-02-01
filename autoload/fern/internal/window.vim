let s:Config = vital#fern#import('Config')
let s:Prompt = vital#fern#import('Prompt')

function! fern#internal#window#find(predicator, ...) abort
  let n = winnr('$')
  if n is# 1
    return 1
  endif
  let origin = (a:0 ? a:1 : winnr()) - 1
  let s = origin % n
  let e = (s - 1) % n
  let former = range(s < 0 ? s + n : s, n - 1)
  let latter = range(0, e < 0 ? e + n : e)
  for winnr in (former + latter)
    if a:predicator(winnr + 1)
      return winnr + 1
    endif
  endfor
  return 0
endfunction

function! fern#internal#window#locate(...) abort
  let winnr = a:0 ? a:1 : winnr('#')
  call fern#internal#locator#focus(winnr('#'))
endfunction

function! fern#internal#window#select() abort
  let threshold = g:fern#internal#locator#threshold
  while threshold > 0
    let ws = filter(
          \ range(1, winnr('$')),
          \ { -> fern#internal#locator#score(v:val) >= threshold },
          \)
    if empty(ws)
      let threshold -= 1
    else
      break
    endif
  endwhile
  if empty(ws)
    let ws = range(1, winnr('$'))
  endif
  return s:select(ws, {
        \ 'auto_select': g:fern#internal#window#auto_select,
        \})
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
    for num in range(length + 1)
      execute printf('cnoremap <buffer><silent> %s %s<CR>', num, num)
    endfor
    call map(keys(store), { k, v -> setwinvar(v, '&statusline', s:_statusline(v, k + 1)) })
    redrawstatus
    let n = input(printf('choose number [1-%d]: ', length))
    redraw | echo
    if n is# v:null
      return 1
    endif
    call win_gotoid(win_getid(a:winnrs[n - 1]))
  finally
    for num in range(length + 1)
      execute printf('silent! cunmap <buffer> %s', num)
    endfor
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

call s:Config.config(expand('<sfile>:p'), {
      \ 'auto_select': 1,
      \})
