;
; RRPGE User Library 32 bit division test
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Some basic tests for the 32 bit divider (us_div32), testing some key points
; and some random values. The expected results are listed in this source code
; as comments, check the program output against these: all must match exactly.
;
; If the divider is known to pass the tests, this may also be used to test
; printf's 32 bit decimal formatter.
;
; Note that in the current form it won't compile. Check the end of the file,
; and link to the User Library accordingly to what you want to test.
;


include "rrpge.asm"

AppAuth db "Jubatian"
AppName db "ULTest: 32 bit division"
Version db "00.000.000"
EngSpec db "00.016.000"
License db "RRPGEvt", "\n"
        db 0


section data

divtss:	db "%10lu (0x%08lX) / %10lu (0x%08lX) = %10lu (0x%08lX)\n", 0


section zero

	; The character writer

writt:	ds 15


section code

main:

	; Switch to 640x400, 16 color mode

	jsv kc_vid_mode {0}

	; Set up display list for 400 image lines. Will use entry 1 of the
	; list for this. Clearing the list is not necessary since the default
	; list for double scanned mode also only contained nonzero for entry
	; 1 (every second entry 1 position in the 400 line list).

	jfa us_dlist_sb_add {0x0000, 0xC000, 400, 1, 0}

	; Set up a character writer.

	jfa us_cw_tile_new {writt, up_font_4i, up_dsurf, 1}

	; Test some divisions.

	jfa divts {0x0000, 0x0010, 0x0000, 0x0003} ; 0x00000005 (5)
	jfa divts {0x0123, 0x0000, 0x0000, 0x0003} ; 0x00610000 (6356992)
	jfa divts {0x1556, 0x05DE, 0x0012, 0x1234} ; 0x0000012E (302)
	jfa divts {0x8000, 0x1111, 0x0000, 0x0003} ; 0x2AAAB05B (715829339)
	jfa divts {0x8000, 0x1110, 0x0000, 0x0003} ; 0x2AAAB05A (715829338)
	jfa divts {0x0400, 0x000F, 0x0100, 0x0003} ; 0x00000004 (4)
	jfa divts {0x0400, 0x000F, 0x0100, 0x0004} ; 0x00000003 (3)
	jfa divts {0x0000, 0x890F, 0x0000, 0x1004} ; 0x00000008 (8)
	jfa divts {0x1000, 0x0000, 0x0001, 0x0000} ; 0x00001000 (4096)
	jfa divts {0x1000, 0x1000, 0x0001, 0x0001} ; 0x00001000 (4096)
	jfa divts {0x1000, 0x0000, 0x0002, 0x0000} ; 0x00000800 (2048)
	jfa divts {0x1000, 0x1000, 0x0002, 0x0002} ; 0x00000800 (2048)
	jfa divts {0x1000, 0x0000, 0x0004, 0x0000} ; 0x00000400 (1024)
	jfa divts {0x1000, 0x1000, 0x0004, 0x0004} ; 0x00000400 (1024)
	jfa divts {0x1000, 0x0000, 0x0008, 0x0000} ; 0x00000200 (512)
	jfa divts {0x1000, 0x1000, 0x0008, 0x0008} ; 0x00000200 (512)
	jfa divts {0x1000, 0x0000, 0x0010, 0x0000} ; 0x00000100 (256)
	jfa divts {0x1000, 0x1000, 0x0010, 0x0010} ; 0x00000100 (256)
	jfa divts {0x1000, 0x0000, 0x0020, 0x0000} ; 0x00000080 (128)
	jfa divts {0x1000, 0x1000, 0x0020, 0x0020} ; 0x00000080 (128)
	jfa divts {0xFFFF, 0xFFFF, 0x8000, 0x0001} ; 0x00000001 (1)
	jfa divts {0xFFFF, 0xFFFF, 0x8000, 0x0000} ; 0x00000001 (1)
	jfa divts {0xFFFF, 0xFFFF, 0x7FFF, 0xFFFF} ; 0x00000001 (2)
	jfa divts {0x8000, 0x0002, 0x4000, 0x0001} ; 0x00000002 (2)
	jfa divts {0x8000, 0x0001, 0x4000, 0x0001} ; 0x00000001 (1)
	jfa divts {0xFFFF, 0xFFFF, 0x0000, 0x0003} ; 0x55555555 (1431655765)
	jfa divts {0xFFFF, 0xFFFE, 0x0000, 0x0003} ; 0x55555554 (1431655764)
	jfa divts {0xFFFF, 0xFFFF, 0x0000, 0x0007} ; 0x24924924 (613566756)
	jfa divts {0xFFFF, 0xFFFC, 0x0000, 0x0007} ; 0x24924924 (613566756)
	jfa divts {0xFFFF, 0xFFFB, 0x0000, 0x0007} ; 0x24924923 (613566755)
	jfa divts {0xE497, 0x4313, 0x0034, 0x017E} ; 0x00000465 (1125)
	jfa divts {0xBA5E, 0x5567, 0x0011, 0xD957} ; 0x00000A71 (2673)
	jfa divts {0xBA5E, 0x5566, 0x0011, 0xD957} ; 0x00000A70 (2672)

.mlp:	jms .mlp



; Divtest function: Prints out a division result

divts:
.o1h	equ	0		; Operand1, high
.o1l	equ	1		; Operand1, low
.o2h	equ	2		; Operand2, high
.o2l	equ	3		; Operand2, low

	jfa us_div32_i {[$.o1h], [$.o1l], [$.o2h], [$.o2l]}
	jfa us_printfnz {writt, up_cr_utf8, divtss, [$.o1h], [$.o1l], [$.o1h], [$.o1l], [$.o2h], [$.o2l], [$.o2h], [$.o2l], c, x3, c, x3}
	rfn c:x3,  0



; Add the include containing the RRPGE User Library's math component here.
; For testing the built-in User Library of an RRPGE implementation, uncomment
; the equs.
;
; include "math.asm"
;
; us_div32_i	equ	us_div32
