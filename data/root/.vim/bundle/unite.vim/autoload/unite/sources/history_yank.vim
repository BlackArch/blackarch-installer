"=============================================================================
" FILE: history_yank.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Jan 2014.
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

" Variables  "{{{
let s:yank_histories = []

" the last modified time of the yank histories file.
let s:yank_histories_file_mtime = 0

let s:prev_registers = {}

call unite#util#set_default('g:unite_source_history_yank_file',
      \ g:unite_data_directory . '/history_yank')

call unite#util#set_default('g:unite_source_history_yank_limit', 100)

call unite#util#set_default(
      \ 'g:unite_source_history_yank_save_clipboard', 0)
"}}}

function! unite#sources#history_yank#define() "{{{
  return s:source
endfunction"}}}
function! unite#sources#history_yank#_append() "{{{
  call s:load()

  let prev_histories = copy(s:yank_histories)

  call s:add_register('"')

  if g:unite_source_history_yank_save_clipboard
    call s:add_register('+')
  endif

  if prev_histories !=# s:yank_histories
    " Updated.

    if g:unite_source_history_yank_limit < len(s:yank_histories)
      let s:yank_histories =
            \ s:yank_histories[ : g:unite_source_history_yank_limit - 1]
    endif

    call s:save()
  endif
endfunction"}}}

let s:source = {
      \ 'name' : 'history/yank',
      \ 'description' : 'candidates from yank history',
      \ 'action_table' : {},
      \ 'default_kind' : 'word',
      \}

function! s:source.gather_candidates(args, context) "{{{
  call s:load()

  let max_width = winwidth(0) - 5
  return map(copy(s:yank_histories), "{
        \ 'word' : v:val[0],
        \ 'is_multiline' : 1,
        \ 'action__regtype' : v:val[1],
        \ }")
endfunction"}}}

" Actions "{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete from yank history',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates) "{{{
  for candidate in a:candidates
    call filter(s:yank_histories, 'v:val[0] !=# candidate.word')
  endfor

  call s:save()
endfunction"}}}
"}}}

function! s:save()  "{{{
  if g:unite_source_history_yank_file == ''
    return
  endif

  call writefile([string(s:yank_histories)],
        \              g:unite_source_history_yank_file)
  let s:yank_histories_file_mtime = getftime(g:unite_source_history_yank_file)
endfunction"}}}
function! s:load()  "{{{
  if !filereadable(g:unite_source_history_yank_file)
  \  || s:yank_histories_file_mtime == getftime(g:unite_source_history_yank_file)
    return
  endif

  let file = readfile(g:unite_source_history_yank_file)
  if empty(file)
    return
  endif

  try
    sandbox let s:yank_histories = eval(file[0])

    " Type check.
    let history = s:yank_histories[0]
    let history[0] = history[0]
  catch
    let s:yank_histories = []
  endtry

  let s:yank_histories_file_mtime = getftime(g:unite_source_history_yank_file)

  let s:yank_histories = unite#util#uniq(s:yank_histories)
endfunction"}}}

function! s:add_register(name) "{{{
  let reg = [getreg(a:name), getregtype(a:name)]
  if get(s:prev_registers, a:name, []) ==# reg
    " Skip same register value.
    return
  endif

  let len_history = len(reg[0])
  " Ignore too long yank.
  if len_history < 2 || len_history > 100000
    return
  endif

  let s:prev_registers[a:name] = reg

  " Append register value.
  call insert(s:yank_histories, reg)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
