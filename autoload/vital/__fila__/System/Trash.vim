if has('mac') && executable('osascript')
  " macOS
  " https://apple.stackexchange.com/a/162354/255654
  function! s:delete(path) abort
    let script = 'tell app "Finder" to move the POSIX file "%s" to trash'
    let abspath = fnamemodify(expand(a:path), ':p')
    echo system(printf('osascript -e ''%s''', printf(script, abspath)))
    return v:shell_error
  endfunction
elseif has('win32') && executable('powershell')
  " Windows
  function! s:delete(path) abort
    let abspath = fnamemodify(expand(a:path), ':p:gs?/?\\?')
    let script = [
          \ printf('$path = \"%s\"', abspath),
          \ '$shell = new-object -comobject \"Shell.Application\"',
          \ '$item = $shell.Namespace(0).ParseName(\"$path\")',
          \ '$item.InvokeVerb(\"delete\")',
          \]
    echo system(printf(
          \ 'powershell -ExecutionPolicy Bypass -Command "%s"',
          \ join(script, "\r\n"))
          \)
    return v:shell_error
  endfunction
else
  " freedesktop
  " https://www.freedesktop.org/wiki/Specifications/trash-spec/
  function! s:delete(path) abort
    throw 'vital: System.Trash: non supported platform'
  endfunction
endif
