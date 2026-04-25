*&---------------------------------------------------------------------*
*& Include ZTEST_NAMING_F01
*&---------------------------------------------------------------------*

" FORM PARAM MATRIX
FORM f_form_good
  TABLES   pt_item STRUCTURE mara
  USING    pv_bukrs TYPE bukrs
           ps_conf  TYPE mara
           pt_tab   TYPE gty_t_head
  CHANGING cv_cnt   TYPE i
           cs_conf  TYPE mara
           ct_tab   TYPE gty_t_head.

  DATA lv_form_ok TYPE i.                                             " valid local
ENDFORM.

FORM iv_form_bad
  TABLES   tt_item STRUCTURE mara
  USING    iv_bukrs TYPE bukrs
           cs_conf  TYPE mara
           ct_tab   TYPE gty_t_head
  CHANGING iv_cnt   TYPE i
           ps_conf  TYPE mara
           pt_conf  TYPE gty_t_head.

  DATA lv_ok TYPE i.                                                  " valid local
ENDFORM.

FORM f_local_matrix.

  " Local scalar / structure / internal table
  DATA lv_scalar_local_ok TYPE i.                                     " valid
  DATA gv_scalar_local_bad TYPE i.                                    " invalid -> should use LV_*

  TYPES: BEGIN OF lty_local_conf,                                     " valid local structure type
           bukrs TYPE bukrs,
           werks TYPE werks_d,
         END OF lty_local_conf.

  TYPES: BEGIN OF gty_local_conf,                                     " invalid local structure type
           bukrs TYPE bukrs,
           werks TYPE werks_d,
         END OF gty_local_conf.

  TYPES lty_t_local_conf TYPE STANDARD TABLE OF lty_local_conf
                         WITH EMPTY KEY.                              " valid local table type

  TYPES gty_t_local_conf TYPE STANDARD TABLE OF lty_local_conf
                         WITH EMPTY KEY.                              " invalid local table type

  DATA ls_local_ok TYPE lty_local_conf.                               " valid
  DATA gt_local_bad TYPE lty_local_conf.                              " invalid -> structure should use LS_*

  DATA lt_local_ok TYPE lty_t_local_conf.                             " valid
  DATA ls_local_tab_bad TYPE lty_t_local_conf.                        " invalid -> table should use LT_*

  " Local object reference
  DATA lo_ref_ok TYPE REF TO cl_abap_typedescr.                       " valid
  DATA lr_ref_ok TYPE REF TO cl_abap_typedescr.                       " valid
  DATA lt_ref_bad TYPE REF TO cl_abap_typedescr.                      " invalid -> should use LO_/LR_*

  DATA lo_local_ref_ok2 TYPE REF TO cl_abap_typedescr.                " valid

  " Local FIELD-SYMBOLS
  FIELD-SYMBOLS <lfs_local_ok> TYPE mara.                             " valid
  FIELD-SYMBOLS <gfs_local_bad> TYPE mara.                            " invalid -> local FS should use <LFS_*>
  FIELD-SYMBOLS <lfs_evidence_ok> TYPE mara.                          " valid

  " Local CONSTANTS
  CONSTANTS lc_ok TYPE c VALUE 'X'.                                   " valid
  CONSTANTS gv_bad_const TYPE c VALUE 'X'.                            " invalid -> local constant should use LC_*
  CONSTANTS gc_bad_const TYPE c VALUE 'Y'.                            " invalid -> local constant should use LC_*

  CONSTANTS: BEGIN OF lc_struct_ok,                                   " valid local structured constant
               bukrs TYPE bukrs VALUE '1000',
             END OF lc_struct_ok.

  CONSTANTS: BEGIN OF gc_struct_bad,                                  " invalid -> local structured constant should use LC_*
               bukrs TYPE bukrs VALUE '1000',
             END OF gc_struct_bad.

  " Local LINE OF / multi TYPES
  TYPES lty_t_line_src TYPE STANDARD TABLE OF mara WITH EMPTY KEY.    " helper local table type
  TYPES lty_line_local_ok TYPE LINE OF lty_t_line_src.                " valid local LINE OF type
  TYPES lty_t_line_local_bad TYPE LINE OF lty_t_line_src.             " invalid -> LINE OF should not use table-type prefix

  TYPES: lty_ok_multi TYPE i,                                         " valid
         bad_local_multi TYPE i.                                      " current false negative

  TYPES: lty_multi_ok_a TYPE i,
         lty_multi_ok_b TYPE i.

  DATA ls_line_local_ok2 TYPE lty_line_local_ok.                      " valid
  DATA lt_line_local_bad2 TYPE lty_line_local_ok.                     " invalid -> structure should use LS_*

  " STATICS
  STATICS st_counter TYPE i.                                          " valid
  STATICS gv_statics_bad TYPE i.                                      " invalid -> STATICS should use ST_*

  " Extra evidence
  DATA lt_local_tab_ok2 TYPE STANDARD TABLE OF i WITH EMPTY KEY.      " valid
  DATA wa_local TYPE mara.                                            " obsolete WA_* warning

  " Local inline matrix
  DATA lt_local_src TYPE STANDARD TABLE OF mara WITH EMPTY KEY.
  lt_local_src = gt_mara.

  READ TABLE lt_local_src INDEX 1 INTO DATA(ls_inline_local_ok).      " valid local inline
  READ TABLE lt_local_src INDEX 1 INTO DATA(lv_inline_local_bad).     " invalid -> should use LS_*

  LOOP AT lt_local_src INTO DATA(ls_inline_loop_ok).
    EXIT.
  ENDLOOP.

  LOOP AT lt_local_src INTO DATA(lt_inline_loop_bad).
    EXIT.
  ENDLOOP.                                                            " invalid -> should use LS_*

  DATA(lo_inline_ref_ok) = cl_abap_typedescr=>describe_by_name( 'MARA' ). " valid
  DATA(lt_inline_ref_bad) = cl_abap_typedescr=>describe_by_name( 'MARA' ). " invalid -> should use LO_*

  SELECT COUNT( * ) FROM mara INTO @DATA(lv_inline_count_ok).         " valid local inline
  SELECT COUNT( * ) FROM mara INTO @DATA(lt_inline_count_bad).        " invalid -> should use LV_*

ENDFORM.
