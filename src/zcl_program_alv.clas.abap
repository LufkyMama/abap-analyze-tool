class ZCL_PROGRAM_ALV definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF ty_where_used_alv,
        line_no     TYPE i,
        program     TYPE progname,
        used_object TYPE string,
        description TYPE string,
      END OF ty_where_used_alv .
  types:
    ty_t_where_used_alv TYPE STANDARD TABLE OF ty_where_used_alv WITH EMPTY KEY .
  types:
    BEGIN OF ty_wu_hit,
        used_in_prog    TYPE progname,
        obj_type        TYPE char10,
        object_name     TYPE string,
        short_text      TYPE string,
        package         TYPE devclass,
        changed_by      TYPE syuname,
        changed_on      TYPE sydatum,
        author          TYPE syuname,
        hit_source      TYPE char20,
        "==== field kỹ thuật để điều hướng ====
        nav_obj_name    TYPE sobj_name,
        nav_obj_type    TYPE trobjtype,
        nav_pgmid       TYPE pgmid,

        nav_used_name   TYPE programm,
        nav_used_type   TYPE trobjtype,
        nav_line        TYPE i,
        nav_include     TYPE programm,

        nav_method_name TYPE string,
        nav_func_group  TYPE rs38l-area,
        nav_kind_raw    TYPE string,
        used_cls_raw    TYPE rsfindlst-used_cls,
        used_obj_raw    TYPE rsfindlst-used_obj,
      END OF ty_wu_hit .
  types:
    ty_t_wu_hit TYPE STANDARD TABLE OF ty_wu_hit WITH EMPTY KEY .

  methods DISPLAY_ANALYSIS_ALV
    importing
      !IT_DATA type ZTT_ERROR optional
      !IV_USER type SYUNAME optional
      !IV_OBJECT type STRING optional
      !IV_DATE type DATUM optional
      !IV_TIME type UZEIT optional .
  methods DISPLAY_WHERE_USED_ALV
    importing
      !IT_DATA type ZCL_PROGRAM_WHEREUSED=>TY_FOUNDS .
  PROTECTED SECTION.
PRIVATE SECTION.

  TYPES:
    BEGIN OF ty_error_alv,
      line        TYPE zst_error-line,
      line_txt    TYPE string,
      msg         TYPE zst_error-msg,
      sev         TYPE zst_error-sev,
      objtype     TYPE zst_error-objtype,
      category    TYPE zst_error-category,
      objname     TYPE zst_error-objname,
      include     TYPE zst_error-include,
      include_txt TYPE string,
      rule        TYPE zst_error-rule,
      chk_date    TYPE zst_error-chk_date,
      chk_usr     TYPE zst_error-chk_usr,
      cell_color  TYPE lvc_t_scol,
    END OF ty_error_alv .
  TYPES:
    tt_error_alv TYPE STANDARD TABLE OF ty_error_alv WITH EMPTY KEY .

  DATA mt_data TYPE ztt_error .
  DATA mt_wu_disp TYPE ty_t_wu_hit .
  DATA mo_events TYPE REF TO cl_salv_events_table .
  DATA mo_alv TYPE REF TO cl_salv_table .
  DATA mt_analysis_disp TYPE tt_error_alv .
  CONSTANTS:
    BEGIN OF gc_col,
      object_name    TYPE lvc_fname VALUE 'OBJECT_NAME',
      hit_source     TYPE lvc_fname VALUE 'HIT_SOURCE',
      obj_type       TYPE lvc_fname VALUE 'OBJ_TYPE',
      short_text     TYPE lvc_fname VALUE 'SHORT_TEXT',
      used_in_prog   TYPE lvc_fname VALUE 'USED_IN_PROG',
      changed_by     TYPE lvc_fname VALUE 'CHANGED_BY',
      changed_on     TYPE lvc_fname VALUE 'CHANGED_ON',
      author         TYPE lvc_fname VALUE 'AUTHOR',
      package        TYPE lvc_fname VALUE 'PACKAGE',
      include        TYPE lvc_fname VALUE 'INCLUDE',

      nav_obj_name   TYPE lvc_fname VALUE 'NAV_OBJ_NAME',
      nav_obj_type   TYPE lvc_fname VALUE 'NAV_OBJ_TYPE',
      nav_pgmid      TYPE lvc_fname VALUE 'NAV_PGMID',
      nav_used_name  TYPE lvc_fname VALUE 'NAV_USED_NAME',
      nav_used_type  TYPE lvc_fname VALUE 'NAV_USED_TYPE',
      nav_line       TYPE lvc_fname VALUE 'NAV_LINE',
      nav_include    TYPE lvc_fname VALUE 'NAV_INCLUDE',
      nav_method     TYPE lvc_fname VALUE 'NAV_METHOD_NAME',
      nav_func_group TYPE lvc_fname VALUE 'NAV_FUNC_GROUP',
*    nav_kind_raw   TYPE lvc_fname VALUE 'NAV_KIND_RAW',
*    used_cls_raw   TYPE lvc_fname VALUE 'USED_CLS_RAW',
*    used_obj_raw   TYPE lvc_fname VALUE 'USED_OBJ_RAW',
      category       TYPE lvc_fname VALUE 'CATEGORY',
      line           TYPE lvc_fname VALUE 'LINE',
    END OF gc_col .
  CONSTANTS:
    BEGIN OF gc_param,
      prog  TYPE string VALUE 'P_PROG',
      func  TYPE string VALUE 'P_FUNC',
      fugr  TYPE string VALUE 'P_FUGR',
      tr    TYPE string VALUE 'P_TR',
      class TYPE string VALUE 'P_CLASS',
    END OF gc_param .
  CONSTANTS:
    BEGIN OF gc_repo,
      report_name TYPE syrepid     VALUE 'Z_ANALYZE_TOOL',
      pfstatus    TYPE sypfkey     VALUE 'ZSALV_STATUS',
      pgmid_r3tr  TYPE tadir-pgmid VALUE 'R3TR',
    END OF gc_repo .
  CONSTANTS:
    BEGIN OF gc_objtype,
      incl TYPE char4     VALUE 'INCL',
      prog TYPE char4     VALUE 'PROG',
      func TYPE char4     VALUE 'FUNC',
      type TYPE char4     VALUE 'TYPE',
      clas TYPE char4     VALUE 'CLAS',
      intf TYPE char4     VALUE 'INTF',
      fugr TYPE char4     VALUE 'FUGR',
      devc TYPE trobjtype VALUE 'DEVC',
      tabl TYPE char4     VALUE 'TABL',
      dtel TYPE char4     VALUE 'DTEL',
      msag TYPE char4     VALUE 'MSAG',
    END OF gc_objtype .
  CONSTANTS:
    BEGIN OF gc_prog,
      prefix_sapl  TYPE string      VALUE 'SAPL',
      class_suffix TYPE string      VALUE 'CP',
      subc_include TYPE trdir-subc  VALUE 'I',
    END OF gc_prog .
  CONSTANTS:
    BEGIN OF gc_operation,
      show TYPE c LENGTH 10 VALUE 'SHOW',
    END OF gc_operation .
  CONSTANTS:
    BEGIN OF gc_disp,
      form        TYPE string VALUE 'FORM',
      method_impl TYPE string VALUE 'METHOD_IMPL',
      unknown     TYPE string VALUE 'UNKNOWN',
    END OF gc_disp .
  CONSTANTS:
    BEGIN OF gc_kind,
      ic TYPE c LENGTH 2 VALUE 'IC',
      fo TYPE c LENGTH 2 VALUE 'FO',
      fu TYPE c LENGTH 2 VALUE 'FU',
      ty TYPE c LENGTH 2 VALUE 'TY',
    END OF gc_kind .
  CONSTANTS:
    BEGIN OF gc_token,
      method_sep   TYPE string     VALUE '=>',
      prefix_slash TYPE c LENGTH 1 VALUE '\',
      prefix_colon TYPE c LENGTH 1 VALUE ':',
      pattern      TYPE c LENGTH 1 VALUE '=',
      kw_method    TYPE string     VALUE 'METHOD',
    END OF gc_token .
  CONSTANTS:
    BEGIN OF gc_hit_source,
      comm           TYPE c LENGTH 4  VALUE 'COMM',
      comment_source TYPE c LENGTH 14 VALUE 'COMMENT SOURCE',
      cross_ref      TYPE c LENGTH 9  VALUE 'CROSS-REF',
    END OF gc_hit_source .
  CONSTANTS:
    BEGIN OF gc_category,
      hardcode    TYPE string VALUE 'HARDCODE',
      naming      TYPE string VALUE 'NAMING',
      clean_code  TYPE string VALUE 'CLEAN_CODE',
      performance TYPE string VALUE 'PERFORMANCE',
      obsolete    TYPE string VALUE 'OBSOLETE',
    END OF gc_category.

  DATA mt_analysis_all TYPE ztt_error .
  DATA mv_current_view TYPE string .

  METHODS navigate_analysis_hit
    IMPORTING
      !ls_hit TYPE ty_error_alv .
  METHODS get_class_include_text
    IMPORTING
      !im_class_name TYPE seoclsname
      !im_include    TYPE programm
    RETURNING
      VALUE(re_text) TYPE string .
  METHODS on_hotspot_click
    FOR EVENT link_click OF cl_salv_events_table
    IMPORTING
      !row
      !column .
  METHODS build_where_used_display
    IMPORTING
      !it_founds     TYPE zcl_program_whereused=>ty_founds
    RETURNING
      VALUE(rt_disp) TYPE ty_t_wu_hit .
  METHODS parse_used_token
    IMPORTING
      !iv_used_obj    TYPE string
      !iv_used_cls    TYPE rsused_cls
      !iv_program     TYPE progname OPTIONAL
      !iv_object_row  TYPE rsfindlst-object_row OPTIONAL
    EXPORTING
      !ev_obj_type    TYPE char10
      !ev_obj_name    TYPE string
      !ev_nav_pgmid   TYPE tadir-pgmid
      !ev_nav_object  TYPE tadir-object
      !ev_nav_name    TYPE sobj_name
      !ev_nav_include TYPE programm
      !ev_nav_line    TYPE i .
  METHODS enrich_where_used_hit
    CHANGING
      !cs_hit TYPE ty_wu_hit .
  METHODS on_salv_link_click
    FOR EVENT link_click OF cl_salv_events_table
    IMPORTING
      !row
      !column .
  METHODS navigate_where_used_hit
    IMPORTING
      !ls_hit    TYPE ty_wu_hit
      !iv_column TYPE salv_de_column .
  METHODS on_user_command
    FOR EVENT added_function OF cl_salv_events_table
    IMPORTING
      !e_salv_function .
  METHODS filter_analysis_by_category
    IMPORTING
      !iv_category TYPE string OPTIONAL .
ENDCLASS.



CLASS ZCL_PROGRAM_ALV IMPLEMENTATION.


METHOD build_where_used_display.

  DATA: ls_hit        TYPE ty_wu_hit,
        lv_class_name TYPE sobj_name.

  DATA: lt_prog_keys TYPE SORTED TABLE OF trdir-name
                      WITH UNIQUE KEY table_line,
        lt_trdir     TYPE SORTED TABLE OF trdir-name
                      WITH UNIQUE KEY table_line.

  " Collect program names first
  LOOP AT it_founds INTO DATA(ls_found_collect).
    IF ls_found_collect-program IS NOT INITIAL.
      INSERT ls_found_collect-program INTO TABLE lt_prog_keys.
    ENDIF.
  ENDLOOP.

  " Read TRDIR once
  IF lt_prog_keys IS NOT INITIAL.
    SELECT name
      FROM trdir
      INTO TABLE @lt_trdir
      FOR ALL ENTRIES IN @lt_prog_keys
      WHERE name = @lt_prog_keys-table_line.
  ENDIF.

  LOOP AT it_founds INTO DATA(ls_found).

    CLEAR: ls_hit, lv_class_name.

    ls_hit-used_in_prog = ls_found-program.
    ls_hit-used_cls_raw = ls_found-used_cls.
    ls_hit-used_obj_raw = ls_found-used_obj.

    IF ls_found-used_cls = gc_hit_source-comm.
      ls_hit-hit_source = gc_hit_source-comment_source.
    ELSE.
      ls_hit-hit_source = gc_hit_source-cross_ref.
    ENDIF.

    me->parse_used_token(
      EXPORTING
        iv_used_obj   = CONV string( ls_found-used_obj )
        iv_used_cls   = ls_found-used_cls
        iv_program    = ls_found-program
        iv_object_row = ls_found-object_row
      IMPORTING
        ev_obj_type    = ls_hit-obj_type
        ev_obj_name    = ls_hit-object_name
        ev_nav_pgmid   = ls_hit-nav_pgmid
        ev_nav_object  = ls_hit-nav_obj_type
        ev_nav_name    = ls_hit-nav_obj_name
        ev_nav_include = ls_hit-nav_include
        ev_nav_line    = ls_hit-nav_line ).

    me->enrich_where_used_hit(
      CHANGING
        cs_hit = ls_hit ).

    " Special case: class + method name stored in USED_IN_PROG
    IF ls_hit-obj_type = gc_objtype-clas
       AND ls_found-program IS NOT INITIAL.

      READ TABLE lt_trdir WITH TABLE KEY table_line = ls_found-program
           TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        lv_class_name = ls_hit-nav_obj_name.
        IF lv_class_name IS INITIAL.
          lv_class_name = CONV sobj_name( ls_hit-object_name ).
        ENDIF.

        " Main object remains the checked class
        ls_hit-object_name     = lv_class_name.
        ls_hit-nav_obj_name    = lv_class_name.
        ls_hit-nav_obj_type    = gc_objtype-clas.

        " Method is kept as technical navigation/display info
        ls_hit-nav_method_name = ls_found-program.
        ls_hit-used_in_prog    = ls_found-program.
      ENDIF.
    ENDIF.

    IF ls_found-program IS NOT INITIAL.
      READ TABLE lt_trdir WITH TABLE KEY table_line = ls_found-program
           TRANSPORTING NO FIELDS.
    ELSE.
      sy-subrc = 4.
    ENDIF.

    IF sy-subrc = 0.
      ls_hit-nav_include   = ls_found-program.
      ls_hit-nav_line      = CONV i( ls_found-object_row ).
      ls_hit-nav_used_name = ls_found-program.
      ls_hit-nav_used_type = gc_objtype-prog.
    ELSE.
      IF ls_hit-nav_used_name IS INITIAL.
        ls_hit-nav_used_name = CONV programm( ls_hit-nav_obj_name ).
      ENDIF.

      IF ls_hit-nav_used_type IS INITIAL.
        ls_hit-nav_used_type = ls_hit-nav_obj_type.
      ENDIF.
    ENDIF.

    APPEND ls_hit TO rt_disp.

  ENDLOOP.

ENDMETHOD.


METHOD display_analysis_alv.

  DATA: lt_alv     TYPE tt_error_alv,
        ls_alv     TYPE ty_error_alv,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_column  TYPE REF TO cl_salv_column_table,
        lo_header  TYPE REF TO cl_salv_form_layout_grid,
        lo_label   TYPE REF TO cl_salv_form_label,
        lo_text    TYPE REF TO cl_salv_form_text.

  DATA: lv_vn_t        TYPE t,
        lv_object      TYPE string,
        lv_warn_count  TYPE i,
        lv_err_count   TYPE i,
        lv_total_count TYPE i,
        lv_dyn_name    TYPE string.

  DATA: ls_scol TYPE lvc_s_scol.

  FIELD-SYMBOLS:
    <fs_value> TYPE any,
    <ls_alv>   TYPE ty_error_alv.

  "---------------------------------------------------------
  " Tự động lấy giá trị từ selection screen của report
  "---------------------------------------------------------
  lv_dyn_name = |({ gc_repo-report_name }){ gc_param-prog }|.
  ASSIGN (lv_dyn_name) TO <fs_value>.
  IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
    lv_object = <fs_value>.
  ELSE.
    lv_dyn_name = |({ gc_repo-report_name }){ gc_param-func }|.
    ASSIGN (lv_dyn_name) TO <fs_value>.
    IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
      lv_object = <fs_value>.
    ELSE.
      lv_dyn_name = |({ gc_repo-report_name }){ gc_param-fugr }|.
      ASSIGN (lv_dyn_name) TO <fs_value>.
      IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
        lv_object = <fs_value>.
      ELSE.
        lv_dyn_name = |({ gc_repo-report_name }){ gc_param-tr }|.
        ASSIGN (lv_dyn_name) TO <fs_value>.
        IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
          lv_object = <fs_value>.
        ELSE.
          lv_dyn_name = |({ gc_repo-report_name }){ gc_param-class }|.
          ASSIGN (lv_dyn_name) TO <fs_value>.
          IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
            lv_object = <fs_value>.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  lv_vn_t = sy-uzeit + ( 5 * 3600 ).

  "---------------------------------------------------------
  " Build ALV display table
  "---------------------------------------------------------
  CLEAR mt_data.
  mt_data = it_data.

  IF mt_analysis_all IS INITIAL.
    mt_analysis_all = it_data.
    mv_current_view = 'ALL'.
  ENDIF.

  IF mv_current_view IS INITIAL OR mv_current_view = 'ALL'.
    mt_analysis_all = it_data.
  ENDIF.

  CLEAR: lt_alv, lv_warn_count, lv_err_count.

  LOOP AT mt_data INTO DATA(ls_err).
    CLEAR ls_alv.
    MOVE-CORRESPONDING ls_err TO ls_alv.

    " Include hiển thị
    ls_alv-include_txt = ls_err-include.

    IF ls_err-objtype = gc_objtype-clas
       AND ls_err-objname IS NOT INITIAL
       AND ls_err-include IS NOT INITIAL.
      ls_alv-include_txt = me->get_class_include_text(
                             im_class_name = CONV seoclsname( ls_err-objname )
                             im_include    = CONV programm( ls_err-include ) ).
    ENDIF.

    " Line hiển thị
    IF ls_err-line > 0.
      ls_alv-line_txt = CONV string( ls_err-line ).
    ELSE.
      CLEAR ls_alv-line_txt.
    ENDIF.

    " Count severity
    CASE ls_err-sev.
      WHEN 'W'.
        lv_warn_count = lv_warn_count + 1.
      WHEN 'E'.
        lv_err_count = lv_err_count + 1.
    ENDCASE.

    APPEND ls_alv TO lt_alv.
  ENDLOOP.
  lv_total_count = lv_err_count + lv_warn_count.
  "---------------------------------------------------------
  " Cell color
  "---------------------------------------------------------
  LOOP AT lt_alv ASSIGNING <ls_alv>.
    CLEAR: <ls_alv>-cell_color, ls_scol.

    ls_scol-fname = 'SEV'.

    CASE <ls_alv>-sev.
      WHEN 'E'.
        ls_scol-color-col = 6.
        ls_scol-color-int = 1.
        ls_scol-color-inv = 0.
      WHEN 'W'.
        ls_scol-color-col = 3.
        ls_scol-color-int = 1.
        ls_scol-color-inv = 0.
      WHEN OTHERS.
        CONTINUE.
    ENDCASE.

    INSERT ls_scol INTO TABLE <ls_alv>-cell_color.
  ENDLOOP.

  " Lưu bảng display để hotspot click dùng lại
  CLEAR mt_analysis_disp.
  mt_analysis_disp = lt_alv.

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = mo_alv
        CHANGING
          t_table      = lt_alv ).

      mo_alv->get_functions( )->set_all( abap_true ).
      mo_alv->get_display_settings( )->set_striped_pattern( abap_true ).

      mo_alv->set_screen_status(
        pfstatus      = gc_repo-pfstatus
        report        = gc_repo-report_name
        set_functions = mo_alv->c_functions_all ).

      lo_columns = mo_alv->get_columns( ).
      lo_columns->set_optimize( abap_true ).
      lo_columns->set_color_column( 'CELL_COLOR' ).

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-category ).
          lo_column->set_visible( abap_false ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'OBJNAME' ).
          lo_column->set_visible( abap_false ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'OBJTYPE' ).
          lo_column->set_visible( abap_false ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'INCLUDE' ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'INCLUDE_TXT' ).
          lo_column->set_short_text( 'Include' ).
          lo_column->set_medium_text( 'Include' ).
          lo_column->set_long_text( 'Include' ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'LINE' ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'LINE_TXT' ).
          lo_column->set_short_text( 'Line' ).
          lo_column->set_medium_text( 'Line' ).
          lo_column->set_long_text( 'Line' ).
          lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'SEV' ).
          lo_column->set_alignment( if_salv_c_alignment=>centered ).
        CATCH cx_salv_not_found.
      ENDTRY.

      "Header
      DATA(o_grid_header) = NEW cl_salv_form_layout_grid( ).
      " Info box bên trái
      DATA(o_grp_info) = NEW cl_salv_form_groupbox(
        header = 'Execution Info' ).

      o_grid_header->set_element(
        row       = 1
        column    = 1
        r_element = o_grp_info ).

      DATA(o_info_grid) = o_grp_info->create_grid( ).
      o_info_grid->create_label(
        row    = 1
        column = 1
        text   = TEXT-C20 ).

      o_info_grid->create_text(
        row    = 1
        column = 2
        text   = lv_object ).

      o_info_grid->create_label(
        row    = 2
        column = 1
        text   = 'Checked by:' ).

      o_info_grid->create_text(
        row    = 2
        column = 2
        text   = CONV string( sy-uname ) ).

      o_info_grid->create_label(
        row    = 3
        column = 1
        text   = 'Date:' ).

      o_info_grid->create_text(
        row    = 3
        column = 2
        text   = |{ sy-datum DATE = USER }| ).

      o_info_grid->create_label(
        row    = 4
        column = 1
        text   = 'Time:' ).

      o_info_grid->create_text(
        row    = 4
        column = 2
        text   = |{ lv_vn_t TIME = USER }| ).

      " Summary box bên phải
      DATA(o_grp_summary) = NEW cl_salv_form_groupbox(
        header = 'Summary' ).

      o_grid_header->set_element(
        row       = 1
        column    = 3
        r_element = o_grp_summary ).

      DATA(o_sum_grid) = o_grp_summary->create_grid( ).
      o_sum_grid->create_label(
        row    = 1
        column = 1
        text   = 'View:' ).

      o_sum_grid->create_text(
        row    = 1
        column = 2
        text   = mv_current_view ).
      o_sum_grid->create_label(
        row    = 2
        column = 1
        text   = 'Errors:' ).

      o_sum_grid->create_text(
        row    = 2
        column = 2
        text   = CONV string( lv_err_count ) ).

      o_sum_grid->create_label(
        row    = 3
        column = 1
        text   = 'Warnings:' ).

      o_sum_grid->create_text(
        row    = 3
        column = 2
        text   = CONV string( lv_warn_count ) ).

      o_sum_grid->create_label(
        row    = 4
        column = 1
        text   = 'Totals:' ).

      o_sum_grid->create_text(
        row    = 4
        column = 2
        text   = CONV string( lv_total_count ) ).
      mo_alv->set_top_of_list( o_grid_header ).
      mo_events = mo_alv->get_event( ).
      SET HANDLER me->on_hotspot_click FOR mo_events.
      SET HANDLER me->on_user_command  FOR mo_events.
      mo_alv->display( ).

    CATCH cx_salv_msg.
      MESSAGE e032(zgsp04_analyzetool).
      RETURN.
  ENDTRY.

ENDMETHOD.


METHOD display_where_used_alv.

  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_column  TYPE REF TO cl_salv_column_table,
        lo_events  TYPE REF TO cl_salv_events_table,
        lo_header  TYPE REF TO cl_salv_form_layout_grid,
        lo_label   TYPE REF TO cl_salv_form_label,
        lo_text    TYPE REF TO cl_salv_form_text.

  DATA: lv_short_text  TYPE scrtext_s,
        lv_medium_text TYPE scrtext_m,
        lv_long_text   TYPE scrtext_l,
        lv_vn_t        TYPE t,
        lv_object      TYPE string,
        lv_dyn_name    TYPE string.

  FIELD-SYMBOLS: <fs_value> TYPE any.

  lv_vn_t = sy-uzeit + ( 6 * 3600 ).
  mt_wu_disp = me->build_where_used_display( it_data ).

  IF me->mt_wu_disp IS INITIAL.
    MESSAGE e030(zgsp04_analyzetool) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  lv_dyn_name = |({ gc_repo-report_name }){ gc_param-prog }|.
  ASSIGN (lv_dyn_name) TO <fs_value>.
  IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
    lv_object = <fs_value>.
  ELSE.
    lv_dyn_name = |({ gc_repo-report_name }){ gc_param-func }|.
    ASSIGN (lv_dyn_name) TO <fs_value>.
    IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
      lv_object = <fs_value>.
    ELSE.
      lv_dyn_name = |({ gc_repo-report_name }){ gc_param-fugr }|.
      ASSIGN (lv_dyn_name) TO <fs_value>.
      IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
        lv_object = <fs_value>.
      ELSE.
        lv_dyn_name = |({ gc_repo-report_name }){ gc_param-tr }|.
        ASSIGN (lv_dyn_name) TO <fs_value>.
        IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
          lv_object = <fs_value>.
        ELSE.
          lv_dyn_name = |({ gc_repo-report_name }){ gc_param-class }|.
          ASSIGN (lv_dyn_name) TO <fs_value>.
          IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
            lv_object = <fs_value>.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = me->mt_wu_disp ).

      lo_alv->get_functions( )->set_all( abap_true ).

      lo_columns = lo_alv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      CREATE OBJECT lo_header.

      lo_label = lo_header->create_label(
                   row    = 1
                   column = 1
                   text   = TEXT-c19 ).

      lo_text  = lo_header->create_text(
                   row    = 1
                   column = 2
                   text   = CONV string( sy-uname ) ).

      lo_label = lo_header->create_label(
                   row    = 1
                   column = 3
                   text   = TEXT-c20 ).

      lo_text  = lo_header->create_text(
                   row    = 1
                   column = 4
                   text   = lv_object ).

      lo_label = lo_header->create_label(
                   row    = 2
                   column = 1
                   text   = TEXT-c21 ).

      lo_text  = lo_header->create_text(
                   row    = 2
                   column = 2
                   text   = sy-datum ).

      lo_label = lo_header->create_label(
                   row    = 2
                   column = 3
                   text   = TEXT-c22 ).

      lo_text  = lo_header->create_text(
                   row    = 2
                   column = 4
                   text   = lv_vn_t ).

      lo_alv->set_top_of_list( lo_header ).

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-hit_source ).

          lv_short_text  = CONV scrtext_s( TEXT-c23 ).
          lv_medium_text = CONV scrtext_m( TEXT-c24 ).
          lv_long_text   = CONV scrtext_l( TEXT-c25 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-object_name ).

          lv_short_text  = CONV scrtext_s( TEXT-c01 ).
          lv_medium_text = CONV scrtext_m( TEXT-c02 ).
          lv_long_text   = CONV scrtext_l( TEXT-c02 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
          lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-obj_type ).

          lv_short_text  = CONV scrtext_s( TEXT-c03 ).
          lv_medium_text = CONV scrtext_m( TEXT-c04 ).
          lv_long_text   = CONV scrtext_l( TEXT-c04 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-short_text ).

          lv_short_text  = CONV scrtext_s( TEXT-c05 ).
          lv_medium_text = CONV scrtext_m( TEXT-c06 ).
          lv_long_text   = CONV scrtext_l( TEXT-c07 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-used_in_prog ).

          lv_short_text  = CONV scrtext_s( TEXT-c08 ).
          lv_medium_text = CONV scrtext_m( TEXT-c09 ).
          lv_long_text   = CONV scrtext_l( TEXT-c09 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
          lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-changed_by ).

          lv_short_text  = CONV scrtext_s( TEXT-c10 ).
          lv_medium_text = CONV scrtext_m( TEXT-c11 ).
          lv_long_text   = CONV scrtext_l( TEXT-c12 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-changed_on ).

          lv_short_text  = CONV scrtext_s( TEXT-c13 ).
          lv_medium_text = CONV scrtext_m( TEXT-c14 ).
          lv_long_text   = CONV scrtext_l( TEXT-c15 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-author ).

          lv_short_text  = CONV scrtext_s( TEXT-c16 ).
          lv_medium_text = CONV scrtext_m( TEXT-c16 ).
          lv_long_text   = CONV scrtext_l( TEXT-c17 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-package ).

          lv_short_text  = CONV scrtext_s( TEXT-c18 ).
          lv_medium_text = CONV scrtext_m( TEXT-c18 ).
          lv_long_text   = CONV scrtext_l( TEXT-c18 ).

          lo_column->set_short_text( lv_short_text ).
          lo_column->set_medium_text( lv_medium_text ).
          lo_column->set_long_text( lv_long_text ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_obj_name ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_obj_type ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_pgmid ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_used_name ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_used_type ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_line ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_include ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_method ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( gc_col-nav_func_group ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'NAV_KIND_RAW' ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'USED_CLS_RAW' ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'USED_OBJ_RAW' ).
          lo_column->set_technical( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.
      TRY.
          lo_columns->set_column_position(
            columnname = gc_col-object_name
            position   = 1 ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_columns->set_column_position(
            columnname = gc_col-obj_type
            position   = 2 ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_columns->set_column_position(
            columnname = gc_col-hit_source
            position   = 3 ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_columns->set_column_position(
            columnname = gc_col-short_text
            position   = 4 ).
        CATCH cx_salv_not_found.
      ENDTRY.

      TRY.
          lo_columns->set_column_position(
            columnname = gc_col-used_in_prog
            position   = 5 ).
        CATCH cx_salv_not_found.
      ENDTRY.

      lo_events = lo_alv->get_event( ).
      SET HANDLER me->on_salv_link_click FOR lo_events.

      lo_alv->display( ).

    CATCH cx_salv_msg.
      MESSAGE e031(zgsp04_analyzetool).
  ENDTRY.

ENDMETHOD.


METHOD enrich_where_used_hit.

  DATA: lv_area       TYPE rs38l-area,
        lv_class_prog TYPE progname,
        lv_prog_sapl  TYPE progname,
        lv_intf_found TYPE abap_bool.

  CLEAR: lv_area, lv_class_prog, lv_prog_sapl, lv_intf_found.

  CASE cs_hit-obj_type.

    WHEN gc_objtype-incl OR gc_objtype-prog.

      SELECT SINGLE text
        FROM trdirt
        INTO @cs_hit-short_text
        WHERE sprsl = @sy-langu
          AND name  = @cs_hit-object_name.

      SELECT SINGLE unam, udat
        FROM trdir
        INTO (@cs_hit-changed_by, @cs_hit-changed_on)
        WHERE name = @cs_hit-object_name.

      SELECT SINGLE devclass, author
        FROM tadir
        INTO (@cs_hit-package, @cs_hit-author)
        WHERE pgmid    = @gc_repo-pgmid_r3tr
          AND object   = @gc_objtype-prog
          AND obj_name = @cs_hit-object_name.

    WHEN gc_objtype-func.

      SELECT SINGLE stext
        FROM tftit
        INTO @cs_hit-short_text
        WHERE spras    = @sy-langu
          AND funcname = @cs_hit-object_name.

      SELECT SINGLE area
        FROM enlfdir
        INTO @lv_area
        WHERE funcname = @cs_hit-object_name.

      IF sy-subrc = 0 AND lv_area IS NOT INITIAL.

        lv_prog_sapl = |{ gc_prog-prefix_sapl }{ lv_area }|.

        SELECT SINGLE devclass, author
          FROM tadir
          INTO (@cs_hit-package, @cs_hit-author)
          WHERE pgmid    = @gc_repo-pgmid_r3tr
            AND object   = @gc_objtype-fugr
            AND obj_name = @lv_area.

        SELECT SINGLE unam, udat
          FROM trdir
          INTO (@cs_hit-changed_by, @cs_hit-changed_on)
          WHERE name = @lv_prog_sapl.

      ENDIF.

    WHEN gc_objtype-type.

      CLEAR: lv_class_prog, lv_intf_found.

      " 1) Try class first
      SELECT SINGLE descript
        FROM seoclasstx
        INTO @cs_hit-short_text
        WHERE langu   = @sy-langu
          AND clsname = @cs_hit-object_name.

      IF sy-subrc = 0.

        cs_hit-obj_type = gc_objtype-clas.

        SELECT SINGLE devclass, author
          FROM tadir
          INTO (@cs_hit-package, @cs_hit-author)
          WHERE pgmid    = @gc_repo-pgmid_r3tr
            AND object   = @gc_objtype-clas
            AND obj_name = @cs_hit-object_name.

        lv_class_prog = |{ cs_hit-object_name WIDTH = 30 PAD = gc_token-pattern }{ gc_prog-class_suffix }|.

        SELECT SINGLE unam, udat
          FROM trdir
          INTO (@cs_hit-changed_by, @cs_hit-changed_on)
          WHERE name = @lv_class_prog.

      ELSE.

        " 2) If not a class, try interface via TADIR
        SELECT SINGLE devclass, author
          FROM tadir
          INTO (@cs_hit-package, @cs_hit-author)
          WHERE pgmid    = @gc_repo-pgmid_r3tr
            AND object   = @gc_objtype-intf
            AND obj_name = @cs_hit-object_name.

        IF sy-subrc = 0.
          lv_intf_found   = abap_true.
          cs_hit-obj_type = gc_objtype-intf.

          " Fallback because system has no SEOINTFTX
          cs_hit-short_text = cs_hit-object_name.
        ENDIF.

      ENDIF.

    WHEN OTHERS.

      SELECT SINGLE devclass, author
        FROM tadir
        INTO (@cs_hit-package, @cs_hit-author)
        WHERE obj_name = @cs_hit-object_name.

  ENDCASE.

  IF cs_hit-short_text IS INITIAL.
    cs_hit-short_text = cs_hit-object_name.
  ENDIF.

ENDMETHOD.


METHOD navigate_where_used_hit.

  DATA: lv_include   TYPE programm,
        lv_line      TYPE i,
        lv_method_uc TYPE string,
        lv_src_uc    TYPE string,
        lt_source    TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  DATA: lv_pat_method_1 TYPE string,
        lv_pat_method_2 TYPE string.

  lv_method_uc = ls_hit-nav_method_name.
  TRANSLATE lv_method_uc TO UPPER CASE.

  lv_pat_method_1 = |*{ gc_token-kw_method }*{ lv_method_uc }*|.
  lv_pat_method_2 = |*{ gc_token-kw_method } { lv_method_uc }*|.

  CASE iv_column.

    WHEN gc_col-object_name
      OR gc_col-obj_type
      OR gc_col-short_text
      OR gc_col-used_in_prog.

      IF ls_hit-nav_include IS NOT INITIAL.

        IF ls_hit-nav_line > 0.
          CALL FUNCTION 'EDITOR_PROGRAM'
            EXPORTING
              display = abap_true
              program = ls_hit-nav_include
              line    = ls_hit-nav_line
            EXCEPTIONS
              OTHERS  = 1.
        ELSE.
          CALL FUNCTION 'EDITOR_PROGRAM'
            EXPORTING
              display = abap_true
              program = ls_hit-nav_include
            EXCEPTIONS
              OTHERS  = 1.
        ENDIF.

        IF sy-subrc = 0.
          RETURN.
        ENDIF.
      ENDIF.

      " Fallback riêng cho class method khi chưa có include thật
      IF ls_hit-nav_obj_type = gc_objtype-clas
         AND ls_hit-nav_obj_name IS NOT INITIAL
         AND ls_hit-nav_method_name IS NOT INITIAL.

        CALL METHOD cl_oo_classname_service=>get_method_include
          EXPORTING
            mtdkey              = VALUE seocpdkey(
                                    clsname = CONV seoclsname( ls_hit-nav_obj_name )
                                    cpdname = CONV seocpdname( ls_hit-nav_method_name ) )
          RECEIVING
            result              = lv_include
          EXCEPTIONS
            class_not_existing  = 1
            method_not_existing = 2
            OTHERS              = 3.

        IF sy-subrc = 0 AND lv_include IS NOT INITIAL.

          READ REPORT lv_include INTO lt_source.
          IF sy-subrc = 0.

            lv_method_uc = ls_hit-nav_method_name.
            TRANSLATE lv_method_uc TO UPPER CASE.

            CLEAR lv_line.
            LOOP AT lt_source INTO DATA(lv_src).
              lv_src_uc = lv_src.
              TRANSLATE lv_src_uc TO UPPER CASE.

              IF lv_src_uc CP lv_pat_method_1
                 OR lv_src_uc CP lv_pat_method_2.
                lv_line = sy-tabix.
                EXIT.
              ENDIF.
            ENDLOOP.

            IF lv_line > 0.
              CALL FUNCTION 'EDITOR_PROGRAM'
                EXPORTING
                  display = abap_true
                  program = lv_include
                  line    = lv_line
                EXCEPTIONS
                  OTHERS  = 1.
            ELSE.
              CALL FUNCTION 'EDITOR_PROGRAM'
                EXPORTING
                  display = abap_true
                  program = lv_include
                EXCEPTIONS
                  OTHERS  = 1.
            ENDIF.

            IF sy-subrc = 0.
              RETURN.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      " Fallback cuối: mở object
      IF ls_hit-nav_obj_name IS NOT INITIAL
         AND ls_hit-nav_obj_type IS NOT INITIAL.

        CALL FUNCTION 'RS_TOOL_ACCESS'
          EXPORTING
            operation   = gc_operation-show
            object_name = ls_hit-nav_obj_name
            object_type = ls_hit-nav_obj_type
            position    = COND i( WHEN ls_hit-nav_line > 0 THEN ls_hit-nav_line ELSE 1 )
          EXCEPTIONS
            OTHERS      = 1.

        IF sy-subrc = 0.
          RETURN.
        ENDIF.
      ENDIF.

      " Fallback thêm cho used object
      IF ls_hit-nav_used_name IS NOT INITIAL
         AND ls_hit-nav_used_type IS NOT INITIAL.

        CALL FUNCTION 'RS_TOOL_ACCESS'
          EXPORTING
            operation   = gc_operation-show
            object_name = ls_hit-nav_used_name
            object_type = ls_hit-nav_used_type
            position    = COND i( WHEN ls_hit-nav_line > 0 THEN ls_hit-nav_line ELSE 1 )
          EXCEPTIONS
            OTHERS      = 1.

        IF sy-subrc = 0.
          RETURN.
        ENDIF.
      ENDIF.

    WHEN gc_col-package.

      IF ls_hit-package IS NOT INITIAL.
        CALL FUNCTION 'RS_TOOL_ACCESS'
          EXPORTING
            operation   = gc_operation-show
            object_name = CONV sobj_name( ls_hit-package )
            object_type = gc_objtype-devc
            position    = 1
          EXCEPTIONS
            OTHERS      = 1.

        IF sy-subrc = 0.
          RETURN.
        ENDIF.
      ENDIF.

  ENDCASE.

  MESSAGE e033(zgsp04_analyzetool) DISPLAY LIKE 'E'.

ENDMETHOD.


METHOD on_hotspot_click.
*METHOD on_hotspot_click.
*  DATA ls_data TYPE zst_error.
*
*  READ TABLE mt_data
*  INTO ls_data INDEX row.
*
*  IF sy-subrc <> 0.
*    RETURN.
*  ENDIF.
*
**  DATA(lv_technical_include) = ls_data-param2.
*  DATA(lv_technical_include) = ls_data-include.
*
**  IF lv_technical_include IS INITIAL.
**    " Phòng hờ trường hợp PARAM2 trống thì lấy ngược lại INCLUDE
**    lv_technical_include = ls_data-include.
**  ENDIF.
*
*  " 3. Điều hướng bằng tên kỹ thuật
*  IF lv_technical_include IS NOT INITIAL.
*    CALL FUNCTION 'RS_TOOL_ACCESS'
*      EXPORTING
*        operation   = gc_operation-show
*        object_name = lv_technical_include
*        object_type = gc_objtype-prog
*        position    = ls_data-line
*      EXCEPTIONS
*        OTHERS      = 3.
*  ENDIF.
*ENDMETHOD.



  DATA ls_hit TYPE ty_error_alv.

  READ TABLE mt_analysis_disp INTO ls_hit INDEX row.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  CASE column.
    WHEN 'LINE_TXT' OR gc_col-line.
      me->navigate_analysis_hit( ls_hit = ls_hit ).
    WHEN OTHERS.
      RETURN.
  ENDCASE.

ENDMETHOD.


METHOD on_salv_link_click.
  DATA ls_hit TYPE ty_wu_hit.
  READ TABLE mt_wu_disp INTO ls_hit INDEX row.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  CASE column.
    WHEN gc_col-object_name
      OR gc_col-obj_type
      OR gc_col-short_text
      OR gc_col-used_in_prog
      OR  gc_col-package.

      me->navigate_where_used_hit(
        ls_hit    = ls_hit
        iv_column = column ).

    WHEN OTHERS.
      RETURN.
  ENDCASE.

ENDMETHOD.


METHOD parse_used_token.

  DATA: lv_raw         TYPE string,
        lv_kind        TYPE c LENGTH 2,
        lv_name        TYPE string,
        lv_class_name  TYPE seoclsname,
        lv_method      TYPE string,
        lv_prog_name   TYPE trdir-name,
        lv_subc        TYPE trdir-subc,
        lv_funcname    TYPE rs38l-name,
        lv_clsname     TYPE seoclsname,
        lv_devclass    TYPE tadir-devclass.

  CLEAR: ev_obj_type,
         ev_obj_name,
         ev_nav_pgmid,
         ev_nav_object,
         ev_nav_name,
         ev_nav_include,
         ev_nav_line.

  lv_raw = iv_used_obj.
  IF lv_raw IS INITIAL AND iv_used_cls IS INITIAL.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " 1) Tách prefix dạng \XX:...
  "------------------------------------------------------------
  CLEAR: lv_kind, lv_name.

  IF lv_raw IS NOT INITIAL
     AND strlen( lv_raw ) >= 5
     AND lv_raw+0(1) = gc_token-prefix_slash
     AND lv_raw+3(1) = gc_token-prefix_colon.

    lv_kind = lv_raw+1(2).
    lv_name = lv_raw+4.
  ELSE.
    lv_name = lv_raw.
  ENDIF.

  TRANSLATE lv_kind TO UPPER CASE.
  CONDENSE lv_name NO-GAPS.

  "------------------------------------------------------------
  " 2) Ưu tiên token prefix trước
  "------------------------------------------------------------
  CASE lv_kind.

    WHEN gc_kind-fu.
      ev_obj_type   = gc_objtype-func.
      ev_obj_name   = lv_name.
      ev_nav_pgmid  = gc_repo-pgmid_r3tr.
      ev_nav_object = gc_objtype-func.
      ev_nav_name   = lv_name.
      RETURN.

    WHEN gc_kind-ic.
      ev_obj_type    = gc_objtype-incl.
      ev_obj_name    = lv_name.
      ev_nav_pgmid   = gc_repo-pgmid_r3tr.
      ev_nav_object  = gc_objtype-prog.
      ev_nav_name    = lv_name.
      ev_nav_include = lv_name.
      ev_nav_line    = iv_object_row.
      RETURN.

    WHEN gc_kind-fo.
      ev_obj_type    = gc_disp-form.
      ev_obj_name    = lv_name.
      ev_nav_pgmid   = gc_repo-pgmid_r3tr.
      ev_nav_object  = gc_objtype-prog.
      ev_nav_name    = iv_program.
      ev_nav_include = iv_program.
      ev_nav_line    = iv_object_row.
      RETURN.

    WHEN gc_kind-ty.
      ev_obj_type   = gc_objtype-type.
      ev_obj_name   = lv_name.
      ev_nav_pgmid  = gc_repo-pgmid_r3tr.
      ev_nav_name   = lv_name.
      CLEAR ev_nav_object.
      RETURN.

    WHEN OTHERS.
  ENDCASE.

  "------------------------------------------------------------
  " 3) Parse method/class theo tên object
  "------------------------------------------------------------
  IF lv_name CS gc_token-method_sep.
    SPLIT lv_name AT gc_token-method_sep INTO lv_class_name lv_method.
    IF lv_class_name IS NOT INITIAL AND lv_method IS NOT INITIAL.
      ev_obj_type    = gc_disp-method_impl.
      ev_obj_name    = lv_name.
      ev_nav_pgmid   = gc_repo-pgmid_r3tr.
      ev_nav_object  = gc_objtype-clas.
      ev_nav_name    = lv_class_name.
      ev_nav_include = iv_program.
      ev_nav_line    = iv_object_row.
      RETURN.
    ENDIF.
  ENDIF.

  "------------------------------------------------------------
  " 4) Fallback theo USED_CLS nếu có ý nghĩa
  "------------------------------------------------------------
  CASE iv_used_cls.

    WHEN gc_objtype-clas.
      ev_obj_type   = gc_objtype-clas.
      ev_obj_name   = lv_name.
      ev_nav_pgmid  = gc_repo-pgmid_r3tr.
      ev_nav_object = gc_objtype-clas.
      ev_nav_name   = lv_name.
      RETURN.

    WHEN gc_objtype-intf.
      ev_obj_type   = gc_objtype-intf.
      ev_obj_name   = lv_name.
      ev_nav_pgmid  = gc_repo-pgmid_r3tr.
      ev_nav_object = gc_objtype-intf.
      ev_nav_name   = lv_name.
      RETURN.

    WHEN gc_objtype-func.
      ev_obj_type   = gc_objtype-func.
      ev_obj_name   = lv_name.
      ev_nav_pgmid  = gc_repo-pgmid_r3tr.
      ev_nav_object = gc_objtype-func.
      ev_nav_name   = lv_name.
      RETURN.

    WHEN gc_objtype-tabl.
      ev_obj_type   = gc_objtype-tabl.
      ev_obj_name   = lv_name.
      ev_nav_pgmid  = gc_repo-pgmid_r3tr.
      ev_nav_object = gc_objtype-tabl.
      ev_nav_name   = lv_name.
      RETURN.

    WHEN gc_objtype-dtel.
      ev_obj_type   = gc_objtype-dtel.
      ev_obj_name   = lv_name.
      ev_nav_pgmid  = gc_repo-pgmid_r3tr.
      ev_nav_object = gc_objtype-dtel.
      ev_nav_name   = lv_name.
      RETURN.

    WHEN gc_objtype-msag.
      ev_obj_type   = gc_objtype-msag.
      ev_obj_name   = lv_name.
      ev_nav_pgmid  = gc_repo-pgmid_r3tr.
      ev_nav_object = gc_objtype-msag.
      ev_nav_name   = lv_name.
      RETURN.

    WHEN gc_objtype-prog.
      " chưa return, vì có thể iv_used_cls = PROG nhưng object thật lại là FM SAP
  ENDCASE.

  "------------------------------------------------------------
  " 5) Resolve thật theo repository
  "------------------------------------------------------------

  " 5.1 Function module?
  CLEAR lv_funcname.
  SELECT SINGLE funcname
    FROM enlfdir
    INTO @lv_funcname
    WHERE funcname = @lv_name.

  IF sy-subrc = 0 AND lv_funcname IS NOT INITIAL.
    ev_obj_type   = gc_objtype-func.
    ev_obj_name   = lv_funcname.
    ev_nav_pgmid  = gc_repo-pgmid_r3tr.
    ev_nav_object = gc_objtype-func.
    ev_nav_name   = lv_funcname.
    RETURN.
  ENDIF.

  " 5.2 Program/include?
  CLEAR: lv_prog_name, lv_subc.
  SELECT SINGLE name, subc
    FROM trdir
    INTO (@lv_prog_name, @lv_subc)
    WHERE name = @lv_name.

  IF sy-subrc = 0 AND lv_prog_name IS NOT INITIAL.
    IF lv_subc = gc_prog-subc_include.
      ev_obj_type = gc_objtype-incl.
    ELSE.
      ev_obj_type = gc_objtype-prog.
    ENDIF.

    ev_obj_name    = lv_prog_name.
    ev_nav_pgmid   = gc_repo-pgmid_r3tr.
    ev_nav_object  = gc_objtype-prog.
    ev_nav_name    = lv_prog_name.
    ev_nav_include = lv_prog_name.
    ev_nav_line    = iv_object_row.
    RETURN.
  ENDIF.

  " 5.3 Class?
  CLEAR lv_clsname.
  SELECT SINGLE clsname
    FROM seoclass
    INTO @lv_clsname
    WHERE clsname = @lv_name.

  IF sy-subrc = 0 AND lv_clsname IS NOT INITIAL.
    ev_obj_type   = gc_objtype-clas.
    ev_obj_name   = lv_clsname.
    ev_nav_pgmid  = gc_repo-pgmid_r3tr.
    ev_nav_object = gc_objtype-clas.
    ev_nav_name   = lv_clsname.
    RETURN.
  ENDIF.

  " 5.4 Interface? dùng TADIR fallback
  CLEAR lv_devclass.
  SELECT SINGLE devclass
    FROM tadir
    INTO @lv_devclass
    WHERE pgmid    = @gc_repo-pgmid_r3tr
      AND object   = @gc_objtype-intf
      AND obj_name = @lv_name.

  IF sy-subrc = 0.
    ev_obj_type   = gc_objtype-intf.
    ev_obj_name   = lv_name.
    ev_nav_pgmid  = gc_repo-pgmid_r3tr.
    ev_nav_object = gc_objtype-intf.
    ev_nav_name   = lv_name.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " 6) Cuối cùng fallback unknown
  "------------------------------------------------------------
  ev_obj_type = gc_disp-unknown.
  ev_obj_name = COND string(
                  WHEN lv_name IS NOT INITIAL THEN lv_name
                  ELSE lv_raw ).

  IF iv_program IS NOT INITIAL.
    ev_nav_pgmid   = gc_repo-pgmid_r3tr.
    ev_nav_object  = gc_objtype-prog.
    ev_nav_name    = iv_program.
    ev_nav_include = iv_program.
    ev_nav_line    = iv_object_row.
  ENDIF.

ENDMETHOD.


METHOD filter_analysis_by_category.

  DATA lt_filtered TYPE ztt_error.

  CLEAR lt_filtered.

  IF iv_category IS INITIAL.
    lt_filtered = mt_analysis_all.
    mv_current_view = 'ALL'.
  ELSE.
    LOOP AT mt_analysis_all INTO DATA(ls_err)
         WHERE category = iv_category.
      APPEND ls_err TO lt_filtered.
    ENDLOOP.
    mv_current_view = iv_category.
  ENDIF.

  me->display_analysis_alv(
    EXPORTING
      it_data = lt_filtered ).

ENDMETHOD.


METHOD get_class_include_text.

  DATA: lo_fetch      TYPE REF TO zcl_program_fetch,
        lt_class_data TYPE zcl_program_fetch=>gty_t_class_source.

  re_text = im_include.

  CREATE OBJECT lo_fetch.

  lt_class_data = lo_fetch->get_class( im_class_name ).

  READ TABLE lt_class_data INTO DATA(ls_item)
    WITH KEY include = im_include.

  IF sy-subrc = 0 AND ls_item-method_name IS NOT INITIAL.
    re_text = ls_item-method_name.
  ENDIF.

ENDMETHOD.


METHOD navigate_analysis_hit.

  " Không navigate nếu không có line thật
  IF ls_hit-line IS INITIAL OR ls_hit-line <= 0.
    RETURN.
  ENDIF.

  " Ưu tiên mở trực tiếp include thật tại đúng line
  IF ls_hit-include IS NOT INITIAL.
    CALL FUNCTION 'EDITOR_PROGRAM'
      EXPORTING
        display = abap_true
        program = ls_hit-include
        line    = ls_hit-line
      EXCEPTIONS
        OTHERS  = 1.

    IF sy-subrc = 0.
      RETURN.
    ENDIF.
  ENDIF.

  " Fallback cuối: mở object nếu có
  IF ls_hit-objname IS NOT INITIAL
     AND ls_hit-objtype IS NOT INITIAL.
    CALL FUNCTION 'RS_TOOL_ACCESS'
      EXPORTING
        operation   = gc_operation-show
        object_name = ls_hit-objname
        object_type = ls_hit-objtype
        position    = COND i( WHEN ls_hit-line > 0 THEN ls_hit-line ELSE 1 )
      EXCEPTIONS
        OTHERS      = 1.

    IF sy-subrc = 0.
      RETURN.
    ENDIF.
  ENDIF.

  MESSAGE e033(zgsp04_analyzetool) DISPLAY LIKE 'E'.

ENDMETHOD.


METHOD on_user_command.

  CASE e_salv_function.
    WHEN 'ALL'.
      me->filter_analysis_by_category( ).

    WHEN gc_category-hardcode.
      me->filter_analysis_by_category(
        iv_category = gc_category-hardcode ).

    WHEN gc_category-naming.
      me->filter_analysis_by_category(
        iv_category = gc_category-naming ).

    WHEN gc_category-obsolete.
      me->filter_analysis_by_category(
        iv_category = gc_category-obsolete ).

    WHEN gc_category-performance.
      me->filter_analysis_by_category(
        iv_category = gc_category-performance ).

    WHEN gc_category-clean_code.
      me->filter_analysis_by_category(
        iv_category = gc_category-clean_code ).

  ENDCASE.

ENDMETHOD.
ENDCLASS.
