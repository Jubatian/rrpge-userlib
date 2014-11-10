;
; RRPGE User Library functions - Main
;
; Author    Sandor Zsuga (Jubatian)
; Copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
;           License) extended as RRPGEvt (temporary version of the RRPGE
;           License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
;           root.
;
; The main file of the RRPGE User Library including the function entry table.
;

include "rrpge.asm"

section code



org 0xF000			; Bottom of entry table

	jma us_ptr_set1i_i	; 0xF000 ptr.asm
	jma us_ptr_set1w_i	; 0xF002 ptr.asm
	jma us_ptr_set2i_i	; 0xF004 ptr.asm
	jma us_ptr_set2w_i	; 0xF006 ptr.asm
	jma us_ptr_set4i_i	; 0xF008 ptr.asm
	jma us_ptr_set4w_i	; 0xF00A ptr.asm
	jma us_ptr_set8i_i	; 0xF00C ptr.asm
	jma us_ptr_set8w_i	; 0xF00E ptr.asm
	jma us_ptr_set16i_i	; 0xF010 ptr.asm
	jma us_ptr_set16w_i	; 0xF012 ptr.asm
	nop			; 0xF014
	nop
	nop			; 0xF016
	nop
	jma us_ptr_setgen16i_i	; 0xF018 ptr.asm
	jma us_ptr_setgen16w_i	; 0xF01A ptr.asm
	jma us_ptr_setgen_i	; 0xF01C ptr.asm
	nop			; 0xF01E
	nop
	jma us_copy_pfc_i	; 0xF020 copy.asm
	jma us_copy_cfp_i	; 0xF022 copy.asm
	jma us_copy_pfp_i	; 0xF024 copy.asm
	jma us_copy_cfc_i	; 0xF026 copy.asm
	jma us_set_p_i		; 0xF028 set.asm
	jma us_set_c_i		; 0xF02A set.asm
	jma us_copy_pfp_l_i	; 0xF02C copysetl.asm
	jma us_set_p_l_i	; 0xF02E copysetl.asm

	; User Library code starts after the table

include "ptr.asm"
include "set.asm"
include "copy.asm"
include "copysetl.asm"
