;
; RRPGE User Library functions - Display List double buffer wrappers
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; This should be placed near dlist.asm so the short jumps to the wrapped
; dlist functions stay in range. Also depends on dbuf.asm
;

include "rrpge.asm"

section code



;
; Implementation of us_dlist_db_setptr
;
us_dlist_db_setptr_i:

.lcl	equ	0		; Display list column to use
.psy	equ	1		; Y position
.dld	equ	2		; Display List Definition

	mov sp,    3

	; Add Display List Definition, then transfer

	jfa us_dbuf_getlist
	mov [$.dld], x3
	jms us_dlist_setptr_i



;
; Implementation of us_dlist_db_add
;
us_dlist_db_add_i:

.rch	equ	0		; Render command, high
.rcl	equ	1		; Render command, low
.hgt	equ	2		; Height
.lcl	equ	3		; Display list column to add to
.psy	equ	4		; Y position (2's complement)
.dld	equ	4		; Display List Definition

	mov sp,    6

	; Move parameters up

	mov c,     [$4]
	mov [$5],  c

	; Add Display List Definition, then transfer

	jfa us_dbuf_getlist
	mov [$.dld], x3
	jms us_dlist_add_i



;
; Implementation of us_dlist_db_addxy
;
us_dlist_db_addxy_i:

.rch	equ	0		; Render command, high
.rcl	equ	1		; Render command, low
.hgt	equ	2		; Height
.lcl	equ	3		; Display list column to add to
.psx	equ	4		; X position (2's complement)
.psy	equ	5		; Y position (2's complement)
.dld	equ	4		; Display List Definition

	mov sp,    7

	; Move parameters up

	mov c,     [$4]
	xch c,     [$5]
	mov [$6],  c

	; Add Display List Definition, then transfer

	jfa us_dbuf_getlist
	mov [$.dld], x3
	jms us_dlist_addxy_i



;
; Implementation of us_dlist_db_addbg
;
us_dlist_db_addbg_i:

.bgh	equ	0		; Background pattern, high
.bgl	equ	1		; Background pattern, low
.hgt	equ	2		; Height
.psy	equ	3		; Y position (2's complement)
.dld	equ	3		; Display List Definition

	mov sp,    5

	; Move parameters up

	mov c,     [$3]
	mov [$4],  c

	; Add Display List Definition, then transfer

	jfa us_dbuf_getlist
	mov [$.dld], x3
	jms us_dlist_addbg_i



;
; Implementation of us_dlist_db_addlist
;
us_dlist_db_addlist_i:

.clh	equ	0		; Command list offset, high
.cll	equ	1		; Command list offset, low
.hgt	equ	2		; Height
.lcl	equ	3		; Display list column to add to
.psy	equ	4		; Y position (2's complement)
.dld	equ	4		; Display List Definition

	mov sp,    6

	; Move parameters up

	mov c,     [$4]
	mov [$5],  c

	; Add Display List Definition, then transfer

	jfa us_dbuf_getlist
	mov [$.dld], x3
	jms us_dlist_addlist_i



;
; Implementation of us_dlist_db_clear
;
us_dlist_db_clear_i:

.dld	equ	0		; Display List Definition

	mov sp,    1

	; Add Display List Definition, then transfer

	jfa us_dbuf_getlist
	mov [$.dld], x3
	jms us_dlist_clear_i
