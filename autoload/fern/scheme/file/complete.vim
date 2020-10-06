let s:PATHSEP = fnamemodify('.', ':p')[-1 :]

function! fern#scheme#file#complete#url(arglead, cmdline, cursorpos) abort
  let suffix = a:arglead =~# '/$' ? s:PATHSEP : ''
  let fpath = fern#fri#to#filepath(fern#fri#parse(a:arglead))
  let rs = s:complete_filepath(fpath . suffix, 'dir')
  call map(rs, { -> fern#fri#from#filepath(v:val) })
  call map(rs, { -> fern#fri#format(v:val) })
  return rs
endfunction

function! fern#scheme#file#complete#reveal(arglead, cmdline, cursorpos) abort
  let base_url = matchstr(a:cmdline, '\<file://\S*')
  let fbase = fern#fri#to#filepath(fern#fri#parse(base_url))
  let path = matchstr(a:arglead, '^-reveal=\zs.*')
  let suffix = path =~# '/$' ? s:PATHSEP : ''
  let fpath = path ==# '' ? '' : fern#internal#filepath#from_slash(path)
  let rs = s:complete_reveal(fpath . suffix, fbase)
  call map(rs, { -> fern#internal#filepath#to_slash(v:val) })
  call map(rs, { -> printf('-reveal=%s', v:val) })
  return rs
endfunction

function! fern#scheme#file#complete#filepath(arglead, cmdline, cursorpos) abort
  let rs = s:complete_filepath(a:arglead, 'dir')
  call map(rs, { -> escape(v:val, ' ') })
  return rs
endfunction

function! fern#scheme#file#complete#filepath_reveal(arglead, cmdline, cursorpos) abort
  let fbase = s:get_basepath(a:cmdline)
  let fpath = matchstr(a:arglead, '^-reveal=\zs.*')
  let rs = s:complete_reveal(fpath, fbase)
  call map(rs, { -> substitute(v:val, '[/\\]$', '', '') })
  call map(rs, { -> printf('-reveal=%s', escape(v:val, ' ')) })
  return rs
endfunction

function! s:get_basepath(cmdline) abort
  let fargs = fern#internal#args#split(a:cmdline)
  let fargs = fargs[index(fargs, 'Fern') + 1:]
  let fargs = filter(fargs, { -> v:val[:0] !=# '-' })
  let base = len(fargs) ==# 1 ? fargs[0] : ''
  return fnamemodify(base, ':p')
endfunction

function! s:complete_filepath(path, type) abort
  if fern#internal#filepath#is_uncpath(a:path)
    let fri = fern#fri#from#filepath(a:path)
    if fri.path ==# '' || fri.path !~# '/' && a:path !~# '[/\\]$'
      return s:windows_share_nodes(fri)
    endif
  endif
  return getcompletion(a:path, a:type)
endfunction

function! s:complete_reveal(fpath, fbase) abort
  let [fpath, fbase] = [a:fpath, a:fbase]
  if fpath !=# '' && fern#internal#filepath#is_absolute(fpath)
    return s:complete_filepath(fpath, 'file')
  endif
  if fpath ==# ''
    if fbase !~# '[/\\]$'
      let fbase .= s:PATHSEP
    endif
    let base = fern#internal#filepath#to_slash(fbase)
    let rs = s:complete_filepath(fbase, 'file')
    call map(rs, { -> fern#internal#filepath#to_slash(v:val) })
  else
    let suffix = matchstr(fpath, '[/\\]$')
    let path = fern#internal#filepath#to_slash(fpath)
    let fri = fern#fri#from#filepath(fbase)
    let base = '/' . fri.path
    let fri.path = fern#internal#path#absolute(path, base)[1 :]
    let rs = s:complete_filepath(fern#fri#to#filepath(fri) . suffix, 'file')
    call map(rs, { -> '/' . fern#fri#from#filepath(v:val).path })
  endif
  call map(rs, { -> fern#internal#path#relative(v:val, base) })
  call map(rs, { -> v:val ==# '' ? '' : fern#internal#filepath#from_slash(v:val) })
  return rs
endfunction

if has('win32')
  let s:Promise = vital#fern#import('Async.Promise')
  let s:CancellationToken = vital#fern#import('Async.CancellationToken')

  function! s:windows_share_nodes(fri) abort
    let waiter = fern#scheme#file#util#list_shares(
          \ s:CancellationToken.none, a:fri.authority)
    let [rs, err] = s:Promise.wait(waiter, {'timeout': 2000})
    if err isnot# v:null
      return []
    endif
    if a:fri.path !=# ''
      let path = tolower(a:fri.path)
      let plen = strlen(path)
      call filter(rs, { -> tolower(v:val[: plen]) ==# path })
    endif
    call map(rs, { -> extend(deepcopy(a:fri), {'path': v:val}) })
    call map(rs, { -> fern#fri#to#uncpath(v:val) . '\' })
    call filter(rs, { -> getftype(v:val) ==# 'dir' })
    return rs
  endfunction
endif
