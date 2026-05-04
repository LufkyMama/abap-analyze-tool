*&---------------------------------------------------------------------*
*& Include          Z_ANALYZE_TOOL_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form modify_selection_screen
*&---------------------------------------------------------------------*
FORM f_modify_selection_screen.

  LOOP AT SCREEN.
    "Show errors only M1 screen
    IF screen-group1 = gc_screen_group_check.
      IF rb_check = abap_true.
        screen-active = gc_screen_active_on. "0
      ELSE.
        screen-active = gc_screen_active_off. "1
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    "Hide TR M2 screen
    IF screen-group1 = gc_screen_group_tr.
      IF rb_exp = abap_true.
        screen-active = gc_screen_active_off. "0
      ELSE.
        screen-active = gc_screen_active_on.  "1
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form validate_selection_screen
*&---------------------------------------------------------------------*
FORM f_validate_selection_screen.

  DATA: lv_cnt_all    TYPE i,
        lv_cnt_export TYPE i.
  CHECK sy-ucomm = gc_ucomm_execute.
  PERFORM f_normalize_inputs.

  CLEAR: lv_cnt_all, lv_cnt_export.

  IF p_prog IS NOT INITIAL.
    lv_cnt_all += 1.
  ENDIF.

  IF p_tr IS NOT INITIAL.
    lv_cnt_all += 1.
  ENDIF.

  IF p_fugr IS NOT INITIAL.
    lv_cnt_all += 1.
  ENDIF.

  IF p_func IS NOT INITIAL.
    lv_cnt_all += 1.
  ENDIF.

  IF p_class IS NOT INITIAL.
    lv_cnt_all += 1.
  ENDIF.

  IF lv_cnt_all = 0.
    MESSAGE e001(z_gsp04_message).
  ELSEIF lv_cnt_all > 1.
    MESSAGE e004(z_gsp04_message) WITH p_prog p_tr.
  ENDIF.

  IF rb_exp = abap_true.

    IF p_tr IS NOT INITIAL.
      MESSAGE e077(z_gsp04_message).
    ENDIF.

    IF p_prog IS NOT INITIAL.
      lv_cnt_export += 1.
    ENDIF.

    IF p_fugr IS NOT INITIAL.
      lv_cnt_export += 1.
    ENDIF.

    IF p_func IS NOT INITIAL.
      lv_cnt_export += 1.
    ENDIF.

    IF p_class IS NOT INITIAL.
      lv_cnt_export += 1.
    ENDIF.

    IF lv_cnt_export = 0.
      MESSAGE e079(z_gsp04_message).
    ELSEIF lv_cnt_export > 1.
      MESSAGE e080(z_gsp04_message).
    ENDIF.

  ENDIF.

  IF p_prog IS NOT INITIAL.
    SELECT SINGLE name
      FROM trdir
      WHERE name = @p_prog
      INTO @DATA(lv_prog_check).
    IF sy-subrc <> 0.
      MESSAGE e002(z_gsp04_message) WITH p_prog.
    ENDIF.
  ENDIF.

  IF p_tr IS NOT INITIAL.
    SELECT SINGLE trkorr
      FROM e070
      WHERE trkorr = @p_tr
      INTO @DATA(lv_tr_check).
    IF sy-subrc <> 0.
      MESSAGE e003(z_gsp04_message) WITH p_tr.
    ENDIF.
  ENDIF.

  IF p_class IS NOT INITIAL.
    SELECT SINGLE clsname
      FROM seoclass
      WHERE clsname = @p_class
      INTO @DATA(lv_class_exists).
    IF sy-subrc <> 0.
      MESSAGE e019(z_gsp04_message) WITH p_class.
    ENDIF.
  ENDIF.

  IF p_fugr IS NOT INITIAL.
    SELECT SINGLE area
      FROM tlibg
      WHERE area = @p_fugr
      INTO @DATA(lv_area).
    IF sy-subrc <> 0.
      MESSAGE e007(z_gsp04_message) WITH p_fugr.
    ENDIF.
  ENDIF.

  IF p_func IS NOT INITIAL.
    SELECT SINGLE funcname
      FROM tfdir
      WHERE funcname = @p_func
      INTO @DATA(lv_func_exists).
    IF sy-subrc <> 0.
      MESSAGE e042(z_gsp04_message) WITH p_func.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form start_of_selection_main
*&---------------------------------------------------------------------*
FORM f_start_of_selection_main.

  DATA: lo_report      TYPE REF TO zcl_program_report,
        lt_errors_disp TYPE ztt_error,
        ls_header      TYPE zcl_program_alv=>gty_alv_header,
        lv_obj_label   TYPE string,
        lv_obj_name    TYPE string.

  "--------------------------------------------------
  " Export Technical Spec
  "--------------------------------------------------
  IF rb_exp = abap_true.

    CREATE OBJECT lo_report.

    IF p_prog IS NOT INITIAL.
      lo_report->export_program_to_excel(
        iv_prog_name = p_prog ).

    ELSEIF p_func IS NOT INITIAL.
      lo_report->export_fm_to_excel(
        iv_func_name = p_func ).

    ELSEIF p_fugr IS NOT INITIAL.
      lo_report->export_fugr_to_excel(
        iv_fugr_name = p_fugr ).

    ELSEIF p_class IS NOT INITIAL.
      lo_report->export_class_to_excel(
        iv_class_name = p_class ).
    ENDIF.

    RETURN.
  ENDIF.

  "--------------------------------------------------
  " Create controller
  "--------------------------------------------------
  go_controller = NEW zcl_program_controller( ).

  "--------------------------------------------------
  " Analyze Check
  "--------------------------------------------------
  IF rb_check = abap_true.
    gt_errors = go_controller->run_process(
      iv_tr    = p_tr
      iv_fugr  = p_fugr
      iv_prog  = p_prog
      iv_func  = p_func
      iv_clas  = p_class
      iv_check = abap_true
    ).
  ENDIF.

  "--------------------------------------------------
  " Where-Used List
  "--------------------------------------------------
  IF rb_used = abap_true.
    gt_founds = go_controller->run_where_used(
      iv_tr               = p_tr
      iv_fugr             = p_fugr
      iv_prog             = p_prog
      iv_func             = p_func
      iv_clas             = p_class
      iv_advanced_wide    = abap_true
      iv_recursive        = abap_true
      iv_include_comments = abap_true
      iv_check            = abap_true
      iv_max_hits         = 20000
    ).
  ENDIF.

  "--------------------------------------------------
  " Create ALV object
  "--------------------------------------------------
  IF go_alv IS INITIAL.
    CREATE OBJECT go_alv.
  ENDIF.

  "--------------------------------------------------
  " Filter Error only if checkbox is selected
  "--------------------------------------------------
  CLEAR lt_errors_disp.

  IF cb_err = abap_true.
    LOOP AT gt_errors INTO DATA(ls_err) WHERE sev = gc_sev_error.
      APPEND ls_err TO lt_errors_disp.
    ENDLOOP.
  ELSE.
    lt_errors_disp = gt_errors.
  ENDIF.

  "--------------------------------------------------
  " Build object label / name for success message
  "--------------------------------------------------
  CLEAR: lv_obj_label, lv_obj_name.

  IF p_tr IS NOT INITIAL.
    lv_obj_label = TEXT-003.
    lv_obj_name  = p_tr.
  ELSEIF p_fugr IS NOT INITIAL.
    lv_obj_label = TEXT-004.
    lv_obj_name  = p_fugr.
  ELSEIF p_prog IS NOT INITIAL.
    lv_obj_label = TEXT-005.
    lv_obj_name  = p_prog.
  ELSEIF p_func IS NOT INITIAL.
    lv_obj_label = TEXT-006.
    lv_obj_name  = p_func.
  ELSEIF p_class IS NOT INITIAL.
    lv_obj_label = TEXT-007.
    lv_obj_name  = p_class.
  ENDIF.
  "--------------------------------------------------
  " Build ALV header
  "--------------------------------------------------
  CLEAR ls_header.

  ls_header-object_name = lv_obj_name.
  ls_header-object_type = lv_obj_label.
  ls_header-checked_by  = sy-uname.
  "--------------------------------------------------
  " Display Analyze result
  "--------------------------------------------------
  IF rb_check = abap_true.
    IF lt_errors_disp IS NOT INITIAL.
      go_alv->display_analysis_alv(
        it_data   = lt_errors_disp
        is_header = ls_header ).
    ELSE.
      MESSAGE s021(z_gsp04_message) WITH lv_obj_label lv_obj_name.
    ENDIF.
  ENDIF.

  "--------------------------------------------------
  " Display Where-Used result
  "--------------------------------------------------
  IF rb_used = abap_true AND gt_founds IS NOT INITIAL.
    go_alv->display_where_used_alv(
      it_data   = gt_founds
      is_header = ls_header ).
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form normalize_inputs
*&---------------------------------------------------------------------*
FORM f_normalize_inputs.
  PERFORM f_normalize USING p_prog.
  PERFORM f_normalize USING p_tr.
  PERFORM f_normalize USING p_fugr.
  PERFORM f_normalize USING p_func.
  PERFORM f_normalize USING p_class.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form normalize
*&---------------------------------------------------------------------*
FORM f_normalize USING pv_any TYPE any.
  IF pv_any IS NOT INITIAL.
    CONDENSE pv_any NO-GAPS.
    TRANSLATE pv_any TO UPPER CASE.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form xlwb_viewer_callback
*&---------------------------------------------------------------------*
FORM f_xlwb_viewer_callback
  USING    pv_event   TYPE char50
  CHANGING cv_fcode   TYPE ui_func
           cv_toolbar TYPE REF TO cl_gui_toolbar
           cv_rawdata TYPE xstring. "Required by ZXLWB_CALLFORM callback interface -> xoa la dump

  TYPE-POOLS: cntb.
  INCLUDE <icon>.

  DATA: lv_filename          TYPE string,
        lv_filepath          TYPE string,
        lv_fullpath          TYPE string,
        lv_default_name      TYPE string,
        lo_container_control TYPE REF TO i_oi_container_control,
        lo_document_proxy    TYPE REF TO i_oi_document_proxy,
        lo_spreadsheet       TYPE REF TO i_oi_spreadsheet,
        ls_handle            TYPE cntl_handle,
        ls_application       TYPE ole2_object,
        ls_activeworkbook    TYPE ole2_object.

  CASE pv_event.

    WHEN gc_xl_event_init.

      IF cv_toolbar IS BOUND.
        cv_toolbar->add_button(
          fcode     = gc_xl_fcode_download
          text      = gc_xl_text_download
          icon      = icon_export
          butn_type = cntb_btype_button ).
      ENDIF.

    WHEN gc_xl_event_fcode.

      CHECK cv_fcode = gc_xl_fcode_download.

      IMPORT lv_save_as = lv_default_name FROM MEMORY ID gc_xl_memory_name.

      IF lv_default_name IS INITIAL.
        lv_default_name = gc_xl_default_name.
      ENDIF.

      cl_gui_frontend_services=>file_save_dialog(
        EXPORTING
          window_title      = gc_xl_window_title
          default_extension = gc_xl_default_ext
          file_filter       = gc_xl_file_filter
          default_file_name = lv_default_name
        CHANGING
          filename          = lv_filename
          path              = lv_filepath
          fullpath          = lv_fullpath ).

      IF lv_fullpath IS INITIAL.
        MESSAGE i029(z_gsp04_message).
        CLEAR cv_fcode.
        RETURN.
      ENDIF.

      PERFORM viewer_get_doi_object IN PROGRAM saplzxlwb
        CHANGING lo_container_control
                 lo_document_proxy
                 lo_spreadsheet.

      CHECK lo_document_proxy IS BOUND.

      lo_document_proxy->get_document_handle(
        IMPORTING
          handle = ls_handle ).

      CALL METHOD OF ls_handle-obj gc_xl_method_app = ls_application.
      IF sy-subrc <> 0.
        MESSAGE  i045(z_gsp04_message).
        CLEAR cv_fcode.
        RETURN.
      ENDIF.

      GET PROPERTY OF ls_application gc_xl_prop_workbook = ls_activeworkbook.
      IF sy-subrc <> 0.
        FREE OBJECT ls_application.
        CLEAR ls_application.
        MESSAGE i048(z_gsp04_message).
        CLEAR cv_fcode.
        RETURN.
      ENDIF.

      CALL METHOD OF ls_activeworkbook gc_xl_method_saveas
        EXPORTING
          #1 = lv_fullpath
          #2 = 51.

      IF sy-subrc = 0.
        MESSAGE s065(z_gsp04_message)..
      ELSE.
        MESSAGE s065(z_gsp04_message)..
      ENDIF.

      FREE OBJECT ls_activeworkbook.
      CLEAR ls_activeworkbook.

      FREE OBJECT ls_application.
      CLEAR ls_application.
      CLEAR cv_fcode.

  ENDCASE.
ENDFORM.
