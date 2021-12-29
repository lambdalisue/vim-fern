function! fern#scheme#file#complete#url(arglead, cmdline, cursorpos) abort
  let path = '/' . fern#fri#parse(a:arglead).path
  let path = fern#internal#filepath#to_slash(path)
  let suffix = a:arglead =~# '/$' ? '/' : ''
  let rs = getcompletion(fern#internal#filepath#from_slash(path) . suffix, 'dir')
  call map(rs, { -> fern#internal#filepath#to_slash(v:val) })
  call map(rs, { -> s:to_fri(v:val) })
  return rs
endfunction

function! fern#scheme#file#complete#reveal(arglead, cmdline, cursorpos) abort
  let base = '/' . fern#fri#parse(matchstr(a:cmdline, '\<file:///\S*')).path
  let path = matchstr(a:arglead, '^-reveal=\zs.*')
  let suffix = matchstr(path, '/$')
  let rs = s:complete_reveal(path, base, suffix)
  call map(rs, { -> printf('-reveal=%s', v:val) })
  return rs
endfunction

function! fern#scheme#file#complete#filepath(arglead, cmdline, cursorpos) abort
  return map(getcompletion(a:arglead, 'dir'), { -> escape(v:val, ' ') })
endfunction

function! fern#scheme#file#complete#filepath_reveal(arglead, cmdline, cursorpos) abort
  let base = fern#internal#filepath#to_slash(s:get_basepath(a:cmdline))
  let path = matchstr(a:arglead, '^-reveal=\zs.*')
  let suffix = matchstr(path, '[/\\]$')
  let path = path ==# '' ? '' : fern#internal#filepath#to_slash(path)
  let rs = s:complete_reveal(path, base, suffix)
  call map(rs, { -> v:val ==# '' ? '' : fern#internal#filepath#from_slash(v:val) })
  call map(rs, { -> printf('-reveal=%s', escape(v:val, ' ')) })
  return rs
endfunction

function! s:to_fri(path) abort
  return fern#fri#format({
        \ 'scheme': 'file',
        \ 'authority': '',
        \ 'path': a:path[1:],
        \ 'query': {},
        \ 'fragment': '',
        \})
endfunction

function! s:get_basepath(cmdline) abort
  let fargs = fern#internal#args#split(a:cmdline)
  let fargs = fargs[index(fargs, 'Fern') + 1:]
  let fargs = filter(fargs, { -> v:val[:0] !=# '-' })
  let base = len(fargs) ==# 1 ? fargs[0] : ''
  let base = base ==# '' ? '.' : base
  return fnamemodify(base, ':p')
endfunction

function! s:complete_reveal(path, base, suffix) abort
  let [path, base, suffix] = [a:path, a:base, a:suffix]
  if path ==# ''
    let path = a:base
    let suffix = '/'
  elseif path[:0] ==# '/'
    let base = ''
  else
    let path = fern#internal#path#absolute(path, a:base)
  endif
  let rs = getcompletion(fern#internal#filepath#from_slash(path) . suffix, 'file')
  call map(rs, { -> fern#internal#filepath#to_slash(v:val) })
  if base !=# ''
    call map(rs, { -> fern#internal#path#relative(v:val, base) })
  endif
  return rs
endfunction
