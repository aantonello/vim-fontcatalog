" Vim Font Catalog Plugin.
" Description: Simple Font Catalog.
" Version: 2.0
" Maintainer: Alessandro Antonello <antonello dot ale at gmail dot com>
" Last Change: Dec 30, 2018
" License: This script is in public domain
" ============================================================================

"" Exported Functions
" fontcatalog#listCategories(ArgLead, CmdLine, CursorPos) <<<
" List all categories found in the catalog.
" @returns A List with category names.
" ============================================================================
fun fontcatalog#listCategories(ArgLead, CmdLine, CursorPos)
    let catalogPath = s:checkConfig()
    if strlen(catalogPath) == 0
        return []
    endif

    let l:categoryList = s:catalogList(catalogPath)

    " We need only names, not paths.
    call map(l:categoryList, 'fnamemodify(v:val, ":t")')

    " If there is an argument lead, filter the list.
    if strlen(a:ArgLead) > 0
        call filter(l:categoryList, 'v:val =~? "^'.a:ArgLead.'"')
    endif

    " Sort in alphabetical order
    call sort(l:categoryList)
    return l:categoryList
endfun  " >>>
" fontcatalog#listFonts(ArgLead, CmdLine, CursorPos) <<<
" List fonts for command line completion
" ============================================================================
fun fontcatalog#listFonts(ArgLead, CmdLine, CursorPos)
    let catalogPath = s:checkConfig()
    if strlen(catalogPath) == 0
        return []
    endif

    let l:fontList = s:fontList(catalogPath)
    if empty(l:fontList)
        return []
    endif

    if strlen(a:ArgLead) > 0
        call filter(l:fontList, 'v:val =~? "^'.a:ArgLead.'"')
    endif

    call sort(l:fontList)
    return l:fontList
endfun  " >>>
" fontcatalog#categoryInfo(...) <<<
" List a category (or categories) and some information about it.
" @param ... A name or leader for a name to be listed. If nothing is passed
" all categories will be listed.
" @returns A string with formated information about the categories listed.
" ============================================================================
fun fontcatalog#categoryInfo(...)
    let catalogPath = s:checkConfig()
    if strlen(catalogPath) == 0
        return []
    endif

    let l:categoryList = s:catalogList(catalogPath)

    " We need only names, not paths.
    call map(l:categoryList, 'fnamemodify(v:val, ":t")')

    " If there is an argument lead, filter the list.
    if a:0 == 1
        call filter(l:categoryList, 'v:val =~? "^'.a:1.'"')
    endif

    "" Sort the list
    call sort(l:categoryList)

    "" Find the category with the longest name:
    let l:width = 0
    for l:categoryName in l:categoryList
        if l:width < strlen(l:categoryName)
            let l:width = strlen(l:categoryName)
        endif
    endfor

    "" Find some information about the categories
    let l:count = 0
    while l:count < len(l:categoryList)
        let l:categoryName = l:categoryList[l:count]
        let l:fontList = s:readCategory(catalogPath, l:categoryName)
        if empty(l:fontList)
            let l:categoryName = l:categoryName .repeat(' ', (l:width - strlen(l:categoryName))).' > With no fonts'
        elseif len(l:fontList) == 1
            let l:categoryName = l:categoryName .repeat(' ', (l:width - strlen(l:categoryName))).' > With "'.l:fontList[0].'" only'
        else
            let l:categoryName = l:categoryName .repeat(' ', (l:width - strlen(l:categoryName))).' > With '.len(l:fontList).' fonts'
        endif
        let l:categoryList[l:count] = l:categoryName
        let l:count = l:count + 1
    endwhile

    return join(l:categoryList, "\n")
endfun  " >>>
" fontcatalog#addFont(...) <<<
" Add the current font to one or more categories.
" @param ... List of categories to add the current font.
" @returns Nothing.
" ============================================================================
fun fontcatalog#addFont(...)
    let catalogPath = s:checkConfig()
    if strlen(catalogPath) == 0
        return
    endif

    let l:fontSpec = &guifont
    let l:categoryList = copy(a:000)
    let l:argumentList = insert(l:categoryList, l:fontSpec)
    let l:argumentList = insert(l:categoryList, catalogPath)

    call call(function('s:addToCategories'), l:argumentList)

    " Also add to the '.allfonts' pseudo category
    call s:addToCategories(catalogPath, l:fontSpec, '.allfonts')
endfun  " >>>
" fontcatalog#removeCurrent(...) <<<
" Remove the current font from one or more categories in the catalog.
" @param ... List of category names. If empty the font will be removed from
" all categories.
" @returns Nothing.
" ============================================================================
fun fontcatalog#removeCurrent(...)
    let catalogPath = s:checkConfig()
    if strlen(catalogPath) == 0
        return
    endif

    let l:fontSpec = &guifont
    let l:categoryList = []
    if a:0 > 0
        let l:categoryList = copy(a:000)
    else
        let l:categoryList = s:catalogList(catalogPath)
        call map(l:categoryList, 'fnamemodify(v:val, ":t")')
    endif

    if !empty(l:categoryList)
        let l:categoryList = insert(l:categoryList, l:fontSpec)
        let l:categoryList = insert(l:categoryList, catalogPath)
        call call(function('s:removeFromCategories'), l:categoryList)
    endif

    if a:0 == 0
        " Also remove from the '.allfonts' and '.lastused' pseudo-category.
        call s:removeFromCategories(catalogPath, l:fontSpec, '.allfonts')
        call s:removeFromCategories(catalogPath, l:fontSpec, '.lastused')
    endif
endfun  " >>>
" fontcatalog#removeFont(name) <<<
" Remove a font from the catalog.
" @param name The font name. Completion is supported.
" ----------------------------------------------------------------------------
fun fontcatalog#removeFont(name)
    let catalogPath = s:checkConfig()
    if strlen(catalogPath) == 0
        return
    endif

    call s:removeFromCategories(catalogPath, a:name)

    if a:0 == 0
        " Also remove from the '.allfonts' pseudo-category.
        call s:removeFromCategories(catalogPath, a:name, '.allfonts')
        call s:removeFromCategories(catalogPath, a:name, '.lastused')
    endif
endfun " >>>
" fontcatalog#removeCategory(name) <<<
" Remove a category from the catalog.
" @param name Category to delete.
" @returns Nothing.
" ============================================================================
fun fontcatalog#removeCategory(name)
    let catalogPath = s:checkConfig()
    if strlen(catalogPath) == 0
        return
    endif

    let l:filePath = globpath(catalogPath, a:name)
    if strlen(l:filePath) == 0
        return
    endif

    let l:fileList = split(l:filePath, "\n")
    if !s:confirm('Are you sure to remove the category "'.fnamemodify(l:fileList[0], ":t").'"?')
        return
    endif

    call delete(l:fileList[0])
endfun  " >>>
" fontcatalog#useFont(...) <<<
" Sets a font to be used.
" @param ... The font name or nothing.
" @returns Nothing.
" ============================================================================
fun fontcatalog#useFont(...)
  let catalogPath = s:checkConfig()
  if strlen(catalogPath) == 0
    return
  endif

  if a:0 == 0
    let l:paramList = [catalogPath]
    echo call(function('s:listCategories'), l:paramList)
  else
    let l:categories = s:fontListCategories(catalogPath, a:1)
    let l:linespace = ''

    if index(l:categories, 'needspace') < 0
      let l:linespace = 'linespace=0'
    else
      let l:linespace = 'linespace=1'
    endif

    exec 'set guifont='.escape(a:1, ' \') l:linespace

    " Airline integration
    call s:resetAirline(index(l:categories, 'powerline') >= 0)

    " WebDevIcons integration
    if index(l:categories, 'devicons') < 0
      let g:webdevicons_enable_nerdtree = 0
    else
      let g:webdevicons_enable_nerdtree = 1
    endif

    " Resets webdevicons so NERDTree and Airline get updated
    if exists('*webdevicons#refresh')
      call webdevicons#refresh()
    endif

    " Record the last used font configuration
    call s:writeCategory(catalogPath, '.lastused', [a:1])
  endif
endfunc " >>>
" fontcatalog#setDefault() <<<
" @param name Name of the default font.
" @returns Nothing
fun fontcatalog#setDefault()
    if exists('g:fc_DontUseDefault') && g:fc_DontUseDefault == 1
        return
    endif

    let defaultFont = ''
    if exists('g:fc_DefaultFont') && strlen(g:fc_DefaultFont) > 0
        let defaultFont = g:fc_DefaultFont
    else
        let catalogPath = s:checkConfig()
        if strlen(catalogPath) > 0
            let l:fontList = s:fontList(catalogPath, '.lastused')
            if len(l:fontList) > 0
                let defaultFont = l:fontList[0]
            endif
        endif
    endif

    if strlen(defaultFont) > 0
        call fontcatalog#useFont(defaultFont)
    endif
endfun  " >>>
" fontcatalog#fontsIn(...) <<<
" List all fonts within a category or categories.
" @param ... List of category names. If empty, all fonts in the catalog are
" listed. If '*' the font dialog will be shown.
" @return A list of all fonts in the catalog.
" ============================================================================
fun fontcatalog#fontsIn(...)
    if a:0 > 0 && a:1 == '*'
        set guifont=*
        return ''
    endif

    let catalogPath = s:checkConfig()
    if strlen(catalogPath) == 0
        return ''
    endif

    if a:0 > 0
        let l:callParams = copy(a:000)
        let l:callParams = insert(l:callParams, catalogPath)
    else
        let l:callParams = [catalogPath]
    endif

    call s:msgEcho('warn', l:callParams)
    let l:fontList = call(function('s:fontList'), l:callParams)

    if empty(l:fontList)
        return 'No fonts found'
    endif

    let l:nameWidth = 0

    " Measure the greatest font name width, in caracters.
    for l:fontName in l:fontList
        if l:nameWidth < strlen(l:fontName)
            let l:nameWidth = strlen(l:fontName)
        endif
    endfor

    call sort(l:fontList)

    " Search for all categories were a font is in.
    let l:categoriesList = []
    let l:fontName = ''
    let index = 0
    while index < len(l:fontList)
        let l:fontName = l:fontList[index]
        let l:categoriesList = s:fontListCategories(catalogPath, l:fontName)
        if !empty(l:categoriesList)
            let l:fontList[index] = l:fontName .repeat(' ', (l:nameWidth - strlen(l:fontName))).' in: '.join(l:categoriesList, ', ')
        endif
        let index = index + 1
    endwhile

    return join(l:fontList, "\n")
endfun  " >>>
" fontcatalog#fontCategories(...)<<<
" The result is a List with the categories a font has.
" Param: a:font Optional. Font specification as defined in the catalog (e.g.:
" 'Consolas:h11'). If omitted the current selected font will be used. When no
" categories found the result is an empty list ([]).
" Return: List
" ============================================================================
fun fontcatalog#fontCategories(...)
  let catalogPath = s:checkConfig()
  if strlen(catalogPath) == 0
    return []
  endif

  let l:font = a:0 ? a:1 : &guifont
  return s:fontListCategories(catalogPath, l:font)
endfun
" >>>

"" Local Functions 
" s:msgEcho(type, msg) <<<
" Echoes a message to the user
" @param type Message type: 'error', 'warn', 'query', 'none'.
" @param msg  Message to show.
" @returns Nothing.
" ============================================================================
fun s:msgEcho(type, msg)
    if a:type ==? 'error'
        echohl ErrorMsg
    elseif a:type ==? 'warn'
        echohl WarningMsg
    elseif a:type ==? 'query'
        echohl Question
    endif
    echo a:msg
    echohl None
endfun  " >>>
" s:confirm(msg) <<<
" Request a user confirmation.
" @param msg Message to show to the user.
" @returns TRUE if the user answered 'yes'. Otherwise FALSE.
" ============================================================================
fun s:confirm(msg)
    echohl Question
    let l:answer = input(a:msg.' ("yes" or "no")')
    echohl None
    return l:answer == 'yes'
endfun  " >>>
" s:checkConfig() <<<
" Verifies the catalog folder configuration.
" @returns The directory where the catalog should be in.
" ============================================================================
fun s:checkConfig()
    let result = ''

    if exists('g:fc_CatalogFolder')
        if strlen(g:fc_CatalogFolder) > 0
            let result = expand(g:fc_CatalogFolder)
        else
            return ''
        endif
    endif

    if strlen(result) == 0
        call s:msgEcho('error', 'No storage folder was set')
        echohl None
        return ''
    endif

    if !isdirectory(result)
        call mkdir(result, 'p')
    endif

    if !isdirectory(result)
        call s:msgEcho('error', 'Could not found font catalog on "'.result.'" path')
        return ''
    endif

    return result
endfun  " >>>
" s:catalogList(catalogPath) <<<
" List all files in the catalog's directory.
" @param catalogPath Path where the catalog is.
" @returns A list with the file names.
" ============================================================================
fun s:catalogList(catalogPath)
    let l:categoriesList = []
    let l:categories = globpath(a:catalogPath, '*')
    if strlen(l:categories) == 0
        return []
    else
        let l:categoriesList = split(l:categories, "\n")
    endif

    " Remove .lastused and .allfonts from the list
    call filter(l:categoriesList, 'v:val !=? ".lastused"')
    call filter(l:categoriesList, 'v:val !=? ".allfonts"')

    return l:categoriesList
endfun  " >>>
" s:readCategory(catalogPath, name) <<<
" Reads a category file.
" @param catalogPath Path for the font catalog.
" @param name Category file name. Can have wildcards.
" @returns A list where each line has a Font specification.
" ============================================================================
fun s:readCategory(catalogPath, name)
    let l:foundFiles = globpath(a:catalogPath, a:name)
    if strlen(l:foundFiles) == 0
        return []
    endif

    let l:filesList = split(l:foundFiles, "\n")
    let l:selectedFile = l:filesList[0]

    if filereadable(l:selectedFile)
        try
            return readfile(l:selectedFile)
        catch
            return []
        endtry
    endif
endfun  " >>>
" s:writeCategory(catalogPath, name, content) <<<
" Writes a category file.
" @param catalogPath Path for the font catalog.
" @param name Category file name.
" @param content A List with the file's content.
" @returns Nothing.
" ============================================================================
fun s:writeCategory(catalogPath, name, content)
    let l:filePath = a:catalogPath .'/'. a:name
    call writefile(a:content, l:filePath)
endfun  " >>>
" s:addToCategories(catalogPath, spec, ...) <<<
" Add a font specification to one or more categories in the catalog.
" @param catalogPath Path for the font catalog.
" @param spec Font specification in the format 'name:height'. Usually this
"        should obtained by the 'guifont' setting.
" @param ... List of categories to add the font. At least one.
" @returns Nothing.
" ============================================================================
fun s:addToCategories(catalogPath, spec, ...)
    for l:categoryName in a:000
        let l:currentList = s:readCategory(a:catalogPath, l:categoryName)
        if empty(l:currentList)
            call add(l:currentList, a:spec)
        else
            if index(l:currentList, a:spec) < 0
                call add(l:currentList, a:spec)
            endif
        endif

        call s:writeCategory(a:catalogPath, l:categoryName, l:currentList)
    endfor
endfun  " >>>
" s:removeFromCategories(catalogPath, spec, ...) <<<
" Remove a Font specification from one or more categories.
" @param catalogPath Path for the font catalog.
" @param spec Font specification. This is usually get from the 'guifont'
"        option.
" @param ... Categories to remove the font.
" @returns Nothing.
" ============================================================================
fun s:removeFromCategories(catalogPath, spec, ...)
    for l:categoryName in a:000
        let l:fontList = s:readCategory(a:catalogPath, l:categoryName)
        if !empty(l:fontList)
            call filter(l:fontList, 'v:val !=? "'.a:spec.'"')
            call s:writeCategory(a:catalogPath, l:categoryName, l:fontList)
        endif
    endfor
endfun  " >>>
" s:fontListCategories(catalogPath, spec) <<<
" Search for all categories that a font is in.
" @param catalogPath Path for the font catalog.
" @param spec The font specification.
" @return A List object with category names.
" ============================================================================
fun s:fontListCategories(catalogPath, spec)
    let l:foundCategories = []
    let l:categoriesList  = s:catalogList(a:catalogPath)

    " Remove path information of categories list.
    call map(l:categoriesList, 'fnamemodify(v:val, ":t")')

    for l:categoryName in l:categoriesList
        let l:fontList = s:readCategory(a:catalogPath, l:categoryName)
        if index(l:fontList, a:spec, 0, 1) >= 0
            call add(l:foundCategories, l:categoryName)
        endif
    endfor

    return l:foundCategories
endfun  " >>>
" s:fontList(catalogPath, ...) <<<
" List fonts in one, several or all categories.
" @param catalogPath Path for the font catalog.
" @param ... List with category names. If empty all fonts will be listed.
" @return A List object with all font names.
" ============================================================================
fun s:fontList(catalogPath, ...)
    let l:fontList = []

    if a:0 == 0
        let l:fontList = s:readCategory(a:catalogPath, '.allfonts')
    else
        let l:fontList = s:readCategory(a:catalogPath, a:1)
        if a:0 > 1
            for l:categoryName in a:000[1:]
                let l:fonts = s:readCategory(a:catalogPath, l:categoryName)
                let l:fontList = s:getCommonItems(l:fontList, l:fonts)
                if empty(l:fontList)
                    break
                endif
            endfor
        endif
    endif

    return l:fontList
endfunc " >>>
" s:getCommonItems(list1, list2) <<<
" Builds a list with items common to both lists.
" @param list1 A list of items.
" @param list2 A list of items.
" @return A list with items that are common to both lists or an empty list if
" no common item was found.
" ============================================================================
fun s:getCommonItems(list1, list2)
    let l:result = []

    for itemInList1 in a:list1
        for itemInList2 in a:list2
            if itemInList1 == itemInList2
                call add(l:result, itemInList1)
            endif
        endfor
    endfor

    return l:result
endfun  " >>>
" s:listCategories(catalogPath, ...) <<<
" List categories of the current font.
" @param catalogPath Path for the font catalog.
" @param ... Font specification or nothing.
" @returns A List object with the category names.
" ============================================================================
fun s:listCategories(catalogPath, ...)
    let l:fontSpec = a:0 ? a:1 : &guifont
    let l:foundCategories = s:fontListCategories(a:catalogPath, l:fontSpec)

    if empty(l:foundCategories)
        return '"'.l:fontSpec.'" not found in catalog'
    else
        call sort(l:foundCategories)
        return '-> Font: "'.l:fontSpec.'"'."\n\t".join(l:foundCategories, ', ')
    endif
endfun  " >>>
" s:resetAirline(allow) <<<
" Params: a:allow v:true to allow airline powerline symbols. v:false
" otherwise.
" Resets Airline configuration.
" ----------------------------------------------------------------------------
fun s:resetAirline(allow)
  if a:allow
    let g:airline_powerline_fonts = 1
    let g:airline_left_sep = "\ue0b0"
    let g:airline_left_alt_sep = "\ue0b1"
    let g:airline_right_sep = "\ue0b2"
    let g:airline_right_alt_sep = "\ue0b3"

    let g:airline#extensions#tabline#left_sep = "\ue0b0"
    let g:airline#extensions#tabline#left_alt_sep = "\ue0b1"
    let g:airline#extensions#tabline#right_sep = "\ue0b2"
    let g:airline#extensions#tabline#right_alt_sep = "\ue0b3"

    let l:powerline_symbols = {
          \ 'readonly': "\ue0a2",
          \ 'whitespace': "\u2632",
          \ 'linenr': "\u2630 ",
          \ 'maxlinenr': " \ue0a1",
          \ 'branch': "\ue0a0",
          \ 'notexists': "\u0246",
          \ 'dirty': "\u26a1",
          \ 'crypt': nr2char(0x1F512),
          \}
    call extend(g:airline_symbols, l:powerline_symbols, 'force')
  else
    let g:airline_powerline_fonts = 0
    let g:airline_left_sep = ""
    let g:airline_left_alt_sep = '〉'
    let g:airline_right_sep = ""
    let g:airline_right_alt_sep = '〈'

    let g:airline#extensions#tabline#left_sep = ''
    let g:airline#extensions#tabline#left_alt_sep = ''
    let g:airline#extensions#tabline#right_sep = ''
    let g:airline#extensions#tabline#right_alt_sep = '|'

    let l:powerline_symbols = {
          \ 'readonly': '∅',
          \ 'whitespace': "Ξ",
          \ 'linenr': 'Δ ',
          \ 'maxlinenr': ' :',
          \ 'branch': 'Ψ',
          \ 'notexists': 'Θ',
          \ 'crypt': '◊',
          \ 'dirty': 'ϟ',
          \}
    call extend(g:airline_symbols, l:powerline_symbols, 'force')
  endif

  if exists(':AirlineRefresh')
    AirlineRefresh
  endif
endfun
" >>>

" vim:ff=unix:fdm=marker:fmr=<<<,>>>
