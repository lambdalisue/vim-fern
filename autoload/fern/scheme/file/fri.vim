function! fern#scheme#file#fri#to_fri(path) abort
  call fern#util#deprecated(
        \ 'fern#scheme#file#fri#to_fri()',
        \ 'fern#internal#filepath module',
        \)
  let path = fern#internal#path#absolute(
        \ fern#internal#filepath#to_slash(a:path),
        \ fern#internal#filepath#to_slash(getcwd()),
        \)
  return printf('file://%s', path)
endfunction

function! fern#scheme#file#fri#from_fri(fri) abort
  call fern#util#deprecated(
        \ 'fern#scheme#file#fri#from_fri()',
        \ 'fern#internal#filepath#from_slash()',
        \)
  return fern#internal#filepath#from_slash('/' . a:fri.path)
endfunction
