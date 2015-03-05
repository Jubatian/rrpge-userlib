;
; RRPGE User Library functions - UTF assistance functions
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Provides functions for working with UTF-8 and UTF-32 characters and strings.
;
; For the us_idfutf32, a conversion table is necessary. The data structure of
; this table is as follows:
;
; 1 word: Unknown charater's conversion value.
; 1 word: Number of entries in table.
; 3 words / entry: Conversion entries in ascending order. First two words are
; the UTF-32 source (Big Endian), last word is the conversion value.
;

include "rrpge.asm"

section code



;
; Implementation of us_utf32f8
;
us_utf32f8_i:
.ub0	equ	0		; First UTF-8 byte
.ub1	equ	1		; Second UTF-8 byte
.ub2	equ	2		; Third UTF-8 byte
.ub3	equ	3		; Fourth UTF-8 byte

	; Check for 7 bit ASCII

	mov c,     0		; Set return high zero for now
	xbc [$.ub0], 7
	jms .var		; Not 7 bit ASCII
	mov x3,    0xFF
	and x3,    [$.ub0]
	rfn			; C was zero, return OK

	; Supports variable number of arguments (up to 4), work around
	; that with adding zero padding.

.var:	mov x3,    sp
	mov sp,    4
	xug 5,     x3
.inv:	rfn c:x3,  0		; Too many parameters, fail (C:X3 zero)
	jmr x3			; SP = 0 would cause infinite loop here. Invalid, don't care.
	mov [$x3], c		; Load a zero for the omitted parameters
	mov [$x3], c
	mov [$x3], c

	; Check for invalid continuing byte as first UTF-8 byte

	xbs [$.ub0], 6
	jms .inv		; Return because this is invalid

	; Set up for continuation byte masking, so all decoders get only the
	; value part (do this with mask to clean up high bits of the word
	; inputs, a bit clear would be sufficient otherwise).

	mov x3,    0x3F		; To mask out the used part of the bytes

	; Go on decoding multi-byte UTF-8

	xbs [$.ub1], 6		; Check continuation byte 1
	xbs [$.ub1], 7
	jms .inv		; Invalid if not 0b10xxxxxx
	and [$.ub1], x3

	; Check for 2 byte sequence

	xbc [$.ub0], 5
	jms .nb2
	mov x3,    0x1F
	and x3,    [$.ub0]
	shl x3,    6
	or  x3,    [$.ub1]
	rfn			; C:X3 proper return for 2 byte source

.nb2:	xbs [$.ub2], 6		; Check continuation byte 2
	xbs [$.ub2], 7
	jms .inv		; Invalid if not 0b10xxxxxx
	and [$.ub2], x3

	; Check for 3 byte sequence

	xbc [$.ub0], 4
	jms .nb3
	mov x3,    6
	shl [$.ub1], x3
	mov x3,    0x0F
	and x3,    [$.ub0]
	shl x3,    12
	or  x3,    [$.ub1]
	or  x3,    [$.ub2]
	rfn			; C:X3 proper return for 3 byte source

.nb3:	xbs [$.ub3], 6		; Check continuation byte 3
	xbs [$.ub3], 7
	jms .inv		; Invalid if not 0b10xxxxxx
	and [$.ub3], x3

	; Check for 4 byte sequence

	xbc [$.ub0], 3
	jms .inv		; Invalid (no longer sequence support)
	mov x3,    6
	shl [$.ub2], x3
	mov x3,    12
	shl c:[$.ub1], x3
	mov x3,    0x07
	and x3,    [$.ub0]
	shl x3,    2
	or  c,     x3		; C: high 5 bits complete
	mov x3,    [$.ub1]
	or  x3,    [$.ub2]
	or  x3,    [$.ub3]
	rfn			; C:X3 proper return for 4 byte source



;
; Implementation of us_utf8f32
;
us_utf8f32_i:
.u4h	equ	0		; UTF32 input, high
.u4l	equ	1		; UTF32 input, low

	; Load input for comparing

	mov c,     [$.u4h]
	mov x3,    [$.u4l]

	; Check for longer than 4 byte sequence (>21 bits)

	xug 0x0020, c
	rfn c:x3,  0		; Invalid input, needs too long sequence!

.nb4:	; Check for 4 byte, and encode it if so (>16 bits)

	xne c,     0
	jms .nb3
	mov c,     0xF080	; Set UTF-8 result bitmask
	mov x3,    [$.u4h]
	shr x3,    2
	shl x3,    8
	or  c,     x3		; First UTF-8 byte created
	mov x3,    [$.u4h]
	and x3,    3
	shl x3,    4
	or  c,     x3
	mov x3,    [$.u4l]
	shr x3,    12
	or  c,     x3		; Second UTF-8 byte created
.nb3e:	mov x3,    0x003F
	and x3,    [$.u4l]
	or  x3,    0x8080	; Add UTF-8 byte identification bits
.nb2e:	xch x3,    [$.u4l]
	and x3,    0x0FC0
	shl x3,    2
	or  x3,    [$.u4l]	; Third and fourth UTF-8 bytes created
	rfn

.nb3:	; Check for 3 byte, and encode it if so (>11 bits)

	xug x3,    0x07FF
	jms .nb2
	mov c,     0x00E0	; Set UTF-8 result bitmask
	shr x3,    12
	or  c,     x3		; First UTF-8 byte created
	jms .nb3e		; Last two bytes form the same way as for 4 byte seq.

.nb2:	; Check for 2 byte, and encode it if so (>7 bits)

	xug x3,    0x007F
	rfn			; 1 byte, plain ASCII-7 goes straight back
	mov x3,    0x003F
	and x3,    [$.u4l]
	or  x3,    0xC080	; Add UTF-8 byte identification bits
	jms .nb2e		; Last byte forms the same way as for 4 byte seq.



;
; Implementation of us_utf8len
;
us_utf8len_i:
.u4h	equ	0		; UTF32 input, high
.u4l	equ	1		; UTF32 input, low

	mov c,     [$.u4h]
	xul c,     0x0020	; Check for longer than 4 byte sequence (>21 bits)
	rfn c:x3,  0		; Invalid input, needs too long sequence!
	mov x3,    4
	jnz c,     .ret		; Check for 4 byte, and return if so (>16 bits)
	mov c,     [$.u4l]
	mov x3,    1
	xul c,     0x0800	; Check for >=3 byte, and add one if so (>11 bits)
	add x3,    1
	xul c,     0x0080	; Check for >=2 byte, and add one if so (>7 bits)
	add x3,    1
.ret:	rfn c:x3,  x3		; If 'x3' stayed 1, then was plain ASCII-7



;
; Implementation of us_idfutf32
;
us_idfutf32_i:
.toh	equ	0		; Table pointer (word), high
.tol	equ	1		; Table pointer (word), low
.u4h	equ	2		; UTF-32 value high
.u4l	equ	3		; UTF-32 value low

.unk	equ	4		; Unknown char value
.mid	equ	5		; Current midpoint to test in log. search

	; Shortcut test: If UTF-32 value is less than 128, then straight
	; conversion.

	mov c,     [$.u4h]
	mov x3,    [$.u4l]
	xne c,     0
	xug 128,   x3
	jms .main
	rfn			; Less than 128, straight return (in X3)

.main:	mov sp,    9

	; Save CPU regs

	mov [$6],  x2
	mov [$7],  a
	mov [$8],  b

	; Init PRAM pointer 3 for table read.

	jfa us_ptr_setwi_i {3, [$.toh], [$.tol]}

	; Read unknown char value and table size, prepare log search range

	mov c,     [x3]		; x3 is P3_RW at this point
	mov [$.unk], c
	mov x3,    [P3_RW]
	xne x3,    0
	jms .fail		; Zero sized table
	mov x2,    0		; Base, initial range is [x2:x3[

	; Save table start offset

	mov a,     [P3_AH]
	mov b,     [P3_AL]
	mov [$.toh], a
	mov [$.tol], b

.lp:	; Logarithmic search loop entry

	; Get location to check for conversion value

	mov b,     x2
	add b,     x3
	shr b,     1
	mov [$.mid], b

	; Calculate table offset to use

	mul c:b,   48		; 48 bits per table entry (16 * 3)
	mov a,     c
	add c:b,   [$.tol]
	adc a,     [$.toh]
	mov [P3_AH], a
	mov [P3_AL], b

	; Load, compare, determine action

	mov a,     [P3_RW]	; UTF-32 to compare with, high
	xeq a,     [$.u4h]	; High equal is typical (especially UTF-16)
	jms .hne
	mov b,     [P3_RW]	; UTF-32 to compare with, low
	xne b,     [$.u4l]
	jms .eql		; Found, so return
	xug b,     [$.u4l]
	jms .lbt
.ltp:	mov x3,    [$.mid]	; New exclusive top end is current location
	jms .echk
.lbt:	mov x2,    [$.mid]	; New inclusive bottom end is...
	add x2,    1		; ...current location + 1
.echk:	xeq x3,    x2		; Empty range check
	jms .lp			; Not empty, continue looping
.fail:	mov x3,    [$.unk]	; No match found, so return
	jms .exit
.hne:	xug a,     [$.u4h]
	jms .lbt
	jms .ltp
.eql:	mov x3,    [P3_RW]	; Found, so OK, return

	; Restore CPU regs & exit

.exit:	mov x2,    [$6]
	mov a,     [$7]
	mov b,     [$8]
	rfn c:x3,  x3
