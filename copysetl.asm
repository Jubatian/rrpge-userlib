;
; RRPGE User Library functions - Copy & Set Large (PRAM)
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; This should be placed near copy.asm and set.asm so the short jumps to the
; tail-called functions stay in range.
;

include "rrpge.asm"
include "copy.asm"
include "set.asm"


section code



;
; Implementation of us_copy_pfp_l
;
us_copy_pfp_l_i:

.tgh	equ	0		; Target (PRAM), high
.tgl	equ	1		; Target (PRAM), low
.srh	equ	2		; Source (PRAM), high
.srl	equ	3		; Source (PRAM), low
.lnh	equ	4		; Length, high
.lnl	equ	5		; Length, low

	; Copy using us_copy_pfp

.l0:	mov c,     0
	xne [$.lnh], c
	jms .le			; If no high part, then finish up
	mov x3,    0xFFF0
	jfa us_copy_pfp {[$.tgh], [$.tgl], [$.srh], [$.srl], x3}
	add c:[$.tgl], x3
	add [$.tgh], c
	add c:[$.srl], x3
	add [$.srh], c
	sub c:[$.lnl], x3
	add [$.lnh], c		; ('c' becomes 0xFFFF on borrow)
	jms .l0

.le:	; Tail call to normal PRAM <= PRAM copy

	mov c,     [$.lnl]
	mov [$.lnh], c
	jms us_copy_pfp



;
; Implementation of us_set_p_l
;
us_set_p_l_i:

.tgh	equ	0		; Target (PRAM), high
.tgl	equ	1		; Target (PRAM), low
.src	equ	2		; Source value
.lnh	equ	3		; Length, high
.lnl	equ	4		; Length, low

	; Set using us_set_p

.l0:	mov c,     0
	xne [$.lnh], c
	jms .le			; If no high part, then finish up
	mov x3,    0xFFF0
	jfa us_set_p {[$.tgh], [$.tgl], [$.src], x3}
	add c:[$.tgl], x3
	add [$.tgh], c
	sub c:[$.lnl], x3
	add [$.lnh], c		; ('c' becomes 0xFFFF on borrow)
	jms .l0

.le:	; Tail call to normal PRAM set

	mov c,     [$.lnl]
	mov [$.lnh], c
	jms us_set_p
