function! s:_vital_depends() abort
  return ['Async.Promise.Process']
endfunction

function! s:_vital_loaded(V) abort
  let s:Process = a:V.import('Async.Promise.Process')
endfunction

" open()
if executable('rundll32')
  function! s:open(filename) abort
    let filename = fnamemodify(substitute(a:filename, '[/\\]\+', '\', 'g'), ':p')
    return s:Process.start([
          \ 'rundll32',
          \ 'url.dll,FileProtocolHandler',
          \ filename,
          \])
          \.then({ r -> s:_iconv_result(r) })
          \.catch({ e -> s:_iconv_result(e) })
  endfunction
elseif executable('cygstart')
  function! s:open(filename) abort
    return s:Process.start([
          \ 'cygstart',
          \ a:filename,
          \])
          \.then({ r -> s:_iconv_result(r) })
          \.catch({ e -> s:_iconv_result(e) })
  endfunction
elseif executable('xdg-open')
  function! s:open(filename) abort
    return s:Process.start([
          \ 'xdg-open',
          \ a:filename,
          \])
  endfunction
elseif executable('gnome-open')
  function! s:open(filename) abort
    return s:Process.start([
          \ 'gnome-open',
          \ a:filename,
          \])
  endfunction
elseif executable('exo-open')
  function! s:open(filename) abort
    return s:Process.start([
          \ 'exo-open',
          \ a:filename,
          \])
  endfunction
elseif executable('open')
  function! s:open(filename) abort
    return s:Process.start([
          \ 'open',
          \ a:filename,
          \])
  endfunction
elseif executable('kioclient')
  function! s:open(filename) abort
    return s:Process.start([
          \ 'kioclient', 'exec',
          \ a:filename,
          \])
  endfunction
else
  function! s:open(filename) abort
    throw 'vital: Async.File: open(): Not supported platform.'
  endfunction
endif

" move_dir()
if has('win32') && executable('cmd')
  function! s:move_dir(src, dst) abort
    " normalize successive slashes to one slash
    let src = substitute(a:src, '[/\\]\+', '\', 'g')
    let dst = substitute(a:dst, '[/\\]\+', '\', 'g')
    " src must NOT have trailing slush
    let src = substitute(src, '\\$', '', '')
    return s:Process.start([
          \ 'cmd.exe', '/c', 'move', '/y', src, dst,
          \])
          \.then({ r -> s:_iconv_result(r) })
          \.catch({ e -> s:_iconv_result(e) })
  endfunction
elseif executable('mv')
  function! s:move_dir(src, dst) abort
    return s:Process.start([
          \ 'mv', a:src, a:dst,
          \])
  endfunction
else
  function! s:move_dir(src, dst) abort
    throw 'vital: Async.File: move(): Not supported platform.'
  endfunction
endif

" move_file()
if has('win32') && executable('cmd')
  function! s:move(src, dst) abort
    " normalize successive slashes to one slash
    let src = fnamemodify(substitute(a:src, '[/\\]\+', '\', 'g'), ':p')
    let dst = fnamemodify(substitute(a:dst, '[/\\]\+', '\', 'g'), ':p')
    " src must NOT have trailing slush
    let src = substitute(src, '\\$', '', '')
    return s:Process.start([
          \ 'cmd.exe', '/c', 'move', '/y', src, dst,
          \])
          \.then({ r -> s:_iconv_result(r) })
          \.catch({ e -> s:_iconv_result(e) })
  endfunction
elseif executable('mv')
  function! s:move(src, dst) abort
    return s:Process.start([
          \ 'mv', a:src, a:dst,
          \])
  endfunction
else
  function! s:move(src, dst) abort
    return !rename(a:src, a:dst)
  endfunction
endif

" copy_dir()
if has('win32') && executable('robocopy')
  function! s:copy_dir(src, dst) abort
    " normalize successive slashes to one slash
    let src = fnamemodify(substitute(a:src, '[/\\]\+', '\', 'g'), ':p')
    let dst = fnamemodify(substitute(a:dst, '[/\\]\+', '\', 'g'), ':p')
    " src must NOT have trailing slush
    let src = substitute(src, '\\$', '', '')
    return s:Process.start([
          \ 'robocopy', '/e', src, dst,
          \])
          \.then({ r -> s:_iconv_result(r) })
          \.catch({ e -> s:_iconv_result(e) })
  endfunction
elseif executable('cp')
  function! s:copy_dir(src, dst) abort
    return s:Process.start([
          \ 'cp', '-R', a:src, a:dst,
          \])
  endfunction
else
  function! s:copy_dir(src, dst) abort
    throw 'vital: Async.File: copy_dir(): Not supported platform.'
  endfunction
endif

" copy()
if has('win32') && executable('cmd')
  function! s:copy(src, dst) abort
    " normalize successive slashes to one slash
    let src = fnamemodify(substitute(a:src, '[/\\]\+', '\', 'g'), ':p')
    let dst = fnamemodify(substitute(a:dst, '[/\\]\+', '\', 'g'), ':p')
    " src must NOT have trailing slush
    let src = substitute(src, '\\$', '', '')
    return s:Process.start([
          \ 'cmd', '/c', 'copy', '/y', src, dst,
          \])
          \.then({ r -> s:_iconv_result(r) })
          \.catch({ e -> s:_iconv_result(e) })
  endfunction
elseif executable('cp')
  function! s:copy(src, dst) abort
    return s:Process.start([
          \ 'cp', a:src, a:dst,
          \])
  endfunction
else
  function! s:copy(src, dst) abort
    let r = writefile(readfile(a:src, 'b'), a:dst, 'b')
    return r is# -1 ? 0 : 1
  endfunction
endif

" trash()
if has('mac') && executable('osascript')
  function! s:trash(path) abort
    let script = 'tell app "Finder" to move the POSIX file "%s" to trash'
    let abspath = fnamemodify(a:path, ':p')
    return s:Process.start([
          \ 'osascript', '-e', printf(script, abspath)
          \])
  endfunction
elseif has('win32') && executable('powershell')
  function! s:trash(path) abort
    let abspath = fnamemodify(substitute(a:path, '[/\\]\+', '\', 'g'), ':p')
    let script = [
          \ '$path = Get-Item ''%s''',
          \ '$shell = New-Object -ComObject ''Shell.Application''',
          \ '$shell.NameSpace(0).ParseName($path.FullName).InvokeVerb(''delete'')',
          \]
    return s:Process.start([
          \ 'powershell',
          \ '-ExecutionPolicy', 'Bypass',
          \ '-Command', printf(join(script, "\r\n"), abspath),
          \])
          \.then({ r -> s:_iconv_result(r) })
          \.catch({ e -> s:_iconv_result(e) })
  endfunction
elseif executable('trash-put')
  " https://github.com/andreafrancia/trash-cli
  function! s:trash(path) abort
    let abspath = fnamemodify(a:path, ':p')
    return s:Process.start([
          \ 'trash-put', abspath,
          \])
  endfunction
elseif executable('gomi')
  " https://github.com/b4b4r07/gomi
  function! s:trash(path) abort
    let abspath = fnamemodify(a:path, ':p')
    return s:Process.start([
          \ 'gomi', abspath,
          \])
  endfunction
else
  " freedesktop
  " https://www.freedesktop.org/wiki/Specifications/trash-spec/
  function! s:trash(path) abort
    throw 'vital: Async.File: trash(): Not supported platform.'
  endfunction
endif

function! s:_iconv_result(r) abort
  let a:r.stdout = map(a:r.stdout, { -> iconv(v:val, 'char', &encoding) })
  let a:r.stderr = map(a:r.stderr, { -> iconv(v:val, 'char', &encoding) })
  return a:r
endfunction
