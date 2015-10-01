;
; RRPGE User Library functions - Character readers
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; This should be placed near utf.asm so the short jumps to the tail-called
; functions stay in range.
;
;
; Character readers implemented:
;
;
; cbyte: CPU RAM 8 bit reader.
;
; Reads bytes, converting the upper 128 bytes to UTF-32 representations by a
; conversion table. A suitable code page 437 table is included in the
; Peripheral RAM, so it can be used with the charset also included in PRAM.
;
; Object structure:
;
; Word0: <Character reader interface>
; Word1: <Character reader interface>
; Word2: Pointer (8 bit) of next character to read, high.
; Word3: Pointer (8 bit) of next character to read, low (on bit 3).
; Word4: PRAM pointer (word) of conversion table, high.
; Word5: PRAM pointer (word) of conversion table, low.
;
; The conversion table is 128 * 32 bits (Big Endian) long, specifying UTF-32
; target values for the byte range 0x80 - 0xFF.
;
; Functions:
;
; us_cr_cbyte_new (Init an object structure)
; us_cr_cbyte_setsi
; us_cr_cbyte_getnc
;
;
; pbyte: Peripheral RAM 8 bit reader.
;
; Reads bytes, converting the upper 128 bytes to UTF-32 representations by a
; conversion table. A suitable code page 437 table is included in the
; Peripheral RAM, so it can be used with the charset also included in PRAM.
;
; Object structure:
;
; Word0: <Character reader interface>
; Word1: <Character reader interface>
; Word2: PRAM pointer (bit) of next character to read, high.
; Word3: PRAM pointer (bit) of next character to read, low.
; Word4: PRAM pointer (word) of conversion table, high.
; Word5: PRAM pointer (word) of conversion table, low.
;
; The conversion table is 128 * 32 bits (Big Endian) long, specifying UTF-32
; target values for the byte range 0x80 - 0xFF.
;
; Functions:
;
; us_cr_pbyte_new (Init an object structure)
; us_cr_pbyte_setsb (Sets PRAM bank)
; us_cr_pbyte_setsi (Selects a 32 bit start offset within PRAM bank)
; us_cr_pbyte_getnc
;
;
; cutf8: CPU RAM UTF-8 reader.
;
; Object structure:
;
; Word0: <Character reader interface>
; Word1: <Character reader interface>
; Word2: Pointer (8 bit) of next character to read, high.
; Word3: Pointer (8 bit) of next character to read, low (on bit 3).
;
; Functions:
;
; us_cr_cutf8_new (Init an object structure, same as setsi)
; us_cr_cutf8_setsi
; us_cr_cutf8_getnc
;
;
; putf8: Peripheral RAM UTF-8 reader.
;
; Object structure:
;
; Word0: <Character reader interface>
; Word1: <Character reader interface>
; Word2: PRAM pointer (bit) of next character to read, high.
; Word3: PRAM pointer (bit) of next character to read, low.
;
; Functions:
;
; us_cr_putf8_new (Init an object structure)
; us_cr_putf8_setsb (Sets PRAM bank)
; us_cr_putf8_setsi (Selects a 32 bit start offset within PRAM bank)
; us_cr_putf8_getnc
;

include "rrpge.asm"
include "ifcharr.asm"
include "utf.asm"

section code



;
; Implementation of us_cr_cbyte_new
;
us_cr_cbyte_new_i:
.opt	equ	0		; Object pointer
.idx	equ	1		; Index
.tbh	equ	2		; Conversion table PRAM word pointer, high
.tbl	equ	3		; Conversion table PRAM word pointer, low

	jfa us_cr_new_i {[$.opt], us_cr_cbyte_setsi, us_cr_cbyte_getnc}
	add x3,    2
	xug sp,    3		; If at least 4 parameters are provided, it has table
	jms .tfd
	mov c,     [$.tbh]
	mov [x3],  c
	mov c,     [$.tbl]
	mov [x3],  c
	jms us_cr_cbyte_setsi_i	; Tail transfer to set index (which is provided)
.tfd:	mov c,     up16h_uf437
	mov [x3],  c
	mov c,     up16l_uf437
	mov [x3],  c
	xul sp,    2
	jms us_cr_cbyte_setsi_i	; Tail transfer to set index
	sub x3,    4		; 1 parameter: no index
.clre:	mov c,     0		; Entry point for clearing exit
	mov [x3],  c
	mov [x3],  c
	rfn c:x3,  0



;
; Implementation of us_cr_cbyte_setsi
; Implementation of us_cr_cutf8_setsi
;
us_cr_cbyte_setsi_i:
us_cr_cutf8_setsi_i:
.opt	equ	0		; Object pointer
.idx	equ	1		; New index

	mov x3,    [$.opt]
	add x3,    2
	mov c,     [$.idx]
	mov [x3],  c		; High of 8 bit pointer
	mov c,     0
	mov [x3],  c		; Low of 8 bit pointer
	rfn c:x3,  0



;
; Implementation of us_cr_cbyte_getnc
;
us_cr_cbyte_getnc_i:
.opt	equ	0		; Object pointer

	; Load character

	jfa us_cr_cchar_f {[$.opt]}

	; If less than 128, then simply return it

	xug x3,    127
	rfn			; <128, ASCII-7 return

.entr:	; Common handler with PRAM loader

	; Save CPU registers

	psh a, d

	; Decode by table

	mov a,     x3
	mov x3,    [$.opt]
	add x3,    4
	btc a,     7		; Mask for 0 - 127 range
	shl a,     1		; Table word pointer
	mov d,     [x3]		; Table pointer, high
	mov c,     [x3]		; Table pointer, low
	add c:a,   c		; Word offset low in 'A'
	add d,     c		; Word offset high in 'D'
	shl c:a,   4
	slc d,     4		; Bit offset
	mov x3,    P3_AH
	mov [x3],  d		; P3_AH
	mov [x3],  a		; P3_AL
	mov c,     0
	mov [x3],  c		; P3_IH
	mov c,     16
	mov [x3],  c		; P3_IL
	mov c,     4
	mov [x3],  c		; P3_DS
	mov c,     [P3_RW]	; UTF-32, high

	; Restore CPU registers & exit

	pop a, d
	rfn x3,    [P3_RW]	; UTF-32, low



;
; Implementation of us_cr_pbyte_new
;
us_cr_pbyte_new_i:
.opt	equ	0		; Object pointer
.bnk	equ	1		; PRAM bank
.idx	equ	2		; Index
.tbh	equ	3		; Conversion table PRAM word pointer, high
.tbl	equ	4		; Conversion table PRAM word pointer, low

	jfa us_cr_new_i {[$.opt], us_cr_pbyte_setsi, us_cr_pbyte_getnc}
	add x3,    2
	xug sp,    4		; If at least 5 parameters are provided, it has table
	jms .tfd
	mov c,     [$.tbh]
	mov [x3],  c
	mov c,     [$.tbl]
	mov [x3],  c
.tsi:	jfa us_cr_pbyte_setsi_i {[$.opt], [$.idx]}
	jms us_cr_pbyte_setsb_i	; Tail transfer to set bank
.tfd:	mov c,     up16h_uf437
	mov [x3],  c
	mov c,     up16l_uf437
	mov [x3],  c
	xul sp,    3
	jms .tsi		; At least 3 parameters: it has index
	sub x3,    4		; Clear index, then tail-transfer to bank set
.clre:	mov c,     0
	mov [x3],  c
	mov [x3],  c
	jms us_cr_pbyte_setsb_i	; Tail transfer to set bank



;
; Implementation of us_cr_pbyte_setsb
; Implementation of us_cr_putf8_setsb
;
us_cr_pbyte_setsb_i:
us_cr_putf8_setsb_i:
.opt	equ	0		; Object pointer
.bnk	equ	1		; PRAM bank

	mov x3,    [$.opt]
	add x3,    2
	mov c,     0x001F
	and [x3],  c		; Keep only in-bank part of offset
	sub x3,    1
	mov c,     [$.bnk]
	shl c,     5		; To bank select over the bit offset
	or  [x3],  c
	rfn c:x3,  0



;
; Implementation of us_cr_pbyte_setsi
; Implementation of us_cr_putf8_setsi
;
us_cr_pbyte_setsi_i:
us_cr_putf8_setsi_i:
.opt	equ	0		; Object pointer
.idx	equ	1		; New index

	mov x3,    [$.opt]
	add x3,    2
	mov c,     0xFFE0
	and [x3],  c		; Keep only bank part of offset
	mov c,     5
	shl c:[$.idx], c
	sub x3,    1
	or  [x3],  c		; High of PRAM bit pointer
	mov c,     [$.idx]
	mov [x3],  c		; Low of PRAM bit pointer
	rfn c:x3,  0



;
; Implementation of us_cr_pbyte_getnc
;
us_cr_pbyte_getnc_i:
.opt	equ	0		; Object pointer

	; Load character

	jfa us_cr_pchar_f {[$.opt]}

	; If less than 128, then simply return it

	xug x3,    127
	rfn			; <128, ASCII-7 return

	; Tail transfer to table load

	jms us_cr_cbyte_getnc_i.entr



;
; Implementation of us_cr_cutf8_new
;
us_cr_cutf8_new_i:
.opt	equ	0		; Object pointer
.idx	equ	1		; Index

	jfa us_cr_new_i {[$.opt], us_cr_cutf8_setsi, us_cr_cutf8_getnc}
	xug sp,    1
	jms us_cr_cbyte_new_i.clre
	jms us_cr_cutf8_setsi_i	; Tail transfer to set index



;
; Implementation of us_cr_cutf8_getnc
;
us_cr_cutf8_getnc_i:
.opt	equ	0		; Object pointer

	mov sp,    2
	mov c,     us_cr_cchar_f
	xch [$0],  c		; Just prepare stack for us_utf32f8 ...
	mov [$1],  c		; ... and transfer
	jms us_utf32f8_i



;
; Implementation of us_cr_putf8_new
;
us_cr_putf8_new_i:
.opt	equ	0		; Object pointer
.bnk	equ	1		; PRAM bank
.idx	equ	2		; Index

	jfa us_cr_new_i {[$.opt], us_cr_putf8_setsi, us_cr_putf8_getnc}
	xug sp,    2		; Note: common handling with byte reader (us_cr_pbyte_setsb_i common)
	jms us_cr_pbyte_new_i.clre
	jfa us_cr_putf8_setsi_i {[$.opt], [$.idx]}
	jms us_cr_putf8_setsb_i	; Tail transfer to set bank



;
; Implementation of us_cr_putf8_getnc
;
us_cr_putf8_getnc_i:
.opt	equ	0		; Object pointer

	mov sp,    2
	mov c,     us_cr_pchar_f
	xch [$0],  c		; Just prepare stack for us_utf32f8 ...
	mov [$1],  c		; ... and transfer
	jms us_utf32f8_i



;
; Internal load character function for CPU RAM, with pointer write-back,
; returning proper to 'x3'.
;
us_cr_cchar_f:
.opt	equ	0		; Object pointer

	psh x2, xm

	; Load character

	mov xm,    0x8666	; x3: PTR8; x2: PTR16I
	mov x2,    [$.opt]
	add x2,    2
	mov x3,    [x2]		; Pointer high (will be x3)
	mov xb3,   [x2]		; Pointer low
	mov c,     [x3]
	sub x2,    2		; Write back new char pointer
	mov [x2],  x3
	mov [x2],  xb3

	; Restore CPU regs & return

	pop x2, xm
	rfn c:x3,  c



;
; Internal load character function for PRAM, with pointer write-back,
; returning proper to 'x3'.
;
us_cr_pchar_f:
.opt	equ	0		; Object pointer

	psh a

	; Load character

	mov x3,    [$.opt]
	add x3,    2
	mov c,     [x3]
	mov a,     [x3]		; Load in 'a' to remember it for adding
	mov [P3_AH], c
	mov [P3_AL], a
	mov c,     3
	mov [P3_DS], c		; 8 bit data size
	add c:a,   8
	sub x3,    2
	add [x3],  c		; High of new PRAM bit pointer
	mov [x3],  a		; Low of new PRAM bit pointer

	; Restore CPU regs & return

	pop a
	rfn c:x3,  [P3_RW_NI]
