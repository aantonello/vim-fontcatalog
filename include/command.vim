vim9script
# ============================================================================
# Operations on commands.
# ============================================================================
import './fontsub.vim' as font
import './category.vim'

# List completion options for `:Font` command.
# @param argLead Word fragment typed by the user.
# @param cmdLine The current content of the commad.
# @param cursorPos Current position of the cursor.
# @return A list of possible completions or an empty list when nothing can be
# completed. Winye.
# ----------------------------------------------------------------------------
export def FontComplete(argLead: string, cmdLine: string, cursorPos: number): list<string>
  # Get the portion of the command line before the cursor position.
  const line = strpart(cmdLine, 0, cursorPos)
  const fontCmdPos = matchstrpos(line, '\s', 0)

  # fontCmdPost must be valid, otherwise completion is nothing.
  if len(fontCmdPos) < 3 || fontCmdPos[2] < 0
    return []
  endif

  const subCmdPos = matchstrpos(line, '\s', fontCmdPos[2])
  if len(subCmdPos) < 3 || subCmdPos[2] < 0
    # Sub command completion.
    if strlen(argLead) > 0
      return matchfuzzy(font.SUBCOMMANDS, argLead, { matchseq: true, limit: 0 })
    else
      return font.SUBCOMMANDS
    endif
  endif

  const splittedLine = split(line, '\s')
  const subCommand   = splittedLine[1]
  var   resultList: list<string> = []

  if subCommand ==# 'set' || subCommand ==# 'remove'
    # Completion is the list of available fonts in catalog.
    resultList = font.ListNames()
  else
    # Otherwise the completion list is the list of categories.
    resultList = category.List()

    const tokens = splittedLine[2 : ]

    # Filter out the tokens already typed.
    if len(tokens) > 0
      resultList->filter((index, value) => tokens->index(value) < 0)
    endif
  endif

  if strlen(argLead) > 0
    return matchfuzzy(resultList, argLead, { matchseq: true, limit: 0 })
  else
    return resultList
  endif
enddef

# List completion options for `:Category` command.
# @param argLead Word fragment typed by the user.
# @param cmdLine The current content of the commad.
# @param cursorPos Current position of the cursor.
# @return A list of possible completions or an empty list when nothing can be
# completed. Winye.
# ----------------------------------------------------------------------------
export def CategoryComplete(argLead: string, cmdLine: string, cursorPos: number): list<string>
  # Get the portion of the command line before the cursor position.
  const line = strpart(cmdLine, 0, cursorPos)
  const categoryCmdPos = matchstrpos(line, '\s', 0)

  # categoryCmdPos must be valid, otherwise completion is nothing.
  if len(categoryCmdPos) < 3 || categoryCmdPos[2] < 0
    return []
  endif

  const subCmdPos = matchstrpos(line, '\s', categoryCmdPos[2])
  if len(subCmdPos) < 3 || subCmdPos[2] < 0
    # Sub command completion.
    if strlen(argLead) > 0
      return matchfuzzy(category.SUBCOMMANDS, argLead, { matchseq: true, limit: 0 })
    else
      return category.SUBCOMMANDS
    endif
  endif

  const splittedLine = split(line, '\s')
  const subCommand   = splittedLine[1]
  var   resultList: list<string> = []

  if subCommand ==# 'rm' || subCommand ==# 'remove'
    resultList = category.List()

    const tokens = splittedLine[2 : ]
    # Filter out tokens already typed.
    if !empty(tokens)
      resultList->filter((index, value) => tokens->index(value) < 0)
    endif

    if strlen(argLead) > 0
      resultList = matchfuzzy(resultList, argLead, { matchseq: true, limit: 0 })
    endif
  endif

  return resultList
enddef

# Handles de main 'Font' command.
# @param subCmd Sub command. Can be empty.
# @param categories List of categories to perform the command.
# @return Nothing.
# ----------------------------------------------------------------------------
export def Font(subCmd = '', categories: list<string> = []): void
  if strlen(subCmd) == 0
    # No subcommand given. Show the current font properties.
    try
      :echomsg 'guifont ' .. font.FormattedInfo()
    catch
      :echomsg v:exception
    finally
      return
    endtry
  endif

  if subCmd ==# 'add'
    # 'add' subcommand adds the current font into one or more categories.
    font.Add(categories)
  elseif subCmd ==# 'ls' || subCmd ==# 'list'
    # 'list' subcommand shows all fonts. If a category is passed, filter
    # results by that category.
    font.List(categories)
  elseif subCmd ==# 'rm'
    # Remove the current font from one or more categories.
    font.Remove(categories)
  elseif subCmd ==# 'remove'
    if empty(categories)
      :echomsg 'A font name is required!'
    else
      font.Delete(categories->join(' '))
    endif
  elseif subCmd ==# 'set'
    # Set the font to be used as guifont.
    if empty(categories)
      :echomsg 'A font name is required!'
    else
      font.Set(categories->join(' '))
    endif
  elseif subCmd == '*'
    # Open the font list dialog for user selection
    :set guifont=*
  else
    # Any other option result in an error:
    :echoerr 'Option "' .. subCmd .. '" not supported!'
  endif
enddef

# Handles de main 'Category' command.
# @param subCmd Sub command. Can be empty.
# @param categories List of categories to perform the command.
# @return Nothing.
# ----------------------------------------------------------------------------
export def Category(subCmd: string = '', categories: list<string> = []): void
  if strlen(subCmd) == 0
    # NO sub command given. Show the current font information.
    try
      :echomsg 'guifont is ' .. font.FormattedInfo()
    catch
      :echomsg v:exception
    endtry
  elseif subCmd ==# 'ls' || subCmd ==# 'list'
    category.ListCommand(categories)

  elseif subCmd ==# 'rm' || subCmd ==# 'remove'
    category.Remove( categories->get(0, '') )
  else
    # Any other option result in an error:
    :echoerr 'Option "' .. subCmd .. '" not supported!'
  endif
enddef

# Sets the default font when GUI enters.
# ----------------------------------------------------------------------------
export def SetDefault()
  # Check whether we are enabled to set the default font.
  if get(g:, 'fc_DontUseDefault', false)
    return
  endif

  # Check whether we have a default font definition. The option overrides the
  # last used font.
  var fontName = get(g:, 'fc_DefaultFont', '')
  if strlen(fontName) > 0
    font.Set(fontName, true)
    return
  endif

  # Check whether we have a last used font.
  fontName = font.GetLastUsed()
  if strlen(fontName) > 0
    font.Set(fontName, true)
  endif
enddef

#:defcompile
