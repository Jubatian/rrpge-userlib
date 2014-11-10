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



org 0xF000				; Bottom of entry table

	jma us_ptr_set1i_i		; 0xF000 ptr.asm
	jma us_ptr_set1w_i		; 0xF002 ptr.asm
	jma us_ptr_set2i_i		; 0xF004 ptr.asm
	jma us_ptr_set2w_i		; 0xF006 ptr.asm
	jma us_ptr_set4i_i		; 0xF008 ptr.asm
	jma us_ptr_set4w_i		; 0xF00A ptr.asm
	jma us_ptr_set8i_i		; 0xF00C ptr.asm
	jma us_ptr_set8w_i		; 0xF00E ptr.asm
	jma us_ptr_set16i_i		; 0xF010 ptr.asm
	jma us_ptr_set16w_i		; 0xF012 ptr.asm
	nop				; 0xF014
	nop
	nop				; 0xF016
	nop
	jma us_ptr_setgen16i_i		; 0xF018 ptr.asm
	jma us_ptr_setgen16w_i		; 0xF01A ptr.asm
	jma us_ptr_setgen_i		; 0xF01C ptr.asm
	nop				; 0xF01E
	nop
	jma us_copy_pfc_i		; 0xF020 copy.asm
	jma us_copy_cfp_i		; 0xF022 copy.asm
	jma us_copy_pfp_i		; 0xF024 copy.asm
	jma us_copy_cfc_i		; 0xF026 copy.asm
	jma us_set_p_i			; 0xF028 set.asm
	jma us_set_c_i			; 0xF02A set.asm
	jma us_copy_pfp_l_i		; 0xF02C copysetl.asm
	jma us_set_p_l_i		; 0xF02E copysetl.asm
	jma us_dloff_from_i		; 0xF030 dloff.asm
	jma us_dloff_to_i		; 0xF032 dloff.asm
	jma us_dlist_setptr_i		; 0xF034 dlist.asm
	jma us_dlist_add_i		; 0xF036 dlist.asm
	jma us_dlist_addxy_i		; 0xF038 dlist.asm
	jma us_dlist_addbg_i		; 0xF03A dlist.asm
	jma us_dlist_addlist_i		; 0xF03C dlist.asm
	jma us_dlist_clear_i		; 0xF03E dlist.asm
	jma us_dloff_clip_i		; 0xF040 dloff.asm
	jma us_dbuf_init_i		; 0xF042 dbuf.asm
	jma us_dlist_sb_setptr_i	; 0xF044 dlist_sb.asm
	jma us_dlist_sb_add_i		; 0xF046 dlist_sb.asm
	jma us_dlist_sb_addxy_i		; 0xF048 dlist_sb.asm
	jma us_dlist_sb_addbg_i		; 0xF04A dlist_sb.asm
	jma us_dlist_sb_addlist_i	; 0xF04C dlist_sb.asm
	jma us_dlist_sb_clear_i		; 0xF04E dlist_sb.asm
	jma us_dbuf_flip_i		; 0xF050 dbuf.asm
	jma us_dbuf_getlist_i		; 0xF052 dbuf.asm
	jma us_dlist_db_setptr_i	; 0xF054 dlist_db.asm
	jma us_dlist_db_add_i		; 0xF056 dlist_db.asm
	jma us_dlist_db_addxy_i		; 0xF058 dlist_db.asm
	jma us_dlist_db_addbg_i		; 0xF05A dlist_db.asm
	jma us_dlist_db_addlist_i	; 0xF05C dlist_db.asm
	jma us_dlist_db_clear_i		; 0xF05E dlist_db.asm
	jma us_dbuf_addfliphook_i	; 0xF060 dbuf.asm
	jma us_dbuf_remfliphook_i	; 0xF062 dbuf.asm
	jma us_dbuf_addframehook_i	; 0xF064 dbuf.asm
	jma us_dbuf_remframehook_i	; 0xF068 dbuf.asm



	; User Library code starts after the table

include "ptr.asm"
include "set.asm"
include "copy.asm"
include "copysetl.asm"
include "dloff.asm"
include "dbuf.asm"
include "dlist_sb.asm"
include "dlist_db.asm"
include "dlist.asm"
