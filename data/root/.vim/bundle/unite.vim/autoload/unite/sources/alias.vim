"=============================================================================
" FILE: alias.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          tacroe <tacroe at gmail.com>
" Last Modified: 31 Oct 2013.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

call unite#util#set_default('g:unite_source_alias_aliases', {})

function! unite#sources#alias#define()
  return s:make_aliases()
endfunction

function! s:make_aliases()
  let aliases = []
  for [name, config] in items(g:unite_source_alias_aliases)
    let args =
          \ (!has_key(config, 'args')) ? [] :
          \ (type(config.args) == type([])) ?
          \ config.args : [config.args]

    let alias = {}
    let alias.name = name
    let alias.description = get(config, 'description',
          \ s:make_default_description(config.source, args))
    let alias.source__config = config
    let alias.source__args = args
    let alias.hooks = {}

    function! alias.hooks.on_pre_init(args, context)
      let config = a:context.source.source__config
      let original_source =
            \ (!has_key(config, 'source') ||
            \  config.source ==# a:context.source.name) ? {} :
            \ deepcopy(unite#get_all_sources(config.source))
      let alias_source = deepcopy(a:context.source)

      if has_key(original_source, 'hooks')
            \ && has_key(original_source.hooks, 'on_pre_init')
        " Call pre init hook.
        call original_source.hooks.on_pre_init(
              \ a:context.source.source__args + a:args,
              \ { 'source' : original_source })
      endif

      let source = extend(a:context.source,
            \ filter(copy(original_source),
            \ 'type(v:val) != type(function("type"))'))
      let source.name = alias_source.name
      let source.description = alias_source.description
      let source.hooks = {}
      let source.source__original_source = original_source
      let source.source__args = a:context.source.source__args

      " Overwrite hooks.
      if has_key(original_source, 'hooks')
        for func in filter(keys(original_source.hooks),
              \ 'v:val !=# "on_pre_init"')
          let define_function = join([
                \ 'function! source.hooks.' . func . '(args, context)',
                \ '  let args = a:context.source.source__args + a:args',
                \ '  return a:context.source.source__original_source.hooks.'
                \                    . func . '(args, a:context)',
                \ 'endfunction'], "\n")
          execute define_function
        endfor
      endif

      " Overwrite functions.
      for func in keys(filter(copy(original_source),
            \ 'type(v:val) == type(function("type"))'))
        if func ==# 'complete'
          let define_function = join([
                \ 'function! source.' . func . '(args, context, arglead, cmdline, cursorpos)',
                \ '  let args = self.source__args + a:args',
                \ '  return self.source__original_source.'
                \                    . func .
                \   '(args, a:context, a:arglead, a:cmdline, a:cursorpos)',
                \ 'endfunction'], "\n")
        else
          let define_function = join([
                \ 'function! source.' . func . '(args, context)',
                \ '  let args = self.source__args + a:args',
                \ '  return self.source__original_source.'
                \                    . func . '(args, a:context)',
                \ 'endfunction'], "\n")
        endif
        execute define_function
      endfor
    endfunction

    call add(aliases, alias)
  endfor

  return aliases
endfunction

function! s:make_default_description(source_name, args)
  let desc = 'alias for "' . a:source_name
  if empty(a:args)
    return desc . '"'
  endif

  let desc .= ':' . join(a:args, ':') . '"'
  return desc
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
