*&---------------------------------------------------------------------*
*& Include          Z_ANALYZE_TOOL_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form modify_selection_screen
*&---------------------------------------------------------------------*
FORM modify_selection_screen.

  LOOP AT SCREEN.
    " Logic cho p_err (Nhóm M1)
    IF screen-group1 = 'M1'.
      IF rb_check = 'X'.
        screen-active = '1'.
      ELSE.
        screen-active = '0'.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    " Logic cho p_tr (Nhóm M2) - Ẩn khi chọn rb_exp
    IF screen-group1 = 'M2'.
      IF rb_exp = 'X'.
        screen-active = '0'. " Ẩn khi rb_exp được chọn
      ELSE.
        screen-active = '1'. " Hiện trong các trường hợp còn lại
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form validate_selection_screen
*&---------------------------------------------------------------------*
FORM validate_selection_screen.

  DATA: lv_cnt_all    TYPE i,
        lv_cnt_export TYPE i.
  CHECK sy-ucomm = 'ONLI'.
  PERFORM normalize_inputs.

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
FORM start_of_selection_main.

  DATA: lo_report      TYPE REF TO zcl_program_report,
        lt_errors_disp TYPE ztt_error,
        lv_obj_label   TYPE string,
        lv_obj_name    TYPE string.

  "--------------------------------------------------
  " Export Technical Spec
  "--------------------------------------------------
  IF rb_exp = abap_true.

    CREATE OBJECT lo_report.

    IF p_prog IS NOT INITIAL.
      lo_report->export_program_to_excel(
        im_prog_name = p_prog ).

    ELSEIF p_func IS NOT INITIAL.
      lo_report->export_fm_to_excel(
        im_func_name = p_func ).

    ELSEIF p_fugr IS NOT INITIAL.
      lo_report->export_fugr_to_excel(
        im_fugr_name = p_fugr ).

    ELSEIF p_class IS NOT INITIAL.
      lo_report->export_class_to_excel(
        im_class_name = p_class ).
    ENDIF.

    RETURN.
  ENDIF.

  "--------------------------------------------------
  " Create controller
  "--------------------------------------------------
  lo_controller = NEW zcl_program_controller( ).

  "--------------------------------------------------
  " Analyze Check
  "--------------------------------------------------
  IF rb_check = abap_true.
    lt_errors = lo_controller->run_process(
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
    lt_founds = lo_controller->run_where_used(
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

  IF p_err = abap_true.
    LOOP AT lt_errors INTO DATA(ls_err) WHERE sev = gc_sev_error.
      APPEND ls_err TO lt_errors_disp.
    ENDLOOP.
  ELSE.
    lt_errors_disp = lt_errors.
  ENDIF.

  "--------------------------------------------------
  " Build object label / name for success message
  "--------------------------------------------------
  CLEAR: lv_obj_label, lv_obj_name.

  IF p_tr IS NOT INITIAL.
    lv_obj_label = 'Transport Request'.
    lv_obj_name  = p_tr.
  ELSEIF p_fugr IS NOT INITIAL.
    lv_obj_label = 'Function Group'.
    lv_obj_name  = p_fugr.
  ELSEIF p_prog IS NOT INITIAL.
    lv_obj_label = 'Program'.
    lv_obj_name  = p_prog.
  ELSEIF p_func IS NOT INITIAL.
    lv_obj_label = 'Function Module'.
    lv_obj_name  = p_func.
  ELSEIF p_class IS NOT INITIAL.
    lv_obj_label = 'Class'.
    lv_obj_name  = p_class.
  ENDIF.

  "--------------------------------------------------
  " Display Analyze result
  "--------------------------------------------------
  IF rb_check = abap_true.
    IF lt_errors_disp IS NOT INITIAL.
      go_alv->display_analysis_alv(
        it_data = lt_errors_disp ).
    ELSE.
      MESSAGE s021(z_gsp04_message) WITH lv_obj_label lv_obj_name.
    ENDIF.
  ENDIF.

  "--------------------------------------------------
  " Display Where-Used result
  "--------------------------------------------------
  IF rb_used = abap_true AND lt_founds IS NOT INITIAL.
    go_alv->display_where_used_alv(
      it_data = lt_founds ).
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form normalize_inputs
*&---------------------------------------------------------------------*
FORM normalize_inputs.
  PERFORM normalize USING p_prog.
  PERFORM normalize USING p_tr.
  PERFORM normalize USING p_fugr.
  PERFORM normalize USING p_func.
  PERFORM normalize USING p_class.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form normalize
*&---------------------------------------------------------------------*
FORM normalize USING p_any TYPE any.
  IF p_any IS NOT INITIAL.
    CONDENSE p_any NO-GAPS.
    TRANSLATE p_any TO UPPER CASE.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form xlwb_viewer_callback
*&---------------------------------------------------------------------*
FORM xlwb_viewer_callback
  USING    pv_event   TYPE char50
  CHANGING cv_fcode   TYPE ui_func
           cr_toolbar TYPE REF TO cl_gui_toolbar
           cv_rawdata TYPE xstring.

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
        lo_application       TYPE ole2_object,
        lo_activeworkbook    TYPE ole2_object.

  CASE pv_event.

    WHEN 'CONTROLS_INIT'.

      IF cr_toolbar IS BOUND.
        cr_toolbar->add_button(
          fcode     = 'ZDOWNLOAD'
          text      = 'Download'
          icon      = icon_export
          butn_type = cntb_btype_button ).
      ENDIF.

    WHEN 'FUNCTION_CODE'.

      CHECK cv_fcode = 'ZDOWNLOAD'.

      IMPORT lv_save_as = lv_default_name FROM MEMORY ID 'ZGSP04_XLSX_NAME'.

      IF lv_default_name IS INITIAL.
        lv_default_name = 'EXPORT.xlsx'.
      ENDIF.

      CALL METHOD cl_gui_frontend_services=>file_save_dialog
        EXPORTING
          window_title      = 'Save Excel File'
          default_extension = 'xlsx'
          file_filter       = 'Excel Files (*.xlsx)|*.xlsx|'
          default_file_name = lv_default_name
        CHANGING
          filename          = lv_filename
          path              = lv_filepath
          fullpath          = lv_fullpath.

      IF lv_fullpath IS INITIAL.
        MESSAGE 'Save operation was canceled.' TYPE 'I'.
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

      CALL METHOD OF ls_handle-obj 'Application' = lo_application.
      IF sy-subrc <> 0.
        MESSAGE 'Cannot access Excel application.' TYPE 'I'.
        CLEAR cv_fcode.
        RETURN.
      ENDIF.

      GET PROPERTY OF lo_application 'ActiveWorkbook' = lo_activeworkbook.
      IF sy-subrc <> 0.
        FREE OBJECT lo_application.
        CLEAR lo_application.
        MESSAGE 'Cannot access active workbook.' TYPE 'I'.
        CLEAR cv_fcode.
        RETURN.
      ENDIF.

      CALL METHOD OF lo_activeworkbook 'SaveAs'
        EXPORTING
          #1 = lv_fullpath
          #2 = 51.

      IF sy-subrc = 0.
        MESSAGE 'Excel file saved successfully.' TYPE 'S'.
      ELSE.
        MESSAGE 'Save failed.' TYPE 'I'.
      ENDIF.

      FREE OBJECT lo_activeworkbook.
      CLEAR lo_activeworkbook.

      FREE OBJECT lo_application.
      CLEAR lo_application.
      CLEAR cv_fcode.

  ENDCASE.
ENDFORM.
