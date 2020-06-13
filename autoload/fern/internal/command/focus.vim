function! fern#internal#command#focus#command(mods, fargs) abort
  call fern#util#deprecated(
        \ '":FernFocus"',
        \ '":FernDo :"'
        \)
  if fern#internal#args#pop(a:fargs, 'drawer', v:false)
    FernDo : -drawer
  else
    FernDo :
  endif
endfunction

function! fern#internal#command#focus#complete(arglead, cmdline, cursorpos) abort
  return fern#internal#complete#options(a:arglead, a:cmdline, a:cursorpos)
endfunction
