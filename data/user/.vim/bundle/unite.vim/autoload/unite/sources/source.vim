"=============================================================================
" FILE: source.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Jun 2013.
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

function! unite#sources#source#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'source',
      \ 'description' : 'candidates from sources list',
      \ 'default_action' : 'start',
      \ 'default_kind' : 'source',
      \}

function! s:source.gather_candidates(args, context) "{{{
  let sources = filter(values(unite#get_all_sources()),
        \        'v:val.is_listed && (empty(a:args) ||
        \            index(a:args, v:val.name) >= 0)')
  return map(copy(unite#util#sort_by(sources, 'v:val.name')), "{
        \ 'word' : v:val.name,
        \ 'abbr' : unite#util#truncate(v:val.name, 25) .
        \         (v:val.description != '' ? ' -- ' . v:val.description : ''),
        \ 'action__source_name' : v:val.name,
        \ 'action__source_args' : [],
        \}")
endfunction"}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return keys(filter(unite#init#_sources([], a:arglead),
            \ 'v:val.is_listed'))
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
