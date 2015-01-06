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
	jma us_dbuf_remframehook_i	; 0xF066 dbuf.asm
	jma us_dbuf_addinithook_i	; 0xF068 dbuf.asm
	jma us_dbuf_reminithook_i	; 0xF06A dbuf.asm
	jma us_sprite_reset_i		; 0xF06C sprite.asm
	jma us_smux_reset_i		; 0xF06E smux.asm
	jma us_sprite_setbounds_i	; 0xF070 sprite.asm
	jma us_smux_setbounds_i		; 0xF072 smux.asm
	jma us_sprite_add_i		; 0xF074 sprite.asm
	jma us_smux_add_i		; 0xF076 smux.asm
	jma us_sprite_addxy_i		; 0xF078 sprite.asm
	jma us_smux_addxy_i		; 0xF07A smux.asm
	jma us_sprite_addlist_i		; 0xF07C sprite.asm
	jma us_smux_addlist_i		; 0xF07E smux.asm
	jma us_sin_i			; 0xF080 math.asm
	jma us_cos_i			; 0xF082 math.asm
	jma us_sincos_i			; 0xF084 math.asm
	jma us_tfreq_i			; 0xF086 math.asm
	jma us_mul32_i			; 0xF088 math.asm
	jma us_div32_i			; 0xF08A math.asm
	jma us_rec16_i			; 0xF08C math.asm
	jma us_rec32_i			; 0xF08E math.asm
	jma us_sqrt16_i			; 0xF090 math.asm
	jma us_sqrt32_i			; 0xF092 math.asm
	jma us_dsurf_set_i		; 0xF094 dsurf.asm
	jma us_dsurf_setdbuf_i		; 0xF096 dsurf.asm
	jma us_dsurf_setm_i		; 0xF098 dsurf.asm
	jma us_dsurf_setmdbuf_i		; 0xF09A dsurf.asm
	jma us_dsurf_get_i		; 0xF09C dsurf.asm
	jma us_dsurf_getacc_i		; 0xF09E dsurf.asm
	jma us_dsurf_getwp_i		; 0xF0A0 dsurf.asm
	jma us_dsurf_setaccpart_i	; 0xF0A2 dsurf.asm
	jma us_dsurf_init_i		; 0xF0A4 dsurf.asm
	jma us_dsurf_flip_i		; 0xF0A6 dsurf.asm
	jma us_tile_set_i		; 0xF0A8 tile.asm
	jma us_tile_getacc_i		; 0xF0AA tile.asm
	jma us_tile_blit_i		; 0xF0AC tile.asm
	jma us_tile_blitb_i		; 0xF0AE tile.asm
	jma us_tile_getwh_i		; 0xF0B0 tile.asm



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
include "sprite.asm"
include "smux.asm"
include "math.asm"
include "dsurf.asm"
include "tile.asm"
