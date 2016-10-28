#
# Makefile for Pascal-p5
#
# Use p5c to make the main compiler interpreter set.
#

all: check pcom pint

check:
	@test -n "$$P5CDIR" || \
	echo "can't find p5c - set P5CDIR environment variable"

pcom: source/pcom.pas
	# disable variant checking for now
	sed 's/(\*$$c+,t-,d-/(*$$c+,t-,d-,v-/' \
		      < source/pcom.pas \
		      > source/pcom_nov.pas
	$$P5CDIR/p5c source/pcom_nov.pas source/pcom.c > source/pcom.lst
	gcc -I $$P5CDIR -o bin/pcom -lm source/pcom.c 2> source/pcom.err
	[ -s source/pcom.err ] || rm -f source/pcom.{c,err}

pint: source/pint.pas
	$$P5CDIR/p5c  source/pint.pas source/pint.c > source/pint.lst
	gcc -I $$P5CDIR -O3 -o bin/pint -lm source/pint.c 2> source/pint.err
	[ -s source/pint.err ] || rm -f source/pint.{c,err}


clean:
	rm -f bin/pcom bin/pint 
	find . -name "*.p5" -type f -delete
	find . -name "*.out" -type f -delete
	find . -name "*.lst" -type f -delete
	find . -name "*.obj" -type f -delete
	find . -name "*.sym" -type f -delete
	find . -name "*.int" -type f -delete
	find . -name "*.dif" -type f -delete
	find . -name "*.err" -type f -delete
	find . -name "*.tmp" -type f -delete
	find . -name "prd" -type f -delete
	find . -name "prr" -type f -delete
	find . -name "temp" -type f -delete
	find . -name "tmp" -type f -delete
	find . -name "*~" -type f -delete
