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


org 0xE000				; Bottom of entry table

	jma us_ptr_set1i_i		; 0xE000 ptr.asm
	jma us_ptr_set1w_i		; 0xE002 ptr.asm
	jma us_ptr_set2i_i		; 0xE004 ptr.asm
	jma us_ptr_set2w_i		; 0xE006 ptr.asm
	jma us_ptr_set4i_i		; 0xE008 ptr.asm
	jma us_ptr_set4w_i		; 0xE00A ptr.asm
	jma us_ptr_set8i_i		; 0xE00C ptr.asm
	jma us_ptr_set8w_i		; 0xE00E ptr.asm
	jma us_ptr_set16i_i		; 0xE010 ptr.asm
	jma us_ptr_set16w_i		; 0xE012 ptr.asm
	nop				; 0xE014
	nop
	nop				; 0xE016
	nop
	jma us_ptr_setgen16i_i		; 0xE018 ptr.asm
	jma us_ptr_setgen16w_i		; 0xE01A ptr.asm
	jma us_ptr_setgen_i		; 0xE01C ptr.asm
	nop				; 0xE01E
	nop
	jma us_copy_pfc_i		; 0xE020 copy.asm
	jma us_copy_cfp_i		; 0xE022 copy.asm
	jma us_copy_pfp_i		; 0xE024 copy.asm
	jma us_copy_cfc_i		; 0xE026 copy.asm
	jma us_set_p_i			; 0xE028 set.asm
	jma us_set_c_i			; 0xE02A set.asm
	jma us_copy_pfp_l_i		; 0xE02C copysetl.asm
	jma us_set_p_l_i		; 0xE02E copysetl.asm
	jma us_dloff_from_i		; 0xE030 dloff.asm
	jma us_dloff_to_i		; 0xE032 dloff.asm
	jma us_dlist_setptr_i		; 0xE034 dlist.asm
	jma us_dlist_add_i		; 0xE036 dlist.asm
	jma us_dlist_addxy_i		; 0xE038 dlist.asm
	jma us_dlist_addbg_i		; 0xE03A dlist.asm
	jma us_dlist_addlist_i		; 0xE03C dlist.asm
	jma us_dlist_clear_i		; 0xE03E dlist.asm
	jma us_dloff_clip_i		; 0xE040 dloff.asm
	jma us_dbuf_init_i		; 0xE042 dbuf.asm
	jma us_dlist_sb_setptr_i	; 0xE044 dlist_sb.asm
	jma us_dlist_sb_add_i		; 0xE046 dlist_sb.asm
	jma us_dlist_sb_addxy_i		; 0xE048 dlist_sb.asm
	jma us_dlist_sb_addbg_i		; 0xE04A dlist_sb.asm
	jma us_dlist_sb_addlist_i	; 0xE04C dlist_sb.asm
	jma us_dlist_sb_clear_i		; 0xE04E dlist_sb.asm
	jma us_dbuf_flip_i		; 0xE050 dbuf.asm
	jma us_dbuf_getlist_i		; 0xE052 dbuf.asm
	jma us_dlist_db_setptr_i	; 0xE054 dlist_db.asm
	jma us_dlist_db_add_i		; 0xE056 dlist_db.asm
	jma us_dlist_db_addxy_i		; 0xE058 dlist_db.asm
	jma us_dlist_db_addbg_i		; 0xE05A dlist_db.asm
	jma us_dlist_db_addlist_i	; 0xE05C dlist_db.asm
	jma us_dlist_db_clear_i		; 0xE05E dlist_db.asm
	jma us_dbuf_addfliphook_i	; 0xE060 dbuf.asm
	jma us_dbuf_remfliphook_i	; 0xE062 dbuf.asm
	jma us_dbuf_addframehook_i	; 0xE064 dbuf.asm
	jma us_dbuf_remframehook_i	; 0xE066 dbuf.asm
	jma us_dbuf_addinithook_i	; 0xE068 dbuf.asm
	jma us_dbuf_reminithook_i	; 0xE06A dbuf.asm
	jma us_sprite_reset_i		; 0xE06C sprite.asm
	jma us_smux_reset_i		; 0xE06E smux.asm
	jma us_sprite_setbounds_i	; 0xE070 sprite.asm
	jma us_smux_setbounds_i		; 0xE072 smux.asm
	jma us_sprite_add_i		; 0xE074 sprite.asm
	jma us_smux_add_i		; 0xE076 smux.asm
	jma us_sprite_addxy_i		; 0xE078 sprite.asm
	jma us_smux_addxy_i		; 0xE07A smux.asm
	jma us_sprite_addlist_i		; 0xE07C sprite.asm
	jma us_smux_addlist_i		; 0xE07E smux.asm
	jma us_sin_i			; 0xE080 math.asm
	jma us_cos_i			; 0xE082 math.asm
	jma us_sincos_i			; 0xE084 math.asm
	jma us_tfreq_i			; 0xE086 math.asm
	jma us_mul32_i			; 0xE088 math.asm
	jma us_div32_i			; 0xE08A math.asm
	jma us_rec16_i			; 0xE08C math.asm
	jma us_rec32_i			; 0xE08E math.asm
	jma us_sqrt16_i			; 0xE090 math.asm
	jma us_sqrt32_i			; 0xE092 math.asm
	jma us_dsurf_set_i		; 0xE094 dsurf.asm
	jma us_dsurf_setdbuf_i		; 0xE096 dsurf.asm
	jma us_dsurf_setm_i		; 0xE098 dsurf.asm
	jma us_dsurf_setmdbuf_i		; 0xE09A dsurf.asm
	jma us_dsurf_get_i		; 0xE09C dsurf.asm
	jma us_dsurf_getacc_i		; 0xE09E dsurf.asm
	jma us_dsurf_getpw_i		; 0xE0A0 dsurf.asm
	jma us_dsurf_setaccpart_i	; 0xE0A2 dsurf.asm
	jma us_dsurf_init_i		; 0xE0A4 dsurf.asm
	jma us_dsurf_flip_i		; 0xE0A6 dsurf.asm
	jma us_tile_set_i		; 0xE0A8 tile.asm
	jma us_tile_getacc_i		; 0xE0AA tile.asm
	jma us_tile_blit_i		; 0xE0AC tile.asm
	jma us_tile_blitb_i		; 0xE0AE tile.asm
	jma us_tile_gethw_i		; 0xE0B0 tile.asm
	jma us_tmap_set_i		; 0xE0B2 tmap.asm
	jma us_tmap_setfn_i		; 0xE0B4 tmap.asm
	jma us_tmap_getacc_i		; 0xE0B6 tmap.asm
	jma us_tmap_getaccxy_i		; 0xE0B8 tmap.asm
	jma us_tmap_getaccxfy_i		; 0xE0BA tmap.asm
	jma us_tmap_blit_i		; 0xE0BC tmap.asm
	jma us_tmap_gethw_i		; 0xE0BE tmap.asm
	jma us_tmap_gettilehw_i		; 0xE0C0 tmap.asm
	jma us_tmap_gettile_i		; 0xE0C2 tmap.asm
	jma us_tmap_settile_i		; 0xE0C4 tmap.asm
	jma us_tmap_setptr_i		; 0xE0C6 tmap.asm
	jma us_fastmap_set_i		; 0xE0C8 fastmap.asm
	jma us_fastmap_mark_i		; 0xE0CA fastmap.asm
	jma us_fastmap_gethw_i		; 0xE0CC fastmap.asm
	jma us_fastmap_getyx_i		; 0xE0CE fastmap.asm
	jma us_fastmap_setdly_i		; 0xE0D0 fastmap.asm
	jma us_fastmap_draw_i		; 0xE0D2 fastmap.asm



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
include "tmap.asm"
include "fastmap.asm"
