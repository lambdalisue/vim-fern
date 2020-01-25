let s:Flag = vital#fila#import('App.Flag')

let s:options = ['-drawer']

function! trea#command#focus#command(mods, qargs) abort
  let [options, remains] = s:Flag.parse(s:Flag.split(a:qargs))

  if s:validate_options(options)
    return
  endif

  if get(options, 'drawer')
    call trea#internal#drawer#focus_next()
  else
    call trea#internal#viewer#focus_next()
  endif
endfunction

function! trea#command#focus#complete(arglead, cmdline, cursorpos) abort
  return filter(copy(s:options), { -> v:val =~# '^' . a:arglead })
endfunction

function! s:validate_options(options) abort
  for key in keys(a:options)
    if index(s:options, '-' . key) is# -1
      call trea#message#error(printf("Unknown option -%s has specified", key))
      return 1
    endif
  endfor
endfunction
