let s:Promise = vital#fern#import('Async.Promise')

function! fern#util#compare(i1, i2) abort
  return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunction

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

" Apply workaround to expand() issue of completeslash on Windows
" See https://github.com/lambdalisue/fern.vim/issues/226
if exists('+completeslash')
  function! fern#util#expand(expr) abort
    let completeslash_saved = &completeslash
    try
      set completeslash&
      return expand(a:expr)
    finally
      let &completeslash = completeslash_saved
    endtry
  endfunction
else
  function! fern#util#expand(expr) abort
    return expand(a:expr)
  endfunction
endif
