TEXCMD = xelatex

ifeq ($(shell uname), Darwin)
    STAT=stat -f %m
else
    STAT=stat -c %Y
endif

all: modbook.sty modbook.pdf

modbook.sty: modbook.ins modbook.dtx
	latex modbook.ins

install: modbook.sty
	cp -f modbook.sty deferral.sty multichoice.sty \
		../texmf/tex/latex/contrib

%.pdf: %.dtx
	export SOURCE_DATE_EPOCH=`$(STAT) "$<"`; \
	base="`basename "$<" .dtx`"; \
	touch "$$base".aux; \
	for i in 1 2 3 4 ; do \
	    oldsum="`shasum "$$base".aux`"; \
	    $(TEXCMD) "$<" || exit 1; \
	    newsum="`shasum "$$base".aux`"; \
	    if [ "$$newsum" = "$$oldsum" ] ; then \
		break; \
	    fi \
	done
