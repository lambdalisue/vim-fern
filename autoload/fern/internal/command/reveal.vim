let s:Promise = vital#fern#import('Async.Promise')

function! fern#internal#command#reveal#command(modes, fargs) abort
  try
    let wait = fern#internal#args#pop(a:fargs, 'wait', v:false)
    if len(a:fargs) isnot# 1
          \ || type(wait) isnot# v:t_bool
      throw 'Usage: FernReveal {reveal} [-wait]'
    endif

    " Does all options are handled?
    call fern#internal#args#throw_if_dirty(a:fargs)

    let helper = fern#helper#new()
    let reveal = fern#internal#command#reveal#normalize(
          \ fern#fri#parse(bufname('%')),
          \ a:fargs[0],
          \)
    let promise = fern#internal#viewer#reveal(helper, reveal)
    call fern#logger#debug('reveal:', reveal)

    if wait
      let [_, err] = s:Promise.wait(promise, {
            \ 'interval': 100,
            \ 'timeout': 5000,
            \})
      if err isnot# v:null
        throw printf('[fern] Failed to wait: %s', err)
      endif
    endif
  catch
    echohl ErrorMsg
    echomsg v:exception
    echohl None
    call fern#logger#debug(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#internal#command#reveal#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-'
    return fern#internal#complete#options(a:arglead, a:cmdline, a:cursorpos)
  endif
  let helper = fern#helper#new()
  let fri = fern#fri#parse(bufname('%'))
  let scheme = helper.fern.scheme
  let cmdline = fri.path
  let arglead = printf('-reveal=%s', a:arglead)
  let rs = fern#internal#complete#reveal(arglead, cmdline, a:cursorpos)
  return map(rs, { -> matchstr(v:val, '-reveal=\zs.*') })
endfunction

function! fern#internal#command#reveal#normalize(fri, reveal) abort
  let reveal = fern#util#expand(a:reveal)
  if empty(reveal) || !fern#internal#filepath#is_absolute(reveal)
    return reveal
  endif
  " reveal points a real filesystem
  let fri = fern#fri#parse(a:fri.path)
  let root = '/' . fri.path
  let reveal = fern#internal#filepath#to_slash(reveal)
  let reveal = fern#internal#path#relative(reveal, root)
  return reveal
endfunction
