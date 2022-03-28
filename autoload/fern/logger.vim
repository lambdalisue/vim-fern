let s:Later = vital#fern#import('Async.Later')
let s:LEVEL_HIGHLIGHT = {
      \ 'DEBUG': 'Comment',
      \ 'INFO': 'Special',
      \ 'WARN': 'WarningMsg',
      \ 'ERROR': 'ErrorMsg',
      \}

function! fern#logger#tap(value, ...) abort
  call call('fern#logger#debug', [a:value] + a:000)
  return a:value
endfunction

function! fern#logger#debug(...) abort
  if g:fern#loglevel > g:fern#DEBUG
    return
  endif
  call call('s:log', ['DEBUG'] + a:000)
endfunction

function! fern#logger#info(...) abort
  if g:fern#loglevel > g:fern#INFO
    return
  endif
  call call('s:log', ['INFO'] + a:000)
endfunction

function! fern#logger#warn(...) abort
  if g:fern#loglevel > g:fern#WARN
    return
  endif
  call call('s:log', ['WARN'] + a:000)
endfunction

function! fern#logger#error(...) abort
  if g:fern#loglevel > g:fern#ERROR
    return
  endif
  call call('s:log', ['ERROR'] + a:000)
endfunction

function! s:log(level, ...) abort
  if g:fern#logfile is# v:null
    let hl = get(s:LEVEL_HIGHLIGHT, a:level, 'None')
    let content = s:format(a:level, a:000, ' ')
    call s:Later.call({ -> s:echomsg(hl, content) })
  else
    let content = s:format(a:level, a:000, "\t")
    call s:Later.call({ -> s:writefile(content) })
  endif
endfunction

function! s:echomsg(hl, content) abort
  let more = &more
  try
    set nomore
    execute printf('echohl %s', a:hl)
    for line in a:content
      echomsg '[fern] ' . line | redraw | echo
    endfor
  finally
    echohl None
    let &more = more
  endtry
endfunction

function! s:writefile(content) abort
  try
    let time = strftime('%H:%M:%S')
    let path = fnamemodify(fern#util#expand(g:fern#logfile), ':p')
    call mkdir(fnamemodify(path, ':h'), 'p')
    call writefile(map(copy(a:content), { -> join([time, v:val], "\t") }), path, 'a')
  catch
    echohl ErrorMsg
    echo v:exception
    echo v:throwpoint
    echohl None
  endtry
endfunction

function! s:format(level, args, sep) abort
  let m = join(map(copy(a:args), { _, v -> type(v) is# v:t_string ? v : string(v) }))
  return map(split(m, '\n'), { -> printf("%-5S:%s%s", a:level, a:sep, v:val) })
endfunction

" For backword compatibility
const g:fern#logger#DEBUG = g:fern#DEBUG
const g:fern#logger#INFO = g:fern#INFO
const g:fern#logger#WARN = g:fern#WARN
const g:fern#logger#ERROR = g:fern#ERROR
