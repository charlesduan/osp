UNAME := $(shell uname)

export TEXINPUTS := .:../modbook:$(HOME)/cdoc/texmf//:

ifeq ($(shell uname), Darwin)
    STAT=stat -f %m
else
    STAT=stat -c %Y
endif

TEXCMD = xelatex

default: book.pdf

%.pdf: %.tex FORCE
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

FORCE:

clean:
	rm -f *.log *.aux *.toc *.dvi *.toa *.snm *.nav *.out
	rm -f *.4ct *.4tc *.idv *.lg *.tmp *.xdv *.xref
	rm -rf *.glo *.idx *.bcf *.run.xml
	rm -f out.pdf cover.pdf body.pdf

mod-%: template.tex
	$(TEXCMD) -jobname=test "\\input template.tex \\import $* \\end{document}"
	$(TEXCMD) -jobname=test "\\input template.tex \\import $* \\end{document}"

# vim: set noexpandtab:
