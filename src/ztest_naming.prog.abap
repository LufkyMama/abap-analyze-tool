*&---------------------------------------------------------------------*
*& Report ZTEST_NAMING
*&---------------------------------------------------------------------*
REPORT ztest_naming.

INCLUDE ztest_naming_top.
INCLUDE ztest_naming_f01.

" Event matrix
INITIALIZATION.
  DATA gv_init_ok TYPE i.                                             " valid global
  DATA lv_init_bad TYPE i.                                            " invalid global -> should use GV_*

AT SELECTION-SCREEN.
  DATA lv_ass_ok TYPE i.                                              " valid local
  DATA gv_ass_bad TYPE i.                                             " invalid local -> should use LV_*

AT SELECTION-SCREEN OUTPUT.
  DATA lv_sscr_out_ok TYPE i.                                         " valid local
  DATA gv_sscr_out_bad TYPE i.                                        " invalid local -> should use LV_*

TOP-OF-PAGE.
  DATA gv_top_ok TYPE i.                                              " valid global
  DATA lv_top_bad TYPE i.                                             " invalid global -> should use GV_*

START-OF-SELECTION.

  " Global inline table / structure inference
  SELECT *
    FROM mara
    INTO TABLE @DATA(gt_mara_inline_ok)
    UP TO 2 ROWS.                                                     " valid global inline

  SELECT *
    FROM mara
    INTO TABLE @DATA(ls_mara_inline_bad)
    UP TO 2 ROWS.                                                     " invalid -> should use GT_*

  READ TABLE gt_mara_inline_ok INDEX 1 INTO DATA(gs_line_inline_ok).  " valid global inline
  READ TABLE gt_mara_inline_ok INDEX 1 INTO DATA(lv_line_inline_bad). " invalid -> should use GS_*

  LOOP AT gt_mara_inline_ok INTO DATA(gs_loop_inline_ok).
    EXIT.
  ENDLOOP.

  LOOP AT gt_mara_inline_ok INTO DATA(lt_loop_inline_bad).
    EXIT.
  ENDLOOP.                                                            " invalid -> should use GS_*

  " Global inline object / scalar inference
  DATA(go_desc_inline_ok) = cl_abap_typedescr=>describe_by_name( 'MARA' ). " valid
  DATA(gt_desc_inline_bad) = cl_abap_typedescr=>describe_by_name( 'MARA' ). " invalid -> should use GO_*

  SELECT COUNT( * ) FROM mara INTO @DATA(gv_count_inline_ok).         " valid global inline
  SELECT COUNT( * ) FROM mara INTO @DATA(gt_count_inline_bad).        " invalid -> should use GV_*

  " Global semantic type inference
  DATA gt_head_ok TYPE gty_t_head.                                    " valid
  DATA gs_head_ok TYPE gty_head.                                      " valid
  DATA gv_head_bad TYPE gty_head.                                     " invalid -> should use GS_*
  DATA gs_tab_bad TYPE gty_t_head.                                    " invalid -> should use GT_*

  " Call FORM cases
  PERFORM f_form_good
    TABLES   gt_mara
    USING    p_bukrs
             gs_mara
             gt_mara
    CHANGING gv_count
             gs_mara
             gt_mara.

  PERFORM iv_form_bad
    TABLES   gt_mara
    USING    p_bukrs
             gs_mara
             gt_mara
    CHANGING gv_count
             gs_mara
             gt_mara.

  PERFORM f_local_matrix.

AT LINE-SELECTION.
  DATA gv_line_sel_ok TYPE i.                                         " valid global
  DATA lv_line_sel_bad TYPE i.                                        " invalid global -> should use GV_*

AT USER-COMMAND.
  DATA gv_ucomm_ok TYPE i.                                            " valid global
  DATA lv_ucomm_bad TYPE i.                                           " invalid global -> should use GV_*

END-OF-SELECTION.
  DATA gv_end_ok TYPE i.                                              " valid global
  DATA lv_end_bad TYPE i.                                             " invalid global -> should use GV_*

END-OF-PAGE.
  DATA gv_end_page_ok TYPE i.                                         " valid global
  DATA lv_end_page_bad TYPE i.                                        " invalid global -> should use GV_*
