;
; RRPGE User Library functions - Double buffering functions
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2015, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Provides management for double buffering to simplify this process.
;
; Uses the following CPU RAM locations:
; 0xFDFF: Current display buffer display list offset
; 0xFDFE: Current work buffer display list offset
; 0xFDF0 - 0xFDFD: Page flip hooks (functions to call when flipping pages)
; 0xFDEF: Absolute offset of first free slot in flip hooks
; 0xFDEE: Absolute offset of first free slot in frame hooks
; 0xFDE0 - 0xFDED: Frame end hooks (functions to call when frame ends)
; 0xFDDE: Flip performed flag (indicates the need to call frame hooks)
; 0xFDDF: Absolute offset of first free slot in init hooks
; 0xFDD0 - 0xFDDD: Init hooks (functions to call when initializing)
;


include "rrpge.asm"
include "dloff.asm"

section code



; 0xFDFF: Current display buffer display list offset
us_dbuf_dl	equ	0xFDFF
; 0xFDEE: Current work buffer display list offset
us_dbuf_wl	equ	0xFDFE
; 0xFDF0 - 0xFDFD: Page flip hooks (functions to call when flipping pages)
us_dbuf_flpa	equ	0xFDF0
us_dbuf_flpe	equ	0xFDFE
; 0xFDEF: Absolute offset of first free slot in flip hooks
us_dbuf_flpf	equ	0xFDEF
; 0xFDEE: Absolute offset of first free slot in frame hooks
us_dbuf_fraf	equ	0xFDEE
; 0xFDE0 - 0xFDED: Frame end hooks (functions to call when frame ends)
us_dbuf_fraa	equ	0xFDE0
us_dbuf_frae	equ	0xFDEE
; 0xFDDF: Absolute offset of first free slot in flip hooks
us_dbuf_inif	equ	0xFDDF
; 0xFDDE: Flip performed flag (indicates the need to call frame hooks)
us_dbuf_ff	equ	0xFDDE
; 0xFDD0 - 0xFDDD: Page flip hooks (functions to call when flipping pages)
us_dbuf_inia	equ	0xFDD0
us_dbuf_inie	equ	0xFDDE



;
; Internal to call all flip hooks. Sets flip performed flag
;
us_dbuf_i_flipcall:

	mov sp,    1

	; Call hooks

	mov x3,    us_dbuf_flpa
	jms .ls
.lp:	mov c,     [x3]
	mov [$0],  x3
	jfa c			; Function may not restore c and x3
	mov x3,    [$0]
.ls:	xeq x3,    [us_dbuf_flpf]
	jms .lp

	; Set flip performed, return

	bts [us_dbuf_ff], 0
	rfn



;
; Internal to call all frame hooks. Clears flip performed flag
;
us_dbuf_i_framecall:

	mov sp,    1

	; Clear flip performed. Do it here so frame hooks which would call
	; us_dbuf_getlist will work properly (no recursive deadlock).

	btc [us_dbuf_ff], 0

	; Call hooks

	mov x3,    us_dbuf_fraa
	jms .ls
.lp:	mov c,     [x3]
	mov [$0],  x3
	jfa c			; Function may not restore c and x3
	mov x3,    [$0]
.ls:	xeq x3,    [us_dbuf_fraf]
	jms .lp

	; Return

	rfn



;
; Implementation of us_dbuf_init
;
us_dbuf_init_i:

.dl1	equ	0		; Display list 1
.dl2	equ	1		; Display list 2
.dcl	equ	2		; Display list clear controls

	; Set Display List 1, so frame transition begins

	mov x3,    [$.dl1]
	mov [P_GDG_DLDEF], x3

	; Propagate Display List 1's size to Display List 2, and set the
	; internal display list variables.

	mov [us_dbuf_dl], x3
	and x3,    0x0003
	mov c,     0xFFFC
	and [$.dl2], c
	or  x3,    [$.dl2]
	mov [us_dbuf_wl], x3

	; Call init hooks

	mov x3,    us_dbuf_inia
	jms .ls
.li:	mov c,     [x3]
	mov [$0],  x3		; [$0] is no longer used (was [$.dl1])
	jfa c			; Function may not restore c and x3
	mov x3,    [$0]
.ls:	xeq x3,    [us_dbuf_inif]
	jms .li

	; Call flip hooks

	jfa us_dbuf_i_flipcall

	; Wait for frame end by the Frame complete flag

.lp:	xbc [P_GDG_STAT], 15	; Frame complete
	jms .lp

	; Set up display list clear

	mov x3,    [$.dcl]
	mov [P_GDG_DLCLR], x3

	; Call frame hooks & generate return value by transferring to
	; us_dbuf_getlist.

	jms us_dbuf_getlist_i



;
; Implementation of us_dbuf_flip
;
us_dbuf_flip_i:

	; Frame hooks were called for the previous frame? If not, call them.

	xbc [us_dbuf_ff], 0
	jfa us_dbuf_i_framecall

	; Wait for the Graphics FIFO to drain

	jms .lpe
.lp:	jsv kc_dly_delay {5000}
.lpe:	xbc [P_GFIFO_STAT], 0	; FIFO is non-empty or peripheral is working
	jms .lp

	; Flip buffers.

	mov x3,    [us_dbuf_dl]
	xch x3,    [us_dbuf_wl]
	mov [P_GDG_DLDEF], x3
	mov [us_dbuf_dl], x3

	; Call flip hooks, simply tail-transfer to it

	jms us_dbuf_i_flipcall



;
; Implementation of us_dbuf_getlist
;
us_dbuf_getlist_i:

	; Optimized for fastest normal return path. This little function may
	; be called many times.

	; Frame hooks were called already?

	xbc [us_dbuf_ff], 0
	jms .lpe		; If not, then wait and call them

.exit:	; Return the current work display list

	rfn c:x3,  [us_dbuf_wl]

	; Wait frame end, then call frame hooks

.lp:	jsv kc_dly_delay {5000}
.lpe:	xbc [P_GDG_STAT], 15	; Frame complete
	jms .lp
	jfa us_dbuf_i_framecall
	jms .exit



;
; Implementation of us_dbuf_addfliphook
;
us_dbuf_addfliphook_i:

.flh	equ	0		; Flip hook function to add

	; First attempt to remove it

	jfa us_dbuf_remfliphook_i {[$.flh]}

	; Add it

	mov x3,    [us_dbuf_flpf]
	xne x3,    us_dbuf_flpe
	jms .exit		; Full, can not add it
	mov c,     [$.flh]
	mov [x3],  c
	mov [us_dbuf_flpf], x3

.exit:	; Done, added (or not added)

	rfn c:x3,  0



;
; Implementation of us_dbuf_remfliphook
;
us_dbuf_remfliphook_i:

.flh	equ	0		; Flip hook function to remove

	; Save regs & set up

	mov sp,    2
	mov c,     [$.flh]
	mov [$0],  xm
	mov [$1],  x2
	mov xm2,   PTR16
	mov x2,    us_dbuf_flpf
	mov x3,    us_dbuf_flpa
	jms .entr

	; Common remove

.lp:	xne c,     [x3]
	jms .rm
.entr:	xeq x3,    [x2]
	jms .lp
	jms .exit		; Nothing to remove

	; Remove by sliding the rest down one position. Note: x3 is in
	; incrementing mode (won't help much if it wasn't, either). Faster
	; removal is possible using two pointers, but this is smaller.

.lr:	mov c,     [x3]
	sub x3,    2
	mov [x3],  c
	add x3,    1
.rm:	xeq x3,    [x2]
	jms .lr
	sub x3,    1
	mov [x2],  x3

.exit:	; Done, removed if found, exit

	mov xm,    [$0]
	mov x2,    [$1]
	rfn c:x3,  0



;
; Implementation of us_dbuf_addframehook
;
us_dbuf_addframehook_i:

.frh	equ	0		; Frame hook function to add

	; First attempt to remove it

	jfa us_dbuf_remframehook_i {[$.frh]}

	; Add it

	mov x3,    [us_dbuf_fraf]
	xne x3,    us_dbuf_frae
	jms .exit		; Full, can not add it
	mov c,     [$.frh]
	mov [x3],  c
	mov [us_dbuf_fraf], x3

.exit:	; Done, added (or not added)

	rfn c:x3,  0



;
; Implementation of us_dbuf_remframehook
;
us_dbuf_remframehook_i:

.frh	equ	0		; Frame hook function to remove

	; Save regs & set up

	mov sp,    2
	mov c,     [$.frh]
	mov [$0],  xm
	mov [$1],  x2
	mov xm2,   PTR16
	mov x2,    us_dbuf_fraf
	mov x3,    us_dbuf_fraa
	jms us_dbuf_remfliphook_i.entr



;
; Implementation of us_dbuf_addinithook
;
us_dbuf_addinithook_i:

.inh	equ	0		; Frame hook function to add

	; First attempt to remove it

	jfa us_dbuf_reminithook_i {[$.inh]}

	; Add it

	mov x3,    [us_dbuf_inif]
	xne x3,    us_dbuf_inie
	jms .exit		; Full, can not add it
	mov c,     [$.inh]
	mov [x3],  c
	mov [us_dbuf_inif], x3

.exit:	; Done, added (or not added)

	rfn c:x3,  0



;
; Implementation of us_dbuf_reminithook
;
us_dbuf_reminithook_i:

.inh	equ	0		; Frame hook function to remove

	; Save regs & set up

	mov sp,    2
	mov c,     [$.inh]
	mov [$0],  xm
	mov [$1],  x2
	mov xm2,   PTR16
	mov x2,    us_dbuf_inif
	mov x3,    us_dbuf_inia
	jms us_dbuf_remfliphook_i.entr
