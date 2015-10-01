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

	; Shift offset five positions to the right for display list

	mov x3,    5
	shr c:[$.doh], x3
	src [$.dol], x3		; $.dol contains display list offset

	; Compose the display list definition

	mov x3,    0xFFFC
	mov c,     0x0003
	and x3,    [$.dol]
	and c,     [$.dsi]
	or  x3,    c

	; Done

	rfn c:x3,  x3



;
; Implementation of us_dloff_to
;
us_dloff_to_i:

.dls	equ	0		; Offset in Display List Definition format

	; Simply remove size and shift left five positions

	mov x3,    0xFFFC
	and x3,    [$.dls]
	shl c:x3,  5

	; Done

	rfn
