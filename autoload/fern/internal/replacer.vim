let s:Promise = vital#fern#import('Async.Promise')
let s:ESCAPE_PATTERN = '^$~.*[]\'

function! fern#internal#replacer#start(factory, ...) abort
  let options = extend({
        \ 'bufname': printf('fern-replacer:%s', sha256(localtime()))[:7],
        \ 'opener': 'vsplit',
        \ 'cursor': [1, 1],
        \ 'is_drawer': v:false,
        \ 'modifiers': [],
        \}, a:0 ? a:1 : {},
        \)
  return s:Promise.new(funcref('s:executor', [a:factory, options]))
endfunction

function! s:executor(factory, options, resolve, reject) abort
  call fern#internal#buffer#open(a:options.bufname, {
        \ 'opener': a:options.opener,
        \ 'locator': a:options.is_drawer,
        \ 'keepalt': !a:options.is_drawer && g:fern#keepalt_on_edit,
        \ 'keepjumps': !a:options.is_drawer && g:fern#keepjumps_on_edit,
        \})

  setlocal buftype=acwrite bufhidden=wipe
  setlocal noswapfile nobuflisted
  setlocal nowrap
  setlocal filetype=fern-replacer

  let b:fern_replacer_resolve = a:resolve
  let b:fern_replacer_factory = a:factory
  let b:fern_replacer_candidates = a:factory()
  let b:fern_replacer_modifiers = a:options.modifiers

  augroup fern_replacer_internal
    autocmd! * <buffer>
    autocmd BufReadCmd  <buffer> call s:BufReadCmd()
    autocmd BufWriteCmd <buffer> call s:BufWriteCmd()
    autocmd ColorScheme <buffer> call s:highlight()
  augroup END

  call s:highlight()
  call s:syntax()

  " Do NOT allow to add/remove lines
  nnoremap <buffer><silent> <Plug>(fern-replacer-p) :<C-u>call <SID>map_paste(0)<CR>
  nnoremap <buffer><silent> <Plug>(fern-replacer-P) :<C-u>call <SID>map_paste(-1)<CR>
  nnoremap <buffer><silent> <Plug>(fern-replacer-warn) :<C-u>call <SID>map_warn()<CR>
  inoremap <buffer><silent><expr> <Plug>(fern-replacer-warn) <SID>map_warn()
  nnoremap <buffer><silent> dd 0D
  nmap <buffer> p <Plug>(fern-replacer-p)
  nmap <buffer> P <Plug>(fern-replacer-P)
  nmap <buffer> o <Plug>(fern-replacer-warn)
  nmap <buffer> O <Plug>(fern-replacer-warn)
  imap <buffer> <C-m> <Plug>(fern-replacer-warn)
  imap <buffer> <Return> <Plug>(fern-replacer-warn)
  edit
  call cursor(a:options.cursor)
endfunction

function! s:map_warn() abort
  echohl WarningMsg
  echo 'Newline is prohibited in the replacer buffer'
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
  let b:fern_replacer_candidates = b:fern_replacer_factory()
  call s:syntax()
  call setline(1, b:fern_replacer_candidates)
endfunction

function! s:BufWriteCmd() abort
  if !&modifiable
    return
  endif
  let candidates = b:fern_replacer_candidates
  let result = []
  for index in range(len(candidates))
    let src = candidates[index]
    let dst = getline(index + 1)
    if empty(dst) || dst ==# src
      continue
    endif
    call add(result, [src, dst])
  endfor
  try
    for Modifier in b:fern_replacer_modifiers
      let result = Modifier(result)
    endfor
    let l:Resolve = b:fern_replacer_resolve
    set nomodified
    close
    call Resolve(result)
  catch
    echohl ErrorMsg
    echo '[fern] Please fix the following error first to continue or cancel with ":q!"'
    echo printf('[fern] %s', substitute(v:exception, '^Vim(.*):', '', ''))
    echohl None
  endtry
endfunction

function! s:syntax() abort
  syntax clear
  syntax match FernReplacerModified '^.\+$'

  for index in range(len(b:fern_replacer_candidates))
    let candidate = b:fern_replacer_candidates[index]
    execute printf(
          \ 'syntax match FernReplacerOriginal ''^\%%%dl%s$''',
          \ index + 1,
          \ escape(candidate, s:ESCAPE_PATTERN),
          \)
  endfor
endfunction

function! s:highlight() abort
  highlight default link FernReplacerOriginal Normal
  highlight default link FernReplacerModified Special
endfunction
