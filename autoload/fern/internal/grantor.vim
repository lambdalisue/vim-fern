let s:Promise = vital#fern#import('Async.Promise')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

let s:processing = 0

function! fern#internal#grantor#init_once() abort
  if exists('s:init')
    return
  endif
  let s:init = 1
  call fern#hook#add('viewer:redraw', funcref('s:redraw'))
  call fern#hook#add('renderer:syntax', { h -> h.fern.grantor.syntax() })
  call fern#hook#add('renderer:highlight', { h -> h.fern.grantor.highlight() })
endfunction

function! s:redraw(helper) abort
  if s:processing
    return
  endif
  let s:processing = 1
  call a:helper.fern.grantor.grant(a:helper)
        \.then({ r -> empty(r) ? s:Promise.reject(v:null) : r })
        \.then({ r -> s:update_nodes(a:helper, r) })
        \.then({ -> a:helper.async.redraw() })
        \.catch({ e -> s:on_catch(e) })
        \.finally({ -> s:Lambda.let(s:, 'processing', 0) })
endfunction

function! s:process_grantor(helper, grantor) abort
  return a:grantor.grant(a:helper)
        \.then({ r -> empty(r) ? s:Promise.reject(v:null) : r })
        \.then({ r -> s:update_nodes(a:helper, r) })
endfunction

function! s:update_nodes(helper, badge_map) abort
  return s:Promise.resolve(a:helper.fern.nodes)
        \.then(s:AsyncLambda.map_f({ n -> s:Lambda.let(n, 'badge', get(a:badge_map, join(n.__key, '/'), '')) }))
endfunction

function! s:on_catch(error) abort
  if a:error is# v:null
    return
  endif
  echohl ErrorMsg
  if type(a:error) is# v:t_string
    for line in split(a:error, '\n')
      echomsg printf("[fern] %s", line)
    endfor
  else
    echomsg printf("[fern] %s", string(a:error))
  endif
  echohl None
endfunction
