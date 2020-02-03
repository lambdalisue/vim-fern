let s:indent = 0

function! fern#profile#start(name) abort
  if !get(g:, 'fern#profile')
    return { -> 0 }
  endif
  let now = reltime()
  let ns = {
        \ 'start': now,
        \ 'previous': now,
        \}
  echomsg s:format(a:name, 'enter')
  let s:indent += 1
  return funcref('s:profile_leave', [ns, a:name])
endfunction

function! s:format(name, label, ...) abort
  return printf(
        \ '%s%s [%s] %s',
        \ repeat('| ', s:indent),
        \ a:name,
        \ a:label,
        \ join(a:000),
        \)
endfunction

function! s:profile_leave(ns, name, ...) abort
  let label = a:0 ? a:1 : 'leave'
  let now = reltime()
  let start = a:ns.start
  let previous = a:ns.previous
  let profile = printf(
        \ '%s [%s]',
        \ split(reltimestr(reltime(previous, now)))[0],
        \ split(reltimestr(reltime(start, now)))[0],
        \)
  let a:ns.previous = now
  if a:0 is# 0
    let s:indent -= 1
  endif
  echomsg s:format(a:name, label, profile)
endfunction
