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
.tfd:	mov c,     up_uf437_h
	mov [x3],  c
	mov c,     up_uf437_l
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

	mov sp,    3

	; Save CPU registers

	mov [$1],  a
	mov [$2],  d

	; Load character ('x3' will point at table pointer high)

	jma d,     us_cr_cchar

	; If less than 128, then simply return it

.entr:	xug 128,   a
	jms .tbl		; >= 128, so use the table
	mov x3,    a
	mov c,     0
	jms .exit

	; Larger than 127, need to use table to get UTF-32

.tbl:	btc a,     7		; Mask for 0 - 127 range
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
	mov x3,    [P3_RW]	; UTF-32, low

	; Restore CPU registers & exit

.exit:	mov a,     [$1]
	mov d,     [$2]
	rfn



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
.tfd:	mov c,     up_uf437_h
	mov [x3],  c
	mov c,     up_uf437_l
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

	mov sp,    3

	; Save CPU registers

	mov [$1],  a
	mov [$2],  d

	; Load character

	jma d,     us_cr_pchar

	; Tail transfer

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

.ub0	equ	1		; UTF-8 sequence, char 0
.ub1	equ	2		; UTF-8 sequence, char 1
.ub2	equ	3		; UTF-8 sequence, char 2

	mov sp,    7

	; Prepare for CPU RAM loading

	mov [$5],  b
	mov b,     us_cr_cchar	; Char. loader: CPU RAM

	; Fast ASCII-7 test: if first char is <128, then plain ASCII-7

.entr:	mov [$4],  a		; Save CPU register A
	mov [$6],  d
	jma d,     b		; Load first character
	xbs a,     7
	jms .exia		; <128, so ASCII-7

	; UTF-8 character sequence. Do a partial decode, just guessing the
	; size, and loading the necessary subsequent chars.

	; Check for invalid continuing byte

	xbs a,     6
	jms .inv		; C:X3 zero, return because this is invalid

	; Check for 2 byte sequence

	mov [$.ub0], a
	jma d,     b
	xbc [$.ub0], 5
	jms .nb2
	jfa us_utf32f8_i {[$.ub0], a}
	jms .exit

.nb2:	; Check for 3 byte sequence

	xne a,     0
	jms .inv		; String end before end of UTF-8 char, invalid
	mov [$.ub1], a
	jma d,     b
	xbc [$.ub0], 4
	jms .nb3
	jfa us_utf32f8_i {[$.ub0], [$.ub1], a}
	jms .exit

.nb3:	; Check for 4 byte sequence

	xne a,     0
	jms .inv		; String end before end of UTF-8 char, invalid
	mov [$.ub2], a
	jma d,     b
	xbc [$.ub0], 3
	jms .inv		; No longer sequence support, so invalid
	jfa us_utf32f8_i {[$.ub0], [$.ub1], [$.ub2], a}
	jms .exit

	; Invalid UTF-8

.inv:	mov x3,    0
	jms .exii

	; ASCII-7 exit

.exia:	mov x3,    a		; Return low
.exii:	mov c,     0		; Return high

	; Restore CPU regs & exit

.exit:	mov b,     [$5]
	mov a,     [$4]
	mov d,     [$6]
	rfn



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

.ub0	equ	1		; UTF-8 sequence, char 0
.ub1	equ	2		; UTF-8 sequence, char 1
.ub2	equ	3		; UTF-8 sequence, char 2

	mov sp,    7

	; Prepare for PRAM loading & transfer

	mov [$5],  b
	mov b,     us_cr_pchar	; Char. loader: PRAM
	jms us_cr_cutf8_getnc_i.entr



;
; Internal load character function for CPU RAM, with pointer write-back,
; returning to 'd'. Assumes the object pointer to be at [$0]. Returns the
; character in 'a', 'x3' set past the current offset in the object structure.
; Register 'c' is destroyed in the process.
;
us_cr_cchar:
.opt	equ	0		; Object pointer

	; Load character pointer

	mov x3,    [$.opt]
	add x3,    2
	mov c,     [x3]		; Pointer high (will be x3)
	mov xb3,   [x3]		; Pointer low
	xch x3,    c

	; Load character

	mov xm3,   PTR8I
	mov a,     [x3]
	mov xm3,   PTR16I
	xch c,     x3
	sub x3,    2		; Write back new char pointer
	mov [x3],  c
	mov [x3],  xb3

	jma d			; Character returns in 'a'



;
; Internal load character function for PRAM, with pointer write-back,
; returning to 'd'. Assumes the object pointer to be at [$0]. Returns the
; character in 'a', 'x3' set past the current offset in the object structure.
; Register 'c', and PRAM pointer 3 are destroyed in the process.
;
us_cr_pchar:
.opt	equ	0		; Object pointer

	; Load character

	mov x3,    [$.opt]
	add x3,    2
	mov c,     [x3]
	mov [P3_AH], c
	mov a,     [x3]		; Load in 'a' to remember it for adding
	mov [P3_AL], a
	mov c,     3
	mov [P3_DS], c		; 8 bit data size
	add c:a,   8
	sub x3,    2
	add [x3],  c		; High of new PRAM bit pointer
	mov [x3],  a		; Low of new PRAM bit pointer
	mov a,     [P3_RW_NI]

	jma d			; Character returns in 'a'
