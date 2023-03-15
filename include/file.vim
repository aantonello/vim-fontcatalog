vim9script
# ============================================================================
# Basic file operations.
# ============================================================================

export const ALLFONTS = '.allfonts'
export const LASTUSED = '.lastused'

# Read a category file.
# @param filePath string with path of the catalog folder.
# @param name string with category name to read.
# @return A list where each line has a font name.
# ----------------------------------------------------------------------------
export def CategoryRead(filePath: string, name: string): list<string>
  const fileList = globpath(filePath, name, true, true)
  if empty(fileList)
    return []
  endif

  # We always select the first file. Should be only one tough.
  const selectedFile = fileList[0]
  if filereadable(selectedFile)
    try
      return readfile(selectedFile)
    catch
      return []
    endtry
  endif

  return []
enddef

# Write category to a file.
# @param filePath string with path of the catalog folder.
# @param name string with category name to read.
# @param data list of strings with data to be written.
# @return Nothing.
# ----------------------------------------------------------------------------
export def CategoryWrite(filePath: string, name: string, data: list<string>): void
  if !isdirectory(filePath)
    mkdir(filePath, 'p')
  endif
  const fileName = simplify(filePath .. '/' .. name)
  writefile(data, fileName, 's')
enddef

# List all categories present in the catalog folder.
# @param catalogPath Path for the catalog.
# @return A list of strings with all categories found.
# ----------------------------------------------------------------------------
export def CatalogList(catalogPath: string): list<string>
  var catalogList = globpath(catalogPath, '*', true, true)

  if empty(catalogList)
    return []
  endif

  # Filter out '.lastused' and '.allfonts'.
  catalogList->filter((_, key) => key !=? LASTUSED && key !=? ALLFONTS)
  catalogList->map((_, val) => val->fnamemodify(':t'))
  return catalogList
enddef

# Deletes a file from the catalog folder.
# @param catalogPath The path to the catalog.
# @param fileName Name of the file (category) to be removed.
# @return On success the function returns TRUE. Otherwise, an error is thrown.
# ----------------------------------------------------------------------------
export def Delete(catalogPath: string, fileName: string): bool
  const filePath = simplify(catalogPath .. '/' .. fileName)
  delete(filePath)
  return true
enddef

#:defcompile
