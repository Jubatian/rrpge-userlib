;
; RRPGE User Library functions - Display List low level assistance
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;

include "rrpge.asm"
include "dloff.asm"

section code



;
; Implementation of us_dlist_setptr
;
us_dlist_setptr_i:

.lcl	equ	0		; Display list column to use
.psy	equ	1		; Y position
.dld	equ	2		; Display List Definition

	mov sp,    7

	; Save CPU regs

	mov [$3],  a
	mov [$4],  b
	mov [$5],  d
	mov [$6],  x0

	; Load display list size & prepare masks

	mov a,     [$.dld]
	and a,     3		; Display list entry size
	not d,     0x0003	; Loads 0xFFFC
	shl d,     a
	and d,     0x07FC	; Mask for display list offset
	xbc [$.dld], 13		; Double scan?
	add a,     1		; 0 / 1 / 2 / 3 / 4
	add a,     7		; 0 => 4 * 32 bit entries etc.

	; Calculate bit offset within display list

	shl c:[$.psy], a	; Bit add value for start offset by Y position
	mov b,     c		; Y high in 'b'
	mov c,     [$.lcl]
	shl c,     5		; Column (32 bit entry) to bit offset
	add [$.psy], c		; No wrap for proper colum specifications

	; Calculate absolute display list offset

	and d,     [$.dld]	; Apply mask on display list def. into the mask
	shl c:d,   14		; Bit offset of display list
	mov x0,    c
	add c:d,   [$.psy]
	adc x0,    b		; Start offset in x0:d acquired

	; Prepare PRAM pointer fill. In 'c' prepares a zero for incr. high

	mov b,     1
	shl c:b,   a		; 128 / 256 / 512 / 1024 / 2048 bit per line
	mov a,     4		; 16 bit pointer, always increment

	; Fill PRAM pointers

	mov x3,    P2_AH	; High part of display list entry
	mov [x3],  x0		; P2_AH
	mov [x3],  d		; P2_AL
	mov [x3],  c		; P2_IH
	mov [x3],  b		; P2_IL
	mov [x3],  a		; P2_DS
	add x3,    3		; To P3_AH
	bts d,     4		; Low part of display list entry
	mov [x3],  x0		; P3_AH
	mov [x3],  d		; P3_AL
	mov [x3],  c		; P3_IH
	mov [x3],  b		; P3_IL
	mov [x3],  a		; P3_DS

	mov x3,    b		; Return value (display list size in bits)

	; Restore CPU regs & exit

	mov a,     [$3]
	mov b,     [$4]
	mov d,     [$5]
	mov x0,    [$6]
	rfn



;
; Implementation of us_dlist_add
;
us_dlist_add_i:

.rch	equ	0		; Render command, high
.rcl	equ	1		; Render command, low
.hgt	equ	2		; Height
.lcl	equ	3		; Display list column to add to
.dld	equ	4		; Display List Definition
.psy	equ	5		; Y position (2's complement)
.mul	equ	6		; Width multiplier

	mov sp,    9

	; Save CPU regs

	mov [$7],  a
	mov [$8],  d

	; Calculate source width multiplier so to know how many to add to the
	; source line select to advance one line. The multiplier stays one if
	; the source is a shift source.

	mov x3,    [$.rch]
	shr x3,    12
	and x3,    7		; Source definition select
	add x3,    P_GDG_SA0
	mov d,     [x3]		; Load source definition
	xbc d,     4
	mov d,     0		; Shift source: multiplier is 1
	and d,     0xF
	shl d,     1
	add d,     1		; Width multiplier: 1 to 31, odd
	mov [$.mul], d

.entr:	; Clip the graphics component if needed. If partial from the top, the
	; render command itself also alters so respecting the first visible
	; line.

	mov x3,    200
	xbs [$.dld], 13		; Double scanned if set
	shl x3,    1		; Make 400 if not double scanned
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

	; Set up PRAM pointers

	jfa us_dlist_setptr_i {[$.lcl], [$.psy], [$.dld]}

	; Add new graphics element to each line.

	not c,     0x0003	; Loads 0xFFFC (to discard low 2 bits of height)
	mov a,     0x0003	; Loads 0x0003 (to retrieve low 2 bits of height)
	and c,     [$.hgt]	; Note: Zero height is also OK
	and a,     [$.hgt]
	mov x3,    22		; Offset of .lt0 relative to jmr
	sub x3,    a
	shl a,     2
	sub x3,    a		; Calculate loop entry (rel. jump to .ltx)
	mov a,     [$.rch]	; Start of high part
	mov d,     [$.rcl]	; Low part (does not change)
	jmr x3
.lp:	sub c,     4
	mov [P2_RW], a
	mov [P3_RW], d
	add a,     [$.mul]
.lt3:	mov [P2_RW], a
	mov [P3_RW], d
	add a,     [$.mul]
.lt2:	mov [P2_RW], a
	mov [P3_RW], d
	add a,     [$.mul]
.lt1:	mov [P2_RW], a
	mov [P3_RW], d
	add a,     [$.mul]
.lt0:	xeq c,     0
	jms .lp

.exit:	; Restore CPU regs & exit

	mov a,     [$7]
	mov d,     [$8]
	rfn



;
; Implementation of us_dlist_addxy
;
us_dlist_addxy_i:

.rch	equ	0		; Render command, high
.rcl	equ	1		; Render command, low
.hgt	equ	2		; Height
.lcl	equ	3		; Display list column to add to
.dld	equ	4		; Display List Definition
.psx	equ	5		; X position (2's complement)
.psy	equ	6		; Y position (2's complement)
.mul	equ	6		; Width multiplier

	mov sp,    9

	; Save CPU regs

	mov [$7],  a
	mov [$8],  d

	; Push stuff around a bit to make it right for jumping into
	; us_dlist_add_i: load X position in A, and fill the Y position in
	; it's place.

	mov a,     [$.psy]
	xch a,     [$.psx]

	; Calculate source width multiplier so to know how many to add to the
	; source line select to advance one line. Shift source is not checked
	; (in this routine using a shift source is useless).

	mov x3,    [$.rch]
	shr x3,    12
	and x3,    7		; Source definition select
	add x3,    P_GDG_SA0
	mov d,     [x3]		; Load source definition
	and d,     0xF
	shl d,     1
	add c:d,   1		; Width multiplier: 1 to 31, odd (c is zeroed)
	mov [$.mul], d

	; Set C to one for 8 bit mode, to be used in subsequend mode specific
	; adjustments.

	xbc [$.dld], 12		; 4 bit mode if clear
	mov c,     1		; 1 in 8 bit mode, 0 in 4 bit mode

	; Calculate X high limit

	mov x3,    640
	shr x3,    c		; 320 in 8 bit mode

	; Check on-screen

	xug x3,    a		; Off-screen to the right?
	jms us_dlist_add_i.exit
	xbs a,     15		; Signed? If so, maybe partly on-screen on left.
	jms .onsc

	; Negative X: possibly partly on-screen. Need to check this situation.

	mov x3,    [$.rch]
	shl x3,    5
	and x3,    7		; Source line size shift
	sbc x3,    0xFFFD	; Adjust: +3 (8 pixels / cell) for 4 bit, +2 (4 pixels / cell) for 8 bit mode
	mov d,     [$.mul]
	shl d,     x3		; Width of graphic element in pixels
	add d,     a
	xsg d,     0		; 1 or more (signed): graphics is on-screen
	jms us_dlist_add_i.exit

	; Graphics on-screen, render it

.onsc:	shl a,     c		; Double X position for 8 bit mode
	and a,     0x03FF	; 10 bits for shift / position
	mov d,     0xFC00	; Preserve high part of command
	and [$.rcl], d
	or  [$.rcl], a
	jms us_dlist_add_i.entr



;
; Implementation of us_dlist_addbg
;
us_dlist_addbg_i:

.bgh	equ	0		; Background pattern, high
.bgl	equ	1		; Background pattern, low
.hgt	equ	2		; Height
.dld	equ	3		; Display List Definition
.psy	equ	4		; Y position (2's complement)

	mov sp,    7

	; Save CPU regs

	mov [$5],  a
	mov [$6],  d

	; Clip the graphics component if needed. If partial from the top, the
	; render command itself also alters so respecting the first visible
	; line.

	mov x3,    200
	xbs [$.dld], 13		; Double scanned if set
	shl x3,    1		; Make 400 if not double scanned
	xbs [$.psy], 15
	jms .ntc		; Positive or zero: no top clip required
	mov a,     [$.psy]
	add [$.hgt], a		; New height
	xbc [$.hgt], 15
	jms .exit		; Turned negative: off screen to the top
	mov a,     0
	mov [$.psy], a		; New Y start (0)
.ntc:	xug x3,    [$.psy]	; Completely off screen to the bottom?
	jms .exit
	mov a,     x3
	sub a,     [$.psy]	; Number of px. available for the source
	xug a,     [$.hgt]
	mov [$.hgt], a		; Truncate height if necessary (may become 0)

	; Set up PRAM pointers

	jfa us_dlist_setptr_i {0, [$.psy], [$.dld]}

	; Add new graphics element to each line.

	not c,     0x0003	; Loads 0xFFFC (to discard low 2 bits of height)
	mov a,     0x0003	; Loads 0x0003 (to retrieve low 2 bits of height)
	and c,     [$.hgt]	; Note: Zero height is also OK
	and a,     [$.hgt]
	mov x3,    18		; Offset of .lt0 relative to jmr
	shl a,     2
	sub x3,    a		; Calculate loop entry (rel. jump to .ltx)
	mov a,     [$.bgh]	; High part of background
	mov d,     [$.bgl]	; Low part of background
	jmr x3
.lp:	sub c,     4
	mov [P2_RW], a
	mov [P3_RW], d
.lt3:	mov [P2_RW], a
	mov [P3_RW], d
.lt2:	mov [P2_RW], a
	mov [P3_RW], d
.lt1:	mov [P2_RW], a
	mov [P3_RW], d
.lt0:	xeq c,     0
	jms .lp

.exit:	; Restore CPU regs & exit

	mov a,     [$5]
	mov d,     [$6]
	rfn



;
; Implementation of us_dlist_addlist
;
us_dlist_addlist_i:

.clh	equ	0		; Command list offset, high
.cll	equ	1		; Command list offset, low
.hgt	equ	2		; Height
.lcl	equ	3		; Display list column to add to
.dld	equ	4		; Display List Definition
.psy	equ	5		; Y position (2's complement)

	mov sp,    7

	; Save CPU regs

	mov [$6],  a

	; Clip the graphics component if needed. If partial from the top, the
	; render command itself also alters so respecting the first visible
	; line.

	mov x3,    200
	xbs [$.dld], 13		; Double scanned if set
	shl x3,    1		; Make 400 if not double scanned
	xbs [$.psy], 15
	jms .ntc		; Positive or zero: no top clip required
	mov a,     [$.psy]
	add [$.hgt], a		; New height
	xbc [$.hgt], 15
	jms .exit		; Turned negative: off screen to the top
	shl a,     1		; To command list offset
	sub c:[$.cll], a
	sub [$.clh], c		; Adjust command list start
	mov a,     0
	mov [$.psy], a		; New Y start (0)
.ntc:	xug x3,    [$.psy]	; Completely off screen to the bottom?
	jms .exit
	mov a,     x3
	sub a,     [$.psy]	; Number of px. available for the source
	xug a,     [$.hgt]
	mov [$.hgt], a		; Truncate height if necessary (may become 0)

	; Set up PRAM pointers

	jfa us_dlist_setptr_i {[$.lcl], [$.psy], [$.dld]}
	jfa us_ptr_set16i_i {1, [$.clh], [$.cll]}

	; Add new graphics element to each line.

	not c,     0x0003	; Loads 0xFFFC (to discard low 2 bits of height)
	mov a,     0x0003	; Loads 0x0003 (to retrieve low 2 bits of height)
	and c,     [$.hgt]	; Note: Zero height is also OK
	and a,     [$.hgt]
	mov x3,    34		; Offset of .lt0 relative to jmr
	shl a,     3
	sub x3,    a		; Calculate loop entry (rel. jump to .ltx)
	jmr x3
.lp:	sub c,     4
	mov a,     [P1_RW]
	mov [P2_RW], a
	mov a,     [P1_RW]
	mov [P3_RW], a
.lt3:	mov a,     [P1_RW]
	mov [P2_RW], a
	mov a,     [P1_RW]
	mov [P3_RW], a
.lt2:	mov a,     [P1_RW]
	mov [P2_RW], a
	mov a,     [P1_RW]
	mov [P3_RW], a
.lt1:	mov a,     [P1_RW]
	mov [P2_RW], a
	mov a,     [P1_RW]
	mov [P3_RW], a
.lt0:	xeq c,     0
	jms .lp

.exit:	; Restore CPU regs & exit

	mov a,     [$6]
	rfn



;
; Implementation of us_dlist_clear
;
us_dlist_clear_i:

.dld	equ	0		; Display List Definition

	; Load display list size & prepare masks

	mov c,     [$.dld]
	and c,     3		; Display list entry size
	not x3,    0x0003	; Loads 0xFFFC
	shl x3,    c
	and x3,    0x07FC	; Mask for display list offset

	; Prepare and fire a PRAM set

	and [$.dld], x3		; Mask out offset bits in list
	mov x3,    3200		; Smallest display list size (400 * 8 words)
	shl x3,    c		; Display list's size in x3
	mov c,     10		; Shift offset to word
	shl c:[$.dld], c
	jfa us_set_p_i {c, [$.dld], 0, x3}

	; All cleared

	rfn
