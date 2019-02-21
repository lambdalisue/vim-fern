let s:HASH = sha256(expand('<sfile>'))

function! s:_vital_created(module) abort
  let s:flush_timer = v:null
  let s:flush_interval = 0
  let s:logfile = v:null
  let s:buffer = []
endfunction

function! s:get_logfile() abort
  return s:logfile
endfunction

function! s:start(filename, ...) abort
  let options = extend({
        \ 'interval': 200,
        \ 'fresh': 0,
        \}, a:0 ? a:1 : {},
        \)
  execute printf('augroup vital_app_struct_logger_%s', s:HASH)
  autocmd! *
  execute 'autocmd VimLeave silent! call s:_flush_callback()'
  execute 'augroup END'
  call mkdir(fnamemodify(a:filename, ':p:h'), 'p')
  let s:flush_interval = options.interval
  let s:logfile = a:filename
  if options.fresh
    call writefile([], s:logfile)
  endif
endfunction

function! s:stop() abort
  silent! call timer_stop(s:flush_timer)
  silent! call s:_flush_callback()
  execute printf('augroup vital_app_struct_logger_%s', s:HASH)
  autocmd! *
  execute 'augroup END'
  let s:logfile = v:null
endfunction

function! s:debug(message, ...) abort
  if s:logfile is# v:null
    return
  endif
  call s:_write('debug', a:message, a:000)
endfunction

function! s:info(message, ...) abort
  if s:logfile is# v:null
    return
  endif
  call s:_write('info', a:message, a:000)
endfunction

function! s:warning(message, ...) abort
  if s:logfile is# v:null
    return
  endif
  call s:_write('warning', a:message, a:000)
endfunction

function! s:error(message, ...) abort
  if s:logfile is# v:null
    return
  endif
  call s:_write('error', a:message, a:000)
endfunction

function! s:critical(message, ...) abort
  if s:logfile is# v:null
    return
  endif
  call s:_write('critical', a:message, a:000)
endfunction

function! s:_write(level, message, contexts) abort
  if s:flush_timer is# v:null
    let s:flush_timer = timer_start(
          \ s:flush_interval,
          \ { -> s:_flush_callback() },
          \)
  endif
  call add(s:buffer, a:contexts + [{
        \ 'time': strftime('%FT%T%z'),
        \ 'level': a:level,
        \ 'message': a:message,
        \ 'exception': v:exception,
        \ 'throwpoint': v:throwpoint,
        \}])
endfunction

function! s:_flush_callback(...) abort
  try
    if empty(s:buffer)
      return
    endif
    let content = []
    for contexts in s:buffer
      let context = {}
      call map(copy(contexts), { -> extend(context, v:val) })
      try
        call add(content, json_encode(context))
      catch
        if &verbose
          echohl Error
          echomsg substitute(v:exception, '^Vim:', '', '')
          echohl None
        endif
        call add(content, json_encode(contexts[-1]))
      endtry
    endfor
    call writefile(content, s:logfile, 'a')
  catch
    if &verbose
      echohl Error
      echomsg substitute(v:exception, '^Vim:', '', '')
      echohl None
    endif
  finally
    let s:flush_timer = v:null
    let s:buffer = []
  endtry
endfunction
