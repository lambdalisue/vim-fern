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

  " Alias map
  nmap <buffer><silent> <Plug>(fern-action-terminal:edit) <Plug>(fern-action-terminal:edit-or-error)
  nmap <buffer><silent> <Plug>(fern-action-terminal) <Plug>(fern-action-terminal:edit)
endfunction

function! s:call(name, ...) abort
  return call(
        \ "fern#internal#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_terminal(helper, opener) abort
  let node = a:helper.get_cursor_node()
  let node = node.status is# a:helper.STATUS_NONE ? node.__owner : node
  if exists('*termopen')
    let Term = function("termopen", [&shell, { 'cwd': node._path }])
  elseif exists('*term_start')
    let Term = function("term_start", [&shell, { 'cwd': node._path, 'curwin': 1 }])
  else
    return s:Promise.reject("neither termopen nor term_start exist")
  endif
  call fern#lib#buffer#open("", {
        \ 'opener': a:opener,
        \ 'locator': a:helper.is_drawer(),
        \})
  call Term()
  return s:Promise.resolve()
endfunction
