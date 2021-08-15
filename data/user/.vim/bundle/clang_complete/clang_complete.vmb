" Vimball Archiver by Charles E. Campbell
UseVimball
finish
bin/cc_args.py	[[[1
102
#!/usr/bin/env python
#-*- coding: utf-8 -*-

import sys

CONFIG_NAME = ".clang_complete"

def readConfiguration():
  try:
    f = open(CONFIG_NAME, "r")
  except IOError:
    return []

  result = []
  for line in f.readlines():
    strippedLine = line.strip()
    if strippedLine:
      result.append(strippedLine)
  f.close()
  return result

def writeConfiguration(lines):
  f = open(CONFIG_NAME, "w")
  f.writelines(lines)
  f.close()

def parseArguments(arguments):
  nextIsInclude = False
  nextIsDefine = False
  nextIsIncludeFile = False
  nextIsIsystem = False

  includes = []
  defines = []
  include_file = []
  options = []
  isystem = []

  for arg in arguments:
    if nextIsInclude:
      includes += [arg]
      nextIsInclude = False
    elif nextIsDefine:
      defines += [arg]
      nextIsDefine = False
    elif nextIsIncludeFile:
      include_file += [arg]
      nextIsIncludeFile = False
    elif nextIsIsystem:
      isystem += [arg]
      nextIsIsystem = False
    elif arg == "-I":
      nextIsInclude = True
    elif arg == "-D":
      nextIsDefine = True
    elif arg[:2] == "-I":
      includes += [arg[2:]]
    elif arg[:2] == "-D":
      defines += [arg[2:]]
    elif arg == "-include":
      nextIsIncludeFile = True
    elif arg == "-isystem":
      nextIsIsystem = True
    elif arg.startswith('-std='):
      options.append(arg)
    elif arg == '-ansi':
      options.append(arg)
    elif arg.startswith('-pedantic'):
      options.append(arg)
    elif arg.startswith('-W'):
      options.append(arg)

  result = list(map(lambda x: "-I" + x, includes))
  result.extend(map(lambda x: "-D" + x, defines))
  result.extend(map(lambda x: "-include " + x, include_file))
  result.extend(map(lambda x: "-isystem" + x, isystem))
  result.extend(options)

  return result

def mergeLists(base, new):
  result = list(base)
  for newLine in new:
    if newLine not in result:
      result.append(newLine)
  return result

configuration = readConfiguration()
args = parseArguments(sys.argv)
result = mergeLists(configuration, args)
writeConfiguration(map(lambda x: x + "\n", result))


import subprocess
proc = subprocess.Popen(sys.argv[1:])
ret = proc.wait()

if ret is None:
  sys.exit(1)
sys.exit(ret)

# vim: set ts=2 sts=2 sw=2 expandtab :
bin/generate_kinds.py	[[[1
87
#!/usr/bin/env python
#-*- coding: utf-8 -*-

import re
import sys
import os.path
import clang.cindex

# you can use this dictionary to map some kinds to better
# textual representation than just the number
mapping = {
    1 : 't' ,  # CXCursor_UnexposedDecl (A declaration whose specific kind is not
               # exposed via this interface)
    2 : 't' ,  # CXCursor_StructDecl (A C or C++ struct)
    3 : 't' ,  # CXCursor_UnionDecl (A C or C++ union)
    4 : 't' ,  # CXCursor_ClassDecl (A C++ class)
    5 : 't' ,  # CXCursor_EnumDecl (An enumeration)
    6 : 'm' ,  # CXCursor_FieldDecl (A field (in C) or non-static data member
               # (in C++) in a struct, union, or C++ class)
    7 : 'e' ,  # CXCursor_EnumConstantDecl (An enumerator constant)
    8 : 'f' ,  # CXCursor_FunctionDecl (A function)
    9 : 'v' ,  # CXCursor_VarDecl (A variable)
   10 : 'a' ,  # CXCursor_ParmDecl (A function or method parameter)
   20 : 't' ,  # CXCursor_TypedefDecl (A typedef)
   21 : 'f' ,  # CXCursor_CXXMethod (A C++ class method)
   22 : 'n' ,  # CXCursor_Namespace (A C++ namespace)
   24 : '+' ,  # CXCursor_Constructor (A C++ constructor)
   25 : '~' ,  # CXCursor_Destructor (A C++ destructor)
   27 : 'a' ,  # CXCursor_TemplateTypeParameter (A C++ template type parameter)
   28 : 'a' ,  # CXCursor_NonTypeTemplateParameter (A C++ non-type template
               # parameter)
   29 : 'a' ,  # CXCursor_TemplateTemplateParameter (A C++ template template
               # parameter)
   30 : 'f' ,  # CXCursor_FunctionTemplate (A C++ function template)
   31 : 'p' ,  # CXCursor_ClassTemplate (A C++ class template)
   33 : 'n' ,  # CXCursor_NamespaceAlias (A C++ namespace alias declaration)
   36 : 't' ,  # CXCursor_TypeAliasDecl (A C++ alias declaration)
   72 : 'u' ,  # CXCursor_NotImplemented
  501 : 'd' ,  # CXCursor_MacroDefinition
  601 : 'ta',  # CXCursor_TypeAliasTemplateDecl (Template alias declaration).
  700 : 'oc',  # CXCursor_OverloadCandidate A code completion overload candidate.
}

if len(sys.argv) != 2:
  print("Usage:", sys.argv[0], "<path-to-Index.h>")
  exit(-1)

index = clang.cindex.Index.create()
tu = index.parse(sys.argv[1])

kinds = None
for child in tu.cursor.get_children():
  if (child.spelling == "CXCursorKind"):
    kinds = child
    break
else:
  print("Index.h doesn't contain CXCursorKind where it is expected, please report a bug.")
  exit(-1)

kinds_py_path = os.path.join(
  os.path.dirname(
    os.path.dirname(
      os.path.abspath(__file__)
    )
  ),
  "plugin",
  "kinds.py"
)

with open(kinds_py_path, "w") as f:
  # First/Last pattern
  fl = re.compile("CXCursor_(First|Last)[A-Z].*")

  f.write("# !! GENERATED FILE, DO NOT EDIT\n")
  f.write("kinds = {\n")

  for kind in kinds.get_children():
    # filter out First/Last markers from the enum
    if fl.match(kind.spelling) is not None:
      continue

    text = mapping.get(kind.enum_value, kind.enum_value)
    f.write("{0} : '{1}', # {2} {3}\n".format(kind.enum_value, text, kind.spelling, kind.brief_comment))

  f.write("}\n")

# vim: set ts=2 sts=2 sw=2 expandtab :
doc/clang_complete.txt	[[[1
404
*clang_complete.txt*	For Vim version 7.3.  Last change: 2016 Sep 24


		  clang_complete plugin documentation


clang_complete plugin		      		*clang_complete*

1. Description		|clang_complete-description|
2. Key bindings		|clang_complete-keybindings|
3. Completion kinds    	|clang_complete-compl_kinds|
4. Configuration	|clang_complete-configuration|
5. Options		|clang_complete-options|
6. Known issues		|clang_complete-issues|
7. cc_args.py script	|clang_complete-cc_args|
8. To do		|clang_complete-todo|
9. FAQ			|clang_complete-faq|
10. License		|clang_complete-license|

Author: Xavier Deguillard <deguilx@gmail.com>	*clang_complete-author*

==============================================================================
1. Description 					*clang_complete-description*

This plugin use clang for accurately completing C and C++ code.

Note: This plugin is incompatible with omnicppcomplete due to the
unconditionnaly set mapping done by omnicppcomplete. So don't forget to
suppress it before using this plugin. Also it's possible to keep
omnicppcomplete plugin enabled by setting |g:clang_omnicppcomplete_compliance|.
in this case it will be possible to use omnicppcomplete in parallel with
clang_complete, though functionality of the latter will be reduced to
<C-X><C-U> only.

==============================================================================
2. Key bindings					*clang_complete-keybindings*

Completion is started with CTRL-X CTRL-U |i_CTRL-X_CTRL-U|, or automatically
depending on the value of |clang_complete-auto|.

You can also jump to the declaration of the symbol under the cursor with
<CTRL-]>. Jumping back is done with <CTRL-T>. Since clang_complete uses
|jumplist|, you can navigate through the jumps with <CTRL-O> and <CTRL-I>

==============================================================================
3. Completion kinds    				*clang_complete-compl_kinds*

Because libclang provides a lot of information about completion, there are
some additional kinds of completion along with standard ones (see
|complete-items| for details):
 '+' - constructor
 '~' - destructor
 'e' - enumerator constant
 'a' - parameter ('a' from "argument") of a function, method or template
 'u' - unknown or buildin type (int, float, ...)
 'n' - namespace or its alias
 'p' - template ('p' from "pattern")

==============================================================================
4. Configuration				*clang_complete-configuration*

Each project can have a .clang_complete at its root, containing the compiler
options. This is useful if you're using some non-standard include paths or
need to specify particular architecture type, frameworks to use, path to
precompiled headers, precompiler definitions etc.

Note that as with other option sources, .clang_complete file is loaded and
parsed by the plugin only on buffer loading (or reloading, for example with
:edit! command). Thus no changes made to .clang_complete file after loading
source file into Vim's buffer will take effect until buffer will be closed and
opened again, reloaded or Vim is restarted.

Compiler options should go on individual lines (multiple options on one line
can work sometimes too, but since there are some not obvious conditions for
that, it's better to have one option per line).

Linking isn't performed during completion, so one doesn't need to specify any
of linker arguments in .clang_complete file. They will lead to completion
failure when using clang executable and will be completely ignored by
libclang.

Example .clang_complete file: >
 -DDEBUG
 -include ../config.h
 -I../common
 -I/usr/include/c++/4.5.3/
 -I/usr/include/c++/4.5.3/x86_64-slackware-linux/
<
==============================================================================
5. Options					*clang_complete-options*

					*clang_complete-loaded*
					*g:clang_complete_loaded*
If set, clang_complete won't be loaded.
Default: unset.

       				       	*clang_complete-auto_select*
				       	*g:clang_auto_select*
If equal to 0, nothing is selected.
If equal to 1, automatically select the first entry in the popup menu, but
without inserting it into the code.
If equal to 2, automatically select the first entry in the popup menu, and
insert it into the code.
Default: 0

       				       	*clang_complete-complete_auto*
       				       	*g:clang_complete_auto*
If equal to 1, automatically complete after ->, ., ::
Default: 1

       				       	*clang_complete-copen*
       				       	*g:clang_complete_copen*
If equal to 1, open quickfix window on error.
Default: 0

       				       	*clang_complete-hl_errors*
       				       	*g:clang_hl_errors*
If equal to 1, it will highlight the warnings and errors the same way clang
does it.
Default: 1

       				       	*clang_complete-periodic_quickfix*
       				       	*g:clang_periodic_quickfix*
If equal to 1, it will periodically update the quickfix window.
Default: 0
Note: You could use the g:ClangUpdateQuickFix() to do the same with a mapping.

       				       	*clang_complete-snippets*
       				       	*g:clang_snippets*
If equal to 1, it will do some snippets magic on code placeholders like
function argument, template parameters, etc.
Default: 0

				       	*clang_complete-snippets_engine*
				       	*g:clang_snippets_engine*
The snippets engine (clang_complete, ultisnips... see the snippets
subdirectory).
Default: "clang_complete"

       				       	*clang_complete-conceal_snippets*
       				       	*g:clang_conceal_snippets*
Note: This option is specific to clang_complete snippets engine.
If equal to 1, clang_complete will use vim 7.3 conceal feature to hide the
snippet placeholders.

Example of conceal configuration (see |'concealcursor'| and |'conceallevel'|
for details): >
 " conceal in insert (i), normal (n) and visual (v) modes
 set concealcursor=inv
 " hide concealed text completely unless replacement character is defined
 set conceallevel=2

Default: 1 (0 if conceal not available)

       				       	*clang_complete-optional_args_in_snippets*
       				       	*g:clang_complete_optional_args_in_snippets*
If equal to 1, it will add optional arguments to the function call snippet.
Snippet replaceable object will not be only the argument, but the preceding
comma will be included as well, so you can press backspace to delete the
optional argument, while the replaceable is selected.
Example: foo($`T param1`, $`T param2`$`, T optional_param`)
Default: 0

       				       	*clang_complete-clang_trailing_placeholder*
       				       	*g:clang_trailing_placeholder*
Note: This option is specific to clang_complete snippets engine.
If equal to 1, clang_complete will add a trailing placeholder after functions
to let you add you continue writing code faster.
Default: 0

       				       	*clang_complete-clang_restore_cr_imap*
       				       	*g:clang_restore_cr_imap*
This option is used for versions of Vim without the Dictionary version of
|maparg()| introduced in 7.3.32. The variable is executed after completion to
restore the insert-mode map of <CR>. Occurrences of "<SID>" in the variable
are replaced with the appropriate "<SNR>" code based on the original map.
Default: 'iunmap <buffer> <CR>'

       				       	*clang_close-preview*
       				       	*g:clang_close_preview*
If equal to 1, the preview window will be close automatically after a
completion.
Default: 0

       				      	*clang_complete-user_options*
       				       	*g:clang_user_options*
Additional compilation argument passed to libclang.

Example: >
 " compile all sources as c++11 (just for example, use .clang_complete for
 " setting version of the language per project)
 let g:clang_user_options = '-std=c++11'
<
Default: ""

       				       	*clang_complete-auto_user_options*
       				       	*g:clang_auto_user_options*
Set sources for user options passed to clang. Available sources are:
- path - use &path content as list of include directories (relative paths are
  ignored);
- .clang_complete - use information from .clang_complete file Multiple options
  are separated by comma;
- compile_commands.json - get the compilation arguments for the sources from a
  compilation database. For example, recent versions of CMake (>=2.8.7) can
  output this information. clang_complete will search upwards from where vi
  was started for a database named 'compile_commands.json'.
  Note : compilation databases can only be used when 'g:clang_use_library'
  equals 1 and the clang libraries are recent enough (clang>=3.2). The 
  compilation database only contains information for the C/C++ sources files,
  so when editing a header, clang_complete will reuse the compilation
  arguments from the last file found in the database.
- {anything} else will be treaded as a custom option source in the following
  manner: clang_complete will try to load the autoload-function named
  getopts#{anything}#getopts, which then will be able to modify
  b:clang_user_options variable. See help on |autoload| if you don't know
  what it is.

This option is processed and all sources are used on buffer loading, not each
time before doing completion.

Default: ".clang_complete, path"

                                        *clang_complete-compilation_database*
                                        *g:clang_compilation_database*
By default, clang_complete will search upwards from where it was started to
find a compilation database. In case this behaviour does not match your needs,
you can set |g:clang_compilation_database| to the directory where the database
can be loaded from.

       				       	*clang_complete-use_library*
       				       	*g:clang_use_library*
Instead of calling the clang/clang++ tool use libclang directly. This gives
access to many more clang features. Furthermore it automatically caches all
includes in memory. Updates after changes in the same file will therefore be a
lot faster.
Note: This version doesn't support calling clang binary for completion. If you
cannot use libclang, you should download clang_complete from vim.org website.
Default: 1

       				       	*clang_complete-library_path*
       				       	*g:clang_library_path*
If libclang is not in the library search path of your system, you should set
this variable to the absolute path of either directory containing
libclang.{dll,so,dylib} (for Windows, Unix variants and OS X respectively) or
to that file itself.
Default: ""

Example: >
 " path to directory where library can be found
 let g:clang_library_path='/usr/lib/llvm-3.8/lib'
 " or path directly to the library file
 let g:clang_library_path='/usr/lib64/libclang.so.3.8'
<
					*clang_complete-sort_algo*
					*g:clang_sort_algo*
How results are sorted (alpha, priority, none). Currently only works with
libclang.
Default: "priority"

					*clang_complete-complete_macros*
					*g:clang_complete_macros*
If clang should complete preprocessor macros and constants.
Default: 0

					*clang_complete-complete_patterns*
					*g:clang_complete_patterns*
If clang should complete code patterns, i.e loop constructs etc.
Default: 0

					*clang_complete-jumpto_declaration_key*
					*g:clang_jumpto_declaration_key*
Set the key used to jump to declaration.
Default: "<C-]>"
Note: You could use the g:ClangGotoDeclaration() to do the same with a mapping.

					*clang_complete-jumpto_declaration_in_preview_key*
					*g:clang_jumpto_declaration_in_preview_key*
Set the key used to jump to declaration in a preview window.
Default: "<C-W>]"
Note: You could use the g:ClangGotoDeclarationPreview() to do the same with a mapping.

					*clang_complete-jumpto_back_key*
					*g:clang_jumpto_back_key*
Set the key used to jump back.
Note: Effectively this will be remapped to <C-O>. The default value is chosen
to be coherent with ctags implementation.
Default: "<C-T>"

					*clang_complete-make_default_keymappings*
					*g:clang_make_default_keymappings*
If this option is set, the default keymappings will be set by clang_complete.
Otherwise none are set and the user will have to provide those keymappings.
Default: 1

					*clang_complete-omnicppcomplete_compliance*
					*g:clang_omnicppcomplete_compliance*
Omnicppcomplete compatibility mode. Keeps omni auto-completion in control of
omnicppcomplete, disables clang's auto-completion (|g:clang_complete_auto|)
and enables only <C-X><C-U> as main clang completion function.
Default: 0

==============================================================================
6. Known issues					*clang_complete-issues*

If you get following error message while trying to complete anything: >
 E121: Undefined variable: b:should_overload
it means that your version of Vim is too old (this is an old bug and it has
been fixed with one of patches for Vim 7.2) and you need to update it.

Ubuntu users may need to install libclang-dev: >
 apt-get install libclang-dev

==============================================================================
7. cc_args.py script				*clang_complete-cc_args*

This script, installed at ~/.vim/bin/cc_args.py, could be used to generate or
update the .clang_complete file. It works similar to gccsence's gccrec and
simply stores -I and -D arguments passed to the compiler in the
.clang_complete file.  Just add the cc_args.py script as the first argument of
the compile command. You should do that every time compile options have
changed.

Example (we need -B flag to force compiling even if project is up to date): >
 make CC='~/.vim/bin/cc_args.py gcc' CXX='~/.vim/bin/cc_args.py g++' -B
After running this command, .clang_complete will be created or updated with
new options. If you don't want to update an existing configuration file,
delete it before running make.

==============================================================================
8. To do					*clang_complete-todo*

- Write some unit tests
- Explore "jump to declaration/definition" with libclang FGJ
- Think about supertab (<C-X><C-U> with supertab and clang_auto_select)

==============================================================================
9. FAQ						*clang_complete-faq*

*) clang_complete doesn't work! I always get the message "pattern not found".

This can have multiple reasons. You can try to open the quickfix window
(:copen) that displays the error messages from clang to get a better idea what
goes on. It might be that you need to update your .clang_complete file. If
this does not help, keep in mind that clang_complete can cause clang to search
for header files first in the system-wide paths and then in the ones specified
locally in .clang_complete. Therefore you might have to add "-nostdinc" and
the system include paths in the right order to .clang_complete.

*) Only function names get completed but not the parentheses/parameters.

Enable the snippets-support by adding the following lines to your .vimrc,
for example:

let g:clang_snippets = 1
let g:clang_snippets_engine = 'clang_complete'

If you have ultisnips installed, you can use

let g:clang_snippets = 1
let g:clang_snippets_engine = 'ultisnips'

instead. After a completetion you can use <Tab> in normal mode to jump to the
next parameter.

*) Can I configure clang_complete to insert the text automatically when there
   is only one possibility?

You can configure vim to complete automatically the longest common match by
adding the following line to your vimrc:

set completeopt=menu,longest

==============================================================================
10. License					*clang_complete-license*

Copyright (c) 2010, 2011, 2012, 2013 Xavier Deguillard, Tobias Grosser
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holders nor the names of their
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Note: This license does not cover the files that come from the LLVM project,
namely, cindex.py and __init__.py, which are covered by the LLVM license.

 vim:tw=78:ts=8:ft=help:norl:
plugin/clang/__init__.py	[[[1
24
#===- __init__.py - Clang Python Bindings --------------------*- python -*--===#
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
#===------------------------------------------------------------------------===#

r"""
Clang Library Bindings
======================

This package provides access to the Clang compiler and libraries.

The available modules are:

  cindex

    Bindings for the Clang indexing library.
"""

__all__ = ['cindex']

plugin/clang/cindex.py	[[[1
3219
#===- cindex.py - Python Indexing Library Bindings -----------*- python -*--===#
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
#===------------------------------------------------------------------------===#

r"""
Clang Indexing Library Bindings
===============================

This module provides an interface to the Clang indexing library. It is a
low-level interface to the indexing library which attempts to match the Clang
API directly while also being "pythonic". Notable differences from the C API
are:

 * string results are returned as Python strings, not CXString objects.

 * null cursors are translated to None.

 * access to child cursors is done via iteration, not visitation.

The major indexing objects are:

  Index

    The top-level object which manages some global library state.

  TranslationUnit

    High-level object encapsulating the AST for a single translation unit. These
    can be loaded from .ast files or parsed on the fly.

  Cursor

    Generic object for representing a node in the AST.

  SourceRange, SourceLocation, and File

    Objects representing information about the input source.

Most object information is exposed using properties, when the underlying API
call is efficient.
"""

# TODO
# ====
#
# o API support for invalid translation units. Currently we can't even get the
#   diagnostics on failure because they refer to locations in an object that
#   will have been invalidated.
#
# o fix memory management issues (currently client must hold on to index and
#   translation unit, or risk crashes).
#
# o expose code completion APIs.
#
# o cleanup ctypes wrapping, would be nice to separate the ctypes details more
#   clearly, and hide from the external interface (i.e., help(cindex)).
#
# o implement additional SourceLocation, SourceRange, and File methods.

from ctypes import *
from ctypes.util import find_library
import collections

import clang.enumerations

# ctypes doesn't implicitly convert c_void_p to the appropriate wrapper
# object. This is a problem, because it means that from_parameter will see an
# integer and pass the wrong value on platforms where int != void*. Work around
# this by marshalling object arguments as void**.
c_object_p = POINTER(c_void_p)

callbacks = {}

def encode(value):
    import sys
    if sys.version_info[0] == 2:
        return value

    try:
        return value.encode('utf-8')
    except AttributeError:
        return value

### Exception Classes ###

class TranslationUnitLoadError(Exception):
    """Represents an error that occurred when loading a TranslationUnit.

    This is raised in the case where a TranslationUnit could not be
    instantiated due to failure in the libclang library.

    FIXME: Make libclang expose additional error information in this scenario.
    """
    pass

class TranslationUnitSaveError(Exception):
    """Represents an error that occurred when saving a TranslationUnit.

    Each error has associated with it an enumerated value, accessible under
    e.save_error. Consumers can compare the value with one of the ERROR_
    constants in this class.
    """

    # Indicates that an unknown error occurred. This typically indicates that
    # I/O failed during save.
    ERROR_UNKNOWN = 1

    # Indicates that errors during translation prevented saving. The errors
    # should be available via the TranslationUnit's diagnostics.
    ERROR_TRANSLATION_ERRORS = 2

    # Indicates that the translation unit was somehow invalid.
    ERROR_INVALID_TU = 3

    def __init__(self, enumeration, message):
        assert isinstance(enumeration, int)

        if enumeration < 1 or enumeration > 3:
            raise Exception("Encountered undefined TranslationUnit save error "
                            "constant: %d. Please file a bug to have this "
                            "value supported." % enumeration)

        self.save_error = enumeration
        Exception.__init__(self, 'Error %d: %s' % (enumeration, message))

### Structures and Utility Classes ###

class CachedProperty(object):
    """Decorator that lazy-loads the value of a property.

    The first time the property is accessed, the original property function is
    executed. The value it returns is set as the new value of that instance's
    property, replacing the original method.
    """

    def __init__(self, wrapped):
        self.wrapped = wrapped
        try:
            self.__doc__ = wrapped.__doc__
        except:
            pass

    def __get__(self, instance, instance_type=None):
        if instance is None:
            return self

        value = self.wrapped(instance)
        setattr(instance, self.wrapped.__name__, value)

        return value


class _CXString(Structure):
    """Helper for transforming CXString results."""

    _fields_ = [("spelling", c_char_p), ("free", c_int)]

    def __del__(self):
        conf.lib.clang_disposeString(self)

    @staticmethod
    def from_result(res, fn, args):
        assert isinstance(res, _CXString)
        return conf.lib.clang_getCString(res)

class SourceLocation(Structure):
    """
    A SourceLocation represents a particular location within a source file.
    """
    _fields_ = [("ptr_data", c_void_p * 2), ("int_data", c_uint)]
    _data = None

    def _get_instantiation(self):
        if self._data is None:
            f, l, c, o = c_object_p(), c_uint(), c_uint(), c_uint()
            conf.lib.clang_getInstantiationLocation(self, byref(f), byref(l),
                    byref(c), byref(o))
            if f:
                f = File(f)
            else:
                f = None
            self._data = (f, int(l.value), int(c.value), int(o.value))
        return self._data

    @staticmethod
    def from_position(tu, file, line, column):
        """
        Retrieve the source location associated with a given file/line/column in
        a particular translation unit.
        """
        return conf.lib.clang_getLocation(tu, file, line, column)

    @staticmethod
    def from_offset(tu, file, offset):
        """Retrieve a SourceLocation from a given character offset.

        tu -- TranslationUnit file belongs to
        file -- File instance to obtain offset from
        offset -- Integer character offset within file
        """
        return conf.lib.clang_getLocationForOffset(tu, file, offset)

    @property
    def file(self):
        """Get the file represented by this source location."""
        return self._get_instantiation()[0]

    @property
    def line(self):
        """Get the line represented by this source location."""
        return self._get_instantiation()[1]

    @property
    def column(self):
        """Get the column represented by this source location."""
        return self._get_instantiation()[2]

    @property
    def offset(self):
        """Get the file offset represented by this source location."""
        return self._get_instantiation()[3]

    def __eq__(self, other):
        return conf.lib.clang_equalLocations(self, other)

    def __ne__(self, other):
        return not self.__eq__(other)

    def __repr__(self):
        if self.file:
            filename = self.file.name
        else:
            filename = None
        return "<SourceLocation file %r, line %r, column %r>" % (
            filename, self.line, self.column)

class SourceRange(Structure):
    """
    A SourceRange describes a range of source locations within the source
    code.
    """
    _fields_ = [
        ("ptr_data", c_void_p * 2),
        ("begin_int_data", c_uint),
        ("end_int_data", c_uint)]

    # FIXME: Eliminate this and make normal constructor? Requires hiding ctypes
    # object.
    @staticmethod
    def from_locations(start, end):
        return conf.lib.clang_getRange(start, end)

    @property
    def start(self):
        """
        Return a SourceLocation representing the first character within a
        source range.
        """
        return conf.lib.clang_getRangeStart(self)

    @property
    def end(self):
        """
        Return a SourceLocation representing the last character within a
        source range.
        """
        return conf.lib.clang_getRangeEnd(self)

    def __eq__(self, other):
        return conf.lib.clang_equalRanges(self, other)

    def __ne__(self, other):
        return not self.__eq__(other)

    def __repr__(self):
        return "<SourceRange start %r, end %r>" % (self.start, self.end)

class Diagnostic(object):
    """
    A Diagnostic is a single instance of a Clang diagnostic. It includes the
    diagnostic severity, the message, the location the diagnostic occurred, as
    well as additional source ranges and associated fix-it hints.
    """

    Ignored = 0
    Note    = 1
    Warning = 2
    Error   = 3
    Fatal   = 4

    def __init__(self, ptr):
        self.ptr = ptr

    def __del__(self):
        conf.lib.clang_disposeDiagnostic(self)

    @property
    def severity(self):
        return conf.lib.clang_getDiagnosticSeverity(self)

    @property
    def location(self):
        return conf.lib.clang_getDiagnosticLocation(self)

    @property
    def spelling(self):
        return conf.lib.clang_getDiagnosticSpelling(self)

    @property
    def ranges(self):
        class RangeIterator:
            def __init__(self, diag):
                self.diag = diag

            def __len__(self):
                return int(conf.lib.clang_getDiagnosticNumRanges(self.diag))

            def __getitem__(self, key):
                if (key >= len(self)):
                    raise IndexError
                return conf.lib.clang_getDiagnosticRange(self.diag, key)

        return RangeIterator(self)

    @property
    def fixits(self):
        class FixItIterator:
            def __init__(self, diag):
                self.diag = diag

            def __len__(self):
                return int(conf.lib.clang_getDiagnosticNumFixIts(self.diag))

            def __getitem__(self, key):
                range = SourceRange()
                value = conf.lib.clang_getDiagnosticFixIt(self.diag, key,
                        byref(range))
                if len(value) == 0:
                    raise IndexError

                return FixIt(range, value)

        return FixItIterator(self)

    @property
    def category_number(self):
        """The category number for this diagnostic."""
        return conf.lib.clang_getDiagnosticCategory(self)

    @property
    def category_name(self):
        """The string name of the category for this diagnostic."""
        return conf.lib.clang_getDiagnosticCategoryName(self.category_number)

    @property
    def option(self):
        """The command-line option that enables this diagnostic."""
        return conf.lib.clang_getDiagnosticOption(self, None)

    @property
    def disable_option(self):
        """The command-line option that disables this diagnostic."""
        disable = _CXString()
        conf.lib.clang_getDiagnosticOption(self, byref(disable))

        return conf.lib.clang_getCString(disable)

    def __repr__(self):
        return "<Diagnostic severity %r, location %r, spelling %r>" % (
            self.severity, self.location, self.spelling)

    def from_param(self):
      return self.ptr

class FixIt(object):
    """
    A FixIt represents a transformation to be applied to the source to
    "fix-it". The fix-it shouldbe applied by replacing the given source range
    with the given value.
    """

    def __init__(self, range, value):
        self.range = range
        self.value = value

    def __repr__(self):
        return "<FixIt range %r, value %r>" % (self.range, self.value)

class TokenGroup(object):
    """Helper class to facilitate token management.

    Tokens are allocated from libclang in chunks. They must be disposed of as a
    collective group.

    One purpose of this class is for instances to represent groups of allocated
    tokens. Each token in a group contains a reference back to an instance of
    this class. When all tokens from a group are garbage collected, it allows
    this class to be garbage collected. When this class is garbage collected,
    it calls the libclang destructor which invalidates all tokens in the group.

    You should not instantiate this class outside of this module.
    """
    def __init__(self, tu, memory, count):
        self._tu = tu
        self._memory = memory
        self._count = count

    def __del__(self):
        conf.lib.clang_disposeTokens(self._tu, self._memory, self._count)

    @staticmethod
    def get_tokens(tu, extent):
        """Helper method to return all tokens in an extent.

        This functionality is needed multiple places in this module. We define
        it here because it seems like a logical place.
        """
        tokens_memory = POINTER(Token)()
        tokens_count = c_uint()

        conf.lib.clang_tokenize(tu, extent, byref(tokens_memory),
                byref(tokens_count))

        count = int(tokens_count.value)

        # If we get no tokens, no memory was allocated. Be sure not to return
        # anything and potentially call a destructor on nothing.
        if count < 1:
            return

        tokens_array = cast(tokens_memory, POINTER(Token * count)).contents

        token_group = TokenGroup(tu, tokens_memory, tokens_count)

        for i in range(0, count):
            token = Token()
            token.int_data = tokens_array[i].int_data
            token.ptr_data = tokens_array[i].ptr_data
            token._tu = tu
            token._group = token_group

            yield token

class TokenKind(object):
    """Describes a specific type of a Token."""

    _value_map = {} # int -> TokenKind

    def __init__(self, value, name):
        """Create a new TokenKind instance from a numeric value and a name."""
        self.value = value
        self.name = name

    def __repr__(self):
        return 'TokenKind.%s' % (self.name,)

    @staticmethod
    def from_value(value):
        """Obtain a registered TokenKind instance from its value."""
        result = TokenKind._value_map.get(value, None)

        if result is None:
            raise ValueError('Unknown TokenKind: %d' % value)

        return result

    @staticmethod
    def register(value, name):
        """Register a new TokenKind enumeration.

        This should only be called at module load time by code within this
        package.
        """
        if value in TokenKind._value_map:
            raise ValueError('TokenKind already registered: %d' % value)

        kind = TokenKind(value, name)
        TokenKind._value_map[value] = kind
        setattr(TokenKind, name, kind)

### Cursor Kinds ###

class CursorKind(object):
    """
    A CursorKind describes the kind of entity that a cursor points to.
    """

    # The unique kind objects, indexed by id.
    _kinds = []
    _name_map = None

    def __init__(self, value):
        if value >= len(CursorKind._kinds):
            CursorKind._kinds += [None] * (value - len(CursorKind._kinds) + 1)
        if CursorKind._kinds[value] is not None:
            raise ValueError('CursorKind already loaded')
        self.value = value
        CursorKind._kinds[value] = self
        CursorKind._name_map = None

    def from_param(self):
        return self.value

    @property
    def name(self):
        """Get the enumeration name of this cursor kind."""
        if self._name_map is None:
            self._name_map = {}
            for key,value in CursorKind.__dict__.items():
                if isinstance(value,CursorKind):
                    self._name_map[value] = key
        return self._name_map[self]

    @staticmethod
    def from_id(id):
        if id >= len(CursorKind._kinds) or CursorKind._kinds[id] is None:
            raise ValueError('Unknown cursor kind')
        return CursorKind._kinds[id]

    @staticmethod
    def get_all_kinds():
        """Return all CursorKind enumeration instances."""
        return [_f for _f in CursorKind._kinds if _f]

    def is_declaration(self):
        """Test if this is a declaration kind."""
        return conf.lib.clang_isDeclaration(self)

    def is_reference(self):
        """Test if this is a reference kind."""
        return conf.lib.clang_isReference(self)

    def is_expression(self):
        """Test if this is an expression kind."""
        return conf.lib.clang_isExpression(self)

    def is_statement(self):
        """Test if this is a statement kind."""
        return conf.lib.clang_isStatement(self)

    def is_attribute(self):
        """Test if this is an attribute kind."""
        return conf.lib.clang_isAttribute(self)

    def is_invalid(self):
        """Test if this is an invalid kind."""
        return conf.lib.clang_isInvalid(self)

    def is_translation_unit(self):
        """Test if this is a translation unit kind."""
        return conf.lib.clang_isTranslationUnit(self)

    def is_preprocessing(self):
        """Test if this is a preprocessing kind."""
        return conf.lib.clang_isPreprocessing(self)

    def is_unexposed(self):
        """Test if this is an unexposed kind."""
        return conf.lib.clang_isUnexposed(self)

    def __repr__(self):
        return 'CursorKind.%s' % (self.name,)

# FIXME: Is there a nicer way to expose this enumeration? We could potentially
# represent the nested structure, or even build a class hierarchy. The main
# things we want for sure are (a) simple external access to kinds, (b) a place
# to hang a description and name, (c) easy to keep in sync with Index.h.

###
# Declaration Kinds

# A declaration whose specific kind is not exposed via this interface.
#
# Unexposed declarations have the same operations as any other kind of
# declaration; one can extract their location information, spelling, find their
# definitions, etc. However, the specific kind of the declaration is not
# reported.
CursorKind.UNEXPOSED_DECL = CursorKind(1)

# A C or C++ struct.
CursorKind.STRUCT_DECL = CursorKind(2)

# A C or C++ union.
CursorKind.UNION_DECL = CursorKind(3)

# A C++ class.
CursorKind.CLASS_DECL = CursorKind(4)

# An enumeration.
CursorKind.ENUM_DECL = CursorKind(5)

# A field (in C) or non-static data member (in C++) in a struct, union, or C++
# class.
CursorKind.FIELD_DECL = CursorKind(6)

# An enumerator constant.
CursorKind.ENUM_CONSTANT_DECL = CursorKind(7)

# A function.
CursorKind.FUNCTION_DECL = CursorKind(8)

# A variable.
CursorKind.VAR_DECL = CursorKind(9)

# A function or method parameter.
CursorKind.PARM_DECL = CursorKind(10)

# An Objective-C @interface.
CursorKind.OBJC_INTERFACE_DECL = CursorKind(11)

# An Objective-C @interface for a category.
CursorKind.OBJC_CATEGORY_DECL = CursorKind(12)

# An Objective-C @protocol declaration.
CursorKind.OBJC_PROTOCOL_DECL = CursorKind(13)

# An Objective-C @property declaration.
CursorKind.OBJC_PROPERTY_DECL = CursorKind(14)

# An Objective-C instance variable.
CursorKind.OBJC_IVAR_DECL = CursorKind(15)

# An Objective-C instance method.
CursorKind.OBJC_INSTANCE_METHOD_DECL = CursorKind(16)

# An Objective-C class method.
CursorKind.OBJC_CLASS_METHOD_DECL = CursorKind(17)

# An Objective-C @implementation.
CursorKind.OBJC_IMPLEMENTATION_DECL = CursorKind(18)

# An Objective-C @implementation for a category.
CursorKind.OBJC_CATEGORY_IMPL_DECL = CursorKind(19)

# A typedef.
CursorKind.TYPEDEF_DECL = CursorKind(20)

# A C++ class method.
CursorKind.CXX_METHOD = CursorKind(21)

# A C++ namespace.
CursorKind.NAMESPACE = CursorKind(22)

# A linkage specification, e.g. 'extern "C"'.
CursorKind.LINKAGE_SPEC = CursorKind(23)

# A C++ constructor.
CursorKind.CONSTRUCTOR = CursorKind(24)

# A C++ destructor.
CursorKind.DESTRUCTOR = CursorKind(25)

# A C++ conversion function.
CursorKind.CONVERSION_FUNCTION = CursorKind(26)

# A C++ template type parameter
CursorKind.TEMPLATE_TYPE_PARAMETER = CursorKind(27)

# A C++ non-type template paramater.
CursorKind.TEMPLATE_NON_TYPE_PARAMETER = CursorKind(28)

# A C++ template template parameter.
CursorKind.TEMPLATE_TEMPLATE_PARAMETER = CursorKind(29)

# A C++ function template.
CursorKind.FUNCTION_TEMPLATE = CursorKind(30)

# A C++ class template.
CursorKind.CLASS_TEMPLATE = CursorKind(31)

# A C++ class template partial specialization.
CursorKind.CLASS_TEMPLATE_PARTIAL_SPECIALIZATION = CursorKind(32)

# A C++ namespace alias declaration.
CursorKind.NAMESPACE_ALIAS = CursorKind(33)

# A C++ using directive
CursorKind.USING_DIRECTIVE = CursorKind(34)

# A C++ using declaration
CursorKind.USING_DECLARATION = CursorKind(35)

# A Type alias decl.
CursorKind.TYPE_ALIAS_DECL = CursorKind(36)

# A Objective-C synthesize decl
CursorKind.OBJC_SYNTHESIZE_DECL = CursorKind(37)

# A Objective-C dynamic decl
CursorKind.OBJC_DYNAMIC_DECL = CursorKind(38)

# A C++ access specifier decl.
CursorKind.CXX_ACCESS_SPEC_DECL = CursorKind(39)


###
# Reference Kinds

CursorKind.OBJC_SUPER_CLASS_REF = CursorKind(40)
CursorKind.OBJC_PROTOCOL_REF = CursorKind(41)
CursorKind.OBJC_CLASS_REF = CursorKind(42)

# A reference to a type declaration.
#
# A type reference occurs anywhere where a type is named but not
# declared. For example, given:
#   typedef unsigned size_type;
#   size_type size;
#
# The typedef is a declaration of size_type (CXCursor_TypedefDecl),
# while the type of the variable "size" is referenced. The cursor
# referenced by the type of size is the typedef for size_type.
CursorKind.TYPE_REF = CursorKind(43)
CursorKind.CXX_BASE_SPECIFIER = CursorKind(44)

# A reference to a class template, function template, template
# template parameter, or class template partial specialization.
CursorKind.TEMPLATE_REF = CursorKind(45)

# A reference to a namespace or namepsace alias.
CursorKind.NAMESPACE_REF = CursorKind(46)

# A reference to a member of a struct, union, or class that occurs in
# some non-expression context, e.g., a designated initializer.
CursorKind.MEMBER_REF = CursorKind(47)

# A reference to a labeled statement.
CursorKind.LABEL_REF = CursorKind(48)

# A reference toa a set of overloaded functions or function templates
# that has not yet been resolved to a specific function or function template.
CursorKind.OVERLOADED_DECL_REF = CursorKind(49)

###
# Invalid/Error Kinds

CursorKind.INVALID_FILE = CursorKind(70)
CursorKind.NO_DECL_FOUND = CursorKind(71)
CursorKind.NOT_IMPLEMENTED = CursorKind(72)
CursorKind.INVALID_CODE = CursorKind(73)

###
# Expression Kinds

# An expression whose specific kind is not exposed via this interface.
#
# Unexposed expressions have the same operations as any other kind of
# expression; one can extract their location information, spelling, children,
# etc. However, the specific kind of the expression is not reported.
CursorKind.UNEXPOSED_EXPR = CursorKind(100)

# An expression that refers to some value declaration, such as a function,
# varible, or enumerator.
CursorKind.DECL_REF_EXPR = CursorKind(101)

# An expression that refers to a member of a struct, union, class, Objective-C
# class, etc.
CursorKind.MEMBER_REF_EXPR = CursorKind(102)

# An expression that calls a function.
CursorKind.CALL_EXPR = CursorKind(103)

# An expression that sends a message to an Objective-C object or class.
CursorKind.OBJC_MESSAGE_EXPR = CursorKind(104)

# An expression that represents a block literal.
CursorKind.BLOCK_EXPR = CursorKind(105)

# An integer literal.
CursorKind.INTEGER_LITERAL = CursorKind(106)

# A floating point number literal.
CursorKind.FLOATING_LITERAL = CursorKind(107)

# An imaginary number literal.
CursorKind.IMAGINARY_LITERAL = CursorKind(108)

# A string literal.
CursorKind.STRING_LITERAL = CursorKind(109)

# A character literal.
CursorKind.CHARACTER_LITERAL = CursorKind(110)

# A parenthesized expression, e.g. "(1)".
#
# This AST node is only formed if full location information is requested.
CursorKind.PAREN_EXPR = CursorKind(111)

# This represents the unary-expression's (except sizeof and
# alignof).
CursorKind.UNARY_OPERATOR = CursorKind(112)

# [C99 6.5.2.1] Array Subscripting.
CursorKind.ARRAY_SUBSCRIPT_EXPR = CursorKind(113)

# A builtin binary operation expression such as "x + y" or
# "x <= y".
CursorKind.BINARY_OPERATOR = CursorKind(114)

# Compound assignment such as "+=".
CursorKind.COMPOUND_ASSIGNMENT_OPERATOR = CursorKind(115)

# The ?: ternary operator.
CursorKind.CONDITIONAL_OPERATOR = CursorKind(116)

# An explicit cast in C (C99 6.5.4) or a C-style cast in C++
# (C++ [expr.cast]), which uses the syntax (Type)expr.
#
# For example: (int)f.
CursorKind.CSTYLE_CAST_EXPR = CursorKind(117)

# [C99 6.5.2.5]
CursorKind.COMPOUND_LITERAL_EXPR = CursorKind(118)

# Describes an C or C++ initializer list.
CursorKind.INIT_LIST_EXPR = CursorKind(119)

# The GNU address of label extension, representing &&label.
CursorKind.ADDR_LABEL_EXPR = CursorKind(120)

# This is the GNU Statement Expression extension: ({int X=4; X;})
CursorKind.StmtExpr = CursorKind(121)

# Represents a C11 generic selection.
CursorKind.GENERIC_SELECTION_EXPR = CursorKind(122)

# Implements the GNU __null extension, which is a name for a null
# pointer constant that has integral type (e.g., int or long) and is the same
# size and alignment as a pointer.
#
# The __null extension is typically only used by system headers, which define
# NULL as __null in C++ rather than using 0 (which is an integer that may not
# match the size of a pointer).
CursorKind.GNU_NULL_EXPR = CursorKind(123)

# C++'s static_cast<> expression.
CursorKind.CXX_STATIC_CAST_EXPR = CursorKind(124)

# C++'s dynamic_cast<> expression.
CursorKind.CXX_DYNAMIC_CAST_EXPR = CursorKind(125)

# C++'s reinterpret_cast<> expression.
CursorKind.CXX_REINTERPRET_CAST_EXPR = CursorKind(126)

# C++'s const_cast<> expression.
CursorKind.CXX_CONST_CAST_EXPR = CursorKind(127)

# Represents an explicit C++ type conversion that uses "functional"
# notion (C++ [expr.type.conv]).
#
# Example:
# \code
#   x = int(0.5);
# \endcode
CursorKind.CXX_FUNCTIONAL_CAST_EXPR = CursorKind(128)

# A C++ typeid expression (C++ [expr.typeid]).
CursorKind.CXX_TYPEID_EXPR = CursorKind(129)

# [C++ 2.13.5] C++ Boolean Literal.
CursorKind.CXX_BOOL_LITERAL_EXPR = CursorKind(130)

# [C++0x 2.14.7] C++ Pointer Literal.
CursorKind.CXX_NULL_PTR_LITERAL_EXPR = CursorKind(131)

# Represents the "this" expression in C++
CursorKind.CXX_THIS_EXPR = CursorKind(132)

# [C++ 15] C++ Throw Expression.
#
# This handles 'throw' and 'throw' assignment-expression. When
# assignment-expression isn't present, Op will be null.
CursorKind.CXX_THROW_EXPR = CursorKind(133)

# A new expression for memory allocation and constructor calls, e.g:
# "new CXXNewExpr(foo)".
CursorKind.CXX_NEW_EXPR = CursorKind(134)

# A delete expression for memory deallocation and destructor calls,
# e.g. "delete[] pArray".
CursorKind.CXX_DELETE_EXPR = CursorKind(135)

# Represents a unary expression.
CursorKind.CXX_UNARY_EXPR = CursorKind(136)

# ObjCStringLiteral, used for Objective-C string literals i.e. "foo".
CursorKind.OBJC_STRING_LITERAL = CursorKind(137)

# ObjCEncodeExpr, used for in Objective-C.
CursorKind.OBJC_ENCODE_EXPR = CursorKind(138)

# ObjCSelectorExpr used for in Objective-C.
CursorKind.OBJC_SELECTOR_EXPR = CursorKind(139)

# Objective-C's protocol expression.
CursorKind.OBJC_PROTOCOL_EXPR = CursorKind(140)

# An Objective-C "bridged" cast expression, which casts between
# Objective-C pointers and C pointers, transferring ownership in the process.
#
# \code
#   NSString *str = (__bridge_transfer NSString *)CFCreateString();
# \endcode
CursorKind.OBJC_BRIDGE_CAST_EXPR = CursorKind(141)

# Represents a C++0x pack expansion that produces a sequence of
# expressions.
#
# A pack expansion expression contains a pattern (which itself is an
# expression) followed by an ellipsis. For example:
CursorKind.PACK_EXPANSION_EXPR = CursorKind(142)

# Represents an expression that computes the length of a parameter
# pack.
CursorKind.SIZE_OF_PACK_EXPR = CursorKind(143)

# A statement whose specific kind is not exposed via this interface.
#
# Unexposed statements have the same operations as any other kind of statement;
# one can extract their location information, spelling, children, etc. However,
# the specific kind of the statement is not reported.
CursorKind.UNEXPOSED_STMT = CursorKind(200)

# A labelled statement in a function.
CursorKind.LABEL_STMT = CursorKind(201)

# A compound statement
CursorKind.COMPOUND_STMT = CursorKind(202)

# A case statement.
CursorKind.CASE_STMT = CursorKind(203)

# A default statement.
CursorKind.DEFAULT_STMT = CursorKind(204)

# An if statement.
CursorKind.IF_STMT = CursorKind(205)

# A switch statement.
CursorKind.SWITCH_STMT = CursorKind(206)

# A while statement.
CursorKind.WHILE_STMT = CursorKind(207)

# A do statement.
CursorKind.DO_STMT = CursorKind(208)

# A for statement.
CursorKind.FOR_STMT = CursorKind(209)

# A goto statement.
CursorKind.GOTO_STMT = CursorKind(210)

# An indirect goto statement.
CursorKind.INDIRECT_GOTO_STMT = CursorKind(211)

# A continue statement.
CursorKind.CONTINUE_STMT = CursorKind(212)

# A break statement.
CursorKind.BREAK_STMT = CursorKind(213)

# A return statement.
CursorKind.RETURN_STMT = CursorKind(214)

# A GNU-style inline assembler statement.
CursorKind.ASM_STMT = CursorKind(215)

# Objective-C's overall @try-@catch-@finally statement.
CursorKind.OBJC_AT_TRY_STMT = CursorKind(216)

# Objective-C's @catch statement.
CursorKind.OBJC_AT_CATCH_STMT = CursorKind(217)

# Objective-C's @finally statement.
CursorKind.OBJC_AT_FINALLY_STMT = CursorKind(218)

# Objective-C's @throw statement.
CursorKind.OBJC_AT_THROW_STMT = CursorKind(219)

# Objective-C's @synchronized statement.
CursorKind.OBJC_AT_SYNCHRONIZED_STMT = CursorKind(220)

# Objective-C's autorealease pool statement.
CursorKind.OBJC_AUTORELEASE_POOL_STMT = CursorKind(221)

# Objective-C's for collection statement.
CursorKind.OBJC_FOR_COLLECTION_STMT = CursorKind(222)

# C++'s catch statement.
CursorKind.CXX_CATCH_STMT = CursorKind(223)

# C++'s try statement.
CursorKind.CXX_TRY_STMT = CursorKind(224)

# C++'s for (* : *) statement.
CursorKind.CXX_FOR_RANGE_STMT = CursorKind(225)

# Windows Structured Exception Handling's try statement.
CursorKind.SEH_TRY_STMT = CursorKind(226)

# Windows Structured Exception Handling's except statement.
CursorKind.SEH_EXCEPT_STMT = CursorKind(227)

# Windows Structured Exception Handling's finally statement.
CursorKind.SEH_FINALLY_STMT = CursorKind(228)

# The null statement.
CursorKind.NULL_STMT = CursorKind(230)

# Adaptor class for mixing declarations with statements and expressions.
CursorKind.DECL_STMT = CursorKind(231)

###
# Other Kinds

# Cursor that represents the translation unit itself.
#
# The translation unit cursor exists primarily to act as the root cursor for
# traversing the contents of a translation unit.
CursorKind.TRANSLATION_UNIT = CursorKind(300)

###
# Attributes

# An attribute whoe specific kind is note exposed via this interface
CursorKind.UNEXPOSED_ATTR = CursorKind(400)

CursorKind.IB_ACTION_ATTR = CursorKind(401)
CursorKind.IB_OUTLET_ATTR = CursorKind(402)
CursorKind.IB_OUTLET_COLLECTION_ATTR = CursorKind(403)

CursorKind.CXX_FINAL_ATTR = CursorKind(404)
CursorKind.CXX_OVERRIDE_ATTR = CursorKind(405)
CursorKind.ANNOTATE_ATTR = CursorKind(406)
CursorKind.ASM_LABEL_ATTR = CursorKind(407)

###
# Preprocessing
CursorKind.PREPROCESSING_DIRECTIVE = CursorKind(500)
CursorKind.MACRO_DEFINITION = CursorKind(501)
CursorKind.MACRO_INSTANTIATION = CursorKind(502)
CursorKind.INCLUSION_DIRECTIVE = CursorKind(503)

### Cursors ###

class Cursor(Structure):
    """
    The Cursor class represents a reference to an element within the AST. It
    acts as a kind of iterator.
    """
    _fields_ = [("_kind_id", c_int), ("xdata", c_int), ("data", c_void_p * 3)]

    @staticmethod
    def from_location(tu, location):
        # We store a reference to the TU in the instance so the TU won't get
        # collected before the cursor.
        cursor = conf.lib.clang_getCursor(tu, location)
        cursor._tu = tu

        return cursor

    def __eq__(self, other):
        return conf.lib.clang_equalCursors(self, other)

    def __ne__(self, other):
        return not self.__eq__(other)

    def is_definition(self):
        """
        Returns true if the declaration pointed at by the cursor is also a
        definition of that entity.
        """
        return conf.lib.clang_isCursorDefinition(self)

    def is_static_method(self):
        """Returns True if the cursor refers to a C++ member function or member
        function template that is declared 'static'.
        """
        return conf.lib.clang_CXXMethod_isStatic(self)

    def get_definition(self):
        """
        If the cursor is a reference to a declaration or a declaration of
        some entity, return a cursor that points to the definition of that
        entity.
        """
        # TODO: Should probably check that this is either a reference or
        # declaration prior to issuing the lookup.
        return conf.lib.clang_getCursorDefinition(self)

    def get_usr(self):
        """Return the Unified Symbol Resultion (USR) for the entity referenced
        by the given cursor (or None).

        A Unified Symbol Resolution (USR) is a string that identifies a
        particular entity (function, class, variable, etc.) within a
        program. USRs can be compared across translation units to determine,
        e.g., when references in one translation refer to an entity defined in
        another translation unit."""
        return conf.lib.clang_getCursorUSR(self)

    @property
    def kind(self):
        """Return the kind of this cursor."""
        return CursorKind.from_id(self._kind_id)

    @property
    def spelling(self):
        """Return the spelling of the entity pointed at by the cursor."""
        if not self.kind.is_declaration():
            # FIXME: clang_getCursorSpelling should be fixed to not assert on
            # this, for consistency with clang_getCursorUSR.
            return None
        if not hasattr(self, '_spelling'):
            self._spelling = conf.lib.clang_getCursorSpelling(self)

        return self._spelling

    @property
    def displayname(self):
        """
        Return the display name for the entity referenced by this cursor.

        The display name contains extra information that helps identify the cursor,
        such as the parameters of a function or template or the arguments of a
        class template specialization.
        """
        if not hasattr(self, '_displayname'):
            self._displayname = conf.lib.clang_getCursorDisplayName(self)

        return self._displayname

    @property
    def location(self):
        """
        Return the source location (the starting character) of the entity
        pointed at by the cursor.
        """
        if not hasattr(self, '_loc'):
            self._loc = conf.lib.clang_getCursorLocation(self)

        return self._loc

    @property
    def extent(self):
        """
        Return the source range (the range of text) occupied by the entity
        pointed at by the cursor.
        """
        if not hasattr(self, '_extent'):
            self._extent = conf.lib.clang_getCursorExtent(self)

        return self._extent

    @property
    def type(self):
        """
        Retrieve the Type (if any) of the entity pointed at by the cursor.
        """
        if not hasattr(self, '_type'):
            self._type = conf.lib.clang_getCursorType(self)

        return self._type

    @property
    def canonical(self):
        """Return the canonical Cursor corresponding to this Cursor.

        The canonical cursor is the cursor which is representative for the
        underlying entity. For example, if you have multiple forward
        declarations for the same class, the canonical cursor for the forward
        declarations will be identical.
        """
        if not hasattr(self, '_canonical'):
            self._canonical = conf.lib.clang_getCanonicalCursor(self)

        return self._canonical

    @property
    def result_type(self):
        """Retrieve the Type of the result for this Cursor."""
        if not hasattr(self, '_result_type'):
            self._result_type = conf.lib.clang_getResultType(self.type)

        return self._result_type

    @property
    def underlying_typedef_type(self):
        """Return the underlying type of a typedef declaration.

        Returns a Type for the typedef this cursor is a declaration for. If
        the current cursor is not a typedef, this raises.
        """
        if not hasattr(self, '_underlying_type'):
            assert self.kind.is_declaration()
            self._underlying_type = \
              conf.lib.clang_getTypedefDeclUnderlyingType(self)

        return self._underlying_type

    @property
    def enum_type(self):
        """Return the integer type of an enum declaration.

        Returns a Type corresponding to an integer. If the cursor is not for an
        enum, this raises.
        """
        if not hasattr(self, '_enum_type'):
            assert self.kind == CursorKind.ENUM_DECL
            self._enum_type = conf.lib.clang_getEnumDeclIntegerType(self)

        return self._enum_type

    @property
    def enum_value(self):
        """Return the value of an enum constant."""
        if not hasattr(self, '_enum_value'):
            assert self.kind == CursorKind.ENUM_CONSTANT_DECL
            # Figure out the underlying type of the enum to know if it
            # is a signed or unsigned quantity.
            underlying_type = self.type
            if underlying_type.kind == TypeKind.ENUM:
                underlying_type = underlying_type.get_declaration().enum_type
            if underlying_type.kind in (TypeKind.CHAR_U,
                                        TypeKind.UCHAR,
                                        TypeKind.CHAR16,
                                        TypeKind.CHAR32,
                                        TypeKind.USHORT,
                                        TypeKind.UINT,
                                        TypeKind.ULONG,
                                        TypeKind.ULONGLONG,
                                        TypeKind.UINT128):
                self._enum_value = \
                  conf.lib.clang_getEnumConstantDeclUnsignedValue(self)
            else:
                self._enum_value = conf.lib.clang_getEnumConstantDeclValue(self)
        return self._enum_value

    @property
    def objc_type_encoding(self):
        """Return the Objective-C type encoding as a str."""
        if not hasattr(self, '_objc_type_encoding'):
            self._objc_type_encoding = \
              conf.lib.clang_getDeclObjCTypeEncoding(self)

        return self._objc_type_encoding

    @property
    def hash(self):
        """Returns a hash of the cursor as an int."""
        if not hasattr(self, '_hash'):
            self._hash = conf.lib.clang_hashCursor(self)

        return self._hash

    @property
    def semantic_parent(self):
        """Return the semantic parent for this cursor."""
        if not hasattr(self, '_semantic_parent'):
            self._semantic_parent = conf.lib.clang_getCursorSemanticParent(self)

        return self._semantic_parent

    @property
    def lexical_parent(self):
        """Return the lexical parent for this cursor."""
        if not hasattr(self, '_lexical_parent'):
            self._lexical_parent = conf.lib.clang_getCursorLexicalParent(self)

        return self._lexical_parent

    @property
    def translation_unit(self):
        """Returns the TranslationUnit to which this Cursor belongs."""
        # If this triggers an AttributeError, the instance was not properly
        # created.
        return self._tu

    @property
    def referenced(self):
        """
        For a cursor that is a reference, returns a cursor 
        representing the entity that it references.
        """
        if not hasattr(self, '_referenced'):
            self._referenced = conf.lib.clang_getCursorReferenced(self)

        return self._referenced

    def get_arguments(self):
        """Return an iterator for accessing the arguments of this cursor."""
        num_args = conf.lib.clang_Cursor_getNumArguments(self)
        for i in range(0, num_args):
            yield conf.lib.clang_Cursor_getArgument(self, i)

    def get_children(self):
        """Return an iterator for accessing the children of this cursor."""

        # FIXME: Expose iteration from CIndex, PR6125.
        def visitor(child, parent, children):
            # FIXME: Document this assertion in API.
            # FIXME: There should just be an isNull method.
            assert child != conf.lib.clang_getNullCursor()

            # Create reference to TU so it isn't GC'd before Cursor.
            child._tu = self._tu
            children.append(child)
            return 1 # continue
        children = []
        conf.lib.clang_visitChildren(self, callbacks['cursor_visit'](visitor),
            children)
        return iter(children)

    def get_tokens(self):
        """Obtain Token instances formulating that compose this Cursor.

        This is a generator for Token instances. It returns all tokens which
        occupy the extent this cursor occupies.
        """
        return TokenGroup.get_tokens(self._tu, self.extent)

    @staticmethod
    def from_result(res, fn, args):
        assert isinstance(res, Cursor)
        # FIXME: There should just be an isNull method.
        if res == conf.lib.clang_getNullCursor():
            return None

        # Store a reference to the TU in the Python object so it won't get GC'd
        # before the Cursor.
        tu = None
        for arg in args:
            if isinstance(arg, TranslationUnit):
                tu = arg
                break

            if hasattr(arg, 'translation_unit'):
                tu = arg.translation_unit
                break

        assert tu is not None

        res._tu = tu
        return res

    @staticmethod
    def from_cursor_result(res, fn, args):
        assert isinstance(res, Cursor)
        if res == conf.lib.clang_getNullCursor():
            return None

        res._tu = args[0]._tu
        return res

### Type Kinds ###

class TypeKind(object):
    """
    Describes the kind of type.
    """

    # The unique kind objects, indexed by id.
    _kinds = []
    _name_map = None

    def __init__(self, value):
        if value >= len(TypeKind._kinds):
            TypeKind._kinds += [None] * (value - len(TypeKind._kinds) + 1)
        if TypeKind._kinds[value] is not None:
            raise ValueError('TypeKind already loaded')
        self.value = value
        TypeKind._kinds[value] = self
        TypeKind._name_map = None

    def from_param(self):
        return self.value

    @property
    def name(self):
        """Get the enumeration name of this cursor kind."""
        if self._name_map is None:
            self._name_map = {}
            for key,value in TypeKind.__dict__.items():
                if isinstance(value,TypeKind):
                    self._name_map[value] = key
        return self._name_map[self]

    @property
    def spelling(self):
        """Retrieve the spelling of this TypeKind."""
        return conf.lib.clang_getTypeKindSpelling(self.value)

    @staticmethod
    def from_id(id):
        if id >= len(TypeKind._kinds) or TypeKind._kinds[id] is None:
            raise ValueError('Unknown type kind %d' % id)
        return TypeKind._kinds[id]

    def __repr__(self):
        return 'TypeKind.%s' % (self.name,)

TypeKind.INVALID = TypeKind(0)
TypeKind.UNEXPOSED = TypeKind(1)
TypeKind.VOID = TypeKind(2)
TypeKind.BOOL = TypeKind(3)
TypeKind.CHAR_U = TypeKind(4)
TypeKind.UCHAR = TypeKind(5)
TypeKind.CHAR16 = TypeKind(6)
TypeKind.CHAR32 = TypeKind(7)
TypeKind.USHORT = TypeKind(8)
TypeKind.UINT = TypeKind(9)
TypeKind.ULONG = TypeKind(10)
TypeKind.ULONGLONG = TypeKind(11)
TypeKind.UINT128 = TypeKind(12)
TypeKind.CHAR_S = TypeKind(13)
TypeKind.SCHAR = TypeKind(14)
TypeKind.WCHAR = TypeKind(15)
TypeKind.SHORT = TypeKind(16)
TypeKind.INT = TypeKind(17)
TypeKind.LONG = TypeKind(18)
TypeKind.LONGLONG = TypeKind(19)
TypeKind.INT128 = TypeKind(20)
TypeKind.FLOAT = TypeKind(21)
TypeKind.DOUBLE = TypeKind(22)
TypeKind.LONGDOUBLE = TypeKind(23)
TypeKind.NULLPTR = TypeKind(24)
TypeKind.OVERLOAD = TypeKind(25)
TypeKind.DEPENDENT = TypeKind(26)
TypeKind.OBJCID = TypeKind(27)
TypeKind.OBJCCLASS = TypeKind(28)
TypeKind.OBJCSEL = TypeKind(29)
TypeKind.COMPLEX = TypeKind(100)
TypeKind.POINTER = TypeKind(101)
TypeKind.BLOCKPOINTER = TypeKind(102)
TypeKind.LVALUEREFERENCE = TypeKind(103)
TypeKind.RVALUEREFERENCE = TypeKind(104)
TypeKind.RECORD = TypeKind(105)
TypeKind.ENUM = TypeKind(106)
TypeKind.TYPEDEF = TypeKind(107)
TypeKind.OBJCINTERFACE = TypeKind(108)
TypeKind.OBJCOBJECTPOINTER = TypeKind(109)
TypeKind.FUNCTIONNOPROTO = TypeKind(110)
TypeKind.FUNCTIONPROTO = TypeKind(111)
TypeKind.CONSTANTARRAY = TypeKind(112)
TypeKind.VECTOR = TypeKind(113)

class Type(Structure):
    """
    The type of an element in the abstract syntax tree.
    """
    _fields_ = [("_kind_id", c_int), ("data", c_void_p * 2)]

    @property
    def kind(self):
        """Return the kind of this type."""
        return TypeKind.from_id(self._kind_id)

    def argument_types(self):
        """Retrieve a container for the non-variadic arguments for this type.

        The returned object is iterable and indexable. Each item in the
        container is a Type instance.
        """
        class ArgumentsIterator(collections.Sequence):
            def __init__(self, parent):
                self.parent = parent
                self.length = None

            def __len__(self):
                if self.length is None:
                    self.length = conf.lib.clang_getNumArgTypes(self.parent)

                return self.length

            def __getitem__(self, key):
                # FIXME Support slice objects.
                if not isinstance(key, int):
                    raise TypeError("Must supply a non-negative int.")

                if key < 0:
                    raise IndexError("Only non-negative indexes are accepted.")

                if key >= len(self):
                    raise IndexError("Index greater than container length: "
                                     "%d > %d" % ( key, len(self) ))

                result = conf.lib.clang_getArgType(self.parent, key)
                if result.kind == TypeKind.INVALID:
                    raise IndexError("Argument could not be retrieved.")

                return result

        assert self.kind == TypeKind.FUNCTIONPROTO
        return ArgumentsIterator(self)

    @property
    def element_type(self):
        """Retrieve the Type of elements within this Type.

        If accessed on a type that is not an array, complex, or vector type, an
        exception will be raised.
        """
        result = conf.lib.clang_getElementType(self)
        if result.kind == TypeKind.INVALID:
            raise Exception('Element type not available on this type.')

        return result

    @property
    def element_count(self):
        """Retrieve the number of elements in this type.

        Returns an int.

        If the Type is not an array or vector, this raises.
        """
        result = conf.lib.clang_getNumElements(self)
        if result < 0:
            raise Exception('Type does not have elements.')

        return result

    @property
    def translation_unit(self):
        """The TranslationUnit to which this Type is associated."""
        # If this triggers an AttributeError, the instance was not properly
        # instantiated.
        return self._tu

    @staticmethod
    def from_result(res, fn, args):
        assert isinstance(res, Type)

        tu = None
        for arg in args:
            if hasattr(arg, 'translation_unit'):
                tu = arg.translation_unit
                break

        assert tu is not None
        res._tu = tu

        return res

    def get_canonical(self):
        """
        Return the canonical type for a Type.

        Clang's type system explicitly models typedefs and all the
        ways a specific type can be represented.  The canonical type
        is the underlying type with all the "sugar" removed.  For
        example, if 'T' is a typedef for 'int', the canonical type for
        'T' would be 'int'.
        """
        return conf.lib.clang_getCanonicalType(self)

    def is_const_qualified(self):
        """Determine whether a Type has the "const" qualifier set.

        This does not look through typedefs that may have added "const"
        at a different level.
        """
        return conf.lib.clang_isConstQualifiedType(self)

    def is_volatile_qualified(self):
        """Determine whether a Type has the "volatile" qualifier set.

        This does not look through typedefs that may have added "volatile"
        at a different level.
        """
        return conf.lib.clang_isVolatileQualifiedType(self)

    def is_restrict_qualified(self):
        """Determine whether a Type has the "restrict" qualifier set.

        This does not look through typedefs that may have added "restrict" at
        a different level.
        """
        return conf.lib.clang_isRestrictQualifiedType(self)

    def is_function_variadic(self):
        """Determine whether this function Type is a variadic function type."""
        assert self.kind == TypeKind.FUNCTIONPROTO

        return conf.lib.clang_isFunctionTypeVariadic(self)

    def is_pod(self):
        """Determine whether this Type represents plain old data (POD)."""
        return conf.lib.clang_isPODType(self)

    def get_pointee(self):
        """
        For pointer types, returns the type of the pointee.
        """
        return conf.lib.clang_getPointeeType(self)

    def get_declaration(self):
        """
        Return the cursor for the declaration of the given type.
        """
        return conf.lib.clang_getTypeDeclaration(self)

    def get_result(self):
        """
        Retrieve the result type associated with a function type.
        """
        return conf.lib.clang_getResultType(self)

    def get_array_element_type(self):
        """
        Retrieve the type of the elements of the array type.
        """
        return conf.lib.clang_getArrayElementType(self)

    def get_array_size(self):
        """
        Retrieve the size of the constant array.
        """
        return conf.lib.clang_getArraySize(self)

    def __eq__(self, other):
        if type(other) != type(self):
            return False

        return conf.lib.clang_equalTypes(self, other)

    def __ne__(self, other):
        return not self.__eq__(other)

## CIndex Objects ##

# CIndex objects (derived from ClangObject) are essentially lightweight
# wrappers attached to some underlying object, which is exposed via CIndex as
# a void*.

class ClangObject(object):
    """
    A helper for Clang objects. This class helps act as an intermediary for
    the ctypes library and the Clang CIndex library.
    """
    def __init__(self, obj):
        assert isinstance(obj, c_object_p) and obj
        self.obj = self._as_parameter_ = obj

    def from_param(self):
        return self._as_parameter_


class _CXUnsavedFile(Structure):
    """Helper for passing unsaved file arguments."""
    _fields_ = [("name", c_char_p), ("contents", c_char_p), ('length', c_ulong)]

# Functions calls through the python interface are rather slow. Fortunately,
# for most symboles, we do not need to perform a function call. Their spelling
# never changes and is consequently provided by this spelling cache.
SpellingCache = {
            # 0: CompletionChunk.Kind("Optional"),
            # 1: CompletionChunk.Kind("TypedText"),
            # 2: CompletionChunk.Kind("Text"),
            # 3: CompletionChunk.Kind("Placeholder"),
            # 4: CompletionChunk.Kind("Informative"),
            # 5 : CompletionChunk.Kind("CurrentParameter"),
            6: '(',   # CompletionChunk.Kind("LeftParen"),
            7: ')',   # CompletionChunk.Kind("RightParen"),
            8: ']',   # CompletionChunk.Kind("LeftBracket"),
            9: ']',   # CompletionChunk.Kind("RightBracket"),
            10: '{',  # CompletionChunk.Kind("LeftBrace"),
            11: '}',  # CompletionChunk.Kind("RightBrace"),
            12: '<',  # CompletionChunk.Kind("LeftAngle"),
            13: '>',  # CompletionChunk.Kind("RightAngle"),
            14: ', ', # CompletionChunk.Kind("Comma"),
            # 15: CompletionChunk.Kind("ResultType"),
            16: ':',  # CompletionChunk.Kind("Colon"),
            17: ';',  # CompletionChunk.Kind("SemiColon"),
            18: '=',  # CompletionChunk.Kind("Equal"),
            19: ' ',  # CompletionChunk.Kind("HorizontalSpace"),
            # 20: CompletionChunk.Kind("VerticalSpace")
}

class CompletionChunk:
    class Kind:
        def __init__(self, name):
            self.name = name

        def __str__(self):
            return self.name

        def __repr__(self):
            return "<ChunkKind: %s>" % self

    def __init__(self, completionString, key):
        self.cs = completionString
        self.key = key
        self.__kindNumberCache = -1

    def __repr__(self):
        return "{'" + self.spelling + "', " + str(self.kind) + "}"

    @CachedProperty
    def spelling(self):
        if self.__kindNumber in SpellingCache:
                return SpellingCache[self.__kindNumber]
        return conf.lib.clang_getCompletionChunkText(self.cs, self.key).spelling

    # We do not use @CachedProperty here, as the manual implementation is
    # apparently still significantly faster. Please profile carefully if you
    # would like to add CachedProperty back.
    @property
    def __kindNumber(self):
        if self.__kindNumberCache == -1:
            self.__kindNumberCache = \
                conf.lib.clang_getCompletionChunkKind(self.cs, self.key)
        return self.__kindNumberCache

    @CachedProperty
    def kind(self):
        return completionChunkKindMap[self.__kindNumber]

    @CachedProperty
    def string(self):
        res = conf.lib.clang_getCompletionChunkCompletionString(self.cs,
                                                                self.key)

        if (res):
          return CompletionString(res)
        else:
          None

    def isKindOptional(self):
      return self.__kindNumber == 0

    def isKindTypedText(self):
      return self.__kindNumber == 1

    def isKindPlaceHolder(self):
      return self.__kindNumber == 3

    def isKindInformative(self):
      return self.__kindNumber == 4

    def isKindResultType(self):
      return self.__kindNumber == 15

completionChunkKindMap = {
            0: CompletionChunk.Kind("Optional"),
            1: CompletionChunk.Kind("TypedText"),
            2: CompletionChunk.Kind("Text"),
            3: CompletionChunk.Kind("Placeholder"),
            4: CompletionChunk.Kind("Informative"),
            5: CompletionChunk.Kind("CurrentParameter"),
            6: CompletionChunk.Kind("LeftParen"),
            7: CompletionChunk.Kind("RightParen"),
            8: CompletionChunk.Kind("LeftBracket"),
            9: CompletionChunk.Kind("RightBracket"),
            10: CompletionChunk.Kind("LeftBrace"),
            11: CompletionChunk.Kind("RightBrace"),
            12: CompletionChunk.Kind("LeftAngle"),
            13: CompletionChunk.Kind("RightAngle"),
            14: CompletionChunk.Kind("Comma"),
            15: CompletionChunk.Kind("ResultType"),
            16: CompletionChunk.Kind("Colon"),
            17: CompletionChunk.Kind("SemiColon"),
            18: CompletionChunk.Kind("Equal"),
            19: CompletionChunk.Kind("HorizontalSpace"),
            20: CompletionChunk.Kind("VerticalSpace")}

class CompletionString(ClangObject):
    class Availability:
        def __init__(self, name):
            self.name = name

        def __str__(self):
            return self.name

        def __repr__(self):
            return "<Availability: %s>" % self

    def __len__(self):
        self.num_chunks

    @CachedProperty
    def num_chunks(self):
        return conf.lib.clang_getNumCompletionChunks(self.obj)

    def __getitem__(self, key):
        if self.num_chunks <= key:
            raise IndexError
        return CompletionChunk(self.obj, key)

    @property
    def priority(self):
        return conf.lib.clang_getCompletionPriority(self.obj)

    @property
    def availability(self):
        res = conf.lib.clang_getCompletionAvailability(self.obj)
        return availabilityKinds[res]

    @property
    def briefComment(self):
        if conf.function_exists("clang_getCompletionBriefComment"):
            return conf.lib.clang_getCompletionBriefComment(self.obj)
        return _CXString()

    def __repr__(self):
        return " | ".join([str(a) for a in self]) \
               + " || Priority: " + str(self.priority) \
               + " || Availability: " + str(self.availability) \
               + " || Brief comment: " + str(self.briefComment.spelling)

availabilityKinds = {
            0: CompletionChunk.Kind("Available"),
            1: CompletionChunk.Kind("Deprecated"),
            2: CompletionChunk.Kind("NotAvailable"),
            3: CompletionChunk.Kind("NotAccessible")}

class CodeCompletionResult(Structure):
    _fields_ = [('cursorKind', c_int), ('completionString', c_object_p)]

    def __repr__(self):
        return str(CompletionString(self.completionString))

    @property
    def kind(self):
        return CursorKind.from_id(self.cursorKind)

    @property
    def string(self):
        return CompletionString(self.completionString)

class CCRStructure(Structure):
    _fields_ = [('results', POINTER(CodeCompletionResult)),
                ('numResults', c_int)]

    def __len__(self):
        return self.numResults

    def __getitem__(self, key):
        if len(self) <= key:
            raise IndexError

        return self.results[key]

class CodeCompletionResults(ClangObject):
    def __init__(self, ptr):
        assert isinstance(ptr, POINTER(CCRStructure)) and ptr
        self.ptr = self._as_parameter_ = ptr

    def from_param(self):
        return self._as_parameter_

    def __del__(self):
        conf.lib.clang_disposeCodeCompleteResults(self)

    @property
    def results(self):
        return self.ptr.contents

    @property
    def diagnostics(self):
        class DiagnosticsItr:
            def __init__(self, ccr):
                self.ccr= ccr

            def __len__(self):
                return int(\
                  conf.lib.clang_codeCompleteGetNumDiagnostics(self.ccr))

            def __getitem__(self, key):
                return conf.lib.clang_codeCompleteGetDiagnostic(self.ccr, key)

        return DiagnosticsItr(self)


class Index(ClangObject):
    """
    The Index type provides the primary interface to the Clang CIndex library,
    primarily by providing an interface for reading and parsing translation
    units.
    """

    @staticmethod
    def create(excludeDecls=False):
        """
        Create a new Index.
        Parameters:
        excludeDecls -- Exclude local declarations from translation units.
        """
        return Index(conf.lib.clang_createIndex(excludeDecls, 0))

    def __del__(self):
        conf.lib.clang_disposeIndex(self)

    def read(self, path):
        """Load a TranslationUnit from the given AST file."""
        return TranslationUnit.from_ast(path, self)

    def parse(self, path, args=None, unsaved_files=None, options = 0):
        """Load the translation unit from the given source code file by running
        clang and generating the AST before loading. Additional command line
        parameters can be passed to clang via the args parameter.

        In-memory contents for files can be provided by passing a list of pairs
        to as unsaved_files, the first item should be the filenames to be mapped
        and the second should be the contents to be substituted for the
        file. The contents may be passed as strings or file objects.

        If an error was encountered during parsing, a TranslationUnitLoadError
        will be raised.
        """
        return TranslationUnit.from_source(path, args, unsaved_files, options,
                                           self)

class TranslationUnit(ClangObject):
    """Represents a source code translation unit.

    This is one of the main types in the API. Any time you wish to interact
    with Clang's representation of a source file, you typically start with a
    translation unit.
    """

    # Default parsing mode.
    PARSE_NONE = 0

    # Instruct the parser to create a detailed processing record containing
    # metadata not normally retained.
    PARSE_DETAILED_PROCESSING_RECORD = 1

    # Indicates that the translation unit is incomplete. This is typically used
    # when parsing headers.
    PARSE_INCOMPLETE = 2

    # Instruct the parser to create a pre-compiled preamble for the translation
    # unit. This caches the preamble (included files at top of source file).
    # This is useful if the translation unit will be reparsed and you don't
    # want to incur the overhead of reparsing the preamble.
    PARSE_PRECOMPILED_PREAMBLE = 4

    # Cache code completion information on parse. This adds time to parsing but
    # speeds up code completion.
    PARSE_CACHE_COMPLETION_RESULTS = 8

    # Flags with values 16 and 32 are deprecated and intentionally omitted.

    # Do not parse function bodies. This is useful if you only care about
    # searching for declarations/definitions.
    PARSE_SKIP_FUNCTION_BODIES = 64

    # Used to indicate that brief documentation comments should be included
    # into the set of code completions returned from this translation unit.
    PARSE_INCLUDE_BRIEF_COMMENTS_IN_CODE_COMPLETION = 128

    @classmethod
    def from_source(cls, filename, args=None, unsaved_files=None, options=0,
                    index=None):
        """Create a TranslationUnit by parsing source.

        This is capable of processing source code both from files on the
        filesystem as well as in-memory contents.

        Command-line arguments that would be passed to clang are specified as
        a list via args. These can be used to specify include paths, warnings,
        etc. e.g. ["-Wall", "-I/path/to/include"].

        In-memory file content can be provided via unsaved_files. This is an
        iterable of 2-tuples. The first element is the str filename. The
        second element defines the content. Content can be provided as str
        source code or as file objects (anything with a read() method). If
        a file object is being used, content will be read until EOF and the
        read cursor will not be reset to its original position.

        options is a bitwise or of TranslationUnit.PARSE_XXX flags which will
        control parsing behavior.

        index is an Index instance to utilize. If not provided, a new Index
        will be created for this TranslationUnit.

        To parse source from the filesystem, the filename of the file to parse
        is specified by the filename argument. Or, filename could be None and
        the args list would contain the filename(s) to parse.

        To parse source from an in-memory buffer, set filename to the virtual
        filename you wish to associate with this source (e.g. "test.c"). The
        contents of that file are then provided in unsaved_files.

        If an error occurs, a TranslationUnitLoadError is raised.

        Please note that a TranslationUnit with parser errors may be returned.
        It is the caller's responsibility to check tu.diagnostics for errors.

        Also note that Clang infers the source language from the extension of
        the input filename. If you pass in source code containing a C++ class
        declaration with the filename "test.c" parsing will fail.
        """
        if args is None:
            args = []
        else:
            # make a copy, because we're modifying the list right below
            args = list(args)

        args.append('-fno-color-diagnostics')

        if unsaved_files is None:
            unsaved_files = []

        if index is None:
            index = Index.create()

        args_array = None
        if len(args) > 0:
            args_array = (c_char_p * len(args))(* [encode(arg) for arg in args])

        unsaved_array = None
        if len(unsaved_files) > 0:
            unsaved_array = (_CXUnsavedFile * len(unsaved_files))()
            for i, (name, contents) in enumerate(unsaved_files):
                if hasattr(contents, "read"):
                    contents = contents.read()

                unsaved_array[i].name = encode(name)
                unsaved_array[i].contents = encode(contents)
                unsaved_array[i].length = len(contents)

        ptr = conf.lib.clang_parseTranslationUnit(index, encode(filename),
                                    args_array, len(args), unsaved_array,
                                    len(unsaved_files), options)

        if not ptr:
            raise TranslationUnitLoadError("Error parsing translation unit.")

        return cls(ptr, index=index)

    @classmethod
    def from_ast_file(cls, filename, index=None):
        """Create a TranslationUnit instance from a saved AST file.

        A previously-saved AST file (provided with -emit-ast or
        TranslationUnit.save()) is loaded from the filename specified.

        If the file cannot be loaded, a TranslationUnitLoadError will be
        raised.

        index is optional and is the Index instance to use. If not provided,
        a default Index will be created.
        """
        if index is None:
            index = Index.create()

        ptr = conf.lib.clang_createTranslationUnit(index, filename)
        if not ptr:
            raise TranslationUnitLoadError(filename)

        return cls(ptr=ptr, index=index)

    def __init__(self, ptr, index):
        """Create a TranslationUnit instance.

        TranslationUnits should be created using one of the from_* @classmethod
        functions above. __init__ is only called internally.
        """
        assert isinstance(index, Index)

        ClangObject.__init__(self, ptr)

    def __del__(self):
        conf.lib.clang_disposeTranslationUnit(self)

    @property
    def cursor(self):
        """Retrieve the cursor that represents the given translation unit."""
        return conf.lib.clang_getTranslationUnitCursor(self)

    @property
    def spelling(self):
        """Get the original translation unit source file name."""
        return conf.lib.clang_getTranslationUnitSpelling(self)

    def get_includes(self):
        """
        Return an iterable sequence of FileInclusion objects that describe the
        sequence of inclusions in a translation unit. The first object in
        this sequence is always the input file. Note that this method will not
        recursively iterate over header files included through precompiled
        headers.
        """
        def visitor(fobj, lptr, depth, includes):
            if depth > 0:
                loc = lptr.contents
                includes.append(FileInclusion(loc.file, File(fobj), loc, depth))

        # Automatically adapt CIndex/ctype pointers to python objects
        includes = []
        conf.lib.clang_getInclusions(self,
                callbacks['translation_unit_includes'](visitor), includes)

        return iter(includes)

    def get_file(self, filename):
        """Obtain a File from this translation unit."""

        return File.from_name(self, filename)

    def get_location(self, filename, position):
        """Obtain a SourceLocation for a file in this translation unit.

        The position can be specified by passing:

          - Integer file offset. Initial file offset is 0.
          - 2-tuple of (line number, column number). Initial file position is
            (0, 0)
        """
        f = self.get_file(filename)

        if isinstance(position, int):
            return SourceLocation.from_offset(self, f, position)

        return SourceLocation.from_position(self, f, position[0], position[1])

    def get_extent(self, filename, locations):
        """Obtain a SourceRange from this translation unit.

        The bounds of the SourceRange must ultimately be defined by a start and
        end SourceLocation. For the locations argument, you can pass:

          - 2 SourceLocation instances in a 2-tuple or list.
          - 2 int file offsets via a 2-tuple or list.
          - 2 2-tuple or lists of (line, column) pairs in a 2-tuple or list.

        e.g.

        get_extent('foo.c', (5, 10))
        get_extent('foo.c', ((1, 1), (1, 15)))
        """
        f = self.get_file(filename)

        if len(locations) < 2:
            raise Exception('Must pass object with at least 2 elements')

        start_location, end_location = locations

        if hasattr(start_location, '__len__'):
            start_location = SourceLocation.from_position(self, f,
                start_location[0], start_location[1])
        elif isinstance(start_location, int):
            start_location = SourceLocation.from_offset(self, f,
                start_location)

        if hasattr(end_location, '__len__'):
            end_location = SourceLocation.from_position(self, f,
                end_location[0], end_location[1])
        elif isinstance(end_location, int):
            end_location = SourceLocation.from_offset(self, f, end_location)

        assert isinstance(start_location, SourceLocation)
        assert isinstance(end_location, SourceLocation)

        return SourceRange.from_locations(start_location, end_location)

    @property
    def diagnostics(self):
        """
        Return an iterable (and indexable) object containing the diagnostics.
        """
        class DiagIterator:
            def __init__(self, tu):
                self.tu = tu

            def __len__(self):
                return int(conf.lib.clang_getNumDiagnostics(self.tu))

            def __getitem__(self, key):
                diag = conf.lib.clang_getDiagnostic(self.tu, key)
                if not diag:
                    raise IndexError
                return Diagnostic(diag)

        return DiagIterator(self)

    def reparse(self, unsaved_files=None, options=0):
        """
        Reparse an already parsed translation unit.

        In-memory contents for files can be provided by passing a list of pairs
        as unsaved_files, the first items should be the filenames to be mapped
        and the second should be the contents to be substituted for the
        file. The contents may be passed as strings or file objects.
        """
        if unsaved_files is None:
            unsaved_files = []

        unsaved_files_array = 0
        if len(unsaved_files):
            unsaved_files_array = (_CXUnsavedFile * len(unsaved_files))()
            for i,(name,value) in enumerate(unsaved_files):
                if not isinstance(value, str):
                    # FIXME: It would be great to support an efficient version
                    # of this, one day.
                    value = value.read()
                    print(value)
                if not isinstance(value, str):
                    raise TypeError('Unexpected unsaved file contents.')
                unsaved_files_array[i].name = encode(name)
                unsaved_files_array[i].contents = encode(value)
                unsaved_files_array[i].length = len(value)
        ptr = conf.lib.clang_reparseTranslationUnit(self, len(unsaved_files),
                unsaved_files_array, options)

    def save(self, filename):
        """Saves the TranslationUnit to a file.

        This is equivalent to passing -emit-ast to the clang frontend. The
        saved file can be loaded back into a TranslationUnit. Or, if it
        corresponds to a header, it can be used as a pre-compiled header file.

        If an error occurs while saving, a TranslationUnitSaveError is raised.
        If the error was TranslationUnitSaveError.ERROR_INVALID_TU, this means
        the constructed TranslationUnit was not valid at time of save. In this
        case, the reason(s) why should be available via
        TranslationUnit.diagnostics().

        filename -- The path to save the translation unit to.
        """
        options = conf.lib.clang_defaultSaveOptions(self)
        result = int(conf.lib.clang_saveTranslationUnit(self, filename,
                                                        options))
        if result != 0:
            raise TranslationUnitSaveError(result,
                'Error saving TranslationUnit.')

    def codeComplete(self, path, line, column, unsaved_files=None,
                     include_macros=False, include_code_patterns=False,
                     include_brief_comments=False):
        """
        Code complete in this translation unit.

        In-memory contents for files can be provided by passing a list of pairs
        as unsaved_files, the first items should be the filenames to be mapped
        and the second should be the contents to be substituted for the
        file. The contents may be passed as strings or file objects.
        """
        options = 0

        if include_macros:
            options += 1

        if include_code_patterns:
            options += 2

        if include_brief_comments:
            options += 4

        if unsaved_files is None:
            unsaved_files = []

        unsaved_files_array = 0
        if len(unsaved_files):
            unsaved_files_array = (_CXUnsavedFile * len(unsaved_files))()
            for i,(name,value) in enumerate(unsaved_files):
                if not isinstance(value, str):
                    # FIXME: It would be great to support an efficient version
                    # of this, one day.
                    value = value.read()
                    print(value)
                if not isinstance(value, str):
                    raise TypeError('Unexpected unsaved file contents.')
                unsaved_files_array[i].name = encode(name)
                unsaved_files_array[i].contents = encode(value)
                unsaved_files_array[i].length = len(value)
        ptr = conf.lib.clang_codeCompleteAt(self, encode(path), line, column,
                unsaved_files_array, len(unsaved_files), options)
        if ptr:
            return CodeCompletionResults(ptr)
        return None

    def get_tokens(self, locations=None, extent=None):
        """Obtain tokens in this translation unit.

        This is a generator for Token instances. The caller specifies a range
        of source code to obtain tokens for. The range can be specified as a
        2-tuple of SourceLocation or as a SourceRange. If both are defined,
        behavior is undefined.
        """
        if locations is not None:
            extent = SourceRange(start=locations[0], end=locations[1])

        return TokenGroup.get_tokens(self, extent)

class File(ClangObject):
    """
    The File class represents a particular source file that is part of a
    translation unit.
    """

    @staticmethod
    def from_name(translation_unit, file_name):
        """Retrieve a file handle within the given translation unit."""
        return File(conf.lib.clang_getFile(translation_unit, encode(file_name)))

    @property
    def name(self):
        """Return the complete file and path name of the file."""
        return conf.lib.clang_getCString(conf.lib.clang_getFileName(self))

    @property
    def time(self):
        """Return the last modification time of the file."""
        return conf.lib.clang_getFileTime(self)

    def __str__(self):
        return self.name

    def __repr__(self):
        return "<File: %s>" % (self.name)

    @staticmethod
    def from_cursor_result(res, fn, args):
        assert isinstance(res, File)

        # Copy a reference to the TranslationUnit to prevent premature GC.
        res._tu = args[0]._tu
        return res

class FileInclusion(object):
    """
    The FileInclusion class represents the inclusion of one source file by
    another via a '#include' directive or as the input file for the translation
    unit. This class provides information about the included file, the including
    file, the location of the '#include' directive and the depth of the included
    file in the stack. Note that the input file has depth 0.
    """

    def __init__(self, src, tgt, loc, depth):
        self.source = src
        self.include = tgt
        self.location = loc
        self.depth = depth

    @property
    def is_input_file(self):
        """True if the included file is the input file."""
        return self.depth == 0

class CompilationDatabaseError(Exception):
    """Represents an error that occurred when working with a CompilationDatabase

    Each error is associated to an enumerated value, accessible under
    e.cdb_error. Consumers can compare the value with one of the ERROR_
    constants in this class.
    """

    # An unknown error occured
    ERROR_UNKNOWN = 0

    # The database could not be loaded
    ERROR_CANNOTLOADDATABASE = 1

    def __init__(self, enumeration, message):
        assert isinstance(enumeration, int)

        if enumeration > 1:
            raise Exception("Encountered undefined CompilationDatabase error "
                            "constant: %d. Please file a bug to have this "
                            "value supported." % enumeration)

        self.cdb_error = enumeration
        Exception.__init__(self, 'Error %d: %s' % (enumeration, message))

class CompileCommand(object):
    """Represents the compile command used to build a file"""
    def __init__(self, cmd, ccmds):
        self.cmd = cmd
        # Keep a reference to the originating CompileCommands
        # to prevent garbage collection
        self.ccmds = ccmds

    @property
    def directory(self):
        """Get the working directory for this CompileCommand"""
        return conf.lib.clang_CompileCommand_getDirectory(self.cmd)

    @property
    def arguments(self):
        """
        Get an iterable object providing each argument in the
        command line for the compiler invocation as a _CXString.

        Invariant : the first argument is the compiler executable
        """
        length = conf.lib.clang_CompileCommand_getNumArgs(self.cmd)
        for i in range(length):
            yield conf.lib.clang_CompileCommand_getArg(self.cmd, i)

class CompileCommands(object):
    """
    CompileCommands is an iterable object containing all CompileCommand
    that can be used for building a specific file.
    """
    def __init__(self, ccmds):
        self.ccmds = ccmds

    def __del__(self):
        conf.lib.clang_CompileCommands_dispose(self.ccmds)

    def __len__(self):
        return int(conf.lib.clang_CompileCommands_getSize(self.ccmds))

    def __getitem__(self, i):
        cc = conf.lib.clang_CompileCommands_getCommand(self.ccmds, i)
        if not cc:
            raise IndexError
        return CompileCommand(cc, self)

    @staticmethod
    def from_result(res, fn, args):
        if not res:
            return None
        return CompileCommands(res)

class CompilationDatabase(ClangObject):
    """
    The CompilationDatabase is a wrapper class around
    clang::tooling::CompilationDatabase

    It enables querying how a specific source file can be built.
    """

    def __del__(self):
        conf.lib.clang_CompilationDatabase_dispose(self)

    @staticmethod
    def from_result(res, fn, args):
        if not res:
            raise CompilationDatabaseError(0,
                                           "CompilationDatabase loading failed")
        return CompilationDatabase(res)

    @staticmethod
    def fromDirectory(buildDir):
        """Builds a CompilationDatabase from the database found in buildDir"""
        errorCode = c_uint()
        try:
            cdb = conf.lib.clang_CompilationDatabase_fromDirectory(encode(buildDir),
                    byref(errorCode))
        except CompilationDatabaseError as e:
            raise CompilationDatabaseError(int(errorCode.value),
                                           "CompilationDatabase loading failed")
        return cdb

    def getCompileCommands(self, filename):
        """
        Get an iterable object providing all the CompileCommands available to
        build filename. Returns None if filename is not found in the database.
        """
        return conf.lib.clang_CompilationDatabase_getCompileCommands(self,
                                                                     encode(filename))

class Token(Structure):
    """Represents a single token from the preprocessor.

    Tokens are effectively segments of source code. Source code is first parsed
    into tokens before being converted into the AST and Cursors.

    Tokens are obtained from parsed TranslationUnit instances. You currently
    can't create tokens manually.
    """
    _fields_ = [
        ('int_data', c_uint * 4),
        ('ptr_data', c_void_p)
    ]

    @property
    def spelling(self):
        """The spelling of this token.

        This is the textual representation of the token in source.
        """
        return conf.lib.clang_getTokenSpelling(self._tu, self)

    @property
    def kind(self):
        """Obtain the TokenKind of the current token."""
        return TokenKind.from_value(conf.lib.clang_getTokenKind(self))

    @property
    def location(self):
        """The SourceLocation this Token occurs at."""
        return conf.lib.clang_getTokenLocation(self._tu, self)

    @property
    def extent(self):
        """The SourceRange this Token occupies."""
        return conf.lib.clang_getTokenExtent(self._tu, self)

    @property
    def cursor(self):
        """The Cursor this Token corresponds to."""
        cursor = Cursor()

        conf.lib.clang_annotateTokens(self._tu, byref(self), 1, byref(cursor))

        return cursor

# Now comes the plumbing to hook up the C library.

# Register callback types in common container.
callbacks['translation_unit_includes'] = CFUNCTYPE(None, c_object_p,
        POINTER(SourceLocation), c_uint, py_object)
callbacks['cursor_visit'] = CFUNCTYPE(c_int, Cursor, Cursor, py_object)

# Functions strictly alphabetical order.
functionList = [
  ("clang_annotateTokens",
   [TranslationUnit, POINTER(Token), c_uint, POINTER(Cursor)]),

  ("clang_CompilationDatabase_dispose",
   [c_object_p]),

  ("clang_CompilationDatabase_fromDirectory",
   [c_char_p, POINTER(c_uint)],
   c_object_p,
   CompilationDatabase.from_result),

  ("clang_CompilationDatabase_getCompileCommands",
   [c_object_p, c_char_p],
   c_object_p,
   CompileCommands.from_result),

  ("clang_CompileCommands_dispose",
   [c_object_p]),

  ("clang_CompileCommands_getCommand",
   [c_object_p, c_uint],
   c_object_p),

  ("clang_CompileCommands_getSize",
   [c_object_p],
   c_uint),

  ("clang_CompileCommand_getArg",
   [c_object_p, c_uint],
   _CXString,
   _CXString.from_result),

  ("clang_CompileCommand_getDirectory",
   [c_object_p],
   _CXString,
   _CXString.from_result),

  ("clang_CompileCommand_getNumArgs",
   [c_object_p],
   c_uint),

  ("clang_codeCompleteAt",
   [TranslationUnit, c_char_p, c_int, c_int, c_void_p, c_int, c_int],
   POINTER(CCRStructure)),

  ("clang_codeCompleteGetDiagnostic",
   [CodeCompletionResults, c_int],
   Diagnostic),

  ("clang_codeCompleteGetNumDiagnostics",
   [CodeCompletionResults],
   c_int),

  ("clang_createIndex",
   [c_int, c_int],
   c_object_p),

  ("clang_createTranslationUnit",
   [Index, c_char_p],
   c_object_p),

  ("clang_CXXMethod_isStatic",
   [Cursor],
   bool),

  ("clang_CXXMethod_isVirtual",
   [Cursor],
   bool),

  ("clang_defaultSaveOptions",
   [TranslationUnit],
   c_uint),

  ("clang_disposeCodeCompleteResults",
   [CodeCompletionResults]),

# ("clang_disposeCXTUResourceUsage",
#  [CXTUResourceUsage]),

  ("clang_disposeDiagnostic",
   [Diagnostic]),

  ("clang_disposeIndex",
   [Index]),

  ("clang_disposeString",
   [_CXString]),

  ("clang_disposeTokens",
   [TranslationUnit, POINTER(Token), c_uint]),

  ("clang_disposeTranslationUnit",
   [TranslationUnit]),

  ("clang_equalCursors",
   [Cursor, Cursor],
   bool),

  ("clang_equalLocations",
   [SourceLocation, SourceLocation],
   bool),

  ("clang_equalRanges",
   [SourceRange, SourceRange],
   bool),

  ("clang_equalTypes",
   [Type, Type],
   bool),

  ("clang_getArgType",
   [Type, c_uint],
   Type,
   Type.from_result),

  ("clang_getArrayElementType",
   [Type],
   Type,
   Type.from_result),

  ("clang_getArraySize",
   [Type],
   c_longlong),

  ("clang_getCanonicalCursor",
   [Cursor],
   Cursor,
   Cursor.from_cursor_result),

  ("clang_getCanonicalType",
   [Type],
   Type,
   Type.from_result),

  ("clang_getCompletionAvailability",
   [c_void_p],
   c_int),

  ("clang_getCompletionBriefComment",
   [c_void_p],
   _CXString),

  ("clang_getCompletionChunkCompletionString",
   [c_void_p, c_int],
   c_object_p),

  ("clang_getCompletionChunkKind",
   [c_void_p, c_int],
   c_int),

  ("clang_getCompletionChunkText",
   [c_void_p, c_int],
   _CXString),

  ("clang_getCompletionPriority",
   [c_void_p],
   c_int),

  ("clang_getCString",
   [_CXString],
   c_char_p),

  ("clang_getCursor",
   [TranslationUnit, SourceLocation],
   Cursor),

  ("clang_getCursorDefinition",
   [Cursor],
   Cursor,
   Cursor.from_result),

  ("clang_getCursorDisplayName",
   [Cursor],
   _CXString,
   _CXString.from_result),

  ("clang_getCursorExtent",
   [Cursor],
   SourceRange),

  ("clang_getCursorLexicalParent",
   [Cursor],
   Cursor,
   Cursor.from_cursor_result),

  ("clang_getCursorLocation",
   [Cursor],
   SourceLocation),

  ("clang_getCursorReferenced",
   [Cursor],
   Cursor,
   Cursor.from_result),

  ("clang_getCursorReferenceNameRange",
   [Cursor, c_uint, c_uint],
   SourceRange),

  ("clang_getCursorSemanticParent",
   [Cursor],
   Cursor,
   Cursor.from_cursor_result),

  ("clang_getCursorSpelling",
   [Cursor],
   _CXString,
   _CXString.from_result),

  ("clang_getCursorType",
   [Cursor],
   Type,
   Type.from_result),

  ("clang_getCursorUSR",
   [Cursor],
   _CXString,
   _CXString.from_result),

# ("clang_getCXTUResourceUsage",
#  [TranslationUnit],
#  CXTUResourceUsage),

  ("clang_getCXXAccessSpecifier",
   [Cursor],
   c_uint),

  ("clang_getDeclObjCTypeEncoding",
   [Cursor],
   _CXString,
   _CXString.from_result),

  ("clang_getDiagnostic",
   [c_object_p, c_uint],
   c_object_p),

  ("clang_getDiagnosticCategory",
   [Diagnostic],
   c_uint),

  ("clang_getDiagnosticCategoryName",
   [c_uint],
   _CXString,
   _CXString.from_result),

  ("clang_getDiagnosticFixIt",
   [Diagnostic, c_uint, POINTER(SourceRange)],
   _CXString,
   _CXString.from_result),

  ("clang_getDiagnosticLocation",
   [Diagnostic],
   SourceLocation),

  ("clang_getDiagnosticNumFixIts",
   [Diagnostic],
   c_uint),

  ("clang_getDiagnosticNumRanges",
   [Diagnostic],
   c_uint),

  ("clang_getDiagnosticOption",
   [Diagnostic, POINTER(_CXString)],
   _CXString,
   _CXString.from_result),

  ("clang_getDiagnosticRange",
   [Diagnostic, c_uint],
   SourceRange),

  ("clang_getDiagnosticSeverity",
   [Diagnostic],
   c_int),

  ("clang_getDiagnosticSpelling",
   [Diagnostic],
   _CXString,
   _CXString.from_result),

  ("clang_getElementType",
   [Type],
   Type,
   Type.from_result),

  ("clang_getEnumConstantDeclUnsignedValue",
   [Cursor],
   c_ulonglong),

  ("clang_getEnumConstantDeclValue",
   [Cursor],
   c_longlong),

  ("clang_getEnumDeclIntegerType",
   [Cursor],
   Type,
   Type.from_result),

  ("clang_getFile",
   [TranslationUnit, c_char_p],
   c_object_p),

  ("clang_getFileName",
   [File],
   _CXString), # TODO go through _CXString.from_result?

  ("clang_getFileTime",
   [File],
   c_uint),

  ("clang_getIBOutletCollectionType",
   [Cursor],
   Type,
   Type.from_result),

  ("clang_getIncludedFile",
   [Cursor],
   File,
   File.from_cursor_result),

  ("clang_getInclusions",
   [TranslationUnit, callbacks['translation_unit_includes'], py_object]),

  ("clang_getInstantiationLocation",
   [SourceLocation, POINTER(c_object_p), POINTER(c_uint), POINTER(c_uint),
    POINTER(c_uint)]),

  ("clang_getLocation",
   [TranslationUnit, File, c_uint, c_uint],
   SourceLocation),

  ("clang_getLocationForOffset",
   [TranslationUnit, File, c_uint],
   SourceLocation),

  ("clang_getNullCursor",
   None,
   Cursor),

  ("clang_getNumArgTypes",
   [Type],
   c_uint),

  ("clang_getNumCompletionChunks",
   [c_void_p],
   c_int),

  ("clang_getNumDiagnostics",
   [c_object_p],
   c_uint),

  ("clang_getNumElements",
   [Type],
   c_longlong),

  ("clang_getNumOverloadedDecls",
   [Cursor],
   c_uint),

  ("clang_getOverloadedDecl",
   [Cursor, c_uint],
   Cursor,
   Cursor.from_cursor_result),

  ("clang_getPointeeType",
   [Type],
   Type,
   Type.from_result),

  ("clang_getRange",
   [SourceLocation, SourceLocation],
   SourceRange),

  ("clang_getRangeEnd",
   [SourceRange],
   SourceLocation),

  ("clang_getRangeStart",
   [SourceRange],
   SourceLocation),

  ("clang_getResultType",
   [Type],
   Type,
   Type.from_result),

  ("clang_getSpecializedCursorTemplate",
   [Cursor],
   Cursor,
   Cursor.from_cursor_result),

  ("clang_getTemplateCursorKind",
   [Cursor],
   c_uint),

  ("clang_getTokenExtent",
   [TranslationUnit, Token],
   SourceRange),

  ("clang_getTokenKind",
   [Token],
   c_uint),

  ("clang_getTokenLocation",
   [TranslationUnit, Token],
   SourceLocation),

  ("clang_getTokenSpelling",
   [TranslationUnit, Token],
   _CXString,
   _CXString.from_result),

  ("clang_getTranslationUnitCursor",
   [TranslationUnit],
   Cursor,
   Cursor.from_result),

  ("clang_getTranslationUnitSpelling",
   [TranslationUnit],
   _CXString,
   _CXString.from_result),

  ("clang_getTUResourceUsageName",
   [c_uint],
   c_char_p),

  ("clang_getTypeDeclaration",
   [Type],
   Cursor,
   Cursor.from_result),

  ("clang_getTypedefDeclUnderlyingType",
   [Cursor],
   Type,
   Type.from_result),

  ("clang_getTypeKindSpelling",
   [c_uint],
   _CXString,
   _CXString.from_result),

  ("clang_hashCursor",
   [Cursor],
   c_uint),

  ("clang_isAttribute",
   [CursorKind],
   bool),

  ("clang_isConstQualifiedType",
   [Type],
   bool),

  ("clang_isCursorDefinition",
   [Cursor],
   bool),

  ("clang_isDeclaration",
   [CursorKind],
   bool),

  ("clang_isExpression",
   [CursorKind],
   bool),

  ("clang_isFileMultipleIncludeGuarded",
   [TranslationUnit, File],
   bool),

  ("clang_isFunctionTypeVariadic",
   [Type],
   bool),

  ("clang_isInvalid",
   [CursorKind],
   bool),

  ("clang_isPODType",
   [Type],
   bool),

  ("clang_isPreprocessing",
   [CursorKind],
   bool),

  ("clang_isReference",
   [CursorKind],
   bool),

  ("clang_isRestrictQualifiedType",
   [Type],
   bool),

  ("clang_isStatement",
   [CursorKind],
   bool),

  ("clang_isTranslationUnit",
   [CursorKind],
   bool),

  ("clang_isUnexposed",
   [CursorKind],
   bool),

  ("clang_isVirtualBase",
   [Cursor],
   bool),

  ("clang_isVolatileQualifiedType",
   [Type],
   bool),

  ("clang_parseTranslationUnit",
   [Index, c_char_p, c_void_p, c_int, c_void_p, c_int, c_int],
   c_object_p),

  ("clang_reparseTranslationUnit",
   [TranslationUnit, c_int, c_void_p, c_int],
   c_int),

  ("clang_saveTranslationUnit",
   [TranslationUnit, c_char_p, c_uint],
   c_int),

  ("clang_tokenize",
   [TranslationUnit, SourceRange, POINTER(POINTER(Token)), POINTER(c_uint)]),

  ("clang_visitChildren",
   [Cursor, callbacks['cursor_visit'], py_object],
   c_uint),

  ("clang_Cursor_getNumArguments",
   [Cursor],
   c_int),

  ("clang_Cursor_getArgument",
   [Cursor, c_uint],
   Cursor,
   Cursor.from_result),
]

class LibclangError(Exception):
    def __init__(self, message):
        self.m = message

    def __str__(self):
        return self.m

def register_function(lib, item, ignore_errors):
    # A function may not exist, if these bindings are used with an older or
    # incompatible version of libclang.so.
    try:
        func = getattr(lib, item[0])
    except AttributeError as e:
        msg = str(e) + ". Please ensure that your python bindings are "\
                       "compatible with your libclang.so version."
        if ignore_errors:
            return
        raise LibclangError(msg)

    if len(item) >= 2:
        func.argtypes = item[1]

    if len(item) >= 3:
        func.restype = item[2]

    if len(item) == 4:
        func.errcheck = item[3]

def register_functions(lib, ignore_errors):
    """Register function prototypes with a libclang library instance.

    This must be called as part of library instantiation so Python knows how
    to call out to the shared library.
    """

    def register(item):
        return register_function(lib, item, ignore_errors)

    list(map(register, functionList))

class Config:
    library_path = None
    library_file = None
    compatibility_check = True
    loaded = False

    @staticmethod
    def set_library_path(path):
        """Set the path in which to search for libclang"""
        if Config.loaded:
            raise Exception("library path must be set before before using " \
                            "any other functionalities in libclang.")

        Config.library_path = path

    @staticmethod
    def set_library_file(filename):
        """Set the exact location of libclang"""
        if Config.loaded:
            raise Exception("library file must be set before before using " \
                            "any other functionalities in libclang.")

        Config.library_file = filename

    @staticmethod
    def set_compatibility_check(check_status):
        """ Perform compatibility check when loading libclang

        The python bindings are only tested and evaluated with the version of
        libclang they are provided with. To ensure correct behavior a (limited)
        compatibility check is performed when loading the bindings. This check
        will throw an exception, as soon as it fails.

        In case these bindings are used with an older version of libclang, parts
        that have been stable between releases may still work. Users of the
        python bindings can disable the compatibility check. This will cause
        the python bindings to load, even though they are written for a newer
        version of libclang. Failures now arise if unsupported or incompatible
        features are accessed. The user is required to test himself if the
        features he is using are available and compatible between different
        libclang versions.
        """
        if Config.loaded:
            raise Exception("compatibility_check must be set before before " \
                            "using any other functionalities in libclang.")

        Config.compatibility_check = check_status

    @CachedProperty
    def lib(self):
        lib = self.get_cindex_library()
        register_functions(lib, not Config.compatibility_check)
        Config.loaded = True
        return lib

    def get_filename(self):
        if Config.library_file:
            return Config.library_file

        import platform
        name = platform.system()

        if name == 'Darwin':
            file = 'libclang.dylib'
        elif name == 'Windows':
            file = 'libclang.dll'
        else:
            file = find_library("clang") or 'libclang.so'

        if Config.library_path:
            file = Config.library_path + '/' + file

        return file

    def get_cindex_library(self):
        try:
            library = cdll.LoadLibrary(self.get_filename())
        except OSError as e:
            msg = str(e) + ". To provide a path to libclang use " \
                           "Config.set_library_path() or " \
                           "Config.set_library_file()."
            raise LibclangError(msg)

        return library

    def function_exists(self, name):
        try:
            getattr(self.lib, name)
        except AttributeError:
            return False

        return True

def register_enumerations():
    for name, value in clang.enumerations.TokenKinds:
        TokenKind.register(value, name)

conf = Config()
register_enumerations()

__all__ = [
    'Config',
    'CodeCompletionResults',
    'CompilationDatabase',
    'CompileCommands',
    'CompileCommand',
    'CursorKind',
    'Cursor',
    'Diagnostic',
    'File',
    'FixIt',
    'Index',
    'SourceLocation',
    'SourceRange',
    'TokenKind',
    'Token',
    'TranslationUnitLoadError',
    'TranslationUnit',
    'TypeKind',
    'Type',
]
plugin/clang/enumerations.py	[[[1
34
#===- enumerations.py - Python Enumerations ------------------*- python -*--===#
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
#===------------------------------------------------------------------------===#

"""
Clang Enumerations
==================

This module provides static definitions of enumerations that exist in libclang.

Enumerations are typically defined as a list of tuples. The exported values are
typically munged into other types or classes at module load time.

All enumerations are centrally defined in this file so they are all grouped
together and easier to audit. And, maybe even one day this file will be
automatically generated by scanning the libclang headers!
"""

# Maps to CXTokenKind. Note that libclang maintains a separate set of token
# enumerations from the C++ API.
TokenKinds = [
    ('PUNCTUATION', 0),
    ('KEYWORD', 1),
    ('IDENTIFIER', 2),
    ('LITERAL', 3),
    ('COMMENT', 4),
]

__all__ = ['TokenKinds']
plugin/clang_complete.vim	[[[1
659
"
" File: clang_complete.vim
" Author: Xavier Deguillard <deguilx@gmail.com>
"
" Description: Use of clang to complete in C/C++.
"
" Help: Use :help clang_complete
"

if exists('g:clang_complete_loaded')
  finish
endif
let g:clang_complete_loaded = 1

au FileType c,cpp,objc,objcpp call <SID>ClangCompleteInit()
au FileType c.*,cpp.*,objc.*,objcpp.* call <SID>ClangCompleteInit()

let b:clang_parameters = ''
let b:clang_user_options = ''
let b:my_changedtick = 0

" Store plugin path, as this is available only when sourcing the file,
" not during a function call.
let s:plugin_path = escape(expand('<sfile>:p:h'), '\')

" Older versions of Vim can't check if a map was made with <expr>
let s:use_maparg = v:version > 703 || (v:version == 703 && has('patch32'))

if has('python')
  let s:py_cmd = 'python'
  let s:pyfile_cmd = 'pyfile'
elseif has('python3')
  let s:py_cmd = 'python3'
  let s:pyfile_cmd = 'py3file'
endif

function! s:ClangCompleteInit()
  let l:bufname = bufname("%")
  if l:bufname == ''
    return
  endif

  if exists('g:clang_use_library') && g:clang_use_library == 0
    echoe "clang_complete: You can't use clang binary anymore."
    echoe 'For more information see g:clang_use_library help.'
    return
  endif

  if !exists('g:clang_auto_select')
    let g:clang_auto_select = 0
  endif

  if !exists('g:clang_complete_auto')
    let g:clang_complete_auto = 1
  endif

  if !exists('g:clang_close_preview')
    let g:clang_close_preview = 0
  endif

  if !exists('g:clang_complete_copen')
    let g:clang_complete_copen = 0
  endif

  if !exists('g:clang_hl_errors')
    let g:clang_hl_errors = 1
  endif

  if !exists('g:clang_periodic_quickfix')
    let g:clang_periodic_quickfix = 0
  endif

  if !exists('g:clang_snippets') || g:clang_snippets == 0
    let g:clang_snippets_engine = 'dummy'
  endif

  if !exists('g:clang_snippets_engine')
    let g:clang_snippets_engine = 'clang_complete'
  endif

  if !exists('g:clang_user_options')
    let g:clang_user_options = ''
  endif

  if !exists('g:clang_conceal_snippets')
    let g:clang_conceal_snippets = has('conceal')
  elseif g:clang_conceal_snippets == 1 && !has('conceal')
    echoe 'clang_complete: conceal feature not available but requested'
  endif

  if !exists('g:clang_complete_optional_args_in_snippets')
    let g:clang_complete_optional_args_in_snippets = 0
  endif

  if !exists('g:clang_trailing_placeholder')
    let g:clang_trailing_placeholder = 0
  endif

  if !exists('g:clang_compilation_database')
    let g:clang_compilation_database = ''
  endif

  if !exists('g:clang_library_path')
    let g:clang_library_path = ''
  endif

  if !exists('g:clang_complete_macros')
    let g:clang_complete_macros = 0
  endif

  if !exists('g:clang_complete_patterns')
    let g:clang_complete_patterns = 0
  endif

  if !exists('g:clang_debug')
    let g:clang_debug = 0
  endif

  if !exists('g:clang_sort_algo')
    let g:clang_sort_algo = 'priority'
  endif

  if !exists('g:clang_auto_user_options')
    let g:clang_auto_user_options = '.clang_complete, path'
  endif

  if !exists('g:clang_jumpto_declaration_key')
    let g:clang_jumpto_declaration_key = '<C-]>'
  endif

  if !exists('g:clang_jumpto_declaration_in_preview_key')
    let g:clang_jumpto_declaration_in_preview_key = '<C-W>]'
  endif

  if !exists('g:clang_jumpto_back_key')
    let g:clang_jumpto_back_key = '<C-T>'
  endif

  if !exists('g:clang_make_default_keymappings')
    let g:clang_make_default_keymappings = 1
  endif

  if !exists('g:clang_restore_cr_imap')
    let g:clang_restore_cr_imap = 'iunmap <buffer> <CR>'
  endif

  if !exists('g:clang_omnicppcomplete_compliance')
    let g:clang_omnicppcomplete_compliance = 0
  endif

  if g:clang_omnicppcomplete_compliance == 1
    let g:clang_complete_auto = 0
    let g:clang_make_default_keymappings = 0
  endif

  call LoadUserOptions()

  let b:my_changedtick = b:changedtick
  let b:clang_parameters = '-x c'

  if &filetype =~ 'objc'
    let b:clang_parameters = '-x objective-c'
  endif

  if &filetype == 'cpp' || &filetype == 'objcpp' || &filetype =~ 'cpp.*' || &filetype =~ 'objcpp.*'
    let b:clang_parameters .= '++'
  endif

  if expand('%:e') =~ 'h.*'
    let b:clang_parameters .= '-header'
  endif

  let g:clang_complete_lib_flags = 0

  if g:clang_complete_macros == 1
    let g:clang_complete_lib_flags = 1
  endif

  if g:clang_complete_patterns == 1
    let g:clang_complete_lib_flags += 2
  endif

  if s:initClangCompletePython() != 1
    return
  endif

  execute s:py_cmd 'snippetsInit()'

  if g:clang_make_default_keymappings == 1
    inoremap <expr> <buffer> <C-X><C-U> <SID>LaunchCompletion()
    inoremap <expr> <buffer> . <SID>CompleteDot()
    inoremap <expr> <buffer> > <SID>CompleteArrow()
    inoremap <expr> <buffer> : <SID>CompleteColon()
    execute "nnoremap <buffer> <silent> " . g:clang_jumpto_declaration_key . " :call <SID>GotoDeclaration(0)<CR><Esc>"
    execute "nnoremap <buffer> <silent> " . g:clang_jumpto_declaration_in_preview_key . " :call <SID>GotoDeclaration(1)<CR><Esc>"
    execute "nnoremap <buffer> <silent> " . g:clang_jumpto_back_key . " <C-O>"
  endif

  if g:clang_omnicppcomplete_compliance == 1
    inoremap <expr> <buffer> <C-X><C-U> <SID>LaunchCompletion()
  endif

  " Force menuone. Without it, when there's only one completion result,
  " it can be confusing (not completing and no popup)
  if g:clang_auto_select != 2
    set completeopt-=menu
    set completeopt+=menuone
  endif

  " Disable every autocmd that could have been set.
  augroup ClangComplete
    autocmd!
  augroup end

  if g:clang_periodic_quickfix == 1
    augroup ClangComplete
      au CursorHold,CursorHoldI <buffer> call <SID>DoPeriodicQuickFix()
    augroup end
  endif

  setlocal completefunc=ClangComplete
  if g:clang_omnicppcomplete_compliance == 0
    setlocal omnifunc=ClangComplete
  endif

endfunction

function! LoadUserOptions()
  let b:clang_user_options = ''

  let l:option_sources = split(g:clang_auto_user_options, ',')
  let l:remove_spaces_cmd = 'substitute(v:val, "\\s*\\(.*\\)\\s*", "\\1", "")'
  let l:option_sources = map(l:option_sources, l:remove_spaces_cmd)

  for l:source in l:option_sources
    if l:source == 'gcc' || l:source == 'clang'
      echo "'" . l:source . "' in clang_auto_user_options is deprecated."
      continue
    endif
    if l:source == 'path'
      call s:parsePathOption()
    elseif l:source == 'compile_commands.json'
      call s:findCompilationDatase(l:source)
    elseif l:source == '.clang_complete'
      call s:parseConfig()
    else
      let l:getopts = 'getopts#' . l:source . '#getopts'
      silent call eval(l:getopts . '()')
    endif
  endfor
endfunction

" Used to tell if a flag needs a space between the flag and file
let s:flagInfo = {
\   '-I': {
\     'pattern': '-I\s*',
\     'output': '-I'
\   },
\   '-F': {
\     'pattern': '-F\s*',
\     'output': '-F'
\   },
\   '-iquote': {
\     'pattern': '-iquote\s*',
\     'output': '-iquote'
\   },
\   '-include': {
\     'pattern': '-include\s\+',
\     'output': '-include '
\   }
\ }

let s:flagPatterns = []
for s:flag in values(s:flagInfo)
  let s:flagPatterns = add(s:flagPatterns, s:flag.pattern)
endfor
let s:flagPattern = '\%(' . join(s:flagPatterns, '\|') . '\)'


function! s:processFilename(filename, root)
  " Handle Unix absolute path
  if matchstr(a:filename, '\C^[''"\\]\=/') != ''
    let l:filename = a:filename
  " Handle Windows absolute path
  elseif s:isWindows() 
       \ && matchstr(a:filename, '\C^"\=[a-zA-Z]:[/\\]') != ''
    let l:filename = a:filename
  " Convert relative path to absolute path
  else
    " If a windows file, the filename may need to be quoted.
    if s:isWindows()
      let l:root = substitute(a:root, '\\', '/', 'g')
      if matchstr(a:filename, '\C^".*"\s*$') == ''
        let l:filename = substitute(a:filename, '\C^\(.\{-}\)\s*$'
                                            \ , '"' . l:root . '\1"', 'g')
      else
        " Strip first double-quote and prepend the root.
        let l:filename = substitute(a:filename, '\C^"\(.\{-}\)"\s*$'
                                            \ , '"' . l:root . '\1"', 'g')
      endif
      let l:filename = substitute(l:filename, '/', '\\', 'g')
    else
      " For Unix, assume the filename is already escaped/quoted correctly
      let l:filename = shellescape(a:root) . a:filename
    endif
  endif
  
  return l:filename
endfunction

function! s:parseConfig()
  let l:local_conf = findfile('.clang_complete', getcwd() . ',.;')
  if l:local_conf == '' || !filereadable(l:local_conf)
    return
  endif

  let l:sep = '/'
  if s:isWindows()
    let l:sep = '\'
  endif

  let l:root = fnamemodify(l:local_conf, ':p:h') . l:sep

  let l:opts = readfile(l:local_conf)
  for l:opt in l:opts
    " Ensure passed filenames are absolute. Only performed on flags which
    " require a filename/directory as an argument, as specified in s:flagInfo
    if matchstr(l:opt, '\C^\s*' . s:flagPattern . '\s*') != ''
      let l:flag = substitute(l:opt, '\C^\s*\(' . s:flagPattern . '\).*'
                            \ , '\1', 'g')
      let l:flag = substitute(l:flag, '^\(.\{-}\)\s*$', '\1', 'g')
      let l:filename = substitute(l:opt,
                                \ '\C^\s*' . s:flagPattern . '\(.\{-}\)\s*$',
                                \ '\1', 'g')
      let l:filename = s:processFilename(l:filename, l:root)
      let l:opt = s:flagInfo[l:flag].output . l:filename
    endif

    let b:clang_user_options .= ' ' . l:opt
  endfor
endfunction

function! s:findCompilationDatase(cdb)
  if g:clang_compilation_database == ''
    let l:local_conf = findfile(a:cdb, getcwd() . ',.;')
    if l:local_conf != '' && filereadable(l:local_conf)
      let g:clang_compilation_database = fnamemodify(l:local_conf, ":p:h")
    endif
  endif
endfunction

function! s:parsePathOption()
  let l:dirs = map(split(&path, '\\\@<![, ]'), 'substitute(v:val, ''\\\([, ]\)'', ''\1'', ''g'')')
  for l:dir in l:dirs
    if len(l:dir) == 0 || !isdirectory(l:dir)
      continue
    endif

    " Add only absolute paths
    if matchstr(l:dir, '\s*/') != ''
      let l:opt = '-I' . shellescape(l:dir)
      let b:clang_user_options .= ' ' . l:opt
    endif
  endfor
endfunction

function! s:initClangCompletePython()
  if !has('python') && !has('python3')
    echoe 'clang_complete: No python support available.'
    echoe 'Cannot use clang library'
    echoe 'Compile vim with python support to use libclang'
    return 0
  endif

  " Only parse the python library once
  if !exists('s:libclang_loaded')
    execute s:py_cmd 'import sys'
    execute s:py_cmd 'import json'

    execute s:py_cmd 'sys.path = ["' . s:plugin_path . '"] + sys.path'
    execute s:pyfile_cmd fnameescape(s:plugin_path) . '/libclang.py'

    try
      execute s:py_cmd 'from snippets.' . g:clang_snippets_engine . ' import *'
      let l:snips_loaded = 1
    catch
      let l:snips_loaded = 0
    endtry
    if l:snips_loaded == 0
      " Oh yeah, vimscript rocks!
      " Putting that echoe inside the catch, will throw an error, and
      " display spurious unwanted errors…
      echoe 'Snippets engine ' . g:clang_snippets_engine . ' not found'
      return 0
    endif

    execute s:py_cmd "vim.command('let l:res = ' + str(initClangComplete(vim.eval('g:clang_complete_lib_flags'),"
                                                    \."vim.eval('g:clang_compilation_database'),"
                                                    \."vim.eval('g:clang_library_path'))))"
    if l:res == 0
      return 0
    endif
    let s:libclang_loaded = 1
  endif
  execute s:py_cmd 'WarmupCache()'
  return 1
endfunction

function! s:DoPeriodicQuickFix()
  " Don't do any superfluous reparsing.
  if b:my_changedtick == b:changedtick
    return
  endif
  let b:my_changedtick = b:changedtick

  execute s:py_cmd 'updateCurrentDiagnostics()'
  call s:ClangQuickFix()
endfunction

function! s:ClangQuickFix()
  " Clear the bad spell, the user may have corrected them.
  syntax clear SpellBad
  syntax clear SpellLocal

  execute s:py_cmd "vim.command('let l:list = ' + json.dumps(getCurrentQuickFixList()))"
  execute s:py_cmd 'highlightCurrentDiagnostics()'

  if g:clang_complete_copen == 1
    " We should get back to the original buffer
    let l:bufnr = bufnr('%')

    " Workaround:
    " http://vim.1045645.n5.nabble.com/setqflist-inconsistency-td1211423.html
    if l:list == []
      cclose
    else
      copen
    endif

    let l:winbufnr = bufwinnr(l:bufnr)
    exe l:winbufnr . 'wincmd w'
  endif
  call setqflist(l:list)
  silent doautocmd QuickFixCmdPost make
endfunction

function! s:escapeCommand(command)
    return s:isWindows() ? a:command : escape(a:command, '()')
endfunction

function! s:isWindows()
  " Check for win32 is enough since it's true on win64
  return has('win32')
endfunction

let b:col = 0

function! ClangComplete(findstart, base)
  if a:findstart
    let l:line = getline('.')
    let l:start = col('.') - 1
    let l:wsstart = l:start
    if l:line[l:wsstart - 1] =~ '\s'
      while l:wsstart > 0 && l:line[l:wsstart - 1] =~ '\s'
        let l:wsstart -= 1
      endwhile
    endif
    while l:start > 0 && l:line[l:start - 1] =~ '\i'
      let l:start -= 1
    endwhile
    let b:col = l:start + 1
    return l:start
  else
    if g:clang_debug == 1
      let l:time_start = reltime()
    endif

    execute s:py_cmd 'snippetsReset()'

    execute s:py_cmd "completions, timer = getCurrentCompletions(vim.eval('a:base'))"
    execute s:py_cmd "vim.command('let l:res = ' + completions)"
    execute s:py_cmd "timer.registerEvent('Load into vimscript')"

    if g:clang_make_default_keymappings == 1
      if s:use_maparg
        let s:old_cr = maparg('<CR>', 'i', 0, 1)
      else
        let s:old_snr = matchstr(maparg('<CR>', 'i'), '<SNR>\d\+_')
      endif
      inoremap <expr> <buffer> <C-Y> <SID>HandlePossibleSelectionCtrlY()
      inoremap <expr> <buffer> <CR> <SID>HandlePossibleSelectionEnter()
    endif
    augroup ClangComplete
      au CursorMovedI <buffer> call <SID>TriggerSnippet()
      if exists('##CompleteDone')
        au CompleteDone,InsertLeave <buffer> call <SID>StopMonitoring()
      else
        au InsertLeave <buffer> call <SID>StopMonitoring()
      endif
    augroup end
    let b:snippet_chosen = 0

    execute s:py_cmd 'timer.finish()'

    if g:clang_debug == 1
      echom 'clang_complete: completion time ' . split(reltimestr(reltime(l:time_start)))[0]
    endif
    return l:res
  endif
endfunction

function! s:HandlePossibleSelectionEnter()
  if pumvisible()
    let b:snippet_chosen = 1
    return "\<C-Y>"
  end
  return "\<CR>"
endfunction

function! s:HandlePossibleSelectionCtrlY()
  if pumvisible()
    let b:snippet_chosen = 1
  end
  return "\<C-Y>"
endfunction

function! s:StopMonitoring()
  if b:snippet_chosen
    call s:TriggerSnippet()
    return
  endif

  if g:clang_make_default_keymappings == 1
    " Restore original return and Ctrl-Y key mappings

    if s:use_maparg
      if get(s:old_cr, 'buffer', 0)
        silent! execute s:old_cr.mode.
            \ (s:old_cr.noremap ? 'noremap '  : 'map').
            \ (s:old_cr.buffer  ? '<buffer> ' : '').
            \ (s:old_cr.expr    ? '<expr> '   : '').
            \ (s:old_cr.nowait  ? '<nowait> ' : '').
            \ s:old_cr.lhs.' '.
            \ substitute(s:old_cr.rhs, '<SID>', '<SNR>'.s:old_cr.sid.'_', 'g')
      else
        silent! iunmap <buffer> <CR>
      endif
    else
      silent! execute substitute(g:clang_restore_cr_imap, '<SID>', s:old_snr, 'g')
    endif

    silent! iunmap <buffer> <C-Y>
  endif

  augroup ClangComplete
    au! CursorMovedI,InsertLeave <buffer>
    if exists('##CompleteDone')
      au! CompleteDone <buffer>
    endif
  augroup END
endfunction

function! s:TriggerSnippet()
  " Dont bother doing anything until we're sure the user exited the menu
  if !b:snippet_chosen
    return
  endif

  " Stop monitoring as we'll trigger a snippet
  let b:snippet_chosen = 0
  call s:StopMonitoring()

  " Trigger the snippet
  execute s:py_cmd 'snippetsTrigger()'

  if g:clang_close_preview
    pclose
  endif
endfunction

function! s:ShouldComplete()
  if (getline('.') =~ '#\s*\(include\|import\)')
    return 0
  else
    if col('.') == 1
      return 1
    endif
    for l:id in synstack(line('.'), col('.') - 1)
      if match(synIDattr(l:id, 'name'), '\CComment\|String\|Number')
            \ != -1
        return 0
      endif
    endfor
    return 1
  endif
endfunction

function! s:LaunchCompletion()
  let l:result = ""
  if s:ShouldComplete()
    let l:result = "\<C-X>\<C-U>"
    if g:clang_auto_select != 2
      let l:result .= "\<C-P>"
    endif
    if g:clang_auto_select == 1
      let l:result .= "\<C-R>=(pumvisible() ? \"\\<Down>\" : '')\<CR>"
    endif
  endif
  return l:result
endfunction

function! s:CompleteDot()
  if g:clang_complete_auto == 1
    return '.' . s:LaunchCompletion()
  endif
  return '.'
endfunction

function! s:CompleteArrow()
  if g:clang_complete_auto != 1 || getline('.')[col('.') - 2] != '-'
    return '>'
  endif
  return '>' . s:LaunchCompletion()
endfunction

function! s:CompleteColon()
  if g:clang_complete_auto != 1 || getline('.')[col('.') - 2] != ':'
    return ':'
  endif
  return ':' . s:LaunchCompletion()
endfunction

function! s:GotoDeclaration(preview)
  try
    execute s:py_cmd "gotoDeclaration(vim.eval('a:preview') == '1')"
  catch /^Vim\%((\a\+)\)\=:E37/
    echoe "The current file is not saved, and 'hidden' is not set."
          \ "Either save the file or add 'set hidden' in your vimrc."
  endtry
  return ''
endfunction

" May be used in a mapping to update the quickfix window.
function! g:ClangUpdateQuickFix()
  call s:DoPeriodicQuickFix()
  return ''
endfunction

function! g:ClangGotoDeclaration()
  call s:GotoDeclaration(0)
  return ''
endfunction

function! g:ClangGotoDeclarationPreview()
  call s:GotoDeclaration(1)
  return ''
endfunction

" vim: set ts=2 sts=2 sw=2 expandtab :
plugin/kinds.py	[[[1
196
# !! GENERATED FILE, DO NOT EDIT
kinds = {
1 : 't', # CXCursor_UnexposedDecl A declaration whose specific kind is not exposed via this interface.
2 : 't', # CXCursor_StructDecl A C or C++ struct.
3 : 't', # CXCursor_UnionDecl A C or C++ union.
4 : 't', # CXCursor_ClassDecl A C++ class.
5 : 't', # CXCursor_EnumDecl An enumeration.
6 : 'm', # CXCursor_FieldDecl A field (in C) or non-static data member (in C++) in a struct, union, or C++ class.
7 : 'e', # CXCursor_EnumConstantDecl An enumerator constant.
8 : 'f', # CXCursor_FunctionDecl A function.
9 : 'v', # CXCursor_VarDecl A variable.
10 : 'a', # CXCursor_ParmDecl A function or method parameter.
11 : '11', # CXCursor_ObjCInterfaceDecl An Objective-C @interface.
12 : '12', # CXCursor_ObjCCategoryDecl An Objective-C @interface for a category.
13 : '13', # CXCursor_ObjCProtocolDecl An Objective-C @protocol declaration.
14 : '14', # CXCursor_ObjCPropertyDecl An Objective-C @property declaration.
15 : '15', # CXCursor_ObjCIvarDecl An Objective-C instance variable.
16 : '16', # CXCursor_ObjCInstanceMethodDecl An Objective-C instance method.
17 : '17', # CXCursor_ObjCClassMethodDecl An Objective-C class method.
18 : '18', # CXCursor_ObjCImplementationDecl An Objective-C @implementation.
19 : '19', # CXCursor_ObjCCategoryImplDecl An Objective-C @implementation for a category.
20 : 't', # CXCursor_TypedefDecl A typedef.
21 : 'f', # CXCursor_CXXMethod A C++ class method.
22 : 'n', # CXCursor_Namespace A C++ namespace.
23 : '23', # CXCursor_LinkageSpec A linkage specification, e.g. 'extern "C"'.
24 : '+', # CXCursor_Constructor A C++ constructor.
25 : '~', # CXCursor_Destructor A C++ destructor.
26 : '26', # CXCursor_ConversionFunction A C++ conversion function.
27 : 'a', # CXCursor_TemplateTypeParameter A C++ template type parameter.
28 : 'a', # CXCursor_NonTypeTemplateParameter A C++ non-type template parameter.
29 : 'a', # CXCursor_TemplateTemplateParameter A C++ template template parameter.
30 : 'f', # CXCursor_FunctionTemplate A C++ function template.
31 : 'p', # CXCursor_ClassTemplate A C++ class template.
32 : '32', # CXCursor_ClassTemplatePartialSpecialization A C++ class template partial specialization.
33 : 'n', # CXCursor_NamespaceAlias A C++ namespace alias declaration.
34 : '34', # CXCursor_UsingDirective A C++ using directive.
35 : '35', # CXCursor_UsingDeclaration A C++ using declaration.
36 : 't', # CXCursor_TypeAliasDecl A C++ alias declaration
37 : '37', # CXCursor_ObjCSynthesizeDecl An Objective-C @synthesize definition.
38 : '38', # CXCursor_ObjCDynamicDecl An Objective-C @dynamic definition.
39 : '39', # CXCursor_CXXAccessSpecifier An access specifier.
40 : '40', # CXCursor_ObjCSuperClassRef An access specifier.
41 : '41', # CXCursor_ObjCProtocolRef An access specifier.
42 : '42', # CXCursor_ObjCClassRef An access specifier.
43 : '43', # CXCursor_TypeRef A reference to a type declaration.
44 : '44', # CXCursor_CXXBaseSpecifier A reference to a type declaration.
45 : '45', # CXCursor_TemplateRef A reference to a class template, function template, template template parameter, or class template partial specialization.
46 : '46', # CXCursor_NamespaceRef A reference to a namespace or namespace alias.
47 : '47', # CXCursor_MemberRef A reference to a member of a struct, union, or class that occurs in some non-expression context, e.g., a designated initializer.
48 : '48', # CXCursor_LabelRef A reference to a labeled statement.
49 : '49', # CXCursor_OverloadedDeclRef A reference to a set of overloaded functions or function templates that has not yet been resolved to a specific function or function template.
50 : '50', # CXCursor_VariableRef A reference to a variable that occurs in some non-expression context, e.g., a C++ lambda capture list.
70 : '70', # CXCursor_InvalidFile A reference to a variable that occurs in some non-expression context, e.g., a C++ lambda capture list.
71 : '71', # CXCursor_NoDeclFound A reference to a variable that occurs in some non-expression context, e.g., a C++ lambda capture list.
72 : 'u', # CXCursor_NotImplemented A reference to a variable that occurs in some non-expression context, e.g., a C++ lambda capture list.
73 : '73', # CXCursor_InvalidCode A reference to a variable that occurs in some non-expression context, e.g., a C++ lambda capture list.
100 : '100', # CXCursor_UnexposedExpr An expression whose specific kind is not exposed via this interface.
101 : '101', # CXCursor_DeclRefExpr An expression that refers to some value declaration, such as a function, variable, or enumerator.
102 : '102', # CXCursor_MemberRefExpr An expression that refers to a member of a struct, union, class, Objective-C class, etc.
103 : '103', # CXCursor_CallExpr An expression that calls a function.
104 : '104', # CXCursor_ObjCMessageExpr An expression that sends a message to an Objective-C object or class.
105 : '105', # CXCursor_BlockExpr An expression that represents a block literal.
106 : '106', # CXCursor_IntegerLiteral An integer literal.
107 : '107', # CXCursor_FloatingLiteral A floating point number literal.
108 : '108', # CXCursor_ImaginaryLiteral An imaginary number literal.
109 : '109', # CXCursor_StringLiteral A string literal.
110 : '110', # CXCursor_CharacterLiteral A character literal.
111 : '111', # CXCursor_ParenExpr A parenthesized expression, e.g. "(1)".
112 : '112', # CXCursor_UnaryOperator This represents the unary-expression's (except sizeof and alignof).
113 : '113', # CXCursor_ArraySubscriptExpr [C99 6.5.2.1] Array Subscripting.
114 : '114', # CXCursor_BinaryOperator A builtin binary operation expression such as "x + y" or "x <= y".
115 : '115', # CXCursor_CompoundAssignOperator Compound assignment such as "+=".
116 : '116', # CXCursor_ConditionalOperator The ?: ternary operator.
117 : '117', # CXCursor_CStyleCastExpr An explicit cast in C (C99 6.5.4) or a C-style cast in C++ (C++ [expr.cast]), which uses the syntax (Type)expr.
118 : '118', # CXCursor_CompoundLiteralExpr [C99 6.5.2.5]
119 : '119', # CXCursor_InitListExpr Describes an C or C++ initializer list.
120 : '120', # CXCursor_AddrLabelExpr The GNU address of label extension, representing &&label.
121 : '121', # CXCursor_StmtExpr This is the GNU Statement Expression extension: ({int X=4; X;})
122 : '122', # CXCursor_GenericSelectionExpr Represents a C11 generic selection.
123 : '123', # CXCursor_GNUNullExpr Implements the GNU __null extension, which is a name for a null pointer constant that has integral type (e.g., int or long) and is the same size and alignment as a pointer.
124 : '124', # CXCursor_CXXStaticCastExpr C++'s static_cast<> expression.
125 : '125', # CXCursor_CXXDynamicCastExpr C++'s dynamic_cast<> expression.
126 : '126', # CXCursor_CXXReinterpretCastExpr C++'s reinterpret_cast<> expression.
127 : '127', # CXCursor_CXXConstCastExpr C++'s const_cast<> expression.
128 : '128', # CXCursor_CXXFunctionalCastExpr Represents an explicit C++ type conversion that uses "functional" notion (C++ [expr.type.conv]).
129 : '129', # CXCursor_CXXTypeidExpr A C++ typeid expression (C++ [expr.typeid]).
130 : '130', # CXCursor_CXXBoolLiteralExpr [C++ 2.13.5] C++ Boolean Literal.
131 : '131', # CXCursor_CXXNullPtrLiteralExpr [C++0x 2.14.7] C++ Pointer Literal.
132 : '132', # CXCursor_CXXThisExpr Represents the "this" expression in C++
133 : '133', # CXCursor_CXXThrowExpr [C++ 15] C++ Throw Expression.
134 : '134', # CXCursor_CXXNewExpr A new expression for memory allocation and constructor calls, e.g: "new CXXNewExpr(foo)".
135 : '135', # CXCursor_CXXDeleteExpr A delete expression for memory deallocation and destructor calls, e.g. "delete[] pArray".
136 : '136', # CXCursor_UnaryExpr A unary expression.
137 : '137', # CXCursor_ObjCStringLiteral An Objective-C string literal i.e. "foo".
138 : '138', # CXCursor_ObjCEncodeExpr An Objective-C @encode expression.
139 : '139', # CXCursor_ObjCSelectorExpr An Objective-C @selector expression.
140 : '140', # CXCursor_ObjCProtocolExpr An Objective-C @protocol expression.
141 : '141', # CXCursor_ObjCBridgedCastExpr An Objective-C "bridged" cast expression, which casts between Objective-C pointers and C pointers, transferring ownership in the process.
142 : '142', # CXCursor_PackExpansionExpr Represents a C++0x pack expansion that produces a sequence of expressions.
143 : '143', # CXCursor_SizeOfPackExpr Represents an expression that computes the length of a parameter pack.
144 : '144', # CXCursor_LambdaExpr None
145 : '145', # CXCursor_ObjCBoolLiteralExpr Objective-c Boolean Literal.
146 : '146', # CXCursor_ObjCSelfExpr Represents the "self" expression in an Objective-C method.
147 : '147', # CXCursor_OMPArraySectionExpr OpenMP 4.0 [2.4, Array Section].
200 : '200', # CXCursor_UnexposedStmt A statement whose specific kind is not exposed via this interface.
201 : '201', # CXCursor_LabelStmt A labelled statement in a function.
202 : '202', # CXCursor_CompoundStmt A group of statements like { stmt stmt }.
203 : '203', # CXCursor_CaseStmt A case statement.
204 : '204', # CXCursor_DefaultStmt A default statement.
205 : '205', # CXCursor_IfStmt An if statement
206 : '206', # CXCursor_SwitchStmt A switch statement.
207 : '207', # CXCursor_WhileStmt A while statement.
208 : '208', # CXCursor_DoStmt A do statement.
209 : '209', # CXCursor_ForStmt A for statement.
210 : '210', # CXCursor_GotoStmt A goto statement.
211 : '211', # CXCursor_IndirectGotoStmt An indirect goto statement.
212 : '212', # CXCursor_ContinueStmt A continue statement.
213 : '213', # CXCursor_BreakStmt A break statement.
214 : '214', # CXCursor_ReturnStmt A return statement.
215 : '215', # CXCursor_GCCAsmStmt A GCC inline assembly statement extension.
215 : '215', # CXCursor_AsmStmt A GCC inline assembly statement extension.
216 : '216', # CXCursor_ObjCAtTryStmt Objective-C's overall @try-@catch-@finally statement.
217 : '217', # CXCursor_ObjCAtCatchStmt Objective-C's @catch statement.
218 : '218', # CXCursor_ObjCAtFinallyStmt Objective-C's @finally statement.
219 : '219', # CXCursor_ObjCAtThrowStmt Objective-C's @throw statement.
220 : '220', # CXCursor_ObjCAtSynchronizedStmt Objective-C's @synchronized statement.
221 : '221', # CXCursor_ObjCAutoreleasePoolStmt Objective-C's autorelease pool statement.
222 : '222', # CXCursor_ObjCForCollectionStmt Objective-C's collection statement.
223 : '223', # CXCursor_CXXCatchStmt C++'s catch statement.
224 : '224', # CXCursor_CXXTryStmt C++'s try statement.
225 : '225', # CXCursor_CXXForRangeStmt C++'s for (* : *) statement.
226 : '226', # CXCursor_SEHTryStmt Windows Structured Exception Handling's try statement.
227 : '227', # CXCursor_SEHExceptStmt Windows Structured Exception Handling's except statement.
228 : '228', # CXCursor_SEHFinallyStmt Windows Structured Exception Handling's finally statement.
229 : '229', # CXCursor_MSAsmStmt A MS inline assembly statement extension.
230 : '230', # CXCursor_NullStmt The null statement ";": C99 6.8.3p3.
231 : '231', # CXCursor_DeclStmt Adaptor class for mixing declarations with statements and expressions.
232 : '232', # CXCursor_OMPParallelDirective OpenMP parallel directive.
233 : '233', # CXCursor_OMPSimdDirective OpenMP SIMD directive.
234 : '234', # CXCursor_OMPForDirective OpenMP for directive.
235 : '235', # CXCursor_OMPSectionsDirective OpenMP sections directive.
236 : '236', # CXCursor_OMPSectionDirective OpenMP section directive.
237 : '237', # CXCursor_OMPSingleDirective OpenMP single directive.
238 : '238', # CXCursor_OMPParallelForDirective OpenMP parallel for directive.
239 : '239', # CXCursor_OMPParallelSectionsDirective OpenMP parallel sections directive.
240 : '240', # CXCursor_OMPTaskDirective OpenMP task directive.
241 : '241', # CXCursor_OMPMasterDirective OpenMP master directive.
242 : '242', # CXCursor_OMPCriticalDirective OpenMP critical directive.
243 : '243', # CXCursor_OMPTaskyieldDirective OpenMP taskyield directive.
244 : '244', # CXCursor_OMPBarrierDirective OpenMP barrier directive.
245 : '245', # CXCursor_OMPTaskwaitDirective OpenMP taskwait directive.
246 : '246', # CXCursor_OMPFlushDirective OpenMP flush directive.
247 : '247', # CXCursor_SEHLeaveStmt Windows Structured Exception Handling's leave statement.
248 : '248', # CXCursor_OMPOrderedDirective OpenMP ordered directive.
249 : '249', # CXCursor_OMPAtomicDirective OpenMP atomic directive.
250 : '250', # CXCursor_OMPForSimdDirective OpenMP for SIMD directive.
251 : '251', # CXCursor_OMPParallelForSimdDirective OpenMP parallel for SIMD directive.
252 : '252', # CXCursor_OMPTargetDirective OpenMP target directive.
253 : '253', # CXCursor_OMPTeamsDirective OpenMP teams directive.
254 : '254', # CXCursor_OMPTaskgroupDirective OpenMP taskgroup directive.
255 : '255', # CXCursor_OMPCancellationPointDirective OpenMP cancellation point directive.
256 : '256', # CXCursor_OMPCancelDirective OpenMP cancel directive.
257 : '257', # CXCursor_OMPTargetDataDirective OpenMP target data directive.
258 : '258', # CXCursor_OMPTaskLoopDirective OpenMP taskloop directive.
259 : '259', # CXCursor_OMPTaskLoopSimdDirective OpenMP taskloop simd directive.
260 : '260', # CXCursor_OMPDistributeDirective OpenMP distribute directive.
300 : '300', # CXCursor_TranslationUnit Cursor that represents the translation unit itself.
400 : '400', # CXCursor_UnexposedAttr An attribute whose specific kind is not exposed via this interface.
401 : '401', # CXCursor_IBActionAttr An attribute whose specific kind is not exposed via this interface.
402 : '402', # CXCursor_IBOutletAttr An attribute whose specific kind is not exposed via this interface.
403 : '403', # CXCursor_IBOutletCollectionAttr An attribute whose specific kind is not exposed via this interface.
404 : '404', # CXCursor_CXXFinalAttr An attribute whose specific kind is not exposed via this interface.
405 : '405', # CXCursor_CXXOverrideAttr An attribute whose specific kind is not exposed via this interface.
406 : '406', # CXCursor_AnnotateAttr An attribute whose specific kind is not exposed via this interface.
407 : '407', # CXCursor_AsmLabelAttr An attribute whose specific kind is not exposed via this interface.
408 : '408', # CXCursor_PackedAttr An attribute whose specific kind is not exposed via this interface.
409 : '409', # CXCursor_PureAttr An attribute whose specific kind is not exposed via this interface.
410 : '410', # CXCursor_ConstAttr An attribute whose specific kind is not exposed via this interface.
411 : '411', # CXCursor_NoDuplicateAttr An attribute whose specific kind is not exposed via this interface.
412 : '412', # CXCursor_CUDAConstantAttr An attribute whose specific kind is not exposed via this interface.
413 : '413', # CXCursor_CUDADeviceAttr An attribute whose specific kind is not exposed via this interface.
414 : '414', # CXCursor_CUDAGlobalAttr An attribute whose specific kind is not exposed via this interface.
415 : '415', # CXCursor_CUDAHostAttr An attribute whose specific kind is not exposed via this interface.
416 : '416', # CXCursor_CUDASharedAttr An attribute whose specific kind is not exposed via this interface.
417 : '417', # CXCursor_VisibilityAttr An attribute whose specific kind is not exposed via this interface.
418 : '418', # CXCursor_DLLExport An attribute whose specific kind is not exposed via this interface.
419 : '419', # CXCursor_DLLImport An attribute whose specific kind is not exposed via this interface.
500 : '500', # CXCursor_PreprocessingDirective An attribute whose specific kind is not exposed via this interface.
501 : 'd', # CXCursor_MacroDefinition An attribute whose specific kind is not exposed via this interface.
502 : '502', # CXCursor_MacroExpansion An attribute whose specific kind is not exposed via this interface.
502 : '502', # CXCursor_MacroInstantiation An attribute whose specific kind is not exposed via this interface.
503 : '503', # CXCursor_InclusionDirective An attribute whose specific kind is not exposed via this interface.
600 : '600', # CXCursor_ModuleImportDecl A module import declaration.
601 : 'ta', # CXCursor_TypeAliasTemplateDecl A module import declaration.
700 : 'oc', # CXCursor_OverloadCandidate A code completion overload candidate.
}
plugin/libclang.py	[[[1
608
from __future__ import print_function

from clang.cindex import *
import vim
import time
import threading
import os
import shlex

from kinds import kinds

def decode(value):
  import sys
  if sys.version_info[0] == 2:
    return value

  try:
    return value.decode('utf-8')
  except AttributeError:
    return value

# Check if libclang is able to find the builtin include files.
#
# libclang sometimes fails to correctly locate its builtin include files. This
# happens especially if libclang is not installed at a standard location. This
# function checks if the builtin includes are available.
def canFindBuiltinHeaders(index, args = []):
  flags = 0
  currentFile = ("test.c", '#include "stddef.h"')
  try:
    tu = index.parse("test.c", args, [currentFile], flags)
  except TranslationUnitLoadError as e:
    return 0
  return len(tu.diagnostics) == 0

# Derive path to clang builtin headers.
#
# This function tries to derive a path to clang's builtin header files. We are
# just guessing, but the guess is very educated. In fact, we should be right
# for all manual installations (the ones where the builtin header path problem
# is very common) as well as a set of very common distributions.
def getBuiltinHeaderPath(library_path):
  if os.path.isfile(library_path):
    library_path = os.path.dirname(library_path)

  knownPaths = [
          library_path + "/../lib/clang",  # default value
          library_path + "/../clang",      # gentoo
          library_path + "/clang",         # opensuse
          library_path + "/",              # Google
          "/usr/lib64/clang",              # x86_64 (openSUSE, Fedora)
          "/usr/lib/clang"
  ]

  for path in knownPaths:
    try:
      subDirs = [f for f in os.listdir(path) if os.path.isdir(path + "/" + f)]
      subDirs = sorted(subDirs) or ['.']
      path = path + "/" + subDirs[-1] + "/include"
      if canFindBuiltinHeaders(index, ["-I" + path]):
        return path
    except:
      pass

  return None

def initClangComplete(clang_complete_flags, clang_compilation_database, \
                      library_path):
  global index

  debug = int(vim.eval("g:clang_debug")) == 1

  if library_path:
    if os.path.isdir(library_path):
      Config.set_library_path(library_path)
    else:
      Config.set_library_file(library_path)

  Config.set_compatibility_check(False)

  try:
    index = Index.create()
  except Exception as e:
    if library_path:
      suggestion = "Are you sure '%s' contains libclang?" % library_path
    else:
      suggestion = "Consider setting g:clang_library_path."

    if debug:
      exception_msg = str(e)
    else:
      exception_msg = ''

    print('''Loading libclang failed, completion won't be available. %s
    %s
    ''' % (suggestion, exception_msg))
    return 0

  global builtinHeaderPath
  builtinHeaderPath = None
  if not canFindBuiltinHeaders(index):
    builtinHeaderPath = getBuiltinHeaderPath(library_path)

    if not builtinHeaderPath:
      print("WARNING: libclang can not find the builtin includes.")
      print("         This will cause slow code completion.")
      print("         Please report the problem.")

  # Cache of translation units.  Maps paths of files:
  # <source file path> : {
  #   'tu':   <translation unit object>,
  #   'args': <list of arguments>,
  # }
  # New cache entry for the same path, but with different list of arguments,
  # overwrite previously cached data.
  global translationUnits
  translationUnits = dict()

  global complete_flags
  complete_flags = int(clang_complete_flags)
  global compilation_database
  if clang_compilation_database != '':
    compilation_database = CompilationDatabase.fromDirectory(clang_compilation_database)
  else:
    compilation_database = None
  global libclangLock
  libclangLock = threading.Lock()
  return 1

# Get a tuple (fileName, fileContent) for the file opened in the current
# vim buffer. The fileContent contains the unsafed buffer content.
def getCurrentFile():
  file = "\n".join(vim.current.buffer[:] + ["\n"])
  return (vim.current.buffer.name, file)

class CodeCompleteTimer:
  def __init__(self, debug, file, line, column, params):
    self._debug = debug

    if not debug:
      return

    content = vim.current.line
    print(" ")
    print("libclang code completion")
    print("========================")
    print("Command: clang %s -fsyntax-only " % " ".join(decode(params['args'])), end=' ')
    print("-Xclang -code-completion-at=%s:%d:%d %s"
       % (file, line, column, file))
    print("cwd: %s" % params['cwd'])
    print("File: %s" % file)
    print("Line: %d, Column: %d" % (line, column))
    print(" ")
    print("%s" % content)

    print(" ")

    current = time.time()
    self._start = current
    self._last = current
    self._events = []

  def registerEvent(self, event):
    if not self._debug:
      return

    current = time.time()
    since_last = current - self._last
    self._last = current
    self._events.append((event, since_last))

  def finish(self):
    if not self._debug:
      return

    overall = self._last - self._start

    for event in self._events:
      name, since_last = event
      percent = 1 / overall * since_last * 100
      print("libclang code completion - %25s: %.3fs (%5.1f%%)" % \
        (name, since_last, percent))

    print(" ")
    print("Overall: %.3f s" % overall)
    print("========================")
    print(" ")

def getCurrentTranslationUnit(args, currentFile, fileName, timer,
                              update = False):
  tuCache = translationUnits.get(fileName)
  if tuCache is not None and tuCache['args'] == args:
    tu = tuCache['tu']
    if update:
      tu.reparse([currentFile])
      timer.registerEvent("Reparsing")
    return tu

  flags = TranslationUnit.PARSE_PRECOMPILED_PREAMBLE | \
          TranslationUnit.PARSE_DETAILED_PROCESSING_RECORD
  try:
    tu = index.parse(fileName, args, [currentFile], flags)
    timer.registerEvent("First parse")
  except TranslationUnitLoadError as e:
    return None

  translationUnits[fileName] = { 'tu': tu, 'args': args }

  # Reparse to initialize the PCH cache even for auto completion
  # This should be done by index.parse(), however it is not.
  # So we need to reparse ourselves.
  tu.reparse([currentFile])
  timer.registerEvent("Generate PCH cache")
  return tu

def splitOptions(options):
  # Use python's shell command lexer to correctly split the list of options in
  # accordance with the POSIX standard
  return shlex.split(options)

def getQuickFix(diagnostic):
  # Some diagnostics have no file, e.g. "too many errors emitted, stopping now"
  if diagnostic.location.file:
    filename = decode(diagnostic.location.file.name)
  else:
    filename = ""

  if diagnostic.severity == diagnostic.Ignored:
    type = 'I'
  elif diagnostic.severity == diagnostic.Note:
    type = 'I'
  elif diagnostic.severity == diagnostic.Warning:
    if "argument unused during compilation" in decode(diagnostic.spelling):
      return None
    type = 'W'
  elif diagnostic.severity == diagnostic.Error:
    type = 'E'
  elif diagnostic.severity == diagnostic.Fatal:
    type = 'E'
  else:
    return None

  return dict({ 'bufnr' : int(vim.eval("bufnr('" + filename + "', 1)")),
    'lnum' : diagnostic.location.line,
    'col' : diagnostic.location.column,
    'text' : decode(diagnostic.spelling),
    'type' : type})

def getQuickFixList(tu):
  return [_f for _f in map (getQuickFix, tu.diagnostics) if _f]

def highlightRange(range, hlGroup):
  pattern = '/\%' + str(range.start.line) + 'l' + '\%' \
      + str(range.start.column) + 'c' + '.*' \
      + '\%' + str(range.end.column) + 'c/'
  command = "exe 'syntax match' . ' " + hlGroup + ' ' + pattern + "'"
  vim.command(command)

def highlightDiagnostic(diagnostic):
  if diagnostic.location.file is None or \
     decode(diagnostic.location.file.name) != vim.eval('expand("%:p")'):
    return

  if diagnostic.severity == diagnostic.Warning:
    hlGroup = 'SpellLocal'
  elif diagnostic.severity == diagnostic.Error:
    hlGroup = 'SpellBad'
  else:
    return

  pattern = '/\%' + str(diagnostic.location.line) + 'l\%' \
      + str(diagnostic.location.column) + 'c./'
  command = "exe 'syntax match' . ' " + hlGroup + ' ' + pattern + "'"
  vim.command(command)

  for range in diagnostic.ranges:
    highlightRange(range, hlGroup)

def highlightDiagnostics(tu):
  for diagnostic in tu.diagnostics:
    highlightDiagnostic(diagnostic)

def highlightCurrentDiagnostics():
  if vim.current.buffer.name in translationUnits:
    highlightDiagnostics(translationUnits[vim.current.buffer.name]['tu'])

def getCurrentQuickFixList():
  if vim.current.buffer.name in translationUnits:
    return getQuickFixList(translationUnits[vim.current.buffer.name]['tu'])
  return []

# Get the compilation parameters from the compilation database for source
# 'fileName'. The parameters are returned as map with the following keys :
#
#   'args' : compiler arguments.
#            Compilation database returns the complete command line. We need
#            to filter at least the compiler invocation, the '-o' + output
#            file, the input file and the '-c' arguments. We alter -I paths
#            to make them absolute, so that we can launch clang from wherever
#            we are.
#            Note : we behave differently from cc_args.py which only keeps
#            '-I', '-D' and '-include' options.
#
#    'cwd' : the compiler working directory
#
# The last found args and cwd are remembered and reused whenever a file is
# not found in the compilation database. For example, this is the case for
# all headers. This achieve very good results in practice.
def getCompilationDBParams(fileName):
  if compilation_database:
    cmds = compilation_database.getCompileCommands(fileName)
    if cmds != None:
      cwd = decode(cmds[0].directory)
      args = []
      skip_next = 1 # Skip compiler invocation
      for arg in (decode(x) for x in cmds[0].arguments):
        if skip_next:
          skip_next = 0;
          continue
        if arg == '-c':
          continue
        if arg == fileName or \
           os.path.realpath(os.path.join(cwd, arg)) == fileName:
          continue
        if arg == '-o':
          skip_next = 1;
          continue
        if arg.startswith('-I'):
          includePath = arg[2:]
          if not os.path.isabs(includePath):
            includePath = os.path.normpath(os.path.join(cwd, includePath))
          args.append('-I'+includePath)
          continue
        args.append(arg)
      getCompilationDBParams.last_query = { 'args': args, 'cwd': cwd }

  # Do not directly return last_query, but make sure we return a deep copy.
  # Otherwise users of that result may accidently change it and store invalid
  # values in our cache.
  query = getCompilationDBParams.last_query
  return { 'args': list(query['args']), 'cwd': query['cwd']}

getCompilationDBParams.last_query = { 'args': [], 'cwd': None }

def getCompileParams(fileName):
  global builtinHeaderPath
  params = getCompilationDBParams(fileName)
  args = params['args']
  args += splitOptions(vim.eval("g:clang_user_options"))
  args += splitOptions(vim.eval("b:clang_user_options"))
  args += splitOptions(vim.eval("b:clang_parameters"))

  if builtinHeaderPath and '-nobuiltininc' not in args:
    args.append("-I" + builtinHeaderPath)

  return { 'args' : args,
           'cwd' : params['cwd'] }

def updateCurrentDiagnostics():
  global debug
  debug = int(vim.eval("g:clang_debug")) == 1
  params = getCompileParams(vim.current.buffer.name)
  timer = CodeCompleteTimer(debug, vim.current.buffer.name, -1, -1, params)

  with libclangLock:
    getCurrentTranslationUnit(params['args'], getCurrentFile(),
                              vim.current.buffer.name, timer, update = True)
  timer.finish()

def getCurrentCompletionResults(line, column, args, currentFile, fileName,
                                timer):

  tu = getCurrentTranslationUnit(args, currentFile, fileName, timer)
  timer.registerEvent("Get TU")

  if tu == None:
    return None

  cr = tu.codeComplete(fileName, line, column, [currentFile],
      complete_flags)

  timer.registerEvent("Code Complete")
  return cr

"""
A normal dictionary will escape single quotes by doing
"\'", but vimscript expects them to be escaped as "''".
This dictionary inherits from the built-in dict and overrides
repr to call the original, then re-escape single quotes in
the way that vimscript expects
"""
class VimscriptEscapingDict(dict):
  def __repr__(self):
    repr = super(VimscriptEscapingDict, self).__repr__()
    new_repr = repr.replace("\\'", "''")
    return new_repr

def formatResult(result):
  completion = VimscriptEscapingDict()
  returnValue = None
  abbr = ""
  word = ""
  info = ""
  place_markers_for_optional_args = int(vim.eval("g:clang_complete_optional_args_in_snippets")) == 1

  def roll_out_optional(chunks):
    result = []
    word = ""
    for chunk in chunks:
      if chunk.isKindInformative() or chunk.isKindResultType() or chunk.isKindTypedText():
        continue

      word += decode(chunk.spelling)
      if chunk.isKindOptional():
        result += roll_out_optional(chunk.string)

    return [word] + result

  for chunk in result.string:

    if chunk.isKindInformative():
      continue

    if chunk.isKindResultType():
      returnValue = chunk
      continue

    chunk_spelling = decode(chunk.spelling)

    if chunk.isKindTypedText():
      abbr = chunk_spelling

    if chunk.isKindOptional():
      for optional_arg in roll_out_optional(chunk.string):
        if place_markers_for_optional_args:
          word += snippetsFormatPlaceHolder(optional_arg)
        info += optional_arg + "=?"

    if chunk.isKindPlaceHolder():
      word += snippetsFormatPlaceHolder(chunk_spelling)
    else:
      word += chunk_spelling

    info += chunk_spelling

  menu = info

  if returnValue:
    menu = decode(returnValue.spelling) + " " + menu

  completion['word'] = snippetsAddSnippet(info, word, abbr)
  completion['abbr'] = abbr
  completion['menu'] = menu
  completion['info'] = info
  completion['dup'] = 1

  # Replace the number that represents a specific kind with a better
  # textual representation.
  completion['kind'] = kinds[result.cursorKind]

  return completion


class CompleteThread(threading.Thread):
  def __init__(self, line, column, currentFile, fileName, params, timer):
    threading.Thread.__init__(self)
    # Complete threads are daemon threads. Python and consequently vim does not
    # wait for daemon threads to finish execution when existing itself. As
    # clang may compile for a while, we do not have to wait for the compilation
    # to finish before vim can quit. Before adding this flags, vim was hanging
    # for a couple of seconds before it exited.
    self.daemon = True
    self.line = line
    self.column = column
    self.currentFile = currentFile
    self.fileName = fileName
    self.result = None
    self.args = params['args']
    self.cwd = params['cwd']
    self.timer = timer

  def run(self):
    with libclangLock:
      if self.line == -1:
        # Warm up the caches. For this it is sufficient to get the
        # current translation unit. No need to retrieve completion
        # results.  This short pause is necessary to allow vim to
        # initialize itself.  Otherwise we would get: E293: block was
        # not locked The user does not see any delay, as we just pause
        # a background thread.
        time.sleep(0.1)
        getCurrentTranslationUnit(self.args, self.currentFile, self.fileName,
                                  self.timer)
      else:
        self.result = getCurrentCompletionResults(self.line, self.column,
                                                  self.args, self.currentFile,
                                                  self.fileName, self.timer)

def WarmupCache():
  params = getCompileParams(vim.current.buffer.name)
  timer = CodeCompleteTimer(0, "", -1, -1, params)
  t = CompleteThread(-1, -1, getCurrentFile(), vim.current.buffer.name,
                     params, timer)
  t.start()

def getCurrentCompletions(base):
  global debug
  debug = int(vim.eval("g:clang_debug")) == 1
  sorting = vim.eval("g:clang_sort_algo")
  line, _ = vim.current.window.cursor
  column = int(vim.eval("b:col"))
  params = getCompileParams(vim.current.buffer.name)

  timer = CodeCompleteTimer(debug, vim.current.buffer.name, line, column,
                            params)

  t = CompleteThread(line, column, getCurrentFile(), vim.current.buffer.name,
                     params, timer)
  t.start()
  while t.isAlive():
    t.join(0.01)
    cancel = int(vim.eval('complete_check()'))
    if cancel != 0:
      return (str([]), timer)

  cr = t.result
  if cr is None:
    print("Cannot parse this source file. The following arguments "
        + "are used for clang: " + " ".join(decode(params['args'])))
    return (str([]), timer)

  results = cr.results

  timer.registerEvent("Count # Results (%s)" % str(len(results)))

  if base != "":
    results = [x for x in results if getAbbr(x.string).startswith(base)]

  timer.registerEvent("Filter")

  if sorting == 'priority':
    getPriority = lambda x: x.string.priority
    results = sorted(results, key=getPriority)
  if sorting == 'alpha':
    getAbbrevation = lambda x: getAbbr(x.string).lower()
    results = sorted(results, key=getAbbrevation)

  timer.registerEvent("Sort")

  result = list(map(formatResult, results))

  timer.registerEvent("Format")
  return (str(result), timer)

def getAbbr(strings):
  for chunks in strings:
    if chunks.isKindTypedText():
      return decode(chunks.spelling)
  return ""

def jumpToLocation(filename, line, column, preview):
  filenameEscaped = decode(filename).replace(" ", "\\ ")
  if preview:
    command = "pedit +%d %s" % (line, filenameEscaped)
  elif filename != vim.current.buffer.name:
    command = "edit %s" % filenameEscaped
  else:
    command = "normal! m'"
  try:
    vim.command(command)
  except:
    # For some unknown reason, whenever an exception occurs in
    # vim.command, vim goes crazy and output tons of useless python
    # errors, catch those.
    return
  if not preview:
    vim.current.window.cursor = (line, column - 1)

def gotoDeclaration(preview=True):
  global debug
  debug = int(vim.eval("g:clang_debug")) == 1
  params = getCompileParams(vim.current.buffer.name)
  line, col = vim.current.window.cursor
  timer = CodeCompleteTimer(debug, vim.current.buffer.name, line, col, params)

  with libclangLock:
    tu = getCurrentTranslationUnit(params['args'], getCurrentFile(),
                                   vim.current.buffer.name, timer,
                                   update = True)
    if tu is None:
      print("Couldn't get the TranslationUnit")
      return

    f = File.from_name(tu, vim.current.buffer.name)
    loc = SourceLocation.from_position(tu, f, line, col + 1)
    cursor = Cursor.from_location(tu, loc)
    defs = [cursor.get_definition(), cursor.referenced]

    for d in defs:
      if d is not None and loc != d.location:
        loc = d.location
        if loc.file is not None:
          jumpToLocation(loc.file.name, loc.line, loc.column, preview)
        break

  timer.finish()

# vim: set ts=2 sts=2 sw=2 expandtab :
plugin/snippets/__init__.py	[[[1
1
__all__ = ['clang_complete', 'ultisnips', 'dummy']
plugin/snippets/clang_complete.py	[[[1
48
import re
import vim

def snippetsInit():
  python_cmd = vim.eval('s:py_cmd')
  vim.command("noremap <silent> <buffer> <tab> :{} updateSnips()<CR>".format(python_cmd))
  vim.command("snoremap <silent> <buffer> <tab> <ESC>:{} updateSnips()<CR>".format(python_cmd))
  if int(vim.eval("g:clang_conceal_snippets")) == 1:
    vim.command("syntax match placeHolder /\$`[^`]*`/ contains=placeHolderMark")
    vim.command("syntax match placeHolderMark contained /\$`/ conceal")
    vim.command("syntax match placeHolderMark contained /`/ conceal")

# The two following function are performance sensitive, do _nothing_
# more that the strict necessary.

def snippetsFormatPlaceHolder(word):
  return "$`%s`" % word

def snippetsAddSnippet(fullname, word, abbr):
  return word

r = re.compile('\$`[^`]*`')

def snippetsTrigger():
  if r.search(vim.current.line) is None:
    return
  vim.command('call feedkeys("\<esc>^\<tab>")')

def snippetsReset():
  pass

def updateSnips():
  line = vim.current.line
  row, col = vim.current.window.cursor

  result = r.search(line, col)
  if result is None:
    result = r.search(line)
    if result is None:
      vim.command('call feedkeys("\<c-i>", "n")')
      return

  start, end = result.span()
  vim.current.window.cursor = row, start
  isInclusive = vim.eval("&selection") == "inclusive"
  vim.command('call feedkeys("\<ESC>v%dl\<C-G>", "n")' % (end - start - isInclusive))

# vim: set ts=2 sts=2 sw=2 expandtab :
plugin/snippets/dummy.py	[[[1
16
def snippetsInit():
  pass

def snippetsFormatPlaceHolder(word):
  return ''

def snippetsAddSnippet(fullname, word, abbr):
  return abbr

def snippetsTrigger():
  pass

def snippetsReset():
  pass

# vim: set ts=2 sts=2 sw=2 expandtab :
plugin/snippets/ultisnips.py	[[[1
39
import vim
import re

try:
  from UltiSnips import UltiSnips_Manager
except:
  from UltiSnips import SnippetManager

  UltiSnips_Manager = SnippetManager(
      vim.eval('g:UltiSnipsExpandTrigger'),
      vim.eval('g:UltiSnipsJumpForwardTrigger'),
      vim.eval('g:UltiSnipsJumpBackwardTrigger'))

def snippetsInit():
  global ultisnips_idx
  ultisnips_idx = 0
  UltiSnips_Manager.add_buffer_filetypes('%s.clang_complete' % vim.eval('&filetype'))

def snippetsFormatPlaceHolder(word):
  # Better way to do that?
  global ultisnips_idx
  ultisnips_idx += 1
  return '${%d:%s}' % (ultisnips_idx, word)

def snippetsAddSnippet(fullname, word, abbr):
  global ultisnips_idx
  ultisnips_idx = 0
  UltiSnips_Manager.add_snippet(fullname, word, fullname, "i", "clang_complete")
  return fullname

def snippetsTrigger():
  print(vim.current.line)
  UltiSnips_Manager.expand()

def snippetsReset():
  if "clang_complete" in UltiSnips_Manager._added_snippets_source._snippets:
    UltiSnips_Manager._added_snippets_source._snippets["clang_complete"]._snippets = []

# vim: set ts=2 sts=2 sw=2 expandtab :
