function! trea#comparator#lexical#compare(n1, n2) abort
  let k1 = a:n1.__key
  let k2 = a:n2.__key
  let l1 = len(k1)
  let l2 = len(k2)
  for index in range(0, min([l1, l2]) - 1)
    if k1[index] ==# k2[index]
      continue
    endif
    return k1[index] > k2[index] ? 1 : -1
  endfor
  " Shorter first
  let r = s:compare(l1, l2)
  return r is# 0 ? s:compare(!a:n1.status, !a:n2.status) : r
endfunction

function! s:compare(i1, i2) abort
  return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunction
