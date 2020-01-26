let s:options = ['-drawer']

function! fern#command#focus#command(mods, qargs) abort
  try
    let [options, _] = fern#command#parse(a:qargs)

    let drawer = options.pop('drawer', v:null)

    call options.throw_if_dirty()

    if drawer
      call fern#internal#drawer#focus_next()
    else
      call fern#internal#viewer#focus_next()
    endif
  catch
    call fern#message#error(v:exception)
    call fern#message#debug(v:throwpoint)
  endtry
endfunction

function! fern#command#focus#complete(arglead, cmdline, cursorpos) abort
  return filter(copy(s:options), { -> v:val =~# '^' . a:arglead })
endfunction
