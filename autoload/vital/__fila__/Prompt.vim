let s:ESCAPE_MARKER = sha256(expand('<sfile>'))

function! s:input(prompt, ...) abort
  let text = a:0 > 0 ? a:1 : ''
  let comp = a:0 > 1
        \ ? type(a:2) is# v:t_func ? 'customlist,' . get(a:2, 'name') : a:2
        \ : v:null
  let default = a:0 > 2 ? a:3 : v:null
  let args = comp is# v:null ? [text] : [text, comp]
  try
    execute printf(
          \ 'silent cnoremap <buffer><silent> <Esc> <C-u>%s<CR>',
          \ s:ESCAPE_MARKER,
          \)
    let result = call('input', [a:prompt] + args)
    return result ==# s:ESCAPE_MARKER ? default : result
  finally
    silent cunmap <buffer> <Esc>
  endtry
endfunction

function! s:ask(...) abort
  call inputsave()
  try
    echohl Question
    return call('s:input', a:000)
  finally
    echohl None
    call inputrestore()
    redraw | echo
  endtry
endfunction

function! s:confirm(prompt, ...) abort
  let default = a:0 ? (a:1 ? 'yes' : 'no') : v:null
  call inputsave()
  echohl Question
  try
    let r = ''
    while r !~? '^\%(y\%[es]\|n\%[o]\)$'
      let r = s:input(a:prompt, '', funcref('s:_confirm_complete'))
      if r is# v:null
        return v:null
      endif
      let r = r ==# '' ? default : r
    endwhile
    return r =~? 'y\%[es]'
  finally
    echohl None
    call inputrestore()
    redraw | echo
  endtry
endfunction

function! s:select(prompt, ...) abort
  let max = a:0 > 0 ? a:1 : 1
  let min = a:0 > 1 ? a:2 : 1
  let pat = a:0 > 2 ? a:3 : '\d'
  let buffer = ''
  call inputsave()
  echohl Question
  try
    while len(buffer) < max
      redraw | echo
      echo a:prompt . buffer
      let c = nr2char(getchar())
      if c ==# "\<Return>" && len(buffer) >= min
        return buffer
      elseif c ==# "\<Esc>"
        return v:null
      elseif c =~# pat
        let buffer .= c
      endif
    endwhile
    return buffer
  finally
    echohl None
    call inputrestore()
  endtry
endfunction

function! s:_confirm_complete(arglead, cmdline, cursorpos) abort
  return filter(['yes', 'no'], { -> v:val =~? '^' . a:arglead })
endfunction
