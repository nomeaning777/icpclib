TARGET = main
LIB = lib.tex
LATEX = platex
DVIPDF = dvipdf

all: $(LIB)
	platex main
	platex main
	dvipdf main.dvi
$(LIB):
	ruby makelib.rb

clean:
	rm -f $(LIB)
	rm -f $(TARGET).pdf $(TARGET).aux $(TARGET).log $(TARGET).dvi $(TARGET).toc $(TARGET).ps
