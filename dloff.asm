;
; RRPGE User Library functions - Display List offset converters
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
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

.doh	equ	0		; Display list PRAM offset, high
.dol	equ	1		; Display list PRAM offset, low
.dsi	equ	2		; Display list size

	; Shift offset up into $.doh, so a transfer to us_dloff_clip is
	; possible

	mov x3,    6
	shl c:[$.dol], x3
	slc [$.doh], x3

	; Transfer, so us_dloff_clip will finish it.

	mov c,     [$.dsi]
	jms us_dloff_clip_i.entr



;
; Implementation of us_dloff_to
;
us_dloff_to_i:

.dls	equ	0		; Offset in Display List Definition format

	; Sanitize offset

	jfa us_dloff_clip_i {[$.dls]}
	and x3,    0x07FC	; Cut size bits

	; Create word offset and return

	shl c:x3,  10
	rfn



;
; Implementation of us_dloff_clip
;
us_dloff_clip_i:

.dls	equ	0		; Offset in Display List Definition format

	; Create size mask

	mov c,     [$.dls]
.entr:	and c,     3		; Size bits
	not x3,    0x0003	; Loads 0xFFFC
	shl x3,    c
	and x3,    0x07FC	; Size dependent mask created

	; Combine into display list offset and return

	and x3,    [$.dls]
	or  x3,    c
	rfn
