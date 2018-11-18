function! fila#node#renderer#render(nodes, options) abort
  let options = extend({
        \ 'leading': ' ',
        \ 'root_symbol': '',
        \ 'leaf_symbol': '|  ',
        \ 'expanded_symbol': '|- ',
        \ 'collapsed_symbol': '|+ ',
        \}, a:options)
  let base = len(a:nodes[0].key)
  return map(copy(a:nodes), { -> s:render(v:val, base, options) })
endfunction

function! s:render(node, base, options) abort
  let level = len(a:node.key) - a:base
  if level is# 0
    return a:options.root_symbol . a:node.text
  endif
  let leading = repeat(a:options.leading, level - 1)
  let symbol = fila#node#is_branch(a:node)
        \ ? fila#node#is_expanded(a:node)
        \   ? a:options.expanded_symbol
        \   : a:options.collapsed_symbol
        \ : a:options.leaf_symbol
  return leading . symbol . a:node.text
endfunction
