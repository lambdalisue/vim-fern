let s:Config = vital#fila#import('Config')

function! fila#renderer#default#new() abort
  return {
        \ 'render': funcref('s:render'),
        \ 'syntax': funcref('s:syntax'),
        \ 'highlight': funcref('s:highlight'),
        \}
endfunction

function! s:render(nodes, marks) abort
  let options = {
        \ 'leading': g:fila#renderer#default#leading,
        \ 'root_symbol': g:fila#renderer#default#root_symbol,
        \ 'leaf_symbol': g:fila#renderer#default#leaf_symbol,
        \ 'expanded_symbol': g:fila#renderer#default#expanded_symbol,
        \ 'collapsed_symbol': g:fila#renderer#default#collapsed_symbol,
        \ 'marked_symbol': g:fila#renderer#default#marked_symbol,
        \ 'unmarked_symbol': g:fila#renderer#default#unmarked_symbol,
        \}
  let base = len(a:nodes[0].key)
  return map(copy(a:nodes), { -> s:render_node(v:val, a:marks, base, options) })
endfunction

function! s:render_node(node, marks, base, options) abort
  let prefix = index(a:marks, a:node.key) is# -1
        \ ? a:options.unmarked_symbol
        \ : a:options.marked_symbol
  let level = len(a:node.key) - a:base
  if level is# 0
    return prefix . a:options.root_symbol . a:node.text
  endif
  let leading = repeat(a:options.leading, level - 1)
  let symbol = fila#node#is_branch(a:node)
        \ ? fila#node#is_expanded(a:node)
        \   ? a:options.expanded_symbol
        \   : a:options.collapsed_symbol
        \ : a:options.leaf_symbol
  return prefix . leading . symbol . a:node.text
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

