#!/bin/sh
# Copyright 2024 Charles Duan.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


filename="$1"
modulename="$2"
dirname=base/"$modulename"
SOFFICE=soffice
W2L=w2l
postconvert=bin/post-convert.rb

if [ x"$filename" = x ] ; then
    echo "Converts Open Source Property modules from Word to TeX format."
    echo "Usage: $0 [docx-file] [module-name]"
    exit 1
fi

if ! [ -f "$filename" ] ; then
    echo "No such file $filename"
    exit 1
fi

if [ -x "$dirname" ] ; then
    echo "$dirname already exists"
    exit 1
fi

case "$filename" in
    *Grynberg*)
        author="Michael Grynberg"
        ;;
    *Grimmelman*)
        author="James Grimmelmann"
        ;;
    *Tushnet*)
        author="Rebecca Tushnet"
        ;;
    *Clowney*)
        author="Stephen Clowney"
        ;;
    *Sheff*)
        author="Jeremy Sheff"
        ;;
    *)
        echo "Could not find author in file name"
        exit 1
        ;;
esac

case "$filename" in
    *.docx )
        docfile="`basename \"$filename\" .docx`".odt
        echo "Converting docx file to $docfile..."
        $SOFFICE --convert-to odt "$filename"
        filename="$docfile"
        ;;
esac

echo "Converting $filename..."

$W2L -wrap_lines_after=0 -config bin/osp.xml "$filename" "$modulename.tex"

mkdir "$dirname"
$postconvert "$modulename.tex" > "$dirname/$modulename.tex"
rm "$modulename.tex"
mv "$modulename"* "$dirname"

date=`echo "$filename" | sed -E 's/.*([0-9_]{10}).*/\1/' | sed 's/_/-/g'`

cat <<EOF > "$dirname"/metadata.tex
\moduleauthor{$author}
\moduleupdated{$date}
EOF


