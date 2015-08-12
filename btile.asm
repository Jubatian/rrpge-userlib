;
; RRPGE User Library functions - Basic tileset
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Basic accelerator tileset.
;
; Uses the following CPU RAM locations:
;
; 0xFDBC: Tile index multiplier
; 0xFDBD: Memorized tile index layout (by us_tile_getacc, low 3 bits)
; 0xFDBE: Memorized tile start offset (by us_tile_getacc)
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
; bit 12-15: Colorkey
; bit  8-11: Pixel AND mask
; bit  5- 7: Tile index layout (see specification)
; bit     4: Unused
; bit     3: Colorkey enabled if set
; bit  0- 2: Pixel barrel rotate right
;

include "rrpge.asm"
include "iftile.asm"

section code



; 0xFDBC: Tile index multiplier
us_tile_imul	equ	0xFDBC
; 0xFDBD: Memorized tile index layout
us_tile_mtil	equ	0xFDBD
; 0xFDBE: Memorized tile start offset
us_tile_moff	equ	0xFDBE



;
; Implementation of us_btile_new
;
us_btile_new_i:
.tgp	equ	0		; Target pointer
.wdt	equ	1		; Width of tiles in cells
.hgt	equ	2		; Height of tiles
.bnk	equ	3		; Bank of tile source
.off	equ	4		; Offset (tile index 0) of tile source
.cfg	equ	5		; Blit configuration

	jfa us_tile_new_i {[$.tgp], us_btile_blit, us_btile_gethw, us_btile_acc}

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
; Implementation of us_btile_acc
;
us_btile_acc_i:
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
	mov [us_tile_imul], c
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
	mov [us_tile_moff], c
	mov c,     [x3]
	mov x3,    c
	shr x3,    5
	mov [us_tile_mtil], x3	; Tile index layout on low 3 bits

	mov x3,    c
	and x3,    0x000F	; VCK, Pixel barrel rot; BB is zero, OK
	mov [P_GFIFO_DATA], x3	; 0x0015: Blit control flags & src. barrel rot
	mov x3,    0x0F00
	and x3,    c
	shr c,     12
	or  x3,    c
	mov [P_GFIFO_DATA], x3	; 0x0016: AND mask and Colorkey

	rfn c:x3,  0



;
; Implementation of us_btile_blit
;
us_btile_blit_i:
.srp	equ	0		; Source pointer (not used)
.idx	equ	1		; Tile index
.ofh	equ	2		; Destination offset, high
.ofl	equ	3		; Destination offset, low

	mov x3,    0x001C
	mov [P_GFIFO_ADDR], x3

	mov c,     [$.ofh]
	mov [P_GFIFO_DATA], c	; 0x001C: Destination whole
	mov c,     0
	xug 4,     sp		; Fraction is zero unless parameter is provided
	mov c,     [$.ofl]
	mov [P_GFIFO_DATA], c	; 0x001D: Destination fraction

.entr:	mov c,     [us_tile_mtil]
	and c,     0x7		; Low 3 bits
	add c,     1
	jmr c			; Jump table to tile index decoding

	jms .ti0
	jms .ti1
	jms .ti2
	jms .ti3
	jms .ti4
	jms .ti5
	jms .ti6

.ti7:
.ti6:
.ti5:	mov c,     0
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	jms .tic

.ti4:	mov c,     [$.idx]
	shr c,     12
	mov [P_GFIFO_DATA], c
	mov c,     0x0FFF	; Tile index bits
	and c,     [$.idx]
	jms .tic

.ti3:	mov c,     [$.idx]
	shr c,     13
	xeq c,     0		; 0: No reindex
	add c,     24		; Banks 25 - 31
	shl c,     8
	xeq c,     0
	bts c,     13		; Enable reindexing
	mov [P_GFIFO_DATA], c
	mov c,     0x1FFF	; Tile index bits
	and c,     [$.idx]
	jms .tic

.ti2:	mov c,     [$.idx]
	shr c,     12
	xeq c,     0		; 0: No reindex
	bts c,     4		; Banks 17 - 31
	shl c,     8
	xeq c,     0
	bts c,     13		; Enable reindexing
	mov [P_GFIFO_DATA], c
	mov c,     0x0FFF	; Tile index bits
	and c,     [$.idx]
	jms .tic

.ti1:	mov c,     [$.idx]
	shr c,     11
	shl c,     8
	xeq c,     0
	bts c,     13		; Enable reindexing
	mov [P_GFIFO_DATA], c
	mov c,     0x07FF	; Tile index bits
	and c,     [$.idx]
	jms .tic

.ti0:	mov c,     0
	xbc [$.idx], 15
	mov c,     0x6000	; Reindexing + VDR enabled
	mov [P_GFIFO_DATA], c
	mov c,     0x7FFF	; Tile index bits
	and c,     [$.idx]

.tic:	mul c,     [us_tile_imul]
	add c,     [us_tile_moff]
	mov x3,    0x001A
	mov [P_GFIFO_ADDR], x3
	mov [P_GFIFO_DATA], c	; 0x001A: Source X whole

	mov c,     0x001F
	mov [P_GFIFO_ADDR], c
	mov [P_GFIFO_DATA], c	; 0x001F: Start trigger

	rfn c:x3,  0



;
; Implementation of us_btile_getwh
;
us_btile_gethw_i:
.srp	equ	0		; Source pointer

	mov x3,    [$.srp]
	add x3,    3
	mov c,     [x3]		; Width
	mov x3,    [x3]		; Height
	xch x3,    c
	rfn
