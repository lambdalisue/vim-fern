let s:Config = vital#fern#import('Config')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:Promise = vital#fern#import('Async.Promise')
let s:CancellationTokenSource = vital#fern#import('Async.CancellationTokenSource')

let s:STATUS_EXPANDED = g:fern#internal#node#STATUS_EXPANDED

function! fern#internal#core#new(url, provider, ...) abort
  let options = extend({
        \ 'comparator': 'default',
        \}, a:0 ? a:1 : {},
        \)
  let root = fern#internal#node#root(a:url, a:provider)
  let fern = {
        \ 'source': s:CancellationTokenSource.new(),
        \ 'provider': a:provider,
        \ 'comparator': g:fern#internal#core#comparators[options.comparator],
        \ 'root': root,
        \ 'nodes': [root],
        \ 'visible_nodes': [root],
        \ 'marks': [],
        \ 'hide': g:fern#internal#core#hide,
        \ 'include': g:fern#internal#core#include,
        \ 'exclude': g:fern#internal#core#exclude,
        \}
  return fern
endfunction

function! fern#internal#core#cancel(fern) abort
  call a:fern.source.cancel()
  let a:fern.source = s:CancellationTokenSource.new()
endfunction

function! fern#internal#core#update_nodes(fern, nodes) abort
  let a:fern.nodes = a:nodes
  let include = a:fern.include
  let exclude = a:fern.exclude
  let Hidden = !a:fern.hide
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || !n.hidden }
  let Include = empty(include)
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || n.label =~ include }
  let Exclude  = empty(exclude)
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || n.label !~ exclude }
  return s:Promise.resolve(a:fern.nodes)
        \.then(s:AsyncLambda.filter_f(Hidden))
        \.then(s:AsyncLambda.filter_f(Include))
        \.then(s:AsyncLambda.filter_f(Exclude))
        \.then({ ns -> s:Lambda.let(a:fern, 'visible_nodes', ns) })
        \.then({ -> fern#internal#core#update_marks(a:fern, a:fern.marks) })
endfunction

function! fern#internal#core#update_marks(fern, marks) abort
  return s:Promise.resolve(a:fern.visible_nodes)
        \.then(s:AsyncLambda.map_f({ n -> n.__key }))
        \.then({ ks -> s:AsyncLambda.filter(a:marks, { m -> index(ks, m) isnot# -1 }) })
        \.then({ ms -> s:Lambda.let(a:fern, 'marks', ms) })
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'hide': 1,
      \ 'include': '',
      \ 'exclude': '',
      \ 'comparator': 'default',
      \ 'comparators': {
      \   'default': function('fern#comparator#default#compare'),
      \   'lexical': function('fern#comparator#lexical#compare'),
      \ },
      \})
