function! fila#error#new(...) abort
  let exception = a:0 > 0 ? a:1 : v:exception
  let throwpoint = a:0 > 1 ? a:2 : v:throwpoint
  if type(exception) is# v:t_dict && has_key(exception, 'exception')
    return {
          \ 'exception': exception.exception,
          \ 'throwpoint': get(exception, 'throwpoint', ''),
          \}
  elseif type(exception) is# v:t_string
    return {
          \ 'exception': exception,
          \ 'throwpoint': throwpoint,
          \}
  else
    return {
          \ 'exception': string(exception),
          \ 'throwpoint': throwpoint,
          \}
  endif
endfunction

function! fila#error#handle(error) abort
  let error = fila#error#new(a:error)
  if error.exception =~# '^Cancelled'
    echohl Title
    echo 'Cancelled'
    echohl None
  else
    let ms = split(error.exception, "\n")
    if g:fila#debug
      let ms += split(error.throwpoint, "\n")
    endif
    echohl WarningMsg
    for m in ms
      echomsg m
    endfor
    echohl None
  endif
endfunction
