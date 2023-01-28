let s:Config = vital#fern#import('Config')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

let s:ESCAPE_PATTERN = '^$~.*[]\'
let s:STATUS_NONE = g:fern#STATUS_NONE
let s:STATUS_COLLAPSED = g:fern#STATUS_COLLAPSED

function! fern#renderer#default#new() abort
  return {
        \ 'render': funcref('s:render'),
        \ 'index': funcref('s:index'),
        \ 'lnum': funcref('s:lnum'),
        \ 'syntax': funcref('s:syntax'),
        \ 'highlight': funcref('s:highlight'),
        \}
endfunction

function! s:render(nodes) abort
  let options = {
        \ 'leading': g:fern#renderer#default#leading,
        \ 'root_symbol': g:fern#renderer#default#root_symbol,
        \ 'leaf_symbol': g:fern#renderer#default#leaf_symbol,
        \ 'expanded_symbol': g:fern#renderer#default#expanded_symbol,
        \ 'collapsed_symbol': g:fern#renderer#default#collapsed_symbol,
        \}
  let base = len(a:nodes[0].__key)
  let l:Profile = fern#profile#start('fern#renderer#default#s:render')
  return s:AsyncLambda.map(copy(a:nodes), { v, -> s:render_node(v, base, options) })
        \.finally({ -> Profile() })
endfunction

function! s:index(lnum) abort
  return a:lnum - 1
endfunction

function! s:lnum(index) abort
  return a:index + 1
endfunction

function! s:syntax() abort
  syntax match FernLeaf   /^.*[^/].*$/ transparent contains=FernLeaderSymbol
  syntax match FernBranch /^.*\/.*$/   transparent contains=FernLeaderSymbol
  syntax match FernRoot   /\%1l.*/       transparent contains=FernRootSymbol
  execute printf(
        \ 'syntax match FernRootSymbol /%s/ contained nextgroup=FernRootText',
        \ escape(g:fern#renderer#default#root_symbol, s:ESCAPE_PATTERN),
        \)
  execute printf(
        \ 'syntax match FernLeafSymbol /%s/ contained nextgroup=FernLeafText',
        \ escape(g:fern#renderer#default#leaf_symbol, s:ESCAPE_PATTERN),
        \)
  execute printf(
        \ 'syntax match FernBranchSymbol /\%%(%s\|%s\)/ contained nextgroup=FernBranchText',
        \ escape(g:fern#renderer#default#collapsed_symbol, s:ESCAPE_PATTERN),
        \ escape(g:fern#renderer#default#expanded_symbol, s:ESCAPE_PATTERN),
        \)
  execute printf(
        \ 'syntax match FernLeaderSymbol /^\%%(%s\)*/ contained nextgroup=FernBranchSymbol,FernLeafSymbol',
        \ escape(g:fern#renderer#default#leading, s:ESCAPE_PATTERN),
        \)
  syntax match FernRootText   /.*\ze.*$/ contained nextgroup=FernBadgeSep
  syntax match FernLeafText   /.*\ze.*$/ contained nextgroup=FernBadgeSep
  syntax match FernBranchText /.*\ze.*$/ contained nextgroup=FernBadgeSep
  syntax match FernBadgeSep   //         contained conceal nextgroup=FernBadge
  syntax match FernBadge      /.*/         contained
  setlocal concealcursor=nvic conceallevel=2
endfunction

function! s:highlight() abort
  highlight default link FernRootSymbol   Directory
  highlight default link FernRootText     Directory
  highlight default link FernLeafSymbol   Directory
  highlight default link FernLeafText     None
  highlight default link FernBranchSymbol Directory
  highlight default link FernBranchText   Directory
  highlight default link FernLeaderSymbol Directory
endfunction

function! s:render_node(node, base, options) abort
  let level = len(a:node.__key) - a:base
  if level is# 0
    return a:options.root_symbol . a:node.label . '' . a:node.badge
  endif
  let leading = repeat(a:options.leading, level - 1)
  let symbol = a:node.status is# s:STATUS_NONE
        \ ? a:options.leaf_symbol
        \ : a:node.status is# s:STATUS_COLLAPSED
        \   ? a:options.collapsed_symbol
        \   : a:options.expanded_symbol
  let suffix = a:node.status ? '/' : ''
  return leading . symbol . a:node.label . suffix . '' . a:node.badge
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'leading': ' ',
      \ 'root_symbol': '',
      \ 'leaf_symbol': '|  ',
      \ 'collapsed_symbol': '|+ ',
      \ 'expanded_symbol': '|- ',
      \})
