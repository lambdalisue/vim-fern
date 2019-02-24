let s:Promise = vital#fila#import('Async.Promise')
let s:Lambda = vital#fila#import('Lambda')
let s:Scenario = vital#fila#import('App.Scenario')

function! fila#ui#viewer#init(provider, ...) abort
  let options = extend({
        \ 'actions': [],
        \ 'default_mappings': 1,
        \}, a:0 ? a:1 : {},
        \)

  if !exists('b:fila_ready')
    let b:fila_ready = 1
    let b:fila_provider = a:provider

    setlocal buftype=nofile bufhidden=unload noswapfile nobuflisted
    setlocal nomodifiable readonly

    augroup fila_ui_viewer_internal
      autocmd! * <buffer>
      autocmd BufEnter    <buffer> setlocal nobuflisted
      autocmd BufReadCmd  <buffer> call s:BufReadCmd()
      autocmd BufReadPre  <buffer> :
      autocmd BufReadPost <buffer> :
      autocmd User FilaViewerReady :
    augroup END

    let scenario = s:Scenario.new({
          \ 'actions': options.actions + fila#ui#action#actions(),
          \})
    call scenario.bind()

    if options.default_mappings
      " nmap <buffer><nowait> <Backspace> <Plug>(fila-action-leave)
      " nmap <buffer><nowait> <C-h>       <Plug>(fila-action-leave)
      " nmap <buffer><nowait> <Return>    <Plug>(fila-action-enter-or-edit)
      " nmap <buffer><nowait> <C-m>       <Plug>(fila-action-enter-or-edit)
      nmap <buffer><nowait> <C-l>       <Plug>(fila-action-reload)<C-l>
      nmap <buffer><nowait> l           <Plug>(fila-action-expand)
      nmap <buffer><nowait> h           <Plug>(fila-action-collapse)
      nmap <buffer><nowait> -           <Plug>(fila-action-mark)
      vmap <buffer><nowait> -           <Plug>(fila-action-mark)
      nmap <buffer><nowait> !           <Plug>(fila-action-hidden)
      " nmap <buffer><nowait> e           <Plug>(fila-action-edit)
      " nmap <buffer><nowait> t           <Plug>(fila-action-edit-tabedit)
      " nmap <buffer><nowait> E           <Plug>(fila-action-edit-side)
    endif
  endif

  let helper = fila#ui#helper#get()
  return helper.init(options)
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:BufReadCmd() abort
  doautocmd <nomodeline> BufReadPre

  let helper = fila#ui#helper#get()
  call helper.redraw()
        \.then({ h -> fila#ui#notifier#notify(h.bufnr) })
        \.catch({ e -> fila#error#handle(e) })

  doautocmd <nomodeline> BufReadPost
endfunction
