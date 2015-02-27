;
; RRPGE User Library functions - Display List sprite manager
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Simple sprite management system for the Graphics Display Generator. For the
; proper function the Display List Clear should be set up appropriately to
; clear the managed columns.
;
; Uses the following CPU RAM locations:
; 0xFACC: Bit0: if clear, indicates the occupation data is dirty.
; 0xFACB: First column to use.
; 0xFACA: Count of columns to use.
; 0xFAC9: Current first occupied column on the top.
; 0xFAC8: Current first non-occupied column on the bottom.
;
; Also adds a Page flip hook (to clear the occupation data).
;

include "rrpge.asm"

section code



; 0xFACC: Dirty flag on bit 0: clear if dirty.
us_sprite_df	equ	0xFACC
; 0xFACB: Column to start at
us_sprite_cs	equ	0xFACB
; 0xFACA: Count of columns
us_sprite_cc	equ	0xFACA
; 0xFAC9: Current top column
us_sprite_pt	equ	0xFAC9
; 0xFAC8: Current start column
us_sprite_ps	equ	0xFAC8



;
; Implementation of us_sprite_reset
;
us_sprite_reset_i:

	; Check dirty, do nothing unless it is necessary to clear

	xbc [us_sprite_df], 0
	rfn			; No need to clear, already OK
	bts [us_sprite_df], 0

	; Get total height & Display list size

	mov c,     [P_GDG_DLDEF]
	mov x3,    4		; Smallest display list size is normally 4 entries
	xbc c,     13		; Double scan?
	mov x3,    8		; But 8 entries when double scanned
	and c,     3
	shl x3,    c		; 'x3': Count of entries on a display list row

	; Calculate bottom end value

	mov c,     [us_sprite_cs]
	xug x3,    c
	mov c,     x3		; Too large: constrain
	mov [us_sprite_ps], c

	; Calculate top end value

	add c,     [us_sprite_cc]
	xug x3,    c
	mov c,     x3		; Too large: constrain
	mov [us_sprite_pt], c

	; Done

	rfn c:x3,  0



;
; Implementation of us_sprite_setbounds
;
us_sprite_setbounds_i:

.cls	equ	0		; Start column
.clc	equ	1		; Count of columns

	mov x3,    [$.cls]
	mov [us_sprite_cs], x3
	mov x3,    [$.clc]
	mov [us_sprite_cc], x3
	btc [us_sprite_df], 0	; Mark dirty
	rfn x3,    0



;
; Implementation of us_sprite_add
;
us_sprite_add_i:

.rch	equ	0		; Render command, high
.rcl	equ	1		; Render command, low
.hgt	equ	2		; Height
.btp	equ	3		; Bottom or Top add (bit 0 zero: bottom)
.psy	equ	4		; Y position (2's complement)

	; Set jump target

	mov x3,    us_dlist_db_add_i

.e:	; Mark dirty

	btc [us_sprite_df], 0

	; Determine column to use

	xbs [$.btp], 0
	jms .b			; To add bottom

.t:	; Add to top

	mov c,     [us_sprite_pt]
	xne c,     [us_sprite_ps]
	rfn			; Equal: can not add more sprites
	sub c,     1
	mov [$.btp], c		; Column is excepted here
	mov [us_sprite_pt], c
	jma x3

.b:	; Add to bottom

	mov c,     [us_sprite_ps]
	xne c,     [us_sprite_pt]
	rfn			; Equal: can not add more sprites
	mov [$.btp], c		; Column is excepted here
	add c,     1
	mov [us_sprite_ps], c
	jma x3



;
; Implementation of us_sprite_addxy
;
us_sprite_addxy_i:

.rch	equ	0		; Render command, high
.rcl	equ	1		; Render command, low
.hgt	equ	2		; Height
.btp	equ	3		; Bottom or Top add (bit 0 zero: bottom)
.psx	equ	4		; X position (2's complement)
.psy	equ	5		; Y position (2's complement)

	; Set jump target & jump common

	mov x3,    us_dlist_db_addxy_i
	jms us_sprite_add_i.e



;
; Implementation of us_sprite_addlist
;
us_sprite_addlist_i:

.clh	equ	0		; Command list offset, high
.cll	equ	1		; Command list offset, low
.hgt	equ	2		; Height
.btp	equ	3		; Bottom or Top add (bit 0 zero: bottom)
.psy	equ	4		; Y position (2's complement)

	; Set jump target & jump common

	mov x3,    us_dlist_db_addlist_i
	jms us_sprite_add_i.e
