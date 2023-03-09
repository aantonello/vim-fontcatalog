vim9script
# ============================================================================
# Operations on commands.
# ============================================================================
import './config.vim'
import './file.vim'
import './font.vim'

# Sub commands available for `:Font` command.
const FONT_COMMANDS = [ 'add', 'ls', 'list', 'rm', 'remove' ]

# Sub commands available for `:Category` command.
const CATG_COMMANDS = [ 'add', 'ls', 'list', 'rm', 'remove' ]

# Get and format the output of the current font information.
# ----------------------------------------------------------------------------
def ShowCurrent(): string
  const current: dict<any> = font.Current(&guifont)
  const [key, value] = current->items()

  return printf("guifont is '%s' in %s", key, value->join(', '))
enddef

# Get and format information of the specified font.
# @param font The font name to show the information.
# ----------------------------------------------------------------------------
def ShowFontInfo(font: string): string
  const properties: dict<any> = font.Current(font)
  const [key, value] = properties->items()

  return printf("'%s' in %s", key, value->join(', '))
enddef

# Adds the current selected font to one or more categories.
# @param categories List of categories to add the font.
# @return A string to be printed in the command line.
# ----------------------------------------------------------------------------
def Add(categories: list<string>): string
  if empty(categories)
    return "No category specified. At least one category should be specified."
  endif

  const catalogFolder = config.Check()
  const font = &guifont

  for category in categories
    font.AddFont(font, category, catalogFolder)
  endfor

  return ShowFontInfo(font)
enddef

# List completion options for `:Font` command.
# @param argLead Word fragment typed by the user.
# @param cmdLine The current content of the commad.
# @param cursorPos Current position of the cursor.
# @return A list of possible completions or an empty list when nothing can be
# completed. Winye.
# ----------------------------------------------------------------------------
export def CompleteFont(argLead: string, cmdLine: string, cursorPos: number): list<string>
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
      return matchfuzzy(FONT_COMMANDS, argLead, { matchseq: true, limit: 0 })
    else
      return FONT_COMMANDS
    endif
  endif

  # Otherwise the completion list is the list of categories.
  const tokens = split(line, '\s')[2 : ]
  const catalogFolder = config.Check()
  var categoryList = file.CatalogList(catalogFolder)

  # Filter out the tokens already typed.
  if len(tokens) > 0
    categoryList->filter((index, value) => tokens->index(value) < 0)
  endif

  if strlen(argLead)
    return matchfuzzy(categoryList, argLead, { matchseq: true, limit: 0 })
  else
    return categoryList
  endif
enddef

# Handles de main 'Font' command.
# @param subCmd Sub command. Can be empty.
# @param categories List of categories to perform the command.
# @return A message to inform the result of operation.
# ----------------------------------------------------------------------------
export def Font(subCmd = '', categories: list<string> = []): string
  if strlen(subCmd) == 0
    # No subcommand given. Show the current font properties.
    return ShowCurrent()
  endif

  if subCmd ==# 'add'
    return Add(categories)
  endif
enddef

#:defcompile
