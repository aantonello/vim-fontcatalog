vim9script
# ============================================================================
# Subcommands for Font command.
# ============================================================================
import './font.vim'

# Supported subcommands:
# - 'add': adds the current guifont into one or more categories. At least one
#   category must be provided.
#   Example: ":Font add bold" add the current font into "bold" category.
# - 'ls' or 'list': lists fonts and categories. Category names can be used to
#   filter the result:
#   Example: ":Font ls" List all fonts and its categories.
#   Example: ":Font ls bold" List all fonts in the "bold" category.
# - 'rm' or 'remove': Remove the selected font from one or more categories.
#   Example: ":Font rm bold" Remove the current font of "bold" category.
#   Example: ":Font rm" Remove the current font of ALL categories.
# - 'set': Select a font. Parameter is the font name.
#   Example: ":Font set Inconsolata:h14"
# ----------------------------------------------------------------------------
export const SUBCOMMANDS = [ 'add', 'ls', 'rm', 'remove', 'set', '*' ]

# List all fonts in the catalog.
# @return A list with all fonts in the catalog. Only names are listed by this
# function.
# ----------------------------------------------------------------------------
export def ListNames(): list<string>
  const fontDict: dict<list<string>> = font.List()

  var names: list<string> = []

  for key in fontDict->keys()
    names->add(key)
  endfor
  names->sort()

  return names
enddef

# Return information about a single font.
# @param fontName Optional. Name of the font to retrieve information. If not
# passed the function return information of the current GUI font.
# @return A string formatted as "{fontName} in {category1}, {category2}, ...".
# When the font isn't found, an error is thrown.
# ----------------------------------------------------------------------------
export def FormattedInfo(fontName: string = ''): string
  const namedFont = (strlen(fontName) > 0) ? fontName : &guifont
  const properties: dict<list<string>> = font.Current(namedFont)

  for key in properties->keys()
    # We just want the first item. The Dictionary will have only one.
    return printf('"%s" in %s', key, join(properties[key], ', '))
  endfor

  # If we reach here the font wasn't found in the catalog.
  throw 'Font "' .. namedFont .. '" not found in catalog!'
  return ''
enddef

# Adds the current selected font in one or more categories.
# @param categories The list of categories to add the font. At least one must
# be passed.
# @return Nothing. A message will be shown to the user in the command line to
# express the success of the operation.
# ----------------------------------------------------------------------------
export def Add(categories: list<string>): void
  if empty(categories)
    throw 'At least one category must be specified.'
  endif

  const fontName = &guifont

  font.Add(fontName, categories)

  :echomsg 'Added ' .. FormattedInfo(fontName)

enddef

# List one or more fonts and its categories.
# @param categories A list of categories to filter of the fonts to show.
# @return Nothing. The function will show the list of fonts in the command
# line. Also we ask the user if he/she wants to select one of the list, by
# typing the number in front of a font. The selection of the user will set the
# chosen font as the current 'guifont'.
# ----------------------------------------------------------------------------
export def List(categories: list<string> = []): void
  var fontList: dict<list<string>> = font.List(categories)

  if empty(fontList)
    if empty(categories)
      :echomsg 'No font found in catalog!'
    else
      :echomsg 'No font found for the specified categories.'
    endif
    return
  endif

  var names: list<string> = []
  var maxLength: number = 0

  for name in fontList->keys()
    maxLength = max([strlen(name), maxLength])
    names->add(name)
  endfor
  names->sort()

  var index: number = 0
  var limit: number = len(names)
  var numlen: number = strchars(printf('%d', limit))
  var fontName: string
  var output: list<string> = []

  const formatString = '%' .. printf('%d', numlen) .. 'd: %s%s in %s'

  while index < limit
    fontName = names[index]
    output->add(printf(formatString, index + 1, fontName, repeat(' ', maxLength - strlen(fontName)), join(fontList[fontName], ', ')))
    index = index + 1
  endwhile

  output->add('Type a number to set the GUI font (<ESC> to cancel): ')

  const answer = input(output->join("\n"), '')
  if answer != '0' && answer != ''
    :echo "\n"
    index = str2nr(answer, 10) - 1
    if index >= 0 && index < limit
      Set(names[index])
    endif
  endif

enddef

# Remove a font from one or more categories.
# @param categories List of categories to remove the font.
# @return Nothing. The function will show a message to the user to inform the
# success or failure of the operation.
# ----------------------------------------------------------------------------
export def Remove(categories: list<string> = []): void
  const fontName = &guifont
  const noFilter: bool = empty(categories)

  if noFilter
    const answer = input('Are you sure to remove ' .. fontName .. ' from the catalog? [y]es or [n]o: ', '')
    if answer == '' || answer ==# 'n'
      return
    endif
    :echo "\n"
  endif

  # The user can by pass the above answer when the only category is '*'
  if noFilter || categories[0] == '*'
    font.Remove(fontName, [])
    :echomsg 'Font "' .. fontName .. '" was removed from catalog.'
  else
    font.Remove(fontName, categories)
    :echomsg printf('Font "%s" was removed from [ %s ]', fontName, categories->join(', '))
  endif
enddef

# Remove a font from the catalog.
# @param fontName String: font to be removed.
# @return Nothing. Success or failure is shown to the user in the command line
# as message.
# ----------------------------------------------------------------------------
export def Delete(fontName: string): void
  const answer = input('Are you sure to remove ' .. fontName .. ' from the catalog? [y]es or [n]o: ', '')
  if answer == '' || answer ==# 'n'
    return
  endif
  :echo "\n"

  font.Remove(fontName, [])
  :echomsg 'Font "' .. fontName .. '" was removed from catalog.'
enddef

# Select a font to be used in the GUI.
# @param fontName Required. Font name to be selected.
# @param default Optional. When TRUE we are setting a default or last used
# font. In this scenario, we don't write the font in the history.
# @return Nothing.
# ----------------------------------------------------------------------------
export def Set(fontName: string, default = false): void
  if strlen(fontName) == 0
    return
  endif

  try
    :execute 'silent set guifont=' .. fontName

    # Also write the name in the 'lastused' record, when this is not a default
    # font or last used one.
    if !default
      font.LastUsed(fontName)
    endif
  catch
    :echomsg v:exception
  endtry
enddef

# Get the last used font.
# ----------------------------------------------------------------------------
export def GetLastUsed(): string
  return font.LastUsed()
enddef

#:defcompile
