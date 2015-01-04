;
; RRPGE User Library functions - Tilesets
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Basic accelerator tileset management.
;
; Uses the following CPU RAM locations:
;
; 0xFABC: Tile index multiplier
; 0xFABD: Memorized tile index layout (by us_tile_getacc, low 3 bits)
; 0xFABE: Memorized tile start offset (by us_tile_getacc)
;
; Uses tileset structures (objects) of the following layout:
;
; Word0: Width (high 7 bits, cells) and Height (low 9 bits) of tile
; Word1: Bank of source
; Word2: Start offset of source (tile index 0)
; Word3: Blit configuration
;
; The blit configuration:
;
; bit  9-15: Bits 1-7 of Pixel AND mask (bit 0 is always 1)
; bit     8: If set, colorkey is Pixel AND mask, otherwise 0x00
; bit  5- 7: Tile index layout (see specification)
; bit     4: If set, 8 bit mode, otherwise 4 bit mode
; bit     3: Colorkey enabled if set
; bit  0- 2: Pixel barrel rotate right
;

include "rrpge.asm"

section code



; 0xFABC: Tile index multiplier
us_tile_imul	equ	0xFABC
; 0xFABD: Memorized tile index layout
us_tile_mtil	equ	0xFABD
; 0xFABE: Memorized tile start offset
us_tile_moff	equ	0xFABE



;
; Implementation of us_tile_set
;
us_tile_set_i:
.tgp	equ	0		; Target pointer
.wdt	equ	1		; Width
.hgt	equ	2		; Height
.bnk	equ	3		; Bank of tile source
.off	equ	4		; Offset (tile index 0) of tile source
.cfg	equ	5		; Blit configuration

	mov c,     [$.wdt]
	shl c,     9		; To high 7 bits
	mov x3,    [$.hgt]
	and x3,    0x01FF
	or  c,     x3		; Width & Height combined
	mov x3,    [$.tgp]
	mov [x3],  c		; Combined width & height
	mov c,     [$.bnk]
	mov [x3],  c		; Bank select
	mov c,     [$.off]
	mov [x3],  c		; Offset (tile index 0)
	mov c,     [$.cfg]
	mov [x3],  c		; Blit configuration
	rfn



;
; Implementation of us_tile_getacc
;
us_tile_getacc_i:
.srp	equ	0		; Source pointer

	mov x3,    [$.srp]
	mov c,     0x800A
	mov [P_GFIFO_ADDR], c
	mov c,     [x3]
	shr c,     9		; Width
	xne c,     0
	bts c,     7		; 0 => 128 cells
	mov [P_GFIFO_DATA], c	; 0x800A: Pointer X post-add whole
	mov x3,    0x8018
	mov [P_GFIFO_ADDR], x3
	mov [P_GFIFO_DATA], c	; 0x8018: Count of cells to blit, whole

	mov x3,    [$.srp]
	mov [$0],  c		; Save width for multiplier

	mov c,     0
	mov [P_GFIFO_DATA], c	; 0x8019: Count of cells to blit, fraction

	mov c,     0x8017
	mov [P_GFIFO_ADDR], c
	mov c,     [x3]
	and c,     0x1FF	; Height
	xne c,     0
	bts c,     9		; 0 => 512 lines
	mov [P_GFIFO_DATA], c	; 0x8017: Count of rows to blit

	mul c,     [$0]		; Tile index multiplier
	mov [us_tile_imul], c

	mov c,     0x8012
	mov [P_GFIFO_ADDR], c
	mov c,     [x3]
	mov [P_GFIFO_DATA], c	; 0x8012: Source bank select
	mov c,     0		; No partitioning on source
	mov [P_GFIFO_DATA], c	; 0x8013: Source partition select
	mov c,     [x3]
	mov [us_tile_moff], c
	mov c,     [x3]
	mov x3,    c
	shr x3,    5
	mov [us_tile_mtil], x3	; Tile index layout on low 3 bits

	mov x3,    0x8015
	mov [P_GFIFO_ADDR], x3
	mov x3,    c
	and x3,    0x001F	; VBT, VCK, Pixel barrel rot; BB is zero, OK
	mov [P_GFIFO_DATA], x3	; 0x8015: Blit control flags & src. barrel rot
	mov [$0],  c
	shr c,     8
	bts c,     0		; AND mask lowest bit is always 1
	mov x3,    c
	shl x3,    8
	xbc [$0],  8
	or  x3,    c		; If bit8 was set, then colorkey is AND mask
	mov [P_GFIFO_DATA], x3	; 0x8016: AND mask and Colorkey

	rfn



;
; Implementation of us_tile_blit
;
us_tile_blit_i:
.idx	equ	0		; Tile index
.ofh	equ	1		; Destination offset, high
.ofl	equ	2		; Destination offset, low

	mov x3,    0x801C
	mov [P_GFIFO_ADDR], x3

	mov c,     [$.ofh]
	mov [P_GFIFO_DATA], c	; 0x801C: Destination whole
	mov c,     [$.ofl]
	mov [P_GFIFO_DATA], c	; 0x801D: Destination fraction

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

.ti7:	mov c,     [$.idx]
	shr c,     8
	and c,     0x00E0	; 3 Pixel OR mask bits, rest zero
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	and c,     0x1FFF	; Tile index bits
	jms .tic

.ti6:	mov c,     [$.idx]
	shr c,     8
	and c,     0x00F0	; 4 Pixel OR mask bits, rest zero
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	and c,     0x0FFF	; Tile index bits
	jms .tic

.ti5:	mov c,     [$.idx]
	shr c,     8
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	and c,     0x00FF	; Tile index bits
	jms .tic

.ti4:	mov c,     [$.idx]
	shr c,     12
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	and c,     0x0FFF	; Tile index bits
	jms .tic

.ti3:	mov c,     [$.idx]
	shr c,     13
	xeq c,     0		; 0: No reindex
	add c,     24		; Banks 25 - 31
	shl c,     8
	xeq c,     0
	bts c,     13		; Enable reindexing
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	and c,     0x1FFF	; Tile index bits
	jms .tic

.ti2:	mov c,     [$.idx]
	shr c,     12
	xeq c,     0		; 0: No reindex
	bts c,     4		; Banks 17 - 31
	shl c,     8
	xeq c,     0
	bts c,     13		; Enable reindexing
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	and c,     0x0FFF	; Tile index bits
	jms .tic

.ti1:	mov c,     [$.idx]
	shr c,     11
	shl c,     8
	xeq c,     0
	bts c,     13		; Enable reindexing
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	and c,     0x07FF	; Tile index bits
	jms .tic

.ti0:	mov c,     0
	xbc [$.idx], 15
	mov c,     0x6000	; Reindexing + VDR enabled
	mov [P_GFIFO_DATA], c
	mov c,     [$.idx]
	and c,     0x7FFF	; Tile index bits

.tic:	mul c,     [us_tile_imul]
	add c,     [us_tile_moff]
	mov x3,    0x801A
	mov [P_GFIFO_ADDR], x3
	mov [P_GFIFO_DATA], c	; 0x801A: Source X whole

	mov c,     0x801F
	mov [P_GFIFO_ADDR], c
	mov [P_GFIFO_DATA], c	; 0x801F: Start trigger

	rfn



;
; Implementation of us_tile_blitb
;
us_tile_blitb_i:
.idx	equ	0		; Tile index
.ofh	equ	1		; Destination offset, high

	mov x3,    0x801C
	mov [P_GFIFO_ADDR], x3

	mov c,     [$.ofh]
	mov [P_GFIFO_DATA], c	; 0x801C: Destination whole
	mov c,     0
	mov [P_GFIFO_DATA], c	; 0x801D: Destination fraction

	jms us_tile_blit_i.entr	; Transfer to normal blit
