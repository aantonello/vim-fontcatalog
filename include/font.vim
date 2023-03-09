vim9script
# ============================================================================
# Operations available to fonts
# ============================================================================
import './file.vim'
import './config.vim'

const CURRENT = 'current'

# Add a font to a category.
# @param fontName Name of the font to add.
# @param category Name of the category.
# @param path Catalog path.
# @return Nothing.
# ----------------------------------------------------------------------------
def AddFont(fontName: string, category: string, path: string): void
  var fontList: list<string>

  fontList = file.CategoryRead(path, category)
  if fontList->index(fontName) < 0
    fontList->add(fontName)
    fontList->sort()
    file.CategoryWrite(path, category, fontList)
  endif
enddef

# Remove a font from a category.
# @param fontName Name of the font to remove.
# @param category Name of the category.
# @param path Catalog path.
# @return Nothing.
# ----------------------------------------------------------------------------
def RemoveFont(fontName: string, category: string, path: string): void
  var fontList: list<string>
  var index: number

  fontList = file.CategoryRead(path, category)
  index = fontList->index(fontName)
  if index >= 0
    fontList->remove(index)
    file.CategoryWrite(path, category, fontList)
  endif
enddef

# Adds a new font or an existing one to a new category.
# @param font Font name. The word 'current' can be used to specify the current
# selected guifont.
# @param categories a list of category names.
# @return Nothing.
# ----------------------------------------------------------------------------
export def Add(font: string, categories: list<string>): void
  const catalogFolder = config.Check()
  var fontName = font

  if font ==? CURRENT
    fontName = &guifont
  endif

  for item in categories
    AddFont(fontName, item, catalogFolder)
  endfor

  # Also add this font to the '.allfonts' file.
  AddFont(fontName, file.ALLFONTS, catalogFolder)
enddef

# Remove a font from one or more categories.
# @param font Name of the font. 'current' can be used to specify the selected
# font.
# @param categories List of categories to remove the font of. If empty, the
# font will be removed from all categories and will not be listed any more.
# @return Nothing.
# ----------------------------------------------------------------------------
export def Remove(font: string, categories: list<string>): void
  const catalogFolder = config.Check()
  const allCategories = empty(categories)

  var fontName = font
  var categoryList = categories

  if font ==? CURRENT
    fontName = &guifont
  endif

  if allCategories
    categoryList = file.CatalogList(catalogFolder)
  endif

  var fontList: list<string>
  var index: number

  for item in categoryList
    RemoveFont(fontName, item, catalogFolder)
  endfor

  # When 'categories' is empty, we must remove the font from the '.allfonts'
  # and '.lastused' categories either.
  if allCategories
    RemoveFont(fontName, file.ALLFONTS, catalogFolder)
    RemoveFont(fontName, file.LASTUSED, catalogFolder)
  endif
enddef

# List all fonts and its categories.
# @return A dictionary where each key is the font name and its value is a list
# of categories:
# {
#   'font': [ 'category1', 'category2', ... ]
# }
# ----------------------------------------------------------------------------
export def List(): dict<any>
  const catalogFolder = config.Check()
  const categoryList = file.CatalogList(catalogFolder)

  var result: dict<any>
  var fontList: list<string>
  var categories: list<string>

  for category in categoryList
    fontList = file.CategoryRead(catalogFolder, category)
    for font in fontList
      categories = result->get(font, [])
      categories->add(category)
      categories->sort()
      result[font] = categories
    endfor
  endfor

  return result
enddef

#:defcompile
