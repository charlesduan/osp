branchname := $(shell git rev-parse --abbrev-ref HEAD | sed 's/^[^-]*-//')

PANDOC = pandoc
PANDOC_TEX_OPTS = -S --to=latex-auto_identifiers-backtick_code_blocks

UNAME := $(shell uname)

export TEXINPUTS := ../../texmf//:

ifeq ($(shell uname), Darwin)
    STAT=stat -f %m
else
    STAT=stat -c %Y
endif

TEXCMD = xelatex
CHECKSIGNED =

main: $(branchname).pdf


parts:
	cpdf -i $(branchname).pdf 1 -o cover.pdf
	cpdf -merge -i $(branchname).pdf 2-end AND -pad-multiple 4 -o body.pdf

signed:
	$(CHECKSIGNED)
	echo 'Enter your name for signing (blank for hand signature): ' ; \
	read SIGNATURE ; \
	echo 'TEXCMD += \\\\def\\\\signedby{'"$$SIGNATURE"'}\\\\input' \
	    >> Makefile
	make
	echo 'main signed: CHECKSIGNED = $$(error BRIEF IS ALREADY SIGNED)' \
	    >> Makefile

word: $(branchname).odt

%.odt: %.tex FORCE
	make4ht -c lr-oo.cfg -f odt "$<"

booklet: out.pdf

out.pdf: $(branchname).pdf
	booklet.rb "$<"

%.pdf: %.tex mkd2tex FORCE
	$(CHECKSIGNED)
	export SOURCE_DATE_EPOCH=`$(STAT) "$<"`; \
	base="`basename "$<" .tex`"; \
	touch "$$base".aux; \
	for i in 1 2 3 4 ; do \
	    oldsum="`shasum "$$base".aux`"; \
	    $(TEXCMD) "$<" || exit 1; \
	    newsum="`shasum "$$base".aux`"; \
	    if [ "$$newsum" = "$$oldsum" ] ; then \
		break; \
	    fi \
	done

%.txt: %.pdf
	pdftotext -layout -enc UTF-8 "$<"


FORCE:

MARKDOWN_FILES = $(wildcard *.mkd)
TEX_FROM_MKD = $(MARKDOWN_FILES:%.mkd=%.tex)

mkd2tex: $(TEX_FROM_MKD)

%.tex: %.mkd
	$(PANDOC) $(PANDOC_TEX_OPTS) "$<" -o "$@"

clean:
	rm -f *.log *.aux *.toc *.dvi *.toa *.snm *.nav *.out
	rm -f *.4ct *.4tc *.idv *.lg *.tmp *.xdv *.xref
	rm -rf *.glo *.idx *.bcf *.run.xml
	rm -f out.pdf cover.pdf body.pdf

# vim: set noexpandtab:
