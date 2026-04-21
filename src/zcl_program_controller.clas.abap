CLASS zcl_program_controller DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

*    DATA rt_errors TYPE zst_error .

    METHODS run_check_tr
      IMPORTING
        !iv_tr             TYPE trkorr
        !iv_check_naming   TYPE abap_bool OPTIONAL
        !iv_check_perf     TYPE abap_bool OPTIONAL
        !iv_check_used     TYPE abap_bool OPTIONAL
        !iv_check_clean    TYPE abap_bool OPTIONAL
        !iv_check_hardcode TYPE abap_bool OPTIONAL
        !iv_check_obsolete TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rt_errors)   TYPE ztt_error .

    METHODS run_check_fugr
      IMPORTING
        !iv_fugr           TYPE rs38l-area
        !iv_check_naming   TYPE abap_bool OPTIONAL
        !iv_check_hardcode TYPE abap_bool OPTIONAL
        !iv_check_obsolete TYPE abap_bool OPTIONAL
        !iv_check_perf     TYPE abap_bool OPTIONAL
        !iv_check_used     TYPE abap_bool OPTIONAL
        !iv_check_clean    TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rt_errors)   TYPE ztt_error .

    METHODS run_process
      IMPORTING
        !iv_prog         TYPE progname OPTIONAL
        !iv_fugr         TYPE rs38l-area OPTIONAL
        !iv_func         TYPE rs38l-name OPTIONAL
        !iv_clas         TYPE seoclsname OPTIONAL
        !iv_tr           TYPE trkorr OPTIONAL
        !iv_check        TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rt_errors) TYPE ztt_error .

    METHODS run_check_fm
      IMPORTING
        !iv_funcname       TYPE rs38l-name
        !iv_check_naming   TYPE abap_bool OPTIONAL
        !iv_check_perf     TYPE abap_bool OPTIONAL
        !iv_check_used     TYPE abap_bool OPTIONAL
        !iv_check_clean    TYPE abap_bool OPTIONAL
        !iv_check_obsolete TYPE abap_bool OPTIONAL
        !iv_check_hardcode TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rt_errors)   TYPE ztt_error .

    METHODS run_check_program
      IMPORTING
        !iv_prog_name      TYPE progname
        !iv_check_naming   TYPE abap_bool OPTIONAL
        !iv_check_perf     TYPE abap_bool OPTIONAL
        !iv_check_clean    TYPE abap_bool OPTIONAL
        !iv_check_hardcode TYPE abap_bool OPTIONAL
        !iv_check_obsolete TYPE abap_bool OPTIONAL
        !iv_check_used     TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rt_errors)   TYPE ztt_error .

    METHODS run_where_used
      IMPORTING
        !iv_tr               TYPE trkorr OPTIONAL
        !iv_fugr             TYPE rs38l-area OPTIONAL
        !iv_prog             TYPE progname OPTIONAL
        !iv_func             TYPE rs38l-name OPTIONAL
        !iv_clas             TYPE seoclsname OPTIONAL
        !iv_comment_scope    TYPE zcl_program_whereused=>ty_r_devclass OPTIONAL
        !iv_advanced_wide    TYPE abap_bool DEFAULT abap_false
        !iv_recursive        TYPE abap_bool DEFAULT abap_false
        !iv_include_comments TYPE abap_bool DEFAULT abap_false
        !iv_max_hits         TYPE i DEFAULT 200
        !iv_offset           TYPE i DEFAULT 0
        !iv_check            TYPE abap_bool
      EXPORTING
        !ev_has_more         TYPE abap_bool
        !ev_next_offset      TYPE i
        !ev_index_suspect    TYPE abap_bool
      RETURNING
        VALUE(rt_founds)     TYPE zcl_program_whereused=>ty_founds .

    METHODS run_check_class
      IMPORTING
        !iv_class_name     TYPE seoclsname
        !iv_check_perf     TYPE abap_bool
        !iv_check_hardcode TYPE abap_bool
        !iv_check_obsolete TYPE abap_bool
        !iv_check_clean    TYPE abap_bool
        !iv_check_used     TYPE abap_bool OPTIONAL
        !iv_check_naming   TYPE abap_bool
      RETURNING
        VALUE(rt_errors)   TYPE ztt_error .
  PROTECTED SECTION.
PRIVATE SECTION.
  TYPES: BEGIN OF gty_e071,
           pgmid    TYPE e071-pgmid,    "Rule ID for Object
           object   TYPE e071-object,   "Object Type
           obj_name TYPE e071-obj_name, "Object Name in Object List
         END OF gty_e071.

  TYPES: gty_t_e071 TYPE STANDARD TABLE OF gty_e071 WITH EMPTY KEY.

  TYPES: BEGIN OF gty_reposrc_meta,
           progname TYPE reposrc-progname,
           unam     TYPE reposrc-unam,
           udat     TYPE reposrc-udat,
         END OF gty_reposrc_meta,
         gty_t_reposrc_meta TYPE HASHED TABLE OF gty_reposrc_meta WITH UNIQUE KEY progname.

  TYPES: BEGIN OF gty_seoclass_key,
           clsname TYPE seoclass-clsname,
         END OF gty_seoclass_key,
         gty_t_seoclass_key TYPE HASHED TABLE OF gty_seoclass_key WITH UNIQUE KEY clsname.

  TYPES: BEGIN OF gty_obj_key,
           find_obj_cls TYPE euobj-id,
           repo_object  TYPE tadir-object,
           obj_name     TYPE sobj_name,
         END OF gty_obj_key .
  TYPES: gty_t_obj_keys TYPE STANDARD TABLE OF gty_obj_key WITH EMPTY KEY .

  DATA go_fetch     TYPE REF TO zcl_program_fetch .
  DATA go_check     TYPE REF TO zcl_program_check .
  DATA go_whereused TYPE REF TO zcl_program_whereused .
  DATA gt_visited   TYPE HASHED TABLE OF gty_obj_key WITH UNIQUE KEY find_obj_cls repo_object obj_name .

  METHODS ensure_objects .

  "Object Types / Repository Types
  CONSTANTS:
    gc_objtype_prog TYPE trobjtype         VALUE 'PROG',
    gc_objtype_incl TYPE trobjtype         VALUE 'INCL',
    gc_objtype_clas TYPE trobjtype         VALUE 'CLAS',
    gc_objtype_fugr TYPE trobjtype         VALUE 'FUGR',
    gc_objtype_func TYPE trobjtype         VALUE 'FUNC',
    gc_objtype_fm   TYPE trobjtype         VALUE 'FM',

    "CONSTANTS: Repository Metadata
    gc_pgmid_r3tr   TYPE e071-pgmid   VALUE 'R3TR',
    gc_subc_include TYPE trdir-subc   VALUE 'I',

    "CONSTANTS: Technical Users / Defaults
    gc_user_unknown TYPE reposrc-unam VALUE 'UNKNOWN',
    gc_user_sap     TYPE reposrc-unam VALUE 'SAP',
    gc_user_ddic    TYPE reposrc-unam VALUE 'DDIC',

    "CONSTANTS: Severity
    gc_sev_error    TYPE zst_error-sev VALUE 'E',
    gc_sev_warning  TYPE zst_error-sev VALUE 'W'.
ENDCLASS.



CLASS ZCL_PROGRAM_CONTROLLER IMPLEMENTATION.


  METHOD ensure_objects.
    IF go_fetch IS INITIAL.
      CREATE OBJECT go_fetch.
    ENDIF.
    IF go_check IS INITIAL.
      CREATE OBJECT go_check.
    ENDIF.
    IF go_whereused IS INITIAL.
      CREATE OBJECT go_whereused.
    ENDIF.
  ENDMETHOD.


METHOD run_check_fm.
  ensure_objects( ).
  CLEAR rt_errors.

  DATA: lv_pname     TYPE progname,
        lv_include   TYPE progname,
        lv_last_user TYPE reposrc-unam,
        lv_last_date TYPE reposrc-udat,
        lt_all_err   TYPE ztt_error.

  DATA: lt_sources             TYPE zcl_program_fetch=>gty_t_program_source,
        lt_source              TYPE string_table,
        ls_src                 TYPE zcl_program_fetch=>gty_program_source,
        lv_text_symbol_checked TYPE abap_bool VALUE abap_false.

  DATA lv_msg TYPE string.

  " 1) Fetch
  lt_sources = go_fetch->get_function_module(
    iv_funcname = iv_funcname ).

  IF lt_sources IS INITIAL.
    MESSAGE e034(z_gsp04_message) WITH iv_funcname INTO lv_msg.
    APPEND VALUE zst_error(
      objtype = gc_objtype_fm
      objname = iv_funcname
      include = ''
      line    = 0
      sev     = gc_sev_error
      msg     = lv_msg
      chk_usr = gc_user_unknown
    ) TO rt_errors.
    RETURN.
  ENDIF.

  CLEAR: lv_pname, lv_include, lt_source, ls_src, lv_last_user.

  " Dòng 1 = main program
  READ TABLE lt_sources INTO ls_src INDEX 1.
  IF sy-subrc = 0.
    lv_pname = ls_src-include.
  ENDIF.

  " Dòng 2 = include chứa FM
  CLEAR ls_src.
  READ TABLE lt_sources INTO ls_src INDEX 2.
  IF sy-subrc = 0 AND ls_src-source_code IS NOT INITIAL.
    lv_include = ls_src-include.
    lt_source  = ls_src-source_code.
  ELSE.
    MESSAGE e035(z_gsp04_message) WITH iv_funcname INTO lv_msg.
    APPEND VALUE zst_error(
      objtype = gc_objtype_fm
      objname = iv_funcname
      include = ''
      line    = 0
      sev     = gc_sev_error
      msg     = lv_msg
      chk_usr = gc_user_unknown
    ) TO rt_errors.
    RETURN.
  ENDIF.

  " Lấy user theo include source của FM
  SELECT SINGLE unam, udat
    FROM reposrc
    INTO (@lv_last_user, @lv_last_date)
    WHERE progname = @lv_include.

  IF sy-subrc <> 0.
    lv_last_user = gc_user_unknown.
    lv_last_date = sy-datum.
  ENDIF.

  CLEAR lt_all_err.

  " Context chung cho FM
  DATA(ls_ctx) = VALUE zcl_program_check=>gty_naming_ctx(
    obj_type  = gc_objtype_fm
    obj_name  = iv_funcname
    main_prog = lv_pname
    include   = lv_include
  ).

  IF iv_check_naming = abap_true.
    APPEND LINES OF go_check->analyze_naming(
      is_ctx    = ls_ctx
      it_source = lt_source ) TO lt_all_err.
  ENDIF.

  IF iv_check_clean = abap_true.
    APPEND LINES OF go_check->analyze_clean_code(
      is_ctx               = ls_ctx
      it_source            = lt_source
      iv_check_unused_text = COND abap_bool(
        WHEN lv_text_symbol_checked = abap_false
        THEN abap_true
        ELSE abap_false ) ) TO lt_all_err.

    lv_text_symbol_checked = abap_true.
  ENDIF.

  IF iv_check_hardcode = abap_true.
    APPEND LINES OF go_check->analyze_hardcode(
      is_ctx    = ls_ctx
      it_source = lt_source ) TO lt_all_err.
  ENDIF.

  IF iv_check_obsolete = abap_true.
    APPEND LINES OF go_check->analyze_obsolete(
      is_ctx    = ls_ctx
      it_source = lt_source ) TO lt_all_err.
  ENDIF.

  IF iv_check_perf = abap_true.
    APPEND LINES OF go_check->analyze_performance(
      is_ctx    = ls_ctx
      it_source = lt_source ) TO lt_all_err.
  ENDIF.

  " Chuẩn hóa thông tin object cho ALV
  LOOP AT lt_all_err ASSIGNING FIELD-SYMBOL(<ls_err>).
    <ls_err>-objtype  = ls_ctx-obj_type.
    <ls_err>-objname  = iv_funcname.
    <ls_err>-include  = lv_include.
    <ls_err>-chk_usr  = lv_last_user.
    <ls_err>-chk_date = lv_last_date.
  ENDLOOP.

  APPEND LINES OF lt_all_err TO rt_errors.
ENDMETHOD.


METHOD run_check_fugr.

  TYPES: BEGIN OF gty_reposrc_meta,
           progname TYPE reposrc-progname,
           unam     TYPE reposrc-unam,
           udat     TYPE reposrc-udat,
         END OF gty_reposrc_meta,
         gty_t_reposrc_meta TYPE HASHED TABLE OF gty_reposrc_meta WITH UNIQUE KEY progname.

  TYPES: BEGIN OF gty_fm_map,
           funcname TYPE tfdir-funcname,
           include  TYPE progname,
         END OF gty_fm_map,
         gty_t_fm_map TYPE STANDARD TABLE OF gty_fm_map WITH EMPTY KEY.

  DATA: lv_msg                 TYPE string,
        lv_fugr                TYPE rs38l-area,
        lv_main_prog           TYPE progname,
        lv_last_user           TYPE reposrc-unam,
        lv_last_date           TYPE reposrc-udat,
        lv_text_symbol_checked TYPE abap_bool VALUE abap_false.

  DATA: lt_all_err   TYPE ztt_error,
        lt_fg_err    TYPE ztt_error,
        lt_src_keys  TYPE SORTED TABLE OF reposrc-progname WITH UNIQUE KEY table_line,
        lt_repo_meta TYPE gty_t_reposrc_meta,
        lt_fm_map    TYPE gty_t_fm_map.

  FIELD-SYMBOLS: <ls_err> TYPE zst_error.

  ensure_objects( ).
  CLEAR rt_errors.

  lv_fugr = iv_fugr.
  TRANSLATE lv_fugr TO UPPER CASE.
  CONDENSE lv_fugr NO-GAPS.

  lv_main_prog = |SAPL{ lv_fugr }|.

  "------------------------------------------------------------
  " 1) Validate function group
  "------------------------------------------------------------
  SELECT SINGLE area
    FROM tlibg
    INTO @DATA(lv_fugr_exists)
    WHERE area = @lv_fugr.

  IF sy-subrc <> 0.
    MESSAGE e007(z_gsp04_message) WITH lv_fugr INTO lv_msg.
    APPEND VALUE zst_error(
      objtype  = gc_objtype_fugr
      objname  = lv_fugr
      include  = ''
      line     = 0
      sev      = gc_sev_error
      msg      = lv_msg
      chk_usr  = gc_user_unknown
      chk_date = sy-datum
    ) TO rt_errors.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " 2) Load all includes/source of function group
  "------------------------------------------------------------
  DATA(lt_sources) = go_fetch->get_function_group( iv_fg_name = lv_fugr ).

  IF lt_sources IS INITIAL.
    MESSAGE e005(z_gsp04_message) WITH lv_fugr INTO lv_msg.
    APPEND VALUE zst_error(
      objtype  = gc_objtype_fugr
      objname  = lv_fugr
      include  = ''
      line     = 0
      sev      = gc_sev_error
      msg      = lv_msg
      chk_usr  = gc_user_unknown
      chk_date = sy-datum
    ) TO rt_errors.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " 3) Read function module <-> include mapping
  "    Dùng lại cách cũ: ENLFDIR + TFDIR
  "------------------------------------------------------------
  SELECT a~funcname, b~include
    FROM enlfdir AS a
    INNER JOIN tfdir AS b
      ON b~funcname = a~funcname
    INTO TABLE @lt_fm_map
    WHERE a~area = @lv_fugr.

  "------------------------------------------------------------
  " 4) Prepare include metadata in one DB hit
  "------------------------------------------------------------
  LOOP AT lt_sources INTO DATA(ls_src_key).
    IF ls_src_key-include IS NOT INITIAL.
      INSERT ls_src_key-include INTO TABLE lt_src_keys.
    ENDIF.
  ENDLOOP.

  IF lt_src_keys IS NOT INITIAL.
    SELECT progname, unam, udat
      FROM reposrc
      INTO TABLE @DATA(lt_repo_raw)
      FOR ALL ENTRIES IN @lt_src_keys
      WHERE progname = @lt_src_keys-table_line.

    IF sy-subrc = 0.
      lt_repo_meta = CORRESPONDING #( lt_repo_raw ).
    ENDIF.
  ENDIF.

  "------------------------------------------------------------
  " 6) Run source-based checks include by include
  "------------------------------------------------------------
  LOOP AT lt_sources INTO DATA(ls_src).

    CLEAR: lt_all_err, lv_last_user, lv_last_date.

    READ TABLE lt_repo_meta
      WITH TABLE KEY progname = ls_src-include
      INTO DATA(ls_meta).

    IF sy-subrc = 0.
      lv_last_user = ls_meta-unam.
      lv_last_date = ls_meta-udat.
    ELSE.
      lv_last_user = gc_user_unknown.
      lv_last_date = sy-datum.
    ENDIF.

    DATA(ls_ctx) = VALUE zcl_program_check=>gty_naming_ctx(
      obj_type  = gc_objtype_fugr
      obj_name  = lv_fugr
      main_prog = lv_main_prog
      include   = ls_src-include ).

    IF iv_check_naming = abap_true.
      APPEND LINES OF go_check->analyze_naming(
        is_ctx    = ls_ctx
        it_source = ls_src-source_code
      ) TO lt_all_err.
    ENDIF.

    IF iv_check_clean = abap_true.
      APPEND LINES OF go_check->analyze_clean_code(
        is_ctx               = ls_ctx
        it_source            = ls_src-source_code
        iv_check_unused_text = COND abap_bool(
          WHEN lv_text_symbol_checked = abap_false
          THEN abap_true
          ELSE abap_false )
      ) TO lt_all_err.

      lv_text_symbol_checked = abap_true.
    ENDIF.

    IF iv_check_hardcode = abap_true.
      APPEND LINES OF go_check->analyze_hardcode(
        is_ctx    = ls_ctx
        it_source = ls_src-source_code
      ) TO lt_all_err.
    ENDIF.

    IF iv_check_obsolete = abap_true.
      APPEND LINES OF go_check->analyze_obsolete(
        is_ctx    = ls_ctx
        it_source = ls_src-source_code
      ) TO lt_all_err.
    ENDIF.

    IF iv_check_perf = abap_true.
      APPEND LINES OF go_check->analyze_performance(
        is_ctx    = ls_ctx
        it_source = ls_src-source_code
      ) TO lt_all_err.
    ENDIF.

    LOOP AT lt_all_err ASSIGNING <ls_err>.
      <ls_err>-objtype = gc_objtype_fugr.
      <ls_err>-include  = ls_src-include.
      <ls_err>-chk_usr  = lv_last_user.
      <ls_err>-chk_date = lv_last_date.
    ENDLOOP.

    SORT lt_all_err BY objtype objname include line msg.
    DELETE ADJACENT DUPLICATES FROM lt_all_err
      COMPARING objtype objname include line msg.

    APPEND LINES OF lt_all_err TO rt_errors.

  ENDLOOP.

  "------------------------------------------------------------
  " 8) Final de-dup
  "------------------------------------------------------------
  SORT rt_errors BY objtype objname include line msg.
  DELETE ADJACENT DUPLICATES FROM rt_errors
    COMPARING objtype objname include line msg.

ENDMETHOD.


METHOD run_check_program.
  ensure_objects( ).
  CLEAR rt_errors.

  DATA: lv_msg     TYPE string,
        lt_all_err TYPE ztt_error.

  DATA: lt_include_keys TYPE SORTED TABLE OF reposrc-progname
                             WITH UNIQUE KEY table_line,
        lt_reposrc_meta TYPE gty_t_reposrc_meta.

  DATA(lt_program_sources) = go_fetch->get_program_source( iv_prog_name ).
  DATA lv_text_symbol_checked TYPE abap_bool VALUE abap_false.
  DATA lt_clean_usage_source  TYPE string_table.

  LOOP AT lt_program_sources INTO DATA(ls_collect).
    IF ls_collect-include IS NOT INITIAL.
      INSERT ls_collect-include INTO TABLE lt_include_keys.
    ENDIF.
  ENDLOOP.

  IF lt_include_keys IS NOT INITIAL.
    SELECT progname, unam, udat
      FROM reposrc
      INTO TABLE @DATA(lt_reposrc_raw)
      FOR ALL ENTRIES IN @lt_include_keys
      WHERE progname = @lt_include_keys-table_line.

    IF sy-subrc = 0.
      SORT lt_reposrc_raw
        BY progname
           udat DESCENDING
           unam DESCENDING.
      DELETE ADJACENT DUPLICATES FROM lt_reposrc_raw COMPARING progname.

      lt_reposrc_meta = CORRESPONDING #( lt_reposrc_raw ).
    ENDIF.
  ENDIF.

  LOOP AT lt_program_sources INTO DATA(ls_src).

    DATA: lv_last_user TYPE reposrc-unam,
          lv_last_date TYPE reposrc-udat.

    CLEAR: lv_last_user, lv_last_date.
    READ TABLE lt_reposrc_meta
      WITH TABLE KEY progname = ls_src-include
      INTO DATA(ls_meta).

    IF sy-subrc = 0.
      lv_last_user = ls_meta-unam.
      lv_last_date = ls_meta-udat.
    ELSE.
      lv_last_user = gc_user_unknown.
      lv_last_date = sy-datum.
    ENDIF.

    IF lv_last_user = gc_user_sap
       OR lv_last_user = gc_user_ddic.
      CONTINUE.
    ENDIF.

    DATA(ls_ctx) = VALUE zcl_program_check=>gty_naming_ctx(
      obj_type  = gc_objtype_prog
      obj_name  = iv_prog_name
      main_prog = iv_prog_name
      include   = ls_src-include ).

    CLEAR lt_clean_usage_source.

    " Current include phải đứng đầu để row của current source vẫn map đúng
    APPEND LINES OF ls_src-source_code TO lt_clean_usage_source.

    LOOP AT lt_program_sources INTO DATA(ls_usage_src).
      IF ls_usage_src-include = ls_src-include.
        CONTINUE.
      ENDIF.

      APPEND LINES OF ls_usage_src-source_code TO lt_clean_usage_source.
    ENDLOOP.

    CLEAR lt_all_err.

    IF iv_check_naming = abap_true.
      APPEND LINES OF go_check->analyze_naming(
        is_ctx    = ls_ctx
        it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_clean = abap_true.
      APPEND LINES OF go_check->analyze_clean_code(
        is_ctx               = ls_ctx
        it_source            = ls_src-source_code
        it_usage_source      = lt_clean_usage_source
        iv_check_unused_text = COND abap_bool(
          WHEN lv_text_symbol_checked = abap_false
          THEN abap_true
          ELSE abap_false ) ) TO lt_all_err.
      lv_text_symbol_checked = abap_true.
    ENDIF.

    IF iv_check_hardcode = abap_true.
      APPEND LINES OF go_check->analyze_hardcode(
        is_ctx    = ls_ctx
        it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_obsolete = abap_true.
      APPEND LINES OF go_check->analyze_obsolete(
        is_ctx    = ls_ctx
        it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_perf = abap_true.
      APPEND LINES OF go_check->analyze_performance(
        is_ctx    = ls_ctx
        it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    LOOP AT lt_all_err ASSIGNING FIELD-SYMBOL(<ls_err>).
      <ls_err>-objname  = iv_prog_name.
      <ls_err>-chk_usr  = lv_last_user.
      <ls_err>-chk_date = lv_last_date.
      <ls_err>-include  = ls_src-include.
      <ls_err>-objtype = gc_objtype_prog.
    ENDLOOP.

    SORT lt_all_err BY objname include line msg.
    DELETE ADJACENT DUPLICATES FROM lt_all_err COMPARING objname include line msg.

    APPEND LINES OF lt_all_err TO rt_errors.

  ENDLOOP.
ENDMETHOD.


METHOD run_check_tr.
  ensure_objects( ).
  CLEAR rt_errors.

  DATA: lt_e071  TYPE STANDARD TABLE OF gty_e071,
        ls_e071  TYPE gty_e071,
        lv_prog  TYPE progname,
        lv_fugr  TYPE rs38l-area,
        lv_func  TYPE rs38l-name,
        lv_class TYPE seoclsname,
        lt_new   TYPE ztt_error,
        ls_err   TYPE zst_error,
        lv_msg   TYPE string.

  DATA: lt_class_keys TYPE SORTED TABLE OF seoclass-clsname WITH UNIQUE KEY table_line,
        lt_seoclass   TYPE gty_t_seoclass_key.

  " 1) Lấy danh sách object trong TR
  SELECT pgmid, object, obj_name
    FROM e071
    INTO TABLE @lt_e071
    WHERE trkorr = @iv_tr.

  IF lt_e071 IS INITIAL.
    MESSAGE e036(z_gsp04_message) WITH iv_tr INTO lv_msg.

    CLEAR ls_err.
    ls_err-line    = 0.
    ls_err-sev     = gc_sev_error.
    ls_err-msg     = lv_msg.
    ls_err-objname = iv_tr.
    APPEND ls_err TO rt_errors.
    RETURN.
  ENDIF.

  " 2) Tránh trùng
  SORT lt_e071 BY object obj_name.
  DELETE ADJACENT DUPLICATES FROM lt_e071 COMPARING object obj_name.

  " 3) Gom class name trước
  LOOP AT lt_e071 INTO ls_e071 WHERE object = gc_objtype_clas.
    lv_class = ls_e071-obj_name.
    CONDENSE lv_class NO-GAPS.

    IF lv_class IS NOT INITIAL.
      INSERT lv_class INTO TABLE lt_class_keys.
    ENDIF.
  ENDLOOP.

  " 4) Select class tồn tại một lần
  IF lt_class_keys IS NOT INITIAL.
    SELECT clsname
      FROM seoclass
      INTO TABLE @DATA(lt_seoclass_raw)
      FOR ALL ENTRIES IN @lt_class_keys
      WHERE clsname = @lt_class_keys-table_line.

    IF sy-subrc = 0.
      lt_seoclass = CORRESPONDING #( lt_seoclass_raw ).
    ENDIF.
  ENDIF.

  " 5) Xử lý từng object trong TR
  LOOP AT lt_e071 INTO ls_e071.
    CASE ls_e071-object.

      WHEN gc_objtype_prog.
        CLEAR lv_prog.
        lv_prog = ls_e071-obj_name.

        CLEAR lt_new.
        lt_new = me->run_check_program(
                   iv_prog_name       = lv_prog
                   iv_check_naming    = iv_check_naming
                   iv_check_perf      = iv_check_perf
                   iv_check_clean     = iv_check_clean
                   iv_check_hardcode  = iv_check_hardcode
                   iv_check_obsolete  = iv_check_obsolete ).
        APPEND LINES OF lt_new TO rt_errors.

      WHEN gc_objtype_clas.
        lv_class = ls_e071-obj_name.
        CONDENSE lv_class NO-GAPS.

        READ TABLE lt_seoclass
          WITH TABLE KEY clsname = lv_class
          TRANSPORTING NO FIELDS.

        IF sy-subrc = 0.
          APPEND LINES OF me->run_check_class(
                   iv_class_name      = lv_class
                   iv_check_naming    = iv_check_naming
                   iv_check_perf      = iv_check_perf
                   iv_check_clean     = iv_check_clean
                   iv_check_hardcode  = iv_check_hardcode
                   iv_check_obsolete  = iv_check_obsolete ) TO rt_errors.
        ENDIF.

      WHEN gc_objtype_fugr.
        CLEAR lv_fugr.
        lv_fugr = ls_e071-obj_name.

        CLEAR lt_new.
        lt_new = me->run_check_fugr(
                   iv_fugr            = lv_fugr
                   iv_check_naming    = iv_check_naming
                   iv_check_perf      = iv_check_perf
                   iv_check_clean     = iv_check_clean
                   iv_check_hardcode  = iv_check_hardcode
                   iv_check_obsolete  = iv_check_obsolete ).
        APPEND LINES OF lt_new TO rt_errors.

      WHEN gc_objtype_func.
        CLEAR lv_func.
        lv_func = ls_e071-obj_name.

        CLEAR lt_new.
        lt_new = me->run_check_fm(
                   iv_funcname        = lv_func
                   iv_check_naming    = iv_check_naming
                   iv_check_perf      = iv_check_perf
                   iv_check_clean     = iv_check_clean
                   iv_check_hardcode  = iv_check_hardcode
                   iv_check_obsolete  = iv_check_obsolete ).
        APPEND LINES OF lt_new TO rt_errors.

      WHEN OTHERS.
        CONTINUE.

    ENDCASE.
  ENDLOOP.

ENDMETHOD.


METHOD run_process.
  ensure_objects( ).

  CLEAR rt_errors.
  IF iv_tr IS NOT INITIAL.
    rt_errors = me->run_check_tr(
        iv_tr             = iv_tr
        iv_check_naming   = iv_check
        iv_check_perf     = iv_check
        iv_check_obsolete = iv_check
        iv_check_clean    = iv_check
        iv_check_hardcode = iv_check ).

  ELSEIF iv_clas IS NOT INITIAL.
    rt_errors = me->run_check_class(
        iv_class_name     = iv_clas
        iv_check_naming   = iv_check
        iv_check_perf     = iv_check
        iv_check_obsolete = iv_check
        iv_check_clean    = iv_check
        iv_check_hardcode = iv_check ).

  ELSEIF iv_func IS NOT INITIAL.
    rt_errors = me->run_check_fm(
        iv_funcname       = iv_func
        iv_check_naming   = iv_check
        iv_check_perf     = iv_check
        iv_check_obsolete = iv_check
        iv_check_clean    = iv_check
        iv_check_hardcode = iv_check ).

  ELSEIF iv_fugr IS NOT INITIAL.
    rt_errors = me->run_check_fugr(
        iv_fugr           = iv_fugr
        iv_check_naming   = iv_check
        iv_check_perf     = iv_check
        iv_check_obsolete = iv_check
        iv_check_clean    = iv_check
        iv_check_hardcode = iv_check ).

  ELSEIF iv_prog IS NOT INITIAL.
    rt_errors = me->run_check_program(
        iv_prog_name      = iv_prog
        iv_check_naming   = iv_check
        iv_check_perf     = iv_check
        iv_check_obsolete = iv_check
        iv_check_clean    = iv_check
        iv_check_hardcode = iv_check ).
  ENDIF.
ENDMETHOD.


METHOD run_where_used.
  ensure_objects( ).
  CLEAR: rt_founds, ev_has_more, ev_next_offset, ev_index_suspect, gt_visited.

  TYPES: BEGIN OF gty_trdir_meta,
           name TYPE trdir-name,
           subc TYPE trdir-subc,
         END OF gty_trdir_meta,
         gty_t_trdir_meta TYPE HASHED TABLE OF gty_trdir_meta WITH UNIQUE KEY name.

  TYPES: BEGIN OF gty_enlfdir_map,
           area     TYPE enlfdir-area,
           funcname TYPE enlfdir-funcname,
         END OF gty_enlfdir_map,
         gty_t_enlfdir_map TYPE STANDARD TABLE OF gty_enlfdir_map WITH EMPTY KEY.

  DATA: lt_keys  TYPE gty_t_obj_keys,
        ls_key   TYPE gty_obj_key,
        lt_all   TYPE zcl_program_whereused=>ty_founds,
        lt_found TYPE zcl_program_whereused=>ty_founds,
        lt_e071  TYPE STANDARD TABLE OF gty_e071 WITH EMPTY KEY,
        ls_e071  TYPE gty_e071,
        lv_subc  TYPE trdir-subc,
        lv_subrc TYPE sy-subrc,
        lv_sus   TYPE abap_bool,
        lv_total TYPE i,
        lv_off   TYPE i,
        lv_end   TYPE i,
        lv_livit TYPE i.

  DATA: lt_prog_keys   TYPE SORTED TABLE OF trdir-name WITH UNIQUE KEY table_line,
        lt_fugr_keys   TYPE SORTED TABLE OF enlfdir-area WITH UNIQUE KEY table_line,
        lt_trdir_meta  TYPE gty_t_trdir_meta,
        lt_enlfdir_map TYPE gty_t_enlfdir_map.

  CLEAR lt_keys.

  "------------------------------------------------------------
  " 1) Build start key(s)
  "------------------------------------------------------------
  IF iv_tr IS NOT INITIAL.

    SELECT pgmid, object, obj_name
      FROM e071
      INTO TABLE @lt_e071
      WHERE trkorr = @iv_tr.

    " 1a) Gom key trước để tránh SELECT trong loop
    LOOP AT lt_e071 INTO ls_e071.
      IF ls_e071-pgmid <> gc_pgmid_r3tr.
        CONTINUE.
      ENDIF.

      CASE ls_e071-object.
        WHEN gc_objtype_prog.
          INSERT CONV trdir-name( ls_e071-obj_name ) INTO TABLE lt_prog_keys.

        WHEN gc_objtype_fugr.
          INSERT CONV enlfdir-area( ls_e071-obj_name ) INTO TABLE lt_fugr_keys.

        WHEN OTHERS.
          CONTINUE.
      ENDCASE.
    ENDLOOP.

    " 1b) Load TRDIR một lần
    IF lt_prog_keys IS NOT INITIAL.
      SELECT name, subc
        FROM trdir
        INTO TABLE @DATA(lt_trdir_raw)
        FOR ALL ENTRIES IN @lt_prog_keys
        WHERE name = @lt_prog_keys-table_line.

      IF sy-subrc = 0.
        lt_trdir_meta = CORRESPONDING #( lt_trdir_raw ).
      ENDIF.
    ENDIF.

    " 1c) Load ENLFDIR một lần
    IF lt_fugr_keys IS NOT INITIAL.
      SELECT area, funcname
        FROM enlfdir
        INTO TABLE @lt_enlfdir_map
        FOR ALL ENTRIES IN @lt_fugr_keys
        WHERE area = @lt_fugr_keys-table_line.
    ENDIF.

    " 1d) Build key từ E071 cho CLAS / PROG / FUNC
    LOOP AT lt_e071 INTO ls_e071.

      IF ls_e071-pgmid <> gc_pgmid_r3tr.
        CONTINUE.
      ENDIF.

      CASE ls_e071-object.

        WHEN gc_objtype_clas.
          APPEND VALUE gty_obj_key(
            find_obj_cls = gc_objtype_clas
            repo_object  = gc_objtype_clas
            obj_name     = ls_e071-obj_name ) TO lt_keys.

        WHEN gc_objtype_prog.
          CLEAR lv_subc.

          READ TABLE lt_trdir_meta
            WITH TABLE KEY name = CONV trdir-name( ls_e071-obj_name )
            INTO DATA(ls_trdir_meta).

          IF sy-subrc = 0.
            lv_subc = ls_trdir_meta-subc.
          ENDIF.

          IF lv_subc = gc_subc_include.
            APPEND VALUE gty_obj_key(
              find_obj_cls = gc_objtype_incl
              repo_object  = gc_objtype_prog
              obj_name     = ls_e071-obj_name ) TO lt_keys.
          ELSE.
            APPEND VALUE gty_obj_key(
              find_obj_cls = gc_objtype_prog
              repo_object  = gc_objtype_prog
              obj_name     = ls_e071-obj_name ) TO lt_keys.
          ENDIF.

        WHEN gc_objtype_func.
          APPEND VALUE gty_obj_key(
            find_obj_cls = gc_objtype_func
            repo_object  = gc_objtype_func
            obj_name     = ls_e071-obj_name ) TO lt_keys.

        WHEN gc_objtype_fugr.
          CONTINUE.

        WHEN OTHERS.
          CONTINUE.

      ENDCASE.

    ENDLOOP.

    " 1e) Build key FUNC từ toàn bộ FUGR đã load sẵn
    LOOP AT lt_enlfdir_map INTO DATA(ls_enlfdir).
      APPEND VALUE gty_obj_key(
        find_obj_cls = gc_objtype_func
        repo_object  = gc_objtype_func
        obj_name     = ls_enlfdir-funcname ) TO lt_keys.
    ENDLOOP.

  ELSEIF iv_fugr IS NOT INITIAL.

    CLEAR lt_keys.

    DATA lt_funcs TYPE STANDARD TABLE OF rs38l-name WITH EMPTY KEY.
    SELECT funcname
      FROM enlfdir
      INTO TABLE @lt_funcs
      WHERE area = @iv_fugr.

    LOOP AT lt_funcs INTO DATA(lv_func).
      APPEND VALUE gty_obj_key(
        find_obj_cls = gc_objtype_func
        repo_object  = gc_objtype_func
        obj_name     = lv_func ) TO lt_keys.
    ENDLOOP.

    IF lt_keys IS INITIAL.
      RETURN.
    ENDIF.

  ELSEIF iv_clas IS NOT INITIAL.

    APPEND VALUE gty_obj_key(
      find_obj_cls = gc_objtype_clas
      repo_object  = gc_objtype_clas
      obj_name     = iv_clas ) TO lt_keys.

  ELSEIF iv_prog IS NOT INITIAL.

    CLEAR lv_subc.
    SELECT SINGLE subc
      FROM trdir
      INTO @lv_subc
      WHERE name = @iv_prog.

    IF sy-subrc = 0 AND lv_subc = gc_subc_include.
      APPEND VALUE gty_obj_key(
        find_obj_cls = gc_objtype_incl
        repo_object  = gc_objtype_prog
        obj_name     = iv_prog ) TO lt_keys.
    ELSE.
      APPEND VALUE gty_obj_key(
        find_obj_cls = gc_objtype_prog
        repo_object  = gc_objtype_prog
        obj_name     = iv_prog ) TO lt_keys.
    ENDIF.

  ELSEIF iv_func IS NOT INITIAL.

    APPEND VALUE gty_obj_key(
      find_obj_cls = gc_objtype_func
      repo_object  = gc_objtype_func
      obj_name     = iv_func ) TO lt_keys.

  ELSE.
    RETURN.
  ENDIF.

  SORT lt_keys BY find_obj_cls repo_object obj_name.
  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING find_obj_cls repo_object obj_name.

  "------------------------------------------------------------
  " 2) Collect where-used
  "------------------------------------------------------------
  CLEAR lt_all.

  LOOP AT lt_keys INTO ls_key.

    READ TABLE gt_visited
      WITH TABLE KEY
        find_obj_cls = ls_key-find_obj_cls
        repo_object  = ls_key-repo_object
        obj_name     = ls_key-obj_name
      TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    INSERT ls_key INTO TABLE gt_visited.

    CLEAR: lv_subrc, lv_sus, lt_found.

    lt_found = go_whereused->get_where_used(
      EXPORTING
        im_find_obj_cls     = ls_key-find_obj_cls
        im_object           = CONV rsobject( ls_key-obj_name )
        im_tadir_object     = ls_key-repo_object
        im_comment_scope    = iv_comment_scope
        im_advanced_wide    = iv_advanced_wide
        im_recursive        = iv_recursive
        im_include_comments = iv_include_comments
      IMPORTING
        ex_last_subrc       = lv_subrc
        ex_index_suspect    = lv_sus ).

    IF lv_sus = abap_true.
      ev_index_suspect = abap_true.
    ENDIF.

    IF lt_found IS NOT INITIAL.
      APPEND LINES OF lt_found TO lt_all.
    ENDIF.

  ENDLOOP.

  SORT lt_all BY used_cls used_obj program object_row.
  DELETE ADJACENT DUPLICATES FROM lt_all
    COMPARING used_cls used_obj program object_row.

  "------------------------------------------------------------
  " 3) Paging
  "------------------------------------------------------------
  DESCRIBE TABLE lt_all LINES lv_total.

  lv_off = iv_offset.
  IF lv_off < 0.
    lv_off = 0.
  ENDIF.
  IF lv_off > lv_total.
    lv_off = lv_total.
  ENDIF.

  lv_livit = iv_max_hits.
  IF lv_livit IS INITIAL OR lv_livit < 0.
    lv_livit = lv_total.
  ENDIF.

  lv_end = lv_off + lv_livit.
  IF lv_end > lv_total.
    lv_end = lv_total.
  ENDIF.

  CLEAR rt_founds.
  IF lv_total > 0 AND lv_off < lv_total.
    LOOP AT lt_all INTO DATA(ls_row) FROM lv_off + 1 TO lv_end.
      APPEND ls_row TO rt_founds.
    ENDLOOP.
  ENDIF.

  ev_has_more    = xsdbool( lv_end < lv_total ).
  ev_next_offset = COND i( WHEN ev_has_more = abap_true THEN lv_end ELSE 0 ).

ENDMETHOD.


METHOD run_check_class.
  ensure_objects( ).
  CLEAR rt_errors.

  DATA(lt_class_data) = go_fetch->get_class( iv_class_name ).

  DATA: lt_temp_errors         TYPE ztt_error,
        lv_last_user           TYPE reposrc-unam,
        lv_last_date           TYPE reposrc-udat,
        lv_text_symbol_checked TYPE abap_bool VALUE abap_false.

  LOOP AT lt_class_data INTO DATA(ls_item).
    IF ls_item-source_code IS INITIAL.
      CONTINUE.
    ENDIF.

    SELECT SINGLE unam, udat
      FROM reposrc
      INTO (@lv_last_user, @lv_last_date)
      WHERE progname = @ls_item-include.

    IF sy-subrc <> 0.
      lv_last_user = gc_user_unknown.
      lv_last_date = sy-datum.
    ENDIF.

    IF lv_last_user = gc_user_sap
       OR lv_last_user = gc_user_ddic.
      CONTINUE.
    ENDIF.

    CLEAR lt_temp_errors.

    DATA(ls_ctx) = VALUE zcl_program_check=>gty_naming_ctx(
      obj_type = gc_objtype_clas
      obj_name = iv_class_name
      include  = ls_item-include ).

    IF iv_check_naming = abap_true.
      APPEND LINES OF go_check->analyze_naming(
        is_ctx    = ls_ctx
        it_source = ls_item-source_code ) TO lt_temp_errors.
    ENDIF.

    IF iv_check_perf = abap_true.
      APPEND LINES OF go_check->analyze_performance(
        is_ctx    = ls_ctx
        it_source = ls_item-source_code ) TO lt_temp_errors.
    ENDIF.

    IF iv_check_clean = abap_true.
      APPEND LINES OF go_check->analyze_clean_code(
        is_ctx               = ls_ctx
        it_source            = ls_item-source_code
        iv_check_unused_text = COND abap_bool(
          WHEN lv_text_symbol_checked = abap_false
          THEN abap_true
          ELSE abap_false ) ) TO lt_temp_errors.

      lv_text_symbol_checked = abap_true.
    ENDIF.

    IF iv_check_hardcode = abap_true.
      APPEND LINES OF go_check->analyze_hardcode(
        is_ctx    = ls_ctx
        it_source = ls_item-source_code ) TO lt_temp_errors.
    ENDIF.

    IF iv_check_obsolete = abap_true.
      APPEND LINES OF go_check->analyze_obsolete(
        is_ctx    = ls_ctx
        it_source = ls_item-source_code ) TO lt_temp_errors.
    ENDIF.

    LOOP AT lt_temp_errors ASSIGNING FIELD-SYMBOL(<fs_err>).
      <fs_err>-objtype  = gc_objtype_clas.
      <fs_err>-objname  = iv_class_name.
      <fs_err>-chk_usr  = lv_last_user.
      <fs_err>-chk_date = lv_last_date.
      <fs_err>-include  = ls_item-include.
    ENDLOOP.

    APPEND LINES OF lt_temp_errors TO rt_errors.
  ENDLOOP.

  SORT rt_errors
  BY objname include line rule msg.

  DELETE ADJACENT DUPLICATES FROM rt_errors COMPARING objname include line rule msg.
ENDMETHOD.
ENDCLASS.
