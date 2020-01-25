let s:Promise = vital#trea#import('Async.Promise')

function! trea#internal#renamer#rename(factory, ...) abort
  let options = extend({
        \ 'bufname': printf('trea-renamer:%s', sha256(localtime()))[:7],
        \ 'opener': 'split',
        \}, a:0 ? a:1 : {},
        \)
  return s:Promise.new(funcref('s:executor', [a:factory, options]))
endfunction

function! s:executor(factory, options, resolve, reject) abort
  call trea#lib#buffer#open(a:options.bufname, {
        \ 'opener': a:options.opener,
        \ 'mods': 'noautocmd',
        \})

  setlocal buftype=acwrite bufhidden=wipe
  setlocal noswapfile nobuflisted
  setlocal nowrap
  setlocal filetype=trea-renamer

  let b:trea_renamer_resolve = a:resolve
  let b:trea_renamer_factory = a:factory
  let b:trea_renamer_candidates = a:factory()

  augroup trea_renamer_internal
    autocmd! * <buffer>
    autocmd BufReadCmd  <buffer> call s:BufReadCmd()
    autocmd BufWriteCmd <buffer> call s:BufWriteCmd()
    autocmd ColorScheme <buffer> call s:highlight()
  augroup END

  call s:highlight()
  call s:syntax()

  " Do NOT allow to add/remove lines
  nnoremap <buffer><silent> <Plug>(trea-renamer-p) :<C-u>call <SID>map_paste(0)<CR>
  nnoremap <buffer><silent> <Plug>(trea-renamer-P) :<C-u>call <SID>map_paste(-1)<CR>
  nnoremap <buffer><silent> <Plug>(trea-renamer-warn) :<C-u>call <SID>map_warn()<CR>
  inoremap <buffer><silent><expr> <Plug>(trea-renamer-warn) <SID>map_warn()
  nnoremap <buffer><silent> dd 0D
  nmap <buffer> p <Plug>(trea-renamer-p)
  nmap <buffer> P <Plug>(trea-renamer-P)
  nmap <buffer> o <Plug>(trea-renamer-warn)
  nmap <buffer> O <Plug>(trea-renamer-warn)
  imap <buffer> <C-m> <Plug>(trea-renamer-warn)
  imap <buffer> <Return> <Plug>(trea-renamer-warn)
  edit
endfunction

function! s:map_warn() abort
  echohl WarningMsg
  echo "Newline is prohibited in the renamer buffer"
  echohl None
  return ''
endfunction

function! s:map_paste(offset) abort
  let line = getline('.')
  let v = substitute(getreg(), '\r\?\n', '', 'g')
  let c = col('.') + a:offset - 1
  let l = line[:c]
  let r = line[c + 1:]
  call setline(line('.'), l . v . r)
endfunction

function! s:BufReadCmd() abort
  let b:trea_renamer_candidates = b:trea_renamer_factory()
  call s:syntax()
  call setline(1, b:trea_renamer_candidates)
endfunction

function! s:BufWriteCmd() abort
  if !&modifiable
    return
  endif
  let candidates = b:trea_renamer_candidates
  let results = []
  for index in range(len(candidates))
    let src = candidates[index]
    let dst = getline(index + 1)
    if empty(dst) || dst ==# src
      continue
    endif
    call add(results, [src, dst])
  endfor
  call b:trea_renamer_resolve(results)
  set nomodifiable
  set nomodified
  close
endfunction

function! s:syntax() abort
  let pattern = '^$~.*[]\'

  syntax clear
  syntax match TreaRenamed '^.\+$'

  for index in range(len(b:trea_renamer_candidates))
    let candidate = b:trea_renamer_candidates[index]
    execute printf(
          \ 'syntax match TreaOrigin ''^\%%%dl%s$''',
          \ index + 1,
          \ escape(candidate, pattern),
          \)
  endfor
endfunction

function! s:highlight() abort
  highlight default link TreaOrigin Normal
  highlight default link TreaRenamed Special
endfunction
