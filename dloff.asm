;
; RRPGE User Library functions - Display List offset converters
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;


include "rrpge.asm"

section code



;
; Implementation of us_dloff_from
;
us_dloff_from_i:

.doh	equ	0		; Display list PRAM word offset, high
.dol	equ	1		; Display list PRAM word offset, low
.dsi	equ	2		; Display list size

	; Shift offset one bit right to get 32 bit offsets

	mov x3,    1
	shr c:[$.doh], x3
	src [$.dol], x3

	; Compose the display list definition

	mov x3,    0xFFC0
	and x3,    [$.dol]
	mov c,     0x000F
	and c,     [$.doh]
	or  x3,    c
	mov c,     3
	and c,     [$.dsi]
	shl c,     4
	or  x3,    c

	; Done

	rfn c:x3,  x3



;
; Implementation of us_dloff_to
;
us_dloff_to_i:

.dls	equ	0		; Offset in Display List Definition format

	; Rotate offset out to get 32 bit offset in c:x3

	mov x3,    0xFFCF
	and x3,    [$.dls]
	shr c:x3,  4

	; Make word offset of it into c:x3

	mov [$.dls], c
	shl c:x3,  1
	xch c,     [$.dls]
	shl c,     1
	or  c,     [$.dls]

	; Done

	rfn
