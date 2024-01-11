# *Open Source Property*: TeX Edition

This is a conversion of the casebooks *Open Source Property* into LaTeX code. It
also provides a software framework for building modular casebooks.

## Authorship and Copyright

The original *[Open Source Property](https://opensourceproperty.org/)* book is
edited by Stephen Clowney, James Grimmelmann, Michael Grynberg, Jeremy Sheff,
and Rebecca Tushnet, and is available under a Creative Commons Attribution
NonCommercial 4.0 International
[license](https://creativecommons.org/licenses/by-nc/4.0/).

The textual content of the present repository is a derivative of that work, with
edits and additions made by Charles Duan. Those additions and edits are
copyright 2023-2024 by Charles Duan, and are available under the same license.

Source code in the `bin` directory and the `modbook` LaTeX package are by
Charles Duan, and available under the GNU Public License 3.0. See the
`LICENSE.txt` file for more details.

## TL;DR: Building a Textbook

Edit the file `book.tex` to your liking. Use the `\import [module]` command to
import a module into the book as a chapter. The list of available modules is in
the `base` directory. To generate a PDF, run `make` or `make book.pdf`.

If you would like to customize the content beyond just selecting chapters, then
read on.


## How to Use This Distribution

*Open Source Property* is a ``modular'' textbook, in that chapters are provided
as somewhat independent units that others, called **compilers** in this
documentation, can arrange into a textbook or other material. Others, called
**editors** in this documentation, may wish to contribute their own modules, or
make edits to the provided content without overwriting the original files. A
person may serve both roles, making edits to the base modules and then
compiling them into a custom textbook.

The files in this distribution are arranged to facilitate the work of both
authors and editors. The directory `base` contains the original *Open Source
Property* content. Each module is stored in a subdirectory, containing `.tex`
files for the content.

### Adding and Editing Content

Editors contributing edits or materials should create a new personal directory.
The directory name `local` is a good choice for personal edits not intended for
further distribution (the `local` directory will not be committed to Git by
default, in the `.gitignore` file).

To edit an existing module, make a subdirectory under your personal directory
with the same name as the original module. For example, to customize the
Adverse Possession module, you might make a directory
`local/adverse-possession`. Then you can copy over any files from the original
module directory and edit them as desired. You don't need to copy every file; if
your personal copy is missing a file in a module, it will be taken from the
original module as described in the next section.

Notice that in each module, there is a file with the same name as the module,
for example `base/adverse-possession/adverse-possession.tex`. This file is the
main outline for the module, and uses `\import` commands to import files from
the module. This makes it easy to edit the overall structure of the module
without dealing with the content, or to edit a single case while retaining the
overall structure.

If, for example, you are happy with the text of the Adverse Possession module
but want to cut out the case *Cahill v. Morrow*, you would create the file
`local/adverse-possession/adverse-possession.tex` with the `\import` lines for
that case removed. You can also mix and match parts of modules. If, for example,
you wanted to teach prescriptive easements in the Adverse Possession module, you
could add to the end of the `adverse-possession.tex` file:
```{tex}
\section{Prescriptive Easements}

\import intro-prescriptive-easements

\import felgenhauer-v-soni


\begin{questions}
\import felgenhauer-v-soni-qs
\end{questions}
```

To create your own module, you simply create a subdirectory under your local
directory and add content files as desired. Please read the `modbook.pdf`
documentation file in this distribution for the available formatting and module
management commands that you will need to use.

### Compiling with Edited Content

Having edited content from the book (or obtained others' edited content), you
may now wish to compile a book using the base modules and some of those edited
or added modules. To do so, use the `\RepositoryPath` command in `book.tex` to
specify the module-containing directories you want to use. The highest priority
directory (probably your `local` one) should be listed first.

For more on importing modules, and also to see how to adjust the appearance and
formatting of the book, see the `book.tex` comments and the `modbook.pdf`
documentation.


## Bundled Programs

The `bin` directory contains two programs to help with assembling modules.

**Importing More *OSP* Modules.** Not all of the written modules have been
converted to TeX format. If one is missing, you can help to convert it. Download
the Word copy of the module from the website, and run:
```
bin/convert-module.sh [filename] [module]
```
This will create the file `base/[module]/[module].tex`. The conversion is not
perfect and will need to be manually adjusted. In particular, individual
readings and cases will not be separated out into individual files; you will
have to do that manually.

The `convert-module.sh` program requires Ruby and
[Writer2LaTeX](https://writer2latex.sourceforge.net/). If you have OpenOffice or
LibreOffice and the command `soffice` is in the path, then `.docx` files will
automatically be converted; otherwise you will have to convert files manually to
`.odt` format.


**Adding Cases.** If you are writing or revising a module, you may want to add a
judicial opinion. The program `bin/scholar2tex.rb` takes a Google Scholar URL
and reformats it into a TeX file with appropriate commands. The conversion is,
again, not perfect, and you will have to make manual adjustments.

The `scholar2tex.rb` program is based on [this
program](https://github.com/charlesduan/scholar2tex). It requires Ruby and
Nokogiri.
