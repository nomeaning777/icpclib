TARGET = main
LIB = lib.tex
LATEX = platex
DVIPDF = dvipdf

all: $(LIB)
	uplatex main
	uplatex main
	dvipdfmx main.dvi
$(LIB):
	ruby makelib.rb

clean:
	rm -f $(LIB)
	rm -f $(TARGET).pdf $(TARGET).aux $(TARGET).log $(TARGET).dvi $(TARGET).toc $(TARGET).ps
