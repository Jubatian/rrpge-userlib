;
; RRPGE User Library functions - Font tileset
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Tileset for 1 bit font blitting.
;
; Uses the following CPU RAM locations:
;
; 0xFD92: Tile index multiplier
; 0xFD93: Memorized blit configuration (by us_tile_getacc)
; 0xFD94: Memorized tile start offset (by us_tile_getacc)
;
; Uses tileset structures (objects) of the following layout:
;
; Word0: <Tileset interface>
; Word1: <Tileset interface>
; Word2: <Tileset interface>
; Word3: Width (cells) of tiles
; Word4: Height of tiles
; Word5: Bank of source
; Word6: Start offset of source (tile index 0)
; Word7: Blit configuration
;
; The blit configuration:
;
; bit 13-15: Unused
; bit    12: High bit of Reindex bank select
; bit  9-11: Unused
; bit     8: If set, colorkey is 0x1, otherwise 0x0
; bit     7: Unused
; bit     6: Reindex by destination if set (if bit 5 is also set)
; bit     5: Tile index layout (0: OR mask + 12 bit; 1: Reindexing + 12 bit)
; bit     4: Unused
; bit     3: Colorkey enabled if set
; bit  0- 2: Unused
;

include "rrpge.asm"

section code



; 0xFD92: Tile index multiplier
us_ftile_imul	equ	0xFD92
; 0xFD93: Memorized blit configuration
us_ftile_mcfg	equ	0xFD93
; 0xFD94: Memorized tile start offset
us_ftile_moff	equ	0xFD94



;
; Implementation of us_ftile_new
;
us_ftile_new_i:
.tgp	equ	0		; Target pointer
.wdt	equ	1		; Width of tiles in cells
.hgt	equ	2		; Height of tiles
.bnk	equ	3		; Bank of tile source
.off	equ	4		; Offset (tile index 0) of tile source
.cfg	equ	5		; Blit configuration

	jfa us_tile_new_i {[$.tgp], us_ftile_blit, us_ftile_gethw, us_ftile_acc}

	mov c,     [$.wdt]
	mov [x3],  c		; Width of tiles
	mov c,     [$.hgt]
	mov [x3],  c		; Height of tiles
	mov c,     [$.bnk]
	mov [x3],  c		; Bank select
	mov c,     [$.off]
	mov [x3],  c		; Offset (tile index 0)
	mov c,     [$.cfg]
	mov [x3],  c		; Blit configuration
	rfn c:x3,  0



;
; Implementation of us_ftile_acc
;
us_ftile_acc_i:
.srp	equ	0		; Source pointer

	mov x3,    [$.srp]
	add x3,    3
	mov c,     0x000A
	mov [P_GFIFO_ADDR], c
	mov c,     [x3]
	mov [$0],  c		; Save width for later uses
	mov [P_GFIFO_DATA], c	; 0x000A: Pointer X post-add whole
	mov c,     0x0017
	mov [P_GFIFO_ADDR], c
	mov c,     [x3]
	mov [P_GFIFO_DATA], c	; 0x0017: Count of rows to blit
	mul c,     [$0]		; Tile index multiplier
	mov [us_ftile_imul], c
	mov c,     [$0]
	mov [P_GFIFO_DATA], c	; 0x0018: Count of cells to blit, whole
	mov c,     0
	mov [P_GFIFO_DATA], c	; 0x0019: Count of cells to blit, fraction

	mov c,     0x0012
	mov [P_GFIFO_ADDR], c
	mov c,     [x3]
	mov [P_GFIFO_DATA], c	; 0x0012: Source bank select
	mov c,     0		; No partitioning on source
	mov [P_GFIFO_DATA], c	; 0x0013: Source partition select
	mov c,     0xFF00
	mov [P_GFIFO_DATA], c	; 0x0014: Source partitioning settings
	mov c,     [x3]
	mov [us_ftile_moff], c
	mov c,     [x3]
	mov [us_ftile_mcfg], c	; Blit configuration

	mov x3,    0x8000
	mov [P_GFIFO_ADDR], x3	; Skip Blit control flags
	shr c,     8		; Colorkey value moved down to bit 0
	and c,     1
	bts c,     8		; Pixel AND mask is always 1
	mov [P_GFIFO_DATA], c	; 0x0016: AND mask and Colorkey

	rfn c:x3,  0



;
; Implementation of us_ftile_blit
;
us_ftile_blit_i:
.srp	equ	0		; Source pointer (not used)
.idx	equ	1		; Tile index
.ofh	equ	2		; Destination offset, high
.ofl	equ	3		; Destination offset, low

	; Add blit control flags with source barrel rotate from the low bits
	; of tile index, also generating tile offset

	mov c,     0x0015
	mov [P_GFIFO_ADDR], c
	mov x3,    0x3
	and x3,    [$.idx]
	xbc [us_ftile_mcfg], 3	; VCK set?
	bts x3,    3
	mov [P_GFIFO_DATA], x3	; 0x0015: Blit configuration
	mov x3,    0xFFF	; 4096 chars
	and x3,    [$.idx]
	shr x3,    2
	mul x3,    [us_ftile_imul]
	add x3,    [us_ftile_moff]
	mov c,     0x001A
	mov [P_GFIFO_ADDR], c
	mov [P_GFIFO_DATA], x3	; 0x001A: Source X whole

	; Add destination location

	mov c,     0x001C
	mov [P_GFIFO_ADDR], c
	mov c,     [$.ofh]
	mov [P_GFIFO_DATA], c	; 0x001C: Destination whole
	mov c,     0
	xul sp,    4		; Fraction is zero unless parameter is provided
	mov c,     [$.ofl]
	mov [P_GFIFO_DATA], c	; 0x001D: Destination fraction

	; Either reindexing or pixel OR mask

	mov x3,    [$.idx]
	shr x3,    12		; The low 4 bits of the OR mask / Reindex
	mov c,     [us_ftile_mcfg]
	xbs c,     5
	jms .roe		; To OR mask
	xbs c,     6
	jms .rin		; To normal reindexing

	; Reindex by destination & OR mask

	or  x3,     0x6000	; VDR, VRE set: Reindex by destination
	jms .roe

.rin:	; Normal reindexing

	shl x3,     8		; Shift up to reindex bank select
	xeq x3,     0		; Only reindex if not zero
	bts x3,     13		; VRE (Reindexing) set
	xbc c,      12
	bts x3,     12		; High bit of reindex bank select
.roe:	mov [P_GFIFO_DATA], x3	; 0x001E: Reindexing & Pixel OR mask

	; Done, blit it

	mov [P_GFIFO_DATA], c	; 0x001F: Start trigger

	rfn c:x3,  0



;
; Implementation of us_ftile_getwh
;
us_ftile_gethw_i:
.srp	equ	0		; Source pointer

	mov x3,    [$.srp]
	add x3,    3
	mov c,     [x3]		; Width
	mov x3,    [x3]		; Height
	xch x3,    c
	rfn



;
; Implementation of us_ftile_setch
;
us_ftile_setch_i:
.srp	equ	0		; Source pointer
.col	equ	1		; New reindex high bit to set

	mov x3,    [$.srp]
	add x3,    7
	btc [x3],  12
	sub x3,    1
	xbc [$.col], 0
	bts [x3],  12
	rfn c:x3,  0
