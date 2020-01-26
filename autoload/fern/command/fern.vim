let s:Config = vital#fern#import('Config')
let s:Path = vital#fern#import('System.Filepath')
let s:Flag = vital#fern#import('App.Flag')

let s:options = [
      \ '-drawer',
      \ '-width=',
      \ '-keep',
      \ '-reveal=',
      \ '-toggle',
      \ '-opener',
      \]

function! fern#command#fern#command(mods, qargs) abort
  let [options, remains] = s:Flag.parse(s:Flag.split(a:qargs))

  if s:validate_options(options)
    return
  endif

  let url = fern#lib#url#parse(expand(get(remains, 0, '.')))
  if empty(url.scheme)
    let url.scheme = 'file'
    let url.authority = {
          \ 'userinfo': '',
          \ 'host': '',
          \ 'port': '',
          \}
  endif
  let url.query = extend(url.query, {
        \ 'reveal':get(options, 'reveal', v:false),
        \ 'drawer': get(options, 'drawer', v:false),
        \ 'width': get(options, 'width', v:false),
        \ 'keep': get(options, 'keep', v:false),
        \})
  try
    let url = fern#scheme#{url.scheme}#command#norm(url)
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: fern#scheme#[^#]\+#command#norm/
    " the scheme does not provide command, ignore
  endtry
  try
    if !empty(get(url.query, 'drawer'))
      call fern#internal#drawer#open(fern#lib#url#format(url), {
            \ 'mods': a:mods,
            \ 'opener': get(options, 'opener', g:fern#command#fern#drawer_opener),
            \ 'toggle': get(options, 'toggle', 0),
            \})
    else
      call fern#internal#viewer#open(fern#lib#url#format(url), {
            \ 'mods': a:mods,
            \ 'opener': get(options, 'opener', g:fern#command#fern#viewer_opener),
            \})
    endif
  catch
    call fern#message#error(v:exception)
    call fern#message#debug(v:throwpoint)
  endtry
endfunction

function! fern#command#fern#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-'
    return filter(copy(s:options), { -> v:val =~# '^' . a:arglead })
  endif
  return getcompletion('', 'dir')
endfunction

function! s:validate_options(options) abort
  let names = map(copy(s:options), { -> matchstr(v:val, '^-\zs.\{-}\ze=\?$') })
  for key in keys(a:options)
    if index(names, key) is# -1
      call fern#message#error(printf("Unknown option -%s has specified", key))
      return 1
    endif
  endfor
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'viewer_opener': 'edit',
      \ 'drawer_opener': 'topleft vsplit',
      \})

