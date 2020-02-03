let s:options = ['-drawer']

function! fern#command#focus#command(mods, qargs) abort
  try
    let [options, args] = fern#internal#command#parse(a:qargs)

    if len(args) isnot# 0
      echohl ErrorMsg
      echo 'Usage: FernFocus [-drawer]'
      echohl None
      return
    endif

    let drawer = options.pop('drawer', v:null)

    call options.throw_if_dirty()

    let found = fern#internal#window#find(
          \ funcref('s:predicator', [drawer]),
          \ winnr() + 1,
          \)
    if found
      call win_gotoid(win_getid(found))
    endif
  catch
    call fern#logger#error(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#command#focus#complete(arglead, cmdline, cursorpos) abort
  return filter(copy(s:options), { -> v:val =~# '^' . a:arglead })
endfunction

function! s:predicator(drawer, winnr) abort
  let bufname = bufname(winbufnr(a:winnr))
  let fri = fern#fri#parse(bufname)
  return fri.scheme ==# 'fern'
        \ && (!a:drawer || fri.authority =~# '\<drawer\>')
endfunction
