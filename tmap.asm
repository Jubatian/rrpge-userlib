;
; RRPGE User Library functions - Tile maps
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Accelerator tilemap core. It should be placed near the tileset interface to
; allow some tail call short jumps to it.
;
; Uses the following CPU RAM locations:
;
; 0xFD95: Destination width (cells)
; 0xFD96: Destination height
; 0xFD97: Tile width (cells)
; 0xFD98: Tile height
; 0xFD99: X origin fraction
; 0xFD9A: X origin
; 0xFD9B: Y origin
;
; Uses tile map structures (objects) of the following layout:
;
; Word0: Used tileset's pointer
; Word1: Width of tile map in tiles
; Word2: Height of tile map in tiles
; Word3: Word offset of tile map start in PRAM, high
; Word4: Word offset of tile map start in PRAM, low
;

include "rrpge.asm"

section code



; 0xFD95: Destination width (cells)
us_tmap_dw	equ	0xFD95
; 0xFD96: Destination height
us_tmap_dh	equ	0xFD96
; 0xFD97: Tile width (cells)
us_tmap_tw	equ	0xFD97
; 0xFD98: Tile height
us_tmap_th	equ	0xFD98
; 0xFD99: X origin fraction
us_tmap_xf	equ	0xFD99
; 0xFD9A: X origin
us_tmap_x	equ	0xFD9A
; 0xFD9B: Y origin
us_tmap_y	equ	0xFD9B




;
; Implementation of us_tmap_new
;
us_tmap_new_i:
.tgp	equ	0		; Target pointer
.tst	equ	1		; Tileset to use
.wdt	equ	2		; Width
.hgt	equ	3		; Height
.ofh	equ	4		; Word offset in PRAM, high
.ofl	equ	5		; Word offset in PRAM, low

	mov x3,    [$.tgp]
	mov c,     [$.tst]
	mov [x3],  c
	mov c,     [$.wdt]
	mov [x3],  c
	mov c,     [$.hgt]
	mov [x3],  c
	mov c,     [$.ofh]
	mov [x3],  c
	mov c,     [$.ofl]
	mov [x3],  c
	rfn c:x3,  0



;
; Implementation of us_tmap_acc
;
us_tmap_acc_i:
.srp	equ	0		; Source tilemap pointer
.dsp	equ	1		; Destination surface pointer

	mov c,     0
	mov [us_tmap_xf], c
	mov [us_tmap_x], c
.entr:	mov [us_tmap_y], c

	jfa us_dsurf_getacc_i {[$.dsp]}
	jfa us_dsurf_getpw_i  {[$.dsp]}
	mov [us_tmap_dw], x3	; Width of destination
	mov x3,    1
	shl x3,    c		; Total cell count of destination / 2
	div x3,    [us_tmap_dw]
	shl x3,    1
	mov [us_tmap_dh], x3	; Height of destination (rounded down to even)

	mov x3,    [$.srp]
	jfa us_tile_gethw_i {[x3]}
	mov [us_tmap_tw], x3	; Width retrieved in x3
	mov [us_tmap_th], c	; Height retrieved in c
	mov x3,    [$.srp]
	mov x3,    [x3]
	mov [$0],  x3		; Just move tilemap pointer in param0 ...
	jms us_tile_acc_i	; ... and tail-transfer.



;
; Implementation of us_tmap_accxy
;
us_tmap_accxy_i:
.srp	equ	0		; Source tilemap pointer
.dsp	equ	1		; Destination surface pointer
.oxw	equ	2		; X origin (whole)
.oyw	equ	3		; Y origin (whole)

	mov c,     0
	mov [us_tmap_xf], c
	mov c,     [$.oyw]
.entr:	mov x3,    [$.oxw]
	mov [us_tmap_x], x3
	jms us_tmap_acc_i.entr



;
; Implementation of us_tmap_getaccxfy
;
us_tmap_accxfy_i:
.srp	equ	0		; Source tilemap pointer
.dsp	equ	1		; Destination surface pointer
.oxw	equ	2		; X origin (whole)
.oxf	equ	3		; X origin (fraction)
.oyw	equ	4		; Y origin (whole)

	mov c,     [$.oxf]
	mov [us_tmap_xf], c
	mov c,     [$.oyw]
	jms us_tmap_accxy_i.entr



;
; Implementation of us_tmap_blit
;
us_tmap_blit_i:
.srp	equ	0		; Source tilemap pointer
.tlx	equ	1		; Tile X start position
.tly	equ	2		; Tile Y start position
.wdt	equ	3		; Width of area in tiles
.hgt	equ	4		; Height of area in tiles

.xpb	equ	5		; X position base on destination
.yps	equ	6		; Y position on destination
.trx	equ	7		; X loop termination point
.try	equ	8		; Y loop termination point
.yml	equ	0		; Pre-multiplied Y position (reuses .srp)
.tdw	equ	9		; us_tmap_dw
.tdh	equ	10		; us_tmap_dh
.tpt	equ	11		; Tileset pointer (Word0 of tilemap)
.tmw	equ	12		; Tile map width (Word1 of tilemap)
.tmh	equ	13		; Tile map height (Word2 of tilemap)
.toh	equ	14		; Tile map offset high (Word3 of tilemap)
.tol	equ	15		; Tile map offset low (Word4 of tilemap)

;
; Region blit with wrapping.
;
; Target position calculations:
;
; XPos = (TWidth  * TXPos + XOrigin) % DWidth
; YPos = (THeight * TYPos + YOrigin) % DHeight
;
; The X position is calculated at cell granularity, the X fraction is only
; applied for calling the blit (essentially a simple pixel shift). During the
; blit both are output using a DDA like approach, with the assumption that
; DWidth and DHeight are larger or equal than the respective TWidth and
; Theight parameters.
;
; Tile map position calculations:
;
; TMapX = TXPos % TMapWidth
; TMapY = TYPos % TMapHeight
;
; The same way like above, divison is not used within the area blit loops.
;

	mov sp,    16

	; Save CPU registers

	xch [$3],  a		; Also load width parameter
	xch [$4],  b		; Also load height parameter
	psh x0, x1, x2

	; If either widht or height is zero, no output

	xne a,     0
	jms .exit
	xne b,     0
	jms .exit

	; Load the source tilemap into stack for easier access

	mov x3,    [$.srp]
	mov c,     [x3]
	mov [$.tpt], c
	mov c,     [x3]
	mov [$.tmw], c
	mov c,     [x3]
	mov [$.tmh], c
	mov c,     [x3]
	mov [$.toh], c
	mov c,     [x3]
	mov [$.tol], c

	; Load us_tmap_dw and us_tmap_dh in stack to save bytes further on.

	mov c,     [us_tmap_dw]
	mov [$.tdw], c
	mov c,     [us_tmap_dh]
	mov [$.tdh], c

	; Calculate target upper-left corner offsets. x2:[$.yps] will be
	; XPos:YPos within the X loop.

	mov c,     [$.tlx]
	mul c,     [us_tmap_tw]
	add c,     [us_tmap_x]
	div c:c,   [$.tdw]
	mov [$.xpb], c		; X position base (x2 is loaded from this)
	mov c,     [$.tly]
	mul c,     [us_tmap_th]
	add c,     [us_tmap_y]
	div c:c,   [$.tdh]
	mov [$.yps], c

	; If width is one, do a special faster column blit

	xne a,     1
	jms .col

	; Calculate loop terminators. The .wdt (a) and .hgt (b) parameters are
	; saturated so with the tile dimensions they don't exceed the
	; destination dimensions. Terminators go into [$.trx]:[$.try].

	mul a,     [us_tmap_tw]
	xug [$.tdw], a
	mov a,     [$.tdw]
	add a,     [$.xpb]
	xug [$.tdw], a
	sub a,     [$.tdw]
	mov [$.trx], a
	mul b,     [us_tmap_th]
	xug [$.tdh], b
	mov b,     [$.tdh]
	add b,     [$.yps]
	xug [$.tdh], b
	sub b,     [$.tdh]
	mov [$.try], b

	; Sanitize [$.tlx]:[$.tly] to be within the tile map. The extra range
	; is already used for setting up the destination positions, not needed
	; any more.

	mov c,     [$.tlx]
	div c:c,   [$.tmw]
	mov [$.tlx], c
	mov c,     [$.tly]
	div c:c,   [$.tmh]
	mov [$.tly], c

	; Initialize Pointer 3 for tile map walking

	mov c,     0
	mov [P3_IH], c
	bts c,     4
	mov [P3_IL], c		; 16 bit walk
	mov c,     4
	mov [P3_DS], c		; 16 bit data unit size

	; Calculate tile map width as PRAM address in x1:x0. This is used for
	; wrapping the tile map on X.

	mov x0,    [$.tmw]
	shl c:x0,  4
	mov x1,    c

.yl:	; Row (Y) loop

	; Calculate start offset for Pointer 3.

	mov a,     [$.tly]
	mul c:a,   [$.tmw]
	mov b,     c
	add c:a,   [$.tol]
	adc b,     [$.toh]
	mov x2,    a		; Transfer to x3:x2, so b:a is saved for
	mov x3,    b		; termination offset calculation
	add c:x2,  [$.tlx]
	add x3,    c
	shl c:x2,  4
	slc x3,    4
	mov [P3_AH], x3
	mov [P3_AL], x2

	; Calculate termination offset in b:a for wrapping

	shl c:a,   4
	slc b,     4
	add c:a,   x0
	adc b,     x1

	; Load XPos to start at

	mov x2,    [$.xpb]

	; Pre-multiply YPos for offset calculation

	mov c,     [$.yps]
	mul c,     [$.tdw]
	mov [$.yml], c

.xl:	; Column (X) loop

	mov x3,    [$.yml]
	add x3,    x2		; Offset on destination
	jfa us_tile_blit_i {[$.tpt], [P3_RW], x3, [us_tmap_xf]}

	xeq [P3_AL], a
	jms .xl0
	xeq [P3_AH], b
	jms .xl0
	sub c:[P3_AL], x0
	sbc [P3_AH], x1		; Tile map position X wrap

.xl0:	add x2,    [us_tmap_tw]
	xug [$.tdw], x2
	sub x2,    [$.tdw]	; X position updated OK

	xeq x2,    [$.trx]
	jms .xl

	; Perform Y increment and wrap calculations

	mov c,     [$.tly]
	add c,     1
	xug [$.tmh], c
	sub c,     [$.tmh]
	mov [$.tly], c		; Tile map Y updated OK

	mov c,     [$.yps]
	add c,     [us_tmap_th]
	xug [$.tdh], c
	sub c,     [$.tdh]
	mov [$.yps], c		; Y position updated OK

	xeq c,     [$.try]
	jms .yl

	; Restore CPU regs. & exit

.exit:	mov a,     [$3]
	mov b,     [$4]
	pop x0, x1, x2
	rfn c:x3,  0

.col:	; Column blit (width is set 1)

	; Calculate loop terminators. The .hgt (b) parameter is saturated so
	; with the tile dimensions it doesn't exceed the destination
	; dimensions. Terminator goes into [$.try].

	mul b,     [us_tmap_th]
	xug [$.tdh], b
	mov b,     [$.tdh]
	add b,     [$.yps]
	xug [$.tdh], b
	sub b,     [$.tdh]
	mov [$.try], b

	; Sanitize [$.tlx]:[$.tly] to be within the tile map. The extra range
	; is already used for setting up the destination positions, not needed
	; any more.

	mov c,     [$.tlx]
	div c:c,   [$.tmw]
	mov [$.tlx], c
	mov c,     [$.tly]
	div c:c,   [$.tmh]
	mov [$.tly], c

	; Initialize Pointer 3 for tile map walking. Normal increment is the
	; tile map width.

	mov a,     [$.tmw]
	shl c:a,   4
	mov [P3_IH], c
	mov [P3_IL], a		; Tile map width
	mov c,     4
	mov [P3_DS], c		; 16 bit data unit size

	; Calculate initial Pointer 3 offset

	mov x2,    [$.tly]
	mul c:x2,  [$.tmw]
	mov x3,    c
	add c:x2,  [$.tol]
	adc x3,    [$.toh]
	add c:x2,  [$.tlx]
	add x3,    c
	shl c:x2,  4
	slc x3,    4
	mov [P3_AH], x3
	mov [P3_AL], x2

	; Calculate offset reduction in b:a, to be used for wrapping the
	; tile map on Y. The reduction is the size of the tile map.

	mov a,     [$.tmw]
	mul c:a,   [$.tmh]
	mov b,     c
	shl c:a,   4
	slc b,     4

.cyl:	; Row (Y) loop

	; Tile output

	mov x3,    [$.yps]
	mul x3,    [$.tdw]
	add x3,    [$.xpb]	; Offset on destination
	jfa us_tile_blit_i {[$.tpt], [P3_RW], x3, [us_tmap_xf]}

	; Perform Y increment and wrap calculations

	mov c,     [$.tly]
	add c,     1
	xug [$.tmh], c
	jms .tyw
	mov [$.tly], c		; Tile map Y updated OK

.tywe:	mov c,     [$.yps]
	add c,     [us_tmap_th]
	xug [$.tdh], c
	sub c,     [$.tdh]
	mov [$.yps], c		; Y position updated OK

	xeq c,     [$.try]
	jms .cyl

	jms .exit

.tyw:	; Tilemap Y wraparound

	sub c,     [$.tmh]
	mov [$.tly], c
	sub c:[P3_AL], a
	sbc [P3_AH], b
	jms .tywe



;
; Implementation of us_tmap_gethw
;
us_tmap_gethw_i:
.tlp	equ	0		; Tilemap pointer

	mov x3,    [$.tlp]
	add x3,    1
	mov c,     [x3]
	mov x3,    [x3]
	xch x3,    c
	rfn



;
; Implementation of us_tmap_gettilehw
;
us_tmap_gettilehw_i:
.tlp	equ	0		; Tilemap pointer

	mov x3,    [$.tlp]
	mov x3,    [x3]
	mov [$0],  x3		; Just load the tileset pointer ...
	jms us_tile_gethw_i	; ... and do a fast tail transfer "call"



;
; Implementation of us_tmap_gettile
;
us_tmap_gettile_i:
.tlp	equ	0		; Tilemap pointer
.tlx	equ	1		; X position
.tly	equ	2		; Y position

	mov x3,    [$.tlp]
	add x3,    1

	mov [$0],  a		; Save CPU register

	mov c,     [$.tlx]
	mov a,     [x3]
	div c:c,   a
	mov [$.tlx], c		; Truncate X position to tilemap
	mov c,     [$.tly]
	div c:c,   [x3]		; Truncate Y position to tilemap

	mov [$2],  b		; Save CPU register

	mul c:a,   c		; Multiplies Width of tile map with Y pos.
	mov b,     c
	add c:a,   [$.tlx]	; b:a is now start offset (carry needed)

	adc b,     [x3]		; Tile map start word offset in PRAM, high
	add c:a,   [x3]
	add b,     c		; b:a is PRAM word offset of tile

	shl c:a,   4
	slc b,     4
	mov [P3_AH], b
	mov [P3_AL], a
	mov c,     2
	mov [P3_DS], c

	mov a,     [$0]		; Restore CPU register
	mov b,     [$2]		; Restore CPU register
	rfn c:x3,  [P3_RW_NI]	; Read tile data



;
; Implementation of us_tmap_settile
;
us_tmap_settile_i:
.tlp	equ	0		; Tilemap pointer
.tlx	equ	1		; X position
.tly	equ	2		; Y position
.idx	equ	3		; Tile index to set

	mov x3,    [$.tlp]
	add x3,    1

	mov [$0],  a		; Save CPU register

	mov c,     [$.tlx]
	mov a,     [x3]
	div c:c,   a
	mov [$.tlx], c		; Truncate X position to tilemap
	mov c,     [$.tly]
	div c:c,   [x3]		; Truncate Y position to tilemap

	mov [$2],  b		; Save CPU register

	mul c:a,   c		; Multiplies Width of tile map with Y pos.
	mov b,     c
	add c:a,   [$.tlx]	; b:a is now start offset (carry needed)

	adc b,     [x3]		; Tile map start word offset in PRAM, high
	add c:a,   [x3]
	add b,     c		; b:a is PRAM word offset of tile

	shl c:a,   4
	slc b,     4
	mov [P3_AH], b
	mov [P3_AL], a
	mov c,     2
	mov [P3_DS], c

	mov x3,    [$.idx]
	mov [P3_RW_NI], x3	; Set tile data
	mov a,     [$0]		; Restore CPU register
	mov b,     [$2]		; Restore CPU register
	rfn c:x3,  0



;
; Implementation of us_tmap_setptr
;
us_tmap_setptr_i:
.tlp	equ	0		; Tilemap pointer
.ptr	equ	1		; Pointer to use

	; Save CPU registers

	psh a, x2, xm

	; Set up pointer

	mov x3,    [$.tlp]
	add x3,    3
	mov a,     [x3]
	mov x3,    [x3]
	shl c:x3,  4
	slc a,     4
	mov c,     a

	mov xm2,   PTR16I
	mov x2,    [$.ptr]
	and x2,    3
	shl x2,    3
	add x2,    P0_AH

	mov [x2],  c		; Px_AH
	mov [x2],  x3		; Px_AL
	mov a,     0
	mov [x2],  a		; Px_IH
	bts a,     4
	mov [x2],  a		; Px_IL (1 word increment)
	mov a,     4
	mov [x2],  a		; Px_DS (16 bit mode)

	; Return is also OK in C:X3. Restore CPU regs. & exit

	pop a, x2, xm
	rfn
