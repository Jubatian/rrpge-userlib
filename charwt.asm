;
; RRPGE User Library functions - Tileset character writer
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; tile: 8 bit Tile map blitter writer.
;
; Outputs characters to the display, properly interpreting new lines and
; carriage returns. Supports color (intended for reindex or OR mask), it can
; be styled with the 'c' attribute. Treats charcodes below 0x20 as control,
; and does not produce display for those.
;
; The ID range 0x0000 - 0x001F (graphical representations of control
; characters) may be accessed by setting the highest bit of those in the
; conversion table, which bit is always ignored for selecting the tile ID.
;
; Object structure:
;
; Word0: <Character writer interface>
; Word1: <Character writer interface>
; Word2: <Character writer interface>
; Word3: X cell position for next character.
; Word4: Y position expressed as Y * surface_width.
; Word5: Width of tileset
; Word6: Height of tileset * surface_width
; Word7: Effective width of surface
; Word8: PRAM pointer (word) of conversion table, high
; Word9: PRAM pointer (word) of conversion table, low
; Word10: Color shift (low 4 bits effective only)
; Word11: Default color (on high bits, low bits are zero)
; Word12: Current color (on high bits, low bits are zero)
; Word13: Tileset object pointer
; Word14: Destination object pointer
;
; Note that Word7 may not necessarily be equal to surface_width (if it is not
; a multiple of the tile width, it is reduced to the next smaller multiple).
;
; Functions:
;
; us_cw_tile_new (Init an object structure)
; us_cw_tile_setnc
; us_cw_tile_setst
; us_cw_tile_init
; us_cw_tile_setxy
;

include "rrpge.asm"
include "ifcharw.asm"
include "charw.asm"
include "utf.asm"

section code



;
; Implementation of us_cw_tile_new
;
us_cw_tile_new_i:
.opt	equ	0		; Object pointer
.col	equ	1		; Initial color (appropriate low bits used)
.csh	equ	2		; Color shift (low 4 bits used)
.tpt	equ	3		; Used tileset object's pointer
.spt	equ	4		; Used destination surface object's pointer
.tbh	equ	5		; Conversion table PRAM word pointer, high
.tbl	equ	6		; Conversion table PRAM word pointer, low

	jfa us_cw_new_i {[$.opt], us_cw_tile_setnc, us_cw_tile_init, us_cw_tile_setst}

	mov c,     0
	mov [x3],  c		; Initial X
	mov [x3],  c		; Initial Y
	add x3,    3
	mov c,     [$.tbh]
	mov [x3],  c
	mov c,     [$.tbl]
	mov [x3],  c
	mov c,     [$.csh]
	mov [x3],  c		; Color shift (shifts only take low 4 bits, don't care)
	shl [$.col], c
	mov c,     [$.col]
	mov [x3],  c		; Color (default)
	mov [x3],  c		; Color (current)
	mov c,     [$.tpt]
	mov [x3],  c
	mov c,     [$.spt]
	mov [x3],  c

	rfn c:x3,  0



;
; Implementation of us_cw_tile_setnc
;
us_cw_tile_setnc_i:
.opt	equ	0		; Object pointer
.u4h	equ	1		; UTF-32, high
.u4l	equ	2		; UTF-32, low

	mov sp,    5

	; Save CPU registers & provide entry point

	mov [$3],  a
	mov [$4],  b

	; Look up character

	mov x3,    [$.opt]
	add x3,    8
	jfa us_idfutf32_i {[x3], [x3], [$.u4h], [$.u4l]}
	mov a,     x3

	; Process special characters

	mov xm3,   PTR16	; It is simpler to do the specials this way
	mov x3,    [$.opt]
	add x3,    5
	mov b,     [x3]		; Prepare tile width in 'b'
	sub x3,    2		; Prepare object pointer in 'x3' (points to X)
	xne a,     '\n'
	jms .nln		; New line (next line by tile height + cret)
	xne a,     '\r'
	jms .crt		; Carriage return
	xne a,     '\t'
	jms .tab		; Tab (jump to next multiple of t.w * 8 on X)
	xne a,     0x08
	jms .bks		; Backspace (one char. back until begin)
	xug a,     0x1F
	jms .exit		; Any other control char.: Do nothing
	mov xm3,   PTR16I	; Restore, function call will need it

	; Prepare for blitting character, and blit it

	mov c,     [x3]
	add c,     [x3]		; X + Y * width: Target pointer
	add x3,    7
	btc a,     15		; Mask out highest bit
	or  a,     [x3]		; Add color (with OR)
	jfa us_tile_blit_i {[x3], a, c}
	mov xm3,   PTR16

	; Add one tile to X location

	mov x3,    [$.opt]
	add x3,    3
	add b,     [x3]
.com:	mov [x3],  b		; Common end (new line check) with Tab
	add x3,    4
	xug [x3],  b
	jms .nlp		; X location got equal or larger than width
	jms .exit
.nlp:	sub x3,    4		; Prepare for new line

.nln:	; New line. Increment Y accordingly, then fall through to carriage
	; return.

	add x3,    3
	mov c,     [x3]
	sub x3,    2
	add [x3],  c
	sub x3,    1		; Prepare for carriage return

.crt:	; Carriage return

	mov c,     0
	mov [x3],  c
	jms .exit

.tab:	; Tab, jumps to next multiple of tilewidth * 8

	shl b,     3		; Tile width * 8
	mov c,     [x3]
	add c,     b
	div c,     b
	mul b,     c		; Rounded up to next multiple
	jms .com		; To common new line check part

.bks:	; Backspace, goes back one character (only if position permits)

	xug b,     [x3]
	sub [x3],  b

.exit:	; Restore CPU regs & return

	mov xm3,   PTR16I
	mov a,     [$3]
	mov b,     [$4]
	rfn c:x3,  0



;
; Implementation of us_cw_tile_setst
;
us_cw_tile_setst_i:
.opt	equ	0		; Object pointer
.atr	equ	1		; Attribute to change
.val	equ	2		; Value to set

	mov c,     [$.atr]
	xeq c,     'c'		; Color
	rfn c:x3,  0		; Only the color attribute exists
	xug sp,    2
	jms .def		; 2 parameters: Set default color
	mov x3,    [$.opt]
	add x3,    10
	mov c,     [$.val]
	shl c,     [x3]
	add x3,    1
	mov [x3],  c
	rfn c:x3,  0
.def:	mov x3,    [$.opt]
	add x3,    11
	mov c,     [x3]
	mov [x3],  c
	rfn c:x3,  0



;
; Implementation of us_cw_tile_init
;
us_cw_tile_init_i:
.opt	equ	0		; Object pointer

.tlw	equ	1		; Tile width
.tlh	equ	2		; Tile height
.dsw	equ	3		; Destination width

	mov sp,    4

	; Prepare calculated values

	; Get tileset dimensions

	mov x3,    [$.opt]
	add x3,    13
	jfa us_tile_gethw_i {[x3]}
	mov [$.tlh], c
	mov [$.tlw], x3

	; Get surface width

	mov x3,    [$.opt]
	add x3,    14
	jfa us_dsurf_getpw_i {[x3]}
	mov [$.dsw], x3

	; Set up calculated structure elements

	mov x3,    [$.opt]
	add x3,    5
	mov c,     [$.tlw]
	mov [x3],  c		; Width of tileset
	mov c,     [$.tlh]
	mul c,     [$.dsw]
	mov [x3],  c		; Height of tileset * surface_width
	mov c,     [$.dsw]
	div c,     [$.tlw]
	mul c,     [$.tlw]	; Trim to smaller tile boundary
	mov [x3],  c		; Effective width of surface

	; Set up accelerator for blitting

	mov x3,    [$.opt]
	add x3,    14
	jfa us_dsurf_getacc_i {[x3]}
	mov x3,    [$.opt]
	add x3,    13
	mov x3,    [x3]
	mov [$.opt], x3
	jma us_tile_acc_i	; Tail transfer



;
; Implementation of us_cw_tile_setxy
;
us_cw_tile_setxy_i:
.opt	equ	0		; Object pointer
.nwx	equ	1		; New character X position
.nwy	equ	2		; New character Y position

	mov x3,    [$.opt]
	add x3,    5
	mov c,     [$.nwx]
	mul c,     [x3]
	add x3,    1
	div c:c,   [x3]		; Take modulo effective surface width
	sub x3,    5
	mov [x3],  c		; New X calculated
	add x3,    2
	mov c,     [$.nwy]
	mul c,     [x3]
	sub x3,    3
	mov [x3],  c		; New Y calculated
	rfn c:x3,  0
