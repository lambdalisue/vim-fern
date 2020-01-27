function! fern#internal#action#init() abort
  nnoremap <buffer><silent> <Plug>(fern-choice) :<C-u>call <SID>map_choice()<CR>
  nnoremap <buffer><silent> <Plug>(fern-repeat) :<C-u>call <SID>map_repeat()<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-help)   :<C-u>call <SID>map_help()<CR>

  if !g:fern_disable_default_mappings
    nmap <buffer> a <Plug>(fern-choice)
    nmap <buffer> . <Plug>(fern-repeat)
    nmap <buffer> ? <Plug>(fern-action-help)
  endif

  let prefix = 'fern-action-'
  let b:fern_action = {
        \ 'actions': s:build_actions(prefix),
        \ 'previous': '',
        \}
endfunction

function! fern#internal#action#call(name) abort
  if !exists('b:fern_action')
    throw 'the buffer has not been initialized for actions'
  endif
  let expr = get(b:fern_action.actions, a:name, v:null)
  if expr is# v:null
    throw printf('no action %s found in the buffer', a:name)
  endif
  let b:fern_action.previous = a:name
  execute printf("normal \<Plug>(%s)", expr)
endfunction

function! s:map_choice() abort
  if !exists('b:fern_action')
    throw 'the buffer has not been initialized for actions'
  endif
  call inputsave()
  try
    let n = get(function('s:complete_choice'), 'name')
    let r = input("action: ", '', printf('customlist,%s', n))
    let names = sort(keys(b:fern_action.actions))
    let name = get(filter(names, { -> v:val =~# '^' . r }), 0)
    if empty(name)
      return
    endif
    call fern#internal#action#call(name)
  finally
    call inputrestore()
  endtry
endfunction

function! s:map_repeat() abort
  if !exists('b:fern_action')
    throw 'the buffer has not been initialized for actions'
  endif
  if empty(b:fern_action.previous)
    return
  endif
  call fern#internal#action#call(b:fern_action.previous)
endfunction

function! s:map_help() abort
  let Sort = { a, b -> s:compare(a[1], b[1]) }
  let rs = split(execute('nmap'), '\n')
  call map(rs, { _, v -> v[3:] })
  call map(rs, { _, v -> matchlist(v, '^\([^ ]\+\)\s*\*\?@\?\(.*\)$')[1:2] })

  let rs1 = map(copy(rs), { _, v -> v + [matchstr(v[1], '^<Plug>(fern-action-\zs.*\ze)$')] })
  call filter(rs1, { _, v -> !empty(v[2]) })
  call filter(rs1, { _, v -> v[0] !~# '^<Plug>' })
  call map(rs1, { _, v -> [v[0], v[2], v[1]] })

  let rs2 = map(copy(rs), { _, v -> v + [matchstr(v[0], '^<Plug>(fern-action-\zs.*\ze)$')] })
  call filter(rs2, { _, v -> !empty(v[2]) })
  call map(rs2, { _, v -> ['', v[2], v[0]] })

  let rs = uniq(sort(rs1 + rs2, Sort), Sort)
  let len0 = max(map(copy(rs), { -> len(v:val[0]) }))
  let len1 = max(map(copy(rs), { -> len(v:val[1]) }))
  let len2 = max(map(copy(rs), { -> len(v:val[2]) }))
  call map(rs, { _, v -> [
       \   printf(printf("%%-%dS", len0), v[0]),
       \   printf(printf("%%-%dS", len1), v[1]),
       \   printf(printf("%%-%dS", len2), v[2]),
       \ ]
       \})
  call map(rs, { -> join(v:val, "  ") })
  execute printf('botright %dnew', len(rs) + 1)
  call setline(1, rs)
  setlocal buftype=nofile bufhidden=wipe
  setlocal noswapfile nobuflisted
  setlocal nomodifiable nomodified
  setlocal nolist signcolumn=no
  setlocal nonumber norelativenumber
  setlocal cursorline
  nnoremap <buffer><silent> q :<C-u>q<CR>
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
  if !exists('b:fern_action')
    return []
  endif
  let names = sort(keys(b:fern_action.actions))
  if empty(a:arglead)
    call filter(names, { -> v:val !~# ':' })
  endif
  return filter(names, { -> v:val =~# '^' . a:arglead })
endfunction

function! s:compare(i1, i2) abort
  return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunction
