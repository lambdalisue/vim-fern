let s:VISIBILITY_IGNORE = -1
let s:VISIBILITY_HIDDEN = 0
let s:VISIBILITY_VISIBLE = 1

let s:plugin_name = matchstr(
      \ expand('<sfile>:p'),
      \ 'autoload[\\/]vital[\\/]__\?\zs[^\\/]\{-}\ze\%(__\)\?[\\/]',
      \)

function! s:_vital_depends() abort
  return ['Async.Promise', 'Prompt', 'App.Revelator']
endfunction

function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')
  let s:Prompt = a:V.import('Prompt')
  let s:Revelator = a:V.import('App.Revelator')
endfunction

function! s:_vital_created(module) abort
  let a:module.name = s:plugin_name
endfunction

function! s:get(...) abort dict
  let expr = a:0 ? a:1 : '%'
  let varname = printf('%s-scenario', self.name)
  let varname = substitute(varname, '\W', '_', 'g')
  return getbufvar(bufnr(expr), varname, v:null)
endfunction

function! s:new(...) abort dict
  let options = extend({
        \ 'actions': [],
        \}, a:0 ? a:1 : {},
        \)
  let scenario = extend({
        \ '__module': self,
        \ '__actions': {},
        \ '__builtin_repeat_cache': '',
        \ 'bind': funcref('s:scenario_bind'),
        \ 'unbind': funcref('s:scenario_unbind'),
        \ 'call': funcref('s:scenario_call'),
        \ 'add': funcref('s:scenario_add'),
        \ 'import': funcref('s:scenario_import'),
        \}, a:0 ? a:1 : {},
        \)
  call scenario.import(options.actions + [
        \ self.define('builtin:choice', funcref('s:_choice'), {
        \   'mapping_mode': 'nv',
        \   'repeatable': 0,
        \   'visibility': s:VISIBILITY_IGNORE,
        \ }),
        \ self.define('builtin:repeat', funcref('s:_repeat'), {
        \   'mapping_mode': 'nv',
        \   'repeatable': 0,
        \   'visibility': s:VISIBILITY_IGNORE,
        \ }),
        \])
  return scenario
endfunction

function! s:define(name, expr, ...) abort dict
  let options = extend({
        \ 'visibility': s:VISIBILITY_VISIBLE,
        \ 'repeatable': 1,
        \ 'mapping_mode': 'n',
        \}, a:0 ? a:1 : {},
        \)
  let action = {
        \ 'name': a:name,
        \ 'expr': a:expr,
        \ 'visibility': options.visibility,
        \ 'repeatable': options.repeatable,
        \ '__map_expr': '',
        \ '__unmap_expr': '',
        \}
  if !empty(options.mapping_mode)
    let mapping = printf('%s-action-%s', self.name, a:name)
    let mapping = substitute(mapping, '\W', '-', 'g')
    let varname = printf('%s-scenario', self.name)
    let varname = substitute(varname, '\W', '_', 'g')
    let lhs = printf('<Plug>(%s)', mapping)
    let rhs = printf('call b:%s.call(''%s'', 1)<CR>', varname, a:name)
    let map_exprs = []
    let unmap_exprs = []
    for mode in split(options.mapping_mode, '\zs')
      call add(map_exprs, printf(
            \ '%snoremap <buffer><silent> %s %s:%s%s',
            \ mode,
            \ lhs,
            \ mode =~# '[i]' ? '<Esc>' : '',
            \ mode =~# '[ni]' ? '<C-u>' : '',
            \ rhs,
            \))
      call add(unmap_exprs, printf('%sunmap <buffer> %s', mode, lhs))
    endfor
    let action.__map_expr = join(filter(map_exprs, '!empty(v:val)'), '|')
    let action.__unmap_expr = join(filter(unmap_exprs, '!empty(v:val)'), '|')
  endif
  return action
endfunction

function! s:scenario_bind(...) abort dict
  let options = extend({
        \ 'default_mappings': 1,
        \}, a:0 ? a:1 : {})
  if options.default_mappings
    let prefix = printf('%s-action', self.__module.name)
    let prefix = substitute(prefix, '\W', '-', 'g')
    execute printf('nmap <buffer><nowait> a <Plug>(%s-builtin-choice)', prefix)
    execute printf('vmap <buffer><nowait> a <Plug>(%s-builtin-choice)', prefix)
    execute printf('imap <buffer><nowait> a <Plug>(%s-builtin-choice)', prefix)
    execute printf('nmap <buffer><nowait> . <Plug>(%s-builtin-repeat)', prefix)
    execute printf('vmap <buffer><nowait> . <Plug>(%s-builtin-repeat)', prefix)
    execute printf('imap <buffer><nowait> . <Plug>(%s-builtin-repeat)', prefix)
  endif
  for action in values(self.__actions)
    execute action.__map_expr
  endfor
  let varname = printf('%s-scenario', self.__module.name)
  let varname = substitute(varname, '\W', '_', 'g')
  let b:{varname} = self
endfunction

function! s:scenario_unbind() abort dict
  " XXX unmap default mappings
  for action in values(self.__actions)
    execute action.__unmap_expr
  endfor
  let varname = printf('%s-scenario', self.__module.name)
  let varname = substitute(varname, '\W', '_', 'g')
  silent! unlet! b:{varname}
endfunction

function! s:scenario_add(action) abort dict
  let self.actions[a:action.name] = a:action
endfunction

function! s:scenario_import(actions) abort dict
  for action in a:actions
    let self.__actions[action.name] = action
  endfor
endfunction

function! s:scenario_call(expr, ...) abort dict range
  let revelator = a:0 ? a:1 : 0
  let range = [a:firstline, a:lastline]
  let [action, params] = s:_find(self, a:expr)
  if revelator
    return s:Revelator.call(action.expr, [range, params], self)
  else
    return call(action.expr, [range, params], self)
  endif
endfunction

function! s:_find(scenario, expr) abort
  let name = matchstr(a:expr, '^\S\+')
  let params = matchstr(a:expr, '^\S\+\s\+\zs.*')
  let suffix = empty(params) ? '' : ' ' . params
  if has_key(a:scenario.__actions, name)
    let action = a:scenario.__actions[name]
    return type(action.expr) is# v:t_string
          \ ? s:_find(a:scenario, action.expr . suffix)
          \ : [action, params]
  else
    let cs = keys(a:scenario.__actions)
    call filter(cs, { -> v:val =~# '^' . name })
    call sort(cs, { a, b -> len(a) - len(b) })
    if empty(cs)
      throw s:Revelator.warning(printf(
            \ 'No corresponding action has found for "%s"',
            \ a:expr
            \))
    endif
    return s:_find(a:scenario, cs[0] . suffix)
  endif
endfunction

function! s:_choice(range, ...) abort dict
  try
    let s:scenario = self
    let expr = s:Prompt.ask('action: ', '', funcref('s:_choice_complete'))
  finally
    silent! unlet! s:scenario
    redraw | echo
  endtry
  if empty(expr)
    return
  endif
  execute printf('%d,%dcall self.call(expr)', a:range[0], a:range[1])
  " to repeatable action
  let [action, _] = s:_find(self, expr)
  if action.repeatable
    let self.__builtin_repeat_cache = expr
  endif
endfunction

function! s:_choice_complete(arglead, cmdline, cursorpos) abort
  let scenario = s:scenario
  let terms = split(a:arglead, ' ', 1)
  let arglead = terms[-1]
  let actions = values(scenario.__actions)
  call filter(actions, { -> v:val.visibility isnot# s:VISIBILITY_IGNORE })
  if empty(arglead)
    call filter(actions, { -> v:val.visibility isnot# s:VISIBILITY_HIDDEN })
  endif
  call map(actions, { -> v:val.name })
  return filter(
        \ uniq(sort(actions)),
        \ { -> v:val =~# '^' . arglead },
        \)
endfunction

function! s:_repeat(...) abort dict
  if empty(self.__builtin_repeat_cache)
    return
  endif
  call self.call(self.__builtin_repeat_cache)
endfunction
