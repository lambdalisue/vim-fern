function! fern#internal#command#focus#command(mods, fargs) abort
  try
    let drawer = fern#internal#args#pop(a:fargs, 'drawer', v:false)

    if len(a:fargs) isnot# 0
          \ || type(drawer) isnot# v:t_bool
      throw 'Usage: FernFocus [-drawer]'
    endif

    " Does all options are handled?
    call fern#internal#args#throw_if_dirty(a:fargs)

    let found = fern#internal#window#find(
          \ funcref('s:predicator', [drawer]),
          \ winnr() + 1,
          \)
    if found
      call win_gotoid(win_getid(found))
    endif
  catch
    echohl ErrorMsg
    echo v:exception
    echohl None
    call fern#logger#debug(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#internal#command#focus#complete(arglead, cmdline, cursorpos) abort
  return fern#internal#complete#options(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! s:predicator(drawer, winnr) abort
  let bufname = bufname(winbufnr(a:winnr))
  let fri = fern#fri#parse(bufname)
  return fri.scheme ==# 'fern'
        \ && (!a:drawer || fri.authority =~# '\<drawer\>')
endfunction
