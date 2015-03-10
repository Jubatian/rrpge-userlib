;
; RRPGE User Library 32 bit reciprocal test
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; This code can be used to test the performance and correctness of an
; implementation for us_rec32 in the RRPGE User Library.
;
; Ideally it produces a green display with some white dots scattered around.
; If a calculation fails to produce the correct result, a red pixel is
; produced. Pixels are output horizontally incrementing as the divider
; increments, with white pixels plotted every second to give some hint on the
; performance of the code.
;
; The range of dividers to test should be set up by properly in "a:b", and the
; loop termination condition. About 256K divisions can be shown on one screen.
; With the current implementation interesting ranges are around:
; 0x00000002 - 0x00100000
; 0x10000000 - 0x10040000
; 0x11110000 - 0x11150000
;
; Note that in the current form it won't compile. Check the end of the file,
; and link to the User Library accordingly to what you want to test.
;

include "rrpge.asm"

AppAuth db "Jubatian"
AppName db "ULTest: 32 bit reciprocal"
Version db "00.000.001"
EngSpec db "00.016.000"
License db "RRPGEvt", "\n"
        db 0

section code

	; Switch to 640x400, 16 color mode, and create an appropriate display
	; list for a 80 column wide display starting at PRAM bank 0.

	jsv kc_vid_mode {0}
	jfa us_dlist_sb_add {0x0000, 0xC000, 400, 1, 0}

	; In 'x0' and 'x1' do some timing using the 187.5Hz clock, to count
	; seconds. 'x0' will track the changes of the clock, and 'x1' will
	; count those to trigger every 187 ticks.

	; Check ranges of the 32 bit reciprocal routine by analysing the
	; remainder. If it is OK, then outputs a green pixel (5), otherwise a
	; red (6) one. Peripheral RAM pointer 1 initially is set up for 4 bits
	; incrementing access, so the simplest is to rely on that for writing
	; pixels.

	mov a,     0		; Starting divider in "a:b"
	mov b,     2

.lp0:	jfa us_rec32_i {a, b}
	neg c,     c		; c:x3 = -c:x3 (the result of reciprocal)
	neg x3,   x3
	xeq x3,    0
	sub c,     1
	jfa us_mul32_i {c, x3, a, b}
	mov x2,    c
	sub c:x3,  b
	sbc c:x2,  a		; b:a - c:x3 must generate carry
	add c,     6		; If carry was generated (0xFFFF), 5
	mov [P1_RW], c		; Output to the Peripheral RAM (incrementing)

	mov c,     [P_CLOCK]
	xne c,     x0
	jms .nclk
	mov x0,    c
	add x1,    1
	xug x1,    186
	jms .nclk
	mov x1,    0
	mov c,     3
	mov [P1_RW], c		; Output a white pixel every second
.nclk:

	add c:b,   1
	add a,     c
	xeq a,     4		; Divider (high) to stop at
	jms .lp0

inf:	jms inf			; End of program, wait in infinite loop


; Add the include containing the RRPGE User Library's math component here.
; For testing the built-in User Library of an RRPGE implementation, uncomment
; the equs.
;
; include "math.asm"
;
; us_rec32_i	equ	us_rec32
; us_mul32_i	equ	us_mul32
