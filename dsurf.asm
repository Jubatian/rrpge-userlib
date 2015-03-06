;
; RRPGE User Library functions - Destination surfaces
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Destination surface management for assisting accelerator usage.
;
; Uses the following CPU RAM locations:
;
; 0xFDBF: Double buffering flipflop on bit 0 (0: 'A' is the display surface)
; 0xFDC0 - 0xFDC7: Default surface definition (just a surface structure)
;
; Uses surface structures (objects) of the following layout:
;
; Word0: PRAM Write mask for the surface, high (for 0x0000)
; Word1: PRAM Write mask for the surface, low (for 0x0001)
; Word2: Surface A bank select (for 0x0002)
; Word3: Surface B bank select (for 0x0002)
; Word4: Surface A partition select (for 0x0003)
; Word5: Surface B partition select (for 0x0003)
; Word6: Width of destination in cells (for 0x0004)
; Word7: Partition size (only destination, for 0x0014)
;

include "rrpge.asm"

section code



; 0xFDBF: Double buffering flipflop (bit 0)
us_dsurf_ff	equ	0xFDBF
; 0xFDC0: Default surface
us_dsurf_defs	equ	0xFDC0



;
; Implementation of us_dsurf_set
;
us_dsurf_new_i:
.tgp	equ	0		; Target pointer
.bnk	equ	1		; Bank select for A & B
.prt	equ	2		; Partition select for A & B
.wdt	equ	3		; Width
.psz	equ	4		; Partition size (low 4 bits)

	mov x3,    [$.tgp]
	not c,     0		; Load 0xFFFF for masks
	mov [x3],  c
	mov [x3],  c		; Mask high & low
	mov c,     [$.psz]
	shl c,     12		; To dest. partition
	mov [x3],  c		; Partition size
	mov c,     [$.bnk]
	mov [x3],  c
	mov [x3],  c		; Surface A & B bank select
	mov c,     [$.prt]
	mov [x3],  c
	mov [x3],  c		; Surface A & B partition select
	mov c,     [$.wdt]
	mov [x3],  c		; Width
	rfn c:x3,  0



;
; Implementation of us_dsurf_setdbuf
;
us_dsurf_newdbuf_i:
.tgp	equ	0		; Target pointer
.bna	equ	1		; Bank select for A
.pra	equ	2		; Partition select for A
.bnb	equ	3		; Bank select for B
.prb	equ	4		; Partition select for B
.wdt	equ	5		; Width
.psz	equ	6		; Partition size (low 4 bits)

	mov x3,    [$.tgp]
	not c,     0		; Load 0xFFFF for masks
	mov [x3],  c
	mov [x3],  c		; Mask high & low
	mov c,     [$.psz]
	shl c,     12		; To dest. partition
	mov [x3],  c		; Partition size
	mov c,     [$.bna]
	mov [x3],  c
	mov c,     [$.bnb]
	mov [x3],  c		; Surface A & B bank select
	mov c,     [$.pra]
	mov [x3],  c
	mov c,     [$.prb]
	mov [x3],  c		; Surface A & B partition select
	mov c,     [$.wdt]
	mov [x3],  c		; Width
	rfn c:x3,  0



;
; Implementation of us_dsurf_setm
;
us_dsurf_newm_i:
.tgp	equ	0		; Target pointer
.msh	equ	1		; Mask, high
.msl	equ	2		; Mask, low
.bnk	equ	3		; Bank select for A & B
.prt	equ	4		; Partition select for A & B
.wdt	equ	5		; Width
.psz	equ	6		; Partition size (low 4 bits)

	mov x3,    [$.tgp]
	mov c,     [$.msh]
	mov [x3],  c
	mov c,     [$.msl]
	mov [x3],  c		; Mask high & low
	mov c,     [$.psz]
	shl c,     12		; To dest. partition
	mov [x3],  c		; Partition size
	mov c,     [$.bnk]
	mov [x3],  c
	mov [x3],  c		; Surface A & B bank select
	mov c,     [$.prt]
	mov [x3],  c
	mov [x3],  c		; Surface A & B partition select
	mov c,     [$.wdt]
	mov [x3],  c		; Width
	rfn c:x3,  0



;
; Implementation of us_dsurf_setmdbuf
;
us_dsurf_newmdbuf_i:
.tgp	equ	0		; Target pointer
.msh	equ	1		; Mask, high
.msl	equ	2		; Mask, low
.bna	equ	3		; Bank select for A
.pra	equ	4		; Partition select for A
.bnb	equ	5		; Bank select for B
.prb	equ	6		; Partition select for B
.wdt	equ	7		; Width
.psz	equ	8		; Partition size (low 4 bits)

	mov x3,    [$.tgp]
	mov c,     [$.msh]
	mov [x3],  c
	mov c,     [$.msl]
	mov [x3],  c		; Mask high & low
	mov c,     [$.psz]
	shl c,     12		; To dest. partition
	mov [x3],  c		; Partition size
	mov c,     [$.bna]
	mov [x3],  c
	mov c,     [$.bnb]
	mov [x3],  c		; Surface A & B bank select
	mov c,     [$.pra]
	mov [x3],  c
	mov c,     [$.prb]
	mov [x3],  c		; Surface A & B partition select
	mov c,     [$.wdt]
	mov [x3],  c		; Width
	rfn c:x3,  0



;
; Implementation of us_dsurf_get
;
us_dsurf_get_i:
.srp	equ	0		; Source pointer

	jfa us_dbuf_getlist_i	; Wait for frame end if necessary

.entr:	mov x3,    [$.srp]
	xbs [us_dsurf_ff], 0
	add x3,    1		; If clear, B is the work surface
	add x3,    3		; Selects A or B bank select
	mov c,     [x3]		; Bank
	add x3,    1
	rfn x3,    [x3]		; Partition



;
; Implementation of us_dsurf_getacc
;
us_dsurf_getacc_i:
.srp	equ	0		; Source pointer

	jfa us_dbuf_getlist_i	; Wait for frame end if necessary

	mov x3,    [$.srp]
	mov c,     0x0000
	mov [P_GFIFO_ADDR], c
	mov c,     [x3]
	mov [P_GFIFO_DATA], c	; Write mask, high
	mov c,     [x3]
	mov [P_GFIFO_DATA], c	; Write mask, low
	mov c,     [x3]		; Load partitioning setting
	xbs [us_dsurf_ff], 0
	add x3,    1		; If clear, B is the work surface
	or  c,     [x3]
	mov [P_GFIFO_DATA], c	; Destination bank select & Partition size
	add x3,    1
	mov c,     [x3]
	mov [P_GFIFO_DATA], c	; Destination partition select
	xbc [us_dsurf_ff], 0
	add x3,    1		; Restore offset in 'x3'
	mov c,     [x3]
	mov [P_GFIFO_DATA], c	; Destination width (post-add whole)
	mov c,     0
	mov [P_GFIFO_DATA], c	; Destination width (post-add fraction)
	jms us_dsurf_get_i.entr	; Tail-transfer for return value



;
; Implementation of us_dsurf_getwp
;
us_dsurf_getpw_i:
.srp	equ	0		; Source pointer

	mov x3,    [$.srp]
	add x3,    7
	mov c,     [x3]
	sub x3,    6
	mov x3,    [x3]
	shr x3,    12
	xch c,     x3
	rfn



;
; Implementation of us_dsurf_init
;
us_dsurf_init_i:

	bts [us_dsurf_ff], 0
	rfn



;
; Implementation of us_dsurf_flip
;
us_dsurf_flip_i:

	mov c,     1
	xor [us_dsurf_ff], c
	rfn c:x3,  0
