;
; RRPGE User Library functions - Tileset interface
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Interface for tilesets.
;
; Uses tileset structures (objects) of the following layout:
;
; Word0: Blit function implementation
; Word1: Height:Width request function implementation
; Word2: Accelerator init function implementation
;

include "rrpge.asm"

section code



;
; Implementation of us_tile_new
;
us_tile_new_i:
.opt	equ	0		; Tileset pointer
.bfn	equ	1		; Blit function implementation
.hfn	equ	2		; Height:Width request function implementation
.afn	equ	3		; Accelerator init function implementation

	mov x3,    [$.opt]
	mov c,     [$.bfn]
	mov [x3],  c
	mov c,     [$.hfn]
	mov [x3],  c
	mov c,     [$.afn]
	mov [x3],  c
	rfn c:x3,  x3



;
; Implementation of us_tile_acc
;
us_tile_acc_i:
.opt	equ	0		; Tileset pointer

	mov x3,    [$.opt]
	add x3,    2
	jma [x3]		; Simply tail-transfer



;
; Implementation of us_tile_blit
;
us_tile_blit_i:
.opt	equ	0		; Tileset pointer
.idx	equ	1		; Tile index
.ofh	equ	2		; Destination offset, high
.ofl	equ	3		; Destination offset, low

	mov x3,    [$.opt]
	jma [x3]		; Simply tail-transfer



;
; Implementation of us_tile_gethw
;
us_tile_gethw_i:
.opt	equ	0		; Tileset pointer

	mov x3,    [$.opt]
	add x3,    1
	jma [x3]		; Simply tail-transfer
