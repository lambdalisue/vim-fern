let s:Config = vital#fern#import('Config')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:Promise = vital#fern#import('Async.Promise')
let s:CancellationTokenSource = vital#fern#import('Async.CancellationTokenSource')

let s:STATUS_EXPANDED = g:fern#STATUS_EXPANDED
let s:default_renderer = function('fern#renderer#default#new')
let s:default_comparator = function('fern#comparator#default#new')

function! fern#internal#core#new(url, provider, ...) abort
  let options = extend({
        \ 'renderer': g:fern#renderer,
        \ 'comparator': g:fern#comparator,
        \}, a:0 ? a:1 : {},
        \)
  let scheme = fern#fri#parse(a:url).scheme
  let root = fern#internal#node#root(a:url, a:provider)
  let fern = {
        \ 'scheme': scheme,
        \ 'source': s:CancellationTokenSource.new(),
        \ 'provider': a:provider,
        \ 'renderer': s:get_renderer(options.renderer),
        \ 'comparator': s:get_comparator(options.comparator),
        \ 'root': root,
        \ 'nodes': [root],
        \ 'visible_nodes': [root],
        \ 'marks': [],
        \ 'hidden': g:fern#default_hidden,
        \ 'include': g:fern#default_include,
        \ 'exclude': g:fern#default_exclude,
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
  let l:Hidden = a:fern.hidden
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || !n.hidden }
  let l:Include = empty(include)
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || n.label =~ include }
  let l:Exclude  = empty(exclude)
       \ ? { -> 1 }
       \ : { n -> n.status is# s:STATUS_EXPANDED || n.label !~ exclude }
  let l:Profile = fern#profile#start('fern#internal#core#update_nodes')
  return s:Promise.resolve(a:fern.nodes)
        \.then(s:AsyncLambda.filter_f(Hidden))
        \.finally({ -> Profile('hidden') })
        \.then(s:AsyncLambda.filter_f(Include))
        \.finally({ -> Profile('include') })
        \.then(s:AsyncLambda.filter_f(Exclude))
        \.finally({ -> Profile('exclude') })
        \.then({ ns -> s:Lambda.let(a:fern, 'visible_nodes', ns) })
        \.finally({ -> Profile('let') })
        \.then({ -> fern#internal#core#update_marks(a:fern, a:fern.marks) })
        \.finally({ -> Profile() })
endfunction

function! fern#internal#core#update_marks(fern, marks) abort
  let l:Profile = fern#profile#start('fern#internal#core#update_marks')
  return s:Promise.resolve(a:fern.visible_nodes)
        \.finally({ -> Profile('resolve') })
        \.then(s:AsyncLambda.map_f({ n -> n.__key }))
        \.finally({ -> Profile('key') })
        \.then({ ks -> s:AsyncLambda.filter(a:marks, { m -> index(ks, m) isnot# -1 }) })
        \.finally({ -> Profile('filter') })
        \.then({ ms -> s:Lambda.let(a:fern, 'marks', ms) })
        \.finally({ -> Profile() })
endfunction

function! s:get_renderer(name) abort
  try
    let l:Renderer = get(g:fern#renderers, a:name, s:default_renderer)
    return Renderer()
  catch
    call fern#logger#error('fern#internal#core:get_renderer', v:exception)
    call fern#logger#debug(v:throwpoint)
    return s:default_renderer()
  endtry
endfunction

function! s:get_comparator(name) abort
  try
    let l:Comparator = get(g:fern#comparators, a:name, s:default_comparator)
    return Comparator()
  catch
    call fern#logger#error('fern#internal#core:get_comparator', v:exception)
    call fern#logger#debug(v:throwpoint)
    return s:default_comparator()
  endtry
endfunction
