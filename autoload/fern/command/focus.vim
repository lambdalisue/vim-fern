let s:options = ['-drawer']

function! fern#command#focus#command(mods, qargs) abort
  try
    let [options, _] = fern#internal#command#parse(a:qargs)

    let drawer = options.pop('drawer', v:null)

    call options.throw_if_dirty()

    let origin = winnr()
    let n = winnr('$')
    let s = origin % n
    let e = (s - 1) % n
    let former = range(s < 0 ? s + n : s, n - 1)
    let latter = range(0, e < 0 ? e + n : e)
    for winnr in (former + latter)
      let bufname = bufname(winbufnr(winnr))
      let fri = fern#fri#parse(bufname)
      if fri.scheme ==# 'fern'
            \ && (!drawer || fri.authority =~# '\<drawer\>')
        call win_gotoid(win_getid(winnr))
      endif
    endfor
  catch
    call fern#logger#error(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#command#focus#complete(arglead, cmdline, cursorpos) abort
  return filter(copy(s:options), { -> v:val =~# '^' . a:arglead })
endfunction
