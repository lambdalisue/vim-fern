let s:Config = vital#trea#import('Config')
let s:Lambda = vital#trea#import('Lambda')
let s:AsyncLambda = vital#trea#import('Async.Lambda')
let s:Promise = vital#trea#import('Async.Promise')
let s:CancellationTokenSource = vital#trea#import('Async.CancellationTokenSource')

let s:STATUS_EXPANDED = g:trea#internal#node#STATUS_EXPANDED

function! trea#internal#core#new(url, provider, ...) abort
  let options = extend({
        \ 'comparator': 'default',
        \}, a:0 ? a:1 : {},
        \)
  let root = trea#internal#node#root(a:url, a:provider)
  let trea = {
        \ 'source': s:CancellationTokenSource.new(),
        \ 'provider': a:provider,
        \ 'comparator': g:trea#internal#core#comparators[options.comparator],
        \ 'root': root,
        \ 'nodes': [root],
        \ 'visible_nodes': [root],
        \ 'marks': [],
        \ 'hidden': 0,
        \ 'include': g:trea#internal#core#include,
        \ 'exclude': g:trea#internal#core#exclude,
        \}
  return trea
endfunction

function! trea#internal#core#cancel(trea) abort
  call a:trea.source.cancel()
  let a:trea.source = s:CancellationTokenSource.new()
endfunction

function! trea#internal#core#update_nodes(trea, nodes) abort
  let a:trea.nodes = copy(a:nodes)
  let include = a:trea.include
  let exclude = a:trea.exclude
  let Hidden = a:trea.hidden
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || !n.hidden }
  let Include = empty(include)
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || n.label =~ include }
  let Exclude  = empty(exclude)
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || n.label !~ exclude }
  return s:Promise.resolve(a:trea.nodes)
        \.then(s:AsyncLambda.filter_f(Hidden))
        \.then(s:AsyncLambda.filter_f(Include))
        \.then(s:AsyncLambda.filter_f(Exclude))
        \.then({ ns -> s:Lambda.let(a:trea, 'visible_nodes', ns) })
        \.then({ -> trea#internal#core#update_marks(a:trea, a:trea.marks) })
endfunction

function! trea#internal#core#update_marks(trea, marks) abort
  return s:Promise.resolve(a:trea.visible_nodes)
        \.then(s:AsyncLambda.map_f({ n -> n.__key }))
        \.then({ ks -> s:AsyncLambda.filter(a:marks, { m -> index(ks, m) isnot# -1 }) })
        \.then({ ms -> s:Lambda.let(a:trea, 'marks', ms) })
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'include': '',
      \ 'exclude': '',
      \ 'comparator': 'default',
      \ 'comparators': {
      \   'default': function('trea#comparator#default#compare'),
      \   'lexical': function('trea#comparator#lexical#compare'),
      \ },
      \})
