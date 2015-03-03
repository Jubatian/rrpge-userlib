;
; RRPGE User Library functions - Set (memory)
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
; Implementation of us_set_p_i
;
us_set_p_i:

.tgh	equ	0		; Target (PRAM), high
.tgl	equ	1		; Target (PRAM), low
.src	equ	2		; Source value
.len	equ	3		; Count of words

	; Set up target (Peripheral RAM pointer)

	mov x3,    [$.tgl]
	shl c:x3,  4
	mov [P3_AL], x3
	mov x3,    [$.tgh]
	slc x3,    4
	mov [P3_AH], x3
	mov x3,    0
	mov [P3_IH], x3
	bts x3,    4		; Increment: 16
	mov [P3_IL], x3
	mov x3,    4		; Data unit size: 16 bits
	mov [P3_DS], x3

	; Set up source & length

	mov x3,    P3_RW	; Save a word & 1 cycle for each copy
	mov xm3,   PTR16
	mov [$0],  a		; Save 'a' to be restored later
	mov a,     [$.src]
	mov c,     [$.len]

	; Common set loop & return implementation 'a' must be saved to
	; [bp + 0], 'xm' must be set up appropriately before jumping here.

.entr:

	; Set loop preparation

	xbs c,     2		; Bit 2 set for length?
	jms .l2
	mov [x3],  a
	mov [x3],  a
	mov [x3],  a
	mov [x3],  a
	sub c,     4
.l2:	xbs c,     1		; Bit 1 set for length?
	jms .l1
	mov [x3],  a
	mov [x3],  a
	sub c,     2
.l1:	xbs c,     0		; Bit 0 set for length?
	jms .l0
	mov [x3],  a
	sub c,     1
.l0:				; Length is divisable by 8 here

	; Set loop

	xne c,     0
	jms .le
.lp:	mov [x3],  a
	mov [x3],  a
	mov [x3],  a
	mov [x3],  a
	mov [x3],  a
	mov [x3],  a
	mov [x3],  a
	mov [x3],  a
	sub c,     8
	jnz c,     .lp		; About 10cy/copy even for PRAM<=>PRAM.
.le:

	; Restore & Exit

	mov a,     [$0]
	mov xm3,   PTR16I
	rfn c:x3,  0



;
; Implementation of us_set_c
;
us_set_c_i:

.trg	equ	0		; Target (CPU RAM)
.src	equ	1		; Source value
.len	equ	2		; Count of words

	; Set up source, target & length

	mov x3,    [$.trg]	; Before saving 'a' overrides it
	mov [$0],  a		; Save 'a' to be restored later
	mov a,     [$.src]
	mov c,     [$.len]

	; To common set loop

	jms us_set_p_i.entr
