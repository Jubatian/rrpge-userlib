;
; RRPGE User Library functions - Double buffering functions
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
;
; Provides management for double buffering to simplify this process.
;
; Uses the following CPU RAM locations:
; 0xFAFF: Current display buffer display list offset
; 0xFAFE: Current work buffer display list offset
; 0xFAFD: Flip performed flag (indicates the need to call frame hooks)
; 0xFAF0 - 0xFAFC: Page flip hooks (functions to call when flipping pages)
; 0xFAEF: Absolute offset of first free slot in flip hooks
; 0xFAEE: Absolute offset of first free slot in frame hooks
; 0xFAE0 - 0xFAED: Frame end hooks (functions to call when frame ends)
; 0xF990 - 0xF99F: Work & Display surface pairs
;


include "rrpge.asm"
include "dloff.asm"

section code



; 0xFAFF: Current display buffer display list offset
us_dbuf_dl	equ	0xFAFF
; 0xFAEE: Current work buffer display list offset
us_dbuf_wl	equ	0xFAFE
; 0xFAFD: Flip performed flag (indicates the need to call frame hooks)
us_dbuf_ff	equ	0xFAFD
; 0xFAF0 - 0xFAFC: Page flip hooks (functions to call when flipping pages)
us_dbuf_flpa	equ	0xFAF0
us_dbuf_flpe	equ	0xFAFD
; 0xFAEF: Absolute offset of first free slot in flip hooks
us_dbuf_flpf	equ	0xFAEF
; 0xFAEE: Absolute offset of first free slot in frame hooks
us_dbuf_fraf	equ	0xFAEE
; 0xFAE0 - 0xFAED: Frame end hooks (functions to call when frame ends)
us_dbuf_fraa	equ	0xFAE0
us_dbuf_frae	equ	0xFAEE
; 0xF990: Work & Display surface pairs (work high, display high, work low, display low)
us_dbuf_sura	equ	0xF990
us_dbuf_sure	equ	0xF9A0



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

	; Call hooks

	mov x3,    us_dbuf_fraa
	jms .ls
.lp:	mov c,     [x3]
	mov [$0],  x3
	jfa c			; Function may not restore c and x3
	mov x3,    [$0]
.ls:	xeq x3,    [us_dbuf_fraf]
	jms .lp

	; Clear flip performed, return

	btc [us_dbuf_ff], 0
	rfn



;
; Internal to correct a display list definition, adding current mode flags.
;
; Param0: Display list definition to patch up.
; Ret.X3: Patched display list definition
;
us_dbuf_i_dlfix:

.dls	equ	0		; Display list definition to fix

	jfa us_dloff_clip {[$.dls]}
	mov c,     [P_GDG_DLDEF]
	and c,     0x3000	; Display mode flags
	or  x3,    c		; Add them to the fixed display list definition
	rfn



;
; Implementation of us_dbuf_init
;
us_dbuf_init_i:

.dl1	equ	0		; Display list 1
.dl2	equ	1		; Display list 2
.dcl	equ	2		; Display list clear controls

	; Set Display List 1, so frame transition begins

	jfa us_dbuf_i_dlfix {[$.dl1]}
	mov [P_GDG_DLDEF], x3

	; Propagate Display List 1's size to Display List 2, and set the
	; internal display list variables.

	mov [us_dbuf_dl], x3
	and x3,    3
	not c,     0x0003	; Load 0xFFFC
	and [$.dl2], c
	or  [$.dl2], x3
	jfa us_dbuf_i_dlfix {[$.dl2]}
	mov [us_dbuf_wl], x3

	; Call flip hooks

	jfa us_dbuf_i_flipcall

	; Wait for frame end by the Frame rate limiter flag

.lp:	xbc [P_GDG_DLDEF], 15	; Frame rate limiter
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

.lp:	xbc [P_GFIFO_STAT], 0	; FIFO is non-empty or peripheral is working
	jms .lp

	; Flip buffers. The display list which becomes the work buffer is also
	; sanitized to make sure it contains the proper mode flags.

	jfa us_dbuf_i_dlfix {[us_dbuf_dl]}
	xch x3,    [us_dbuf_wl]
	mov [P_GDG_DLDEF], x3
	mov [us_dbuf_dl], x3

	; Flip surfaces (X3 is in incrementing 16 bit mode)

	mov x3,    us_dbuf_sura
.ls:	mov c,     [x3]		; Load work surface element
	xch c,     [x3]		; Swap display surface element with it
	sub x3,    2
	mov [x3],  c		; Store previous display surface element to the work element
	add x3,    1
	xeq x3,    us_dbuf_sure	; Swapped all?
	jms .ls

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
	jms .lp			; If not, then wait and call them

.exit:	; Return the current work display list

	mov x3,    [us_dbuf_wl]
	rfn

	; Wait frame end, then call frame hooks

.lp:	xbc [P_GDG_DLDEF], 15	; Frame rate limiter
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

	rfn



;
; Implementation of us_dbuf_remfliphook
;
us_dbuf_remfliphook_i:

.flh	equ	0		; Flip hook function to remove

	; Look for the function

	mov x3,    us_dbuf_flpa
	mov c,     [$.flh]
	jms .ls
.lp:	xne c,     [x3]
	jms .rm
.ls:	xeq x3,    [us_dbuf_flpf]
	jms .lp
	jms .exit		; Nothing to remove

	; Remove by sliding the rest down one position. Note: x3 is in
	; incrementing mode (won't help much if it wasn't, either). Faster
	; removal is possible using two pointers, but this is smaller.

.rm:	mov c,     [x3]
	sub x3,    2
	mov [x3],  c
	add x3,    1
	xeq x3,    [us_dbuf_flpf]
	jms .rm
	sub x3,    1
	mov [us_dbuf_flpf], x3

.exit:	; Done, removed if found, exit

	rfn



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

	rfn



;
; Implementation of us_dbuf_remframehook
;
us_dbuf_remframehook_i:

.frh	equ	0		; Frame hook function to remove

	; Look for the function

	mov x3,    us_dbuf_fraa
	mov c,     [$.frh]
	jms .ls
.lp:	xne c,     [x3]
	jms .rm
.ls:	xeq x3,    [us_dbuf_fraf]
	jms .lp
	jms .exit		; Nothing to remove

	; Remove by sliding the rest down one position. Note: x3 is in
	; incrementing mode (won't help much if it wasn't, either). Faster
	; removal is possible using two pointers, but this is smaller.

.rm:	mov c,     [x3]
	sub x3,    2
	mov [x3],  c
	add x3,    1
	xeq x3,    [us_dbuf_fraf]
	jms .rm
	sub x3,    1
	mov [us_dbuf_fraf], x3

.exit:	; Done, removed if found, exit

	rfn



;
; Implementation of us_dbuf_setsurface
;
us_dbuf_setsurface_i:

.sid	equ	0		; Surface ID to set
.dsh	equ	1		; Display surface, high
.dsl	equ	2		; Display surface, low
.wrh	equ	3		; Work surface, high
.wrl	equ	4		; Work surface, low

	mov x3,    [$.sid]
	and x3,    3		; Only 4 surfaces
	shl x3,    2		; Offset of surface pair
	add x3,    us_dbuf_sura
	mov c,     [$.wrh]
	mov [x3],  c
	mov c,     [$.dsh]
	mov [x3],  c
	mov c,     [$.wrl]
	mov [x3],  c
	mov c,     [$.dsl]
	mov [x3],  c
	rfn



;
; Implementation of us_dbuf_getsurface
;
us_dbuf_getsurface_i:

.sid	equ	0		; Surface ID to get

	; Optimized for fastest normal return path. This little function may
	; be called many times.

	; Frame hooks were called already?

	xbc [us_dbuf_ff], 0
	jms .lp			; If not, then wait and call them

.exit:	; Return the current work surface

	mov x3,    [$.sid]
	and x3,    3		; Only 4 surfaces
	shl x3,    2		; Offset of surface pair
	add x3,    us_dbuf_sura
	mov c,     [x3]		; Work surface, high
	add x3,    1		; Skip display surface, high
	mov x3,    [x3]		; Work surface, low
	rfn

	; Wait frame end, then call frame hooks

.lp:	xbc [P_GDG_DLDEF], 15	; Frame rate limiter
	jms .lp
	jfa us_dbuf_i_framecall
	jms .exit
