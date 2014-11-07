#
# Makefile for Pascal-p5
#
# Makes the main compiler interpreter set.
#
PC=gpc
CFLAGS=--classic-pascal-level-0 --no-warnings --transparent-file-names --no-range-checking

all: pcom pint

pcom: source/pcom.pas
	$(PC) $(CFLAGS) -o bin/pcom source/pcom.pas
	
pint: source/pint.pas
	$(PC) $(CFLAGS) -o bin/pint source/pint.pas
	
clean: rm bin/pcom bin/pint
 