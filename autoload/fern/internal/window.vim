let s:Config = vital#fern#import('Config')

function! fern#internal#window#find(predicator, ...) abort
  let n = winnr('$')
  if n is# 1
    return a:predicator(winnr())
  endif
  let origin = (a:0 ? a:1 : winnr()) - 1
  let s = origin % n
  let e = (s - 1) % n
  let former = range(s < 0 ? s + n : s, n - 1)
  let latter = range(0, e < 0 ? e + n : e)
  for index in (former + latter)
    let winnr = index + 1
    if a:predicator(winnr)
      return winnr
    endif
  endfor
  return 0
endfunction

function! fern#internal#window#select() abort
  let threshold = g:fern#internal#locator#THRESHOLD
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
    let chars = map(
          \ range(length + 1),
          \ { _, v -> get(g:fern#internal#window#select_chars, v, string(v)) },
          \)
    call map(keys(store), { k, v -> setwinvar(v, '&statusline', s:statusline(v, chars[k])) })
    redrawstatus
    call s:cnoremap_all(chars)
    let n = input('choose window: ')
    call s:cunmap_all()
    redraw | echo
    if n is# v:null
      return 1
    endif
    let n = index(chars, n)
    if n is# -1
      return 1
    endif
    call win_gotoid(win_getid(a:winnrs[n]))
  finally
    call map(keys(store), { _, v -> setwinvar(v, '&statusline', store[v]) })
    redrawstatus
  endtry
endfunction

function! s:statusline(winnr, char) abort
  let width = winwidth(a:winnr) - len(a:winnr . '') - 6
  let leading = repeat(' ', width / 2)
  return printf(
        \ '%%#FernWindowSelectStatusLine#%s%%#FernWindowSelectIndicator#   %s   %%#FernWindowSelectStatusLine#',
        \ leading,
        \ a:char,
        \)
endfunction

function! s:cnoremap_all(chars) abort
  for nr in range(256)
    silent! execute printf("cnoremap \<buffer>\<silent> \<Char-%d> \<Nop>", nr)
  endfor
  for char in a:chars
    silent! execute printf("cnoremap \<buffer>\<silent> %s %s\<CR>", char, char)
  endfor
  silent! cunmap <buffer> <Return>
  silent! cunmap <buffer> <Esc>
endfunction

function! s:cunmap_all() abort
  for nr in range(256)
    silent! execute printf("cunmap \<buffer> \<Char-%d>", nr)
  endfor
endfunction

function! s:highlight() abort
  highlight default link FernWindowSelectStatusLine StatusLineNC
  highlight default link FernWindowSelectIndicator  DiffText
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'auto_select': 1,
      \ 'select_chars': split('abcdefghijklmnopqrstuvwxyz', '\zs'),
      \})

augroup fern_internal_window_internal
  autocmd!
  autocmd ColorScheme * call s:highlight()
augroup END

call s:highlight()
