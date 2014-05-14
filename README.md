Font Catalog
============

A simple still helpful GUI font catalog. This plugin enables you to
categorize your preferred fonts so you can easily choose between them.

Some people like to use Vim in a terminal window. Simple still efficient. Some
people like to use GUI Vim, like my self. Most, maybe, choose a single font
and stick with it for a very long time. Others like to change it from time to
time, between Vim sessions or Vim instances. Some match font selection with
color scheme. Some are good to use with light background. Others only on dark
background. Some fonts looks great in Linux or Mac but sucks on Windows.
Others look the other way around. Some fonts have *bold* and/or *italic*
variants. Others do not. Thats is why I wrote this little plugin. To organize
this bunch of differences and possibilities in a simple way.

**Font Catalog** builds a catalog of fonts you choose to use in Vim sessions.
You set a font in GUI Vim then add it to the catalog, setting some categories
(or properties) for that font. You do this with all your fonts, or only the
fonts you use most. The you can query the plugin which font has a specific
property or which fonts share some set of properties.

The catalog is just a directory in your machine. The default directory is
`~/.vim/fontcatalog` but you can choose other location setting the
`g:fc_CatalogFolder` option in your `vimrc` file. Categories are files. The
plugin enables you to manage these categories, adding or removing fonts to it
or removing an entire category. Choosing a font is still manual. But, based on
the catalog, the command is *completion enabled*.

## Installing

A Vimball file is provided. Load `fontcatalog.vmb` into Vim and source it:

    :so %

It will decompress and install the complete set of (2) files in the right
directories. Also the help file will be ready to use.

    :help fontcatalog

## License

This plugin is under GPLv3 license. This basically means that you are free to
copy, share, sell or change it as you like. There are no warranties though. If
you find some bugs, please mail me.

## ChangeLog

**May 14, 2014**: Version 1.0 - First release.

