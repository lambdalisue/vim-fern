let s:Promise = vital#fern#import('Async.Promise')
let s:timer_diffupdate = 0

function! fern#mapping#diff#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-diff:select)   :<C-u>call <SID>call('diff', 'select', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:split)    :<C-u>call <SID>call('diff', 'split', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:vsplit)   :<C-u>call <SID>call('diff', 'vsplit', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:tabedit)  :<C-u>call <SID>call('diff', 'tabedit', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:above)    :<C-u>call <SID>call('diff', 'leftabove split', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:left)     :<C-u>call <SID>call('diff', 'leftabove vsplit', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:below)    :<C-u>call <SID>call('diff', 'rightbelow split', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:right)    :<C-u>call <SID>call('diff', 'rightbelow vsplit', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:top)      :<C-u>call <SID>call('diff', 'topleft split', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:leftest)  :<C-u>call <SID>call('diff', 'topleft vsplit', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:bottom)   :<C-u>call <SID>call('diff', 'botright split', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:rightest) :<C-u>call <SID>call('diff', 'botright vsplit', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:edit-or-error)   :<C-u>call <SID>call('diff', 'edit', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:edit-or-split)   :<C-u>call <SID>call('diff', 'edit/split', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:edit-or-vsplit)  :<C-u>call <SID>call('diff', 'edit/vsplit', v:false)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:edit-or-tabedit) :<C-u>call <SID>call('diff', 'edit/tabedit', v:false)<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-diff:select:vert)   :<C-u>call <SID>call('diff', 'select', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:split:vert)    :<C-u>call <SID>call('diff', 'split', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:vsplit:vert)   :<C-u>call <SID>call('diff', 'vsplit', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:tabedit:vert)  :<C-u>call <SID>call('diff', 'tabedit', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:above:vert)    :<C-u>call <SID>call('diff', 'leftabove split', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:left:vert)     :<C-u>call <SID>call('diff', 'leftabove vsplit', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:below:vert)    :<C-u>call <SID>call('diff', 'rightbelow split', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:right:vert)    :<C-u>call <SID>call('diff', 'rightbelow vsplit', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:top:vert)      :<C-u>call <SID>call('diff', 'topleft split', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:leftest:vert)  :<C-u>call <SID>call('diff', 'topleft vsplit', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:bottom:vert)   :<C-u>call <SID>call('diff', 'botright split', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:rightest:vert) :<C-u>call <SID>call('diff', 'botright vsplit', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:edit-or-error:vert)   :<C-u>call <SID>call('diff', 'edit', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:edit-or-split:vert)   :<C-u>call <SID>call('diff', 'edit/split', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:edit-or-vsplit:vert)  :<C-u>call <SID>call('diff', 'edit/vsplit', v:true)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-diff:edit-or-tabedit:vert) :<C-u>call <SID>call('diff', 'edit/tabedit', v:true)<CR>

  " Smart map
  nmap <buffer><silent><expr>
        \ <Plug>(fern-action-diff:side)
        \ fern#smart#drawer(
        \   "\<Plug>(fern-action-diff:left)",
        \   "\<Plug>(fern-action-diff:right)",
        \ )
  nmap <buffer><silent><expr>
        \ <Plug>(fern-action-diff:side:vert)
        \ fern#smart#drawer(
        \   "\<Plug>(fern-action-diff:left:vert)",
        \   "\<Plug>(fern-action-diff:right:vert)",
        \ )

  " Alias map
  nmap <buffer><silent> <Plug>(fern-action-diff:edit) <Plug>(fern-action-diff:edit-or-error)
  nmap <buffer><silent> <Plug>(fern-action-diff:edit:vert) <Plug>(fern-action-diff:edit-or-error:vert)
  nmap <buffer><silent> <Plug>(fern-action-diff) <Plug>(fern-action-diff:edit)
  nmap <buffer><silent> <Plug>(fern-action-diff:vert) <Plug>(fern-action-diff:edit:vert)
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_diff(helper, opener, vert) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let nodes = filter(copy(nodes), { -> v:val.bufname isnot# v:null })
  if empty(nodes)
    return s:Promise.reject('no node found which has bufname')
  elseif len(nodes) < 2
    return s:Promise.reject('at least two nodes are required to perform diff')
  endif
  try
    let is_drawer = a:helper.sync.is_drawer()
    let first = nodes[0]
    let nodes = nodes[1:]
    call fern#internal#buffer#open(first.bufname, {
          \ 'opener': a:opener,
          \ 'locator': is_drawer,
          \ 'keepalt': !is_drawer && g:fern#keepalt_on_edit,
          \ 'keepjumps': !is_drawer && g:fern#keepjumps_on_edit,
          \})
    call s:diffthis()
    let winid = win_getid()
    for node in nodes
      noautocmd call win_gotoid(winid)
      call fern#internal#buffer#open(node.bufname, {
            \ 'opener': a:vert ? 'vsplit' : 'split',
            \ 'locator': is_drawer,
            \ 'keepalt': !is_drawer && g:fern#keepalt_on_edit,
            \ 'keepjumps': !is_drawer && g:fern#keepjumps_on_edit,
            \})
      call s:diffthis()
    endfor
    call s:diffupdate()
    normal! zm
    " Fix <C-w><C-p> (#47)
    let winid_fern = win_getid()
    noautocmd call win_gotoid(winid)
    noautocmd call win_gotoid(winid_fern)
    return a:helper.async.update_marks([])
        \.then({ -> a:helper.async.remark() })
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:diffthis() abort
  diffthis
  augroup fern_mapping_diff_internal
    autocmd! * <buffer>
    autocmd BufReadPost <buffer>
          \ if &diff && &foldmethod !=# 'diff' |
          \   setlocal foldmethod=diff |
          \ endif
  augroup END
endfunction

function! s:diffupdate() abort
  " NOTE:
  " 'diffupdate' does not work just after a buffer has opened
  " so use timer to delay the command.
  silent! call timer_stop(s:timer_diffupdate)
  let s:timer_diffupdate = timer_start(100, function('s:diffupdate_internal', [bufnr('%')]))
endfunction

function! s:diffupdate_internal(bufnr, ...) abort
  let winid = bufwinid(a:bufnr)
  if winid == -1
    return
  endif
  let winid_saved = win_getid()
  try
    if winid != winid_saved
      call win_gotoid(winid)
    endif
    diffupdate
    syncbind
  finally
    call win_gotoid(winid_saved)
  endtry
endfunction
