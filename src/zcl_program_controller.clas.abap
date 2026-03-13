class ZCL_PROGRAM_CONTROLLER definition
  public
  final
  create public .

public section.

  data RT_ERRORS type ZST_ERROR .

  methods RUN_CHECK_TR
    importing
      !IV_TRKORR type TRKORR
      !IV_CHECK_NAMING type FLAG optional
      !IV_CHECK_PERF type FLAG optional
      !IV_CHECK_USED type FLAG optional
      !IV_CHECK_CLEAN type FLAG optional
      !IV_CHECK_HARDCODE type FLAG optional
      !IV_CHECK_OBSOLETE type FLAG optional
    returning
      value(RT_ERRORS) type ZTT_ERROR .
  methods RUN_CHECK_FUGR
    importing
      !IV_FUGR type RS38L-AREA
      !IV_CHECK_NAMING type CHAR1
      !IV_CHECK_HARD type CHAR1
      !IV_CHECK_OBSOLETE type CHAR1
    returning
      value(RT_ERRORS) type ZTT_ERROR .
  methods RUN_PROCESS
    importing
      !IV_PROG_NAME type PROGNAME
      !IV_CHECK_NAMING type FLAG
      !IV_CHECK_PERF type FLAG
      !IV_CHECK_USED type FLAG
      !IV_TR type TRKORR
      !IV_TYPE type CHAR4 optional
    returning
      value(RT_ALL_ERRORS) type ZTT_ERROR .
  methods RUN_CHECK_FM
    importing
      !IV_FUNCNAME type RS38L-NAME
      !IV_CHECK_NAMING type ABAP_BOOL optional
      !IV_CHECK_PERF type ABAP_BOOL optional
      !IV_CHECK_USED type ABAP_BOOL optional
      !IV_CHECK_CLEAN type ABAP_BOOL optional
      !IV_CHECK_OBSOLETE type ABAP_BOOL optional
      !IV_CHECK_HARDCODE type ABAP_BOOL optional
    returning
      value(RT_ERRORS) type ZTT_ERROR .
  methods RUN_CHECK_PROGRAM
    importing
      !IV_PROG_NAME type PROGNAME
      !IV_CHECK_NAMING type ABAP_BOOL optional
      !IV_CHECK_PERF type ABAP_BOOL optional
      !IV_CHECK_CLEAN type ABAP_BOOL optional
      !IV_CHECK_HARDCODE type ABAP_BOOL optional
      !IV_CHECK_OBSOLETE type ABAP_BOOL optional
      !IV_CHECK_USED type ABAP_BOOL optional
    returning
      value(RT_ERRORS) type ZTT_ERROR .
  methods RUN_WHERE_USED
    importing
      !IV_TR type TRKORR optional
      !IV_FUGR type RS38L-AREA optional
      !IV_PROG type PROGNAME optional
      !IV_FUNC type RS38L-NAME optional
      !IV_CLAS type SEOCLSNAME optional
      !IT_COMMENT_SCOPE type ZCL_PROGRAM_WHEREUSED=>TY_R_DEVCLASS optional
      !IV_ADVANCED_WIDE type ABAP_BOOL default ABAP_FALSE
      !IV_RECURSIVE type ABAP_BOOL default ABAP_FALSE
      !IV_INCLUDE_COMMENTS type ABAP_BOOL default ABAP_FALSE
      !IV_MAX_HITS type I default 200
      !IV_OFFSET type I default 0
    exporting
      !EV_HAS_MORE type ABAP_BOOL
      !EV_NEXT_OFFSET type I
      !EV_INDEX_SUSPECT type ABAP_BOOL
    returning
      value(RT_FOUNDS) type ZCL_PROGRAM_WHEREUSED=>TY_FOUNDS .
  PROTECTED SECTION.
PRIVATE SECTION.

  TYPES: BEGIN OF ty_obj_key,
           find_obj_cls TYPE euobj-id,
           repo_object  TYPE tadir-object,
           obj_name     TYPE sobj_name,
         END OF ty_obj_key.
  TYPES: ty_t_obj_keys TYPE STANDARD TABLE OF ty_obj_key WITH EMPTY KEY .

  DATA mo_fetch     TYPE REF TO zcl_program_fetch .
  DATA mo_check     TYPE REF TO zcl_program_check .
  DATA mo_whereused TYPE REF TO zcl_program_whereused .
  DATA mt_visited   TYPE HASHED TABLE OF ty_obj_key WITH UNIQUE KEY find_obj_cls repo_object obj_name.

  METHODS ensure_objects .
ENDCLASS.



CLASS ZCL_PROGRAM_CONTROLLER IMPLEMENTATION.


  METHOD ensure_objects.
    IF mo_fetch IS INITIAL.
      CREATE OBJECT mo_fetch.
    ENDIF.
    IF mo_check IS INITIAL.
      CREATE OBJECT mo_check.
    ENDIF.
    IF mo_whereused IS INITIAL.
      CREATE OBJECT mo_whereused.
    ENDIF.
  ENDMETHOD.


  METHOD run_check_fm.
    ensure_objects( ).
    CLEAR rt_errors.

    DATA lv_pname   TYPE progname.
    DATA lv_include TYPE progname.

    "1) FETCH
    DATA(lt_source) = mo_fetch->get_function_module(
      EXPORTING
        iv_funcname = iv_funcname
      IMPORTING
        ev_main_prog = lv_pname
        ev_include   = lv_include ).

    IF lt_source IS INITIAL.
      APPEND VALUE zst_error(
        line = 0
        sev  = 'E'
        msg  = |Cannot read source for FM { iv_funcname }.|
        code = ''
      ) TO rt_errors.
      RETURN.
    ENDIF.

    "2) CHECK-NAMING
    IF iv_check_naming = 'X'.
      DATA(ls_ctx) = VALUE zcl_program_check=>ty_naming_ctx(
        obj_type  = 'FM'
        obj_name  = iv_funcname
        main_prog = lv_pname
        include   = lv_include ).

      DATA(lt_err_name) = mo_check->analyze_naming(
        is_ctx    = ls_ctx
        it_source = lt_source ).
      APPEND LINES OF lt_err_name TO rt_errors.
    ENDIF.


    "3) CHECK - CLEAN CODE
    IF iv_check_clean = abap_true.
      DATA(ls_cc_ctx) = VALUE zcl_program_check=>ty_naming_ctx(
                          obj_type  = 'FM'
                          obj_name  = iv_funcname
                          main_prog = lv_pname
                          include   = lv_include ).

      DATA(lt_err_cc) = mo_check->analyze_clean_code(
                          is_ctx    = ls_cc_ctx
                          it_source = lt_source ).
      APPEND LINES OF lt_err_cc TO rt_errors.
    ENDIF.
  ENDMETHOD.


METHOD run_check_fugr.
  DATA: lo_fetch TYPE REF TO zcl_program_fetch,
        lo_check TYPE REF TO zcl_program_check,
        lt_src   TYPE string_table,
        ls_ctx   TYPE zcl_program_check=>ty_naming_ctx.

  CREATE OBJECT: lo_fetch, lo_check.

  " 1. Lấy mã nguồn gộp từ các Include của Function Group
  lo_fetch->get_function_group(
    EXPORTING iv_fg_name = iv_fugr
    IMPORTING et_source  = lt_src ).

  IF lt_src IS NOT INITIAL.
    " Thiết lập ngữ cảnh để kiểm tra đặt tên
    ls_ctx-obj_type  = 'FUGR'.
    ls_ctx-obj_name  = iv_fugr.
    ls_ctx-include   = iv_fugr.

    " 2. Áp dụng Naming Check (nếu người dùng chọn)
    IF iv_check_naming = 'X'.
      APPEND LINES OF lo_check->analyze_naming(
        is_ctx    = ls_ctx
        it_source = lt_src
      ) TO rt_errors.
    ENDIF.

    " 3. Áp dụng Hardcode Check (nếu người dùng chọn)
    IF iv_check_hard = 'X'.
      APPEND LINES OF lo_check->analyze_hardcode(
        it_source = lt_src
      ) TO rt_errors.
    ENDIF.

    " 4. Áp dụng Obsolete Check (giữ nguyên không thay đổi logic bên trong)
   IF iv_check_obsolete = 'X'.
      APPEND LINES OF lo_check->analyze_obsolete(
        it_source = lt_src
      ) TO rt_errors.
    ENDIF.
 ENDIF.
ENDMETHOD.


  METHOD run_check_program.
    ensure_objects( ).
    CLEAR rt_errors.

    "1/FETCH
    DATA(lt_source) = mo_fetch->get_source_code( iv_prog_name = iv_prog_name ).

    IF lt_source IS INITIAL.
      APPEND VALUE zst_error(
        line = 0
        sev  = 'E'
        msg  = |Cannot read source for program { iv_prog_name }.|
        code = ''
      ) TO rt_errors.
      RETURN.
    ENDIF.

    "2/ Check Naming
    DATA(ls_ctx) = VALUE zcl_program_check=>ty_naming_ctx(
       obj_type  = 'PROG'
       obj_name  = iv_prog_name
       main_prog = iv_prog_name
       include   = iv_prog_name ).

    IF iv_check_naming = abap_true.
      APPEND LINES OF mo_check->analyze_naming(
        is_ctx    = ls_ctx
        it_source = lt_source )
      TO rt_errors.
    ENDIF.

    "3/ Check Clean Code
    IF iv_check_clean = abap_true.

      "Re-use same ctx của Program (main_prog/include = program)
      DATA(ls_cc_ctx) = VALUE zcl_program_check=>ty_naming_ctx(
                          obj_type  = 'PROG'
                          obj_name  = iv_prog_name
                          main_prog = iv_prog_name
                          include   = iv_prog_name ).

      DATA(lt_err_cc) = mo_check->analyze_clean_code(
                          is_ctx    = ls_cc_ctx
                          it_source = lt_source ).

      APPEND LINES OF lt_err_cc TO rt_errors.
    ENDIF.

    "4/ Check Hard Code
    IF iv_check_hardcode = abap_true.
      APPEND LINES OF mo_check->analyze_hardcode( it_source = lt_source )
        TO rt_errors.
    ENDIF.

    "5/ Check Obsolete
    IF iv_check_obsolete = abap_true.
      APPEND LINES OF mo_check->analyze_obsolete( it_source = lt_source )
        TO rt_errors.
    ENDIF.

*  IF iv_check_perf = abap_true.
*    APPEND LINES OF mo_check_perf->analyze_perf( it_source = lt_source )
*      TO rt_errors.
*  ENDIF.

  ENDMETHOD.


  METHOD run_check_tr.

  ensure_objects( ).
  CLEAR rt_errors.

  "---- Type tối giản, đúng 3 field mình SELECT ----
  TYPES: BEGIN OF ty_e071_min,
           pgmid    TYPE e071-pgmid,
           object   TYPE e071-object,
           obj_name TYPE e071-obj_name,
         END OF ty_e071_min.

  DATA: lt_e071  TYPE STANDARD TABLE OF ty_e071_min,
        ls_e071  TYPE ty_e071_min,
        lv_prog  TYPE progname,
        lv_fugr  TYPE rs38l-area,
        lv_func  TYPE rs38l-name,
        lt_new   TYPE ztt_error,
        ls_err   TYPE zst_error.

  "1) Lấy danh sách object trong TR
  SELECT pgmid object obj_name
    FROM e071
    INTO TABLE lt_e071
    WHERE trkorr = iv_trkorr.

  IF lt_e071 IS INITIAL.
    CLEAR ls_err.
    ls_err-line = 0.
    ls_err-sev  = 'E'.
    ls_err-msg  = 'TR is empty or not found'.
    CLEAR ls_err-code.
    APPEND ls_err TO rt_errors.
    RETURN.
  ENDIF.

  "2) Tránh trùng
  SORT lt_e071 BY object obj_name.
  DELETE ADJACENT DUPLICATES FROM lt_e071 COMPARING object obj_name.

  "3) Dispatch
  LOOP AT lt_e071 INTO ls_e071.

    CASE ls_e071-object.

      WHEN 'PROG'.
        CLEAR lv_prog.
        lv_prog = ls_e071-obj_name.

        CLEAR lt_new.
        lt_new = me->run_check_program(
                   iv_prog_name       = lv_prog
                   iv_check_naming    = iv_check_naming
                   iv_check_perf      = iv_check_perf
                   iv_check_clean     = space
                   iv_check_hardcode  = space
                   iv_check_obsolete  = space
                 ).
        APPEND LINES OF lt_new TO rt_errors.

      WHEN 'FUGR'.
        CLEAR lv_fugr.
        lv_fugr = ls_e071-obj_name.

        CLEAR lt_new.
        lt_new = me->run_check_fugr(
                   iv_fugr         = lv_fugr
                   iv_check_naming = iv_check_naming
                   iv_check_hard   = space
                   iv_check_obsolete = space
                 ).
        APPEND LINES OF lt_new TO rt_errors.

      WHEN 'FUNC'.
        CLEAR lv_func.
        lv_func = ls_e071-obj_name.

        CLEAR lt_new.
        lt_new = me->run_check_fm(
                   iv_funcname     = lv_func
                   iv_check_naming = iv_check_naming
                   iv_check_perf   = iv_check_perf
                   iv_check_used   = iv_check_used
                 ).
        APPEND LINES OF lt_new TO rt_errors.

      WHEN OTHERS.
        CONTINUE.

    ENDCASE.

  ENDLOOP.

ENDMETHOD.


  METHOD run_process.
    " Data Declarations
    DATA: lo_fetch       TYPE REF TO zcl_program_fetch,
          lo_check       TYPE REF TO zcl_program_check,
          lt_source_code TYPE string_table,
          lt_new_errors  TYPE ztt_error.

    " -------------------------------------------------------
    " 1. INSTANTIATE: Create the objects
    " -------------------------------------------------------
    CREATE OBJECT lo_fetch.
    CREATE OBJECT lo_check.

    " -------------------------------------------------------
    " 2. FETCH: Get the code from the system
    " -------------------------------------------------------
    " We ask the Fetch class to grab the code for the program name provided
    lt_source_code = lo_fetch->get_source_code( iv_prog_name = iv_prog_name ).

    " Check if source code was actually found
    IF lt_source_code IS INITIAL.
      " Optional: Return an error if program doesn't exist
      DATA(ls_error) = VALUE zst_error( msg = 'Program not found or empty' sev = 'E' ).
      INSERT ls_error INTO TABLE rt_all_errors.
      RETURN.
    ENDIF.

    " -------------------------------------------------------
    " 3. CHECK: Analyze the Naming Conventions
    " -------------------------------------------------------
    " Pass the code (lt_source_code) AND the name (iv_program_name) to the check class
    DATA(ls_ctx) = VALUE zcl_program_check=>ty_naming_ctx(
       obj_type  = 'PROG'
       obj_name  = iv_prog_name
       main_prog = iv_prog_name
       include   = iv_prog_name ).

    lt_new_errors = lo_check->analyze_naming(
                      is_ctx    = ls_ctx
                      it_source = lt_source_code ).

    " Add any errors found to our final result table
    APPEND LINES OF lt_new_errors TO rt_all_errors.
    " -------------------------------------------------------
    " 4. CHECK: Function Group
    " -------------------------------------------------------


  ENDMETHOD.


METHOD run_where_used.
  ensure_objects( ).
  CLEAR: ev_has_more, ev_next_offset, ev_index_suspect.
  CLEAR mt_visited.

  DATA lt_keys TYPE ty_t_obj_keys.
  DATA lt_all  TYPE zcl_program_whereused=>ty_founds.
  DATA ls_key  TYPE ty_obj_key.
  DATA lv_subc TYPE trdir-subc.
  DATA lv_subrc TYPE sy-subrc.
  DATA lv_sus   TYPE abap_bool.
  DATA lv_total TYPE i.
  DATA lv_off   TYPE i.
  DATA lv_end   TYPE i.

  "------------------------------------------------------------
  " Inline helper: GET_OBJECTS_FROM_TR (same code, just inlined)
  "------------------------------------------------------------
  TYPES: BEGIN OF ty_e071,
           pgmid    TYPE e071-pgmid,
           object   TYPE e071-object,
           obj_name TYPE e071-obj_name,
         END OF ty_e071.

  DATA lt_e071 TYPE STANDARD TABLE OF ty_e071 WITH EMPTY KEY.
  DATA ls_e071 TYPE ty_e071.
  DATA lv_subc_tr TYPE trdir-subc.

  "1) Build start object(s)
  IF iv_tr IS NOT INITIAL.

    CLEAR lt_keys.

    IF iv_tr IS NOT INITIAL.
      SELECT pgmid object obj_name
        FROM e071
        INTO TABLE lt_e071
        WHERE trkorr = iv_tr.

      LOOP AT lt_e071 INTO ls_e071.

        IF ls_e071-pgmid <> 'R3TR'.
          CONTINUE.
        ENDIF.

        CASE ls_e071-object.

          WHEN 'CLAS'.
            APPEND VALUE ty_obj_key(
              find_obj_cls = 'CLAS'
              repo_object  = 'CLAS'
              obj_name     = ls_e071-obj_name ) TO lt_keys.

          WHEN 'PROG'.
            CLEAR lv_subc_tr.
            SELECT SINGLE subc
              FROM trdir
              INTO lv_subc_tr
              WHERE name = ls_e071-obj_name.

            IF sy-subrc = 0 AND lv_subc_tr = 'I'.
              APPEND VALUE ty_obj_key(
                find_obj_cls = 'INCL'
                repo_object  = 'PROG'
                obj_name     = ls_e071-obj_name ) TO lt_keys.
            ELSE.
              APPEND VALUE ty_obj_key(
                find_obj_cls = 'PROG'
                repo_object  = 'PROG'
                obj_name     = ls_e071-obj_name ) TO lt_keys.
            ENDIF.

          WHEN 'FUNC'.
            APPEND VALUE ty_obj_key(
              find_obj_cls = 'FUNC'
              repo_object  = 'FUNC'
              obj_name     = ls_e071-obj_name ) TO lt_keys.

          WHEN 'FUGR'.
            APPEND VALUE ty_obj_key(
              find_obj_cls = 'FUNC'
              repo_object  = 'FUGR'
              obj_name     = ls_e071-obj_name ) TO lt_keys.

          WHEN OTHERS.
            CONTINUE.

        ENDCASE.

      ENDLOOP.
    ENDIF.

  ELSEIF iv_fugr IS NOT INITIAL.

    "------------------------------------------------------------
    " Inline helper: GET_OBJECTS_FROM_FUGR (same code, inlined)
    "------------------------------------------------------------
    CLEAR lt_keys.
    IF iv_fugr IS INITIAL.
      RETURN.
    ENDIF.

    APPEND VALUE ty_obj_key(
      find_obj_cls = 'FUNC'
      repo_object  = 'FUGR'
      obj_name     = iv_fugr ) TO lt_keys.

  ELSEIF iv_clas IS NOT INITIAL.

    APPEND VALUE ty_obj_key(
      find_obj_cls = 'CLAS'
      repo_object  = 'CLAS'
      obj_name     = iv_clas ) TO lt_keys.

  ELSEIF iv_prog IS NOT INITIAL.

    CLEAR lv_subc.
    SELECT SINGLE subc
      FROM trdir
      INTO lv_subc
      WHERE name = iv_prog.

    IF sy-subrc = 0 AND lv_subc = 'I'.
      APPEND VALUE ty_obj_key(
        find_obj_cls = 'INCL'
        repo_object  = 'PROG'
        obj_name     = iv_prog ) TO lt_keys.
    ELSE.
      APPEND VALUE ty_obj_key(
        find_obj_cls = 'PROG'
        repo_object  = 'PROG'
        obj_name     = iv_prog ) TO lt_keys.
    ENDIF.

  ELSEIF iv_func IS NOT INITIAL.

    APPEND VALUE ty_obj_key(
      find_obj_cls = 'FUNC'
      repo_object  = 'FUNC'
      obj_name     = iv_func ) TO lt_keys.

  ELSE.
    RETURN.
  ENDIF.

  "2) Collect where-used for each key
  LOOP AT lt_keys INTO ls_key.

    "------------------------------------------------------------
    " Inline helper: ADD_TO_VISITED (same code, inlined)
    "------------------------------------------------------------
    READ TABLE mt_visited
      WITH TABLE KEY
        find_obj_cls = ls_key-find_obj_cls
        repo_object  = ls_key-repo_object
        obj_name     = ls_key-obj_name
      TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    INSERT ls_key INTO TABLE mt_visited.

    CLEAR: lv_subrc, lv_sus.

    DATA(lt_found_key) = mo_whereused->get_where_used(
      EXPORTING
        iv_find_obj_cls       = ls_key-find_obj_cls
        iv_object             = CONV rsobject( ls_key-obj_name )
        iv_tadir_object       = ls_key-repo_object
        it_comment_scope      = it_comment_scope
        iv_recursive          = iv_recursive
        iv_advanced_wide      = iv_advanced_wide
        iv_include_comments   = iv_include_comments
      IMPORTING
        ev_last_subrc         = lv_subrc
        ev_index_suspect      = lv_sus ).

    IF lv_sus = abap_true.
      ev_index_suspect = abap_true.
    ENDIF.

    APPEND LINES OF lt_found_key TO lt_all.
  ENDLOOP.

  "3) Global dedupe
  SORT lt_all BY used_cls used_obj program object_row.
  DELETE ADJACENT DUPLICATES FROM lt_all COMPARING used_cls used_obj program object_row.

  "4) Paging
  DESCRIBE TABLE lt_all LINES lv_total.

  lv_off = iv_offset.
  IF lv_off < 0.
    lv_off = 0.
  ENDIF.
  IF lv_off > lv_total.
    lv_off = lv_total.
  ENDIF.

  lv_end = lv_off + iv_max_hits.
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
ENDCLASS.
