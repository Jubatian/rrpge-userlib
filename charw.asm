;
; RRPGE User Library functions - Character writers
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Character writers implemented:
;
;
; cbyte: CPU RAM 8 bit writer.
;
; Writes bytes, converting UTF-32 values including and above 128 using a
; conversion table. A suitable table for reasonable code page 437 conversion
; is included in the Peripheral RAM. No output styles are supported.
;
; Object structure:
;
; Word0: <Character writer extended interface>
; Word1: <Character writer extended interface>
; Word2: <Character writer extended interface>
; Word3: <Character writer extended interface>
; Word4: Pointer (8 bit) of next character to write, high (1 bit).
; Word5: Pointer (8 bit) of next character to write, low.
; Word6: Pointer (8 bit) of termination, high (1 bit).
; Word7: Pointer (8 bit) of termination, low.
; Word8: PRAM pointer (word) of conversion table, high.
; Word9: PRAM pointer (word) of conversion table, low.
;
; Functions:
;
; us_cwr_cbyte_new (Init an object structure)
; us_cwr_cbyte_newz (Init an object structure, with terminating zero)
; us_cwr_cbyte_setnc
; us_cwr_cbyte_nextid
;
;
; pbyte: Peripheral RAM 8 bit writer.
;
; Writes bytes, converting UTF-32 values including and above 128 using a
; conversion table. A suitable table for reasonable code page 437 conversion
; is included in the Peripheral RAM. No output styles are supported.
;
; Object structure:
;
; Word0: <Character writer extended interface>
; Word1: <Character writer extended interface>
; Word2: <Character writer extended interface>
; Word3: <Character writer extended interface>
; Word4: PRAM pointer (bit) of next character to write, high.
; Word5: PRAM pointer (bit) of next character to write, low.
; Word6: PRAM pointer (bit) of termination, high.
; Word7: PRAM pointer (bit) of termination, low.
; Word8: PRAM pointer (word) of conversion table, high.
; Word9: PRAM pointer (word) of conversion table, low.
;
; Functions:
;
; us_cwr_pbyte_new (Init an object structure)
; us_cwr_pbyte_newz (Init an object structure, with terminating zero)
; us_cwr_pbyte_setnc
; us_cwr_pbyte_nextid
;
;
; cutf8: CPU RAM UTF-8 writer.
;
; Object structure:
;
; Word0: <Character writer extended interface>
; Word1: <Character writer extended interface>
; Word2: <Character writer extended interface>
; Word3: <Character writer extended interface>
; Word4: Pointer (8 bit) of next character to write, high (1 bit).
; Word5: Pointer (8 bit) of next character to write, low.
; Word6: Pointer (8 bit) of termination, high (1 bit).
; Word7: Pointer (8 bit) of termination, low.
;
; Functions:
;
; us_cwr_cutf8_new (Init an object structure)
; us_cwr_cutf8_newz (Init an object structure, with terminating zero)
; us_cwr_cutf8_setnc
; us_cwr_cutf8_nextid
;
;
; putf8: Peripheral RAM UTF-8 writer.
;
; Object structure:
;
; Word0: <Character writer extended interface>
; Word1: <Character writer extended interface>
; Word2: <Character writer extended interface>
; Word3: <Character writer extended interface>
; Word4: PRAM pointer (bit) of next character to write, high.
; Word5: PRAM pointer (bit) of next character to write, low.
; Word6: PRAM pointer (bit) of termination, high.
; Word7: PRAM pointer (bit) of termination, low.
;
; Functions:
;
; us_cwr_putf8_new (Init an object structure)
; us_cwr_putf8_newz (Init an object structure, with terminating zero)
; us_cwr_putf8_setnc
; us_cwr_putf8_nextid
;

include "rrpge.asm"
include "ifcharw.asm"
include "utf.asm"

section code



;
; Implementation of us_cwr_cbyte_set
;
us_cwr_cbyte_new_i:
.opt	equ	0		; Object pointer
.idx	equ	1		; Index (word offset) to start at
.trm	equ	2		; Termination index (word offset)
.tbh	equ	3		; Conversion table PRAM word pointer, high
.tbl	equ	4		; Conversion table PRAM word pointer, low

	jfa us_cwr_new_i {[$.opt], us_cwr_cbyte_setnc, us_cwr_cbyte_nextsi}
	add x3,    4
	mov c,     [$.tbh]
	mov [x3],  c
	mov c,     [$.tbl]
	mov [x3],  c

	jms us_cwr_cutf8_new_i.entr



;
; Implementation of us_cwr_cbyte_setz
;
us_cwr_cbyte_newz_i:
.opt	equ	0		; Object pointer
.idx	equ	1		; Index (word offset) to start at
.trm	equ	2		; Termination index (word offset)
.tbh	equ	3		; Conversion table PRAM word pointer, high
.tbl	equ	4		; Conversion table PRAM word pointer, low

	jfa us_cwr_new_i {[$.opt], us_cwr_cbyte_setnc, us_cwr_cbyte_nextsi}
	add x3,    4
	mov c,     [$.tbh]
	mov [x3],  c
	mov c,     [$.tbl]
	mov [x3],  c

	jms us_cwr_cutf8_newz_i.entr



;
; Implementation of us_cwr_cbyte_setnc
;
us_cwr_cbyte_setnc_i:
.opt	equ	0		; Object pointer
.u4h	equ	1		; UTF-32 input, high
.u4l	equ	2		; UTF-32 input, low

	mov sp,    7

	; Save CPU registers & provide entry point

	mov [$6],  x2
	mov x2,    us_cwr_cchar
.entr:	mov [$3],  a
	mov [$4],  b
	mov [$5],  d

	; Look up character

	mov x3,    [$.opt]
	add x3,    8
	jfa us_idfutf32_i {[x3], [x3], [$.u4h], [$.u4l]}
	mov a,     x3

	; Write character

	jma d,     x2

	; Restore CPU regs & return

	mov d,     [$5]
	mov a,     [$3]
	mov b,     [$4]
	mov x2,    [$6]
	rfn c:x3,  0



;
; Implementation of us_cwr_cbyte_nextsi
; Implementation of us_cwr_cutf8_nextsi
;
us_cwr_cbyte_nextsi_i:
us_cwr_cutf8_nextsi_i:
.opt	equ	0		; Object pointer

	mov x3,    [$.opt]
	add x3,    5
	xbs [x3],  3
	jms .ret		; At index boundary, OK, return.
	sub x3,    2
	mov c,     1
	add [x3],  c
	mov c,     0
	mov [x3],  c
.ret:	mov x3,    [$.opt]
	add x3,    4
	rfn c:x3,  [x3]		; Reproduced index



;
; Implementation of us_cwr_pbyte_new
;
us_cwr_pbyte_new_i:
.opt	equ	0		; Object pointer
.bnk	equ	1		; PRAM bank
.idx	equ	2		; Index (32 bit offset) to start at
.trm	equ	3		; Termination index (word offset)
.tbh	equ	4		; Conversion table PRAM word pointer, high
.tbl	equ	5		; Conversion table PRAM word pointer, low

	jfa us_cwr_new_i {[$.opt], us_cwr_pbyte_setnc, us_cwr_pbyte_nextsi}
	add x3,    4
	mov c,     [$.tbh]
	mov [x3],  c
	mov c,     [$.tbl]
	mov [x3],  c

	jms us_cwr_putf8_new_i.entr



;
; Implementation of us_cwr_pbyte_newz
;
us_cwr_pbyte_newz_i:
.opt	equ	0		; Object pointer
.bnk	equ	1		; PRAM bank
.idx	equ	2		; Index (32 bit offset) to start at
.trm	equ	3		; Termination index (word offset)
.tbh	equ	4		; Conversion table PRAM word pointer, high
.tbl	equ	5		; Conversion table PRAM word pointer, low

	jfa us_cwr_new_i {[$.opt], us_cwr_pbyte_setnc, us_cwr_pbyte_nextsi}
	add x3,    4
	mov c,     [$.tbh]
	mov [x3],  c
	mov c,     [$.tbl]
	mov [x3],  c

	jms us_cwr_putf8_newz_i.entr



;
; Implementation of us_cwr_pbyte_setnc
;
us_cwr_pbyte_setnc_i:
.opt	equ	0		; Object pointer
.u4h	equ	1		; UTF-32 input, high
.u4l	equ	2		; UTF-32 input, low

	mov sp,    7

	; Save CPU registers & transfer

	mov [$6],  x2
	mov x2,    us_cwr_pchar
	jms us_cwr_cbyte_setnc_i.entr



;
; Implementation of us_cwr_pbyte_nextsi
; Implementation of us_cwr_putf8_nextsi
;
us_cwr_pbyte_nextsi_i:
us_cwr_putf8_nextsi_i:
.opt	equ	0		; Object pointer

	mov x3,    [$.opt]
	add x3,    5
	mov c,     [x3]
	xbs c,     3
	xbc c,     4
	jms .cnt		; No boundary, step up to next.
	jms .ret		; At index boundary, OK, return.
.cnt:	sub x3,    1
	mov c,     0xFFE0	; Clear all non-boundary bits
	and c,     [x3]
	add c,     0x0020	; Step up to next boundary
	sub x3,    1
	mov [x3],  c
	jnz c,     .ret		; No carry (did not wrap), return OK.
	sub x3,    1
	mov c,     1
	add [x3],  c		; Add carry
.ret:	mov x3,    [$.opt]
	add x3,    4
	mov c,     [x3]
	shr c:c,   5
	mov x3,    [x3]
	src x3,    5		; Reproduced index
	rfn c:x3,  x3



;
; Implementation of us_cwr_cutf8_new
;
us_cwr_cutf8_new_i:
.opt	equ	0		; Object pointer
.idx	equ	1		; Index (word offset) to start at
.trm	equ	2		; Termination index (word offset)

	jfa us_cwr_new_i {[$.opt], us_cwr_cutf8_setnc, us_cwr_cutf8_nextsi}

.entr:	mov x3,    [$.opt]
	add x3,    4
	mov c,     [$.idx]
	mov [x3],  c		; High of 8 bit pointer
	mov c,     0
	mov [x3],  c		; Low of 8 bit pointer
	mov c,     [$.trm]
	mov [x3],  c		; High of 8 bit pointer
	mov c,     0
	mov [x3],  c		; Low of 8 bit pointer

	rfn c:x3,  0



;
; Implementation of us_cwr_cutf8_newz
;
us_cwr_cutf8_newz_i:
.opt	equ	0		; Object pointer
.idx	equ	1		; Index (word offset) to start at
.trm	equ	2		; Termination index (word offset)

	jfa us_cwr_new_i {[$.opt], us_cwr_cutf8_setnc, us_cwr_cutf8_nextsi}

.entr:	mov x3,    [$.trm]
	sub x3,    1
	mov [$.trm], x3
	mov c,     0
	mov [x3],  c		; Zero the terminating word

	jms us_cwr_cutf8_new_i.entr



;
; Implementation of us_cwr_cutf8_setnc
;
us_cwr_cutf8_setnc_i:
.opt	equ	0		; Object pointer
.u4h	equ	1		; UTF-32 input, high
.u4l	equ	2		; UTF-32 input, low

	mov sp,    9

	; Save CPU registers & provide entry point

	mov [$8],  x2
	mov x2,    us_cwr_cchar
.entr:	mov [$3],  a
	mov [$4],  b
	mov [$5],  x0
	mov [$6],  x1
	mov [$7],  d

	; Get UTF-8 sequence of character

	jfa us_utf8f32_i {[$.u4h], [$.u4l]}
	mov x0,    c
	mov x1,    x3

	; Write characters. Just process all nonzeros. A simple size reduction
	; is used here: the UTF-8 sequence's top 2 chars never equal the low 2
	; chars (due to the start byte), except when the whole is zero.

	jms .l1
.l0:	mov x0,    x1
.l1:	mov a,     x0
	shr a,     8
	xeq a,     0
	jma d,     x2
	mov a,     0x00FF
	and a,     x0
	xeq a,     0
	jma d,     x2
	xeq x0,    x1
	jms .l0

	; Restore CPU regs & return

	mov d,     [$7]
	mov a,     [$3]
	mov b,     [$4]
	mov x0,    [$5]
	mov x1,    [$6]
	mov x2,    [$8]
	rfn c:x3,  0



;
; Implementation of us_cwr_putf8_new
;
us_cwr_putf8_new_i:
.opt	equ	0		; Object pointer
.bnk	equ	1		; PRAM bank
.idx	equ	2		; Index (32 bit offset) to start at
.trm	equ	3		; Termination index (32 bit offset)

	jfa us_cwr_new_i {[$.opt], us_cwr_putf8_setnc, us_cwr_putf8_nextsi}

.entr:	mov c,     5
	shl [$.bnk], c

	shl c:[$.trm], c
	or  c,     [$.bnk]

.entz:	mov x3,    [$.opt]
	add x3,    6
	mov [x3],  c		; High of bit pointer
	mov c,     [$.trm]
	mov [x3],  c		; Low of bit pointer

	sub x3,    4
	mov c,     5
	shl c:[$.idx], c
	or  c,     [$.bnk]
	mov [x3],  c		; High of bit pointer
	mov c,     [$.idx]
	mov [x3],  c		; Low of bit pointer

	rfn c:x3,  0



;
; Implementation of us_cwr_putf8_newz
;
us_cwr_putf8_newz_i:
.opt	equ	0		; Object pointer
.bnk	equ	1		; PRAM bank
.idx	equ	2		; Index (32 bit offset) to start at
.trm	equ	3		; Termination index (32 bit offset)

	jfa us_cwr_new_i {[$.opt], us_cwr_putf8_setnc, us_cwr_putf8_nextsi}

.entr:	mov c,     5
	shl [$.bnk], c

	mov x3,    [$.trm]
	sub x3,    1
	shl c:x3,  5
	mov [P3_AL], x3
	mov [$.trm], x3		; Terminator low
	or  c,     [$.bnk]	; C: keep terminator high in it
	mov [P3_AH], c		; Terminator high
	mov x3,    3
	mov [P3_DS], x3
	mov x3,    0
	mov [P3_RW_NI], x3	; Write out zero terminator

	jms us_cwr_putf8_new_i.entz



;
; Implementation of us_cwr_putf8_setnc
;
us_cwr_putf8_setnc_i:
.opt	equ	0		; Object pointer
.u4h	equ	1		; UTF-32 input, high
.u4l	equ	2		; UTF-32 input, low

	mov sp,    9

	; Save CPU registers & transfer

	mov [$8],  x2
	mov x2,    us_cwr_pchar
	jms us_cwr_cutf8_setnc_i.entr



;
; Internal write character function for CPU RAM, with pointer write-back,
; returning to 'd'. Assumes the object pointer at [$0]. Expects the character
; to write in register 'a'. Registers 'x3', 'b' and 'c' are destroyed in the
; process.
;
us_cwr_cchar:
.opt	equ	0		; Object pointer

	; Load character pointer

	mov x3,    [$.opt]
	add x3,    4
	mov c,     [x3]		; Pointer high
	mov xb3,   [x3]		; Pointer low

	; Check termination (checking high is sufficient)

	xne c,     [x3]		; Terminator high
	jma d			; End of area reached, no output

	; Save character

	xch x3,    c
	mov xm3,   PTR8I
	mov [x3],  a
	mov xm3,   PTR16I
	xch x3,    c
	sub x3,    3		; Write back new char pointer
	mov [x3],  c
	mov [x3],  xb3
	jma d



;
; Internal write character function for PRAM, with pointer write-back,
; returning to 'd'. Assumes the object pointer at [$0]. Expects the character
; to write in register 'a'. Registers 'x3', 'b' and 'c' are destroyed in the
; process. PRAM pointer 3 is destroyed in the process.
;
us_cwr_pchar:
.opt	equ	0		; Object pointer

	; Load character pointer

	mov x3,    [$.opt]
	add x3,    4
	mov c,     [x3]		; Pointer high
	mov b,     [x3]		; Pointer low

	; Check termination

	xne c,     [x3]		; Terminator high
	xeq b,     [x3]		; Terminator low
	jms .cnt
	jma d			; End of area reached, no output

	; Save character

.cnt:	mov [P3_AH], c
	mov [P3_AL], b
	mov c,     3		; Data unit size: 8 bits
	mov [P3_DS], c
	mov [P3_RW_NI], a
	add c:b,   8
	mov x3,    [$.opt]	; Write back new char pointer
	add x3,    4
	add [x3],  c		; High of new PRAM pointer
	mov [x3],  b		; Low of new PRAM pointer
	jma d
