*&---------------------------------------------------------------------*
*& Include          ZTEST_NAMING_I01
*&---------------------------------------------------------------------*

" BLOCK 3/5 - EVENT + INLINE MATRIX
INITIALIZATION.
  DATA lv_init_ok TYPE i.                                            " valid local
  DATA gv_init_bad TYPE i.                                           " invalid local -> should use LV_*

AT SELECTION-SCREEN.
  DATA lv_ass_ok TYPE i.                                             " valid local
  DATA gv_ass_bad TYPE i.                                            " invalid local -> should use LV_*

AT SELECTION-SCREEN OUTPUT.
  DATA lv_sscr_out_ok TYPE i.                                        " valid local
  DATA gv_sscr_out_bad TYPE i.                                       " invalid local -> should use LV_*

TOP-OF-PAGE.
  DATA lv_top_ok TYPE i.                                             " valid local
  DATA gv_top_bad TYPE i.                                            " invalid local -> should use LV_*

START-OF-SELECTION.

  " Inline table / structure inference
  SELECT *
    FROM mara
    INTO TABLE @DATA(lt_mara_ok)
    UP TO 2 ROWS.                                                    " valid

  SELECT *
    FROM mara
    INTO TABLE @DATA(ls_mara_bad)
    UP TO 2 ROWS.                                                    " invalid -> should use LT_*

  READ TABLE lt_mara_ok INDEX 1 INTO DATA(ls_line_ok).               " valid
  READ TABLE lt_mara_ok INDEX 1 INTO DATA(lv_line_bad).              " invalid -> should use LS_*

  LOOP AT lt_mara_ok INTO DATA(ls_loop_ok).
    EXIT.
  ENDLOOP.

  LOOP AT lt_mara_ok INTO DATA(lt_loop_bad).
    EXIT.
  ENDLOOP.                                                           " invalid -> should use LS_*

  " Inline object/scalar inference
  DATA(lo_desc_ok) = cl_abap_typedescr=>describe_by_name( 'MARA' ).   " valid
  DATA(lt_desc_bad) = cl_abap_typedescr=>describe_by_name( 'MARA' ).  " invalid -> should use LO_/LR_*

  SELECT COUNT( * ) FROM mara INTO @DATA(lv_count_ok).               " valid
  SELECT COUNT( * ) FROM mara INTO @DATA(lt_count_bad).              " invalid -> should use LV_*

  " Semantic type inference
  DATA lt_head_ok TYPE gty_t_head.                                   " valid
  DATA ls_head_ok TYPE gty_head.                                     " valid
  DATA lv_head_bad TYPE gty_head.                                    " invalid -> should use LS_*
  DATA ls_tab_bad TYPE gty_t_head.                                   " invalid -> should use LT_*

  " Call grouped FORM cases
  PERFORM f_form_good
    TABLES   gt_mara
    USING    p_bukrs
             gs_mara
             gt_mara
    CHANGING gv_count.

  PERFORM iv_form_bad
    TABLES   gt_mara
    USING    p_bukrs
             gs_mara
             gt_mara
    CHANGING gv_count.

  PERFORM f_local_matrix.

AT LINE-SELECTION.
  DATA lv_line_sel_ok TYPE i.                                        " should be local
  DATA gv_line_sel_bad TYPE i.                                       " invalid local -> should use LV_*

AT USER-COMMAND.
  DATA lv_ucomm_ok TYPE i.                                           " should be local
  DATA gv_ucomm_bad TYPE i.                                          " invalid local -> should use LV_*

END-OF-SELECTION.
  DATA lv_end_ok  TYPE i.                                            " valid local
  DATA gv_end_bad TYPE i.                                            " invalid local -> should use LV_*

END-OF-PAGE.
  DATA lv_end_page_ok TYPE i.                                        " valid local
  DATA gv_end_page_bad TYPE i.                                       " invalid local -> should use LV_*
