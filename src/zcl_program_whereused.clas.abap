CLASS zcl_program_whereused DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "Kết quả where-used
    TYPES ty_founds TYPE STANDARD TABLE OF rsfindlst WITH EMPTY KEY.

    "NEW: dùng range devclass để scan comment-out nhiều package
    TYPES ty_r_devclass TYPE RANGE OF devclass.

    METHODS get_where_used
      IMPORTING
        iv_find_obj_cls     TYPE euobj-id
        iv_object           TYPE rsobject
        iv_tadir_object     TYPE tadir-object OPTIONAL
        iv_default_devclass TYPE devclass OPTIONAL
        it_comment_scope    TYPE ty_r_devclass OPTIONAL
        iv_recursive        TYPE abap_bool DEFAULT abap_false
        iv_advanced_wide    TYPE abap_bool DEFAULT abap_false
        iv_include_comments TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_last_subrc       TYPE sy-subrc
        ev_index_suspect    TYPE abap_bool
      RETURNING
        VALUE(rt_founds)    TYPE ty_founds.
protected section.
PRIVATE SECTION.

  TYPES: ty_t_euobj_id TYPE STANDARD TABLE OF euobj-id WITH EMPTY KEY,
         tt_repids     TYPE SORTED TABLE OF syrepid WITH UNIQUE KEY table_line.

  METHODS scan_comment_out
    IMPORTING
      it_repids        TYPE tt_repids
      iv_find_obj_cls  TYPE euobj-id
      iv_object        TYPE rsobject
    RETURNING
      VALUE(rt_founds) TYPE ty_founds.
ENDCLASS.



CLASS ZCL_PROGRAM_WHEREUSED IMPLEMENTATION.


METHOD get_where_used.

  ev_last_subrc    = 0.
  ev_index_suspect = abap_false.

  "Resolve TADIR object once
  DATA(lv_tadir_object) = iv_tadir_object.
  IF lv_tadir_object IS INITIAL.
    CASE iv_find_obj_cls.
      WHEN 'CLAS'. lv_tadir_object = 'CLAS'.
      WHEN 'PROG' OR 'INCL'. lv_tadir_object = 'PROG'.
      WHEN 'FUNC'. lv_tadir_object = 'FUNC'.
      WHEN OTHERS. lv_tadir_object = 'PROG'.
    ENDCASE.
  ENDIF.

  "----------------------------------------------------------------------
  "A) candidates OBJ_CLS  (INLINE build_obj_cls_candidates)
  "----------------------------------------------------------------------
  DATA lt_cls TYPE ty_t_euobj_id.
  lt_cls = VALUE #( ( lv_tadir_object ) ).

  CASE lv_tadir_object.
    WHEN 'PROG'.
      APPEND 'INCL' TO lt_cls.
    WHEN 'FUGR'.
      APPEND 'FUNC' TO lt_cls.
    WHEN OTHERS.
  ENDCASE.

  SORT lt_cls BY table_line.
  DELETE ADJACENT DUPLICATES FROM lt_cls COMPARING table_line.

  "----------------------------------------------------------------------
  "B) scope (devclass range) for XREF only (INLINE determine_scope_range + get_object_devclass)
  "----------------------------------------------------------------------
  DATA lt_scope TYPE ty_r_devclass.
  CLEAR lt_scope.

  IF iv_advanced_wide = abap_true.
    " leave lt_scope initial
  ELSE.

    "INLINE get_object_devclass
    DATA lv_devclass TYPE devclass.
    DATA lv_tadir_object2 TYPE tadir-object.
    DATA lv_fugr TYPE rs38l-area.

    CLEAR lv_devclass.

    lv_tadir_object2 = lv_tadir_object.

    IF lv_tadir_object2 = 'INCL'.
      lv_tadir_object2 = 'PROG'.
    ENDIF.

    IF lv_tadir_object2 = 'FUNC'.
      CLEAR lv_fugr.
      SELECT SINGLE area
        FROM enlfdir
        INTO lv_fugr
        WHERE funcname = iv_object.

      IF sy-subrc = 0 AND lv_fugr IS NOT INITIAL.
        lv_tadir_object2 = 'FUGR'.

        SELECT SINGLE devclass
          FROM tadir
          INTO lv_devclass
          WHERE pgmid    = 'R3TR'
            AND object   = lv_tadir_object2
            AND obj_name = lv_fugr.

        IF sy-subrc <> 0.
          CLEAR lv_devclass.
        ENDIF.
      ELSE.
        CLEAR lv_devclass.
      ENDIF.
    ELSE.
      SELECT SINGLE devclass
        FROM tadir
        INTO lv_devclass
        WHERE pgmid    = 'R3TR'
          AND object   = lv_tadir_object2
          AND obj_name = iv_object.

      IF sy-subrc <> 0.
        CLEAR lv_devclass.
      ENDIF.
    ENDIF.

    IF lv_devclass IS INITIAL OR lv_devclass = '$TMP'.
      lv_devclass = iv_default_devclass.
    ENDIF.

    IF lv_devclass IS NOT INITIAL AND lv_devclass <> '$TMP'.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_devclass ) TO lt_scope.
    ENDIF.

  ENDIF.

  "----------------------------------------------------------------------
  "C) crossref (semantic where-used, based on index)  (INLINE call_crossref_first_match)
  "----------------------------------------------------------------------
  DATA lt_founds TYPE ty_founds.
  CLEAR lt_founds.

  DATA lt_findstrings TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  APPEND iv_object TO lt_findstrings.

  LOOP AT lt_cls INTO DATA(lv_cls).
    CLEAR lt_founds.

    CALL FUNCTION 'RS_EU_CROSSREF'
      EXPORTING
        i_find_obj_cls           = lv_cls
        no_dialog                = abap_true
        rekursiv                 = xsdbool( iv_recursive = abap_true )
      TABLES
        i_findstrings            = lt_findstrings
        i_scope_devclass         = lt_scope
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

    IF lt_founds IS NOT INITIAL.
      EXIT.
    ENDIF.

    IF ev_last_subrc = 2 OR ev_last_subrc = 4 OR ev_last_subrc = 7.
      ev_index_suspect = abap_true.
    ENDIF.
  ENDLOOP.

  "If crossref failed (not_found=2 is OK), show warning but still continue
  IF ev_last_subrc <> 0 AND ev_last_subrc <> 2.
    MESSAGE |Where-used cross-reference failed (subrc { ev_last_subrc }).|
      TYPE 'W' DISPLAY LIKE 'W'.
  ENDIF.

  "----------------------------------------------------------------------
  "D) Optional: supports multiple devclass via it_comment_scope
  "----------------------------------------------------------------------
  IF iv_include_comments = abap_true.

    DATA lt_scope_comm  TYPE ty_r_devclass.
    DATA lt_seed_repids TYPE tt_repids.

    " 1) explicit caller scope wins
    lt_scope_comm = it_comment_scope.

    " 2) derive from semantic where-used hits
    LOOP AT lt_founds INTO DATA(ls_fx) WHERE program IS NOT INITIAL.

      IF ls_fx-used_cls = 'COMM'.
        CONTINUE.
      ENDIF.

      DATA(lv_devclass_hit) = VALUE devclass( ).
      DATA(lv_is_tmp_hit)   = abap_false.
      DATA(lv_root_repid)   = VALUE syrepid( ).

      "INLINE resolve_scan_anchor (iv_repid = ls_fx-program)
      DATA: lv_fugr_main   TYPE rs38l-area,
            lv_class_30    TYPE c LENGTH 30,
            lv_class_name  TYPE seoclsname,
            lv_rep_u       TYPE string,
            lv_fg_name     TYPE string,
            lv_fg_suffix   TYPE string,
            lv_class_prog2 TYPE syrepid.

      CLEAR: lv_devclass_hit, lv_is_tmp_hit.
      lv_root_repid = ls_fx-program.

      SELECT SINGLE devclass
        FROM tadir
        INTO lv_devclass_hit
        WHERE pgmid    = 'R3TR'
          AND object   = 'PROG'
          AND obj_name = ls_fx-program.

      IF sy-subrc = 0.
        lv_is_tmp_hit = xsdbool( lv_devclass_hit = '$TMP' ).
      ELSE.

        CLEAR lv_devclass_hit.

        IF strlen( ls_fx-program ) >= 5 AND ls_fx-program+0(4) = 'SAPL'.
          lv_fugr_main = ls_fx-program+4.

          SELECT SINGLE devclass
            FROM tadir
            INTO lv_devclass_hit
            WHERE pgmid    = 'R3TR'
              AND object   = 'FUGR'
              AND obj_name = lv_fugr_main.

          IF sy-subrc = 0.
            lv_is_tmp_hit = xsdbool( lv_devclass_hit = '$TMP' ).
          ENDIF.
        ENDIF.

        IF lv_devclass_hit IS INITIAL.

          IF strlen( ls_fx-program ) >= 32.
            CLEAR lv_class_30.
            lv_class_30 = ls_fx-program(30).

            CLEAR lv_class_name.
            lv_class_name = lv_class_30.
            SHIFT lv_class_name RIGHT DELETING TRAILING '='.

            IF lv_class_name IS NOT INITIAL.
              SELECT SINGLE devclass
                FROM tadir
                INTO lv_devclass_hit
                WHERE pgmid    = 'R3TR'
                  AND object   = 'CLAS'
                  AND obj_name = lv_class_name.

              IF sy-subrc = 0.
                CLEAR lv_class_prog2.
                lv_class_prog2 = lv_class_name.
                REPLACE ALL OCCURRENCES OF space IN lv_class_prog2 WITH '='.
                CONCATENATE lv_class_prog2+0(30) 'CP' INTO lv_root_repid.
                lv_is_tmp_hit = xsdbool( lv_devclass_hit = '$TMP' ).
              ENDIF.
            ENDIF.
          ENDIF.

        ENDIF.

        IF lv_devclass_hit IS INITIAL.
          lv_rep_u = ls_fx-program.
          TRANSLATE lv_rep_u TO UPPER CASE.

          CLEAR: lv_fg_name, lv_fg_suffix.
          FIND FIRST OCCURRENCE OF PCRE '^L(.+)(TOP|U[0-9A-Z]{2}|F[0-9A-Z]{2}|I[0-9A-Z]{2}|O[0-9A-Z]{2})$'
               IN lv_rep_u
               SUBMATCHES lv_fg_name lv_fg_suffix.

          IF sy-subrc = 0 AND lv_fg_name IS NOT INITIAL.
            SELECT SINGLE devclass
              FROM tadir
              INTO lv_devclass_hit
              WHERE pgmid    = 'R3TR'
                AND object   = 'FUGR'
                AND obj_name = lv_fg_name.

            IF sy-subrc = 0.
              CONCATENATE 'SAPL' lv_fg_name INTO lv_root_repid.
              lv_is_tmp_hit = xsdbool( lv_devclass_hit = '$TMP' ).
            ENDIF.
          ENDIF.
        ENDIF.

      ENDIF.

      IF lv_is_tmp_hit = abap_true.
        IF lv_root_repid IS NOT INITIAL.
          INSERT lv_root_repid INTO TABLE lt_seed_repids.
        ENDIF.
      ELSEIF lv_devclass_hit IS NOT INITIAL.
        APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_devclass_hit ) TO lt_scope_comm.
      ELSEIF lv_root_repid IS NOT INITIAL.
        INSERT lv_root_repid INTO TABLE lt_seed_repids.
      ENDIF.

    ENDLOOP.

    " 3) direct safe fallback for include/program input itself
    IF lt_scope_comm IS INITIAL AND lt_seed_repids IS INITIAL.
      IF ( iv_find_obj_cls = 'INCL' OR iv_find_obj_cls = 'PROG' ) AND iv_object IS NOT INITIAL.
        INSERT CONV syrepid( iv_object ) INTO TABLE lt_seed_repids.
      ENDIF.
    ENDIF.

    " 4) fallback to target object package only if non-$TMP (INLINE get_object_devclass)
    IF lt_scope_comm IS INITIAL AND lt_seed_repids IS INITIAL.

      DATA lv_obj_devclass TYPE devclass.
      DATA lv_tadir_object3 TYPE tadir-object.
      DATA lv_fugr2 TYPE rs38l-area.

      CLEAR lv_obj_devclass.
      lv_tadir_object3 = iv_tadir_object.

      IF lv_tadir_object3 = 'INCL'.
        lv_tadir_object3 = 'PROG'.
      ENDIF.

      IF lv_tadir_object3 = 'FUNC'.
        CLEAR lv_fugr2.
        SELECT SINGLE area
          FROM enlfdir
          INTO lv_fugr2
          WHERE funcname = iv_object.

        IF sy-subrc = 0 AND lv_fugr2 IS NOT INITIAL.
          lv_tadir_object3 = 'FUGR'.

          SELECT SINGLE devclass
            FROM tadir
            INTO lv_obj_devclass
            WHERE pgmid    = 'R3TR'
              AND object   = lv_tadir_object3
              AND obj_name = lv_fugr2.

          IF sy-subrc <> 0.
            CLEAR lv_obj_devclass.
          ENDIF.
        ENDIF.
      ELSE.
        SELECT SINGLE devclass
          FROM tadir
          INTO lv_obj_devclass
          WHERE pgmid    = 'R3TR'
            AND object   = lv_tadir_object3
            AND obj_name = iv_object.

        IF sy-subrc <> 0.
          CLEAR lv_obj_devclass.
        ENDIF.
      ENDIF.

      IF lv_obj_devclass IS NOT INITIAL AND lv_obj_devclass <> '$TMP'.
        APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_obj_devclass ) TO lt_scope_comm.
      ENDIF.
    ENDIF.

    " 5) sanitize package scope
    DELETE lt_scope_comm WHERE low IS INITIAL OR low = '$TMP'.
    SORT lt_scope_comm BY sign option low high.
    DELETE ADJACENT DUPLICATES FROM lt_scope_comm COMPARING sign option low high.

    " 6) execute only on safe scope
    IF lt_scope_comm IS INITIAL AND lt_seed_repids IS INITIAL.
      MESSAGE 'Comment-out scan skipped (no safe package/seed scope).' TYPE 'W'.
    ELSE.

      "INLINE get_repids_from_scope
      TYPES:
        tt_root_repids TYPE SORTED TABLE OF syrepid WITH UNIQUE KEY table_line,
        tt_tadir_name  TYPE STANDARD TABLE OF tadir-obj_name WITH EMPTY KEY.

      DATA:
        lt_roots2       TYPE tt_root_repids,
        lt_expand_from2 TYPE tt_root_repids,
        lt_prog_roots2  TYPE tt_tadir_name,
        lt_classes2     TYPE tt_tadir_name,
        lt_fugrs2       TYPE tt_tadir_name,
        lt_includes2    TYPE STANDARD TABLE OF syrepid WITH EMPTY KEY,
        lv_prog_root2   TYPE tadir-obj_name,
        lv_class2       TYPE tadir-obj_name,
        lv_fugr3        TYPE tadir-obj_name,
        lv_root2        TYPE syrepid,
        lv_expand_prog2 TYPE syrepid,
        lv_inc2         TYPE syrepid,
        lv_class_prog3  TYPE syrepid,
        lv_fugr_prog2   TYPE syrepid.

      DATA lt_repids TYPE tt_repids.
      CLEAR lt_repids.

      LOOP AT lt_seed_repids INTO lv_root2.
        INSERT lv_root2 INTO TABLE lt_repids.
        IF lines( lt_repids ) >= 5000.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF lt_scope_comm IS NOT INITIAL AND lines( lt_repids ) < 5000.

        SELECT a~obj_name
          FROM tadir AS a
          INNER JOIN trdir AS t
            ON t~name = a~obj_name
          INTO TABLE lt_prog_roots2
          WHERE a~pgmid    = 'R3TR'
            AND a~object   = 'PROG'
            AND a~devclass IN lt_scope_comm
            AND t~subc     <> 'I'.

        LOOP AT lt_prog_roots2 INTO lv_prog_root2.
          INSERT lv_prog_root2 INTO TABLE lt_roots2.
          IF lines( lt_roots2 ) >= 5000.
            lt_repids = lt_roots2.
            EXIT.
          ENDIF.
        ENDLOOP.

        CLEAR lt_classes2.
        SELECT obj_name
          FROM tadir
          INTO TABLE lt_classes2
          WHERE pgmid    = 'R3TR'
            AND object   = 'CLAS'
            AND devclass IN lt_scope_comm.

        LOOP AT lt_classes2 INTO lv_class2.
          CLEAR lv_class_prog3.
          lv_class_prog3 = |{ lv_class2 WIDTH = 30 PAD = '=' }CP|.
          INSERT lv_class_prog3 INTO TABLE lt_roots2.

          IF lines( lt_roots2 ) >= 5000.
            lt_repids = lt_roots2.
            EXIT.
          ENDIF.
        ENDLOOP.

        CLEAR lt_fugrs2.
        SELECT obj_name
          FROM tadir
          INTO TABLE lt_fugrs2
          WHERE pgmid    = 'R3TR'
            AND object   = 'FUGR'
            AND devclass IN lt_scope_comm.

        LOOP AT lt_fugrs2 INTO lv_fugr3.
          CLEAR lv_fugr_prog2.
          lv_fugr_prog2 = |SAPL{ lv_fugr3 }|.
          INSERT lv_fugr_prog2 INTO TABLE lt_roots2.

          IF lines( lt_roots2 ) >= 5000.
            lt_repids = lt_roots2.
            EXIT.
          ENDIF.
        ENDLOOP.

      ENDIF.

      LOOP AT lt_roots2 INTO lv_root2.
        INSERT lv_root2 INTO TABLE lt_repids.
        IF lines( lt_repids ) >= 5000.
          EXIT.
        ENDIF.
      ENDLOOP.

      lt_expand_from2 = lt_repids.

      LOOP AT lt_expand_from2 INTO lv_expand_prog2.

        CLEAR lt_includes2.
        CALL FUNCTION 'RS_GET_ALL_INCLUDES'
          EXPORTING
            program             = lv_expand_prog2
            with_class_includes = 'X'
          TABLES
            includetab          = lt_includes2
          EXCEPTIONS
            not_existent        = 1
            no_program          = 2
            OTHERS              = 3.

        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        LOOP AT lt_includes2 INTO lv_inc2.
          INSERT lv_inc2 INTO TABLE lt_repids.
          IF lines( lt_repids ) >= 5000.
            EXIT.
          ENDIF.
        ENDLOOP.

        IF lines( lt_repids ) >= 5000.
          EXIT.
        ENDIF.

      ENDLOOP.

      IF lt_repids IS NOT INITIAL.
        DATA(lt_comm) = scan_comment_out(
                          it_repids       = lt_repids
                          iv_find_obj_cls = iv_find_obj_cls
                          iv_object       = iv_object ).
        APPEND LINES OF lt_comm TO lt_founds.
      ENDIF.

    ENDIF.

  ENDIF.

  "----------------------------------------------------------------------
  "E) dedupe + return  (INLINE dedupe_founds)
  "----------------------------------------------------------------------
  SORT lt_founds BY used_cls used_obj program object_row.
  DELETE ADJACENT DUPLICATES FROM lt_founds
    COMPARING used_cls used_obj program object_row.

  rt_founds = lt_founds.

  IF ev_index_suspect = abap_true.
    MESSAGE |Warning: where-used index may be outdated/incomplete (EU_* jobs), results may be missing.|
      TYPE 'W' DISPLAY LIKE 'W'.
  ENDIF.

ENDMETHOD.


METHOD scan_comment_out.
  CLEAR rt_founds.
  IF it_repids IS INITIAL OR iv_object IS INITIAL.
    RETURN.
  ENDIF.

  DATA lv_obj_u TYPE string.
  lv_obj_u = iv_object.
  TRANSLATE lv_obj_u TO UPPER CASE.

  DATA lv_repid TYPE syrepid.
  DATA lt_src   TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  DATA lv_line  TYPE string.
  DATA lv_trim  TYPE string.
  DATA lv_pay   TYPE string.
  DATA lv_u     TYPE string.
  DATA lv_idx   TYPE sy-tabix.

  DATA ls_found TYPE rsfindlst.
  DATA lv_hit   TYPE abap_bool.
  DATA lv_re    TYPE string.

  "For INCLUDE parsing (kept for compatibility though we use PCRE for INCL now)
  DATA lt_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  DATA lv_part  TYPE string.
  DATA lv_off   TYPE i.
  DATA lv_dummy TYPE string.

  LOOP AT it_repids INTO lv_repid.

    CLEAR lt_src.

    "Try inactive first (if edited but not activated), then active/default
    READ REPORT lv_repid STATE 'I' INTO lt_src.
    IF sy-subrc <> 0 OR lt_src IS INITIAL.
      READ REPORT lv_repid INTO lt_src. "active/default
    ENDIF.

    IF sy-subrc <> 0 OR lt_src IS INITIAL.
      CONTINUE.
    ENDIF.

    LOOP AT lt_src INTO lv_line.
      lv_idx = sy-tabix.

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

      IF lv_line+0(1) = '*'.
        IF strlen( lv_line ) > 1.
          lv_pay = lv_line+1.
        ELSE.
          CONTINUE.
        ENDIF.
      ELSEIF lv_trim+0(1) = '"'.
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

        WHEN 'INCL'.
          "Match INCLUDE in full-line comments:
          "  INCLUDE zxxx.         / INCLUDE 'zxxx'.
          "  INCLUDE: a, b.        / INCLUDE: 'a', 'b'.
          "We are already inside comment payload (after removing * or ")
          lv_re = '^INCLUDE[[:space:]]*:?[[:space:]]*(''{OBJ}''|{OBJ})([^A-Z0-9_/]|$)'.
          REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.

          FIND PCRE lv_re IN lv_u.
          IF sy-subrc = 0.
            lv_hit = abap_true.
          ENDIF.

        WHEN 'FUNC'.
          lv_re = 'CALL[[:space:]]+FUNCTION[[:space:]]+(''{OBJ}''|{OBJ})([^A-Z0-9_/]|$)'.
          REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.

          FIND PCRE lv_re IN lv_u.
          IF sy-subrc = 0.
            lv_hit = abap_true.
          ENDIF.

        WHEN 'PROG'.
          lv_re = 'SUBMIT[[:space:]]+(''{OBJ}''|{OBJ})([^A-Z0-9_/]|$)'.
          REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.

          FIND PCRE lv_re IN lv_u.
          IF sy-subrc = 0.
            lv_hit = abap_true.
          ENDIF.

        WHEN 'CLAS'.
          "1) NEW <class>
          lv_re = 'NEW[[:space:]]+{OBJ}([^A-Z0-9_/]|$)'.
          REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.
          FIND PCRE lv_re IN lv_u.
          IF sy-subrc = 0.
            lv_hit = abap_true.
          ENDIF.

          "2) TYPE REF TO <class>
          IF lv_hit = abap_false.
            lv_re = 'TYPE[[:space:]]+REF[[:space:]]+TO[[:space:]]+{OBJ}([^A-Z0-9_/]|$)'.
            REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.
            FIND PCRE lv_re IN lv_u.
            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.
          ENDIF.

          "3) REF TO <class>
          IF lv_hit = abap_false.
            lv_re = 'REF[[:space:]]+TO[[:space:]]+{OBJ}([^A-Z0-9_/]|$)'.
            REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.
            FIND PCRE lv_re IN lv_u.
            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.
          ENDIF.

          "4) CREATE OBJECT ... TYPE <class>
          IF lv_hit = abap_false.
            lv_re = 'CREATE[[:space:]]+OBJECT.*TYPE[[:space:]]+{OBJ}([^A-Z0-9_/]|$)'.
            REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.
            FIND PCRE lv_re IN lv_u.
            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.
          ENDIF.

          "5) <class>=>
          IF lv_hit = abap_false.
            lv_re = '{OBJ}[[:space:]]*=>'.
            REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.
            FIND PCRE lv_re IN lv_u.
            IF sy-subrc = 0.
              lv_hit = abap_true.
            ENDIF.
          ENDIF.

        WHEN OTHERS.
          lv_re = '(^|[^A-Z0-9_/]){OBJ}([^A-Z0-9_/]|$)'.
          REPLACE ALL OCCURRENCES OF '{OBJ}' IN lv_re WITH lv_obj_u.
          FIND PCRE lv_re IN lv_u.

          IF sy-subrc = 0.
            lv_hit = abap_true.
          ENDIF.

      ENDCASE.

      IF lv_hit = abap_false.
        CONTINUE.
      ENDIF.

      CLEAR ls_found.
      ls_found-used_cls   = 'COMM'.
      ls_found-used_obj   = iv_object.
      ls_found-program    = lv_repid.
      ls_found-object_row = lv_idx.
      APPEND ls_found TO rt_founds.

    ENDLOOP.
  ENDLOOP.

ENDMETHOD.
ENDCLASS.
