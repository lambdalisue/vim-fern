function! fern#internal#command#do#command(mods, fargs) abort
  let winid_saved = win_getid()
  try
    let stay = fern#internal#args#pop(a:fargs, 'stay', v:false)
    let drawer = fern#internal#args#pop(a:fargs, 'drawer', v:false)

    if len(a:fargs) is# 0
          \ || type(stay) isnot# v:t_bool
          \ || type(drawer) isnot# v:t_bool
      throw 'Usage: FernDo {expr...} [-drawer] [-stay]'
    endif

    " Does all options are handled?
    call fern#internal#args#throw_if_dirty(a:fargs)

    let found = fern#internal#window#find(
          \ funcref('s:predicator', [drawer]),
          \ winnr() + 1,
          \)
    if !found
      return
    endif
    call win_gotoid(win_getid(found))
    execute join([a:mods] + a:fargs, ' ')
  catch
    echohl ErrorMsg
    echo v:exception
    echohl None
    call fern#logger#debug(v:exception)
    call fern#logger#debug(v:throwpoint)
  finally
    if stay
      call win_gotoid(winid_saved)
    endif
  endtry
endfunction

function! fern#internal#command#do#complete(arglead, cmdline, cursorpos) abort
  return fern#internal#complete#options(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! s:predicator(drawer, winnr) abort
  let bufname = bufname(winbufnr(a:winnr))
  let fri = fern#fri#parse(bufname)
  return fri.scheme ==# 'fern'
        \ && (!a:drawer || fri.authority =~# '^drawer:')
endfunction
