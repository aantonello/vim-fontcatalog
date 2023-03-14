" Vim Font Catalog Plugin
" Description: Simple Font Catalog.
" Version: 2.0
" Maintainer: Alessandro Antonello <antonello dot ale at gmail do com>
" Last Change: May 13, 2014
"              2023 Março 13
" License: This script is in plublic domain.
" ============================================================================
" Load it only once. Or you can disable it easily.
if exists('g:loaded_fontcatalog') || !has('gui_running')
  finish
endif
let g:loaded_fontcatalog = 1

import '../include/command.vim' as commands

"" Initializing global options:
let g:fc_DontUseDefault = get(g:, 'fc_DontUseDefault', v:false)
let g:fc_DefaultFont = get(g:, 'fc_DefaultFont', '')
let g:fc_CatalogFolder = get(g:, 'fc_CatalogFolder', expand('$HOME/.fontcatalog'))

" Script local functions: {{{
if !exists('s:FontCommand')
  function s:FontCommand(...)
    if a:0 == 0
      call commands.Font()

    elseif a:0 == 1
      call commands.Font(a:1)

    else
      call commands.Font(a:1, a:000[1:])
    endif
  endfunction

  function s:CategoryCommand(...)
    if a:0 == 0
      call commands.Category()

    elseif a:0 == 1
      call commands.Category(a:1)

    else
      call commands.Category(a:1, a:000[1:])
    endif
  endfunction

  function s:CompleteFont(a, c, p)
    return commands.FontComplete(a:a, a:c, a:p)
  endfunction
endif
" Script local functions: }}}

" Comands: {{{
command -nargs=* -complete=customlist,s:CompleteFont         Font          :call s:FontCommand(<f-args>)

let s:CompleteCategory = function(commands.CategoryComplete)
command -nargs=* -complete=customlist,s:CompleteCategory     Category      :call s:CategoryCommand(<f-args>)
" Comands: }}}

" Schedule de definition of the default font at GUI enter
autocmd GUIEnter * call commands.SetDefault()

