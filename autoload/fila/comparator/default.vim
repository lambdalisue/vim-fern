let s:Comp = { i1, i2 -> i1 == i2 ? 0 : i1 > i2 ? 1 : -1 }

function! fila#comparator#default#new() abort
  return { 'compare': funcref('s:compare') }
endfunction

function! s:compare(n1, n2) abort
  let k1 = a:n1.key
  let k2 = a:n2.key
  let t1 = fila#node#is_branch(a:n1)
  let t2 = fila#node#is_branch(a:n2)
  let l1 = len(k1)
  let l2 = len(k2)
  for index in range(0, min([l1, l2]) - 1)
    if k1[index] ==# k2[index]
      continue
    endif
    let _t1 = index + 1 is# l1 ? t1 : 1
    let _t2 = index + 1 is# l2 ? t2 : 1
    if _t1 is# _t2
      " Lexical compare
      return k1[index] > k2[index] ? 1 : -1
    else
      " Directory first
      return _t1 ? -1 : 1
    endif
  endfor
  " Shorter first
  let r = s:Comp(l1, l2)
  return r is# 0 ? s:Comp(!a:n1.status, !a:n2.status) : r
endfunction
