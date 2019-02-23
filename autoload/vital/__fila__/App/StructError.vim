function! s:new(exception, ...) abort
  let context = { 'exception': a:exception }
  call map(copy(a:000), { -> extend(context, v:val) })
  return json_encode(context)
endfunction

function! s:parse(...) abort
  let context = {
        \ 'exception': a:0 > 0 ? a:1 : v:exception,
        \ 'throwpoint': a:0 > 1 ? a:2 : v:throwpoint,
        \}
  try
    " NOTE:
    " exception/throwpoint SHOULD be overwritten by decoded context to know
    " the original exception/throwpoint
    return extend(context, json_decode(context.exception))
  catch
  endtry
  return context
endfunction

function! s:cause(...) abort
  let context = call('s:parse', a:000)
  try
    while 1
      call extend(context, json_decode(context.exception))
    endwhile
  catch
    return context
  endtry
endfunction
