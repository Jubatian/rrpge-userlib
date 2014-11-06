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

us_ptr_set1i:			; 0xF000
	jma us_ptr_set1i_i	; ptr.asm
us_ptr_set1w:			; 0xF002
	jma us_ptr_set1w_i	; ptr.asm
us_ptr_set2i:			; 0xF004
	jma us_ptr_set2i_i	; ptr.asm
us_ptr_set2w:			; 0xF006
	jma us_ptr_set2w_i	; ptr.asm
us_ptr_set4i:			; 0xF008
	jma us_ptr_set4i_i	; ptr.asm
us_ptr_set4w:			; 0xF00A
	jma us_ptr_set4w_i	; ptr.asm
us_ptr_set8i:			; 0xF00C
	jma us_ptr_set8i_i	; ptr.asm
us_ptr_set8w:			; 0xF00E
	jma us_ptr_set8w_i	; ptr.asm
us_ptr_set16i:			; 0xF010
	jma us_ptr_set16i_i	; ptr.asm
us_ptr_set16w:			; 0xF012
	jma us_ptr_set16w_i	; ptr.asm
	nop			; 0xF014
	nop
	nop			; 0xF016
	nop
us_ptr_setgen16i:		; 0xF018
	jma us_ptr_setgen16i_i	; ptr.asm
us_ptr_setgen16w:		; 0xF01A
	jma us_ptr_setgen16w_i	; ptr.asm
us_ptr_setgen:			; 0xF01C
	jma us_ptr_setgen_i	; ptr.asm
	nop			; 0xF01E
	nop
us_copy_pfc:			; 0xF020
	jma us_copy_pfc_i	; copy.asm
us_copy_cfp:			; 0xF022
	jma us_copy_cfp_i	; copy.asm
us_copy_pfp:			; 0xF024
	jma us_copy_pfp_i	; copy.asm
us_copy_cfc:			; 0xF026
	jma us_copy_cfc_i	; copy.asm
us_set_p:			; 0xF028
	jma us_set_p_i		; set.asm
us_set_c:			; 0xF02A
	jma us_set_c_i		; set.asm
us_copy_pfp_l:			; 0xF02C
	jma us_copy_pfp_l_i	; copysetl.asm
us_set_p_l:			; 0xF02E
	jma us_set_p_l_i	; copysetl.asm

	; User Library code starts after the table

include "ptr.asm"
include "set.asm"
include "copy.asm"
include "copysetl.asm"
