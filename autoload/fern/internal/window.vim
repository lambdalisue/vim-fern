let s:Config = vital#fern#import('Config')
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
  return s:WindowSelector.select(ws, {
        \ 'auto_select': g:fern#internal#window#auto_select,
        \})
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'auto_select': 1,
      \})
