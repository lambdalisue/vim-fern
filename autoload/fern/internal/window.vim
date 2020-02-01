let s:Config = vital#fern#import('Config')
let s:WindowLocator = vital#fern#import('Vim.Window.Locator')
let s:WindowSelector = vital#fern#import('Vim.Window.Selector')

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
  call s:WindowLocator.focus(winnr('#'))
endfunction

function! fern#internal#window#select() abort
  let ws = filter(
        \ range(1, winnr('$')),
        \ { -> s:WindowLocator.is_suitable(v:val) },
        \)
  if empty(ws)
    let ws = range(1, winnr('$'))
  endif
  return s:WindowSelector.select(ws, {
        \ 'auto_select': g:fern#internal#window#auto_select,
        \})
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'locator_threshold': {
      \   'winwidth': 0,
      \   'winheight': 0,
      \ },
      \ 'auto_select': 1,
      \})
call s:WindowLocator.set_thresholds(g:fern#internal#window#locator_threshold)

" NOTE:
" g:fern#internal#window#locator_threshold is effective only BEFORE initialization
" so lock this variable to tell users that this variable is not effective
" anymore.
lockvar 2 g:fern#internal#window#locator_threshold
