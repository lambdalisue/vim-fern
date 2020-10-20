let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#terminal#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:select)   :<C-u>call <SID>call('terminal', 'select')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:split)    :<C-u>call <SID>call('terminal', 'split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:vsplit)   :<C-u>call <SID>call('terminal', 'vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:tabedit)  :<C-u>call <SID>call('terminal', 'tabedit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:above)    :<C-u>call <SID>call('terminal', 'leftabove split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:left)     :<C-u>call <SID>call('terminal', 'leftabove vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:below)    :<C-u>call <SID>call('terminal', 'rightbelow split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:right)    :<C-u>call <SID>call('terminal', 'rightbelow vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:top)      :<C-u>call <SID>call('terminal', 'topleft split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:leftest)  :<C-u>call <SID>call('terminal', 'topleft vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:bottom)   :<C-u>call <SID>call('terminal', 'botright split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:rightest) :<C-u>call <SID>call('terminal', 'botright vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:edit-or-error)   :<C-u>call <SID>call('terminal', 'edit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:edit-or-split)   :<C-u>call <SID>call('terminal', 'edit/split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:edit-or-vsplit)  :<C-u>call <SID>call('terminal', 'edit/vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-terminal:edit-or-tabedit) :<C-u>call <SID>call('terminal', 'edit/tabedit')<CR>

  " Smart map
  nmap <buffer><silent><expr>
        \ <Plug>(fern-action-terminal:side)
        \ fern#smart#drawer(
        \   "\<Plug>(fern-action-terminal:left)",
        \   "\<Plug>(fern-action-terminal:right)",
        \ )

  " Alias map
  nmap <buffer><silent> <Plug>(fern-action-terminal:edit) <Plug>(fern-action-terminal:edit-or-error)
  nmap <buffer><silent> <Plug>(fern-action-terminal) <Plug>(fern-action-terminal:edit)
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_terminal(helper, opener) abort
  let STATUS_NONE = a:helper.STATUS_NONE
  let nodes = a:helper.sync.get_selected_nodes()
  let nodes = map(copy(nodes), { _, n -> n.status is# STATUS_NONE ? n.__owner : n })
  let winid = win_getid()
  try
    for node in nodes
      call win_gotoid(winid)
      try
        call fern#internal#buffer#open('', {
              \ 'opener': a:opener,
              \ 'locator': a:helper.sync.is_drawer(),
              \})
      catch /^Vim\%((\a\+)\)\=:E32:/
      endtry
      enew | call s:term(node._path)
    endfor
    return a:helper.async.update_marks([])
        \.then({ -> a:helper.async.remark() })
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

if exists('*termopen')
  function! s:term(cwd) abort
    call termopen(&shell, { 'cwd': a:cwd })
  endfunction
elseif exists('*term_start')
  function! s:term(cwd) abort
    call term_start(&shell, { 'cwd': a:cwd, 'curwin': 1 })
  endfunction
else
  function! s:term(cwd) abort
    throw 'neither termopen nor term_start exist'
  endfunction
endif
