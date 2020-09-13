let s:ESCAPE_PATTERN = '^$~.*[]\'

function! fern#internal#rename_solver#solve(pairs, ...) abort
  let options = extend({
        \ 'exist': { p -> getftype(p) !=# '' },
        \ 'tempname': { _ -> tempname() },
        \ 'isdirectory': { p -> isdirectory(p) },
        \}, a:0 ? a:1 : {},
        \)
  let l:Exist = options.exist
  let l:Tempname = options.tempname
  let l:IsDirectory = options.isdirectory
  " Sort by 'dst' depth
  let pairs = sort(copy(a:pairs), funcref('s:compare'))
  " Build steps from given pairs
  let steps = []
  let tears = []
  let src_map = s:dict(map(
        \ copy(a:pairs),
        \ { -> [v:val[0], 1] },
        \))
  for [src, dst] in pairs
    let rsrc_map = s:dict(map(
          \ copy(a:pairs),
          \ { -> [s:replace(v:val[0], steps), 1] },
          \))
    let rsrc = s:replace(src, steps)
    if rsrc ==# dst
      continue
    endif
    let rdst = s:replace_backword(dst, steps)
    if get(rsrc_map, dst)
      let tmp = Tempname(dst)
      call add(steps, [rsrc, tmp, '', ''])
      call add(tears, [tmp, dst, src, rdst])
    elseif !get(src_map, rdst) && Exist(rdst)
      throw printf('Destination "%s" already exist as "%s"', dst, rdst)
    else
      call add(steps, [rsrc, dst, src, rdst])
    endif
  endfor
  let steps += tears
  " Check 'dst' uniqueness
  let dup = s:find_duplication(map(copy(steps), { -> v:val[1] }))
  if !empty(dup)
    throw printf('Destination "%s" appears more than once', dup)
  endif
  " Check parent directories of 'dst'
  for [rsrc, dst, src, rdst] in steps
    let prv = rdst
    let cur = fern#internal#path#dirname(prv)
    while cur !=# '' && cur !=# prv
      if !Exist(cur)
        break
      elseif !IsDirectory(cur)
        throw printf(
              \ 'Destination "%s" in "%s" is not directory',
              \ s:replace(cur, steps),
              \ dst,
              \)
      endif
      let prv = cur
      let cur = fern#internal#path#dirname(cur)
    endwhile
  endfor
  return map(steps, { -> v:val[0:1] })
endfunction

function! s:dict(entries) abort
  let m = {}
  call map(copy(a:entries), { _, v -> extend(m, { v[0]: v[1] }) })
  return m
endfunction

function! s:compare(a, b) abort
  let a = len(split(a:a[1], '[/\\]'))
  let b = len(split(a:b[1], '[/\\]'))
  return a is# b ? 0 : a > b ? 1 : -1
endfunction

function! s:find_duplication(list) abort
  let seen = {}
  for item in a:list
    if has_key(seen, item)
      return item
    endif
    let seen[item] = 1
  endfor
endfunction

function! s:replace(text, applied) abort
  let text = a:text
  for item in a:applied
    let [src, dst] = item[0:1]
    let text = substitute(text, escape(src, s:ESCAPE_PATTERN), dst, '')
  endfor
  return text
endfunction

function! s:replace_backword(text, applied) abort
  let text = a:text
  for item in reverse(copy(a:applied))
    let [src, dst] = item[0:1]
    let text = substitute(text, escape(dst, s:ESCAPE_PATTERN), src, '')
  endfor
  return text
endfunction
