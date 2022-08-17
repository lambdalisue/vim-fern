let s:Config = vital#fern#import('Config')
let s:WindowSelector = vital#fern#import('App.WindowSelector')

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
  let ws = fern#internal#locator#list()
  let ws = empty(ws) ? range(1, winnr('$')) : ws
  return s:WindowSelector.select(ws, {
        \ 'auto_select': g:fern#internal#window#auto_select,
        \ 'select_chars': g:fern#internal#window#select_chars,
        \ 'statusline_hl': 'FernWindowSelectStatusLine',
        \ 'indicator_hl': 'FernWindowSelectIndicator',
        \ 'use_winbar': g:fern#internal#window#use_winbar,
        \ 'use_popup': g:fern#window_selector_use_popup,
        \})
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'auto_select': 1,
      \ 'select_chars': split('abcdefghijklmnopqrstuvwxyz', '\zs'),
      \ 'use_winbar': exists('&winbar') && &laststatus is# 3,
      \})

function! s:highlight() abort
  highlight default link FernWindowSelectStatusLine VitalWindowSelectorStatusLine
  highlight default link FernWindowSelectIndicator VitalWindowSelectorIndicator
endfunction

augroup fern_internal_window
  autocmd!
  autocmd ColorScheme * call s:highlight()
augroup END

call s:highlight()
