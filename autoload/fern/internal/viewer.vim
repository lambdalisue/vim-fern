let s:Lambda = vital#fern#import('Lambda')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#internal#viewer#open(fri, options) abort
  call fern#logger#debug('open:', a:fri)
  let bufname = fern#fri#format(a:fri)
  return s:Promise.new(funcref('s:open', [bufname, a:options]))
endfunction

function! fern#internal#viewer#init() abort
  try
    let bufnr = bufnr('%')
    return s:init()
          \.then({ -> s:notify(bufnr, v:null) })
          \.catch({ e -> s:Lambda.pass(s:Promise.reject(e), s:notify(bufnr, e)) })
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! fern#internal#viewer#reveal(helper, path) abort
  let path = fern#internal#filepath#to_slash(a:path)
  let path = substitute(path, '^\./', '', '')
  let reveal = split(path, '/')
  let previous = a:helper.sync.get_cursor_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.async.reveal_node(reveal) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.focus_node(reveal) })
endfunction

function! s:open(bufname, options, resolve, reject) abort
  if fern#internal#buffer#open(a:bufname, a:options)
    call a:reject('Cancelled')
    return
  endif
  let b:fern_notifier = {
        \ 'resolve': a:resolve,
        \ 'reject': a:reject,
        \}
endfunction

function! s:init() abort
  command! -buffer -bar -nargs=*
        \ -complete=customlist,fern#internal#command#reveal#complete
        \ FernReveal
        \ call fern#internal#command#reveal#command(<q-mods>, [<f-args>])

  setlocal buftype=nofile bufhidden=unload
  setlocal noswapfile nobuflisted nomodifiable
  setlocal signcolumn=yes
  " The 'foldmethod=manual' is required to avoid the following issue
  " https://github.com/lambdalisue/fern.vim/issues/331
  setlocal foldmethod=manual

  augroup fern_internal_viewer_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> setlocal nobuflisted
    autocmd BufReadCmd <buffer> nested call s:BufReadCmd()
    autocmd CursorMoved,CursorMovedI,BufLeave <buffer> let b:fern_cursor = getcurpos()[1:2]
  augroup END
  call fern#internal#viewer#auto_duplication#init()
  call fern#internal#viewer#hide_cursor#init()

  " Add unique fragment to make each buffer uniq
  let bufname = bufname('%')
  let fri = fern#fri#parse(bufname)
  if empty(fri.authority)
    let fri.authority = sha256(localtime())[:7]
    let previous = bufname
    let bufname = fern#fri#format(fri)
    execute printf('silent! keepalt file %s', fnameescape(bufname))
    execute printf('silent! bwipeout %s', previous)
  endif

  let resource_uri = fri.path
  let scheme = fern#fri#parse(resource_uri).scheme
  let provider = fern#internal#scheme#provider_new(scheme)
  if provider is# v:null
    throw printf('no such scheme %s exists', scheme)
  endif

  let b:fern = fern#internal#core#new(
        \ resource_uri,
        \ provider,
        \)
  let helper = fern#helper#new()
  let root = helper.sync.get_root_node()

  call fern#mapping#init(scheme)
  call fern#internal#drawer#init()
  if !g:fern#disable_viewer_spinner
    call fern#internal#spinner#start()
  endif

  " now the buffer is ready so set filetype to emit FileType
  setlocal filetype=fern
  call fern#action#_init()

  let l:Profile = fern#profile#start('fern#internal#viewer:init')
  return s:Promise.resolve()
        \.then({ -> helper.async.expand_node(root.__key) })
        \.finally({ -> Profile('expand') })
        \.then({ -> helper.async.redraw() })
        \.finally({ -> Profile('redraw') })
        \.finally({ -> Profile() })
        \.then({ -> fern#hook#emit('viewer:ready', helper) })
endfunction

function! s:notify(bufnr, error) abort
  let notifier = getbufvar(a:bufnr, 'fern_notifier', v:null)
  if notifier isnot# v:null
    call setbufvar(a:bufnr, 'fern_notifier', v:null)
    if a:error is# v:null
      call notifier.resolve(a:bufnr)
    else
      call notifier.reject([a:bufnr, a:error])
    endif
  endif
endfunction

function! s:BufReadCmd() abort
  let helper = fern#helper#new()
  setlocal filetype=fern
  setlocal modifiable
  call setline(1, get(b:, 'fern_viewer_cache_content', []))
  setlocal nomodifiable
  call helper.sync.set_cursor(get(b:, 'fern_cursor', getcurpos()[1:2]))
  let root = helper.sync.get_root_node()
  call s:Promise.resolve()
        \.then({ -> helper.async.reload_node(root.__key) })
        \.then({ -> helper.async.redraw() })
        \.then({ -> fern#hook#emit('viewer:ready', helper) })
        \.catch({ e -> fern#logger#error(e) })
endfunction

augroup fern_internal_viewer
  autocmd!
  autocmd User FernSyntax :
  autocmd User FernHighlight :
augroup END

" Cache content to accelerate rendering
call fern#hook#add('viewer:redraw', { h ->
      \ setbufvar(h.bufnr, 'fern_viewer_cache_content', getbufline(h.bufnr, 1, '$'))
      \})

" Deprecated:
call fern#hook#add('viewer:highlight', { h -> fern#hook#emit('renderer:highlight', h) })
call fern#hook#add('viewer:syntax', { h -> fern#hook#emit('renderer:syntax', h) })
