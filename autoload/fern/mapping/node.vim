let s:Promise = vital#fern#import('Async.Promise')
let s:Prompt = vital#fern#import('Prompt')

function! fern#mapping#node#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-debug)         :<C-u>call <SID>call('debug')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-reload)        :<C-u>call <SID>call('reload')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-expand)        :<C-u>call <SID>call('expand')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-collapse)      :<C-u>call <SID>call('collapse')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-reveal)        :<C-u>call <SID>call('reveal')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-enter)         :<C-u>call <SID>call('enter')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-leave)         :<C-u>call <SID>call('leave')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-open:select)   :<C-u>call <SID>call('open', 'select')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:edit)     :<C-u>call <SID>call('open', 'edit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:split)    :<C-u>call <SID>call('open', 'split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:vsplit)   :<C-u>call <SID>call('open', 'vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:tabedit)  :<C-u>call <SID>call('open', 'tabedit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:above)    :<C-u>call <SID>call('open', 'leftabove split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:left)     :<C-u>call <SID>call('open', 'leftabove vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:below)    :<C-u>call <SID>call('open', 'rightbelow split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:right)    :<C-u>call <SID>call('open', 'rightbelow vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:top)      :<C-u>call <SID>call('open', 'topleft split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:leftest)  :<C-u>call <SID>call('open', 'topleft vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:bottom)   :<C-u>call <SID>call('open', 'botright split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:rightest) :<C-u>call <SID>call('open', 'botright vsplit')<CR>

  " Smart map
  nmap <buffer><silent><expr>
        \ <Plug>(fern-action-open:side)
        \ fern#smart#drawer(
        \   "\<Plug>(fern-action-open:left)",
        \   "\<Plug>(fern-action-open:right)",
        \ )
  nmap <buffer><silent><expr>
        \ <Plug>(fern-open-or-enter)
        \ fern#smart#leaf(
        \   "\<Plug>(fern-action-open)",
        \   "\<Plug>(fern-action-enter)",
        \ )
  nmap <buffer><silent><expr>
        \ <Plug>(fern-open-or-expand)
        \ fern#smart#leaf(
        \   "\<Plug>(fern-action-open)",
        \   "\<Plug>(fern-action-expand)",
        \ )

  " Alias map
  nmap <buffer><silent> <Plug>(fern-action-open) <Plug>(fern-action-open:edit)

  if !a:disable_default_mappings
    nmap <buffer><nowait> <F5> <Plug>(fern-action-reload)
    nmap <buffer><nowait> <Return> <Plug>(fern-open-or-enter)
    nmap <buffer><nowait> <C-m> <Plug>(fern-open-or-enter)
    nmap <buffer><nowait> <Backspace> <Plug>(fern-action-leave)
    nmap <buffer><nowait> <C-h> <Plug>(fern-action-leave)
    nmap <buffer><nowait> l <Plug>(fern-open-or-expand)
    nmap <buffer><nowait> h <Plug>(fern-action-collapse)
    nmap <buffer><nowait> i <Plug>(fern-action-reveal)
    nmap <buffer><nowait> s <Plug>(fern-action-open:select)
    nmap <buffer><nowait> e <Plug>(fern-action-open)
    nmap <buffer><nowait> E <Plug>(fern-action-open:side)
    nmap <buffer><nowait> t <Plug>(fern-action-open:tabedit)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ "fern#internal#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_debug(helper) abort
  let node = a:helper.get_cursor_node()
  redraw | echo fern#internal#node#debug(node)
endfunction

function! s:map_reload(helper) abort
  let node = a:helper.get_cursor_node()
  if node is# v:null
    return s:Promise.reject("no node found on a cursor line")
  endif
  return a:helper.reload_node(node.__key)
        \.then({ -> a:helper.redraw() })
endfunction

function! s:map_expand(helper) abort
  let node = a:helper.get_cursor_node()
  if node is# v:null
    return s:Promise.reject("no node found on a cursor line")
  endif
  let previous = a:helper.get_cursor_node()
  return a:helper.expand_node(node.__key)
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(
        \   node.__key,
        \   { 'previous': previous, 'offset': 1 },
        \ )
        \})
endfunction

function! s:map_collapse(helper) abort
  let node = a:helper.get_cursor_node()
  if node is# v:null
    return s:Promise.reject("no node found on a cursor line")
  endif
  let previous = a:helper.get_cursor_node()
  return a:helper.collapse_node(node.__key)
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(
        \   node.__key,
        \   { 'previous': previous },
        \ )
        \})
endfunction

function! s:map_reveal(helper) abort
  let node = a:helper.get_cursor_node()
  let path = node is# v:null
        \ ? ''
        \ : join(node.__key, '/') . '/'
  let path = s:Prompt.ask("Reveal: ", path)
  if empty(path)
    return s:Promise.reject("Cancelled")
  endif
  let key = split(path, '/')
  let root = a:helper.get_root_node()
  let previous = a:helper.get_cursor_node()
  return a:helper.reveal_node(key)
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(
        \   key,
        \   { 'previous': previous },
        \ )
        \})
endfunction

function! s:map_enter(helper) abort
  let node = a:helper.get_cursor_node()
  if node is# v:null
    return s:Promise.reject("no node found on a cursor line")
  endif
  return a:helper.enter_tree(node)
endfunction

function! s:map_leave(helper) abort
  return a:helper.leave_tree()
endfunction

function! s:map_open(helper, opener) abort
  let node = a:helper.get_cursor_node()
  if node is# v:null
    return s:Promise.reject("no node found on a cursor line")
  elseif node.bufname is# v:null
    return s:Promise.reject("the node does not have bufname")
  endif
  try
    call fern#lib#buffer#open(expand(node.bufname), {
          \ 'opener': a:opener,
          \ 'locator': a:helper.is_drawer(),
          \})
    return s:Promise.resolve()
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction
