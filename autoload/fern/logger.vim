let s:Later = vital#fern#import('Async.Later')

function! fern#logger#debug(...) abort
  if g:fern#loglevel > g:fern#logger#DEBUG
    return
  endif
  call call('s:log', ['DEBUG'] + a:000)
endfunction

function! fern#logger#info(...) abort
  if g:fern#loglevel > g:fern#logger#INFO
    return
  endif
  call call('s:log', ['INFO'] + a:000)
endfunction

function! fern#logger#warn(...) abort
  if g:fern#loglevel > g:fern#logger#WARN
    return
  endif
  call call('s:log', ['WARN'] + a:000)
endfunction

function! fern#logger#error(...) abort
  if g:fern#loglevel > g:fern#logger#ERROR
    return
  endif
  call call('s:log', ['ERROR'] + a:000)
endfunction

function! s:log(level, ...) abort
  let content = s:format(a:level, a:000)
  if g:fern#logfile is# v:null
    call s:Later.call({ -> s:echomsg(content) })
  else
    call s:Later.call({ -> s:writefile(content) })
  endif
endfunction

function! s:echomsg(content) abort
  let more = &more
  try
    set nomore
    for line in a:content
      echomsg '[fern] ' . line | redraw | echo
    endfor
  finally
    let &more = more
  endtry
endfunction

function! s:writefile(content) abort
  try
    let time = strftime('%H:%M:%S')
    let path = fnamemodify(expand(g:fern#logfile), ':p')
    call mkdir(fnamemodify(path, ':h'), 'p')
    call writefile(map(copy(a:content), { -> join([time, v:val], "\t") }), path, 'a')
  catch
    echohl ErrorMsg
    echo v:exception
    echo v:throwpoint
    echohl None
  endtry
endfunction

function! s:format(level, args) abort
  let m = join(map(copy(a:args), { _, v -> type(v) is# v:t_string ? v : string(v) }))
  return map(split(m, '\n'), { -> printf("%-5S:\t%s", a:level, v:val) })
endfunction

let g:fern#logger#DEBUG = 0
let g:fern#logger#INFO = 1
let g:fern#logger#WARN = 2
let g:fern#logger#ERROR = 3
lockvar g:fern#logger#DEBUG
lockvar g:fern#logger#INFO
lockvar g:fern#logger#WARN
lockvar g:fern#logger#ERROR
