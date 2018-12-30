" Vim Font Catalog Plugin
" Description: Simple Font Catalog.
" Version: 1.0
" Maintainer: Alessandro Antonello <antonello dot ale at gmail do com>
" Last Change: May 13, 2014
" License: This script is in plublic domain.
" ============================================================================

" Load it only once. Or you can disable it easily.
if exists('g:loaded_fontcatalog') || !has('gui_running')
    finish
endif
let g:loaded_fontcatalog = 1

"" Commands
" Add the current font to one or more categories
command -nargs=+ -complete=customlist,fontcatalog#listCategories FontAdd :call fontcatalog#addFont(<f-args>)

" Remove the current font from one or more categories in the catalog.
command -nargs=* -complete=customlist,fontcatalog#listCategories FontRm :call fontcatalog#removeCurrent(<f-args>)

" Remove an specified font from all categories in the catalog.
command -nargs=1 -complete=customlist,fontcatalog#listFonts FontRmFont :call fontcatalog#removeFont(<args>)

" Remove a category from the catalog.
command -nargs=1 -complete=customlist,fontcatalog#listCategories FontRmCat :call fontcatalog#removeCategory(<f-args>)

" Lists the current categories
command -nargs=? -complete=customlist,fontcatalog#listCategories FontCategories :echo fontcatalog#categoryInfo(<f-args>)

" List all fonts within a category or categories.
command -nargs=* -complete=customlist,fontcatalog#listCategories Fonts :echo fontcatalog#listFonts(<f-args>)

" Sets a font to be used.
command -nargs=? -complete=customlist,fontcatalog#listFonts Font :call fontcatalog#removeCategory(<f-args>)

" Set a default font or use one from the previous session. We build an
" 'autocmd' because this script is sourced before the GUI enters.
" Do nothing if 'g:fc_DontUseDefault' is set.
if exists('g:fc_DontUseDefault') && g:fc_DontUseDefault == 1
    finish
endif

autocmd GUIEnter * call fontcatalog#setDefault()
" vim:ff=unix:fdm=marker:fmr=<<<,>>>
