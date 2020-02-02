  let s:Promise = vital#fern#import('Async.Promise')

function! fern#util#sleep(ms) abort
  return s:Promise.new({ resolve -> timer_start(a:ms, { -> resolve() }) })
endfunction

function! fern#util#deprecated(name, ...) abort
  if a:0
    call fern#logger#warn(printf(
          \ '%s has deprecated. Use %s instead.',
          \ a:name,
          \ a:1,
          \))
  else
    call fern#logger#warn(printf(
          \ '%s has deprecated. See :help %s.',
          \ a:name,
          \ a:name,
          \))
  endif
endfunction

function! fern#util#obsolete(name, ...) abort
  if a:0
    throw printf(
          \ '%s has obsolete. Use %s instead.',
          \ a:name,
          \ a:1,
          \)
  else
    throw printf(
          \ '%s has obsolete. See :help %s.',
          \ a:name,
          \ a:name,
          \)
  endif
endfunction
