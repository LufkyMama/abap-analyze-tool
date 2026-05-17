CLASS zcl_program_whereused DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:

      gty_t_founds TYPE STANDARD TABLE OF rsfindlst WITH EMPTY KEY .
    TYPES:

      gty_r_devclass TYPE RANGE OF devclass .

    METHODS get_where_used
      IMPORTING
        !iv_find_obj_cls     TYPE euobj-id
        !iv_object           TYPE rsobject
        !iv_tadir_object     TYPE tadir-object OPTIONAL
        !iv_default_devclass TYPE devclass OPTIONAL
        !is_comment_scope    TYPE gty_r_devclass OPTIONAL
        !iv_recursive        TYPE abap_bool DEFAULT abap_false
        !iv_advanced_wide    TYPE abap_bool DEFAULT abap_false
        !iv_include_comments TYPE abap_bool DEFAULT abap_false
      EXPORTING
        !ev_last_subrc       TYPE sy-subrc
        !ev_index_suspect    TYPE abap_bool
      RETURNING
        VALUE(rt_founds)     TYPE gty_t_founds .
protected section.
PRIVATE SECTION.

  TYPES:
    gty_t_euobj_id TYPE STANDARD TABLE OF euobj-id WITH EMPTY KEY,
    gty_t_repids   TYPE SORTED TABLE OF syrepid WITH UNIQUE KEY table_line.

  "======================================================================

  CONSTANTS gc_zero             TYPE i VALUE 0.
  CONSTANTS gc_len_one          TYPE i VALUE 1.
  CONSTANTS gc_max_dist         TYPE i VALUE 999999.
  CONSTANTS gc_max_repids       TYPE i VALUE 5000.
  CONSTANTS gc_len_sapl         TYPE i VALUE 5.
  CONSTANTS gc_len_sapl_prefix  TYPE i VALUE 4.
  CONSTANTS gc_len_class_name   TYPE i VALUE 30.
  CONSTANTS gc_len_class_prog   TYPE i VALUE 32.

  " Added to resolve 'Unknown field' errors in implementation
  CONSTANTS gc_quote TYPE c LENGTH 1 VALUE ''''.

  CONSTANTS gc_arrow            TYPE string VALUE '=>'.
  CONSTANTS gc_colon            TYPE string VALUE ':'.
  CONSTANTS gc_backslash        TYPE string VALUE '\'.
  CONSTANTS gc_stmt_include     TYPE string VALUE 'INCLUDE'.
  CONSTANTS gc_stmt_call_func    TYPE string VALUE 'CALL FUNCTION'.
  CONSTANTS gc_stmt_submit       TYPE string VALUE 'SUBMIT'.
  CONSTANTS gc_stmt_new          TYPE string VALUE 'NEW'.
  CONSTANTS gc_stmt_type_ref     TYPE string VALUE 'TYPE REF TO'.
  CONSTANTS gc_stmt_ref_to       TYPE string VALUE 'REF TO'.
  CONSTANTS gc_stmt_type         TYPE string VALUE 'TYPE'.

  CONSTANTS gc_obj_clas         TYPE tadir-object VALUE 'CLAS' ##NO_TEXT.
  CONSTANTS gc_obj_prog         TYPE tadir-object VALUE 'PROG' ##NO_TEXT.
  CONSTANTS gc_obj_func         TYPE tadir-object VALUE 'FUNC' ##NO_TEXT.
  CONSTANTS gc_obj_fugr         TYPE tadir-object VALUE 'FUGR' ##NO_TEXT.

  CONSTANTS gc_obj_incl         TYPE c LENGTH 4 VALUE 'INCL' ##NO_TEXT.
  CONSTANTS gc_used_comm        TYPE c LENGTH 4 VALUE 'COMM' ##NO_TEXT.
  CONSTANTS gc_pgmid_r3tr       TYPE c LENGTH 4 VALUE 'R3TR' ##NO_TEXT.
  CONSTANTS gc_dev_tmp          TYPE devclass   VALUE '$TMP' ##NO_TEXT.
  CONSTANTS gc_prefix_sapl      TYPE c LENGTH 4 VALUE 'SAPL' ##NO_TEXT.
  CONSTANTS gc_suffix_cp        TYPE c LENGTH 2 VALUE 'CP'   ##NO_TEXT.
  CONSTANTS gc_range_sign_inc   TYPE c LENGTH 1 VALUE 'I'    ##NO_TEXT.
  CONSTANTS gc_range_opt_eq     TYPE c LENGTH 2 VALUE 'EQ'   ##NO_TEXT.
  CONSTANTS gc_flag_x           TYPE c LENGTH 1 VALUE 'X'    ##NO_TEXT.
  CONSTANTS gc_trdir_subc_i     TYPE c LENGTH 1 VALUE 'I'    ##NO_TEXT.
  CONSTANTS gc_char_eq          TYPE c LENGTH 1 VALUE '='    ##NO_TEXT.
  CONSTANTS gc_state_inactive    TYPE c LENGTH 1 VALUE 'I'    ##NO_TEXT.
  CONSTANTS gc_comment_star     TYPE c LENGTH 1 VALUE '*'    ##NO_TEXT.
  CONSTANTS gc_comment_quote    TYPE c LENGTH 1 VALUE '"'    ##NO_TEXT.

  CONSTANTS gc_placeholder_obj     TYPE string VALUE '{OBJ}' ##NO_TEXT.
  CONSTANTS gc_regex_incl_comment  TYPE string VALUE '^INCLUDE[[:space:]]*:?[[:space:]]*(''{OBJ}''|{OBJ})([^A-Z0-9_/]|$)' ##NO_TEXT.
  CONSTANTS gc_regex_func_comment  TYPE string VALUE 'CALL[[:space:]]+FUNCTION[[:space:]]+(''{OBJ}''|{OBJ})([^A-Z0-9_/]|$)' ##NO_TEXT.
  CONSTANTS gc_regex_prog_comment  TYPE string VALUE 'SUBMIT[[:space:]]+(''{OBJ}''|{OBJ})([^A-Z0-9_/]|$)' ##NO_TEXT.
  CONSTANTS gc_regex_clas_new      TYPE string VALUE 'NEW[[:space:]]+{OBJ}([^A-Z0-9_/]|$)' ##NO_TEXT.
  CONSTANTS gc_regex_clas_type_ref TYPE string VALUE 'TYPE[[:space:]]+REF[[:space:]]+TO[[:space:]]+{OBJ}([^A-Z0-9_/]|$)' ##NO_TEXT.
  CONSTANTS gc_regex_clas_ref_to   TYPE string VALUE 'REF[[:space:]]+TO[[:space:]]+{OBJ}([^A-Z0-9_/]|$)' ##NO_TEXT.
  CONSTANTS gc_regex_clas_create   TYPE string VALUE 'CREATE[[:space:]]+OBJECT.*TYPE[[:space:]]+{OBJ}([^A-Z0-9_/]|$)' ##NO_TEXT.
  CONSTANTS gc_regex_clas_static   TYPE string VALUE '{OBJ}[[:space:]]*=>' ##NO_TEXT.
  CONSTANTS gc_regex_default_obj   TYPE string VALUE '(^|[^A-Z0-9_/]){OBJ}([^A-Z0-9_/]|$)' ##NO_TEXT.
  CONSTANTS gc_regex_fg_inc        TYPE string VALUE '^L(.+)(TOP|U[0-9A-Z]{2}|F[0-9A-Z]{2}|I[0-9A-Z]{2}|O[0-9A-Z]{2})$' ##NO_TEXT.

  "======================================================================

  METHODS scan_comment_out
    IMPORTING
      !it_repids       TYPE gty_t_repids
      !iv_find_obj_cls TYPE euobj-id
      !iv_object       TYPE rsobject
      !iv_comment_only TYPE abap_bool DEFAULT abap_true
      !iv_used_cls_out TYPE euobj-id OPTIONAL
    RETURNING
      VALUE(rt_founds) TYPE gty_t_founds.
ENDCLASS.



CLASS ZCL_PROGRAM_WHEREUSED IMPLEMENTATION.


METHOD get_where_used.

    "======================================================================
    " A) Local TYPES
    "======================================================================
    TYPES: BEGIN OF lty_tadir_cache,
             object   TYPE tadir-object,
             obj_name TYPE tadir-obj_name,
             devclass TYPE devclass,
           END OF lty_tadir_cache.

    TYPES:
      lty_t_tadir_cache TYPE HASHED TABLE OF lty_tadir_cache WITH UNIQUE KEY object obj_name,
      lty_t_root_repids TYPE SORTED TABLE OF syrepid WITH UNIQUE KEY table_line,
      lty_t_tadir_name  TYPE STANDARD TABLE OF tadir-obj_name WITH EMPTY KEY.

    "======================================================================
    " B) Local DATA - scope for crossref
    "======================================================================


    DATA lv_tadir_object TYPE tadir-object.
    DATA lt_cls          TYPE gty_t_euobj_id.

    DATA lt_founds       TYPE gty_t_founds.
    DATA lt_findstrings  TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lt_comm         TYPE gty_t_founds.

    DATA lv_object_full TYPE string.
    DATA lv_object_root TYPE tadir-obj_name.
    DATA lv_subobject   TYPE string.

    DATA ls_scope         TYPE gty_r_devclass.
    DATA lv_devclass      TYPE devclass.
    DATA lv_tadir_object2 TYPE tadir-object.
    DATA lv_fugr          TYPE rs38l-area.

    DATA ls_scope_comm   TYPE gty_r_devclass.
    DATA lt_seed_repids  TYPE gty_t_repids.
    DATA lv_devclass_hit TYPE devclass.
    DATA lv_is_tmp_hit   TYPE abap_bool.

    DATA lv_fugr_main   TYPE rs38l-area.
    DATA lv_class_30    TYPE seoclsname.
    DATA lv_class_name  TYPE seoclsname.
    DATA lv_rep_u       TYPE string.
    DATA lv_fg_name     TYPE string.
    DATA lv_fg_suffix   TYPE string.
    DATA lv_class_prog2 TYPE syrepid.

    DATA lt_repids       TYPE gty_t_repids.
    DATA lt_expand_from2 TYPE lty_t_root_repids.
    DATA lt_prog_roots2  TYPE lty_t_tadir_name.
    DATA lt_classes2     TYPE lty_t_tadir_name.
    DATA lt_fugrs2       TYPE lty_t_tadir_name.
    DATA lt_includes2    TYPE STANDARD TABLE OF syrepid WITH EMPTY KEY.

    DATA lv_class_prog3  TYPE syrepid.
    DATA lv_fugr_prog2   TYPE syrepid.

    DATA lt_tadir_cache TYPE lty_t_tadir_cache.
    DATA lt_tadir_buf   TYPE STANDARD TABLE OF lty_tadir_cache WITH EMPTY KEY.
    DATA ls_tadir_cache TYPE lty_tadir_cache.

    DATA lt_prog_names  TYPE lty_t_tadir_name.
    DATA lt_fugr_names  TYPE lty_t_tadir_name.
    DATA lt_class_names TYPE lty_t_tadir_name.

    DATA lt_all_includes TYPE STANDARD TABLE OF syrepid WITH EMPTY KEY.
    DATA lt_all_repids   TYPE STANDARD TABLE OF syrepid WITH EMPTY KEY.
    DATA lv_delete_from  TYPE i.

    " Enrich line data
    DATA lt_src_enrich TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    FIELD-SYMBOLS <lfs_fx> LIKE LINE OF lt_founds.

    ev_last_subrc    = gc_zero.
    ev_index_suspect = abap_false.

    CLEAR: lv_object_full, lv_object_root, lv_subobject.
    lv_object_full = iv_object.
    lv_object_root = iv_object.

    IF iv_find_obj_cls = gc_obj_clas AND lv_object_full CS gc_arrow.
      SPLIT lv_object_full AT gc_arrow INTO lv_object_root lv_subobject.
    ENDIF.

    "Resolve TADIR object once
    lv_tadir_object = iv_tadir_object.
    IF lv_tadir_object IS INITIAL.
      CASE iv_find_obj_cls.
        WHEN gc_obj_clas.
          lv_tadir_object = gc_obj_clas.
        WHEN gc_obj_prog OR gc_obj_incl.
          lv_tadir_object = gc_obj_prog.
        WHEN gc_obj_func.
          lv_tadir_object = gc_obj_func.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    ENDIF.

    "----------------------------------------------------------------------
    " C) candidates OBJ_CLS
    "----------------------------------------------------------------------
    lt_cls = VALUE #( ( iv_find_obj_cls ) ).

    IF iv_find_obj_cls = gc_obj_prog.
      APPEND gc_obj_incl TO lt_cls.
    ENDIF.

    SORT lt_cls BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_cls COMPARING table_line.

    "----------------------------------------------------------------------
    " D) scope (devclass range) for XREF only
    "----------------------------------------------------------------------
    CLEAR ls_scope.

    IF iv_advanced_wide = abap_true.
      " leave ls_scope initial
    ELSE.

      CLEAR lv_devclass.

      lv_tadir_object2 = lv_tadir_object.

      IF lv_tadir_object2 = gc_obj_incl.
        lv_tadir_object2 = gc_obj_prog.
      ENDIF.

      IF lv_tadir_object2 = gc_obj_func.
        CLEAR lv_fugr.
        SELECT SINGLE area
          FROM enlfdir
          INTO @lv_fugr
          WHERE funcname = @iv_object.

        IF sy-subrc = 0 AND lv_fugr IS NOT INITIAL.
          lv_tadir_object2 = gc_obj_fugr.

          SELECT SINGLE devclass
            FROM tadir
            INTO @lv_devclass
            WHERE pgmid    = @gc_pgmid_r3tr
              AND object   = @lv_tadir_object2
              AND obj_name = @lv_fugr.

          IF sy-subrc <> 0.
            CLEAR lv_devclass.
          ENDIF.
        ELSE.
          CLEAR lv_devclass.
        ENDIF.
      ELSE.
        IF lv_tadir_object2 = gc_obj_clas.
          SELECT SINGLE devclass
            FROM tadir
            INTO @lv_devclass
            WHERE pgmid    = @gc_pgmid_r3tr
              AND object   = @lv_tadir_object2
              AND obj_name = @lv_object_root.
        ELSE.
          SELECT SINGLE devclass
            FROM tadir
            INTO @lv_devclass
            WHERE pgmid    = @gc_pgmid_r3tr
              AND object   = @lv_tadir_object2
              AND obj_name = @iv_object.
        ENDIF.

        IF sy-subrc <> 0.
          CLEAR lv_devclass.
        ENDIF.
      ENDIF.

      IF lv_devclass IS INITIAL.
        lv_devclass = iv_default_devclass.
      ENDIF.

      IF lv_devclass IS NOT INITIAL.
        APPEND VALUE #( sign = gc_range_sign_inc option = gc_range_opt_eq low = lv_devclass ) TO ls_scope.
      ENDIF.

    ENDIF.

    "----------------------------------------------------------------------
    " E) crossref (semantic where-used, based on index)
    "----------------------------------------------------------------------
    CLEAR: lt_founds, lt_findstrings.
    APPEND lv_object_full TO lt_findstrings.

    LOOP AT lt_cls INTO DATA(lv_cls).
      CLEAR lt_founds.

      CALL FUNCTION 'RS_EU_CROSSREF'
        EXPORTING
          i_find_obj_cls           = lv_cls
          no_dialog                = abap_true
          rekursiv                 = xsdbool( iv_recursive = abap_true )
        TABLES
          i_findstrings            = lt_findstrings
          i_scope_devclass         = ls_scope
          o_founds                 = lt_founds
        EXCEPTIONS
          not_executed             = 1
          not_found                = 2
          illegal_object           = 3
          no_cross_for_this_object = 4
          batch                    = 5
          batchjob_error           = 6
          wrong_type               = 7
          object_not_exist         = 8
          OTHERS                   = 9.

      ev_last_subrc = sy-subrc.

      CASE ev_last_subrc.
        WHEN 0.
        WHEN 2.
        WHEN 4.
          MESSAGE w026(z_gsp04_message) WITH ev_last_subrc.
        WHEN 7 OR 8.
          CLEAR rt_founds.
          RETURN.
        WHEN OTHERS.
          CLEAR rt_founds.
          RETURN.
      ENDCASE.

      IF lt_founds IS NOT INITIAL.
        EXIT.
      ENDIF.
    ENDLOOP.

    "----------------------------------------------------------------------
    " E2) Enrich OBJECT_ROW from real source
    "----------------------------------------------------------------------
    LOOP AT lt_founds ASSIGNING <lfs_fx>
         WHERE program IS NOT INITIAL
           AND used_cls <> gc_used_comm.

      CLEAR lt_src_enrich.

      " keep USED_OBJ untouched
      DATA(lv_old_row) = <lfs_fx>-object_row.
      DATA(lv_obj_u)   = to_upper( CONV string( iv_object ) ).
      DATA(lv_used_u)  = to_upper( CONV string( <lfs_fx>-used_obj ) ).

      " normalize technical prefix from USED_OBJ
      IF lv_used_u CS gc_colon AND substring( val = lv_used_u len = gc_len_one ) = gc_backslash.
        lv_used_u = substring_after( val = lv_used_u sub = gc_colon ).
        lv_used_u = to_upper( lv_used_u ).
      ENDIF.

      " prefer object name from input; fallback to used_obj
      DATA(lv_find_u) = lv_obj_u.
      IF lv_find_u IS INITIAL.
        lv_find_u = lv_used_u.
      ENDIF.

      IF lv_find_u IS INITIAL.
        CONTINUE.
      ENDIF.

      READ REPORT <lfs_fx>-program STATE gc_state_inactive INTO lt_src_enrich.
      IF sy-subrc <> 0 OR lt_src_enrich IS INITIAL.
        READ REPORT <lfs_fx>-program INTO lt_src_enrich.
      ENDIF.

      IF sy-subrc <> 0 OR lt_src_enrich IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_row_new)   = gc_zero.
      DATA(lv_best_dist) = gc_max_dist.
      DATA lv_dist TYPE i.

      DATA(lv_pat_incl)   = |{ gc_stmt_include } { lv_find_u }|.
      DATA(lv_pat_func)   = |{ gc_stmt_call_func } { gc_quote }{ lv_find_u }{ gc_quote }|.
      DATA(lv_pat_prog)   = |{ gc_stmt_submit } { lv_find_u }|.
      DATA(lv_pat_static) = |{ lv_find_u }{ gc_arrow }|.

      DATA(lv_where_used_u) = lv_used_u.
      IF lv_where_used_u IS INITIAL.
        lv_where_used_u = lv_find_u.
      ENDIF.

      DATA(lv_lines_count) = lines( lt_src_enrich ).
      DO lv_lines_count TIMES.
        DATA(lv_stmt_row) = sy-index.
        READ TABLE lt_src_enrich INTO DATA(lv_src_line) INDEX lv_stmt_row.

        IF NOT ( lv_src_line CS lv_find_u OR lv_src_line CS lv_where_used_u ).
          CONTINUE.
        ENDIF.

        IF lv_src_line IS INITIAL.
          CONTINUE.
        ENDIF.

        DATA(lv_trim) = lv_src_line.
        SHIFT lv_trim LEFT DELETING LEADING space.
        IF lv_trim IS INITIAL.
          CONTINUE.
        ENDIF.

        " ignore full-line comments for semantic enrichment
        IF substring( val = lv_trim len = gc_len_one ) = gc_comment_star OR substring( val = lv_trim len = gc_len_one ) = gc_comment_quote.
          CONTINUE.
        ENDIF.

        DATA(lv_src_u) = to_upper( lv_src_line ).

        DATA(lv_match_this_line) = abap_false.

        CASE iv_find_obj_cls.

          WHEN gc_obj_incl.
            IF lv_src_u CS lv_pat_incl.
              lv_match_this_line = abap_true.
            ENDIF.

          WHEN gc_obj_prog.
            IF lv_src_u CS lv_pat_prog OR lv_src_u CS lv_pat_incl.
              lv_match_this_line = abap_true.
            ENDIF.

          WHEN gc_obj_func.
            IF lv_src_u CS lv_pat_func.
              lv_match_this_line = abap_true.
            ENDIF.

          WHEN gc_obj_clas.
            IF lv_src_u CS |{ gc_stmt_new } { lv_find_u }|
                OR lv_src_u CS |{ gc_stmt_type_ref } { lv_find_u }|
                OR lv_src_u CS |{ gc_stmt_ref_to } { lv_find_u }|
                OR lv_src_u CS |{ gc_stmt_type } { lv_find_u }|
                OR lv_src_u CS lv_pat_static.
              lv_match_this_line = abap_true.
            ENDIF.

            IF lv_match_this_line = abap_false
                AND lv_subobject IS NOT INITIAL
                AND lv_src_u CS |{ lv_object_root }{ gc_arrow }{ lv_subobject }|.
              lv_match_this_line = abap_true.
            ENDIF.

          WHEN OTHERS.
            IF lv_src_u CS lv_find_u.
              lv_match_this_line = abap_true.
            ENDIF.

        ENDCASE.

        " fallback by USED_OBJ if IM_OBJECT does not match
        IF lv_match_this_line = abap_false
           AND lv_used_u IS NOT INITIAL
           AND lv_used_u <> lv_find_u.

          IF iv_find_obj_cls = gc_obj_incl AND lv_src_u CS |{ gc_stmt_include } { lv_used_u }|.
            lv_match_this_line = abap_true.
          ELSEIF iv_find_obj_cls = gc_obj_prog
             AND ( lv_src_u CS |{ gc_stmt_submit } { lv_used_u }| OR lv_src_u CS |{ gc_stmt_include } { lv_used_u }| ).
            lv_match_this_line = abap_true.
          ELSEIF iv_find_obj_cls = gc_obj_func AND lv_src_u CS |{ gc_stmt_call_func } { gc_quote }{ lv_used_u }{ gc_quote }|.
            lv_match_this_line = abap_true.
          ELSEIF iv_find_obj_cls = gc_obj_clas
             AND ( lv_src_u CS |{ gc_stmt_new } { lv_used_u }|
                OR lv_src_u CS |{ gc_stmt_type_ref } { lv_used_u }|
                OR lv_src_u CS |{ gc_stmt_ref_to } { lv_used_u }|
                OR lv_src_u CS |{ gc_stmt_type } { lv_used_u }|
                OR lv_src_u CS |{ lv_used_u }{ gc_arrow }| ).
            lv_match_this_line = abap_true.
          ELSEIF iv_find_obj_cls <> gc_obj_clas
             AND iv_find_obj_cls <> gc_obj_func
             AND iv_find_obj_cls <> gc_obj_prog
             AND iv_find_obj_cls <> gc_obj_incl
             AND lv_src_u CS lv_used_u.
            lv_match_this_line = abap_true.
          ENDIF.
        ENDIF.

        IF lv_match_this_line = abap_false.
          CONTINUE.
        ENDIF.

        IF lv_old_row > gc_zero.
          lv_dist = abs( lv_stmt_row - lv_old_row ).
          IF lv_dist < lv_best_dist.
            lv_best_dist = lv_dist.
            lv_row_new   = lv_stmt_row.
          ENDIF.
        ELSEIF lv_row_new IS INITIAL.
          lv_row_new = lv_stmt_row.
        ENDIF.

      ENDDO.

      IF lv_row_new IS INITIAL
         AND lv_old_row > gc_zero
         AND lv_old_row <= lines( lt_src_enrich ).
        lv_row_new = lv_old_row.
      ENDIF.

      IF lv_row_new > gc_zero.
        <lfs_fx>-object_row = lv_row_new.
        <lfs_fx>-object     = lv_row_new.
      ENDIF.

    ENDLOOP.

    "----------------------------------------------------------------------
    " F) Optional: supports multiple devclass via it_comment_scope
    "----------------------------------------------------------------------
    IF iv_include_comments = abap_true.

      ls_scope_comm = is_comment_scope.

      CLEAR: lt_tadir_cache, lt_prog_names, lt_fugr_names, lt_class_names.

      LOOP AT lt_founds INTO DATA(ls_fx) WHERE program IS NOT INITIAL AND used_cls <> gc_used_comm.

        APPEND ls_fx-program TO lt_prog_names.

        IF strlen( ls_fx-program ) >= gc_len_sapl AND substring( val = ls_fx-program len = gc_len_sapl_prefix ) = gc_prefix_sapl.
          APPEND CONV tadir-obj_name( substring( val = ls_fx-program off = gc_len_sapl_prefix ) ) TO lt_fugr_names.
        ENDIF.

        IF strlen( ls_fx-program ) >= gc_len_class_prog.
          CLEAR lv_class_30.
          lv_class_30 = substring( val = ls_fx-program len = gc_len_class_name ).

          CLEAR lv_class_name.
          lv_class_name = lv_class_30.
          SHIFT lv_class_name RIGHT DELETING TRAILING gc_char_eq.

          IF lv_class_name IS NOT INITIAL.
            APPEND CONV tadir-obj_name( lv_class_name ) TO lt_class_names.
          ENDIF.
        ENDIF.

        lv_rep_u = ls_fx-program.
        lv_rep_u = to_upper( lv_rep_u ).

        CLEAR: lv_fg_name, lv_fg_suffix.
        FIND FIRST OCCURRENCE OF PCRE gc_regex_fg_inc
             IN lv_rep_u
             SUBMATCHES lv_fg_name lv_fg_suffix.

        IF sy-subrc = 0 AND lv_fg_name IS NOT INITIAL.
          APPEND CONV tadir-obj_name( lv_fg_name ) TO lt_fugr_names.
        ENDIF.

      ENDLOOP.

      SORT lt_prog_names BY table_line.
      DELETE ADJACENT DUPLICATES FROM lt_prog_names COMPARING table_line.

      SORT lt_fugr_names BY table_line.
      DELETE ADJACENT DUPLICATES FROM lt_fugr_names COMPARING table_line.

      SORT lt_class_names BY table_line.
      DELETE ADJACENT DUPLICATES FROM lt_class_names COMPARING table_line.

      IF lt_prog_names IS NOT INITIAL.
        CLEAR lt_tadir_buf.
        SELECT object, obj_name, devclass
          FROM tadir
          INTO TABLE @lt_tadir_buf
          FOR ALL ENTRIES IN @lt_prog_names
          WHERE pgmid    = @gc_pgmid_r3tr
            AND object   = @gc_obj_prog
            AND obj_name = @lt_prog_names-table_line.

        LOOP AT lt_tadir_buf INTO ls_tadir_cache.
          INSERT ls_tadir_cache INTO TABLE lt_tadir_cache.
        ENDLOOP.
      ENDIF.

      IF lt_fugr_names IS NOT INITIAL.
        CLEAR lt_tadir_buf.
        SELECT object, obj_name, devclass
          FROM tadir
          INTO TABLE @lt_tadir_buf
          FOR ALL ENTRIES IN @lt_fugr_names
          WHERE pgmid    = @gc_pgmid_r3tr
            AND object   = @gc_obj_fugr
            AND obj_name = @lt_fugr_names-table_line.

        LOOP AT lt_tadir_buf INTO ls_tadir_cache.
          INSERT ls_tadir_cache INTO TABLE lt_tadir_cache.
        ENDLOOP.
      ENDIF.

      IF lt_class_names IS NOT INITIAL.
        CLEAR lt_tadir_buf.
        SELECT object, obj_name, devclass
          FROM tadir
          INTO TABLE @lt_tadir_buf
          FOR ALL ENTRIES IN @lt_class_names
          WHERE pgmid    = @gc_pgmid_r3tr
            AND object   = @gc_obj_clas
            AND obj_name = @lt_class_names-table_line.

        LOOP AT lt_tadir_buf INTO ls_tadir_cache.
          INSERT ls_tadir_cache INTO TABLE lt_tadir_cache.
        ENDLOOP.
      ENDIF.

      LOOP AT lt_founds INTO ls_fx WHERE program IS NOT INITIAL.

        IF ls_fx-used_cls = gc_used_comm.
          CONTINUE.
        ENDIF.

        CLEAR: lv_devclass_hit, lv_is_tmp_hit.
        DATA(lv_root_repid) = ls_fx-program.

        READ TABLE lt_tadir_cache
          INTO ls_tadir_cache
          WITH TABLE KEY object   = gc_obj_prog
                         obj_name = ls_fx-program.

        IF sy-subrc = 0.
          lv_devclass_hit = ls_tadir_cache-devclass.
          lv_is_tmp_hit   = xsdbool( lv_devclass_hit = gc_dev_tmp ).
        ELSE.

          CLEAR lv_devclass_hit.

          IF strlen( ls_fx-program ) >= gc_len_sapl AND substring( val = ls_fx-program len = gc_len_sapl_prefix ) = gc_prefix_sapl.
            lv_fugr_main = substring( val = ls_fx-program off = gc_len_sapl_prefix ).

            READ TABLE lt_tadir_cache
              INTO ls_tadir_cache
              WITH TABLE KEY object   = gc_obj_fugr
                             obj_name = CONV tadir-obj_name( lv_fugr_main ).

            IF sy-subrc = 0.
              lv_devclass_hit = ls_tadir_cache-devclass.
              lv_is_tmp_hit   = xsdbool( lv_devclass_hit = gc_dev_tmp ).
            ENDIF.
          ENDIF.

          IF lv_devclass_hit IS INITIAL.

            IF strlen( ls_fx-program ) >= gc_len_class_prog.
              CLEAR lv_class_30.
              lv_class_30 = substring( val = ls_fx-program len = gc_len_class_name ).

              CLEAR lv_class_name.
              lv_class_name = lv_class_30.
              SHIFT lv_class_name RIGHT DELETING TRAILING gc_char_eq.

              IF lv_class_name IS NOT INITIAL.
                READ TABLE lt_tadir_cache
                  INTO ls_tadir_cache
                  WITH TABLE KEY object   = gc_obj_clas
                                 obj_name = CONV tadir-obj_name( lv_class_name ).

                IF sy-subrc = 0.
                  lv_devclass_hit = ls_tadir_cache-devclass.

                  CLEAR lv_class_prog2.
                  lv_class_prog2 = lv_class_name.
                  REPLACE ALL OCCURRENCES OF space IN lv_class_prog2 WITH gc_char_eq.
                  lv_root_repid = |{ substring( val = lv_class_prog2 len = gc_len_class_name ) }{ gc_suffix_cp }|.

                  lv_is_tmp_hit = xsdbool( lv_devclass_hit = gc_dev_tmp ).
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

          IF lv_devclass_hit IS INITIAL.
            lv_rep_u = ls_fx-program.
            lv_rep_u = to_upper( lv_rep_u ).

            CLEAR: lv_fg_name, lv_fg_suffix.
            FIND FIRST OCCURRENCE OF PCRE gc_regex_fg_inc
                 IN lv_rep_u
                 SUBMATCHES lv_fg_name lv_fg_suffix.

            IF sy-subrc = 0 AND lv_fg_name IS NOT INITIAL.
              READ TABLE lt_tadir_cache
                INTO ls_tadir_cache
                WITH TABLE KEY object   = gc_obj_fugr
                               obj_name = CONV tadir-obj_name( lv_fg_name ).

              IF sy-subrc = 0.
                lv_devclass_hit = ls_tadir_cache-devclass.
                CONCATENATE gc_prefix_sapl lv_fg_name INTO lv_root_repid.
                lv_is_tmp_hit = xsdbool( lv_devclass_hit = gc_dev_tmp ).
              ENDIF.
            ENDIF.
          ENDIF.

        ENDIF.

        IF lv_is_tmp_hit = abap_true.
          CONTINUE.
        ELSEIF lv_devclass_hit IS NOT INITIAL.
          APPEND VALUE #( sign = gc_range_sign_inc option = gc_range_opt_eq low = lv_devclass_hit ) TO ls_scope_comm.
        ELSEIF lv_root_repid IS NOT INITIAL.
          INSERT lv_root_repid INTO TABLE lt_seed_repids.
        ENDIF.

      ENDLOOP.

      IF ls_scope_comm IS INITIAL AND lt_seed_repids IS INITIAL.
        IF ( iv_find_obj_cls = gc_obj_incl OR iv_find_obj_cls = gc_obj_prog ) AND iv_object IS NOT INITIAL.

          CLEAR lv_devclass.
          SELECT SINGLE devclass
            FROM tadir
            INTO @lv_devclass
            WHERE pgmid    = @gc_pgmid_r3tr
              AND object   = @gc_obj_prog
              AND obj_name = @iv_object.

          IF sy-subrc = 0 AND lv_devclass <> gc_dev_tmp.
            INSERT CONV syrepid( iv_object ) INTO TABLE lt_seed_repids.
          ENDIF.

        ELSEIF iv_find_obj_cls = gc_obj_clas AND lv_object_root IS NOT INITIAL.

          CLEAR lv_devclass.
          SELECT SINGLE devclass
            FROM tadir
            INTO @lv_devclass
            WHERE pgmid    = @gc_pgmid_r3tr
              AND object   = @gc_obj_clas
              AND obj_name = @lv_object_root.

          IF sy-subrc = 0 AND lv_devclass <> gc_dev_tmp.
            CLEAR lv_class_prog3.
            lv_class_prog3 = lv_object_root.
            WHILE strlen( lv_class_prog3 ) < gc_len_class_name.
              lv_class_prog3 = lv_class_prog3 && gc_char_eq.
            ENDWHILE.
            lv_class_prog3 = lv_class_prog3 && gc_suffix_cp.
            INSERT lv_class_prog3 INTO TABLE lt_seed_repids.
          ENDIF.

        ENDIF.
      ENDIF.

      IF ls_scope_comm IS INITIAL AND lt_seed_repids IS INITIAL.

        CLEAR lv_devclass.
        lv_tadir_object2 = lv_tadir_object.

        IF lv_tadir_object2 = gc_obj_incl.
          lv_tadir_object2 = gc_obj_prog.
        ENDIF.

        IF lv_tadir_object2 = gc_obj_func.
          CLEAR lv_fugr.
          SELECT SINGLE area
            FROM enlfdir
            INTO @lv_fugr
            WHERE funcname = @iv_object.

          IF sy-subrc = 0 AND lv_fugr IS NOT INITIAL.
            lv_tadir_object2 = gc_obj_fugr.

            SELECT SINGLE devclass
              FROM tadir
              INTO @lv_devclass
              WHERE pgmid    = @gc_pgmid_r3tr
                AND object   = @lv_tadir_object2
                AND obj_name = @lv_fugr.

            IF sy-subrc <> 0.
              CLEAR lv_devclass.
            ENDIF.
          ENDIF.
        ELSE.
          IF lv_tadir_object2 = gc_obj_clas.
            SELECT SINGLE devclass
              FROM tadir
              INTO @lv_devclass
              WHERE pgmid    = @gc_pgmid_r3tr
                AND object   = @lv_tadir_object2
                AND obj_name = @lv_object_root.
          ELSE.
            SELECT SINGLE devclass
              FROM tadir
              INTO @lv_devclass
              WHERE pgmid    = @gc_pgmid_r3tr
                AND object   = @lv_tadir_object2
                AND obj_name = @iv_object.
          ENDIF.

          IF sy-subrc <> 0.
            CLEAR lv_devclass.
          ENDIF.
        ENDIF.

        IF lv_devclass IS NOT INITIAL AND lv_devclass <> gc_dev_tmp.
          APPEND VALUE #( sign = gc_range_sign_inc option = gc_range_opt_eq low = lv_devclass ) TO ls_scope_comm.
        ENDIF.
      ENDIF.

      DELETE ls_scope_comm WHERE low IS INITIAL OR low = gc_dev_tmp.
      SORT ls_scope_comm BY sign option low high.
      DELETE ADJACENT DUPLICATES FROM ls_scope_comm COMPARING sign option low high.

      IF ls_scope_comm IS INITIAL AND lt_seed_repids IS INITIAL.
        MESSAGE w027(z_gsp04_message).
      ELSE.

        CLEAR lt_repids.

        LOOP AT lt_seed_repids INTO DATA(lv_root2).
          INSERT lv_root2 INTO TABLE lt_repids.
          IF lines( lt_repids ) >= gc_max_repids.
            EXIT.
          ENDIF.
        ENDLOOP.

        IF ls_scope_comm IS NOT INITIAL AND lines( lt_repids ) < gc_max_repids.

          SELECT a~obj_name
            FROM tadir AS a
            INNER JOIN trdir AS t
              ON t~name = a~obj_name
            INTO TABLE @lt_prog_roots2
            WHERE a~pgmid    = @gc_pgmid_r3tr
              AND a~object   = @gc_obj_prog
              AND a~devclass IN @ls_scope_comm
              AND t~subc     <> @gc_trdir_subc_i.

          LOOP AT lt_prog_roots2 INTO DATA(lv_prog_root2).
            INSERT lv_prog_root2 INTO TABLE lt_repids.
            IF lines( lt_repids ) >= gc_max_repids.
              EXIT.
            ENDIF.
          ENDLOOP.

          IF lines( lt_repids ) < gc_max_repids.
            CLEAR lt_classes2.
            SELECT obj_name
              FROM tadir
              INTO TABLE @lt_classes2
              WHERE pgmid    = @gc_pgmid_r3tr
                AND object   = @gc_obj_clas
                AND devclass IN @ls_scope_comm.

            LOOP AT lt_classes2 INTO DATA(lv_class2).
              CLEAR lv_class_prog3.
              lv_class_prog3 = lv_class2.
              WHILE strlen( lv_class_prog3 ) < gc_len_class_name.
                lv_class_prog3 = lv_class_prog3 && gc_char_eq.
              ENDWHILE.
              lv_class_prog3 = lv_class_prog3 && gc_suffix_cp.
              INSERT lv_class_prog3 INTO TABLE lt_repids.

              IF lines( lt_repids ) >= gc_max_repids.
                EXIT.
              ENDIF.
            ENDLOOP.
          ENDIF.

          IF lines( lt_repids ) < gc_max_repids.
            CLEAR lt_fugrs2.
            SELECT obj_name
              FROM tadir
              INTO TABLE @lt_fugrs2
              WHERE pgmid    = @gc_pgmid_r3tr
                AND object   = @gc_obj_fugr
                AND devclass IN @ls_scope_comm.

            LOOP AT lt_fugrs2 INTO DATA(lv_fugr3).
              CLEAR lv_fugr_prog2.
              lv_fugr_prog2 = |{ gc_prefix_sapl }{ lv_fugr3 }|.
              INSERT lv_fugr_prog2 INTO TABLE lt_repids.

              IF lines( lt_repids ) >= gc_max_repids.
                EXIT.
              ENDIF.
            ENDLOOP.
          ENDIF.

        ENDIF.

        CLEAR lt_all_includes.
        lt_expand_from2 = lt_repids.
        LOOP AT lt_expand_from2 INTO DATA(lv_expand_prog2).

          CLEAR lt_includes2.

          CALL FUNCTION 'RS_GET_ALL_INCLUDES'
            EXPORTING
              program             = lv_expand_prog2
              with_class_includes = gc_flag_x
            TABLES
              includetab          = lt_includes2
            EXCEPTIONS
              not_existent        = 1
              no_program          = 2
              OTHERS              = 3.

          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          INSERT LINES OF lt_includes2 INTO TABLE lt_all_includes.
        ENDLOOP.

        CLEAR lt_all_repids.

        APPEND LINES OF lt_repids       TO lt_all_repids.
        APPEND LINES OF lt_all_includes TO lt_all_repids.

        DELETE lt_all_repids WHERE table_line IS INITIAL.

        SORT lt_all_repids BY table_line.
        DELETE ADJACENT DUPLICATES FROM lt_all_repids COMPARING table_line.

        "Limit number of programs/includes to scan
        IF lines( lt_all_repids ) > gc_max_repids.
          lv_delete_from = gc_max_repids + 1.
          DELETE lt_all_repids FROM lv_delete_from.
        ENDIF.

        "Rebuild unique table safely
        CLEAR lt_repids.
        INSERT LINES OF lt_all_repids INTO TABLE lt_repids.
        IF lt_repids IS NOT INITIAL.
          lt_comm = scan_comment_out(
                      it_repids       = lt_repids
                      iv_find_obj_cls = iv_find_obj_cls
                      iv_object       = iv_object ).
          APPEND LINES OF lt_comm TO lt_founds.
        ENDIF.

      ENDIF.
    ENDIF.

    "----------------------------------------------------------------------
    " G) dedupe + return
    "----------------------------------------------------------------------
*    SORT lt_founds BY used_cls used_obj program object_row.
*    DELETE ADJACENT DUPLICATES FROM lt_founds
*      COMPARING used_cls used_obj program object_row.
*
*    rt_founds = lt_founds.

" Keep real self-calls only when they have a source location.
" A true recursive/self reference must still have PROGRAM and OBJECT_ROW.
" Rows without PROGRAM are non-navigable cross-reference/index rows.
    DELETE lt_founds WHERE program IS INITIAL.

    SORT lt_founds BY used_cls used_obj program object_row.
    DELETE ADJACENT DUPLICATES FROM lt_founds
      COMPARING used_cls used_obj program object_row.

    rt_founds = lt_founds.
    IF ev_index_suspect = abap_true.
      MESSAGE w028(z_gsp04_message).
    ENDIF.

  ENDMETHOD.


METHOD scan_comment_out.

    "======================================================================
    " A) Local data
    "======================================================================
    DATA lv_obj_u TYPE string.
    DATA lv_repid TYPE syrepid.
    DATA lt_src   TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_line  TYPE string.
    DATA lv_trim  TYPE string.
    DATA lv_pay   TYPE string.
    DATA lv_u     TYPE string.
    DATA lv_idx   TYPE sy-tabix.
    DATA lv_lines TYPE i.

    DATA ls_found TYPE rsfindlst.
    DATA lv_hit   TYPE abap_bool.
    DATA lv_re    TYPE string.

    "======================================================================
    " B) Guard clause
    "======================================================================
    CLEAR rt_founds.
    IF it_repids IS INITIAL OR iv_object IS INITIAL.
      RETURN.
    ENDIF.

    "======================================================================
    " C) Normalize target object
    "======================================================================
    lv_obj_u = iv_object.
    TRANSLATE lv_obj_u TO UPPER CASE.

    "======================================================================
    " D) Scan each report
    "======================================================================
    LOOP AT it_repids INTO lv_repid.

      CLEAR lt_src.

      "Try inactive first (if edited but not activated), then active/default
      READ REPORT lv_repid STATE gc_state_inactive INTO lt_src.
      IF sy-subrc <> 0 OR lt_src IS INITIAL.
        READ REPORT lv_repid INTO lt_src.
      ENDIF.

      IF sy-subrc <> 0 OR lt_src IS INITIAL.
        CONTINUE.
      ENDIF.

      lv_lines = lines( lt_src ).

      DO lv_lines TIMES.
        lv_idx = sy-index.
        READ TABLE lt_src INTO lv_line INDEX lv_idx.

        IF lv_line IS INITIAL.
          CONTINUE.
        ENDIF.

        "Trim for checks
        lv_trim = lv_line.
        SHIFT lv_trim LEFT DELETING LEADING space.
        IF lv_trim IS INITIAL.
          CONTINUE.
        ENDIF.

        "Only full-line comments:
        "  * at column 1  OR  " after optional leading spaces
        CLEAR lv_pay.

        IF lv_line+0(1) = gc_comment_star.
          IF strlen( lv_line ) > 1.
            lv_pay = lv_line+1.
          ELSE.
            CONTINUE.
          ENDIF.
        ELSEIF lv_trim+0(1) = gc_comment_quote.
          IF strlen( lv_trim ) > 1.
            lv_pay = lv_trim+1.
          ELSE.
            CONTINUE.
          ENDIF.
        ELSE.
          CONTINUE.
        ENDIF.

        SHIFT lv_pay LEFT DELETING LEADING space.
        IF lv_pay IS INITIAL.
          CONTINUE.
        ENDIF.

        "Uppercase copy for matching
        lv_u = lv_pay.
        TRANSLATE lv_u TO UPPER CASE.

        lv_hit = abap_false.

        CASE iv_find_obj_cls.

          WHEN gc_obj_incl.
            lv_re = gc_regex_incl_comment.
            REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.

            FIND PCRE lv_re IN lv_u.
            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.

          WHEN gc_obj_func.
            lv_re = gc_regex_func_comment.
            REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.

            FIND PCRE lv_re IN lv_u.
            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.

          WHEN gc_obj_prog.
            lv_re = gc_regex_prog_comment.
            REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.

            FIND PCRE lv_re IN lv_u.
            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.

          WHEN gc_obj_clas.
            "1) NEW <class>
            lv_re = gc_regex_clas_new.
            REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.
            FIND PCRE lv_re IN lv_u.
            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.

            "2) TYPE REF TO <class>
            IF lv_hit = abap_false.
              lv_re = gc_regex_clas_type_ref.
              REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.
              FIND PCRE lv_re IN lv_u.
              IF sy-subrc = 0.
                lv_hit = abap_true.
              ENDIF.
            ENDIF.

            "3) REF TO <class>
            IF lv_hit = abap_false.
              lv_re = gc_regex_clas_ref_to.
              REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.
              FIND PCRE lv_re IN lv_u.
              IF sy-subrc = 0.
                lv_hit = abap_true.
              ENDIF.
            ENDIF.

            "4) CREATE OBJECT ... TYPE <class>
            IF lv_hit = abap_false.
              lv_re = gc_regex_clas_create.
              REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.
              FIND PCRE lv_re IN lv_u.
              IF sy-subrc = 0.
                lv_hit = abap_true.
              ENDIF.
            ENDIF.

            "5) <class>=>
            IF lv_hit = abap_false.
              lv_re = gc_regex_clas_static.
              REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.
              FIND PCRE lv_re IN lv_u.
              IF sy-subrc = 0.
                lv_hit = abap_true.
              ENDIF.
            ENDIF.

          WHEN OTHERS.
            lv_re = gc_regex_default_obj.
            REPLACE ALL OCCURRENCES OF gc_placeholder_obj IN lv_re WITH lv_obj_u.
            FIND PCRE lv_re IN lv_u.

            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.

        ENDCASE.

        IF lv_hit = abap_false.
          CONTINUE.
        ENDIF.

        CLEAR ls_found.
        ls_found-used_cls   = gc_used_comm.
        ls_found-used_obj   = iv_object.
        ls_found-program    = lv_repid.
        ls_found-object     = lv_idx.
        ls_found-object_row = lv_idx.
        APPEND ls_found TO rt_founds.

      ENDDO.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
