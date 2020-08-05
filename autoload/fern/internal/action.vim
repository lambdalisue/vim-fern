function! fern#internal#action#init() abort
  nnoremap <buffer><silent> <Plug>(fern-action-choice) :<C-u>call <SID>map_choice()<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-repeat) :<C-u>call <SID>map_repeat()<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-help) :<C-u>call <SID>map_help(0)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-help:all) :<C-u>call <SID>map_help(1)<CR>

  " NOTE:
  " Action is core feature of fern so do NOT refer g:fern#disable_default_mappings
  if !hasmapto('<Plug>(fern-action-choice)', 'n')
    nmap <buffer> a <Plug>(fern-action-choice)
  endif
  if !hasmapto('<Plug>(fern-action-repeat)', 'n')
    nmap <buffer> . <Plug>(fern-action-repeat)
  endif
  if !hasmapto('<Plug>(fern-action-help)', 'n')
    nmap <buffer> ? <Plug>(fern-action-help)
  endif

  let prefix = 'fern-action-'
  let b:fern_action = {
        \ 'actions': s:build_actions(prefix),
        \ 'previous': '',
        \}
endfunction

function! fern#internal#action#call(name, ...) abort
  let options = extend({
        \ 'capture': 0,
        \ 'verbose': 0,
        \}, a:0 ? a:1 : {},
        \)
  if !exists('b:fern_action')
    throw 'the buffer has not been initialized for actions'
  endif
  if index(b:fern_action.actions, a:name) is# -1
    throw printf('no action %s found in the buffer', a:name)
  endif
  let b:fern_action.previous = a:name
  let Fn = funcref('s:call', [a:name])
  if options.verbose
    let Fn = funcref('s:verbose', [Fn])
  endif
  if options.capture
    let Fn = funcref('s:capture', [Fn])
  endif
  call Fn()
endfunction

function! s:map_choice() abort
  if !exists('b:fern_action')
    throw 'the buffer has not been initialized for actions'
  endif
  call inputsave()
  try
    let fn = get(function('s:complete_choice'), 'name')
    let expr = input('action: ', '', printf('customlist,%s', fn))
  finally
    call inputrestore()
  endtry
  let r = s:parse_expr(expr)
  let ns = copy(b:fern_action.actions)
  let r.name = get(filter(ns, { -> v:val =~# '^' . r.name }), 0)
  if empty(r.name)
    return
  endif
  call fern#internal#action#call(r.name, {
       \ 'capture': r.capture,
       \ 'verbose': r.verbose,
       \})
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

function! s:map_help(all) abort
  let Sort = { a, b -> s:compare(a[1], b[1]) }
  let rs = split(execute('nmap'), '\n')
  call map(rs, { _, v -> v[3:] })
  call map(rs, { _, v -> matchlist(v, '^\([^ ]\+\)\s*\*\?@\?\(.*\)$')[1:2] })

  " To action mapping
  let rs1 = map(copy(rs), { _, v -> v + [matchstr(v[1], '^<Plug>(fern-action-\zs.*\ze)$')] })
  call filter(rs1, { _, v -> !empty(v[2]) })
  call filter(rs1, { _, v -> v[0] !~# '^<Plug>' || v[0] =~# '^<Plug>(fern-action-' })
  call map(rs1, { _, v -> [v[0], v[2], v[1]] })

  " From action mapping
  let rs2 = map(copy(rs), { _, v -> v + [matchstr(v[0], '^<Plug>(fern-action-\zs.*\ze)$')] })
  call filter(rs2, { _, v -> !empty(v[2]) })
  call map(rs2, { _, v -> ['', v[2], v[0]] })

  let rs = uniq(sort(rs1 + rs2, Sort), Sort)
  if !a:all
    call filter(rs, { -> v:val[1] !~# ':' || !empty(v:val[0]) })
  endif
  let len0 = max(map(copy(rs), { -> len(v:val[0]) }))
  let len1 = max(map(copy(rs), { -> len(v:val[1]) }))
  let len2 = max(map(copy(rs), { -> len(v:val[2]) }))
  call map(rs, { _, v -> [
       \   printf(printf('%%-%dS', len0), v[0]),
       \   printf(printf('%%-%dS', len1), v[1]),
       \   printf(printf('%%-%dS', len2), v[2]),
       \ ]
       \})

  call map(rs, { -> join(v:val, '  ') })
  if !a:all
    echohl Title
    echo "NOTE: Some actions are concealed. Use 'help:all' action to see all actions."
    echohl None
  endif
  echo join(rs, "\n")
endfunction

function! s:parse_expr(expr) abort
  if empty(a:expr)
    return {'name' : '', 'capture': 0, 'verbose': 0}
  endif
  let terms = split(a:expr)
  let name = remove(terms, -1)
  let Has = { ns, n -> len(filter(copy(ns), { -> v:val ==# n })) }
  return {
        \ 'name': name,
        \ 'capture': Has(terms, 'capture'),
        \ 'verbose': Has(terms, 'verbose'),
        \}
endfunction

function! s:build_actions(prefix) abort
  let n = len(a:prefix)
  let ms = split(execute(printf('nmap <Plug>(%s', a:prefix)), '\n')
  call map(ms, { _, v -> split(v)[1] })
  call map(ms, { _, v -> matchstr(v, '^<Plug>(\zs.*\ze)$') })
  call filter(ms, { _, v -> !empty(v) })
  call map(ms, { _, expr -> expr[n :] })
  return sort(ms)
endfunction

function! s:complete_choice(arglead, cmdline, cursorpos) abort
  if !exists('b:fern_action')
    return []
  endif
  let names = copy(b:fern_action.actions)
  let names += ['capture', 'verbose']
  if empty(a:arglead)
    call filter(names, { -> v:val !~# ':' })
  endif
  return filter(names, { -> v:val =~# '^' . a:arglead })
endfunction

function! s:compare(i1, i2) abort
  return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunction

function! s:call(name) abort
  execute printf("normal \<Plug>(fern-action-%s)", a:name)
endfunction

function! s:capture(fn) abort
  let output = execute('call a:fn()')
  let rs = split(output, '\r\?\n')
  execute printf('botright %dnew', len(rs))
  call setline(1, rs)
  setlocal buftype=nofile bufhidden=wipe
  setlocal noswapfile nobuflisted
  setlocal nomodifiable nomodified
  setlocal nolist signcolumn=no
  setlocal nonumber norelativenumber
  setlocal cursorline
  nnoremap <buffer><silent> q :<C-u>q<CR>
endfunction

function! s:verbose(fn) abort
  let verbose_saved = &verbose
  try
    set verbose
    call a:fn()
  finally
    let &verbose = verbose_saved
  endtry
endfunction
