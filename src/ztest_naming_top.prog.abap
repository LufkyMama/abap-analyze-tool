*&---------------------------------------------------------------------*
*& Include ZTEST_NAMING_TOP
*&---------------------------------------------------------------------*

" Global TYPES
TYPES gty_head TYPE mara.                                             " valid
TYPES gty_t_head TYPE STANDARD TABLE OF mara WITH EMPTY KEY.          " valid

TYPES lty_wrong_global TYPE mara.                                     " invalid -> should be GTY_*
TYPES lty_t_wrong_global TYPE STANDARD TABLE OF mara WITH EMPTY KEY.  " invalid -> should be GTY_T_*

TYPES: BEGIN OF gty_conf,                                             " valid
         bukrs TYPE bukrs,
         werks TYPE werks_d,
       END OF gty_conf.

TYPES: BEGIN OF lty_conf,                                             " invalid global -> should be GTY_*
         bukrs TYPE bukrs,
         werks TYPE werks_d,
       END OF lty_conf.

TYPES: BEGIN OF lv_a,                                                 " invalid global -> should be GTY_*
         bukrs TYPE bukrs,
         werks TYPE werks_d,
       END OF lv_a.

TYPES gty_line_ok TYPE LINE OF gty_t_head.                            " valid

TYPES: gty_ok_multi TYPE i,                                           " valid
       bad_multi   TYPE i.                                            " invalid

TYPES: gty_multi_ok_a TYPE i,
       gty_multi_ok_b TYPE i.

" Global CONSTANTS
CONSTANTS gc_status TYPE c VALUE 'A'.                                 " valid
CONSTANTS gv_wrong_const TYPE c VALUE 'B'.                            " invalid -> should be GC_*
CONSTANTS lc_wrong_global TYPE c LENGTH 1 VALUE 'X'.                  " invalid -> should be GC_*

CONSTANTS: BEGIN OF gc_conf,                                          " valid
             bukrs TYPE bukrs VALUE '1000',
             werks TYPE werks_d VALUE '1000',
           END OF gc_conf.

CONSTANTS: BEGIN OF lc_wrong_conf,                                    " invalid -> should be GC_*
             bukrs TYPE bukrs VALUE '1000',
             werks TYPE werks_d VALUE '1000',
           END OF lc_wrong_conf.

" Global DATA / FIELD-SYMBOLS
DATA gv_count TYPE i.                                                 " valid
DATA lv_wrong_global TYPE i.                                          " invalid -> global scalar should use GV_*

DATA gs_mara TYPE mara.                                               " valid
DATA gs_t001 TYPE t001.                                               " valid
DATA gv_wrong_struct TYPE mara.                                       " invalid -> structure should use GS_*

DATA gt_mara TYPE STANDARD TABLE OF mara WITH EMPTY KEY.              " valid
DATA gs_wrong_tab TYPE STANDARD TABLE OF mara WITH EMPTY KEY.         " invalid -> table should use GT_*

DATA go_desc TYPE REF TO cl_abap_typedescr.                           " valid
DATA gt_wrong_ref TYPE REF TO cl_abap_typedescr.                      " invalid -> ref should use GO_/GR_*

DATA gs_line_ok TYPE gty_line_ok.                                     " valid
DATA gt_line_wrong TYPE gty_line_ok.                                  " invalid -> structure should use GS_*

DATA wa_mara TYPE mara.                                               " obsolete WA_* warning

FIELD-SYMBOLS <gfs_head> TYPE mara.                                   " valid
FIELD-SYMBOLS <lfs_wrong_global> TYPE mara.                           " invalid -> global FS should use <GFS_*>

DATA gv_f01_global_ok TYPE i.                                         " valid global
DATA lv_f01_global_bad TYPE i.                                        " invalid global
FIELD-SYMBOLS <gfs_f01_ok> TYPE mara.                                 " valid global
FIELD-SYMBOLS <lfs_f01_bad> TYPE mara.                                " invalid global

" SCREEN MATRIX
SELECTION-SCREEN BEGIN OF BLOCK bl_main WITH FRAME TITLE text-001.
PARAMETERS p_bukrs TYPE bukrs.                                        " valid
PARAMETERS bukrs   TYPE bukrs.                                        " invalid -> should use P_*

PARAMETERS cb_run AS CHECKBOX.                                        " valid
PARAMETERS rb_runfg AS CHECKBOX.                                      " invalid -> checkbox should use CB_*

PARAMETERS rb_one  RADIOBUTTON GROUP rg1.                             " valid
PARAMETERS cb_one  RADIOBUTTON GROUP rg1.                             " invalid -> radiobutton should use RB_*
PARAMETERS rb_bad1 RADIOBUTTON GROUP bad1.                            " invalid -> group should use RG__ / wrong prefix
PARAMETERS rb_bad2 RADIOBUTTON GROUP bad1.                            " invalid -> group should use RG__ / wrong prefix

SELECT-OPTIONS s_matnr  FOR gs_mara-matnr.                            " valid
SELECT-OPTIONS so_matnr FOR gs_mara-matnr.                            " invalid -> should use S_*
SELECTION-SCREEN END OF BLOCK bl_main.

SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE text-002.       " invalid -> block should use BL_*
PARAMETERS p_dummy TYPE char1.                                        " valid
SELECTION-SCREEN END OF BLOCK main.
