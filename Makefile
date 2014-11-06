############
# Makefile #
############
#
# Author    Sandor Zsuga (Jubatian)
# Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
#           License) extended as RRPGEvt (temporary version of the RRPGE
#           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
#           root.
#

RRPGEASM = ../asm/rrpgeasm

all: userlib.txt

clean:
	rm -r -f userlib.bin app.rpa genulib genulib.o userlib.txt

userlib.txt: userlib.bin genulib
	./genulib <userlib.bin >userlib.txt

userlib.bin: app.rpa
	tail app.rpa -c+123045 >userlib.bin

app.rpa:
	$(RRPGEASM);

genulib.o: genulib.c
	gcc -c genulib.c -o genulib.o -Os -s -Wall -pipe -pedantic

genulib: genulib.o
	gcc -o genulib genulib.o -Os -s


.PHONY: all clean
