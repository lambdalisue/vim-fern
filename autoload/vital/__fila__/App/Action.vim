let s:plugin_name = matchstr(
      \ expand('<sfile>:p'),
      \ 'autoload[\\/]vital[\\/]__\?\zs[^\\/]\{-}\ze\%(__\)\?[\\/]',
      \)

function! s:_vital_depends() abort
  return ['Prompt', 'App.Revelator']
endfunction

function! s:_vital_loaded(V) abort
  let s:Prompt = a:V.import('Prompt')
  let s:Revelator = a:V.import('App.Revelator')
endfunction

function! s:_vital_created(module) abort
  let a:module.name = printf('%s-action', s:plugin_name)
endfunction

function! s:new(...) abort dict
  let action = extend({
        \ 'actions': {},
        \ 'args': { -> [] },
        \}, a:0 ? a:1 : {})
  call extend(action, {
        \ 'name': self.name,
        \ 'builtin_repeat_cache': '',
        \ 'init': funcref('s:action_init'),
        \ 'define': funcref('s:action_define'),
        \ 'call': funcref('s:action_call'),
        \ 'call_safe': funcref('s:action_call_safe'),
        \})
  call action.define('builtin:choice', funcref('s:_choice'), {
        \ 'mapping_mode': 'nv',
        \ 'repeat': 0,
        \ 'hidden': 2,
        \})
  call action.define('builtin:repeat', funcref('s:_repeat'), {
        \ 'mapping_mode': 'nv',
        \ 'repeat': 0,
        \ 'hidden': 2,
        \})
  return action
endfunction

function! s:get(...) abort dict
  let expr = a:0 ? a:1 : '%'
  let name = substitute(self.name, '\W', '_', 'g')
  return getbufvar(bufnr(expr), name, v:null)
endfunction

function! s:action_init(...) abort dict
  let options = extend({
        \ 'default_mappings': 1,
        \}, a:0 ? a:1 : {})
  if options.default_mappings
    let prefix = substitute(self.name, '\W', '-', 'g')
    execute printf('nmap <buffer><nowait> a <Plug>(%s-builtin-choice)', prefix)
    execute printf('vmap <buffer><nowait> a <Plug>(%s-builtin-choice)', prefix)
    execute printf('imap <buffer><nowait> a <Plug>(%s-builtin-choice)', prefix)
    execute printf('nmap <buffer><nowait> . <Plug>(%s-builtin-repeat)', prefix)
    execute printf('vmap <buffer><nowait> . <Plug>(%s-builtin-repeat)', prefix)
    execute printf('imap <buffer><nowait> . <Plug>(%s-builtin-repeat)', prefix)
  endif
  let name = substitute(self.name, '\W', '_', 'g')
  let b:{name} = self
endfunction

function! s:action_define(name, expr, ...) abort dict
  let action = extend({
        \ 'name': a:name,
        \ 'expr': a:expr,
        \ 'repeat': 1,
        \ 'hidden': 0,
        \ 'mapping_mode': 'n',
        \}, a:0 ? a:1 : {})
  if !empty(action.mapping_mode)
    let mapping = printf(
          \ '<Plug>(%s-%s)',
          \ substitute(self.name, '\W', '-', 'g'),
          \ substitute(action.name, '\W', '-', 'g'),
          \)
    for mode in split(action.mapping_mode, '\zs')
      execute printf(
            \ '%snoremap <buffer><silent> %s %s:%scall b:%s.call_safe(''%s'')<CR>',
            \ mode,
            \ mapping,
            \ mode =~# '[i]' ? '<Esc>' : '',
            \ mode =~# '[ni]' ? '<C-u>' : '',
            \ substitute(self.name, '\W', '_', 'g'),
            \ a:name,
            \)
    endfor
  endif
  let self.actions[action.name] = action
endfunction

function! s:action_call(expr) abort dict range
  let range = [a:firstline, a:lastline]
  let [action, params] = s:_find(self, a:expr)
  let args = self.args()
  return call(action.expr, [range, params] + args, self)
endfunction

function! s:action_call_safe(expr) abort dict range
  let range = [a:firstline, a:lastline]
  let [action, params] = s:_find(self, a:expr)
  let args = self.args()
  return s:Revelator.call(action.expr, [range, params] + args, self)
endfunction

function! s:_find(action, expr) abort
  let name = matchstr(a:expr, '^\S\+')
  let params = matchstr(a:expr, '^\S\+\s\+\zs.*')
  let suffix = empty(params) ? '' : ' ' . params
  if has_key(a:action.actions, name)
    let action = a:action.actions[name]
    return type(action.expr) is# v:t_string
          \ ? s:_find(a:action, action.expr . suffix)
          \ : [action, params]
  else
    let cs = keys(a:action.actions)
    call filter(cs, { -> v:val =~# '^' . name })
    call sort(cs, { a, b -> len(a) - len(b) })
    if empty(cs)
      throw s:Revelator.warning(printf(
            \ 'No corresponding action has found for "%s"',
            \ a:expr
            \))
    endif
    return s:_find(a:action, cs[0] . suffix)
  endif
endfunction

function! s:_choice(range, ...) abort dict
  try
    let s:action = self
    let expr = s:Prompt.ask('action: ', '', funcref('s:_choice_complete'))
  finally
    silent! unlet! s:action
    redraw | echo
  endtry
  if empty(expr)
    return
  endif
  execute printf('%d,%dcall self.call(expr)', a:range[0], a:range[1])
  " to repeat action
  let [action, _] = s:_find(self, expr)
  if action.repeat
    let self.builtin_repeat_cache = expr
  endif
endfunction

function! s:_choice_complete(arglead, cmdline, cursorpos) abort
  let action = s:action
  let terms = split(a:arglead, ' ', 1)
  let arglead = terms[-1]
  let actions = values(action.actions)
  call filter(actions, { -> v:val.hidden isnot# 2 })
  if empty(arglead)
    call filter(actions, { -> v:val.hidden isnot# 1 })
  endif
  call map(actions, { -> v:val.name })
  return filter(
        \ uniq(sort(actions)),
        \ { -> v:val =~# '^' . arglead },
        \)
endfunction

function! s:_repeat(...) abort dict
  if empty(self.builtin_repeat_cache)
    return
  endif
  call self.call(self.builtin_repeat_cache)
endfunction
