;
; RRPGE User Library functions - Fast scrolling tile map
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Accelerator driven, graphics display generator scrolled fast tile maps.
; These maps work by entirely occupying a destination, which is scrolled by
; manipulating display lists (shift mode source). The display lists need to be
; double buffered (uses us_dbuf_getlist). The destination surface has to be
; single buffered, and sufficiently large so the usual scrolls don't cause
; blit preparation related overflows.
;
; Uses fast scrolling tile map structures (objects) of the following layout:
;
; Word0: Used tile map's pointer
; Word1: Destination surface's pointer
; Word2: Display list used rows (1 - 400 or 200; visible height)
; Word3: Starting source line select value (15 bits)
; Word4: Current top-left tile X position
; Word5: Current top-left tile Y position
; Word6: Full update request flag & Render command flags
; Word7: Display list column to use (1 - 3, 7, 15, 31 or 63)
; Word8: Display list Y start offset (0 - 399 or 199)
; Word9: Source line select value range
;
; The source definitions to be used have to be set up manually in accordance
; with the destination surface (note: must be shift sources).
;
; Full update request & Render command flags:
;
; bit    15: Combine with mask if clear
; bit    14: Combine with colorkey if clear
; bit 10-13: Mask / Colorkey value (as in render command, bits 10-13)
; bit     9: If set, priority selector active (render command, bit 31)
; bit  3- 8: Unused
; bit     2: Expect Y scroll only if set
; bit     1: Expect X scroll only if set
; bit     0: Full update request if set
;



include "rrpge.asm"

section code



;
; Implementation of us_fastmap_set
;
us_fastmap_set_i:
.fmp	equ	0		; Fast map structure pointer
.tms	equ	1		; Tilemap structure pointer
.dss	equ	2		; Destination surface structure pointer
.dlc	equ	3		; Display list column to use
.dly	equ	4		; Display list start Y location
.dlr	equ	5		; Display list count of used rows
.sls	equ	6		; Starting source line select value
.slr	equ	7		; Source line select value range
.flg	equ	8		; Render command flags

	mov x3,    [$.fmp]
	mov c,     [$.tms]
	mov [x3],  c
	mov c,     [$.dss]
	mov [x3],  c
	mov c,     [$.dlr]
	mov [x3],  c
	mov c,     [$.sls]
	mov [x3],  c
	mov c,     0
	mov [x3],  c
	mov [x3],  c
	mov c,     [$.flg]
	bts c,     0		; Set full update request for first draw
	mov [x3],  c
	mov c,     [$.dlc]
	mov [x3],  c
	mov c,     [$.dly]
	mov [x3],  c
	mov c,     [$.slr]
	mov [x3],  c
	rfn



;
; Implementation of us_fastmap_mark
;
us_fastmap_mark_i:
.fmp	equ	0		; Fast map structure pointer

	mov x3,    [$.fmp]
	add x3,    6
	bts [x3],  0
	rfn



;
; Implementation of us_fastmap_gethw
;
us_fastmap_gethw_i:
.fmp	equ	0		; Fast map structure pointer

.dly	equ	1		; Display List used rows (Word2)
.sls	equ	2		; Starting source line select (Word3)
.tlh	equ	0		; Tile height
.tlw	equ	3		; Tile width (cells)
.tmp	equ	0		; Tile map pointer
.flg	equ	4		; Flags, for X and Y scroll expectations

	mov sp,    5

	; Load elements of the structure

	mov x3,    [$.fmp]
	mov c,     [x3]		; Tile map pointer
	mov [$.tmp], c
	add x3,    1
	mov c,     [x3]
	mov [$.dly], c		; Display list used rows (visible height)
	mov c,     [x3]
	mov [$.sls], c		; Starting source line select value
	add x3,    2
	mov c,     [x3]
	mov [$.flg], c		; Flags

	; Load tile dimensions

	jfa us_tmap_gettilehw_i {[$.tmp]}
	mov [$.tlh], c
	mov [$.tlw], x3

	; Extract display area width from the appropriate shift mode region
	; register. Rescale it to tile boundary.

	mov x3,    [$.sls]
	shl x3,    14
	and x3,    1		; Shift mode region select
	add x3,    P_GDG_SMRA
	mov x3,    [x3]		; Load appropriate shift mode region
	shr x3,    8		; Output width in cells
	xbs [$.flg], 2		; Only Y scrolling expected: No extra tile
	add x3,    [$.tlw]	; One tile wider to support scrolling
	add x3,    [$.tlw]	; Fractional sizes rounded up to next boundary
	sub x3,    1
	div x3,    [$.tlw]	; Output width in tiles

	; Get output height in tiles

	mov c,     [$.dly]
	xbs [$.flg], 1		; Only X scrolling expected: No extra tile
	add c,     [$.tlh]	; One tile taller to support scrolling
	add c,     [$.tlh]	; Fractional sizes rounded up to next boundary
	sub c,     1
	div c,     [$.tlh]	; Output height in tiles

	; All OK, Height:Width in C:X3

	rfn



;
; Implementation of us_fastmap_getyx
;
us_fastmap_getyx_i:
.fmp	equ	0		; Fast map structure pointer

	; Just load those from the structure

	mov x3,    [$.fmp]
	add x3,    4
	mov c,     [x3]		; Current tile X
	mov x3,    [x3]		; Current tile Y
	xch c,     x3
	rfn



;
; Implementation of us_fastmap_setdly
;
us_fastmap_setdly_i:
.fmp	equ	0		; Fast map structure pointer
.nws	equ	1		; New display list starting row
.nwr	equ	2		; New display list used rows

	mov sp,    4

	; Save CPU regs & load variables

	xch a,     [$.nws]
	xch b,     [$.nwr]
	mov [$3],  d

	; A full update may be necessary after this update. It is necessary if
	; the height grows to include an additional tile.

	mov x3,    [$.fmp]
	add x3,    2
	mov d,     [x3]
	xug b,     d
	jms .hle		; New height is less or equal: OK

	; Load tile height (into C)

	mov x3,    [$.fmp]
	jfa us_tmap_gettilehw_i {[x3]}

	; Calculate tile counts for old and new heights

	add d,     c
	sub d,     1
	div d,     c		; Old height in tiles (rounded up)
	mov x3,    b
	add x3,    c
	sub x3,    1
	div x3,    c		; New height in tiles (rounded up)
	xne d,     x3
	jms .hle		; Equal: OK

	; Set full update

	mov x3,    [$.fmp]
	add x3,    6
	bts [x3],  0		; Full update requested

.hle:	; Just add the two parameters to the structure

	mov x3,    [$.fmp]
	add x3,    2
	mov [x3],  b
	add x3,    5
	mov [x3],  a

	; Restore CPU regs & exit

	mov a,     [$.nws]
	mov b,     [$.nwr]
	mov d,     [$3]
	rfn



;
; Implementation of us_fastmap_draw
;
us_fastmap_draw_i:
.fmp	equ	0		; Fast map structure pointer
.psx	equ	1		; Desired new top-left X position
.psy	equ	2		; Desired new top-left Y position

.dld	equ	3		; Display List Definition to use
.dly	equ	4		; Display List used rows (Word2)
.sls	equ	5		; Starting source line select (Word3)
.cpx	equ	6		; Current tile X (Word4)
.cpy	equ	7		; Current tile Y (Word5)
.tlh	equ	8		; Tile height
.tlw	equ	9		; Tile width (cells)
.opw	equ	10		; Output width in tiles
.oph	equ	11		; Output height in tiles
.flg	equ	12		; Flags (Word6)
.sr0	equ	8		; Temp for side blit (parameter 0)
.sr1	equ	9		; Temp for side blit (parameter 1)
.wr1	equ	13		; Temp for wide blit (parameter 1)
.dcu	equ	8		; Display list column to use (Word7)
.dys	equ	9		; Display list Y start offset (Word8)
.slr	equ	13		; Source line select value range (Word9)
.swr	equ	12		; Source wrap point

;
; Some overall concepts
;
; The tile map is used with 0:0 origin. With this, any given tile will always
; blit to the same location of the destination.
;
; The top-left X:Y refers to the display area's top-left corner (so 0:0 will
; make the tile map aligned with the top-left corner).
;
; Visible destination dimensions are calculated using the appropriate shift
; mode region, and the display list used rows. Blitting only targets to fill
; this area proper. The visible destination area dimensions are rounded up to
; tile boundaries, in either dimension always 1 tile more is rendered to
; support fractional tile scrolling.
;
; A full update is performed if the full update request flag is set, or either
; X or Y scrolled a larger distance than visible. Width is only considered at
; cell granularity, when the tile map is on boundary, one extra tile is drawn.
;

	mov sp,    18

	; Save CPU regs

	mov [$14], a
	mov [$15], b
	mov [$16], x0
	mov [$17], x1

	; Load elements of the structure

	mov x3,    [$.fmp]
	mov x0,    [x3]		; Tile map pointer
	mov x1,    [x3]		; Destination surface pointer
	mov c,     [x3]
	xne c,     0
	jms .exit		; Zero height: Nothing to render
	mov [$.dly], c		; Display list used rows (visible height)
	mov c,     [x3]
	mov [$.sls], c		; Starting source line select value
	mov c,     [x3]
	mov [$.cpx], c		; Current tile X
	mov c,     [x3]
	mov [$.cpy], c		; Current tile Y
	mov c,     [x3]
	mov [$.flg], c		; Full update req. & Render command flags

	; No sanity checks here, the blit process will simply blit something
	; on the destination. The whole reason for sanity checks is just to
	; restrain developers from trying to be "creative" with the library,
	; or accidentally exploiting undefined behavior. So they prevent
	; filling the display list, making no visible output, which is OK for
	; this purpose.

	; Extract display area width from the appropriate shift mode region
	; register.

	mov x3,    [$.sls]
	shl x3,    14
	and x3,    1		; Shift mode region select
	add x3,    P_GDG_SMRA
	mov a,     [x3]		; Load appropriate shift mode region
	shr a,     8		; Output width in cells
	xne a,     0
	jms .exit		; Zero width: Nothing to render

	; Load tile dimensions

	jfa us_tmap_gettilehw_i {x0}
	mov [$.tlh], c
	mov [$.tlw], x3

	; Rescale output width to tile boundary.

	xbs [$.flg], 2		; Only Y scrolling expected: No extra tile
	add a,     [$.tlw]	; One tile wider to support scrolling
	add a,     [$.tlw]	; Fractional sizes rounded up to next boundary
	sub a,     1
	div a,     [$.tlw]	; Output width in tiles
	mov [$.opw], a

	; Get output height in tiles

	mov b,     [$.dly]
	xbs [$.flg], 1		; Only X scrolling expected: No extra tile
	add b,     [$.tlh]	; One tile taller to support scrolling
	add b,     [$.tlh]	; Fractional sizes rounded up to next boundary
	sub b,     1
	div b,     [$.tlh]
	mov [$.oph], b

	; Initialize for blitting

	jfa us_tmap_getacc_i {x0, x1}

	; Load display list

	jfa us_dbuf_getlist_i {}
	mov [$.dld], x3		; Save display list definition

	; Truncate X:Y positions to whole tile positions. X is also scaled
	; down to cells, as 4 / 8 pixels per cell depending on mode. The
	; positions code the new top left corner, and using the previous
	; positions, they are used to determine what to blit.

	mov c,     [$.tlw]
	shl c,     2
	xbs [$.dld], 12		; If set, 8 bit mode
	shl c,     1		; In 4 bit mode, 8 pixels per cell
	mov a,     [$.psx]
	div a,     c		; A: Xnew
	mov b,     [$.psy]
	div b,     [$.tlh]	; B: Ynew

	; Save new X:Y positions

	mov x3,    [$.fmp]
	add x3,    4
	mov [x3],  a
	mov [x3],  b

	; Check full update flag, skip if so

	xbc [x3],  0
	jms .flu

	; Prepare to blit. There are four (+ full update) possibilities
	; depending on where the new tiles need to be output: up+left,
	; bottom+left, bottom+right, up+right. Zero scroll is not considered
	; here, it will just end up in one of these groups.
	;
	; The followings have to be prepared:
	;
	; Xnew:         New tile X coordinate, comes in X0
	; Ynew:         New tile Y coordinate, comes in Y0
	; Xold + XDisp: Old tile X ($.cpx) + Displayed width ($.opw)
	; Yold:         Old tile Y, comes in $.cpy
	; Yold + YDisp: Old tile Y ($.cpy) + Displayed height ($.oph)
	; XDisp:        Displayed width, comes in $.opw
	; YDisp - YChg: Displayed height ($.oph) - Y scroll amount
	; XChg:         X scroll amount
	; YChg:         Y scroll amount

	mov x3,    [$.cpx]
	add x3,    [$.opw]
	mov [$.sr0], x3		; Side region, parameter 0 prepare: Xold + XDisp
	mov x3,    [$.cpy]
	add x3,    [$.oph]
	mov [$.wr1], x3		; Wide region, parameter 1 prepare: Yold + YDisp
	mov x0,    a		; Xnew in A => X0
	mov x1,    b		; Ynew in B => X1

	sub x0,    [$.cpx]	; Preparing XChg in X0
	sub x1,    [$.cpy]	; Preparing YChg in X1
	xbc x0,    15
	jms .xl0		; X0(X) less than $.cpx
	xbc x1,    15
	jms .yl0		; X1(Y) less than $.cpy

	; X >= $.cpx and Y >= $.cpy, scroll in at right and bottom
	; Regions:
	;
	; +-----+                 Xstart      Ystart      Width  Height
	; |     |
	; | Old +--+ Wide region  Xnew        Yold+YDisp  XDisp  YChg
	; |     |  |
	; +--+--+--+ Side region  Xold+XDisp  Ynew        XChg   YDisp-YChg
	;    |     |
	;    +-----+

	mov [$.sr1], b		; Side region, parameter 1 is Ynew
	jms .xyc

.yl0:	; X >= $.cpx and Y < $.cpy, scroll in at right and top
	; Regions:
	;
	;    +-----+              Xstart      Ystart      Width  Height
	;    |     |
	; +--+--+--+ Wide region  Xnew        Ynew        XDisp  YChg
	; |     |  |
	; | Old +--+ Side region  Xold+XDisp  Yold        XChg   YDisp-YChg
	; |     |
	; +-----+

	neg x1,    x1		; YChg in X1
	mov [$.wr1], b		; Wide region, parameter 1 is Ynew
	mov c,     [$.cpy]
	mov [$.sr1], c		; Side region, parameter 1 is Yold
	jms .xyc

.xl0:	xbc x1,    15
	jms .yl1		; X1(Y) less than $.cpy

	; X < $.cpx and Y >= $.cpy, scroll in at left and bottom
	; Regions:
	;
	;    +-----+              Xstart      Ystart      Width  Height
	;    |     |
	; +--+ Old | Wide region  Xnew        Yold+YDisp  XDisp  YChg
	; |  |     |
	; +--+--+--+ Side region  Xnew        Ynew        XChg   YDisp-YChg
	; |     |
	; +-----+

	neg x0,    x0		; XChg in X0
	mov [$.sr0], a		; Side region, parameter 0 is Xnew
	mov [$.sr1], b		; Side region, parameter 1 is Ynew
	jms .xyc

.yl1:	; X < $.cpx and Y < $.cpy, scroll in at left and top
	; Regions:
	;
	; +-----+                 Xstart      Ystart      Width  Height
	; |     |
	; +--+--+--+ Wide region  Xnew        Ynew        XDisp  YChg
	; |  |     |
	; +--+ Old | Side region  Xnew        Yold        XChg   YDisp-YChg
	;    |     |
	;    +-----+

	neg x0,    x0		; XChg in X0
	neg x1,    x1		; YChg in X1
	mov [$.wr1], b		; Wide region, parameter 1 is Ynew
	mov [$.sr0], a		; Side region, parameter 0 is Xnew
	mov c,     [$.cpy]
	mov [$.sr1], c		; Side region, parameter 1 is Yold

.xyc:	; Side specifics done, common preparation can go on

	xug [$.opw], x0
	jms .flu		; X change > visible width: full update
	xug [$.oph], x1
	jms .flu		; Y change > visible height: full update

	mov x3,    [$.oph]
	sub x3,    x1		; YDisp - YChg prepared

	; Do the two blits, every parameter ready. First the side region,
	; since it needs a parameter from X3 which is clobbered in the
	; function. The blit function can deal with zero width or height, so
	; don't care.

	jfa us_tmap_blit_i {[$.sr0], [$.sr1], x0,      x3}
	jfa us_tmap_blit_i {a,       [$.wr1], [$.opw], x1}
	jms .ben

.flu:	; Full update. Use the new X:Y positions with the display width and
	; height in $.opw and $.oph to update the entire displayed area.

	jfa us_tmap_blit_i {a, b, [$.opw], [$.oph]}

.ben:	; Clear full update flag

	mov x3,    [$.fmp]
	add x3,    6
	btc [x3],  0

	; Display list fill, always needed. Fills the specified area (column,
	; Y range) according to the current position. First load stuff from
	; the fast tile mapper structure

	sub x3,    1
	mov x0,    [x3]		; Load render command flags
	mov c,     [x3]
	mov [$.dcu], c		; Display list column to use
	mov c,     [x3]
	mov [$.dys], c		; Display list Y start
	mov c,     [x3]
	mov [$.slr], c		; Source line select value range

	; Some sanity checks to achieve defined behavior in most cases (bad
	; parameters => nothing drawn due to skipping display list fill).

	mov c,     0		; Some zero checks
	xne c,     [$.dcu]
	jms .exit		; Invalid column select
	xne c,     [$.slr]
	jms .exit		; No source line select range
	mov x3,    [$.dld]
	and x3,    3		; Display list size (0 - 3)
	xbc [$.dld], 13
	add x3,    1		; Double scanned mode (1 - 4)
	mov c,     4
	shl c,     x3		; 4, 8, 16, 32, 64 maximum column count
	xug c,     [$.dcu]
	jms .exit		; Invalid column select
	mov x3,    400
	xbc [$.dld], 13
	shr x3,    1		; Double scanned mode (max height is 200 lines)
	xug x3,    [$.dys]
	jms .exit		; Too big Y start
	mov c,     [$.dys]
	add c,     [$.dly]
	add x3,    1
	xug x3,    c
	jms .exit		; Y start + Used rows exceed max height
	xbc [$.sls], 15
	jms .exit		; Invalid source line select value start
	xbc [$.slr], 15
	jms .exit		; Too large source line select range
	mov c,     [$.sls]
	add c,     [$.slr]
	sub c,     1
	xbc c,     15
	jms .exit		; Source line select wraps improperly

	; Prepare X, which will produce bits 0-9 of the render command.

	mov x3,    [$.psx]
	xbc [$.dld], 12		; If set, 8 bit mode
	shl x3,    1
	and x3,    0x03FF

	; Combine low word of render command into X0, keeping priority
	; selector in register A

	mov a,     0
	xbc x0,    9
	bts a,     15		; High bit of A is set when pri. select active
	and x0,    0xFC00
	or  x0,    x3

	; Prepare Y, selecting the appropriate source line select value.

	mov x1,    [$.psy]
	div c:x1,  [$.slr]
	mov x1,    c
	add x1,    [$.sls]
	or  x1,    a		; Priority selector

	; Set up wrapping point for source line select

	mov c,     [$.sls]
	add c,     [$.slr]
	mov [$.swr], c
	or  [$.swr], a		; Priority selector

	; Set up for display list walking (PRAM pointer 2 for high word,
	; pointer 3 for low word)

	jfa us_dlist_setptr_i {[$.dcu], [$.dys], [$.dld]}

	; Build the display list

	not c,     0x0003	; Loads 0xFFFC (to discard low 2 bits of height)
	mov a,     0x0003	; Loads 0x0003 (to retrieve low 2 bits of height)
	and c,     [$.dly]
	and a,     [$.dly]
	mov x3,    30		; Offset of .lt0 relative to jmr
	mov b,     a
	shl a,     3
	sub a,     b		; 7 words / block
	sub x3,    a
	jmr x3
.llp:	sub c,     4
	mov [P2_RW], x1
	mov [P3_RW], x0
	add x1,    1
	xne x1,    [$.swr]
	sub x1,    [$.slr]
.lt3:	mov [P2_RW], x1
	mov [P3_RW], x0
	add x1,    1
	xne x1,    [$.swr]
	sub x1,    [$.slr]
.lt2:	mov [P2_RW], x1
	mov [P3_RW], x0
	add x1,    1
	xne x1,    [$.swr]
	sub x1,    [$.slr]
.lt1:	mov [P2_RW], x1
	mov [P3_RW], x0
	add x1,    1
	xne x1,    [$.swr]
	sub x1,    [$.slr]
.lt0:	xeq c,     0
	jms .llp

	; Restore CPU regs & exit

.exit:	mov a,     [$14]
	mov b,     [$15]
	mov x0,    [$16]
	mov x1,    [$17]
	rfn