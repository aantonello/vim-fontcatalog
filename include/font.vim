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
  final fontList: list<string> = file.CategoryRead(path, category)

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
  final fontList: list<string> = file.CategoryRead(path, category)
  const index: number = fontList->index(fontName)

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
  const fontName = (font !=? CURRENT) ? font : &guifont

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
  const allCategories: bool = empty(categories)

  const fontName = (font !=? CURRENT) ? font : &guifont
  var categoryList = categories

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
# @param filter A list of categories to filter the list of fonts. Only fonts
# in one or all of these categories will be listed.
# @return A dictionary where each key is the font name and its value is a list
# of categories:
# {
#   'font': [ 'category1', 'category2', ... ]
# }
# ----------------------------------------------------------------------------
export def List(filter: list<string> = []): dict<list<string>>
  const catalogFolder = config.Check()
  var categoryList = file.CatalogList(catalogFolder)

  if !empty(filter)
    categoryList->filter((_, value) => filter->index(value) >= 0)
  endif

  var result: dict<list<string>> = { }
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

# Return information of a font.
# @param font Font name.
# @return A dictionary with the following format:
# {
#   'font name': [ 'category1', 'category2', ... ]
# }
# ----------------------------------------------------------------------------
export def Current(font: string): dict<any>
  const catalogFolder = config.Check()
  const categoryList  = file.CatalogList(catalogFolder)

  var fontList: list<string>
  var categories: list<string>
  var result: dict<any>

  for category in categoryList
    fontList = file.CategoryRead(catalogFolder, category)
    if fontList->index(font) >= 0
      categories = result->get(font, [])
      categories->add(category)
      categories->sort()
      result[font] = categories
    endif
  endfor

  return result
enddef

# Writes the passed font in the '.lastused' record.
# @param fontName Optiona.. Name of the font to be written in the '.lastused'
# record. When missing, no new font will be written.
# @return The name of the last font recorded as last used.
# ----------------------------------------------------------------------------
export def LastUsed(fontName: string = ''): string
  const catalogFolder = config.Check()
  const lastUsed = file.CategoryRead(catalogFolder, file.LASTUSED)

  if strlen(fontName) > 0
    const fontList: list<string> = [ fontName ]
    file.CategoryWrite(catalogFolder, file.LASTUSED, fontList)
  endif

  return lastUsed->get(0, '')
enddef

#:defcompile
