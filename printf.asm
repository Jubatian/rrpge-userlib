;
; RRPGE User Library functions - Printf and string support
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; The Printf functionality, and the other minor string assistance functions
; here use the character readers and writers to work on string data, using
; their common interface functions (so it is possible to choose the
; appropriate reader or writer, and to write user provided readers and
; writers).
;


include "rrpge.asm"

section code



;
; Implementation of us_strcpynz
;
us_strcpynz_i:
.twr	equ	0		; Target character writer
.srd	equ	1		; Source character reader
.idx	equ	2		; String index in source reader

	jfa us_cr_setsi_i {[$.srd], [$.idx]}
	jfa us_cw_init_i  {[$.twr]}
	jms .st
.lp:	jfa us_cw_setnc_i {[$.twr], c, x3}
.st:	jfa us_cr_getnc_i {[$.srd]}
	jnz x3,    .lp
	jnz c,     .lp
	rfn c:x3,  0



;
; Implementation of us_strcpy
;
us_strcpy_i:
.twr	equ	0		; Target character writer
.srd	equ	1		; Source character reader
.idx	equ	2		; String index in source reader

	jfa us_strcpynz_i {[$.twr], [$.srd], [$.idx]}
.entr:	jfa us_cw_setnc_i {[$.twr], 0, 0}
	rfn c:x3,  0



;
; Implementation of us_printfnz
;
us_printfnz_i:
.twr	equ	0		; Target character writer
.srd	equ	1		; Source character reader
.idx	equ	2		; String index in source reader
.pr0	equ	3		; First parameter (up to 13)

	jmr c,     us_printf_core_i
	rfn c:x3,  0



;
; Implementation of us_printf
;
us_printf_i:
.twr	equ	0		; Target character writer
.srd	equ	1		; Source character reader
.idx	equ	2		; String index in source reader
.pr0	equ	3		; First parameter (up to 13)

	jmr c,     us_printf_core_i
	jms us_strcpy_i.entr



;
; Internal: Printf core logic. Accepts printf parameters, except that C is
; also passed as link register: address to return to.
;
us_printf_core_i:
.twr	equ	0		; Target character writer
.srd	equ	1		; Source character reader
.idx	equ	2		; String index in source reader
.pr0	equ	3		; First parameter (up to 13)

.ret	equ	2		; Return address (reuses .idx)
.tmp	equ	3		; Temporary storage (reuses .pr0)

	mov sp,    23

	; Save CPU regs

	mov x3,    16
	mov [$x3], a
	mov [$x3], b
	mov [$x3], d
	mov [$x3], x0
	mov [$x3], x1
	mov [$x3], x2
	mov [$x3], xm

	; Prepare for character processing

	mov xm2,   PTR16I
	mov x2,    3		; Current parameter load offset
	xch [$.idx], c		; Populate [$.ret] with return to address
	jfa us_cr_setsi_i {[$.srd], c}
	jfa us_cw_init_i  {[$.twr]}

.l0:	; Main character processing loop.

	jfa us_cr_getnc_i {[$.srd]}

	; If it is some non-ASCII-7 character, just output it

	jnz c,     .cou0	; C nonzero: Definitely not ASCII-7

	; End of string?

	xne x3,    0
	jms .exit


	; If it is a '\', then read in special character to process. The '\'
	; is never displayed, neither any character escaped with it except if
	; it is a valid control code.

	xeq x3,    '\\'
	jms .nsc		; Not a special character
	jfa us_cr_getnc_i {[$.srd]}
	jnz c,     .cds2	; Not a valid escape, discard
	xeq x3,    '"'		; Double quote, can go on to char. output
	xne x3,    '\\'
.cou0:	jms .cout		; Backslash, can go on to char. output
	xne x3,    'n'
	jms .enl		; Newline
	xne x3,    'r'
	jms .ecr		; Carriage return
	xne x3,    't'
	jms .etb		; Horizontal tab
	xne x3,    'b'
	jms .ebk		; Backspace
.cds2:	jms .cds		; Not a valid escape, discard (or end of string)

.enl:	mov x3,    '\n'
	jms .cout
.ecr:	mov x3,    '\r'
	jms .cout
.etb:	mov x3,    '\t'
	jms .cout
.ebk:	mov x3,    0x08		; Backspace
	jms .cout


.nsc:	; If it is a '%', then some format string, also taking a parameter.
	; Parameters come from [$x2].

	xeq x3,    '%'
	jms .atr		; Not a format specifier
	jfa us_cr_getnc_i {[$.srd]}
	jnz c,     .cds2	; Not a valid format specifier, discard
	xne x3,    '%'
	jms .cout		; '%', just output it ("%%")

	; Collect format string. The following registers will be used:
	; A: Flags:
	; bit 0: Left justify if set
	; bit 1: Add positive sign if set (zero will still show without sign)
	; bit 2: Insert space where the sign would occur if no sign
	; bit 3: Pad the number with zeroes (if right justified)
	; bit 4: (Support: Negative flag)
	; bit 5: (Support: Request lowercase hexa output)
	; bit 6: (Support: Need a sign character space)
	; B: Minimal width to use for the output
	; D: Type:
	; 0: String
	; 1: Character, 16 bit
	; 2: Signed decimal, 16 bit
	; 3: Unsigned decimal, 16 bit
	; 4: Lowercase hexa, 16 bit
	; 5: Uppercase hexa, 16 bit
	; bit 3: If set, 32 bit input (except for String)

.ffl:	; Look for flags (multiple flags may be present)

	mov a,     0

.ff0:	mov d,     a		; A flag is only accepted if it changes state
	xne x3,    '-'
	bts a,     0		; Left justify
	xne x3,    '+'
	bts a,     1		; Add positive sign
	xne x3,    ' '
	bts a,     2		; Insert space for no-sign
	xne x3,    '0'
	bts a,     3		; Pad the number with zeroes
	xne d,     a
	jms .fwd		; No state change occured: Not a valid flag, go on
	jfa us_cr_getnc_i {[$.srd]}
	jnz c,     .cds1	; Not a valid format specifier, discard
	jms .ff0		; Go on trying to read flags

.fwd:	; Look for width specifier

	mov b,     0

.fw0:	xul x3,    0x30
	xul x3,    0x3A
	jms .fsp		; X3 < '0' (0x30) or X3 > '9' (0x39), go for specifier
	and x3,    0x0F
	mul b,     10
	add b,     x3		; Minimal width set
	jfa us_cr_getnc_i {[$.srd]}
	jnz c,     .cds1	; Not a valid specifier, discard
	jms .fw0		; Go on reading width specifier

.fsp:	; Look for specifier ("long")

	mov d,     0

	xeq x3,    'l'
	jms .fft		; Not "long"
	bts d,     3		; Add "long"
	jfa us_cr_getnc_i {[$.srd]}

.fft:	; Look for format specifier

	or  d,     7		; Start as "No type found"

	xeq x3,    'd'		; Signed decimal
	xne x3,    'i'
	and d,     10		; Signed decimal
	xne x3,    'u'
	and d,     11		; Unsigned decimal
	xne x3,    'x'
	and d,     12		; Lowercase hexa
	xne x3,    'X'
	and d,     13		; Uppercase hexa
	xne x3,    'c'
	and d,     9		; Character
	xne x3,    's'
	and d,     8		; String
	mov c,     d
	and c,     7
	xne c,     7
.cds1:	jms .cds		; Not a valid type specifier, discard

	; The format specification is acquired in A:B:D.

	xeq d,     0		; Process string
	xne d,     8
	jms .fst		; Process string (long specifier has no effect)
	xne d,     1
	jms .fcs		; Process char (16 bit)
	xne d,     9
	jms .fcl		; Process char (32 bit)
	xne d,     2
	jms .fis		; Process signed decimal (16 bit)
	xne d,     10
	jms .fil		; Process signed decimal (32 bit)
	xne d,     3
	jms .fus		; Process unsigned decimal (16 bit)
	xne d,     11
	jms .ful		; Process unsigned decimal (32 bit)
	xne d,     4
	jms .fxs		; Process hexa, lowercase (16 bit)
	xne d,     12
	jms .fxl		; Process hexa, lowercase (32 bit)
	xne d,     5
	jms .fhs		; Process hexa, uppercase (16 bit)
	jms .fhl		; Process hexa, uppercase (32 bit)

.fst:	; String processing: do an strcpynz using the next two parameters for
	; source string

	jfa us_strcpynz_i {[$.twr], [$x2], [$x2]}
	jms .l0

.fcs:	; 16 bit character: one parameter, just output it to the writer

	jfa us_cw_setnc_i {[$.twr],     0, [$x2]}
	jms .l0

.fcl:	; 32 bit character: two parameters, just output them to the writer

	jfa us_cw_setnc_i {[$.twr], [$x2], [$x2]}
	jms .l0

.fis:	; 16 bit signed decimal: Load and go on to common signed integer

	mov c,     0
	mov x3,    [$x2]
	xbc x3,    15
	not c,     0		; Negative: High is also negative
	jms .icm

.fil:	; 32 bit signed decimal

	mov c,     [$x2]
	mov x3,    [$x2]

.icm:	; Check for sign, if any, set flag for it, and reduce total chars
	; output, then negate (absolute value).

	xbs c,     15
	jms .ucm		; Go to unsigned common processing
	neg x3,    x3
	neg c,     c
	xeq x3,    0
	sub c,     1		; Absolute value got
	bts a,     4		; Flag for negative sign set
	jms .ucm		; Go to unsigned common processing

.fus:	; 16 bit unsigned decimal

	mov c,     0
	jms .full

.ful:	; 32 bit unsigned decimal

	mov c,     [$x2]
.full:	mov x3,    [$x2]

.ucm:	; Unsigned common (actually with signed, 'a', bit 4 indicates the
	; necessity of a negative sign). Convert to BCD, so can be forwarded
	; to hexadecimal output.

	jfa us_printf_tobcd_i {c, x3}
	jms .hcm

.fxs:	; 16 bit lowercase hexa

	bts a,     5		; Lowercase
	jms .fhs

.fxl:	; 32 bit lowercase hexa

	bts a,     5		; Lowercase
	jms .fhl

.fhs:	; 16 bit uppercase hexa

	mov c,     0
	jms .fhll

.fhl:	; 32 bit uppercase hexa

	mov c,     [$x2]
.fhll:	mov x3,    [$x2]
	mov d,     0		; Uppermost 4 digits zero (BCD uses it)

.hcm:	; Hexadecimal (truly, all numeric) common processing. First determine
	; whether a character for sign ('+', '-' or ' ') will be taken or not,
	; and reduce total char count if any.

	jnz d,     .hnz		; Test zero to see if the number has no sign at all
	jnz c,     .hnz
	xne x3,    0
	btc a,     1		; Zero: Positive sign can not be added!
.hnz:	xne b,     0
	jms .hns		; Only take the char if it can be taken
	xbc a,     4
	bts a,     6		; Has negative sign: need a char for it!
	xbc a,     1
	bts a,     6		; Has positive sign: need a char for it!
	xbc a,     2
	bts a,     6		; Inserts space if no sign: need a char for it!
	xbc a,     6
	sub b,     1		; Take that char

.hns:	; There are up to 10 digits in the hexa (or BCD) source. Shift stuff
	; out on the left until getting to the first valid digit. 'X0' will
	; store remaining digits, 'X1' will replace 'C' so it can be used for
	; carry.

	mov x1,    c
	mov x0,    10
	shl c:x3,  8
	slc c:x1,  8
	slc d,     8		; Shift number up (no carry-out)
.hdc:	xul d,     0x1000
	jms .hde		; Highest digit is nonzero, number size got
	shl c:x3,  4
	slc c:x1,  4
	slc d,     4
	sub x0,    1
	xeq x0,    1		; At last digit, done (next iteration would fail on zero)
	jms .hdc

.hde:	; Calculate number of spaces or zeros required as padding (either at
	; the beginning or end depending on alignment for spaces).

	sub b,     x0		; Subtract no. of digits to output
	xbc b,     15		; Turned negative?
	mov b,     0		; If so, no spaces

	; Prepare for character output. 'x2' is freed up to be able to place
	; the number to output in d:x1:x2, so the function calls can clobber
	; c and x3.

	mov [$.tmp], x2		; Save away the current parameter pointer
	mov x2,    x3

	; If right alignment is selected with spaces, output these

	xeq b,     0		; Any chars to pad with?
	xbc a,     0
	jms .hsg		; Left justify was selected
	xbc a,     3
	jms .hsg		; Right justify, but with zeros
.hl0:	jfa us_cw_setnc_i {[$.twr], 0, ' '}
	sub b,     1
	jnz b,     .hl0

.hsg:	; Output sign if any is to be output ('+', '-', ' ' or nothing).
	; Note: The character for sign is already taken, so 'b' has to be
	; left alone here.

	mov c,     0x16		; Sign request bits
	and c,     a
	xne c,     0
	jms .hzp		; No sign to add
	xbc a,     2
	mov c,     ' '		; Space: Lowest priority
	xbc a,     1
	mov c,     '+'		; Positive
	xbc a,     4
	mov c,     '-'		; Negative
	jfa us_cw_setnc_i {[$.twr], 0, c}

.hzp:	; If zero padding was requested, output these zeroes

	xeq b,     0		; Any char to pad with?
	xbs a,     3
	jms .hnm		; No zero padding selected
.hl1:	jfa us_cw_setnc_i {[$.twr], 0, '0'}
	sub b,     1
	jnz b,     .hl1

.hnm:	; Output the number (hexadecimal or BCD)

.hl2:	shl c:x2,  4
	slc c:x1,  4
	slc c:d,   4		; Rotate next digit off
	xul c,     10
	add c,     7		; 10 + 7 + 48 = 65 ('A')
	add c,     48		; 48 (0x30): '0', bit 5 already set
	xbc a,     5
	bts c,     5		; 97 (0x61): 'a'
.hnmo:	jfa us_cw_setnc_i {[$.twr], 0, c}
	sub x0,    1		; One digit less to go
	jnz x0,    .hl2

	; If padding bytes are still present, it was a left aligned number
	; with spaces, so output these accordingly.

	xne b,     0
	jms .hen
.hl3:	jfa us_cw_setnc_i {[$.twr], 0, ' '}
	sub b,     1
	jnz b,     .hl3

.hen:	; Clean up after hex output and loop

	mov x2,    [$.tmp]	; Restore parameter pointer
	jms .l0


.atr:	; If it is a '$', then an attribute. Otherwise nothing else, just
	; output it.

	xeq x3,    '$'
	jms .cout		; Not an attribute, nothing else, output char
	jfa us_cr_getnc_i {[$.srd]}
	jnz c,     .cds0	; Not a valid attribute specifier, discard
	xne x3,    '$'
	jms .cout		; '$', just output it ("$$")

	; Store away attribute character in A, it could be anything. Then go
	; on, check next character for attribute value type.

	mov a,     x3
	mov b,     0		; Attribute value under construction
	jfa us_cr_getnc_i {[$.srd]}
	jnz c,     .cds0	; Not a valid attribute type, discard
	xeq x3,    'd'
	xne x3,    'i'
	jms .adc		; Decimal number
	xne x3,    'u'
	jms .adc		; Decimal number
	xeq x3,    'x'
	xne x3,    'X'
	jms .ahx		; Hexadecimal number
	xne x3,    'c'
	jms .ach		; Single character
	xne x3,    ';'
	jms .adf		; Restore default / previous (no value provided)
	jms .ada		; Assume decimal

.adc:	; Decimal number

.adl:	jfa us_cr_getnc_i {[$.srd]}
.ada:	jnz c,     .cds0	; Not a valid attribute value, discard
	xne x3,    ';'
	jms .aen		; End of value and attribute; done.
	xul x3,    48		; '0'
	xul x3,    58		; '9' + 1
.cds0:	jms .cds		; Not a valid type / decimal first char
	and x3,    0xF
	mul b,     10
	add b,     x3
	jms .adl

.ahx:	; Hexadecimal number

.ahl:	jfa us_cr_getnc_i {[$.srd]}
	jnz c,     .cds		; Not a valid attribute value, discard
	xne x3,    ';'
	jms .aen		; End of value and attribute; done.
	xul x3,    48		; '0'
	xul x3,    58		; '9' + 1
	jms .ah0		; Not between 0-9 inclusive
	and x3,    0xF
	jms .ahc
.ah0:	xul x3,    65		; 'A'
	xul x3,    71		; 'F' + 1
	jms .ah1		; Not between A-F inclusive
	sub x3,    55
	jms .ahc
.ah1:	xul x3,    97		; 'a'
	xul x3,    103		; 'f' + 1
	jms .cds		; Not a valid attribute value, discard
	sub x3,    87
.ahc:	shl b,     4
	add b,     x3
	jms .ahl

.ach:	; Single character

	jfa us_cr_getnc_i {[$.srd]}
	jnz c,     .cds		; Not a valid attribute value, discard
	xne x3,    ';'
	jms .aen		; End of value and attribute; done.
	xug x3,    0x1F
	jms .cds		; Not a valid attribute value (control char), discard
	mov b,     x3
	jfa us_cr_getnc_i {[$.srd]}
	xne c,     0
	xeq x3,    ';'
	jms .cds		; Must end here.

.aen:	; Attribute acquired in 'a', value in 'b', output it

	jfa us_cw_setst_i{[$.twr], a, b}
	jms .l0

.adf:	; Restore default was asked for attribute 'a', do it

	jfa us_cw_setst_i{[$.twr], a}
	jms .l0


.cds:	; Discard character (invalid escape, format or attribute string)

	jnz c,     .l00
	jnz x3,    .l00
	jms .exit		; End of input string (may happen)

.cout:	; OK, in C:X3, a valid character is listed. Output it.

	jfa us_cw_setnc_i {[$.twr], c, x3}
.l00:	jms .l0

.exit:	; Restore CPU regs & return

	mov x3,    16
	mov a,     [$x3]
	mov b,     [$x3]
	mov d,     [$x3]
	mov x0,    [$x3]
	mov x1,    [$x3]
	mov x2,    [$x3]
	mov xm,    [$x3]
	jma [$.ret]



;
; Internal: Converts a 32 bit input to BCD, result produced in d:c:x3, padded
; to left.
;
us_printf_tobcd_i:
.inh	equ	0		; Input, high
.inl	equ	1		; Input, low

	; Save CPU regs & Load inputs

	mov sp,    4
	mov [$2],  a
	xch [$.inh], x1
	xch [$.inl], x0
	mov [$3],  x2
	mov x2,    32		; Number of steps remaining (32 bit input)

	; Produce result in d:a:x3 first, 'c' is needed for carry-overs

	mov d,     0
	mov a,     0
	mov x3,    0

	; First do "empty" left shifts until getting something useful. Shift
	; with 4, since the first 4 valid shift-ins into the BCD do not need
	; any correction (first correction is necessary on the fourth). This
	; way smaller numbers get processed a lot faster.

	jms .l1
.l0:	jnz c,     .l2
.l1:	shl c:x0,  4
	slc c:x1,  4
	sub x2,    4
	jnz x2,    .l0
	mov x3,    c
	xul x3,    10		; Input is between 0 and 15, simple
	add x3,    6		; Just correct it for 10-15.
	jms .fin		; Done
.l2:	mov x3,    c

	xul x3,    4		; Do some extra shift-ins, faster if possible
	jms .s0
	shl c:x0,  2
	slc c:x1,  2
	slc x3,    2
	sub x2,    2
.s0:	xul x3,    8
	jms .s1
	shl c:x0,  1
	slc c:x1,  1
	slc x3,    1
	sub x2,    1
.s1:	xul x3,    10		; Do first correction (note: x2 nonzero here)
	add x3,    6

.d16:	; Pre-correct and shift for 16 bit (4 digit) BCD. Faster, do it until
	; possible.

	jnz a,     .d32		; Carry-out (in prev. loop), so continue in 32 bits

	; Pre-correct steps. This transforms 5,6,7,8,9 digits to 8,9,10,11,12:
	; no carry here, but shift will produce a carry proper where
	; correction was made, leaving the correct BCD digit in place.

	mov c,     0x000F	; Digit 10^0
	and c,     x3
	xul c,     0x0005
	add x3,    0x0003
	mov c,     0x00F0	; Digit 10^1
	and c,     x3
	xul c,     0x0050
	add x3,    0x0030
	mov c,     0x0F00	; Digit 10^2
	and c,     x3
	xul c,     0x0500
	add x3,    0x0300
	xul x3,    0x5000	; Digit 10^3
	add x3,    0x3000

	; Shift next bit in. This may produce a carry-out, indicating need to
	; start filling in higher digits.

	shl c:x0,  1
	slc c:x1,  1
	slc c:x3,  1
	slc a,     1

	sub x2,    1
	jnz x2,    .d16
	jms .fin		; Done, didn't need 32 bit processing

.d32:	; Pre-correct and shift for 40 bit (10 digit) BCD. Note: from a 32 bit
	; input, only up to 10 decimal digits may be produced (4294967295).

	; Pre-correct steps. This transforms 5,6,7,8,9 digits to 8,9,10,11,12:
	; no carry here, but shift will produce a carry proper where
	; correction was made, leaving the correct BCD digit in place.

	mov c,     0x000F	; Digit 10^0
	and c,     x3
	xul c,     0x0005
	add x3,    0x0003
	mov c,     0x00F0	; Digit 10^1
	and c,     x3
	xul c,     0x0050
	add x3,    0x0030
	mov c,     0x0F00	; Digit 10^2
	and c,     x3
	xul c,     0x0500
	add x3,    0x0300
	xul x3,    0x5000	; Digit 10^3
	add x3,    0x3000
	mov c,     0x000F	; Digit 10^4
	and c,     a
	xul c,     0x0005
	add a,     0x0003
	mov c,     0x00F0	; Digit 10^5
	and c,     a
	xul c,     0x0050
	add a,     0x0030
	mov c,     0x0F00	; Digit 10^6
	and c,     a
	xul c,     0x0500
	add a,     0x0300
	xul a,     0x5000	; Digit 10^7
	add a,     0x3000
	mov c,     0x000F	; Digit 10^8
	and c,     d
	xul c,     0x0005
	add d,     0x0003	; Note: Digit 10^9 doesn't ever need correction

	; Shift next bit in.

	shl c:x0,  1
	slc c:x1,  1
	slc c:x3,  1
	slc c:a,   1
	slc d,     1

	sub x2,    1
	jnz x2,    .d32		; Process until the whole (32 bit) input number is done.

.fin:	; BCD number generated, finish and return.

	mov c,     a		; Result in d:c:x3
	mov a,     [$2]
	mov x1,    [$.inh]
	mov x0,    [$.inl]
	mov x2,    [$3]
	rfn
