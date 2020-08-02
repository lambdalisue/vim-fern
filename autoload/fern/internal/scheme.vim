function! s:call(scheme, name, ...) abort
  try
    return call(printf('fern#scheme#%s#%s', a:scheme, a:name), a:000)
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: fern#scheme#[^#]\+#.*/
    return v:null
  endtry
endfunction

function! fern#internal#scheme#provider_new(scheme) abort
  return call('s:call', [a:scheme, 'provider#new'])
endfunction

function! fern#internal#scheme#mapping_init(scheme, disable_default_mappings) abort
  let mappings = get(g:, printf('fern#scheme#%s#mapping#mappings', a:scheme), [])
  for name in mappings
    call s:call(a:scheme, printf('mapping#%s#init', name), a:disable_default_mappings)
  endfor
  return s:call(a:scheme, 'mapping#init', a:disable_default_mappings)
endfunction

function! fern#internal#scheme#complete_url(scheme, arglead, cmdline, cursorpos) abort
  return s:call(a:scheme, 'complete#url', a:arglead, a:cmdline, a:cursorpos)
endfunction

function! fern#internal#scheme#complete_reveal(scheme, arglead, cmdline, cursorpos) abort
  return s:call(a:scheme, 'complete#reveal', a:arglead, a:cmdline, a:cursorpos)
endfunction
