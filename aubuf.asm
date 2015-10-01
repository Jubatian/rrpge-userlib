;
; RRPGE User Library functions - Audio buffer management
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
; Uses the following CPU RAM locations:
;
; 0xFDAE: Buffer size as 512 bit << value.
; 0xFDAF: Block size within buffer as 512 bit << value.
; 0xFDB0: Current write offset in buffer.
; 0xFDB1: Blocks to keep empty in the buffer.
;

include "rrpge.asm"

section code



; 0xFDAE: Buffer size as 512 bit << value
us_aubuf_bufs	equ	0xFDAE
; 0xFDAF: Block size within buffer as 512 bit << value
us_aubuf_blks	equ	0xFDAF
; 0xFDB0: Current write offset in buffer
us_aubuf_wrof	equ	0xFDB0
; 0xFDB1: Blocks to keep empty in the buffer
us_aubuf_ecnt	equ	0xFDB1



;
; Implementation of us_aubuf_init
;
us_aubuf_init_i:

.lco	equ	0		; Left channel start, 512 bit unit
.rco	equ	1		; Right channel offset, 512 bit unit
.bfs	equ	2		; Buffer size as 512 << $.bfs
.blk	equ	3		; Block size as 512 << $.blk

	; Save CPU registers

	psh a, b

	; Calculate buffer size in words (samples)

	mov a,     32
	shl c:a,   [$.bfs]
	mov b,     c

	; Clear target buffers to silence

	mov x3,    [$.lco]
	shl c:x3,  5		; Word offset
	jfa us_set_p_l_i {c, x3, 0x8000, b, a}
	mov x3,    [$.rco]
	shl c:x3,  5		; Word offset
	jfa us_set_p_l_i {c, x3, 0x8000, b, a}

	; Set up audio pointers. Tries to do it in a "painless" manner,
	; minimizing chances of audio output distortion (the kernel may
	; still take away CPU for a few milliseconds). If the original
	; buffer contained silence, the change is seamless.

	mov a,     [$.lco]
	mov b,     [$.rco]
	mov c,     1
	shl c,     [$.bfs]
	sub c,     1
	xug c,     [P_AUDIO_SIZE]
	mov [P_AUDIO_SIZE], c
	mov [P_AUDIO_LOFF], a
	mov [P_AUDIO_ROFF], b
	mov [P_AUDIO_SIZE], c

	; Set internal variables

	mov c,     [$.bfs]
	mov [us_aubuf_bufs], c
	mov c,     [$.blk]
	mov [us_aubuf_blks], c
	mov c,     0
	mov [us_aubuf_ecnt], c
	mov c,     [P_AUDIO_CTR]
	mov [us_aubuf_wrof], c

	; Restore CPU regs & exit

	pop a, b
	rfn c:x3,  0



;
; Implementation of us_aubuf_setecnt
;
us_aubuf_setecnt_i:

.cnt	equ	0		; New count of blocks to keep empty

	mov x3,    [$.cnt]
	mov [us_aubuf_ecnt], x3
	rfn x3,    0



;
; Implementation of us_aubuf_isempty
;
us_aubuf_isempty_i:

	mov x3,    [P_AUDIO_CTR]
	sub x3,    [us_aubuf_wrof]
	shr x3,    5		; To 512 bit units
	shr x3,    [us_aubuf_blks]
	xug x3,    [us_aubuf_ecnt]
	rfn x3,    0
	rfn x3,    1



;
; Implementation of us_aubuf_blockdone
;
us_aubuf_blockdone_i:

	mov x3,    32
	shl x3,    [us_aubuf_blks]
	add [us_aubuf_wrof], x3
	rfn x3,    0



;
; Implementation of us_aubuf_getlf
;
us_aubuf_getlf_i:

	mov c,     1
	shl c,     [us_aubuf_bufs]
	sub c,     1		; Buffer size mask for 512 bit units
	mov x3,    [us_aubuf_wrof]
	shr x3,    5		; To 512 bit units
	shr x3,    [us_aubuf_blks]
	shl x3,    [us_aubuf_blks]
	and x3,    c		; Mask to size
	add x3,    [P_AUDIO_LOFF]
	shl c:x3,  4		; To cell address
	rfn



;
; Implementation of us_aubuf_getrt
;
us_aubuf_getrt_i:

	mov c,     1
	shl c,     [us_aubuf_bufs]
	sub c,     1		; Buffer size mask for 512 bit units
	mov x3,    [us_aubuf_wrof]
	shr x3,    5		; To 512 bit units
	shr x3,    [us_aubuf_blks]
	shl x3,    [us_aubuf_blks]
	and x3,    c		; Mask to size
	add x3,    [P_AUDIO_ROFF]
	shl c:x3,  4		; To cell address
	rfn



;
; Implementation of us_aubuf_mixlf
;
us_aubuf_mixlf_i:

	mov c,     8
	mov [P_MFIFO_ADDR], c
	jfa us_aubuf_getlf_i {}
	mov [P_MFIFO_DATA], c	; Destination bank select
	mov [P_MFIFO_DATA], x3	; Destination start pointer
	mov c,     32
	shl c,     [us_aubuf_blks]
	mov [P_MFIFO_DATA], c	; Destination cell count
	rfn c:x3,  0



;
; Implementation of us_aubuf_mixrt
;
us_aubuf_mixrt_i:

	mov c,     8
	mov [P_MFIFO_ADDR], c
	jfa us_aubuf_getrt_i {}
	mov [P_MFIFO_DATA], c	; Destination bank select
	mov [P_MFIFO_DATA], x3	; Destination start pointer
	mov c,     32
	shl c,     [us_aubuf_blks]
	mov [P_MFIFO_DATA], c	; Destination cell count
	rfn c:x3,  0
