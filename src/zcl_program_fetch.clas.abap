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
  CONSTANTS:
    gc_pat_class_cs    TYPE programm VALUE '*CS',
    gc_pat_class_cp    TYPE programm VALUE '*CP',
    gc_pat_class_ct    TYPE programm VALUE '*CT',
    gc_pat_class_cu    TYPE programm VALUE '*=CU',
    gc_pat_class_co    TYPE programm VALUE '*=CO',
    gc_pat_class_ci    TYPE programm VALUE '*=CI'.
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
  "------------------------------------------------------------
  " Class include kind
  "------------------------------------------------------------
  CONSTANTS:
    gc_class_kind_method  TYPE string VALUE 'METHOD',
    gc_class_kind_section TYPE string VALUE 'SECTION'.

  "------------------------------------------------------------
  " Class visibility / exposure values
  "------------------------------------------------------------
  CONSTANTS:
    gc_exposure_private   TYPE c LENGTH 1 VALUE '0',
    gc_exposure_protected TYPE c LENGTH 1 VALUE '1',
    gc_exposure_public    TYPE c LENGTH 1 VALUE '2'.
  "------------------------------------------------------------
  " Class section names
  "------------------------------------------------------------
  CONSTANTS:
    gc_section_private   TYPE string VALUE 'PRIVATE',
    gc_section_protected TYPE string VALUE 'PROTECTED',
    gc_section_public    TYPE string VALUE 'PUBLIC'.

  "------------------------------------------------------------
  " Class method declaration type
  "------------------------------------------------------------
  CONSTANTS:
    gc_mtddecl_instance TYPE seomtddecl VALUE '0',
    gc_mtddecl_static   TYPE seomtddecl VALUE '1'.

  "------------------------------------------------------------
  " Class method level text
  "------------------------------------------------------------
  CONSTANTS:
    gc_method_level_instance TYPE string VALUE 'INSTANCE',
    gc_method_level_static   TYPE string VALUE 'STATIC'.

  "------------------------------------------------------------
  " Class section descriptions
  "------------------------------------------------------------
  CONSTANTS:
    gc_desc_public_section    TYPE string VALUE 'Public section declarations',
    gc_desc_protected_section TYPE string VALUE 'Protected section declarations',
    gc_desc_private_section   TYPE string VALUE 'Private section declarations'.

  "------------------------------------------------------------
  " Function group include technical tokens
  "------------------------------------------------------------
  CONSTANTS:
    gc_fg_prefix_l TYPE c LENGTH 1 VALUE 'L',
    gc_fg_top      TYPE string     VALUE 'TOP',
    gc_like_any    TYPE c LENGTH 1 VALUE '%'.
ENDCLASS.



CLASS ZCL_PROGRAM_FETCH IMPLEMENTATION.


METHOD get_class.

  DATA: lt_includes   TYPE TABLE OF programm,
        ls_row        TYPE gty_class_source,
        ls_mtdkey     TYPE seocpdkey,
        lv_inc        TYPE programm,
        lv_class_name TYPE seoclsname.

  DATA: ls_clskey  TYPE seoclskey,
        lt_methods TYPE seoo_methods_r,
        ls_class   TYPE vseoclass.

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

      ls_row-include_kind = gc_class_kind_method.
      ls_row-method_name  = ls_mtdkey-cpdname.
      TRANSLATE ls_row-method_name TO UPPER CASE.
      CONDENSE ls_row-method_name NO-GAPS.

      READ TABLE lt_methods ASSIGNING FIELD-SYMBOL(<lfs_method_md>)
       WITH KEY cmpname = ls_mtdkey-cpdname
       BINARY SEARCH.

      IF sy-subrc = 0.

        CASE <lfs_method_md>-exposure.
          WHEN gc_exposure_private. "0
            ls_row-section = gc_section_private.
          WHEN gc_exposure_protected. "1
            ls_row-section = gc_section_protected.
          WHEN gc_exposure_public. "2
            ls_row-section = gc_section_public.
          WHEN OTHERS.
            CLEAR ls_row-section.
        ENDCASE.

        ls_row-description = <lfs_method_md>-descript.

        CASE <lfs_method_md>-mtddecltyp.
          WHEN gc_mtddecl_instance.
            ls_row-method_level = gc_method_level_instance.
          WHEN gc_mtddecl_static.
            ls_row-method_level = gc_method_level_static.
          WHEN OTHERS.
            CLEAR ls_row-method_level.
        ENDCASE.

      ENDIF.

    ELSE.

      ls_row-include_kind = gc_class_kind_section.

      IF lv_inc CP gc_pat_class_cu.
        ls_row-section      = gc_section_public.
        ls_row-method_name  = gc_label_public_section.
        ls_row-description  = gc_desc_public_section.
        CLEAR ls_row-method_level.

      ELSEIF lv_inc CP gc_pat_class_co.
        ls_row-section      = gc_section_protected.
        ls_row-method_name  = gc_label_protected_section.
        ls_row-description  = gc_desc_protected_section.
        CLEAR ls_row-method_level.

      ELSEIF lv_inc CP gc_pat_class_ci.
        ls_row-section      = gc_section_private.
        ls_row-method_name  = gc_label_private_section.
        ls_row-description  = gc_desc_private_section.
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

    DATA(lv_top_name) = CONV progname( |{ gc_fg_prefix_l }{ iv_fg_name }{ gc_fg_top }| ).
    DATA(lo_top_src)  = me->get_source_code( lv_top_name ).

    IF lo_top_src IS NOT INITIAL.
      CLEAR ls_source.
      ls_source-include     = lv_top_name.
      ls_source-type        = gc_src_type_top.
      ls_source-source_code = lo_top_src.
      APPEND ls_source TO rt_sources.
    ENDIF.

    DATA: lt_incls TYPE STANDARD TABLE OF progname.
    DATA(lv_like) = CONV progname( |{ gc_fg_prefix_l }{ iv_fg_name }{ gc_like_any }| ).

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

      DATA(lo_temp) = me->get_source_code( lv_incl ).

      IF lo_temp IS NOT INITIAL.
        CLEAR ls_source.
        ls_source-include = lv_incl.

        IF lv_incl CP gc_pat_fg_u.
          ls_source-type = gc_src_type_func.
        ELSEIF lv_incl CP gc_pat_fg_f.
          ls_source-type = gc_src_type_form.
        ELSE.
          ls_source-type = gc_src_type_incl.
        ENDIF.

        ls_source-source_code = lo_temp.
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
