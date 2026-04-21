CLASS zcl_program_fetch DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF gty_class_source,
             include      TYPE progname,
             include_kind TYPE char20,   " SECTION / METHOD / OTHER
             section      TYPE char20,   " PRIVATE-0 / PROTECTED-1 / PUBLIC-2
             method_level TYPE char20,   "INSTANCE-0 / STATIC-1
             description  TYPE seodescr,
             method_name  TYPE seocpdname,
             source_code  TYPE string_table,
           END OF gty_class_source.
    TYPES: gty_t_class_source TYPE STANDARD TABLE OF gty_class_source WITH EMPTY KEY .

    TYPES: BEGIN OF gty_program_source,
             include     TYPE programm,
             source_code TYPE string_table,
           END OF gty_program_source .
    TYPES: gty_t_program_source TYPE STANDARD TABLE OF gty_program_source WITH EMPTY KEY .

    TYPES: BEGIN OF gty_function_group,
             include     TYPE programm,
             type        TYPE char4,
             source_code TYPE string_table,
           END OF gty_function_group .
    TYPES: gty_t_function_group TYPE STANDARD TABLE OF gty_function_group WITH EMPTY KEY .

    METHODS get_program_source
      IMPORTING
        !iv_program_name  TYPE progname
      RETURNING
        VALUE(rt_sources) TYPE gty_t_program_source .

    METHODS get_function_group
      IMPORTING
        VALUE(iv_fg_name) TYPE rs38l-area
      RETURNING
        VALUE(rt_sources) TYPE gty_t_function_group .

    METHODS get_source_code
      IMPORTING
        !iv_name          TYPE progname
      RETURNING
        VALUE(rt_sources) TYPE string_table .

    METHODS get_function_module
      IMPORTING
        !iv_funcname      TYPE rs38l-name
      RETURNING
        VALUE(rt_sources) TYPE gty_t_program_source .

    METHODS get_class
      IMPORTING
        !iv_class_name         TYPE seoclsname
      RETURNING
        VALUE(rt_class_source) TYPE gty_t_class_source .
  PROTECTED SECTION.
PRIVATE SECTION.
  "Repository / TR Object Types
  CONSTANTS:
    gc_objtype_prog TYPE trobjtype VALUE 'PROG',
    gc_objtype_fugr TYPE trobjtype VALUE 'FUGR',
    gc_objtype_func TYPE trobjtype VALUE 'FUNC'.


  CONSTANTS:
    gc_pat_class_cs    TYPE programm VALUE '*CS',
    gc_pat_class_cp    TYPE programm VALUE '*CP',
    gc_pat_class_ct    TYPE programm VALUE '*CT',
    gc_pat_class_cu    TYPE programm VALUE '*=CU',
    gc_pat_class_co    TYPE programm VALUE '*=CO',
    gc_pat_class_ci    TYPE programm VALUE '*=CI',
    gc_pat_class_ccdef TYPE programm VALUE '*CCDEF',
    gc_pat_class_ccmac TYPE programm VALUE '*CCMAC',
    gc_pat_class_ccimp TYPE programm VALUE '*CCIMP',
    gc_pat_class_ccau  TYPE programm VALUE '*CCAU'.
  "Class Section Labels
  CONSTANTS:
    gc_label_public_section    TYPE string VALUE '(Public Section)',
    gc_label_protected_section TYPE string VALUE '(Protected Section)',
    gc_label_private_section   TYPE string VALUE '(Private Section)'.

  "Function Group Include Patterns
  CONSTANTS:
    gc_pat_fg_top TYPE progname VALUE '*TOP',
    gc_pat_fg_uxx TYPE progname VALUE '*UXX',
    gc_pat_fg_u   TYPE progname VALUE '*U*',
    gc_pat_fg_f   TYPE progname VALUE '*F*'.

  "Function Group Source Types
  CONSTANTS:
    gc_src_type_top  TYPE string VALUE 'TOP',
    gc_src_type_func TYPE string VALUE 'FUNC',
    gc_src_type_form TYPE string VALUE 'FORM',
    gc_src_type_incl TYPE string VALUE 'INCL'.

  "Program Include Patterns
  CONSTANTS:
    gc_pat_class_pool TYPE string VALUE '=='.
ENDCLASS.



CLASS ZCL_PROGRAM_FETCH IMPLEMENTATION.


METHOD get_class.

  DATA: lt_includes   TYPE TABLE OF programm,
        ls_row        TYPE gty_class_source,
        ls_mtdkey     TYPE seocpdkey,
        lv_inc        TYPE programm,
        lv_class_name TYPE seoclsname.

  DATA: ls_clskey     TYPE seoclskey,
        lt_methods    TYPE seoo_methods_r,
        ls_method_md  LIKE LINE OF lt_methods,
        ls_class      TYPE vseoclass.

  CLEAR rt_class_source.

  lv_class_name = iv_class_name.
  TRANSLATE lv_class_name TO UPPER CASE.
  CONDENSE lv_class_name NO-GAPS.

  CLEAR ls_clskey.
  ls_clskey-clsname = lv_class_name.

  TRY.
      CALL FUNCTION 'SEO_CLASS_TYPEINFO_GET'
        EXPORTING
          clskey            = ls_clskey
          version           = '0'
          state             = '1'
          with_descriptions = seox_true
          ignore_switches   = 'X'
        IMPORTING
          class             = ls_class
          methods           = lt_methods
        EXCEPTIONS
          not_existing      = 1
          is_interface      = 2
          model_only        = 3
          OTHERS            = 4.
    CATCH cx_root.
      CLEAR lt_methods.
  ENDTRY.

  SORT lt_methods BY cmpname.

  cl_oo_classname_service=>get_all_class_includes(
    EXPORTING
      class_name = lv_class_name
    RECEIVING
      result     = lt_includes ).

  LOOP AT lt_includes INTO lv_inc.

    IF lv_inc CP gc_pat_class_cs
       OR lv_inc CP gc_pat_class_cp
       OR lv_inc CP gc_pat_class_ct.
      CONTINUE.
    ENDIF.

    CLEAR: ls_row, ls_mtdkey.
    ls_row-include = lv_inc.

    cl_oo_classname_service=>get_method_by_include(
      EXPORTING
        incname = lv_inc
      RECEIVING
        mtdkey  = ls_mtdkey
      EXCEPTIONS
        OTHERS  = 1 ).

    IF sy-subrc = 0 AND ls_mtdkey-cpdname IS NOT INITIAL.

      ls_row-include_kind = 'METHOD'.
      ls_row-method_name  = ls_mtdkey-cpdname.
      TRANSLATE ls_row-method_name TO UPPER CASE.
      CONDENSE ls_row-method_name NO-GAPS.

      READ TABLE lt_methods INTO ls_method_md
        WITH KEY cmpname = ls_mtdkey-cpdname
        BINARY SEARCH.
      IF sy-subrc = 0.

        CASE ls_method_md-exposure.
          WHEN '0'.
            ls_row-section = 'PRIVATE'.
          WHEN '1'.
            ls_row-section = 'PROTECTED'.
          WHEN '2'.
            ls_row-section = 'PUBLIC'.
          WHEN OTHERS.
            CLEAR ls_row-section.
        ENDCASE.

        ls_row-description = ls_method_md-descript.

        CASE ls_method_md-mtddecltyp.
          WHEN '0'.
            ls_row-method_level = 'INSTANCE'.
          WHEN '1'.
            ls_row-method_level = 'STATIC'.
          WHEN OTHERS.
            CLEAR ls_row-method_level.
        ENDCASE.

      ENDIF.

    ELSE.

      ls_row-include_kind = 'SECTION'.

      IF lv_inc CP gc_pat_class_cu.
        ls_row-section      = 'PUBLIC'.
        ls_row-method_name  = gc_label_public_section.
        ls_row-description  = 'Public section declarations'.
        CLEAR ls_row-method_level.

      ELSEIF lv_inc CP gc_pat_class_co.
        ls_row-section      = 'PROTECTED'.
        ls_row-method_name  = gc_label_protected_section.
        ls_row-description  = 'Protected section declarations'.
        CLEAR ls_row-method_level.

      ELSEIF lv_inc CP gc_pat_class_ci.
        ls_row-section      = 'PRIVATE'.
        ls_row-method_name  = gc_label_private_section.
        ls_row-description  = 'Private section declarations'.
        CLEAR ls_row-method_level.

      ELSE.
        CONTINUE.
      ENDIF.

    ENDIF.

    ls_row-source_code = me->get_source_code( iv_name = lv_inc ).

    IF ls_row-source_code IS NOT INITIAL.
      APPEND ls_row TO rt_class_source.
    ENDIF.

  ENDLOOP.

ENDMETHOD.


  METHOD get_function_group.
    CLEAR rt_sources.

    DATA: ls_source TYPE gty_function_group.

    DATA(lv_top_name) = CONV progname( |L{ iv_fg_name }TOP| ).
    DATA(lt_top_src)  = me->get_source_code( lv_top_name ).

    IF lt_top_src IS NOT INITIAL.
      CLEAR ls_source.
      ls_source-include     = lv_top_name.
      ls_source-type        = gc_src_type_top.
      ls_source-source_code = lt_top_src.
      APPEND ls_source TO rt_sources.
    ENDIF.

    DATA: lt_incls TYPE STANDARD TABLE OF progname.
    DATA(lv_like) = |L{ iv_fg_name }%|.

    SELECT name
      FROM trdir
      INTO TABLE @lt_incls
      WHERE name LIKE @lv_like.

    DATA(lv_expected_len) = strlen( iv_fg_name ) + 4.

    LOOP AT lt_incls INTO DATA(lv_incl).

      IF lv_incl CP gc_pat_fg_top
         OR lv_incl CP gc_pat_fg_uxx
         OR strlen( lv_incl ) > lv_expected_len.
        CONTINUE.
      ENDIF.

      DATA(lt_temp) = me->get_source_code( lv_incl ).

      IF lt_temp IS NOT INITIAL.
        CLEAR ls_source.
        ls_source-include = lv_incl.

        IF lv_incl CP gc_pat_fg_u.
          ls_source-type = gc_src_type_func.
        ELSEIF lv_incl CP gc_pat_fg_f.
          ls_source-type = gc_src_type_form.
        ELSE.
          ls_source-type = gc_src_type_incl.
        ENDIF.

        ls_source-source_code = lt_temp.
        APPEND ls_source TO rt_sources.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


METHOD get_function_module.

  DATA: lv_funcname TYPE rs38l-name,
        lv_pname    TYPE progname,
        lv_incno    TYPE tfdir-include,
        lv_include  TYPE progname,
        lt_includes TYPE STANDARD TABLE OF programm WITH EMPTY KEY,
        lv_inc      TYPE programm,
        ls_res      TYPE gty_program_source.

  CLEAR: rt_sources.

  lv_funcname = iv_funcname.
  TRANSLATE lv_funcname TO UPPER CASE.

  "1) Lấy metadata FM từ TFDIR
  SELECT SINGLE pname, include
    INTO (@lv_pname, @lv_incno)
    FROM tfdir
    WHERE funcname = @lv_funcname.

  IF sy-subrc <> 0 OR lv_pname IS INITIAL OR lv_incno IS INITIAL.
    RETURN.
  ENDIF.

  "2) Ghép ra include thật sự của FM
  CALL FUNCTION 'FUNCTION_INCLUDE_CONCATENATE'
    EXPORTING
      include_number           = lv_incno
    IMPORTING
      include                  = lv_include
    CHANGING
      program                  = lv_pname
    EXCEPTIONS
      not_enough_input         = 1
      no_function_pool         = 2
      delimiter_wrong_position = 3
      OTHERS                   = 4.

  IF sy-subrc <> 0 OR lv_include IS INITIAL.
    RETURN.
  ENDIF.

  "3) Main program trước
  CLEAR ls_res.
  ls_res-include     = lv_pname.
  ls_res-source_code = me->get_source_code( iv_name = lv_pname ).
  IF ls_res-source_code IS NOT INITIAL.
    APPEND ls_res TO rt_sources.
  ENDIF.

  "4) Lấy toàn bộ include của function pool
  SELECT include
    FROM d010inc
    INTO TABLE @lt_includes
    WHERE master = @lv_pname.

  DELETE lt_includes WHERE table_line IS INITIAL.
  SORT lt_includes BY table_line.
  DELETE ADJACENT DUPLICATES FROM lt_includes COMPARING table_line.

  "5) Đưa include chứa FM lên đầu danh sách include
  IF lv_include IS NOT INITIAL.
    DELETE lt_includes WHERE table_line = lv_include.
    INSERT lv_include INTO lt_includes INDEX 1.
  ENDIF.

  "6) Đọc source cho từng include
  LOOP AT lt_includes INTO lv_inc.
    CLEAR ls_res.
    ls_res-include     = lv_inc.
    ls_res-source_code = me->get_source_code( iv_name = lv_inc ).

    IF ls_res-source_code IS NOT INITIAL.
      APPEND ls_res TO rt_sources.
    ENDIF.
  ENDLOOP.

ENDMETHOD.


METHOD get_source_code.
  CLEAR rt_sources.

  READ REPORT iv_name INTO rt_sources.

  IF sy-subrc <> 0.
    CLEAR rt_sources.
  ENDIF.
ENDMETHOD.


METHOD get_program_source.
  DATA: lt_includes TYPE STANDARD TABLE OF programm,
        lv_inc      TYPE programm,
        ls_res      TYPE gty_program_source.

  CLEAR rt_sources.

  ls_res-include     = iv_program_name.
  ls_res-source_code = me->get_source_code( iv_program_name ).

  IF ls_res-source_code IS NOT INITIAL.
    APPEND ls_res TO rt_sources.
  ENDIF.

  SELECT include
    FROM d010inc
    INTO TABLE @lt_includes
    WHERE master = @iv_program_name.

  LOOP AT lt_includes INTO lv_inc.
    IF lv_inc CS gc_pat_class_pool.
      CONTINUE.
    ENDIF.

    CLEAR ls_res.
    ls_res-include = lv_inc.

    READ REPORT lv_inc INTO ls_res-source_code.
    IF sy-subrc = 0 AND ls_res-source_code IS NOT INITIAL.
      APPEND ls_res TO rt_sources.
    ENDIF.
  ENDLOOP.
ENDMETHOD.
ENDCLASS.
