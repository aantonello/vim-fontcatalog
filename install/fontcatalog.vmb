" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/fontcatalog.vim	[[[1
502
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

"" Default Catalog Location
let s:font_catalog = expand('~/.vim/fontcatalog')
if exists('g:fc_CatalogFolder')
    let s:font_catalog = expand(g:fc_CatalogFolder)
endif

"" Exported Functions
" s:FontCatalogList(ArgLead, CmdLine, CursorPos) <<<
" List all categories found in the catalog.
" @returns A List with category names.
" ============================================================================
fun s:FontCatalogList(ArgLead, CmdLine, CursorPos)
    if !s:checkConfig()
        return []
    endif

    let l:categoryList = s:catalogList()

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
" s:FontCatalogFontsList(ArgLead, CmdLine, CursorPos) <<<
" List fonts for command line completion
" ============================================================================
fun s:FontCatalogFontsList(ArgLead, CmdLine, CursorPos)
    let l:fontList = s:fontList()
    if empty(l:fontList)
        return []
    endif

    if strlen(a:ArgLead) > 0
        call filter(l:fontList, 'v:val =~? "^'.a:ArgLead.'"')
    endif

    call sort(l:fontList)
    return l:fontList
endfun  " >>>
" s:FontCatalogCategoriesInfo(...) <<<
" List a category (or categories) and some information about it.
" @param ... A name or leader for a name to be listed. If nothing is passed
" all categories will be listed.
" @returns A string with formated information about the categories listed.
" ============================================================================
fun s:FontCatalogCategoriesInfo(...)
    if !s:checkConfig()
        return []
    endif

    let l:categoryList = s:catalogList()

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
        let l:fontList = s:readCategory(l:categoryName)
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
" s:FontCatalogAdd(...) <<<
" Add the current font the one or more categories.
" @param ... List of categories to add the current font.
" @returns Nothing.
" ============================================================================
fun s:FontCatalogAdd(...)
    if !s:checkConfig()
        return
    endif

    let l:fontSpec = &guifont
    let l:categoryList = copy(a:000)
    let l:argumentList = insert(l:categoryList, l:fontSpec)

    call call(function('s:addToCategories'), l:argumentList)

    " Also add to the '.allfonts' pseudo category
    call s:addToCategories(l:fontSpec, '.allfonts')
endfun  " >>>
" s:FontCatalogRem(...) <<<
" Remove the current font from one or more categories in the catalog.
" @param ... List of category names. If empty the font will be removed from
" all categories.
" @returns Nothing.
" ============================================================================
fun s:FontCatalogRem(...)
    if !s:checkConfig()
        return
    endif

    let l:fontSpec = &guifont
    let l:categoryList = []
    if a:0 > 0
        let l:categoryList = copy(a:000)
    else
        let l:categoryList = s:catalogList()
        call map(l:categoryList, 'fnamemodify(v:val, ":t")')
    endif

    if !empty(l:categoryList)
        let l:categoryList = insert(l:categoryList, l:fontSpec)
        call call(function('s:removeFromCategories'), l:categoryList)
    endif

    if a:0 == 0
        " Also remove from the '.allfonts' pseudo-category.
        call s:removeFromCategories(l:fontSpec, '.allfonts')
    endif
endfun  " >>>
" s:FontCatalogRemoveCategory(name) <<<
" Remove a category from the catalog.
" @param name Category to delete.
" @returns Nothing.
" ============================================================================
fun s:FontCatalogRemoveCategory(name)
    let l:filePath = globpath(s:font_catalog, a:name)
    if strlen(l:filePath) == 0
        return
    endif

    let l:fileList = split(l:filePath, "\n")
    if !s:confirm('Are you sure to remove the category "'.fnamemodify(l:fileList[0], ":t").'"?')
        return
    endif

    call delete(l:fileList[0])
endfun  " >>>
" s:FontCatalogListCategories() <<<
" List the categories of the current font.
" @returns A List object with the category names.
" ============================================================================
fun s:FontCatalogListCategories()
    if !s:checkConfig()
        return ''
    endif

    let l:fontSpec = &guifont
    let l:foundCategories = s:fontListCategories(l:fontSpec)

    if empty(l:foundCategories)
        return '"'.l:fontSpec.'" not found in font catalog'
    else
        call sort(l:foundCategories)
        return join(l:foundCategories, '  ')
    endif
endfun  " >>>
" s:FontCatalogFonts(...) <<<
" List all fonts within a category or categories.
" @param ... List of category names. If empty, all fonts in the catalog are
" listed.
" @return A list of all fonts in the catalog.
" ============================================================================
fun s:FontCatalogFonts(...)
    if !s:checkConfig()
        return ''
    endif

    let l:fontList = call(function('s:fontList'), a:000)

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
        let l:categoriesList = s:fontListCategories(l:fontName)
        if !empty(l:categoriesList)
            let l:fontList[index] = l:fontName .repeat(' ', (l:nameWidth - strlen(l:fontName))).' in: '.join(l:categoriesList, ', ')
        endif
        let index = index + 1
    endwhile

    return join(l:fontList, "\n")
endfun  " >>>
" s:FontCatalogSet(spec) <<<
" Sets a font to be used.
" @param spec The font specification.
" @returns Nothing.
" ============================================================================
fun s:FontCatalogSet(spec)
    if a:spec == '*'
        set guifont=*
    elseif a:spec == '?'
        call s:msgEcho('none', 'Font: "'.&guifont.'"')
    else
        exec 'set guifont='.escape(a:spec, ' \')
    endif

    if a:spec != '?' && a:spec != '*' && s:checkConfig()
        call s:writeCategory('.lastused', [a:spec])
    endif
endfunc " >>>

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
" @returns TRUE when the folder was found. FALSE otherwise.
" ============================================================================
fun s:checkConfig()
    if strlen(s:font_catalog) == 0
        call s:msgEcho('error', 'No storage folder was defined')
        return 0
    endif

    if !isdirectory(s:font_catalog)
        call mkdir(s:font_catalog)
    endif

    if !isdirectory(s:font_catalog)
        call s:msgEcho('error', 'Could not found font catalog on path: "'.s:font_catalog.'"')
        return 0
    endif

    return 1
endfun  " >>>
" s:catalogList() <<<
" List all files in the catalog's directory.
" @returns A list with the file names.
" ============================================================================
fun s:catalogList()
    let l:categoriesList = []
    let l:categories = globpath(s:font_catalog, '*')
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
" s:readCategory(name) <<<
" Reads a category file.
" @param name Category file name. Can have wildcards.
" @returns A list where each line has a Font specification.
" ============================================================================
fun s:readCategory(name)
    let l:foundFiles = globpath(s:font_catalog, a:name)
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
" s:writeCategory(name, content) <<<
" Writes a category file.
" @param name Category file name.
" @param content A List with the file's content.
" @returns Nothing.
" ============================================================================
fun s:writeCategory(name, content)
    let l:filePath = s:font_catalog .'/'. a:name
    call writefile(a:content, l:filePath)
endfun  " >>>
" s:addToCategories(spec, ...) <<<
" Add a font specification to one or more categories in the catalog.
" @param spec Font specification in the format 'name:height'. Usually this
"        should obtained by the 'guifont' setting.
" @param ... List of categories to add the font. At least one.
" @returns Nothing.
" ============================================================================
fun s:addToCategories(spec, ...)
    for l:categoryName in a:000
        let l:currentList = s:readCategory(l:categoryName)
        if empty(l:currentList)
            call add(l:currentList, a:spec)
        else
            if index(l:currentList, a:spec) < 0
                call add(l:currentList, a:spec)
            endif
        endif

        call s:writeCategory(l:categoryName, l:currentList)
    endfor
endfun  " >>>
" s:removeFromCategories(spec, ...) <<<
" Remove a Font specification from one or more categories.
" @param spec Font specification. This is usually get from the 'guifont'
"        option.
" @param ... Categories to remove the font.
" @returns Nothing.
" ============================================================================
fun s:removeFromCategories(spec, ...)
    for l:categoryName in a:000
        let l:fontList = s:readCategory(l:categoryName)
        if !empty(l:fontList)
            call filter(l:fontList, 'v:val !=? "'.a:spec.'"')
            call s:writeCategory(l:categoryName, l:fontList)
        endif
    endfor
endfun  " >>>
" s:fontListCategories(spec) <<<
" Search for all categories that a font is in.
" @param spec The font specification.
" @return A List object with category names.
" ============================================================================
fun s:fontListCategories(spec)
    let l:foundCategories = []
    let l:categoriesList  = s:catalogList()

    " Remove path information of categories list.
    call map(l:categoriesList, 'fnamemodify(v:val, ":t")')

    for l:categoryName in l:categoriesList
        let l:fontList = s:readCategory(l:categoryName)
        if index(l:fontList, a:spec, 0, 1) >= 0
            call add(l:foundCategories, l:categoryName)
        endif
    endfor

    return l:foundCategories
endfun  " >>>
" s:fontList(...) <<<
" List fonts in one, several or all categories.
" @param ... List with category names. If empty all fonts will be listed.
" @return A List object with all font names.
" ============================================================================
fun s:fontList(...)
    let l:fontList = []

    if a:0 == 0
        let l:fontList = s:readCategory('.allfonts')
    else
        let l:fontList = s:readCategory(a:1)
        if a:0 > 1
            for l:categoryName in a:000[1:]
                let l:fonts = s:readCategory(l:categoryName)
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

"" Commands
" Add the current font to one or more categories
command -nargs=+ -complete=customlist,s:FontCatalogList FCAdd :call s:FontCatalogAdd(<f-args>)

" Remove the current font from one or more categories in the catalog.
command -nargs=* -complete=customlist,s:FontCatalogList FCRem :call s:FontCatalogRem(<f-args>)

" Remove a category from the catalog.
command -nargs=1 -complete=customlist,s:FontCatalogList FCDel :call s:FontCatalogRemoveCategory(<f-args>)

" List the categories of the current font.
command -nargs=0 FCCat :echo s:FontCatalogListCategories()

" List all fonts within a category or categories.
command -nargs=* -complete=customlist,s:FontCatalogList FCFonts :echo s:FontCatalogFonts(<f-args>)
command -nargs=* -complete=customlist,s:FontCatalogList Fonts :echo s:FontCatalogFonts(<f-args>)

" Sets a font to be used.
command -nargs=1 -complete=customlist,s:FontCatalogFontsList FCSet :call s:FontCatalogSet(<f-args>)
command -nargs=1 -complete=customlist,s:FontCatalogFontsList Font :call s:FontCatalogSet(<f-args>)

" Opens the browse for font dialog.
command -nargs=0 FCLoad :set guifont=*

" Lists the current categories
command -nargs=? FCList :echo s:FontCatalogCategoriesInfo(<f-args>)

"" If there is a default font, use it
if exists('g:fc_DefaultFont')
    call s:FontCatalogSet(g:fc_DefaultFont)
else
    "" Select from a previous usage
    let fontList = s:fontList('.lastused')
    if !empty(fontList)
        call s:FontCatalogSet(fontList[0])
    endif
    unlet fontList
endif
" vim:ff=unix:fdm=marker:fmr=<<<,>>>
doc/fontcatalog.txt	[[[1
260
*fontcatalog.txt*            Font Catalog Plugin                  May 13, 2014
*fontcatalog.vim*                                                *fontcatalog*

Author: Alessandro Antonello <antonello.ale@gmail.com>

License:    This plugin is under GPLv3 license.  This basically means that you
            are free  to copy,  share,  distribute,  sell or change  it as you
            like.  There are no warranties tough.

==============================================================================
                                                           *fontcatalog-index*
1. Contents                                             *fontcatalog-contents*

        1. Contents..................................: |fontcatalog-contents|
        2. What is this plugin for?..................: |fontcatalog-whatis|
        3. Installing................................: |fontcatalog-install|
        4. Options...................................: |fontcatalog-options|
        5. Commands..................................: |fontcatalog-commands|
            :FCAdd                                   : |:FCAdd|
            :FCRem                                   : |:FCRem|
            :FCDel                                   : |:FCDel|
            :FCCat                                   : |:FCCat|
            :FCFonts or :Fonts                       : |:FCFonts|
            :FCFont or :Font                         : |:FCFont|
            :FCLoad                                  : |:FCLoad|
            :FCList                                  : |:FCList|
        6. Mappings..................................: |fontcatalog-mappings|
        7. ChangeLog.................................: |fontcatalog-changes|
        8. Todo......................................: |fontcatalog-todo|

==============================================================================
2. What is this plugin for?                               *fontcatalog-whatis*

        Some  people like  to use  Vim  in  a  terminal  window.  Simple still
        efficient.  Some people  use Vim in  the GUI.  Most,  maybe,  choose a
        single font and stick with it for a very long time.  Others, including
        my self,  like to  change font from time to  time,  or from session to
        session.  For this kind of people open the font list dialog every time
        he/she needs to choose another font may be boring or  cumbersome.  For
        this kind of people this plugin is for.

        This plugin enables you to choose a font from the font list dialog and
        set a  category for it.  A  category is simply  a name like  'bold' or
        'italic' with will be used to list fonts alike.  Maybe an example will
        clarify things better.

        I like the Consolas font. So I can load it using the font list dialog:
>
        :FCLoad
<
        Upon selected GUI Vim will start using it. It looks great on Windows
        but on Mac OS X it is a little heavy when used with dark background
        color schemes. So I put it in a category:
>
        :FCAdd regular bold italic heavy-on-dark
<
        Well,  that was  four categories:  'regular' because it  has a regular
        normal shape.  'bold' because it has a bold version.  MacVim is unable
        to fake  bold and italic  style so is  useful to have  categories that
        tell if a font has or not that style.  'italic' was also created thing
        in that matter.  Finally 'heavy-on-dark' because it is  a little heavy
        in dark backgrounds.

        The font 'Letter  Gothic Std Medium' has a  thin shape.  Good for dark
        backgrounds.  It also has  'bold' and 'italic' variants.  So  I put it
        on these categories:
>
        :FCAdd regular bold italic ok-on-dark
<
        Meaning this font is Ok on dark backgrounds. After I add several fonts
        to my categories I can list and set then in a more easily fashion:
>
        :FCFonts ok-on-dark
<
        Will list all fonts that I  put in that category.  Lets pretend that I
        want to use 'Letter Gothic Std Medium'.  I can type:
>
        :FCSet let<Tab>
<
        The name will be  completed for me.  I can change the  size if I want.
        Pressing <Enter> the chosen font will be set.

==============================================================================
3. Installing                                            *fontcatalog-install*

        Installation   is   very   simple.   There   are   just   two   files:
        'fontcatalog.vim' and 'fontcatalog.txt'.  Put 'fontcatalog.vim' in the
        plugins directory  and 'fontcatalog.txt'  in the  doc directory.  Open
        Vim and type:
>
        :helptags ~/.vim/doc
<
        Also,  a VimBall  file is provided.  You  can source 'fontcatalog.vmb'
        and files will be magically installed. Open that file on Vim and type:
>
        :so %
<
        And that is it.

==============================================================================
4. Options                                               *fontcatalog-options*

                                                        *'g:fc_CatalogFolder'*
        This  option  sets the  directory  where  categories  will  be stored.
        Categories  are really files that  lists all  fonts added  to it.  You
        should set this in your 'vimrc'  file because 'gvimrc' is loaded after
        the plugin it self.
>
        let g:fc_CatalogFolder = <default: ~/.vim/fontcatalog>
<
        The plugin will try to create this directory if it doesn't exist.


                                                          *'g:fc_DefaultFont'*
        This is  optional.  A font to be  used when GUI  Vim starts.  A string
        with the font name and size, like used in the option |'guifont'|.  You
        don't need to scape spaces.  The script does this automatically.
>
        let g:fc_DefaultFont = 'Letter Gothic Std Medium:h12'
<
        This also must  be set in 'vimrc' file.  'gvimrc'  will load after the
        plugin and it will not find this variable.

        When there is  no default font the  plugin will try to use  one from a
        previous session.  The  last  used  font,  if  there  is one,  will be
        selected.  Otherwise it  will let GUI Vim  to figure out  what font to
        use.


                                                      *'g:loaded_fontcatalog'*
        If you  wanna to  disable the  plugin to  load just  set this  in your
        'vimrc' file.
>
        let g:loaded_fontcatalog = 1
<
        The plugin will not load when this  variable is set and when no GUI is
        running.

==============================================================================
5. Commands                                             *fontcatalog-commands*

                                                                      *:FCAdd*
:FCAdd {category} [category] [...]
        Adds the current selected font in one or more categories.  You can use
        <Tab>  for command  line completion  or  <CTRL-D>  to  see  a  list of
        categories already created.  See  |c_CTRL-D|.  If the category doesn't
        exists it  will be  created.  You can add  the font  in more  than one
        category with a single command.
>
        :FCAdd light bold
<


                                                                      *:FCRem*
:FCRem {category} [category] [...]
        Removes the  current selected font  from one or  more categories.  You
        can use <Tab> for command line completion or <CTRL-D> to see a list of
        categories.  You can remove the font  from more than one category with
        a single command.
>
        :FCRem light bold
<


                                                                      *:FCDel*
:FCDel {category}
        Will delete a category.  You can use <Tab> for command line completion
        or  <CTRL-D> for  a list  of categories.  The  deletion will  ask your
        confirmation before erasing the file from the catalog directory.  Only
        one category can be deleted at a time.
>
        :FCDel light
<


                                                                      *:FCCat*
:FCCat
        List all categories where the  current selected font can be found.  No
        arguments for this command.  The result is a simple list of names.
>
        :FCCat
        light bold
<


                                                                    *:FCFonts*
                                                                      *:Fonts*
:Fonts {category} [category] [...]
        List all fonts that are within a category or categories.  The argument
        is  one or  more category  names.  Completion applies.  When  only one
        category is  typed all  fonts in that  category will  be listed.  When
        more than  one category is typed  fonts only common  to all categories
        are listed.
>
        :FCFonts bold
        Consolas:h12                 in: bold, italic, regular
        Letter Gothic Std Medium:h12 in: bold, light
<


                                                                     *:FCFont*
                                                                       *:Font*
:Font {font-spec}
        Select a font to  be  used  in  GUI  Vim.  Its  result  is the same as
        setting the option |'guifont'|.  Its argument is a font specification,
        name and size.  Completion applies.  If you  pass '*' as the font name
        the font list dialog will be shown.  If  you pass '?' as the font name
        the current selected  font specification will be shown  in the command
        line.
>
        :Font ?
        Font: "Letter Gothic Std Medium:h12"
<


                                                                     *:FCLoad*
:FCLoad
        Show the  dialog with  the list  of fonts  in the  system.  The system
        dialog is shown.  Like when setting |'guifont'| with '*'.  The same as
        |:FCFont| passing '*' as font name.
>
        :FCLoad
<



                                                                     *:FCList*
:FCList [category]
        List  categories  information.  Its argument  is  a  category  name or
        nothing.  When no  name is  passed it  lists all  existing categories.
        Otherwise only the typed category will be listed.
>
        :FCList
        bold        > With 2 fonts
        regular     > With "Consolas:h12" only
        light       > With "Letter Gothic Std Medium:h12" only
<

==============================================================================
6. Mappings                                             *fontcatalog-mappings*

        There is no  mappings defined in the plugin.  You  can create your own
        if you need.  You can put your  mappings in the 'gvimrc' file since it
        is loaded after  the  plugin  is  load  and  the  commands are already
        available.

==============================================================================
7. ChangeLog                                             *fontcatalog-changes*

May 13, 2014:
        * fontcatalog.vim (version 1.0): First release.
        * fontcatalog.txt (version 1.0): First release.

==============================================================================
8. Todo                                                     *fontcatalog-todo*

        Better font choosing method. Maybe using quickfix window.

==============================================================================
vim:tw=78:ts=4:sw=4:ft=help:
