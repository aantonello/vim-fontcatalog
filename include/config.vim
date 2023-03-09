vim9script
# ============================================================================
# Configuration functions.
# ============================================================================

# Check the catalog path configuration.
# @return A string with the catalog path defined or a default value.
# ----------------------------------------------------------------------------
export def Check(): string
  var catalogFolder = get(g:, 'fc_CatalogFolder', '$VIM/catalog')
  return expand(catalogFolder)
enddef

#:defcompile
