"=============================================================================
" FILE: tab.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Apr 2013.
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

function! unite#sources#tab#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'tab',
      \ 'description' : 'candidates from tab list',
      \ 'syntax' : 'uniteSource__Tab',
      \ 'hooks' : {},
      \ 'default_kind' : 'tab',
      \}

function! s:source.gather_candidates(args, context) "{{{
  let list = range(1, tabpagenr('$'))
  let arg = get(a:args, 0, '')
  if arg ==# 'no-current'
    call filter(list, 'v:val != tabpagenr()')
  endif

  let candidates = []
  for i in list
    " Get current window buffer in tabs.
    let bufnr = tabpagebuflist(i)[tabpagewinnr(i) - 1]

    let bufname = unite#substitute_path_separator(
          \ (i == tabpagenr() ?
          \       bufname('#') : bufname(bufnr)))
    if bufname == ''
      let bufname = '[No Name]'
    endif

    if exists('*gettabvar')
      " Use gettabvar().
      let title = gettabvar(i, 'title')
      if title != ''
        let title = '[' . title . ']'
      endif

      let cwd = unite#substitute_path_separator(
            \ (i == tabpagenr() ? getcwd() : gettabvar(i, 'cwd')))
      if cwd !~ '/$'
        let cwd .= '/'
      endif
    else
      let title = ''
      let cwd = ''
    endif

    let abbr = i . ': ' . title
    if cwd != ''
      if stridx(bufname, cwd) == 0
        let bufname = bufname[len(cwd) :]
      endif
      let abbr .= (title != '' ? ' ' : '') . bufname

      let abbr .= ' (' . substitute(cwd, '.\zs/$', '', '') . ')'
    else
      let abbr .= bufname
    endif

    let wincnt = tabpagewinnr(i, '$')
    if i == tabpagenr()
      let wincnt -= 1
    endif
    if wincnt > 1
      let abbr .= '{' . wincnt . '}'
    endif
    let abbr .= getbufvar(bufnr('%'), '&modified') ? '[+]' : ''

    if len(tabpagebuflist(i)) > 1
      " Get tab windows list.
      let tabnr = tabpagenr()
      execute 'tabnext' i
      let abbr .= "\n" . join(map(range(1, winnr('$')),
            \ "printf('%s %d: %s', repeat(' ', 1), v:val,
            \ (bufname(winbufnr(v:val)) == '' ?
            \ '[No Name]' : bufname(winbufnr(v:val))))"), "\n")
      execute 'tabnext' tabnr
    endif
    let word = exists('*gettabvar') && gettabvar(i, 'title') != '' ?
          \ gettabvar(i, 'title') : bufname

    call add(candidates, {
          \ 'word' : abbr,
          \ 'is_multiline' : 1,
          \ 'action__tab_nr' : i,
          \ 'action__directory' : cwd,
          \ })
  endfor

  return candidates
endfunction"}}}
function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return ['no-current']
endfunction"}}}
function! s:source.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__Tab_title /\[.\{-}\]/
        \ contained containedin=uniteSource__Tab
  highlight default link uniteSource__Tab_title Function
  syntax match uniteSource__Tab_directory /(.\{-})/
        \ contained containedin=uniteSource__Tab
  highlight default link uniteSource__Tab_directory PreProc
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
