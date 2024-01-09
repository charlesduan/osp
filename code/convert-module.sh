#!/bin/sh

filename="$1"
modulename="$2"
dirname=../tex/"$modulename"
SOFFICE=soffice
W2L=w2l

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

w2l -wrap_lines_after=0 -config osp.xml "$filename" "$modulename.tex"

mkdir ../tex/"$modulename"
./post-convert.rb "$modulename.tex" > "$dirname/$modulename.tex"
rm "$modulename.tex"
mv "$modulename"* "$dirname"

date=`echo "$filename" | sed -E 's/.*([0-9_]{10}).*/\1/' | sed 's/_/-/g'`

cat <<EOF > ../tex/"$modulename"/metadata.tex
\moduleauthor{$author}
\moduleupdated{$date}
EOF


