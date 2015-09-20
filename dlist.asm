;
; RRPGE User Library functions - Display List low level assistance
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Uses the following CPU RAM locations:
; 0xFDAC: Vertical limit, low
; 0xFDAD: Vertical limit, high
;


include "rrpge.asm"
include "dloff.asm"

section code



; 0xFDAC: Vertical limit, low
us_dlist_vl	equ	0xFDAC
; 0xFDAD: Vertical limit, high
us_dlist_vh	equ	0xFDAD



;
; Implementation of us_dlist_setbounds
;
us_dlist_setbounds_i:

.vll	equ	0		; Vertical limit, low
.vlh	equ	1		; Vertical limit, high

	mov c,     [$.vll]
	mov x3,    [$.vlh]
	xsg c,     0		; Clip to zero on the bottom
	mov c,     0
	xsg x3,    0
	mov x3,    0
	xsg 400,   c		; Clip to 400 on the top
	mov c,     400
	xsg 400,   x3
	mov x3,    400
	xsg x3,    c		; Swap if low limit is higher than high limit
	xch x3,    c
	mov [us_dlist_vl], c
	mov [us_dlist_vh], x3
	rfn c:x3,  0



;
; Implementation of us_dlist_setptr
;
us_dlist_setptr_i:

.lcl	equ	0		; Display list column to use
.psy	equ	1		; Y position
.dld	equ	2		; Display List Definition

	; Save CPU regs

	psh a, b, d, x0

	; Load display list size & prepare masks

	mov a,     [$.dld]
	and a,     3		; Display list entry size
	add a,     7		; 0 => 4 * 32 bit entries etc.

	; Calculate bit offset within display list

	shl c:[$.psy], a	; Bit add value for start offset by Y position
	mov b,     c		; Y high in 'b'
	mov c,     [$.lcl]
	shl c,     5		; Column (32 bit entry) to bit offset
	add [$.psy], c		; No wrap for proper colum specifications

	; Calculate absolute display list offset

	mov d,     0xFFFC
	and d,     [$.dld]	; Offset bits recovered as 512 bit offset
	shl c:d,   9		; Bit offset of display list
	mov x0,    c
	add c:d,   [$.psy]
	adc x0,    b		; Start offset in x0:d acquired

	; Prepare PRAM pointer fill. In 'c' prepares a zero for incr. high

	mov b,     1
	shl c:b,   a		; 128 / 256 / 512 / 1024 bit per line
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

	pop a, b, d, x0
	rfn c:x3,  x3



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

	mov sp,    7

	; Save CPU regs

	psh a, d

	; Retrieve source width to know how much to add to the source line
	; select to advance one line.

	mov x3,    [$.rcl]
	shr x3,    13		; Source definition select
	add x3,    P_GDG_SA0
	mov a,     [x3]
	mov d,     0x3F
	and d,     a
	xbs a,     6		; Tiled mode: Shift source bit ignored
	xbs a,     7		; Shift source
	jms .nsh
	mov x3,    d
	mov d,     1
	shl d,     x3
.nsh:	shl d,     1		; Size in cells instead of cell pairs
	xbs a,     6		; Tiled mode: Always like X expanded
	xbc a,     11		; X expanded mode
	shr d,     1		; X expanded mode: a cell pair needs one cell source
	mov [$.mul], d

.entr:	; Clip the graphics component if needed. If partial from the top, the
	; render command itself also alters so respecting the first visible
	; line.

	mov a,     [us_dlist_vl]
	xsg a,     [$.psy]
	jms .ntc		; No top clip required
	xch a,     [$.psy]	; New Y start set in $.psy
	sub a,     [$.psy]	; 'a': Vertical relocation (negative)
	add [$.hgt], a		; New height
	xbc [$.hgt], 15		; (Note: ZERO HEIGHT may remain here!)
	jms .exit		; Turned negative: off display to the top
	mul a,     [$.mul]	; For new source line select
	sub [$.rch], a		; OK, new source start calculated
.ntc:	mov a,     [us_dlist_vh]
	xug a,     [$.psy]	; Completely off display to the bottom?
	jms .exit
	sub a,     [$.psy]	; Number of px. available for the source
	xug a,     [$.hgt]
	mov [$.hgt], a		; Truncate height if necessary

	; Set up PRAM pointers

	jfa us_dlist_setptr_i {[$.lcl], [$.psy], [$.dld]}

	; Add new graphics element to each line.

	mov c,     0xFFFC	; Loads 0xFFFC (to discard low 2 bits of height)
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
.lt0:	jnz c,     .lp

.exit:	; Restore CPU regs & exit

	pop a, d
	rfn c:x3,  0



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

.mul	equ	6		; Width

	mov sp,    7

	; Save CPU regs

	psh a, d

	; Push stuff around a bit to make it right for jumping into
	; us_dlist_add_i: load X position in A, and fill the Y position in
	; it's place.

	mov a,     [$.psy]
	xch a,     [$.psx]

	; Retrieve source width to know how much to add to the source line
	; select to advance one line. Shift source and Tiled mode are ignored
	; (in this routine these are useless).

	mov x3,    [$.rcl]
	shr x3,    13		; Source definition select
	add x3,    P_GDG_SA0
	mov x3,    [x3]
	mov d,     0x3F
	and d,     x3
	mov c,     d		; Store away cell pair width, the output width
	xbs x3,    11		; X expanded mode
	shl d,     1		; Non X expanded mode needs 2 cells per cell pair
	mov [$.mul], d

	; Check on-screen

	xug 640,   a		; Off-screen to the right?
	jms us_dlist_add_i.exit
	xbs a,     15		; Signed? If so, maybe partly on-screen on left.
	jms .onsc

	; Negative X: possibly partly on-screen. Need to check this situation.

	shl c,     4		; Output width in pixels
	add c,     a
	xsg c,     0		; 1 or more (signed): graphics is on-screen
	jms us_dlist_add_i.exit

	; Graphics on-screen, render it

.onsc:	and a,     0x03FF	; 10 bits for shift / position
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

	; Save CPU regs

	psh a, d

	; Clip the graphics component if needed. If partial from the top, the
	; render command itself also alters so respecting the first visible
	; line.

	mov a,     [us_dlist_vl]
	xsg a,     [$.psy]
	jms .ntc		; No top clip required
	xch a,     [$.psy]	; New Y start set in $.psy
	sub a,     [$.psy]	; 'a': Vertical relocation (negative)
	add [$.hgt], a		; New height
	xbc [$.hgt], 15		; (Note: ZERO HEIGHT may remain here!)
	jms .exit		; Turned negative: off display to the top
.ntc:	mov a,     [us_dlist_vh]
	xug a,     [$.psy]	; Completely off display to the bottom?
	jms .exit
	sub a,     [$.psy]	; Number of px. available for the source
	xug a,     [$.hgt]
	mov [$.hgt], a		; Truncate height if necessary

	; Set up PRAM pointers

	jfa us_dlist_setptr_i {0, [$.psy], [$.dld]}

	; Add new graphics element to each line.

	mov c,     0xFFFC	; Loads 0xFFFC (to discard low 2 bits of height)
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
.lt0:	jnz c,     .lp

.exit:	; Restore CPU regs & exit

	pop a, d
	rfn c:x3,  0



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

	mov a,     [us_dlist_vl]
	xsg a,     [$.psy]
	jms .ntc		; No top clip required
	xch a,     [$.psy]	; New Y start set in $.psy
	sub a,     [$.psy]	; 'a': Vertical relocation (negative)
	add [$.hgt], a		; New height
	xbc [$.hgt], 15		; (Note: ZERO HEIGHT may remain here!)
	jms .exit		; Turned negative: off display to the top
	shl a,     1		; To command list offset
	sub c:[$.cll], a
	add [$.clh], c		; Adjust command list start (carry is 0xFFFF on borrow)
.ntc:	mov a,     [us_dlist_vh]
	xug a,     [$.psy]	; Completely off display to the bottom?
	jms .exit
	sub a,     [$.psy]	; Number of px. available for the source
	xug a,     [$.hgt]
	mov [$.hgt], a		; Truncate height if necessary

	; Set up PRAM pointers

	jfa us_dlist_setptr_i {[$.lcl], [$.psy], [$.dld]}
	jfa us_ptr_setwi_i {1, [$.clh], [$.cll]}

	; Add new graphics element to each line.

	mov c,     0xFFFC	; Loads 0xFFFC (to discard low 2 bits of height)
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
.lt0:	jnz c,     .lp

.exit:	; Restore CPU regs & exit

	mov a,     [$6]
	rfn c:x3,  0



;
; Implementation of us_dlist_clear
;
us_dlist_clear_i:

.dld	equ	0		; Display List Definition

	; Load display list offset and size

	mov x3,    0xFFFC
	and x3,    [$.dld]	; Offset bits recovered as 512 bit offset

	mov c,     [$.dld]
	and c,     3		; Display list entry size

	; Prepare and fire a PRAM set

	mov [$.dld], x3
	mov x3,    3200		; Smallest display list size (400 * 8 words)
	shl x3,    c		; Display list's size in x3
	mov c,     5		; Shift offset to word (16 bit offset)
	shl c:[$.dld], c
	jfa us_set_p_i {c, [$.dld], 0, x3}

	; All cleared

	rfn c:x3,  0
