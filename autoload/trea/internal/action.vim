let s:Config = vital#trea#import('Config')

function! trea#internal#action#init() abort
  let prefix = 'trea-action-'
  let b:trea_action = {
        \ 'actions': s:build_actions(prefix),
        \ 'previous': '',
        \}
  nnoremap <buffer><silent> <Plug>(trea-action-choice) :<C-u>call <SID>map_choice()<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-repeat) :<C-u>call <SID>map_repeat()<CR>

  if !g:trea#internal#action#disable_default_mappings
    nmap <buffer> a <Plug>(trea-action-choice)
    nmap <buffer> . <Plug>(trea-action-repeat)
  endif
endfunction

function! trea#internal#action#call(name) abort
  if !exists('b:trea_action')
    throw 'the buffer has not been initialized for actions'
  endif
  let expr = get(b:trea_action.actions, a:name, v:null)
  if expr is# v:null
    throw printf('no action %s found in the buffer', a:name)
  endif
  execute printf("normal \<Plug>(%s)", expr)
  let b:trea_action.previous = a:name
endfunction

function! s:map_choice() abort
  if !exists('b:trea_action')
    throw 'the buffer has not been initialized for actions'
  endif
  call inputsave()
  try
    let n = get(function('s:complete_choice'), 'name')
    let r = input("action: ", '', printf('customlist,%s', n))
    let names = sort(keys(b:trea_action.actions))
    let name = get(filter(names, { -> v:val =~# '^' . r }), 0)
    if empty(name)
      return
    endif
    call trea#internal#action#call(name)
  finally
    call inputrestore()
  endtry
endfunction

function! s:map_repeat() abort
  if !exists('b:trea_action')
    throw 'the buffer has not been initialized for actions'
  endif
  if empty(b:trea_action.previous)
    return
  endif
  call trea#internal#action#call(b:trea_action.previous)
endfunction

function! s:build_actions(prefix) abort
  let ms = split(execute(printf('nmap <Plug>(%s', a:prefix)), '\n')
  call map(ms, { _, v -> split(v)[1] })
  call map(ms, { _, v -> matchstr(v, '^<Plug>(\zs.*\ze)$') })
  call filter(ms, { _, v -> !empty(v) })
  let actions = {}
  for expr in ms
    let name = expr[len(a:prefix):]
    let actions[name] = expr
  endfor
  return actions
endfunction

function! s:complete_choice(arglead, cmdline, cursorpos) abort
  if !exists('b:trea_action')
    return []
  endif
  let names = sort(keys(b:trea_action.actions))
  if empty(a:arglead)
    call filter(names, { -> v:val !~# ':' })
  endif
  return filter(names, { -> v:val =~# '^' . a:arglead })
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'disable_default_mappings': 0,
      \})
