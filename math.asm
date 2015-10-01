;
; RRPGE User Library functions - Math functions
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;

include "rrpge.asm"

section code



;
; Implementation of us_mul32
;
us_mul32_i:

.o1h	equ	0		; Operand 1, high
.o1l	equ	1		; Operand 1, low
.o2h	equ	2		; Operand 2, high
.o2l	equ	3		; Operand 2, low
.rsl	equ	1		; Result low (reuses o1l)
.rsh	equ	3		; Result high (reuses o2l)

	; Performing the 32 bit multiply:
	;
	; [$.rsh]:[$.rsl] = [$.o1h]:[$.o1l] * [$.o2h]:[$.o2l]
	;
	; This can be broken into four 16 bit multiplies with 32 bit results
	; as follows:
	;
	; [$.rsh]:[$.rsl] = (([$.o1h] * [$.o2h]) << 32) +
	;                   (([$.o1h] * [$.o2l]) << 16) +
	;                   (([$.o1l] * [$.o2h]) << 16) +
	;                   (([$.o1l] * [$.o2l]))
	;
	; Since the result is 32 bits, the (o1h * o2h) member can be omitted
	; entirely. Only the low 16 bits of (o1h * o2l) and (o1l * o2h) is
	; used, so no need to generate and use carry (high 16 bits) for those.

	mov x3,    [$.o1l]
	mul c:x3,  [$.o2l]
	xch [$.o1l], x3		; [$.rsl] gets result low
	mac x3,    [$.o2h]
	xch [$.o2l], x3		; [$.rsh] gets (o1l * o2h) + ((o1l * o2l) >> 16)
	mul x3,    [$.o1h]
	add x3,    [$.rsh]
	mov c,     x3
	mov x3,    [$.rsl]
	rfn



;
; Implementation of us_div32
;
us_div32_i:

.o1h	equ	0		; Operand 1, high
.o1l	equ	1		; Operand 1, low
.o2h	equ	2		; Operand 2, high
.o2l	equ	3		; Operand 2, low

	; Performing the 32 bit divide:
	;
	; c:x3 = us_rec32 {[$.o2h], [$.o2l]}
	; c:x3 = (c:x3 * [$.o1h]:[$.o1l]) >> 32
	; if ([$.o1h]:[$.o1l] >= ((c:x3 + 1) * [$.o2h]:[$.o2l]))
	;   c:x3 ++
	;
	; The correction step (if):
	; This is necessary since the reciprocal is not accurate (it is
	; smaller than the real reciprocal since being truncated to 0.32 fixed
	; point).

	mov c,     [$.o2h]
	jnz c,     .l0
	mov c,     [$.o2l]
	xne c,     1
	jms .l1			; For a divisor of 1, special return
	xne c,     0
	rfn x3,    0		; For a divisor of 0, return zero

.l0:	mov sp,    6

	; c:x3 = us_rec32 {[$.o2h], [$.o2l]}

	jfa us_rec32_i {[$.o2h], [$.o2l]}

	; c:x3 = (c:x3 * [$.o1h]:[$.o1l]) >> 32

	mov [$5],  x3
	mov [$4],  c
	mul c:x3,  [$.o1l]	; x3 (lowest 16 bit of result) is discardable
	mov x3,    [$4]
	mac c:x3,  [$.o1l]	; c:x3 *= [$.o1l], bits 16 - 47 of result
	xch c,     x3		; c: bits 16 - 31; x3: bits 32 - 47
	xch x3,    [$5]
	mac c:x3,  [$.o1h]	; c:x3: bits 16 - 47 of result, x3 discardable
	mov x3,    [$4]
	mac c:x3,  [$.o1h]	; c:x3: bits 32 - 63 of result
	mov [$4],  c
	add c:x3,  [$5]		; Add the "* [$.o1l]" part's bit 32 - 47
	add c,     [$4]

	; if ([$.o1h]:[$.o1l] >= ((c:x3 + 1) * [$.o2h]:[$.o2l]))
	;   c:x3 ++
	;
	; Here either c:x3 or [$.o2h]:[$.o2l] must be less than 0x10000, so
	; only occupying 16 bits. This can be exploited to simplify the
	; multiplication.

	jnz c,     .l2

	; Try to go for:
	; if ([$.o1h]:[$.o1l] >= ((x3 + 1) * [$.o2h]:[$.o2l]))
	;   x3 ++

	add x3,    1
	jnz x3,    .l3

	; Special: x3 was 0xFFFF. This case [$.o2h]:[$.o2l] is also <= 0xFFFF
	; since the number to be divided was less than 0x100000000.

	sub x3,    1

.l2:	; if ([$.o1h]:[$.o1l] >= ((c:x3 + 1) * [$.o2l]))
	;   c:x3 ++
	; This is transformed in order to reduce comparisons (the subtraction
	; result obviously needing check for > 16 bits):
	; if ([$.o1h]:[$.o1l] - (c:x3 * [$.o2l]) >= [$.o2l])
	;   c:x3 ++

	mov [$5],  x3
	mov [$4],  c
	mov [$.o2h],  c
	mul c:x3,  [$.o2l]
	xch x3,    [$.o2h]
	mac x3,    [$.o2l]	; x3:[$.o2h]: c:x3 * [$.o2l]
	xch x3,    [$.o2h]
	sub c:[$.o1l], x3
	mov x3,    [$.o1h]
	sbc x3,    [$.o2h]	; x3:[$.o1l]: [$.o1h]:[$.o1l] - (c:x3 * [$.o2l])
	jnz x3,    .l2a
	mov x3,    [$.o1l]
	xul x3,    [$.o2l]
	jms .l2a		; [$.o1l] >= [$.o2l]: Add 1
	mov c,     [$4]
	rfn x3,    [$5]
.l2a:	mov x3,    [$5]
	add c:x3,  1
	add c,     [$4]
	rfn

.l3:	; if ([$.o1h]:[$.o1l] >= ((x3 + 1) * [$.o2h]:[$.o2l]))
	;   x3 ++
	; Register x3 is already incremented, so multiply and compare only.

	mov [$5],  x3
	mov x3,    [$.o2l]
	mul c:x3,  [$5]
	mov [$4],  x3
	mov x3,    [$.o2h]
	mac c:x3,  [$5]		; x3:[$4]: (x3 + 1) * [$.o2h]:[$.o2l]
	jnz c,     .l3o		; Multiplication overflow?
	mov c,     [$5]		; Check [$.o1h]:[$.o1l] >= x3:[$4]
	xne x3,    [$.o1h]
	jms .l3e
	xul x3,    [$.o1h]
	sub c,     1		; x3 >  [$.o1h]: Remove the +1
	rfn c:x3,  c		; x3 <  [$.o1h]
.l3e:	mov x3,    [$4]
	xug x3,    [$.o1l]
	rfn c:x3,  c		; x3 <= [$.o1l]
.l3x:	sub c,     1		; x3 >  [$.o1l]: Remove the +1
	rfn c:x3,  c
.l3o:	mov c,     [$5]		; Multiplication overflow: Remove the +1
	jms .l3x

.l1:	; Special return for a divisor of 1

	mov c,     [$.o1h]
	rfn x3,    [$.o1l]



;
; Implementation of us_sin
;
us_sin_i:

.ang	equ	0		; Angle

	mov x3,    [$.ang]
	jms us_cos_i.entr



;
; Implementation of us_cos
;
us_cos_i:

.ang	equ	0		; Angle

	mov x3,    0x4000
	add x3,    [$.ang]

.entr:	; Entry point for us_sin

	shr c:x3,  7
	or  x3,    0xFE00	; up_sine, need direct value for comparisons

	; "Whole" angle from the table: return fast

	xne c,     0
	rfn x3,    [x3]		; "Whole" angles from the table

	; Do linear interpolation between 2 points

	xug x3,    0xFF7F	; 0xFF80 - 0xFFFF: Next value is larger
	xug x3,    0xFE7F	; 0xFE80 - 0xFF7F: Next value is smaller
	jms .inc		; 0xFE00 - 0xFE7F: Next value is larger

.dec:	xne x3,    0xFF00
	jms .crzn		; Special: Zero => Negative crossover
	neg c,     c		; Negate multiplier
	mov [$0],  c		; $0: Multiplier
	mov c,     [x3]		; c:  Low  (larger)
	mov x3,    [x3]		; x3: High (smaller)
	sub c,     x3
	mul c:c,   [$0]
	add x3,    c
	rfn c:x3,  x3

.inc:	xne x3,    0xFFFF
	jms .crnz		; Special: Negative => Zero crossover
	mov [$0],  c		; $0: Multiplier
	mov c,     [x3]		; c:  Low  (smaller)
	mov x3,    [x3]		; x3: High (larger)
	xch c,     x3
	sub c,     x3
	mul c:c,   [$0]
	add x3,    c
	rfn c:x3,  x3

.crzn:	add x3,    1
	mov x3,    [x3]
	neg x3,    x3
	mul c:x3,  c
	neg x3,    c
	rfn c:x3,  x3

.crnz:	mov x3,    [x3]
	neg x3,    x3
	neg c,     c
	mul c:x3,  c
	neg x3,    c
	rfn c:x3,  x3



;
; Implementation of us_sincos
;
us_sincos_i:

.ang	equ	0		; Angle

	jfa us_cos_i {[$.ang]}
	xch [$.ang], x3
	jfa us_sin_i {x3}
	mov c,     [$.ang]
	rfn



;
; Implementation of us_rec16
;
us_rec16_i:

.inp	equ	0		; Input

	; Algorithm:
	; x3 = 0xFFFF / [$.inp]
	; c  = x3 * (-[$.inp])      -- Real remainder
	; if (c == [$.inp])         -- Correction necessary
	;   c  = 0
	;   x3 ++
	;
	; Division by zero note: The "div" instruction returns 0xFFFF this
	; case. The correction is carried out, so producing a zero result.

	not x3,    0		; Load 0xFFFF
	div x3,    [$.inp]
	neg c,     [$.inp]
	mul c,     x3
	xeq c,     [$.inp]
	rfn
	add x3,    1
	rfn c:x3,  x3



;
; Implementation of us_rec32
;
us_rec32_i:

.inh	equ	0		; Input, high
.inl	equ	1		; Input, low

	mov sp,    4

	; Save registers & load divider. Stack positions 2 and 3 are used for
	; temporaries.

	xch [$0],  b		; Also loads divider high
	xch [$1],  a		; Also loads divider low
	psh x0, x1

	; Main branch out, favoring the most expensive paths first

	jnz b,     .brh
	xug a,     0x0100
	jms .brb		; Region 0x00000000 - 0x00000100
	xug a,     0x4000
	jms .br2		; Region 0x00000101 - 0x00004000
.brh:	xug b,     0x1000
	jms .br3		; Region 0x00004001 - 0x10000000
	xug b,     0x8000
	jms .br4		; Region 0x10000001 - 0x80000000
	mov c,     0
	mov x3,    1		; Region 0x80000001 - 0xFFFFFFFF: return is 1
	jms .exit
.brb:	xug 2,     a
	jms .br1		; Region 0x00000002 - 0x00000100
	mov c,     0
	mov x3,    1		; Region 0x00000000 - 0x00000001: return is 0
	jms .exit

.br4:	; Large numbers: a simple approximation with divide is OK. Just that
	; the Newton-Raphson (.br3) can not handle divisors equal or larger
	; than 0x20000000 due to the left shift of the divisor ("b:a") by 3 in
	; it's algorithm.
	; Algorithm:
	; x3 = 0xFFFF / (b + 1)     -- Divide with "(b:a >> 16) + 1"
	; x0:x1 = x3 * (-b:a)       -- Real remainder
	; if (x0:x1 >= b:a) x3++    -- Correction
	; c  = 0                    -- High part for result into c:x3
	
	mov x1,    b
	add x1,    1		; Divide with "(b:a >> 16) + 1"
	not x3,    0		; Load 0xFFFF
	div x3,    x1
	neg x1,    a		; x0:x1 = x3 * (-b:a)
	neg x0,    b
	xeq a,     0
	sub x0,    1
	mul c:x1,  x3
	mac x0,    x3
	sub c:x1,  a		; if (x0:x1 >= b:a) x3++ with subtraction
	sbc c:x0,  b
	add c,     1		; 0 if there was carry, 1 if not
	add x3,    c
	mov c,     0

	; OK, recoprocal got in "c:x3", exit

	jms .exit

.br1:	; Perform reciprocal calculation by 3 divides + 1 mul. In this layout
	; inputs from 1 to 0x100 can be processed (actually there is some
	; headroom above). This solver is in place primarily to shave off a
	; few instructions from the 0x100 - 0x4000 range algorithm which is
	; the most expensive region.
	; Algorithm:
	; b  = 0xFFFF / a           -- High part for "b:x3" result
	; x1 = (-b) * a             -- Real remainder
	; if (x1 == a)              -- Correction only needed this case
	;   b ++
	;   x1 = 0
	; x1 <<= 8
	; b:x3 += ((x1 / a) << 8)
	; x0    = ((x1 % a) << 8)
	; b:x3 +=   x0 / a
	; c:x3  = b:x3

	not b,     0		; Load 0xFFFF
	div b,     a
	neg x1,    b
	mul x1,    a
	xeq x1,    a
	jms .dna3
	add b,     1
	mov x1,    0
.dna3:	shl x1,    8

	div c:x1,  a
	mov x0,    c
	shl x0,    8
	shl c:x1,  8
	add b,     c
	mov x3,    x1

	div x0,    a
	add c:x3,  x0
	add c,     b

	; OK, recoprocal got in "c:x3", exit

	jms .exit

.br2:	; Perform reciprocal calculation by 9 divides + 1 mul. In this layout
	; inputs from 0x100 to 0x4000 can be processed (there is some headroom
	; above, but not enough to allow for example to cut a comparison in
	; the Newton-Raphson approximator block). Due to the start from 0x100,
	; shifting the division results with 8 or less to left do not produce
	; carry which is utilized in the algorithm.
	; Algorithm:
	; b  = 0xFFFF / a           -- High part for "b:x3" result
	; x1 = (-b) * a             -- Real remainder
	; if (x1 == a)              -- Correction only needed this case
	;   b ++
	;   x1 = 0
	; x1 <<= 2
	; b:x3 += ((x1 / a) << 14)
	; x0    = ((x1 % a) << 2)
	; b:x3 += ((x0 / a) << 12)
	; x1    = ((x0 % a) << 2)
	; b:x3 += ((x1 / a) << 10)
	; x0    = ((x1 % a) << 2)
	; b:x3 += ((x0 / a) << 8)
	; x1    = ((x0 % a) << 2)
	; b:x3 += ((x1 / a) << 6)
	; x0    = ((x1 % a) << 2)
	; b:x3 += ((x0 / a) << 4)
	; x1    = ((x0 % a) << 2)
	; b:x3 += ((x1 / a) << 2)
	; x0    = ((x1 % a) << 2)
	; b:x3 +=   x0 / a
	; c:x3  = b:x3

	not b,     0		; Load 0xFFFF
	div b,     a
	neg x1,    b
	mul x1,    a
	xeq x1,    a
	jms .dna9
	add b,     1
	mov x1,    0
.dna9:	shl x1,    2

	div c:x1,  a
	mov x0,    c
	shl x0,    2
	shl c:x1,  14
	add b,     c
	mov x3,    x1

	div c:x0,  a
	mov x1,    c
	shl x1,    2
	shl c:x0,  12
	add b,     c
	add c:x3,  x0
	add b,     c

	div c:x1,  a
	mov x0,    c
	shl x0,    2
	shl c:x1,  10
	add b,     c
	add c:x3,  x1
	add b,     c

	div c:x0,  a
	mov x1,    c
	shl x1,    2
	shl x0,    8		; Since 'a' is >= 0x100, no carry
	add c:x3,  x0
	add b,     c

	div c:x1,  a
	mov x0,    c
	shl x0,    2
	shl x1,    6		; Since 'a' is >= 0x100, no carry
	add c:x3,  x1
	add b,     c

	div c:x0,  a
	mov x1,    c
	shl x1,    2
	shl x0,    4		; Since 'a' is >= 0x100, no carry
	add c:x3,  x0
	add b,     c

	div c:x1,  a
	mov x0,    c
	shl x0,    2
	shl x1,    2		; Since 'a' is >= 0x100, no carry
	add c:x3,  x1
	add b,     c

	div x0,    a
	add c:x3,  x0
	add c,     b

	; OK, recoprocal got in "c:x3", exit

	jms .exit

.br3:	; Large branch set for approximating the result of the reciprocal. It
	; is set up so the two step Newton-Raphson will deviate at most 15
	; below the true result. There is no path longer than 5 steps, so with
	; all this takes about 60 cycles to process. The approximate is placed
	; in x1.

	mov x3,    a		; x0:x3 = b:a >> 3
	mov x0,    b
	shr c:x0,  3
	jnz x0,    .xdvj	; x0 >= 0x80000, approximate with division
	src x3,    3		; x3 is used for comparing

	; The branch block as output from nrbranch is optimized here: the leaf
	; selections are transformed from 5 instructions (7 words) to 3
	; instructions (5 words) with little impact (1 cycle) on performance.
	; This saves 23 words here (1 extra is needed to reset x1).

	mov x1,    0		; Start with zero for adding in leaf selectors
	xug x3,    0x23A6	; 0x23A6 < x3
	jms .x23a		;          x3 <= 0x23A6
	xug x3,    0x7071	; 0x7071 < x3
	jms .x707		; 0x23A6 < x3 <= 0x7071
	xug x3,    0x859E	; 0x859E < x3
	jms .x859		; 0x7071 < x3 <= 0x859E
.xdvj:	jms .xdiv		; Do approximation with division
.x859:	mov x1,    0x0F53
	jms .xend
.x707:	xug x3,    0x3C88	; 0x3C88 < x3 <= 0x7071
	jms .x3c8		; 0x23A6 < x3 <= 0x3C88
	xug x3,    0x516E	; 0x516E < x3 <= 0x7071
	jms .x516		; 0x3C88 < x3 <= 0x516E
	xug x3,    0x5F59	; 0x5F59 < x3 <= 0x7071
	mov x1,    0x0344	; 0x516E < x3 <= 0x5F59; x1 = 0x157A
	add x1,    0x1236
	jms .xend
.x516:	xug x3,    0x45FF	; 0x45FF < x3 <= 0x516E
	mov x1,    0x041B	; 0x3C88 < x3 <= 0x45FF; x1 = 0x1D41
	add x1,    0x1926
	jms .xend
.x3c8:	xug x3,    0x2E04	; 0x2E04 < x3 <= 0x3C88
	jms .x2e0		; 0x23A6 < x3 <= 0x2E04
	xug x3,    0x34A8	; 0x34A8 < x3 <= 0x3C88
	mov x1,    0x0510	; 0x2E04 < x3 <= 0x34A8; x1 = 0x26E4
	add x1,    0x21D4
	jms .xend
.x2e0:	xug x3,    0x286B	; 0x286B < x3 <= 0x2E04
	mov x1,    0x062A	; 0x23A6 < x3 <= 0x286B; x1 = 0x32AA
	add x1,    0x2C80
	jms .xend
.x23a:	xug x3,    0x0EEE	; 0x0EEE < x3 <= 0x23A6
	jms .x0ee		;          x3 <= 0x0EEE
	xug x3,    0x1678	; 0x1678 < x3 <= 0x23A6
	jms .x167		; 0x0EEE < x3 <= 0x1678
	xug x3,    0x1C19	; 0x1C19 < x3 <= 0x23A6
	jms .x1c1		; 0x1678 < x3 <= 0x1C19
	xug x3,    0x1F98	; 0x1F98 < x3 <= 0x23A6
	mov x1,    0x075F	; 0x1C19 < x3 <= 0x1F98; x1 = 0x40D0
	add x1,    0x3971
	jms .xend
.x1c1:	xug x3,    0x1918	; 0x1918 < x3 <= 0x1C19
	mov x1,    0x08B9	; 0x1678 < x3 <= 0x1918; x1 = 0x519A
	add x1,    0x48E1
	jms .xend
.x167:	xug x3,    0x1235	; 0x1235 < x3 <= 0x1678
	jms .x123		; 0x0EEE < x3 <= 0x1235
	xug x3,    0x1436	; 0x1436 < x3 <= 0x1678
	mov x1,    0x0A2E	; 0x1235 < x3 <= 0x1436; x1 = 0x6550
	add x1,    0x5B22
	jms .xend
.x123:	xug x3,    0x1074	; 0x1074 < x3 <= 0x1235
	mov x1,    0x0BFC	; 0x0EEE < x3 <= 0x1074; x1 = 0x7C72
	add x1,    0x7076
	jms .xend
.x0ee:	xug x3,    0x0A68	; 0x0A68 < x3 <= 0x0EEE
	jms .x0a6		;          x3 <= 0x0A68
	xug x3,    0x0C62	; 0x0C62 < x3 <= 0x0EEE
	jms .x0c6		; 0x0A68 < x3 <= 0x0C62
	xug x3,    0x0D94	; 0x0D94 < x3 <= 0x0EEE
	mov x1,    0x0DA5	; 0x0C62 < x3 <= 0x0D94; x1 = 0x96CA
	add x1,    0x8925
	jms .xend
.x0c6:	xug x3,    0x0B56	; 0x0B56 < x3 <= 0x0C62
	mov x1,    0x0F44	; 0x0A68 < x3 <= 0x0B56; x1 = 0xB49C
	add x1,    0xA558
	jms .xend
.x0a6:	xug x3,    0x08D3	; 0x08D3 < x3 <= 0x0A68
	jms .x08d		;          x3 <= 0x08D3
	xug x3,    0x098F	; 0x098F < x3 <= 0x0A68
	mov x1,    0x1171	; 0x08D3 < x3 <= 0x098F; x1 = 0xD62E
	add x1,    0xC4BD
	jms .xend
.x08d:	xug x3,    0x0826	; 0x0826 < x3 <= 0x08D3
	mov x1,    0x133C	;          x3 <= 0x0826; x1 = 0xFB3B
	add x1,    0xE7FF
	jms .xend

.xdiv:	; Approximate using a division into x1.

	mov x3,    b
	add x3,    1		; Divide with "(b:a >> 16) + 1"
	not x1,    0		; Load 0xFFFF
	div x1,    x3
	shr x1,    2

.xend:	; Prepare divider in "b:a" for further work:
	; [$2]:[$3] = b:a << 3
	; b:a = -b:a << 2
	; Above it is prepared for the post-correcting restoring division,
	; below for the Newton-Raphson search, which is shifted 2 to right so
	; 16 bit operations can perform it.

	shl c:a,   3
	slc b,     3
	mov [$2],  b
	mov [$3],  a
	shr c:b,   1
	src a,     1
	neg b,     b
	neg a,     a
	xeq a,     0
	sub b,     1		; 'b' negated for "-b:a"

	; Run 2 iterations of Newton-Raphson style reciprocal search, then
	; calculate remainder as follows:
	; x1 += (x1 * (((-(b:a << 2)) * x1) >> 16)) >> 16
	; x1 += (x1 * (((-(b:a << 2)) * x1) >> 16)) >> 16
	; b:a =        ((-(b:a << 2)) * x1)
	; Takes approx. 140 cycles

	mov x3,    a		; x3  = ((-(b:a << 2)) * x1) >> 16
	mul c:x3,  x1
	mov x3,    b
	mac x3,    x1

	mul c:x3,  x1		; x1 += (x3 * x1) >> 16
	add x1,    c

	mov x3,    a		; x3  = ((-(b:a << 2)) * x1) >> 16
	mul c:x3,  x1
	mov x3,    b
	mac x3,    x1

	mul c:x3,  x1		; x1 += (x3 * x1) >> 16
	add x1,    c

	mul c:a,   x1		; b:a = ((-(b:a << 2)) * x1)
	mac b,     x1

	; Shift up current result into x0:x1.

	shl c:x1,  2
	mov x0,    c

	; 4 step restoring division to fix up to 15 difference. The algorithm
	; is roughly as follows:
	; b:a -= [$2]:[$3]
	; if (carry)  b:a   += [$2]:[$3]
	; else        x0:x1 += 8
	; [$2]:[$3] >>= 1
	; if (carry)  b:a   += [$2]:[$3]
	; else        x0:x1 += 4
	; [$2]:[$3] >>= 1
	; if (carry)  b:a   += [$2]:[$3]
	; else        x0:x1 += 2
	; [$2]:[$3] >>= 1
	; if (!carry) x0:x1 += 1

	mov x3,    1		; For shifting stack relatives

	sub c:a,   [$3]
	sbc c:b,   [$2]
	xbs c,     0
	jms .ra3		; No carry: could be subtracted
	add c:a,   [$3]
	adc b,     [$2]

	shr c:[$2], x3
	src [$3],  x3
	sub c:a,   [$3]
	sbc c:b,   [$2]
	xbs c,     0
	jms .ra2		; No carry: could be subtracted
.rc2:	add c:a,   [$3]
	adc b,     [$2]

	shr c:[$2], x3
	src [$3],  x3
	sub c:a,   [$3]
	sbc c:b,   [$2]
	xbs c,     0
	jms .ra1		; No carry: could be subtracted
.rc1:	add c:a,   [$3]
	adc b,     [$2]

	shr c:[$2], x3
	src [$3],  x3
	sub c:a,   [$3]
	sbc c:b,   [$2]
	xbs c,     0
	jms .ra0		; No carry: could be subtracted
	jms .rend

.ra3:	add c:x1,  8
	add x0,    c

	shr c:[$2], x3
	src [$3],  x3
	sub c:a,   [$3]
	sbc c:b,   [$2]
	xbc c,     0
	jms .rc2		; Carry: need to restore
.ra2:	add c:x1,  4
	add x0,    c

	shr c:[$2], x3
	src [$3],  x3
	sub c:a,   [$3]
	sbc c:b,   [$2]
	xbc c,     0
	jms .rc1		; Carry: need to restore
.ra1:	add c:x1,  2
	add x0,    c

	shr c:[$2], x3
	src [$3],  x3
	sub c:a,   [$3]
	sbc c:b,   [$2]
	xbc c,     0
	jms .rend		; Carry: don't add (last iteration)
.ra0:	add c:x1,  1
	add x0,    c
.rend:

	; Move recoprocal from "x0:x1" into "c:x3" and exit

	mov c,     x0
	mov x3,    x1

.exit:	; Restore regs & return

	mov b,     [$0]
	mov a,     [$1]
	pop x0, x1
	rfn



;
; Implementation of us_sqrt16
;
us_sqrt16_i:

.inp	equ	0		; Input

	; Set up, and calculate first 2 digit of square root

	mov x3,    1
	add c:[$.inp], x3	; Easier to compare this way
	xeq c,     0
	rfn c:x3,  0x00FF	; However 0xFFFF needs special return

	mov c,      [$.inp]
	mov x3,     0
	xug 0x4001, c
	jms .l0			; [$.inp] >= 0x4000 (0x80 ^ 2)
	xug 0x1001, c
	bts x3,     6		; [$.inp] >= 0x1000 (0x40 ^ 2)
	jms .st
.l0:	bts x3,     7
	xug 0x9001, c
	bts x3,     6		; [$.inp] >= 0x9000 (0xC0 ^ 2)

.st:	; The 13 further digits are calculated as follows:
	; The digit of interest is set in the return (x3)
	; It is raised to square (x3 ^ 2)
	; Then (x3 ^ 2) > [$.inh]:[$.inl] (original input) is checked, if the
	; check passes, the digit can not be set (so cleared back).
	; [$.inh]:[$.inl] needed an increment so the check can be performed
	; with a subtract which would give a ">=" relation by carry.

	bts x3,    5
	mov c,     x3
	mul c,     c
	xug [$.inp], c
	btc x3,    5

	bts x3,    4
	mov c,     x3
	mul c,     c
	xug [$.inp], c
	btc x3,    4

	bts x3,    3
	mov c,     x3
	mul c,     c
	xug [$.inp], c
	btc x3,    3

	bts x3,    2
	mov c,     x3
	mul c,     c
	xug [$.inp], c
	btc x3,    2

	bts x3,    1
	mov c,     x3
	mul c,     c
	xug [$.inp], c
	btc x3,    1

	bts x3,    0
	mov c,     x3
	mul c,     c
	xug [$.inp], c
	btc x3,    0

	rfn c:x3,  x3



;
; Implementation of us_sqrt32
;
us_sqrt32_i:

.inh	equ	0		; Input, high
.inl	equ	1		; Input, low

	; Save registers

	psh a, b

	; Set up, and calculate first 3 digits of square root

	mov a,     [$.inh]	; Save for first comparisons
	mov x3,    1
	add c:[$.inl], x3
	mov x3,    0		; Also initial return value
	adc c:[$.inh], x3	; Easier to compare this way
	xeq c,     0
	jms .ffff		; However 0xFFFFFFFF needs special return

	xug 0x4000, a
	jms .l0			; [$.inh]:[$.inl] >= 0x40000000 (0x8000 ^ 2)
	xug 0x1000, a
	jms .l1			; [$.inh]:[$.inl] >= 0x10000000 (0x4000 ^ 2)
	xug 0x0400, a
	bts x3,    13		; [$.inh]:[$.inl] >= 0x04000000 (0x2000 ^ 2)
	jms .st
.l0:	bts x3,    15
	xug 0x9000, a
	jms .l2			; [$.inh]:[$.inl] >= 0x90000000 (0xC000 ^ 2)
	xug 0x6400, a
	bts x3,    13		; [$.inh]:[$.inl] >= 0x64000000 (0xA000 ^ 2)
	jms .st
.l1:	bts x3,    14
	xug 0x2400, a
	bts x3,    13		; [$.inh]:[$.inl] >= 0x24000000 (0x6000 ^ 2)
	jms .st
.l2:	bts x3,    14
	xug 0xC400, a
	bts x3,    13		; [$.inh]:[$.inl] >= 0xC4000000 (0xE000 ^ 2)

.st:	; The 13 further digits are calculated as follows:
	; The digit of interest is set in the return (x3)
	; It is raised to square (x3 ^ 2)
	; Then (x3 ^ 2) > [$.inh]:[$.inl] (original input) is checked, if the
	; check passes, the digit can not be set (so cleared back).
	; [$.inh]:[$.inl] needed an increment so the check can be performed
	; with a subtract which would give a ">=" relation by carry.

	bts x3,    12
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    12

	bts x3,    11
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    11

	bts x3,    10
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    10

	bts x3,    9
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    9

	bts x3,    8
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    8

	bts x3,    7
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    7

	bts x3,    6
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    6

	bts x3,    5
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    5

	bts x3,    4
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    4

	bts x3,    3
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    3

	bts x3,    2
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    2

	bts x3,    1
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    1

	bts x3,    0
	mov a,     x3
	mul c:a,   a
	mov b,     c
	sub c:a,   [$.inl]
	sbc c:b,   [$.inh]
	xne c,     0
	btc x3,    0

.exit:	; Restore regs & return

	pop a, b
	rfn c:x3,  x3

.ffff:	mov x3,    0xFFFF	; 0xFFFF return for max input
	jms .exit
