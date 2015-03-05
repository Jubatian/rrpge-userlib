;
; RRPGE User Library functions - Character writer interface
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; The character writer interface provides a common solution for writing
; character data, accomodating up to 32 bits wide characters. It may normally
; be used to output UTF-32 source, but other uses are possible.
;
; The object structure is as follows:
;
; Word0: Set next character function implementation
; Word1: Initialize for output function implementation
; Word2: Set output style function implementation
;
; The set output style and the initialize functions not necessarily have to
; be provided. If not, they must be loaded with zeros, then calling these will
; do nothing.
;
; This interface may be extended (charwr) for character writers which produce
; readable data (with a character reader). For those, the object structure is
; extended with an extra function:
;
; Word3: Get next index function implementation
;

include "rrpge.asm"

section code



;
; Implementation of us_cw_new
;
us_cw_new_i:
.opt	equ	0		; Character writer pointer
.nfn	equ	1		; Set next character function implementation
.ifn	equ	2		; Initialize for output function implementation
.sfn	equ	3		; Set output style function implementation

	xug 4,     sp
	jms .po			; All 4 parameters provided
	mov x3,    sp
	mov sp,    4
	mov c,     0
	mov [$.sfn], c		; 3 parameters: no .sfn
	xug x3,    2
	mov [$.ifn], c		; 2 parameters: no .sfn and .ifn
.po:	mov x3,    [$.opt]
	mov c,     [$.nfn]
	mov [x3],  c
	mov c,     [$.ifn]
	mov [x3],  c
	mov c,     [$.sfn]
	mov [x3],  c
	rfn c:x3,  x3



;
; Implementation of us_cw_setnc
;
us_cw_setnc_i:
.opt	equ	0		; Character writer pointer
.chh	equ	1		; Character, high
.chl	equ	2		; Character, low

	mov x3,    [$.opt]
	jma [x3]		; Simply tail-transfer



;
; Implementation of us_cw_setst
;
us_cw_setst_i:
.opt	equ	0		; Character writer pointer
.atr	equ	1		; Attribute to set
.val	equ	2		; Value to set

	mov x3,    [$.opt]
	add x3,    2
	mov c,     [x3]
	xeq c,     0
	jma c			; Simply tail-transfer
	rfn c:x3,  0



;
; Implementation of us_cw_init
;
us_cw_init_i:
.opt	equ	0		; Character writer pointer

	mov x3,    [$.opt]
	add x3,    1
	mov c,     [x3]
	xeq c,     0
	jma c			; Simply tail-transfer
	rfn c:x3,  0



;
; Implementation of us_cwr_new
;
us_cwr_new_i:
.opt	equ	0		; Character writer (extended) pointer
.nfn	equ	1		; Set next character function implementation
.ifn	equ	2		; Initialize for output function implementation
.sfn	equ	3		; Set output style function implementation
.ffn	equ	4		; Get next index function implementation

	xug 5,     sp		; 3 or 4 parameters: at least .opt, .nfn and .ffn
	jms .po
	mov x3,    sp
	mov sp,    5
	sub x3,    1
	mov c,     [$x3]	; .ffn comes as last parameter
	mov [$.ffn], c
	mov c,     0		; .sfn unimplemented
	mov [$.sfn], c
	xug x3,    3
	mov [$.ifn], c		; 3 parameters: .ifn is also unimplemented
.po:	jfa us_cw_new_i {[$.opt], [$.nfn], [$.ifn], [$.sfn]}
	mov c,     [$.ffn]
	mov [x3],  c
	rfn c:x3,  x3



;
; Implementation of us_cwr_nextsi
;
us_cwr_nextsi_i:
.opt	equ	0		; Character writer (extended) pointer

	mov x3,    [$.opt]
	add x3,    3
	jma [x3]		; Simply tail-transfer
