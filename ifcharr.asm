;
; RRPGE User Library functions - Character reader interface
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; The character reader interface provides a common solution for reading
; character data, providing up to 32 bits wide characters. It may normally
; be used to produce UTF-32 results, but other uses are possible.
;
; The object structure is as follows:
;
; Word0: Get next character function implementation
; Word1: Set index function implementation
;

include "rrpge.asm"

section code



;
; Implementation of us_cr_new
;
us_cr_new_i:
.opt	equ	0		; Character reader pointer
.ifn	equ	1		; Set index function implementation
.gfn	equ	2		; Get next character function implementation

	mov x3,    [$.opt]
	mov c,     [$.gfn]
	mov [x3],  c
	mov c,     [$.ifn]
	mov [x3],  c
	rfn c:x3,  x3



;
; Implementation of us_cr_setsi
;
us_cr_setsi_i:
.opt	equ	0		; Character reader pointer
.idx	equ	1		; Index to set

	mov x3,    [$.opt]
	add x3,    1
	jma [x3]		; Simply tail-transfer



;
; Implementation of us_cr_getnc
;
us_cr_getnc_i:
.opt	equ	0		; Character reader pointer

	mov x3,    [$.opt]
	jma [x3]		; Simply tail-transfer
