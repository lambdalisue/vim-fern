function! fern#lib#url#parse(url) abort
  let u = s:parse_url(a:url)
  let b = s:parse_bare(u.bare)
  let a = s:parse_authority(b.authority)
  let q = s:parse_query(u.query)
  let f = s:parse_fragment(u.fragment)
  return extend({
        \ 'scheme': b.scheme,
        \ 'authority': a,
        \ 'path': b.path,
        \ 'query': q,
        \ 'fragment': f,
        \}, s:url)
endfunction

function! fern#lib#url#simplify(path) abort
  let result = []
  let path = split(a:path, '/')
  for term in path
    if term ==# '..'
      if empty(result) || result[-1] == '..'
        call insert(result, '..', 0)
      else
        call remove(result, -1)
      endif
    elseif term ==# '.' || empty(term)
      continue
    else
      call add(result, term)
    endif
  endfor
  let prefix = a:path[:0] ==# '/' ? '/' : ''
  return prefix . join(result, '/')
endfunction

function! fern#lib#url#commonpath(paths) abort
  for path in a:paths
    if path[:0] !=# '/'
      throw printf("path must be absolute but %s", path)
    endif
  endfor
  let paths = map(copy(a:paths), { -> split(fern#lib#url#simplify(v:val), '/') })
  let common = []
  for index in range(min(map(copy(paths), { -> len(v:val) })))
    let term = paths[0][index]
    if empty(filter(paths[1:], { -> v:val[index] !=? term }))
      call add(common, term)
    endif
  endfor
  return '/' . join(common, '/')
endfunction

function! fern#lib#url#relative(path, base) abort
  if a:path[:0] !=# '/'
    throw printf("path must be absolute but %s", a:path)
  elseif a:base[:0] !=# '/'
    throw printf("base must be absolute but %s", a:base)
  endif
  let path = split(fern#lib#url#simplify(a:path), '/')
  let base = split(fern#lib#url#simplify(a:base), '/')
  for index in range(min([len(path), len(base)]))
    if path[0] !=? base[0]
      break
    endif
    call remove(path, 0)
    call remove(base, 0)
  endfor
  let prefix = repeat('../', len(base))
  return prefix . join(path, '/')
endfunction

function! s:encode(str) abort
  let pattern = '^$~.*[]\'
  let chars = "%:/?#[]@!$&'()*+,;= "
  let rules = map(split(chars, '\zs'), { _, v -> [v, printf('%%%x', char2nr(v))] })
  let str = a:str
  for rule in rules
    let str = substitute(str, escape(rule[0], pattern), rule[1], 'g')
  endfor
  return str
endfunction

function! s:decode(str) abort
  let str = a:str
  let hex = matchstr(str, '%\zs[0-9a-fA-F]\{2}')
  while !empty(hex)
    let repl = nr2char(str2nr(hex, 16))
    let str = substitute(str, '%' . hex, escape(repl, '&'), 'ig')
    let hex = matchstr(str, '%\zs[0-9a-fA-F]\{2}')
  endwhile
  return str
endfunction

function! s:parse_url(url) abort
  let u = matchstr(a:url, '^.\{-}\ze\%(?.\{-}\)\?\%(#.*\)\?$')
  let q = matchstr(a:url, '\zs?.\{-}\ze\%(#.*\)\?$')
  let f = matchstr(a:url, '\zs#.*\ze$')
  return {
        \ 'bare': u,
        \ 'query': q,
        \ 'fragment': f,
        \}
endfunction

function! s:parse_bare(bare) abort
  let m = matchlist(a:bare, '^\([^:]\+\):\(//[^/]*\)\(/.*\)$')
  if empty(m)
    let m = matchlist(a:bare, '^\([^:]\+\):\(.*\)$')
    if empty(m)
      return {
            \ 'scheme': '',
            \ 'authority': '',
            \ 'path': a:bare,
            \}
    endif
    return {
          \ 'scheme': m[1],
          \ 'authority': '',
          \ 'path': m[2],
          \}
  endif
  return {
        \ 'scheme': m[1],
        \ 'authority': m[2],
        \ 'path': m[3],
        \}
endfunction

function! s:parse_authority(authority) abort
  if empty(a:authority)
    return {}
  endif
  let a = matchstr(a:authority, '^//\zs.*')
  let u = matchstr(a, '^.*\ze@')
  let h = matchstr(a, '^\%(.*@\)\?\zs[^:]\+\ze\%(:\d\+\)\?$')
  let p = matchstr(a, ':\zs\d\+$')
  return {
        \ 'userinfo': u,
        \ 'host': empty(h) ? a : h,
        \ 'port': p,
        \}
endfunction

function! s:format_authority(authority) abort
  if empty(a:authority)
    return ''
  endif
  let text = ''
  if !empty(a:authority.userinfo)
    let text .= printf("%s@", a:authority.userinfo)
  endif
  let text .= a:authority.host
  if !empty(a:authority.port)
    let text .= printf(":%s", a:authority.port)
  endif
  return printf("//%s", text)
endfunction

function! s:parse_query(query) abort
  let obj = {}
  let query = matchstr(a:query, '^?\zs.*')
  let terms = split(query, '&\%(\w\+;\)\@!')
  call map(terms, { _, v -> (split(v, '=', 1) + [v:true])[:1] })
  call map(terms, { _, v -> extend(obj, {s:decode(v[0]): s:decode(v[1])})})
  return obj
endfunction

function! s:format_query(query) abort
  if empty(a:query)
    return ''
  endif
  let terms = []
  for [k, v] in items(a:query)
    if v is# v:false || v is# v:null
      continue
    elseif v is# v:true
      call add(terms, s:encode(k))
    else
      call add(terms, printf("%s=%s", s:encode(k), s:encode(v)))
    endif
  endfor
  return printf('?%s', join(terms, '&'))
endfunction

function! s:parse_fragment(fragment) abort
  if empty(a:fragment)
    return ''
  endif
  return s:decode(matchstr(a:fragment, '^#\zs.*'))
endfunction

function! s:format_fragment(fragment) abort
  if empty(a:fragment)
    return ''
  endif
  return printf('#%s', s:encode(a:fragment))
endfunction

let s:url = {}

function! s:url.to_string() abort
  let url = empty(self.scheme) ? '' : printf("%s:", self.scheme)
  let url .= s:format_authority(self.authority)
  let url .= self.path
  let url .= s:format_query(self.query)
  let url .= s:format_fragment(self.fragment)
  return url
endfunction
