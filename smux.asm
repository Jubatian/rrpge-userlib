;
; RRPGE User Library functions - Display List sprite multiplexer
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Simple sprite management system for the Graphics Display Generator. It is
; capable to automatically multiplex sprites. For the proper function the
; Display List Clear should be set up appropriately to clear the managed
; columns.
;
; Uses the following CPU RAM locations:
; 0xFB00 - 0xFC8F: Occupation data
; 0xFDCF: First column to use.
; 0xFDCE: Count of columns to use.
; 0xFDCD: Bit0: if clear, indicates the occupation data is dirty.
;
; Also adds a Page flip hook (to clear the occupation data).
;
; Occupation data format:
;
; Low 400 bytes are the bottom limits, High 400 bytes are the top limits (as
; first occupied locations, so the row is full when they equal).
;

include "rrpge.asm"

section code



; 0xFB00 - 0xFC8F: Occupation data
us_smux_ola	equ	0xFB00
us_smux_ole	equ	0xFBC8
us_smux_oha	equ	0xFBC8
us_smux_ohe	equ	0xFC90
; 0xFDCF: Column to start at
us_smux_cs	equ	0xFDCF
; 0xFDCE: Count of columns
us_smux_cc	equ	0xFDCE
; 0xFDCD: Dirty flag on bit 0: clear if dirty.
us_smux_df	equ	0xFDCD



;
; Internal function to set up display list pointer.
;
; Param1: Y position
; Param0: Display List Definition
; Ret.X3: Display list row size in bits (used to advance rows)
;
; The display list pointer is set up to incrementing 16 bits.
;
us_smux_setptr_i:

.psy	equ	0		; Y position
.dld	equ	1		; Display List Definition

	; Save CPU regs

	psh a, b, d

	; Load display list size & prepare masks

	mov a,     [$.dld]
	shr a,     4
	and a,     3		; Display list entry size
	add a,     7		; 0 => 4 * 32 bit entries etc.

	; Calculate bit offset within display list

	shl c:[$.psy], a	; Bit add value for start offset by Y position
	mov b,     c		; Y high in 'b'

	; Calculate absolute display list offset

	mov d,     [$.dld]
	shr c:d,   4
	or  d,     c
	and d,     0xFFFC	; Offset bits recovered as 512 bit offset
	shl c:d,   9		; Bit offset of display list
	add b,     c
	add c:d,   [$.psy]
	add b,     c		; Start offset in b:d acquired

	; Fill PRAM pointer 3

	mov x3,    P3_AH
	mov [x3],  b		; P3_AH
	mov [x3],  d		; P3_AL
	mov c,     0
	mov [x3],  c		; P3_IH
	mov c,     16		; 16 bit increments
	mov [x3],  c		; P3_IL
	mov c,     4		; 16 bit pointer
	mov [x3],  c		; P3_DS

	mov x3,    1
	shl x3,    a		; Return value (display list size in bits)

	; Restore CPU regs & exit

	pop a, b, d
	rfn c:x3,  x3



;
; Implementation of us_smux_reset
;
us_smux_reset_i:

	; Check dirty, do nothing unless it is necessary to clear

	xbc [us_smux_df], 0
	rfn			; No need to clear, already OK
	bts [us_smux_df], 0

	; Save CPU regs

	psh a, d, x2, xm

	; Get Display list size

	mov c,     [P_GDG_DLDEF]
	mov x3,    4		; Smallest display list size is 4 entries
	shr c,     4
	and c,     3
	shl x3,    c		; 'x3': Count of entries on a display list row

	; Calculate bottom end fill value

	mov a,     [us_smux_cs]
	mov c,     a		; For top end
	xug x3,    a
	mov a,     x3		; Too large: constrain
	mov x2,    a
	shl x2,    8
	or  a,     x2		; 'a': Bottom end fill value

	; Calculate top end fill value

	add c,     [us_smux_cc]
	xug x3,    c
	mov c,     x3		; Too large: constrain
	mov x2,    c
	shl x2,    8
	or  c,     x2		; 'c': Top end fill value

	; Prepare pointers

	mov xm,    0x6666	; All pointers PTR16I
	mov x2,    us_smux_ola
	mov x3,    us_smux_oha
	mov d,     200
	add d,     x2		; Loop terminator

	; Clear loop

.lp:	mov [x2],  a
	mov [x3],  c
	mov [x2],  a
	mov [x3],  c
	mov [x2],  a
	mov [x3],  c
	mov [x2],  a
	mov [x3],  c
	xeq x2,    d
	jms .lp

	; Restore CPU regs & exit

	pop a, d, x2, xm
	rfn c:x3,  0



;
; Implementation of us_smux_setbounds
;
us_smux_setbounds_i:

.cls	equ	0		; Start column
.clc	equ	1		; Count of columns

	mov x3,    [$.cls]
	mov [us_smux_cs], x3
	mov x3,    [$.clc]
	mov [us_smux_cc], x3
	btc [us_smux_df], 0	; Mark dirty
	rfn x3,    0



;
; Implementation of us_smux_add
;
us_smux_add_i:

.rch	equ	0		; Render command, high
.rcl	equ	1		; Render command, low
.hgt	equ	2		; Height
.btp	equ	3		; Bottom or Top add (bit 0 zero: bottom)
.psy	equ	4		; Y position (2's complement)

.mul	equ	5		; Width multiplier
.dld	equ	6		; Display list definition

	mov sp,    7

	; Save CPU regs

	psh a, b, d, x0, x1, x2, xm, xb

	; Load display list definition

	jfa us_dbuf_getlist_i
	mov [$.dld], x3

	; Retrieve source width to know how much to add to the source line
	; select to advance one line. Shift source is ignored (in this routine
	; a shift source is useless).

	mov x3,    [$.rcl]
	shr x3,    12
	and x3,    7		; Source definition select
	add x3,    P_GDG_SA0
	mov d,     0x7F
	and d,     [x3]		; Load source definition
	mov [$.mul], d

.entr:	; Clip the graphics component if needed. If partial from the top, the
	; render command itself also alters so respecting the first visible
	; line.

	mov x3,    400
	xbs [$.psy], 15
	jms .ntc		; Positive or zero: no top clip required
	mov a,     [$.psy]
	add [$.hgt], a		; New height
	xbc [$.hgt], 15
	jms .exit		; Turned negative: off screen to the top
	mul a,     [$.mul]	; For new source line select
	sub [$.rch], a		; OK, new source start calculated
	mov a,     0
	mov [$.psy], a		; New Y start (0)
.ntc:	xug x3,    [$.psy]	; Completely off screen to the bottom?
	jms .exit
	mov a,     x3
	sub a,     [$.psy]	; Number of px. available for the source
	xug a,     [$.hgt]
	mov [$.hgt], a		; Truncate height if necessary (may become 0)
	xne a,     0
	jms .exit		; Exit on zero (not handled in the main loop)

	; Rows will be added, so dirty flag will indicate the need to clear

	btc [us_smux_df], 0

	; Set up PRAM pointer 3

	jfa us_smux_setptr_i {[$.psy], [$.dld]}

	; Set up X0 and X1 for pointing into the occupation data

	mov xb,    0x0000	; Low bits of 8 bit pointers: even
	xbc [$.psy], 0
	mov xb,    0x8888	; Start position is odd
	mov x0,    [$.psy]
	shr x0,    1		; To word offset
	add x0,    us_smux_ola	; Low bounds offset
	mov x1,    200
	add x1,    x0		; High bounds offset

	; Init data to add

	mov a,     [$.rch]	; Start of high part
	mov b,     [$.rcl]	; Low part (does not change)

	; Loop init (in x3 the add value for display list row walking was
	; prepared by us_smux_setptr_i)

	mov x2,    [$.hgt]
	mov d,     [P3_AL]	; Tracks P3_AL during the loop
	xbc [$.btp], 0		; Add to bottom if 0
	jms .t			; Add to top if 1

.b:	; Add to bottom end

	mov xm,    0x448C	; X3: PTR16, X2: PTR16, X1: PTR8I, X0: PTR8W
.lpb:	mov c,     [x0]
	xne c,     [x1]
	jms .lxb		; Equal column offsets: row has no more sprites free
	shl c,     5		; Bit offset of display list column
	add c,     d
	mov [P3_AL], c
	mov [P3_RW], a
	mov c,     1
	mov [P3_RW_NI], b	; Avoid address low wraparound
	add [x0],  c
.leb:	add c:d,   x3
	add [P3_AH], c
	add a,     [$.mul]
	sub x2,    1
	jnz x2,    .lpb
	jms .exit

.lxb:	mov [x0],  c		; Just to increment x0:xb0
	jms .leb
.lxt:	mov [x1],  c		; Just to increment x1:xb1
	jms .let

.t:	; Add to top end

	mov xm,    0x44C8	; X3: PTR16, X2: PTR16, X1: PTR8W, X0: PTR8I
.lpt:	mov c,     [x1]
	xne c,     [x0]
	jms .lxt		; Equal column offsets: row has no more sprites free
	sub c,     1
	mov [x1],  c
	shl c,     5		; Bit offset of display list column
	add c,     d
	mov [P3_AL], c
	mov [P3_RW], a
	mov [P3_RW_NI], b	; Avoid address low wraparound
.let:	add c:d,   x3
	add [P3_AH], c
	add a,     [$.mul]
	sub x2,    1
	jnz x2,    .lpt

.exit:	; Restore CPU regs & exit

	pop a, b, d, x0, x1, x2, xm, xb
	rfn c:x3,  0



;
; Implementation of us_smux_addxy
;
us_smux_addxy_i:

.rch	equ	0		; Render command, high
.rcl	equ	1		; Render command, low
.hgt	equ	2		; Height
.btp	equ	3		; Bottom or Top add (bit 0 zero: bottom)
.psx	equ	4		; X position (2's complement)
.psy	equ	5		; Y position (2's complement)

.mul	equ	5		; Width multiplier
.dld	equ	6		; Display list definition

	mov sp,    7

	; Save CPU regs

	psh a, b, d, x0, x1, x2, xm, xb

	; Push stuff around a bit to make it right for jumping into
	; us_dlist_add_i: load X position in A, and fill the Y position in
	; it's place.

	mov a,     [$.psy]
	xch a,     [$.psx]

	; Load display list definition

	jfa us_dbuf_getlist_i
	mov [$.dld], x3

	; Retrieve source width to know how much to add to the source line
	; select to advance one line. Shift source is ignored (in this routine
	; a shift source is useless).

	mov x3,    [$.rcl]
	shr x3,    12
	and x3,    7		; Source definition select
	add x3,    P_GDG_SA0
	mov d,     0x7F
	and d,     [x3]		; Load source definition
	mov [$.mul], d

	; Check on-screen

	xug 640,   a		; Off-screen to the right?
	jms us_smux_add_i.exit
	xbs a,     15		; Signed? If so, maybe partly on-screen on left.
	jms .onsc

	; Negative X: possibly partly on-screen. Need to check this situation.

	mov d,     [$.mul]
	shl d,     3		; Source width in pixels
	add d,     a
	xsg d,     0		; 1 or more (signed): graphics is on-screen
	jms us_smux_add_i.exit

	; Graphics on-screen, render it

.onsc:	and a,     0x03FF	; 10 bits for shift / position
	mov d,     0xFC00	; Preserve high part of command
	and [$.rcl], d
	or  [$.rcl], a
	jms us_smux_add_i.entr



;
; Implementation of us_smux_addlist
;
us_smux_addlist_i:

.clh	equ	0		; Command list offset, high
.cll	equ	1		; Command list offset, low
.hgt	equ	2		; Height
.btp	equ	3		; Bottom or Top add (bit 0 zero: bottom)
.psy	equ	4		; Y position (2's complement)

.dld	equ	5		; Display list definition

	mov sp,    6

	; Save CPU regs

	psh a, b, d, x0, x1, x2, xm, xb

	; Load display list definition

	jfa us_dbuf_getlist_i
	mov [$.dld], x3

	; Clip the graphics component if needed. If partial from the top, the
	; render command itself also alters so respecting the first visible
	; line.

	mov x3,    400
	xbs [$.psy], 15
	jms .ntc		; Positive or zero: no top clip required
	mov a,     [$.psy]
	add [$.hgt], a		; New height
	xbc [$.hgt], 15
	jms .exit		; Turned negative: off screen to the top
	shl a,     1		; To command list offset
	sub c:[$.cll], a
	add [$.clh], c		; Adjust command list start (carry is 0xFFFF on borrow)
	mov a,     0
	mov [$.psy], a		; New Y start (0)
.ntc:	xug x3,    [$.psy]	; Completely off screen to the bottom?
	jms .exit
	mov a,     x3
	sub a,     [$.psy]	; Number of px. available for the source
	xug a,     [$.hgt]
	mov [$.hgt], a		; Truncate height if necessary (may become 0)
	xne a,     0
	jms .exit		; Exit on zero (not handled in the main loop)

	; Rows will be added, so dirty flag will indicate the need to clear

	btc [us_smux_df], 0

	; Set up PRAM pointers

	jfa us_smux_setptr_i {[$.psy], [$.dld]}
	jfa us_ptr_setwi_i {2, [$.clh], [$.cll]}

	; Set up X0 and X1 for pointing into the occupation data

	mov xb,    0x0000	; Low bits of 8 bit pointers: even
	xbc [$.psy], 0
	mov xb,    0x8888	; Start position is odd
	mov x0,    [$.psy]
	shr x0,    1		; To word offset
	add x0,    us_smux_ola	; Low bounds offset
	mov x1,    200
	add x1,    x0		; High bounds offset

	; Loop init (in x3 the add value for display list row walking was
	; prepared by us_smux_setptr_i)

	mov x2,    [$.hgt]
	mov d,     [P3_AL]	; Tracks P3_AL during the loop
	xbc [$.btp], 0		; Add to bottom if 0
	jms .t			; Add to top if 1

.b:	; Add to bottom end

	mov xm,    0x448C	; X3: PTR16, X2: PTR16, X1: PTR8I, X0: PTR8W
.lpb:	mov a,     [P2_RW]
	mov b,     [P2_RW]
	mov c,     [x0]
	xne c,     [x1]
	jms .lxb		; Equal column offsets: row has no more sprites free
	shl c,     5		; Bit offset of display list column
	add c,     d
	mov [P3_AL], c
	mov [P3_RW], a
	mov c,     1
	mov [P3_RW_NI], b	; Avoid address low wraparound
	add [x0],  c
.leb:	add c:d,   x3
	add [P3_AH], c
	sub x2,    1
	jnz x2,    .lpb
	jms .exit

.lxb:	mov [x0],  c		; Just to increment x0:xb0
	jms .leb
.lxt:	mov [x1],  c		; Just to increment x1:xb1
	jms .let

.t:	; Add to top end

	mov xm,    0x44C8	; X3: PTR16, X2: PTR16, X1: PTR8W, X0: PTR8I
.lpt:	mov a,     [P2_RW]
	mov b,     [P2_RW]
	mov c,     [x1]
	xne c,     [x0]
	jms .lxt		; Equal column offsets: row has no more sprites free
	sub c,     1
	mov [x1],  c
	shl c,     5		; Bit offset of display list column
	add c,     d
	mov [P3_AL], c
	mov [P3_RW], a
	mov [P3_RW_NI], b	; Avoid address low wraparound
.let:	add c:d,   x3
	add [P3_AH], c
	sub x2,    1
	jnz x2,    .lpt

.exit:	; Restore CPU regs & exit

	pop a, b, d, x0, x1, x2, xm, xb
	rfn c:x3,  0
