let s:Config = vital#fern#import('Config')
let s:Promise = vital#fern#import('Async.Promise')
let s:Process = vital#fern#import('Async.Promise.Process')

function! fern#scheme#file#mapping#grep#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-grep)  :<C-u>call <SID>call('grep')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-grep=) :<C-u>call <SID>call_without_guard('grep')<CR>
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:call_without_guard(name, ...) abort
  return call(
        \ 'fern#mapping#call_without_guard',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_grep(helper) abort
  let pattern = input('Grep: ', '')
  if empty(pattern)
    return s:Promise.reject('Cancelled')
  endif
  let node = a:helper.sync.get_cursor_node()
  let node = node.status isnot# a:helper.STATUS_EXPANDED ? node.__owner : node
  let args = s:grepargs([pattern, fern#internal#filepath#from_slash(node._path)])
  let efm = g:fern#scheme#file#mapping#grep#grepformat
  let title = printf('[fern] %s', join(map(copy(args), { _, v -> v =~# '\s' ? printf('"%s"', v) : v }), ' '))
  let token = a:helper.fern.source.token
  return s:Process.start(args, { 'token': token })
        \.then({ v -> v.stdout })
        \.then({ v -> setqflist([], 'a', { 'efm': efm, 'lines': v, 'title': title }) })
        \.then({ -> execute('copen') })
endfunction

function! s:grepargs(args) abort
  let args = fern#internal#args#split(g:fern#scheme#file#mapping#grep#grepprg)
  let args = map(args, { _, v -> v =~# '^[%#]\%(:.*\)\?$' ? fern#util#expand(v) : v })
  let index = index(args, '$*')
  return index is# -1
        \ ? args + a:args
        \ : args[:index - 1] + a:args + args[index + 1:]
endfunction

function! s:default_grepprg() abort
  if &grepprg =~# '^\%(grep -n \|grep -n $\* /dev/null\|internal\)$'
    return has('unix') ? 'grep -rn $* /dev/null' : 'gren -rn'
  endif
  return &grepprg
endfunction


call s:Config.config(expand('<sfile>:p'), {
      \ 'grepprg': s:default_grepprg(),
      \ 'grepformat': &grepformat,
      \})
