function! s:_vital_created(module) abort
  " build pattern for parsing arguments
  let single_quote = '''\zs[^'']\+\ze'''
  let double_quote = '"\zs[^"]\+\ze"'
  let bare_strings = '\%(\\\s\|[^ ''"]\)\+'
  let s:PARSE_PATTERN = printf(
        \ '\%%(%s\)*\zs\%%(\s\+\|$\)\ze',
        \ join([single_quote, double_quote, bare_strings], '\|')
        \)
  let s:NORM_PATTERN = '^\%("\zs.*\ze"\|''\zs.*\ze''\|.*\)$'
endfunction

function! s:split(cmdline) abort
  return map(
        \ split(a:cmdline, s:PARSE_PATTERN),
        \ 's:_norm(v:val)',
        \)
endfunction

function! s:parse(args) abort
  let options = {}
  let remains = []
  for index in range(len(a:args))
    let term = a:args[index]
    if term ==# '--'
      let remains += a:args[index+1:]
      return [options, remains]
    elseif term =~# '^-\S\+='
      let name = matchstr(term, '^-\zs\S\+\ze=')
      let options[name] = matchstr(term, '^-\S\+=\zs.*')
    elseif term =~# '^-\S\+'
      let name = matchstr(term, '^-\zs\S\+')
      let options[name] = v:true
    else
      call add(remains, term)
    endif
  endfor
  return [options, remains]
endfunction

function! s:flag(args, name) abort
  let pattern = printf('^-%s$', a:name)
  return match(a:args, pattern) isnot# -1
endfunction

function! s:value(args, name, ...) abort
  let pattern = printf('^-%s=\zs.*$', a:name)
  let index = match(a:args, pattern)
  if index is# -1
    return a:0 ? a:1 : v:null
  endif
  return matchstr(a:args[index], pattern)
endfunction


" Private
function! s:_norm(term) abort
  let m = matchlist(a:term, '^\(-\w\|--\S\+=\)\(.\+\)')
  if empty(m)
    return matchstr(a:term, s:NORM_PATTERN)
  endif
  return m[1] . matchstr(m[2], s:NORM_PATTERN)
endfunction
