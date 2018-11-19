let s:Comp = { i1, i2 -> i1 == i2 ? 0 : i1 > i2 ? 1 : -1 }

function! fila#comparator#lexical#new() abort
  return { 'compare': funcref('s:compare') }
endfunction

function! s:compare(n1, n2) abort
  let k1 = a:n1.key
  let k2 = a:n2.key
  let l1 = len(k1)
  let l2 = len(k2)
  for index in range(0, min([l1, l2]) - 1)
    if k1[index] ==# k2[index]
      continue
    endif
    return k1[index] > k2[index] ? 1 : -1
  endfor
  " Shorter first
  let r = s:Comp(l1, l2)
  return r is# 0 ? s:Comp(!a:n1.status, !a:n2.status) : r
endfunction
