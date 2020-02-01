let s:conditions = [
      \ { wi -> !wi.loclist },
      \ { wi -> !wi.quickfix },
      \ { wi -> !getwinvar(wi.winid, '&winfixwidth', 0) },
      \ { wi -> !getwinvar(wi.winid, '&winfixheight', 0) },
      \ { wi -> !getbufvar(wi.bufnr, '&previewwindow', 0) },
      \]
function! fern#internal#locator#score(winnr) abort

  let winid = win_getid(a:winnr)
  let wininfo = getwininfo(winid)
  if empty(wininfo)
    return 0
  endif
  let wi = wininfo[0]
  let score = 1
  for Condition in s:conditions
    let score += Condition(wi)
  endfor
  return score
endfunction

function! fern#internal#locator#find(origin) abort
  let nwinnr = winnr('$')
  if nwinnr == 1
    return 1
  endif
  let origin = a:origin == 0 ? winnr() : a:origin
  let former = range(origin, winnr('$'))
  let latter = reverse(range(1, origin - 1))
  let threshold = g:fern#internal#locator#threshold
  while threshold > 0
    for winnr in (former + latter)
      if fern#internal#locator#score(winnr) >= threshold
        return winnr
      endif
    endfor
    let threshold -= 1
  endwhile
  return 0
endfunction

function! fern#internal#locator#focus(origin) abort
  let winnr = fern#internal#locator#find(a:origin)
  if winnr == 0 || winnr == winnr()
    return 1
  endif
  call win_gotoid(win_getid(winnr))
endfunction

let g:fern#internal#locator#threshold = len(s:conditions) + 1
lockvar g:fern#internal#locator#threshold
