"=============================================================================
" FILE: register.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Jan 2013.
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

function! unite#sources#register#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'register',
      \ 'description' : 'candidates from register',
      \ 'action_table' : {},
      \ 'default_kind' : 'word',
      \}

function! s:source.gather_candidates(args, context) "{{{
  let candidates = []

  let max_width = winwidth(0) - 5
  let registers = [
        \ '"', '+', '*',
        \ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        \ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
        \ 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
        \ 'u', 'v', 'w', 'x', 'y', 'z',
        \ '-', '.', ':', '#', '%', '/', '=',
        \ ]

  for reg in registers
    let register = getreg(reg, 1)
    if register != ''
      call add(candidates, {
            \ 'word' : register,
            \ 'abbr' : printf('%-3s - %s', reg, register),
            \ 'is_multiline' : 1,
            \ 'action__register' : reg,
            \ 'action__regtype' : getregtype(reg),
            \ })
    endif
  endfor

  return candidates
endfunction"}}}

" Actions "{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete registers',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates) "{{{
  for candidate in a:candidates
    silent! call setreg(candidate.action__register, '')
  endfor
endfunction"}}}

let s:source.action_table.edit = {
      \ 'description' : 'change register value',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:source.action_table.edit.func(candidate) "{{{
  let register = getreg(a:candidate.action__register, 1)
  let register = substitute(register, '\r\?\n', '\\n', 'g')
  let new_value = substitute(input('', register), '\\n', '\n', 'g')
  silent! call setreg(a:candidate.action__register,
        \ new_value, a:candidate.action__regtype)
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
