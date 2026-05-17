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
        !it_comment_scope    TYPE zcl_program_whereused=>gty_r_devclass OPTIONAL
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
        VALUE(rt_founds)     TYPE zcl_program_whereused=>gty_t_founds .

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
    gc_kind         TYPE string        VALUE 'SECTION',
    gc_fugr_prefix  TYPE string        VALUE 'SAPL'.
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

  DATA: lv_funcname  TYPE rs38l-name,
        lv_fugr      TYPE rs38l-area,
        lv_pname     TYPE progname,
        lv_include   TYPE progname,
        lv_last_user TYPE reposrc-unam,
        lv_last_date TYPE reposrc-udat,
        lt_all_err   TYPE ztt_error.

  DATA: lt_sources             TYPE zcl_program_fetch=>gty_t_program_source,
        lt_source              TYPE string_table,
        lt_clean_usage_source  TYPE string_table,
        ls_src                 TYPE zcl_program_fetch=>gty_program_source,
        lv_text_symbol_checked TYPE abap_bool VALUE abap_false.

  DATA lv_msg TYPE string.

  lv_funcname = iv_funcname.
  TRANSLATE lv_funcname TO UPPER CASE.
  CONDENSE lv_funcname NO-GAPS.

  "------------------------------------------------------------
  " 1) Get FM metadata
  "------------------------------------------------------------
  SELECT SINGLE pname, include
    FROM tfdir
    INTO (@lv_pname, @lv_include)
    WHERE funcname = @lv_funcname.

  SELECT SINGLE area
    FROM enlfdir
    INTO @lv_fugr
    WHERE funcname = @lv_funcname.

  "------------------------------------------------------------
  " 2) Fetch current FM source as fallback
  "------------------------------------------------------------
  lt_sources = go_fetch->get_function_module(
    iv_funcname = lv_funcname ).

  IF lt_sources IS INITIAL.
    MESSAGE e034(z_gsp04_message) WITH lv_funcname INTO lv_msg.

    APPEND VALUE zst_error(
      objtype = gc_objtype_fm
      objname = lv_funcname
      include = ''
      line    = 0
      sev     = gc_sev_error
      msg     = lv_msg
      chk_usr = gc_user_unknown
    ) TO rt_errors.

    RETURN.
  ENDIF.

  "Fallback nếu TFDIR chưa trả đủ.
  IF lv_pname IS INITIAL.
    READ TABLE lt_sources INTO ls_src INDEX 1.
    IF sy-subrc = 0.
      lv_pname = ls_src-include.
    ENDIF.
  ENDIF.

  IF lv_include IS INITIAL.
    READ TABLE lt_sources INTO ls_src INDEX 2.
    IF sy-subrc = 0.
      lv_include = ls_src-include.
    ENDIF.
  ENDIF.

  "------------------------------------------------------------
  " 3) Fetch full function group source
  "------------------------------------------------------------
  DATA(lt_fg_sources) = go_fetch->get_function_group( iv_fg_name = lv_fugr ).

  "Nếu không lấy được FG source thì fallback về source của FM.
  IF lt_fg_sources IS INITIAL.
    lt_fg_sources = CORRESPONDING #( lt_sources ).
  ENDIF.

  "------------------------------------------------------------
  " 4) Get current FM include source
  "------------------------------------------------------------
  CLEAR: lt_source,
         ls_src.
  SORT lt_fg_sources BY include.
  READ TABLE lt_fg_sources INTO DATA(ls_fg_src)
  WITH KEY include = lv_include
  BINARY SEARCH.

  IF sy-subrc = 0 AND ls_fg_src-source_code IS NOT INITIAL.
    lt_source = ls_fg_src-source_code.
  ELSE.
    READ TABLE lt_sources INTO ls_src INDEX 2.
    IF sy-subrc = 0 AND ls_src-source_code IS NOT INITIAL.
      lv_include = ls_src-include.
      lt_source  = ls_src-source_code.
    ENDIF.
  ENDIF.

  IF lt_source IS INITIAL.
    MESSAGE e035(z_gsp04_message) WITH lv_funcname INTO lv_msg.

    APPEND VALUE zst_error(
      objtype = gc_objtype_fm
      objname = lv_funcname
      include = ''
      line    = 0
      sev     = gc_sev_error
      msg     = lv_msg
      chk_usr = gc_user_unknown
    ) TO rt_errors.

    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " 5) Build clean usage source
  "------------------------------------------------------------
  CLEAR lt_clean_usage_source.

  "Current FM include phải đứng đầu để row của current source map đúng.
  APPEND LINES OF lt_source TO lt_clean_usage_source.

  LOOP AT lt_fg_sources INTO DATA(ls_usage_src).
    IF ls_usage_src-include = lv_include.
      CONTINUE.
    ENDIF.

    IF ls_usage_src-source_code IS INITIAL.
      CONTINUE.
    ENDIF.

    APPEND LINES OF ls_usage_src-source_code TO lt_clean_usage_source.
  ENDLOOP.

  "------------------------------------------------------------
  " 6) Read metadata
  "------------------------------------------------------------
  SELECT SINGLE unam, udat
    FROM reposrc
    INTO (@lv_last_user, @lv_last_date)
    WHERE progname = @lv_include.

  IF sy-subrc <> 0.
    lv_last_user = gc_user_unknown.
    lv_last_date = sy-datum.
  ENDIF.

  CLEAR lt_all_err.

  DATA(ls_ctx) = VALUE zcl_program_check=>gty_naming_ctx(
    obj_type  = gc_objtype_fm
    obj_name  = lv_funcname
    main_prog = lv_pname
    include   = lv_include ).

  IF iv_check_naming = abap_true.
    APPEND LINES OF go_check->analyze_naming( is_ctx    = ls_ctx
                                              it_source = lt_source ) TO lt_all_err.
  ENDIF.

  IF iv_check_clean = abap_true.
    APPEND LINES OF go_check->analyze_clean_code(
      is_ctx               = ls_ctx
      it_source            = lt_source
      it_usage_source      = lt_clean_usage_source
      iv_check_unused_text = COND abap_bool(
        WHEN lv_text_symbol_checked = abap_false
        THEN abap_true
        ELSE abap_false ) ) TO lt_all_err.
    lv_text_symbol_checked = abap_true.
  ENDIF.

  IF iv_check_hardcode = abap_true.
    APPEND LINES OF go_check->analyze_hardcode( is_ctx    = ls_ctx
                                                it_source = lt_source ) TO lt_all_err.
  ENDIF.

  IF iv_check_obsolete = abap_true.
    APPEND LINES OF go_check->analyze_obsolete( is_ctx    = ls_ctx
                                                it_source = lt_source ) TO lt_all_err.
  ENDIF.

  IF iv_check_perf = abap_true.
    APPEND LINES OF go_check->analyze_performance( is_ctx    = ls_ctx
                                                   it_source = lt_source ) TO lt_all_err.
  ENDIF.

  LOOP AT lt_all_err ASSIGNING FIELD-SYMBOL(<lfs_err>).
    <lfs_err>-objtype  = ls_ctx-obj_type.
    <lfs_err>-objname  = lv_funcname.
    <lfs_err>-include  = lv_include.
    <lfs_err>-chk_usr  = lv_last_user.
    <lfs_err>-chk_date = lv_last_date.
  ENDLOOP.

  SORT lt_all_err BY objtype objname include line msg.
  DELETE ADJACENT DUPLICATES FROM lt_all_err
    COMPARING objtype objname include line msg.

  APPEND LINES OF lt_all_err TO rt_errors.
ENDMETHOD.


METHOD run_check_fugr.

  TYPES: BEGIN OF lty_reposrc_meta,
           progname TYPE reposrc-progname,
           unam     TYPE reposrc-unam,
           udat     TYPE reposrc-udat,
         END OF lty_reposrc_meta,
         lty_t_reposrc_meta TYPE HASHED TABLE OF lty_reposrc_meta WITH UNIQUE KEY progname.


  DATA: lv_msg                 TYPE string,
        lv_fugr                TYPE rs38l-area,
        lv_main_prog           TYPE progname,
        lv_last_user           TYPE reposrc-unam,
        lv_last_date           TYPE reposrc-udat,
        lv_text_symbol_checked TYPE abap_bool VALUE abap_false.

  DATA: lt_all_err            TYPE ztt_error,
        lt_src_keys           TYPE SORTED TABLE OF reposrc-progname WITH UNIQUE KEY table_line,
        lt_repo_meta          TYPE lty_t_reposrc_meta,
        lt_clean_usage_source TYPE string_table.

  FIELD-SYMBOLS: <lfs_err> TYPE zst_error.

  ensure_objects( ).
  CLEAR rt_errors.

  lv_fugr = iv_fugr.
  TRANSLATE lv_fugr TO UPPER CASE.
  CONDENSE lv_fugr NO-GAPS.

  lv_main_prog = |{ gc_fugr_prefix }{ lv_fugr }|.

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
  " 5) Run source-based checks include by include
  "------------------------------------------------------------
  LOOP AT lt_sources INTO DATA(ls_src).

    IF ls_src-source_code IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR: lt_all_err,
           lv_last_user,
           lv_last_date.

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

    "Current include phải đứng đầu để row của current source map đúng.
    APPEND LINES OF ls_src-source_code TO lt_clean_usage_source.

    APPEND LINES OF ls_src-source_code
      TO lt_clean_usage_source.

    lt_clean_usage_source = VALUE string_table(
      BASE lt_clean_usage_source
      FOR ls_usage_src IN lt_sources
      WHERE ( include <> ls_src-include )
      FOR lv_usage_line IN ls_usage_src-source_code
      ( lv_usage_line )
    ).

    DATA(ls_ctx) = VALUE zcl_program_check=>gty_naming_ctx( obj_type  = gc_objtype_fugr
                                                            obj_name  = lv_fugr
                                                            main_prog = lv_main_prog
                                                            include   = ls_src-include ).

    IF iv_check_naming = abap_true.
      APPEND LINES OF go_check->analyze_naming( is_ctx    = ls_ctx
                                                it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_clean = abap_true.
      APPEND LINES OF go_check->analyze_clean_code( is_ctx               = ls_ctx
                                                    it_source            = ls_src-source_code
                                                    it_usage_source      = lt_clean_usage_source
                                                    iv_check_unused_text = COND abap_bool( WHEN lv_text_symbol_checked = abap_false
                                                                                           THEN abap_true
                                                                                           ELSE abap_false ) ) TO lt_all_err.
      lv_text_symbol_checked = abap_true.
    ENDIF.

    IF iv_check_hardcode = abap_true.
      APPEND LINES OF go_check->analyze_hardcode( is_ctx    = ls_ctx
                                                  it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_obsolete = abap_true.
      APPEND LINES OF go_check->analyze_obsolete( is_ctx    = ls_ctx
                                                  it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_perf = abap_true.
      APPEND LINES OF go_check->analyze_performance( is_ctx    = ls_ctx
                                                     it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    LOOP AT lt_all_err ASSIGNING <lfs_err>.
      <lfs_err>-objtype  = gc_objtype_fugr.
      <lfs_err>-objname  = lv_fugr.
      <lfs_err>-include  = ls_src-include.
      <lfs_err>-chk_usr  = lv_last_user.
      <lfs_err>-chk_date = lv_last_date.
    ENDLOOP.
    APPEND LINES OF lt_all_err TO rt_errors.

  ENDLOOP.

  "------------------------------------------------------------
  " 6) Final de-dup
  "------------------------------------------------------------
  SORT rt_errors BY objtype objname include line msg.
  DELETE ADJACENT DUPLICATES FROM rt_errors
    COMPARING objtype objname include line msg.

ENDMETHOD.


METHOD run_check_program.
  ensure_objects( ).
  CLEAR rt_errors.

  DATA: lt_include_keys TYPE SORTED TABLE OF reposrc-progname
                             WITH UNIQUE KEY table_line,
        lt_reposrc_meta TYPE gty_t_reposrc_meta,
        lt_all_err      TYPE ztt_error.

  DATA(lt_program_sources) = go_fetch->get_program_source( iv_prog_name ).
  DATA lv_text_symbol_checked TYPE abap_bool VALUE abap_false.
  DATA lt_clean_usage_source  TYPE string_table.

  "------------------------------------------------------------
  "Prepare include keys for REPOSRC metadata
  "------------------------------------------------------------
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

  "------------------------------------------------------------
  "Run Check
  "------------------------------------------------------------
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

    CLEAR lt_clean_usage_source.

    " Current include phải đứng đầu để row của current source map đúng
    APPEND LINES OF ls_src-source_code
      TO lt_clean_usage_source.

    lt_clean_usage_source = VALUE string_table(
      BASE lt_clean_usage_source
      FOR ls_usage_src IN lt_program_sources
      WHERE ( include <> ls_src-include )
      FOR lv_usage_line IN ls_usage_src-source_code
      ( lv_usage_line )
    ).

    DATA(ls_ctx) = VALUE zcl_program_check=>gty_naming_ctx( obj_type  = gc_objtype_prog
                                                            obj_name  = iv_prog_name
                                                            main_prog = iv_prog_name
                                                            include   = ls_src-include ).
    CLEAR lt_all_err.

    IF iv_check_naming = abap_true.
      APPEND LINES OF go_check->analyze_naming( is_ctx    = ls_ctx
                                                it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_clean = abap_true.
      APPEND LINES OF go_check->analyze_clean_code( is_ctx               = ls_ctx
                                                    it_source            = ls_src-source_code
                                                    it_usage_source      = lt_clean_usage_source
                                                    iv_check_unused_text = COND abap_bool( WHEN lv_text_symbol_checked = abap_false
                                                                                           THEN abap_true
                                                                                           ELSE abap_false ) ) TO lt_all_err.
      lv_text_symbol_checked = abap_true.
    ENDIF.

    IF iv_check_hardcode = abap_true.
      APPEND LINES OF go_check->analyze_hardcode( is_ctx    = ls_ctx
                                                  it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_obsolete = abap_true.
      APPEND LINES OF go_check->analyze_obsolete( is_ctx    = ls_ctx
                                                  it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    IF iv_check_perf = abap_true.
      APPEND LINES OF go_check->analyze_performance( is_ctx    = ls_ctx
                                                     it_source = ls_src-source_code ) TO lt_all_err.
    ENDIF.

    LOOP AT lt_all_err ASSIGNING FIELD-SYMBOL(<lfs_err>).
      <lfs_err>-objname  = iv_prog_name.
      <lfs_err>-chk_usr  = lv_last_user.
      <lfs_err>-chk_date = lv_last_date.
      <lfs_err>-include  = ls_src-include.
      <lfs_err>-objtype  = gc_objtype_prog.
    ENDLOOP.

    APPEND LINES OF lt_all_err TO rt_errors.
  ENDLOOP.

  SORT rt_errors
    BY objname
       include
       line
       msg.

  DELETE ADJACENT DUPLICATES FROM rt_errors
    COMPARING objname include line msg.

ENDMETHOD.


METHOD run_check_tr.
  ensure_objects( ).
  CLEAR rt_errors.

  TYPES: BEGIN OF lty_d010inc_map,
         include TYPE d010inc-include,
         master  TYPE d010inc-master,
         END OF lty_d010inc_map,
       lty_t_d010inc_map TYPE HASHED TABLE OF lty_d010inc_map WITH UNIQUE KEY include.

  DATA: lt_e071        TYPE STANDARD TABLE OF gty_e071,
        ls_e071        TYPE gty_e071,
        lv_prog        TYPE progname,
        lv_master_prog TYPE progname,
        lv_fugr        TYPE rs38l-area,
        lv_func        TYPE rs38l-name,
        lv_class       TYPE seoclsname,
        lt_new         TYPE ztt_error.

  DATA: lt_d010inc_map  TYPE lty_t_d010inc_map,
        lt_seoclass     TYPE gty_t_seoclass_key,
        lt_prog_keys    TYPE SORTED TABLE OF d010inc-include
                                  WITH UNIQUE KEY table_line,

        lt_class_keys   TYPE SORTED TABLE OF seoclass-clsname
                                   WITH UNIQUE KEY table_line.

  DATA: lt_prog_done  TYPE SORTED TABLE OF progname
                         WITH UNIQUE KEY table_line,

        lt_class_done TYPE SORTED TABLE OF seoclsname
                           WITH UNIQUE KEY table_line,

        lt_fugr_done  TYPE SORTED TABLE OF rs38l-area
                           WITH UNIQUE KEY table_line,

        lt_func_done  TYPE SORTED TABLE OF rs38l-name
                           WITH UNIQUE KEY table_line.

  "------------------------------------------------------------
  " Get TR Object
  "------------------------------------------------------------
  SELECT pgmid, object, obj_name
    FROM e071
    INTO TABLE @lt_e071
    WHERE trkorr = @iv_tr.

  IF lt_e071 IS INITIAL.
    MESSAGE e003(z_gsp04_message) WITH iv_tr.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  "
  "------------------------------------------------------------
  SORT lt_e071 BY pgmid object obj_name.
  DELETE ADJACENT DUPLICATES FROM lt_e071
    COMPARING pgmid object obj_name.

  "------------------------------------------------------------
  " Gather Class name
  "------------------------------------------------------------
  LOOP AT lt_e071
    INTO ls_e071
    WHERE object = gc_objtype_clas.

    lv_class = ls_e071-obj_name.

    TRANSLATE lv_class TO UPPER CASE.
    CONDENSE lv_class NO-GAPS.

    IF lv_class IS NOT INITIAL.
      INSERT lv_class INTO TABLE lt_class_keys.
    ENDIF.
  ENDLOOP.

  "------------------------------------------------------------
  " Select class exsit once
  "------------------------------------------------------------
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
  "------------------------------------------------------------
  " Gather Progam / Include to read usage one
  "------------------------------------------------------------
  LOOP AT lt_e071 INTO ls_e071 WHERE object = gc_objtype_prog.

    lv_prog = ls_e071-obj_name.
    TRANSLATE lv_prog TO UPPER CASE.
    CONDENSE lv_prog NO-GAPS.

    IF lv_prog IS NOT INITIAL.
      INSERT lv_prog INTO TABLE lt_prog_keys.
    ENDIF.

  ENDLOOP.
  "------------------------------------------------------------
  " Select include -> master program once
  "------------------------------------------------------------
  IF lt_prog_keys IS NOT INITIAL.

    SELECT include, master
      FROM d010inc
      INTO TABLE @DATA(lt_d010inc_raw)
      FOR ALL ENTRIES IN @lt_prog_keys
      WHERE include = @lt_prog_keys-table_line.

    IF sy-subrc = 0.

      SORT lt_d010inc_raw BY include master.
      DELETE ADJACENT DUPLICATES FROM lt_d010inc_raw
        COMPARING include.

      lt_d010inc_map = CORRESPONDING #( lt_d010inc_raw ).

    ENDIF.

  ENDIF.

  "------------------------------------------------------------
  " Run check
  "------------------------------------------------------------
  LOOP AT lt_e071 INTO ls_e071.
    CASE ls_e071-object.

      WHEN gc_objtype_prog.

        CLEAR: lv_prog,
               lv_master_prog,
               lt_new.

        lv_prog = ls_e071-obj_name.
        TRANSLATE lv_prog TO UPPER CASE.
        CONDENSE lv_prog NO-GAPS.

        IF lv_prog IS INITIAL.
          CONTINUE.
        ENDIF.

        "If program like INCLUDE *_T01, *_F00, *_F01
        "Then map to master program to run_check_program .
        READ TABLE lt_d010inc_map
          WITH TABLE KEY include =  lv_prog
          INTO DATA(ls_d010inc_map).

        IF sy-subrc = 0 AND ls_d010inc_map-master IS NOT INITIAL.
          lv_master_prog = ls_d010inc_map-master.

          lv_prog = lv_master_prog.
          TRANSLATE lv_prog TO UPPER CASE.
          CONDENSE lv_prog NO-GAPS.
        ENDIF.


        "Chỉ check một lần cho cùng master program.
        READ TABLE lt_prog_done
          WITH TABLE KEY table_line = lv_prog
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.

        INSERT lv_prog INTO TABLE lt_prog_done.

        lt_new = me->run_check_program(
                   iv_prog_name       = lv_prog
                   iv_check_naming    = iv_check_naming
                   iv_check_perf      = iv_check_perf
                   iv_check_clean     = iv_check_clean
                   iv_check_hardcode  = iv_check_hardcode
                   iv_check_obsolete  = iv_check_obsolete ).

        APPEND LINES OF lt_new TO rt_errors.

      WHEN gc_objtype_clas.

        CLEAR lv_class.

        lv_class = ls_e071-obj_name.
        TRANSLATE lv_class TO UPPER CASE.
        CONDENSE lv_class NO-GAPS.

        IF lv_class IS INITIAL.
          CONTINUE.
        ENDIF.

        READ TABLE lt_class_done
          WITH TABLE KEY table_line = lv_class
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.

        READ TABLE lt_seoclass
          WITH TABLE KEY clsname = lv_class
          TRANSPORTING NO FIELDS.

        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        INSERT lv_class INTO TABLE lt_class_done.

        APPEND LINES OF me->run_check_class(
                 iv_class_name      = lv_class
                 iv_check_naming    = iv_check_naming
                 iv_check_perf      = iv_check_perf
                 iv_check_clean     = iv_check_clean
                 iv_check_hardcode  = iv_check_hardcode
                 iv_check_obsolete  = iv_check_obsolete ) TO rt_errors.

      WHEN gc_objtype_fugr.

        CLEAR: lv_fugr,
               lt_new.

        lv_fugr = ls_e071-obj_name.
        TRANSLATE lv_fugr TO UPPER CASE.
        CONDENSE lv_fugr NO-GAPS.

        IF lv_fugr IS INITIAL.
          CONTINUE.
        ENDIF.

        READ TABLE lt_fugr_done
          WITH TABLE KEY table_line = lv_fugr
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.

        INSERT lv_fugr INTO TABLE lt_fugr_done.

        lt_new = me->run_check_fugr(
                   iv_fugr            = lv_fugr
                   iv_check_naming    = iv_check_naming
                   iv_check_perf      = iv_check_perf
                   iv_check_clean     = iv_check_clean
                   iv_check_hardcode  = iv_check_hardcode
                   iv_check_obsolete  = iv_check_obsolete ).
        APPEND LINES OF lt_new TO rt_errors.

      WHEN gc_objtype_func.

        CLEAR: lv_func,
               lt_new.

        lv_func = ls_e071-obj_name.
        TRANSLATE lv_func TO UPPER CASE.
        CONDENSE lv_func NO-GAPS.

        IF lv_func IS INITIAL.
          CONTINUE.
        ENDIF.

        READ TABLE lt_func_done
          WITH TABLE KEY table_line = lv_func
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.

        INSERT lv_func INTO TABLE lt_func_done.

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

  CLEAR: rt_founds,
         ev_has_more,
         ev_next_offset,
         ev_index_suspect,
         gt_visited.

  TYPES: BEGIN OF lty_trdir_meta,
           name TYPE trdir-name,
           subc TYPE trdir-subc,
         END OF lty_trdir_meta,
         lty_t_trdir_meta TYPE HASHED TABLE OF lty_trdir_meta
           WITH UNIQUE KEY name.

  TYPES: BEGIN OF lty_fugr_func_map,
           area     TYPE tlibg-area,
           funcname TYPE rs38l-name,
         END OF lty_fugr_func_map,
         lty_t_fugr_func_map TYPE STANDARD TABLE OF lty_fugr_func_map
           WITH EMPTY KEY.

  DATA: lt_keys          TYPE gty_t_obj_keys,
        ls_key           TYPE gty_obj_key,
        lt_all           TYPE zcl_program_whereused=>gty_t_founds,
        lt_found         TYPE zcl_program_whereused=>gty_t_founds,
        lt_e071          TYPE STANDARD TABLE OF gty_e071 WITH EMPTY KEY,
        ls_e071          TYPE gty_e071,
        lv_subc          TYPE trdir-subc,
        lv_sus           TYPE abap_bool,
        lv_trkorr_chk    TYPE e070-trkorr,
        lv_total         TYPE i,
        lv_off           TYPE i,
        lv_end           TYPE i,
        lv_livit         TYPE i.

  DATA: lt_prog_keys     TYPE SORTED TABLE OF trdir-name WITH UNIQUE KEY table_line,
        lt_fugr_keys     TYPE SORTED TABLE OF tlibg-area WITH UNIQUE KEY table_line,
        lt_trdir_meta    TYPE lty_t_trdir_meta,
        lt_fugr_func_map TYPE lty_t_fugr_func_map.

  DATA: lt_functab       TYPE STANDARD TABLE OF rs38l_incl WITH EMPTY KEY,
        ls_functab       TYPE rs38l_incl,
        lv_fugr_key      TYPE tlibg-area,
        lv_area_chk      TYPE tlibg-area,
        lv_clsname_chk   TYPE seoclass-clsname,
        lv_func_chk      TYPE tfdir-funcname.

  CLEAR lt_keys.

  "------------------------------------------------------------
  " 1) Build start key(s) + validate existence
  "------------------------------------------------------------
  IF iv_tr IS NOT INITIAL.

    CLEAR lv_trkorr_chk.

    SELECT SINGLE trkorr
      FROM e070
      INTO @lv_trkorr_chk
      WHERE trkorr = @iv_tr.

    IF lv_trkorr_chk IS INITIAL.
      MESSAGE s003(z_gsp04_message) WITH iv_tr.
      RETURN.
    ENDIF.

    SELECT pgmid, object, obj_name
      FROM e071
      INTO TABLE @lt_e071
      WHERE trkorr = @iv_tr.

    IF lt_e071 IS INITIAL.
      MESSAGE s069(z_gsp04_message) WITH iv_tr.
      RETURN.
    ENDIF.

    "----------------------------------------------------------
    " 1a) Collect PROG and FUGR keys from transport
    "----------------------------------------------------------
    LOOP AT lt_e071 INTO ls_e071.

      IF ls_e071-pgmid <> gc_pgmid_r3tr.
        CONTINUE.
      ENDIF.

      CASE ls_e071-object.

        WHEN gc_objtype_prog.
          INSERT CONV trdir-name( ls_e071-obj_name )
            INTO TABLE lt_prog_keys.

        WHEN gc_objtype_fugr.
          INSERT CONV tlibg-area( ls_e071-obj_name )
            INTO TABLE lt_fugr_keys.

        WHEN OTHERS.
          CONTINUE.

      ENDCASE.

    ENDLOOP.

    "----------------------------------------------------------
    " 1b) Load TRDIR metadata for PROG/INCL distinction
    "----------------------------------------------------------
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

    "----------------------------------------------------------
    " 1c) Expand FUGR -> FUNC using SAP repository API
    "     Avoid direct SELECT on ENLFDIR by AREA because ENLFDIR
    "     is single-record buffered and AREA access bypasses buffer.
    "----------------------------------------------------------
    IF lt_fugr_keys IS NOT INITIAL.

      LOOP AT lt_fugr_keys INTO lv_fugr_key.

        CLEAR lt_functab.

        CALL FUNCTION 'RS_FUNCTION_POOL_CONTENTS'
          EXPORTING
            function_pool           = lv_fugr_key
          TABLES
            functab                 = lt_functab
          EXCEPTIONS
            function_pool_not_found = 1
            OTHERS                  = 2.

        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        LOOP AT lt_functab INTO ls_functab.

          IF ls_functab-funcname IS INITIAL.
            CONTINUE.
          ENDIF.

          APPEND VALUE lty_fugr_func_map(
            area     = lv_fugr_key
            funcname = ls_functab-funcname ) TO lt_fugr_func_map.

        ENDLOOP.

      ENDLOOP.

    ENDIF.

    "----------------------------------------------------------
    " 1d) Build keys from E071: CLAS / PROG / FUNC
    "----------------------------------------------------------
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

          " FUGR itself is expanded to FUNC keys above.
          CONTINUE.

        WHEN OTHERS.
          CONTINUE.

      ENDCASE.

    ENDLOOP.

    "----------------------------------------------------------
    " 1e) Add function modules expanded from FUGR
    "----------------------------------------------------------
    LOOP AT lt_fugr_func_map INTO DATA(ls_fugr_func).

      APPEND VALUE gty_obj_key(
        find_obj_cls = gc_objtype_func
        repo_object  = gc_objtype_func
        obj_name     = ls_fugr_func-funcname ) TO lt_keys.

    ENDLOOP.

    IF lt_keys IS INITIAL.
      MESSAGE s070(z_gsp04_message) WITH iv_tr.
      RETURN.
    ENDIF.

  ELSEIF iv_fugr IS NOT INITIAL.

    "----------------------------------------------------------
    " Validate function group
    "----------------------------------------------------------
    CLEAR lv_area_chk.

    SELECT SINGLE area
      FROM tlibg
      INTO @lv_area_chk
      WHERE area = @iv_fugr.

    IF sy-subrc <> 0.
      MESSAGE s007(z_gsp04_message) WITH iv_fugr.
      RETURN.
    ENDIF.

    CLEAR: lt_keys,
           lt_functab.

    "----------------------------------------------------------
    " Expand FUGR -> FUNC using SAP repository API
    "----------------------------------------------------------
    CALL FUNCTION 'RS_FUNCTION_POOL_CONTENTS'
      EXPORTING
        function_pool           = iv_fugr
      TABLES
        functab                 = lt_functab
      EXCEPTIONS
        function_pool_not_found = 1
        OTHERS                  = 2.

    IF sy-subrc <> 0.
      MESSAGE s072(z_gsp04_message) WITH iv_fugr.
      RETURN.
    ENDIF.

    LOOP AT lt_functab INTO ls_functab.

      IF ls_functab-funcname IS INITIAL.
        CONTINUE.
      ENDIF.

      APPEND VALUE gty_obj_key(
        find_obj_cls = gc_objtype_func
        repo_object  = gc_objtype_func
        obj_name     = ls_functab-funcname ) TO lt_keys.

    ENDLOOP.

    IF lt_keys IS INITIAL.
      MESSAGE s072(z_gsp04_message) WITH iv_fugr.
      RETURN.
    ENDIF.

  ELSEIF iv_clas IS NOT INITIAL.

    CLEAR lv_clsname_chk.

    SELECT SINGLE clsname
      FROM seoclass
      INTO @lv_clsname_chk
      WHERE clsname = @iv_clas.

    IF sy-subrc <> 0.
      MESSAGE s019(z_gsp04_message) WITH iv_clas.
      RETURN.
    ENDIF.

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

    IF sy-subrc <> 0.
      MESSAGE s002(z_gsp04_message) WITH iv_prog.
      RETURN.
    ENDIF.

    IF lv_subc = gc_subc_include.

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

    CLEAR lv_func_chk.

    SELECT SINGLE funcname
      FROM tfdir
      INTO @lv_func_chk
      WHERE funcname = @iv_func.

    IF sy-subrc <> 0.
      MESSAGE s042(z_gsp04_message) WITH iv_func.
      RETURN.
    ENDIF.

    APPEND VALUE gty_obj_key(
      find_obj_cls = gc_objtype_func
      repo_object  = gc_objtype_func
      obj_name     = iv_func ) TO lt_keys.

  ELSE.

    RETURN.

  ENDIF.

  "------------------------------------------------------------
  " Deduplicate start keys
  "------------------------------------------------------------
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

    CLEAR: lv_sus,
           lt_found.

    lt_found = go_whereused->get_where_used(
      EXPORTING
        iv_find_obj_cls     = ls_key-find_obj_cls
        iv_object           = CONV rsobject( ls_key-obj_name )
        iv_tadir_object     = ls_key-repo_object
        is_comment_scope    = it_comment_scope
        iv_advanced_wide    = iv_advanced_wide
        iv_recursive        = iv_recursive
        iv_include_comments = iv_include_comments
      IMPORTING
        ev_index_suspect    = lv_sus ).

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
  ev_next_offset = COND i(
                     WHEN ev_has_more = abap_true
                     THEN lv_end
                     ELSE 0 ).

  "------------------------------------------------------------
  " 4) No where-used found
  "------------------------------------------------------------
  IF rt_founds IS INITIAL.

    IF iv_prog IS NOT INITIAL.
      MESSAGE s071(z_gsp04_message) WITH iv_prog.

    ELSEIF iv_fugr IS NOT INITIAL.
      MESSAGE s072(z_gsp04_message) WITH iv_fugr.

    ELSEIF iv_func IS NOT INITIAL.
      MESSAGE s073(z_gsp04_message) WITH iv_func.

    ELSEIF iv_clas IS NOT INITIAL.
      MESSAGE s074(z_gsp04_message) WITH iv_clas.

    ELSEIF iv_tr IS NOT INITIAL.
      MESSAGE s075(z_gsp04_message) WITH iv_tr.

    ENDIF.

  ENDIF.

ENDMETHOD.


METHOD run_check_class.
  ensure_objects( ).
  CLEAR rt_errors.

  TYPES: BEGIN OF lty_reposrc_meta,
           progname TYPE reposrc-progname,
           unam     TYPE reposrc-unam,
           udat     TYPE reposrc-udat,
         END OF lty_reposrc_meta,
         lty_t_reposrc_meta TYPE HASHED TABLE OF lty_reposrc_meta
           WITH UNIQUE KEY progname.

  DATA(lt_class_data) = go_fetch->get_class( iv_class_name ).

  DATA: lt_temp_errors            TYPE ztt_error,
        lt_clean_usage_source TYPE string_table,
        lt_class_sig_source       TYPE string_table,
        lt_src_keys               TYPE SORTED TABLE OF reposrc-progname WITH UNIQUE KEY table_line,
        lt_repo_meta              TYPE lty_t_reposrc_meta,
        lv_last_user              TYPE reposrc-unam,
        lv_last_date              TYPE reposrc-udat,
        lv_text_symbol_checked    TYPE abap_bool VALUE abap_false.
  "-----------------------
  "Prepare class signature
  "-----------------------
  LOOP AT lt_class_data INTO DATA(ls_class_sig)

   WHERE include_kind = gc_kind.
    APPEND LINES OF ls_class_sig-source_code
      TO lt_class_sig_source.

  ENDLOOP.
  "-----------------------
  "Prepare include keys
  "-----------------------
  LOOP AT lt_class_data INTO DATA(ls_src_key).

    IF ls_src_key-include IS NOT INITIAL.
      INSERT ls_src_key-include INTO TABLE lt_src_keys.
    ENDIF.

  ENDLOOP.
  "-----------------------
  "Load REPOSR metdata once
  "-----------------------
  IF lt_src_keys IS NOT INITIAL.
    SELECT progname, unam, udat
      FROM reposrc
      INTO TABLE @DATA(lt_repo_raw)
      FOR ALL ENTRIES IN @lt_src_keys
      WHERE progname = @lt_src_keys-table_line.

    IF sy-subrc = 0.

       SORT lt_repo_raw
        BY progname
           udat DESCENDING
           unam DESCENDING.

      DELETE ADJACENT DUPLICATES FROM lt_repo_raw
        COMPARING progname.

      lt_repo_meta = CORRESPONDING #( lt_repo_raw ).
    ENDIF.
  ENDIF.

  "-----------------------
  "Run Check
  "-----------------------
  LOOP AT lt_class_data INTO DATA(ls_item).

    IF ls_item-source_code IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR: lt_temp_errors,
            lv_last_user,
            lv_last_date.

    READ TABLE lt_repo_meta
          WITH TABLE KEY progname = ls_item-include
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
    CLEAR lt_clean_usage_source.

    " Current include phải đứng đầu để row của current source map đúng
    APPEND LINES OF ls_item-source_code
      TO lt_clean_usage_source.

    APPEND LINES OF ls_item-source_code
      TO lt_clean_usage_source.

    lt_clean_usage_source = VALUE string_table(
      BASE lt_clean_usage_source
      FOR ls_usage_item IN lt_class_data
      WHERE ( include <> ls_item-include )
      FOR lv_usage_line IN ls_usage_item-source_code
      ( lv_usage_line )
    ).

    DATA(ls_ctx) = VALUE zcl_program_check=>gty_naming_ctx( obj_type = gc_objtype_clas
                                                            obj_name = iv_class_name
                                                            include  = ls_item-include ).

    IF iv_check_naming = abap_true.
      APPEND LINES OF go_check->analyze_naming( is_ctx    = ls_ctx
                                                it_source = ls_item-source_code
                                                it_class_sig_source = lt_class_sig_source ) TO lt_temp_errors. "NEW
    ENDIF.

    IF iv_check_perf = abap_true.
      APPEND LINES OF go_check->analyze_performance( is_ctx    = ls_ctx
                                                     it_source = ls_item-source_code ) TO lt_temp_errors.
    ENDIF.

    IF iv_check_clean = abap_true.
      APPEND LINES OF go_check->analyze_clean_code( is_ctx               = ls_ctx
                                                    it_source            = ls_item-source_code
                                                    it_usage_source      = lt_clean_usage_source
                                                    iv_check_unused_text = COND abap_bool( WHEN lv_text_symbol_checked = abap_false
                                                                                           THEN abap_true
                                                                                           ELSE abap_false ) ) TO lt_temp_errors.
      lv_text_symbol_checked = abap_true.
    ENDIF.

    IF iv_check_hardcode = abap_true.
      APPEND LINES OF go_check->analyze_hardcode( is_ctx    = ls_ctx
                                                  it_source = ls_item-source_code ) TO lt_temp_errors.
    ENDIF.

    IF iv_check_obsolete = abap_true.
      APPEND LINES OF go_check->analyze_obsolete( is_ctx    = ls_ctx
                                                  it_source = ls_item-source_code ) TO lt_temp_errors.
    ENDIF.

    LOOP AT lt_temp_errors ASSIGNING FIELD-SYMBOL(<lfs_err>).
      <lfs_err>-objtype  = gc_objtype_clas.
      <lfs_err>-objname  = iv_class_name.
      <lfs_err>-chk_usr  = lv_last_user.
      <lfs_err>-chk_date = lv_last_date.
      <lfs_err>-include  = ls_item-include.
    ENDLOOP.

    APPEND LINES OF lt_temp_errors TO rt_errors.
  ENDLOOP.

  SORT rt_errors
    BY objname include line rule msg.

  DELETE ADJACENT DUPLICATES FROM rt_errors
    COMPARING objname include line rule msg.
ENDMETHOD.
ENDCLASS.
