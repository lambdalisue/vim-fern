let s:Config = vital#fila#import('Config')
let s:STATUS_NONE      = g:fila#tree#item#STATUS_NONE
let s:STATUS_COLLAPSED = g:fila#tree#item#STATUS_COLLAPSED

function! fila#renderer#default#new() abort
  return {
        \ 'render': funcref('s:render'),
        \ 'syntax': funcref('s:syntax'),
        \ 'highlight': funcref('s:highlight'),
        \ 'translate': { lnum -> lnum - 1 },
        \}
endfunction

function! s:render(items, marks) abort
  let options = {
        \ 'leading': g:fila#renderer#default#leading,
        \ 'root_symbol': g:fila#renderer#default#root_symbol,
        \ 'leaf_symbol': g:fila#renderer#default#leaf_symbol,
        \ 'expanded_symbol': g:fila#renderer#default#expanded_symbol,
        \ 'collapsed_symbol': g:fila#renderer#default#collapsed_symbol,
        \ 'marked_symbol': g:fila#renderer#default#marked_symbol,
        \ 'unmarked_symbol': g:fila#renderer#default#unmarked_symbol,
        \}
  let base = a:items[0].__level
  return map(copy(a:items), { -> s:render_item(v:val, a:marks, base, options) })
endfunction

function! s:render_item(item, marks, base, options) abort
  let prefix = index(a:marks, a:item.resource_uri) is# -1
        \ ? a:options.unmarked_symbol
        \ : a:options.marked_symbol
  let level = a:item.__level - a:base
  " if level is# 0
  "   return prefix . a:options.root_symbol . a:item.label
  " endif
  let leading = repeat(a:options.leading, level)
  let symbol = a:item.status is# s:STATUS_NONE
        \ ? a:options.leaf_symbol
        \ : a:item.status is# s:STATUS_COLLAPSED
        \   ? a:options.collapsed_symbol
        \   : a:options.expanded_symbol
  return prefix . leading . symbol . a:item.label
endfunction

function! s:syntax() abort
  syntax clear
  syntax match FilaRoot   /\%1l.*/
  syntax match FilaLeaf   /^\s*|  /
  syntax match FilaBranch /^\s*|[+-] .*/
  syntax match FilaMarked /^* .*/
endfunction

function! s:highlight() abort
  highlight default link FilaRoot   Directory
  highlight default link FilaLeaf   Directory
  highlight default link FilaBranch Directory
  highlight default link FilaMarked Title
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'leading': ' ',
      \ 'root_symbol': '',
      \ 'leaf_symbol': '|  ',
      \ 'expanded_symbol': '|- ',
      \ 'collapsed_symbol': '|+ ',
      \ 'marked_symbol': '* ',
      \ 'unmarked_symbol': '  ',
      \})
