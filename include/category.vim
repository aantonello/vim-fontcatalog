vim9script
# ============================================================================
# Basic operations on categories.
# ============================================================================
import './config.vim'
import './file.vim'

# Supported subcommands:
# - 'ls' or 'list': List all categories names and the fonts they have.
#   Example: ":Category ls" List all categories.
# - 'rm' or 'remove': Remove a category from catalog.
#   Example: ":Category rm bold" remove the "bold" category.
# ----------------------------------------------------------------------------
export const SUBCOMMANDS = [ 'ls', 'rm' ]

# Returns the list of categories in the category folder.
# ----------------------------------------------------------------------------
export def List(): list<string>
  const catalogFolder = config.Check()
  return file.CatalogList(catalogFolder)
enddef

# Return the list of categories formatted.
# To be presented in the command window to show to the user.
# @param categories Optional. A list of categories to filter the output.
# @return Nothing. The result is presented in the command window.
# ----------------------------------------------------------------------------
export def ListCommand(categories: list<string>): void
  const catalogFolder = config.Check()

  final categoryList = file.CatalogList(catalogFolder)

  if !empty(categories)
    categoryList->filter((_, value) => categories->index(value) >= 0)
  endif
  categoryList->sort()

  final resultDict: dict<list<string>> = {}
  var maxLength: number = 0

  for category in categoryList
    resultDict[category] = file.CategoryRead(catalogFolder, category)
    maxLength = max([strlen(category), maxLength])
  endfor

  # We will build a list with each category name first, followed by all fonts
  # defined to this category. Almost like the font list is presented to the
  # user.
  final output: list<string> = []

  for [key, value] in resultDict->items()
    output->add('at "' .. key .. '":')
    for item in value
      output->add(repeat(' ', maxLength) .. item)
    endfor
    output->add(repeat('-', maxLength))
  endfor

  :echo output->join("\n")

enddef

# Remove a category from the catalog.
# @param name Required. Category name to remove.
# @return Nothing. A message with the success or failure will be displayed at
# the command window.
# ----------------------------------------------------------------------------
export def Remove(name: string): void
  if strlen(name) == 0
    :echo 'A category name must be provided!'
    return
  endif

  const catalogFolder = config.Check()

  # Ask for user confirmation:
  const answer = input('Are you sure to remove the category ' .. name .. ' from the catalog? [y]es or [n]o: ', '')
  if answer == '' || answer ==# 'n'
    return
  endif
  :echo "\n"

  try
    file.Delete(catalogFolder, name)
    :echomsg 'Category "' .. name .. '" was removed from catalog.'
  catch
    :echomsg v:exception
  endtry
enddef

#:defcompile
