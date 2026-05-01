CLASS zcl_program_report DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS export_program_to_excel
      IMPORTING
        im_prog_name TYPE progname .
    METHODS export_fm_to_excel
      IMPORTING
        im_func_name       TYPE rs38l-name
        im_direct_download TYPE abap_bool OPTIONAL
        im_save_as         TYPE string OPTIONAL.
    METHODS export_fugr_to_excel
      IMPORTING
        im_fugr_name TYPE rs38l-area.
    METHODS export_class_to_excel
      IMPORTING
        im_class_name TYPE seoclsname .
  PRIVATE SECTION.

    "========TABLE TYPES======"
    TYPES: BEGIN OF ty_class_source,
             include      TYPE progname,
             include_kind TYPE char20,   " SECTION / METHOD / OTHER
             section      TYPE char20,   " PUBLIC / PROTECTED / PRIVATE
             method_level TYPE char20,
             description  TYPE seodescr,
             method_name  TYPE seocpdname,
             source_code  TYPE string_table,
           END OF ty_class_source .

    TYPES: tt_class_source TYPE STANDARD TABLE OF ty_class_source WITH EMPTY KEY .

    TYPES: BEGIN OF ty_program_source,
             include     TYPE programm,
             source_code TYPE string_table,
           END OF ty_program_source .

    TYPES: gty_t_program_source TYPE STANDARD TABLE OF ty_program_source WITH EMPTY KEY .
    TYPES: gty_t_de_rollnames TYPE SORTED TABLE OF rollname WITH UNIQUE KEY table_line .
    TYPES: gty_t_seen_prog TYPE SORTED TABLE OF progname WITH UNIQUE KEY table_line .
    TYPES: gty_t_seen_type TYPE SORTED TABLE OF ddobjname WITH UNIQUE KEY table_line .

    TYPES: BEGIN OF ty_comp_meta,
             clsname    TYPE seoclsname,
             cmpname    TYPE seocmpname,
             version    TYPE seoversion,
             state      TYPE seostate,
             exposure   TYPE seoexpose,
             attdecltyp TYPE seoattdecl,
             attrdonly  TYPE seordonly,
             attvalue   TYPE seovalue,
             attdynamic TYPE seodynamic,
             attexpvirt TYPE seoexpose,
             mtddecltyp TYPE seomtddecl,
             mtdabstrct TYPE seoabstrct,
             mtdfinal   TYPE seofinal,
           END OF ty_comp_meta .

    TYPES: BEGIN OF ty_comp_text,
             clsname  TYPE seoclsname,
             cmpname  TYPE seocmpname,
             langu    TYPE sylangu,
             descript TYPE seodescr,
           END OF ty_comp_text .

    TYPES: BEGIN OF ty_subco_meta,
             clsname    TYPE seoclsname,
             cmpname    TYPE seocmpname,
             sconame    TYPE seosconame,
             version    TYPE seoversion,
             pardecltyp TYPE seopardecl,
             parpasstyp TYPE seoparpass,
             typtype    TYPE seotyptype,
             type       TYPE rs38l_typ,
             tableof    TYPE seotableof,
             parvalue   TYPE seovalue,
             paroptionl TYPE seooptionl,
             parpreferd TYPE c LENGTH 1,
           END OF ty_subco_meta .

    TYPES: BEGIN OF ty_subco_text,
             clsname  TYPE seoclsname,
             cmpname  TYPE seocmpname,
             sconame  TYPE seosconame,
             langu    TYPE sylangu,
             descript TYPE seodescr,
           END OF ty_subco_text .

    TYPES: BEGIN OF ty_rel_meta,
             clsname    TYPE seoclsname,
             refclsname TYPE seoclsname,
             version    TYPE seoversion,
             state      TYPE seostate,
             reltype    TYPE seoreltype,
             relname    TYPE seorelname,
             exposure   TYPE seoexpose,
             impfinal   TYPE seofinal,
             impabstrct TYPE seoabstrct,
           END OF ty_rel_meta .

    TYPES: BEGIN OF ty_fg_fm,
             fm_name     TYPE rs38l-name,
             description TYPE tftit-stext,
             download    TYPE icon_d,
           END OF ty_fg_fm .

    TYPES: ty_t_fg_fm TYPE STANDARD TABLE OF ty_fg_fm WITH EMPTY KEY .

    TYPES: BEGIN OF gty_tab_hit,
             tab_name TYPE tabname,
             usa_type TYPE char15,
             acc_type TYPE char20,
             src      TYPE char20,
             use_fld  TYPE string,
             key_fld  TYPE string,
           END OF gty_tab_hit.

    TYPES gty_t_tab_hits TYPE SORTED TABLE OF gty_tab_hit
      WITH UNIQUE KEY tab_name usa_type acc_type src.

    TYPES: BEGIN OF ty_str_hit,
             str_name TYPE tabname,
             usa_type TYPE char20,
             src      TYPE char20,
           END OF ty_str_hit.

    TYPES: gty_t_str_hits TYPE SORTED TABLE OF ty_str_hit WITH UNIQUE KEY str_name usa_type src.

    DATA go_fetch TYPE REF TO zcl_program_fetch .
    DATA go_check TYPE REF TO zcl_program_check .
    DATA mo_whereused TYPE REF TO zcl_program_whereused .
    DATA gt_fg_fm TYPE ty_t_fg_fm .
    CLASS-DATA gv_xlwb_default_file TYPE string .

    "========METHODS======"
    METHODS fill_class_layout_attr
      IMPORTING
        !im_class_name    TYPE seoclsname
        !imt_class_source TYPE tt_class_source
      CHANGING
        !ch_layout        TYPE zst_class_layout .
    METHODS fill_class_layout_classdef
      IMPORTING
        !im_class_name TYPE seoclsname
      CHANGING
        !ch_layout     TYPE zst_class_layout .
    METHODS fill_class_layout_method
      IMPORTING
        !im_class_name    TYPE seoclsname
        !imt_class_source TYPE tt_class_source
      CHANGING
        !ch_layout        TYPE zst_class_layout .
    METHODS fill_class_layout_param
      IMPORTING
        !im_class_name    TYPE seoclsname
        !imt_class_source TYPE tt_class_source
      CHANGING
        !ch_layout        TYPE zst_class_layout .
    METHODS normalize_class_layout
      CHANGING
        !ch_layout TYPE zst_class_layout .
    METHODS ensure_objects .
    METHODS fill_screen_layout
      IMPORTING
        !im_program_name  TYPE progname
      CHANGING
        !ch_screen_layout TYPE zst_screen_layout .
    METHODS fill_overview
      IMPORTING
        !iv_objtype        TYPE trobjtype OPTIONAL
        !iv_objname        TYPE sobj_name OPTIONAL
        !IV_description    TYPE trdirt-text
        !iv_package        TYPE tadir-devclass
        !iv_status         TYPE string
        !iv_created_by     TYPE tadir-author
        !iv_created_on     TYPE reposrc-cdat
        !iv_changed_by     TYPE reposrc-unam
        !iv_changed_on     TYPE reposrc-udat
        !iv_trkorr         TYPE e071-trkorr OPTIONAL
        !iv_version        TYPE string OPTIONAL
        !iv_tcode          TYPE tstc-tcode OPTIONAL
      RETURNING
        VALUE(re_overview) TYPE zcore_st_parameter .
    METHODS call_excel_form
      IMPORTING
        !im_excel           TYPE zst_gsp04_report
        !im_viewer_title    TYPE string OPTIONAL
        !im_direct_download TYPE abap_bool OPTIONAL
        !im_save_as         TYPE string OPTIONAL
        !iv_objtype         TYPE trobjtype OPTIONAL .

    METHODS fill_class_layout
      IMPORTING
        !im_class_name   TYPE seoclsname
      RETURNING
        VALUE(re_layout) TYPE zst_class_layout .
    METHODS fill_data_element
      IMPORTING
        !iv_objtype            TYPE trobjtype
        !iv_objname            TYPE sobj_name
      RETURNING
        VALUE(rt_data_element) TYPE ztt_dataelement .
    METHODS de_build_rows
      IMPORTING
        !it_rollnames         TYPE gty_t_de_rollnames
      RETURNING
        VALUE(rt_dataelement) TYPE ztt_dataelement .
    METHODS collect_from_source
      IMPORTING
        !it_source     TYPE string_table
        !iv_follow_inc TYPE abap_bool OPTIONAL
      CHANGING
        !ct_rollnames  TYPE gty_t_de_rollnames
        !ct_seen_prog  TYPE gty_t_seen_prog
        !ct_seen_type  TYPE gty_t_seen_type .
    METHODS resolve_ddic_type
      IMPORTING
        !iv_name      TYPE string
      CHANGING
        !ct_rollnames TYPE gty_t_de_rollnames
        !ct_seen_type TYPE gty_t_seen_type .
    METHODS collect_from_meta
      IMPORTING
        !iv_objtype   TYPE trobjtype
        !iv_objname   TYPE sobj_name
      CHANGING
        !ct_rollnames TYPE gty_t_de_rollnames
        !ct_seen_type TYPE gty_t_seen_type .
    METHODS fill_table
      IMPORTING
        !iv_objtype     TYPE trobjtype
        !iv_objname     TYPE sobj_name
      RETURNING
        VALUE(rt_table) TYPE ztt_table .
    METHODS collect_table_from_source
      IMPORTING
        !it_source   TYPE string_table
      CHANGING
        !ct_tab_hits TYPE gty_t_tab_hits.

    METHODS build_table_rows
      IMPORTING
        !it_tab_hits    TYPE gty_t_tab_hits
      RETURNING
        VALUE(rt_table) TYPE ztt_table.
    METHODS resolve_table_info
      IMPORTING
        !iv_tabname TYPE tabname
      CHANGING
        !cs_row     TYPE zst_table .
    METHODS is_valid_table_name
      IMPORTING
        iv_tabname   TYPE tabname
      RETURNING
        VALUE(rv_ok) TYPE abap_bool.
    METHODS fill_structure
      IMPORTING
        !iv_objtype         TYPE trobjtype
        !iv_objname         TYPE sobj_name
      RETURNING
        VALUE(rt_structure) TYPE ztt_structure.

    METHODS collect_structure_from_source
      IMPORTING
        !it_source   TYPE string_table
      CHANGING
        !ct_str_hits TYPE gty_t_str_hits.

    METHODS build_structure_rows
      IMPORTING
        !it_str_hits        TYPE gty_t_str_hits
      RETURNING
        VALUE(rt_structure) TYPE ztt_structure.
    METHODS collect_structure_from_meta
      IMPORTING
        !iv_objtype  TYPE trobjtype
        !iv_objname  TYPE sobj_name
      CHANGING
        !ct_str_hits TYPE gty_t_str_hits.

    "==========CONSTANTS=========="
    CONSTANTS:
      BEGIN OF gc_export,
        kw_na             TYPE string    VALUE 'N/A',
        kw_active         TYPE string    VALUE 'Active',
        kw_inactive       TYPE string    VALUE 'Inactive',

        kw_pgmid_r3tr     TYPE pgmid     VALUE 'R3TR',
        kw_r3state_active TYPE r3state   VALUE 'A',

        kw_obj_prog       TYPE trobjtype VALUE 'PROG',
        kw_obj_clas       TYPE trobjtype VALUE 'CLAS',
        kw_obj_fugr       TYPE trobjtype VALUE 'FUGR',
        kw_obj_func       TYPE trobjtype VALUE 'FUNC',
      END OF gc_export,

      BEGIN OF gc_abap_token,
        select        TYPE string VALUE 'SELECT',
        select_single TYPE string VALUE 'SELECT SINGLE',
        insert        TYPE string VALUE 'INSERT',
        update        TYPE string VALUE 'UPDATE',
        modify        TYPE string VALUE 'MODIFY',
        delete        TYPE string VALUE 'DELETE',
        join          TYPE string VALUE 'JOIN',
        from          TYPE string VALUE 'FROM',
        where         TYPE string VALUE 'WHERE',
        into          TYPE string VALUE 'INTO',
        as            TYPE string VALUE 'AS',
        type          TYPE string VALUE 'TYPE',
        like          TYPE string VALUE 'LIKE',
        references    TYPE string VALUE 'REFERENCES',
        single        TYPE string VALUE 'SINGLE',
        inner         TYPE string VALUE 'INNER',
        left          TYPE string VALUE 'LEFT',
        right         TYPE string VALUE 'RIGHT',
        on            TYPE string VALUE 'ON',
        distinct      TYPE string VALUE 'DISTINCT',
        appending     TYPE string VALUE 'APPENDING',
        up            TYPE string VALUE 'UP',
        package       TYPE string VALUE 'PACKAGE',
        bypassing     TYPE string VALUE 'BYPASSING',
        connection    TYPE string VALUE 'CONNECTION',
        and           TYPE string VALUE 'AND',
        or            TYPE string VALUE 'OR',
        not           TYPE string VALUE 'NOT',
        in            TYPE string VALUE 'IN',
        between       TYPE string VALUE 'BETWEEN',
      END OF gc_abap_token,

      BEGIN OF gc_de_token,
        tables   TYPE string VALUE 'TABLES',
        ref      TYPE string VALUE 'REF',
        standard TYPE string VALUE 'STANDARD',
        sorted   TYPE string VALUE 'SORTED',
        hashed   TYPE string VALUE 'HASHED',
        table    TYPE string VALUE 'TABLE',
        of       TYPE string VALUE 'OF',
        line     TYPE string VALUE 'LINE',
        for      TYPE string VALUE 'FOR',
      END OF gc_de_token,

      BEGIN OF gc_symbol,
        pattern_literal TYPE string VALUE '''*''',
        pattern_var     TYPE string VALUE '@*',
        lparen          TYPE string VALUE '(',
        rparen          TYPE string VALUE ')',
        dot             TYPE string VALUE '.',
        comma           TYPE string VALUE ',',
        colon           TYPE string VALUE ':',
        bang            TYPE string VALUE '!',
        dash            TYPE string VALUE '-',
        star            TYPE string VALUE '*',
        tilde           TYPE string VALUE '~',
        c_equal         TYPE string VALUE ' = ',
      END OF gc_symbol,

      BEGIN OF gc_de_skip,
        type_i       TYPE string VALUE 'I',
        type_c       TYPE string VALUE 'C',
        type_n       TYPE string VALUE 'N',
        type_p       TYPE string VALUE 'P',
        type_f       TYPE string VALUE 'F',
        type_string  TYPE string VALUE 'STRING',
        type_xstring TYPE string VALUE 'XSTRING',
        type_d       TYPE string VALUE 'D',
        type_t       TYPE string VALUE 'T',
        type_any     TYPE string VALUE 'ANY',
        type_object  TYPE string VALUE 'OBJECT',
        pat_ty       TYPE string VALUE 'TY_*',
        pat_lt       TYPE string VALUE 'LT_*',
        pat_ls       TYPE string VALUE 'LS_*',
        pat_lv       TYPE string VALUE 'LV_*',
        pat_gt       TYPE string VALUE 'GT_*',
        pat_gs       TYPE string VALUE 'GS_*',
        pat_lo       TYPE string VALUE 'LO_*',
      END OF gc_de_skip,

      BEGIN OF gc_table_usage,
        read  TYPE char15 VALUE 'READ',
        write TYPE char15 VALUE 'WRITE',
      END OF gc_table_usage,

      BEGIN OF gc_table_access,
        select        TYPE char20 VALUE 'SELECT',
        select_single TYPE char20 VALUE 'SELECT SINGLE',
        join          TYPE char20 VALUE 'JOIN',
        insert        TYPE char20 VALUE 'INSERT',
        update        TYPE char20 VALUE 'UPDATE',
        modify        TYPE char20 VALUE 'MODIFY',
        delete        TYPE char20 VALUE 'DELETE',
      END OF gc_table_access,

      BEGIN OF gc_table_source,
        select   TYPE char20 VALUE 'SELECT',
        db_write TYPE char20 VALUE 'DB WRITE',
      END OF gc_table_source,

      BEGIN OF gc_sql_func,
        count TYPE string VALUE 'COUNT',
        sum   TYPE string VALUE 'SUM',
        avg   TYPE string VALUE 'AVG',
        min   TYPE string VALUE 'MIN',
        max   TYPE string VALUE 'MAX',
      END OF gc_sql_func,

      BEGIN OF gc_ddic,
        as4local_active TYPE dd02l-as4local VALUE 'A',
        as4vers_active  TYPE dd02l-as4vers  VALUE '0000',
        tabclass_transp TYPE dd02l-tabclass VALUE 'TRANSP',
        tabclass_view   TYPE dd02l-tabclass VALUE 'VIEW',
        tabclass_inttab TYPE dd02l-tabclass VALUE 'INTTAB',
        tabclass_append TYPE dd02l-tabclass VALUE 'APPEND',
        tabclass_struct TYPE dd02l-tabclass VALUE 'STRUCT',
        field_mandt     TYPE fieldname      VALUE 'MANDT',
      END OF gc_ddic,

      BEGIN OF gc_ddic_text,
        transparent_table TYPE string VALUE 'Transparent Table',
        view              TYPE string VALUE 'View',
        internal_table    TYPE string VALUE 'Internal Table',
        append_structure  TYPE string VALUE 'Append Structure',
        structure         TYPE string VALUE 'Structure',
      END OF gc_ddic_text,

      BEGIN OF gc_label,
        public_section    TYPE string VALUE 'PUBLIC SECTION',
        private_section   TYPE string VALUE 'PRIVATE SECTION',
        protected_section TYPE string VALUE 'PROTECTED SECTION',
      END OF gc_label.
ENDCLASS.



CLASS ZCL_PROGRAM_REPORT IMPLEMENTATION.


  METHOD build_table_rows.

    TYPES: BEGIN OF lty_tabname,
             tabname TYPE tabname,
           END OF lty_tabname.

    TYPES: BEGIN OF lty_dd02l,
             tabname  TYPE tabname,
             tabclass TYPE dd02l-tabclass,
             contflag TYPE dd02l-contflag,
           END OF lty_dd02l.

    TYPES: BEGIN OF lty_dd02t,
             tabname TYPE tabname,
             ddtext  TYPE dd02t-ddtext,
           END OF lty_dd02t.

    TYPES: BEGIN OF lty_mandt,
             tabname TYPE tabname,
           END OF lty_mandt.

    DATA: ls_hit      TYPE gty_tab_hit,
          ls_row      TYPE zst_table,
          lv_no       TYPE i,
          ls_tabname  TYPE lty_tabname,
          lt_tabnames TYPE SORTED TABLE OF lty_tabname WITH UNIQUE KEY tabname,
          lt_dd02l    TYPE STANDARD TABLE OF lty_dd02l WITH EMPTY KEY,
          ls_dd02l    TYPE lty_dd02l,
          lt_dd02t    TYPE STANDARD TABLE OF lty_dd02t WITH EMPTY KEY,
          ls_dd02t    TYPE lty_dd02t,
          lt_mandt    TYPE STANDARD TABLE OF lty_mandt WITH EMPTY KEY,
          ls_mandt    TYPE lty_mandt.

    CLEAR: rt_table, lv_no, lt_tabnames.

    LOOP AT it_tab_hits INTO ls_hit.
      IF ls_hit-tab_name IS NOT INITIAL.
        ls_tabname-tabname = ls_hit-tab_name.
        INSERT ls_tabname INTO TABLE lt_tabnames.
      ENDIF.
    ENDLOOP.

    IF lt_tabnames IS INITIAL.
      RETURN.
    ENDIF.

    SELECT tabname,
           tabclass,
           contflag
      FROM dd02l
      INTO TABLE @lt_dd02l
      FOR ALL ENTRIES IN @lt_tabnames
      WHERE tabname  = @lt_tabnames-tabname
        AND as4local = @gc_ddic-as4local_active
        AND as4vers  = @gc_ddic-as4vers_active.

    SELECT tabname,
           ddtext
      FROM dd02t
      INTO TABLE @lt_dd02t
      FOR ALL ENTRIES IN @lt_tabnames
      WHERE tabname    = @lt_tabnames-tabname
        AND ddlanguage = @sy-langu
        AND as4local   = @gc_ddic-as4local_active
        AND as4vers    = @gc_ddic-as4vers_active.

    SELECT tabname
      FROM dd03l
      INTO TABLE @lt_mandt
      FOR ALL ENTRIES IN @lt_tabnames
      WHERE tabname   = @lt_tabnames-tabname
        AND fieldname = @gc_ddic-field_mandt
        AND as4local  = @gc_ddic-as4local_active
        AND as4vers   = @gc_ddic-as4vers_active.

    SORT lt_dd02l BY tabname.
    SORT lt_dd02t BY tabname.
    SORT lt_mandt BY tabname.

    LOOP AT it_tab_hits INTO ls_hit.

      CLEAR: ls_row, ls_dd02l, ls_dd02t, ls_mandt.

      READ TABLE lt_dd02l INTO ls_dd02l
        WITH KEY tabname = ls_hit-tab_name
        BINARY SEARCH.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_no = lv_no + 1.

      READ TABLE lt_dd02t INTO ls_dd02t
        WITH KEY tabname = ls_hit-tab_name
        BINARY SEARCH.

      READ TABLE lt_mandt INTO ls_mandt
        WITH KEY tabname = ls_hit-tab_name
        BINARY SEARCH.

      ls_row-tab_no      = lv_no.
      ls_row-tab_name    = ls_hit-tab_name.
      ls_row-tab_des     = ls_dd02t-ddtext.
      ls_row-tab_del_cls = ls_dd02l-contflag.
      ls_row-tab_usa_typ = ls_hit-usa_type.
      ls_row-tab_acc_typ = ls_hit-acc_type.
      ls_row-tab_src     = ls_hit-src.
      ls_row-tab_use_fld = ls_hit-use_fld.
      ls_row-tab_key_fld = ls_hit-key_fld.

      CASE ls_dd02l-tabclass.
        WHEN gc_ddic-tabclass_transp.
          ls_row-tab_type = gc_ddic_text-transparent_table.
        WHEN gc_ddic-tabclass_view.
          ls_row-tab_type = gc_ddic_text-view.
        WHEN gc_ddic-tabclass_inttab.
          ls_row-tab_type = gc_ddic_text-internal_table.
        WHEN gc_ddic-tabclass_append.
          ls_row-tab_type = gc_ddic_text-append_structure.
        WHEN gc_ddic-tabclass_struct.
          ls_row-tab_type = gc_ddic_text-structure.
        WHEN OTHERS.
          ls_row-tab_type = ls_dd02l-tabclass.
      ENDCASE.

      IF ls_mandt-tabname IS NOT INITIAL.
        ls_row-tab_cli_dep = abap_true.
      ENDIF.

      ls_row-tab_name    = COND #( WHEN ls_row-tab_name    IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_name ).
      ls_row-tab_type    = COND #( WHEN ls_row-tab_type    IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_type ).
      ls_row-tab_des     = COND #( WHEN ls_row-tab_des     IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_des ).
      ls_row-tab_usa_typ = COND #( WHEN ls_row-tab_usa_typ IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_usa_typ ).
      ls_row-tab_acc_typ = COND #( WHEN ls_row-tab_acc_typ IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_acc_typ ).
      ls_row-tab_use_fld = COND #( WHEN ls_row-tab_use_fld IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_use_fld ).
      ls_row-tab_key_fld = COND #( WHEN ls_row-tab_key_fld IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_key_fld ).
      ls_row-tab_cli_dep = COND #( WHEN ls_row-tab_cli_dep IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_cli_dep ).
      ls_row-tab_del_cls = COND #( WHEN ls_row-tab_del_cls IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_del_cls ).
      ls_row-tab_src     = COND #( WHEN ls_row-tab_src     IS INITIAL THEN gc_export-kw_na ELSE ls_row-tab_src ).

      APPEND ls_row TO rt_table.

    ENDLOOP.

  ENDMETHOD.


  METHOD call_excel_form.

    DATA: lv_formname     TYPE char255 VALUE 'ZGSP04_REPORT',
          lv_viewer_title TYPE string,
          lv_save_as      TYPE string.

    lv_viewer_title = im_viewer_title.
    CONDENSE lv_viewer_title NO-GAPS.

    IF lv_viewer_title IS INITIAL.
      lv_viewer_title = lv_formname.
    ENDIF.

    lv_save_as = im_save_as.
    IF lv_save_as IS INITIAL.
      lv_save_as = |{ lv_viewer_title }.xlsx|.
    ENDIF.

    EXPORT lv_save_as = lv_save_as TO MEMORY ID 'ZGSP04_XLSX_NAME'.

    IF im_direct_download = abap_true.

      CALL FUNCTION 'ZXLWB_CALLFORM'
        EXPORTING
          iv_formname        = lv_formname
          iv_context_ref     = im_excel
          iv_viewer_suppress = 'X'
          iv_save_as         = lv_save_as
        EXCEPTIONS
          process_terminated = 1
          OTHERS             = 2.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      RETURN.
    ENDIF.

    CALL FUNCTION 'ZXLWB_CALLFORM'
      EXPORTING
        iv_formname             = lv_formname
        iv_context_ref          = im_excel
        iv_viewer_title         = lv_viewer_title
        iv_viewer_inplace       = 'X'
        iv_viewer_callback_prog = 'Z_ANALYZE_TOOL'
        iv_viewer_callback_form = 'XLWB_VIEWER_CALLBACK'
      EXCEPTIONS
        process_terminated      = 1
        OTHERS                  = 2.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.


  METHOD collect_from_meta.

    DATA: lt_params TYPE STANDARD TABLE OF fupararef WITH EMPTY KEY,
          ls_param  TYPE fupararef,
          lt_subco  TYPE STANDARD TABLE OF seosubcodf WITH EMPTY KEY,
          ls_subco  TYPE seosubcodf.

    CASE iv_objtype.

      WHEN gc_export-kw_obj_func.

        CLEAR lt_params.

        SELECT parameter,
               paramtype,
               structure,
               type
          FROM fupararef
          INTO CORRESPONDING FIELDS OF TABLE @lt_params
          WHERE funcname = @iv_objname.

        LOOP AT lt_params INTO ls_param.

          IF ls_param-structure IS NOT INITIAL.
            me->resolve_ddic_type(
              EXPORTING
                iv_name      = CONV string( ls_param-structure )
              CHANGING
                ct_rollnames = ct_rollnames
                ct_seen_type = ct_seen_type ).
          ENDIF.

        ENDLOOP.

      WHEN gc_export-kw_obj_clas.

        CLEAR lt_subco.

        SELECT clsname,
               cmpname,
               sconame,
               version,
               type,
               tableof
          FROM seosubcodf
          INTO CORRESPONDING FIELDS OF TABLE @lt_subco
          WHERE clsname = @iv_objname
            AND version = '1'.

        LOOP AT lt_subco INTO ls_subco.

          IF ls_subco-type IS NOT INITIAL.
            me->resolve_ddic_type(
              EXPORTING
                iv_name      = CONV string( ls_subco-type )
              CHANGING
                ct_rollnames = ct_rollnames
                ct_seen_type = ct_seen_type ).
          ENDIF.

        ENDLOOP.

      WHEN OTHERS.
        RETURN.

    ENDCASE.

  ENDMETHOD.


  METHOD collect_from_source.

    DATA: lv_line         TYPE string,
          lv_stmt         TYPE string,
          lv_work         TYPE string,
          lt_tokens       TYPE STANDARD TABLE OF string WITH EMPTY KEY,
          lv_token        TYPE string,
          lv_next         TYPE string,
          lv_next2        TYPE string,
          lv_next3        TYPE string,
          lv_next4        TYPE string,
          lv_target       TYPE string,
          lv_idx          TYPE sy-tabix,
          lv_tabname      TYPE dd03l-tabname,
          lv_fieldname    TYPE dd03l-fieldname,
          lv_name         TYPE string,
          lv_include_name TYPE progname,
          lv_sel_field    TYPE string,
          lv_sel_tab      TYPE string,
          lv_from_idx     TYPE sy-tabix,
          lv_star_tab     TYPE string,
          lv_from_idx2    TYPE sy-tabix,
          lt_inc_source   TYPE string_table.

    CLEAR lv_stmt.

    LOOP AT it_source INTO lv_line.

      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.

      " INCLUDE include
      IF iv_follow_inc = abap_true.
        DATA(lv_inc_uc) = lv_line.
        TRANSLATE lv_inc_uc TO UPPER CASE.
        CONDENSE lv_inc_uc.

        CLEAR lv_include_name.
        FIND PCRE '^\s*INCLUDE\s+([A-Z0-9_]+)\.' IN lv_inc_uc
          SUBMATCHES lv_include_name.

        IF sy-subrc = 0 AND lv_include_name IS NOT INITIAL.

          READ TABLE ct_seen_prog WITH TABLE KEY table_line = lv_include_name
            TRANSPORTING NO FIELDS.

          IF sy-subrc <> 0.

            INSERT lv_include_name INTO TABLE ct_seen_prog.

            CLEAR lt_inc_source.
            lt_inc_source = me->go_fetch->get_source_code(
              iv_name = lv_include_name ).

            IF lt_inc_source IS NOT INITIAL.
              me->collect_from_source(
                EXPORTING
                  it_source     = lt_inc_source
                  iv_follow_inc = abap_true
                CHANGING
                  ct_rollnames  = ct_rollnames
                  ct_seen_prog  = ct_seen_prog
                  ct_seen_type  = ct_seen_type ).
            ENDIF.

          ENDIF.
        ENDIF.
      ENDIF.

      IF lv_stmt IS INITIAL.
        lv_stmt = lv_line.
      ELSE.
        CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
      ENDIF.

      IF lv_line NS gc_symbol-dot.
        CONTINUE.
      ENDIF.

      lv_work = lv_stmt.
      TRANSLATE lv_work TO UPPER CASE.

      REPLACE ALL OCCURRENCES OF '(' IN lv_work WITH ' ( '.
      REPLACE ALL OCCURRENCES OF ')' IN lv_work WITH ' ) '.
      REPLACE ALL OCCURRENCES OF gc_symbol-comma IN lv_work WITH ' , '.
      REPLACE ALL OCCURRENCES OF gc_symbol-dot   IN lv_work WITH ' . '.
      REPLACE ALL OCCURRENCES OF gc_symbol-colon IN lv_work WITH ' : '.
      REPLACE ALL OCCURRENCES OF gc_symbol-c_equal         IN lv_work WITH ' = '.
      REPLACE ALL OCCURRENCES OF gc_symbol-bang  IN lv_work WITH ' !'.
      CONDENSE lv_work.

      CLEAR lt_tokens.
      SPLIT lv_work AT space INTO TABLE lt_tokens.

      lv_idx = 1.
      WHILE lv_idx <= lines( lt_tokens ).

        READ TABLE lt_tokens INTO lv_token INDEX lv_idx.

        CLEAR: lv_next, lv_next2, lv_next3, lv_next4,
               lv_target, lv_tabname, lv_fieldname.

        READ TABLE lt_tokens INTO lv_next  INDEX lv_idx + 1.
        READ TABLE lt_tokens INTO lv_next2 INDEX lv_idx + 2.
        READ TABLE lt_tokens INTO lv_next3 INDEX lv_idx + 3.
        READ TABLE lt_tokens INTO lv_next4 INDEX lv_idx + 4.

        " TABLES mara / TABLES: sscrfields, ...
        IF lv_token = gc_de_token-tables.

          lv_from_idx = lv_idx + 1.

          WHILE lv_from_idx <= lines( lt_tokens ).

            READ TABLE lt_tokens INTO lv_name INDEX lv_from_idx.

            IF sy-subrc <> 0 OR lv_name = gc_symbol-dot.
              EXIT.
            ENDIF.

            IF lv_name <> gc_symbol-colon
               AND lv_name <> gc_symbol-comma.

              me->resolve_ddic_type(
                EXPORTING
                  iv_name      = lv_name
                CHANGING
                  ct_rollnames = ct_rollnames
                  ct_seen_type = ct_seen_type ).

            ENDIF.

            lv_from_idx = lv_from_idx + 1.

          ENDWHILE.

        ENDIF.

        " TYPE ...
        IF lv_token = gc_abap_token-type.

          IF lv_next <> gc_de_token-ref.

            IF ( lv_next = gc_de_token-standard
              OR lv_next = gc_de_token-sorted
              OR lv_next = gc_de_token-hashed )
              AND lv_next2 = gc_de_token-table
              AND lv_next3 = gc_de_token-of.

              lv_target = lv_next4.

            ELSEIF lv_next = gc_de_token-table
               AND lv_next2 = gc_de_token-of.

              lv_target = lv_next3.

            ELSEIF lv_next = gc_de_token-line
               AND lv_next2 = gc_de_token-of.

              lv_target = lv_next3.

            ELSE.

              lv_target = lv_next.

            ENDIF.

            IF lv_target IS NOT INITIAL.
              me->resolve_ddic_type(
                EXPORTING
                  iv_name      = lv_target
                CHANGING
                  ct_rollnames = ct_rollnames
                  ct_seen_type = ct_seen_type ).
            ENDIF.

          ENDIF.

        ENDIF.

        " LIKE ...
        IF lv_token = gc_abap_token-like.

          IF lv_next = gc_de_token-line
             AND lv_next2 = gc_de_token-of.

            lv_target = lv_next3.

          ELSEIF lv_next <> gc_de_token-ref.

            lv_target = lv_next.

          ENDIF.

          IF lv_target IS NOT INITIAL.
            me->resolve_ddic_type(
              EXPORTING
                iv_name      = lv_target
              CHANGING
                ct_rollnames = ct_rollnames
                ct_seen_type = ct_seen_type ).
          ENDIF.

        ENDIF.

        " SELECT-OPTIONS ... FOR mara-matnr
        IF lv_token = gc_de_token-for AND lv_next IS NOT INITIAL.

          me->resolve_ddic_type(
            EXPORTING
              iv_name      = lv_next
            CHANGING
              ct_rollnames = ct_rollnames
              ct_seen_type = ct_seen_type ).

        ENDIF.

        " SELECT SINGLE field FROM tab
        IF lv_token = gc_abap_token-select
           OR lv_token = gc_abap_token-single.

          CLEAR: lv_sel_field, lv_sel_tab, lv_from_idx.

          IF lv_token = gc_abap_token-select.
            IF lv_next = gc_abap_token-single.
              lv_sel_field = lv_next2.
            ELSE.
              lv_sel_field = lv_next.
            ENDIF.
          ELSEIF lv_token = gc_abap_token-single.
            lv_sel_field = lv_next.
          ENDIF.

          lv_from_idx = lv_idx.
          WHILE lv_from_idx <= lines( lt_tokens ).

            READ TABLE lt_tokens INTO lv_name INDEX lv_from_idx.

            IF lv_name = gc_abap_token-from.
              EXIT.
            ENDIF.

            lv_from_idx = lv_from_idx + 1.

          ENDWHILE.

          IF lv_from_idx > 0.
            READ TABLE lt_tokens INTO lv_sel_tab INDEX lv_from_idx + 1.
          ENDIF.

          IF lv_sel_field IS NOT INITIAL
             AND lv_sel_tab   IS NOT INITIAL
             AND lv_sel_field <> gc_symbol-star
             AND lv_sel_field <> gc_abap_token-distinct
             AND lv_sel_tab   <> gc_symbol-dot.

            IF lv_sel_field CS gc_symbol-tilde.
              SPLIT lv_sel_field AT gc_symbol-tilde INTO lv_name lv_sel_field.
            ENDIF.

            IF lv_sel_tab CS gc_symbol-tilde.
              SPLIT lv_sel_tab AT gc_symbol-tilde INTO lv_sel_tab lv_name.
            ENDIF.

            CONCATENATE lv_sel_tab lv_sel_field INTO lv_name
              SEPARATED BY gc_symbol-dash.

            me->resolve_ddic_type(
              EXPORTING
                iv_name      = lv_name
              CHANGING
                ct_rollnames = ct_rollnames
                ct_seen_type = ct_seen_type ).

          ENDIF.

        ENDIF.

        " SELECT * FROM tab
        IF lv_token = gc_abap_token-select
           OR lv_token = gc_abap_token-single.

          CLEAR: lv_star_tab, lv_from_idx2.

          IF ( lv_token = gc_abap_token-select
               AND lv_next = gc_symbol-star )
             OR ( lv_token = gc_abap_token-select
                  AND lv_next = gc_abap_token-single
                  AND lv_next2 = gc_symbol-star )
             OR ( lv_token = gc_abap_token-single
                  AND lv_next = gc_symbol-star ).

            lv_from_idx2 = lv_idx.
            WHILE lv_from_idx2 <= lines( lt_tokens ).

              READ TABLE lt_tokens INTO lv_name INDEX lv_from_idx2.

              IF lv_name = gc_abap_token-from.
                EXIT.
              ENDIF.

              lv_from_idx2 = lv_from_idx2 + 1.

            ENDWHILE.

            IF lv_from_idx2 > 0.
              READ TABLE lt_tokens INTO lv_star_tab INDEX lv_from_idx2 + 1.
            ENDIF.

            IF lv_star_tab IS NOT INITIAL
               AND lv_star_tab <> gc_symbol-dot.

              IF lv_star_tab CS gc_symbol-tilde.
                SPLIT lv_star_tab AT gc_symbol-tilde INTO lv_name lv_star_tab.
              ENDIF.

              me->resolve_ddic_type(
                EXPORTING
                  iv_name      = lv_star_tab
                CHANGING
                  ct_rollnames = ct_rollnames
                  ct_seen_type = ct_seen_type ).

            ENDIF.

          ENDIF.

        ENDIF.

        lv_idx = lv_idx + 1.

      ENDWHILE.

      CLEAR lv_stmt.

    ENDLOOP.

  ENDMETHOD.


  METHOD collect_table_from_source.

    TYPES: BEGIN OF lty_alias_map,
             alias    TYPE string,
             tab_name TYPE tabname,
           END OF lty_alias_map.

    TYPES: BEGIN OF lty_field_map,
             tab_name TYPE tabname,
             field    TYPE fieldname,
           END OF lty_field_map.

    TYPES: BEGIN OF lty_stmt_tab,
             tab_name TYPE tabname,
           END OF lty_stmt_tab.

    DATA: lv_line          TYPE string,
          lv_stmt          TYPE string,
          lv_stmt_uc       TYPE string,
          lv_work          TYPE string,
          lv_cmt_pos       TYPE i,
          lt_tokens        TYPE STANDARD TABLE OF string WITH EMPTY KEY,
          lv_token         TYPE string,
          lv_next          TYPE string,
          lv_next2         TYPE string,
          lv_next3         TYPE string,
          lv_prev          TYPE string,
          lv_idx           TYPE sy-tabix,
          lv_from_idx      TYPE sy-tabix,
          lv_select_from   TYPE sy-tabix,
          lv_select_to     TYPE sy-tabix,
          lv_main_tab      TYPE tabname,
          lv_tabname       TYPE tabname,
          lv_join_tab      TYPE tabname,
          lv_alias         TYPE string,
          lv_field         TYPE fieldname,
          lv_candidate     TYPE string,
          ls_alias         TYPE lty_alias_map,
          lt_alias         TYPE STANDARD TABLE OF lty_alias_map WITH EMPTY KEY,
          ls_used          TYPE lty_field_map,
          lt_used          TYPE SORTED TABLE OF lty_field_map WITH UNIQUE KEY tab_name field,
          ls_key           TYPE lty_field_map,
          lt_key           TYPE SORTED TABLE OF lty_field_map WITH UNIQUE KEY tab_name field,
          ls_hit           TYPE gty_tab_hit,
          lv_access        TYPE char20,
          lv_has_join      TYPE abap_bool,
          ls_stmt_tab      TYPE lty_stmt_tab,
          lt_all_stmt_tabs TYPE SORTED TABLE OF lty_stmt_tab WITH UNIQUE KEY tab_name,
          lt_all_ddic_keys TYPE STANDARD TABLE OF lty_field_map WITH EMPTY KEY,
          lt_all_stmt_keys TYPE SORTED TABLE OF lty_field_map WITH UNIQUE KEY tab_name field,
          lv_idx2          TYPE sy-tabix,
          lv_idx3          TYPE sy-tabix.

    FIELD-SYMBOLS: <lfs_hit> TYPE gty_tab_hit.

    CLEAR: lv_stmt,
           lt_all_stmt_keys.

    "========================================================
    " PRE-SCAN
    "========================================================
    LOOP AT it_source INTO lv_line.

      CONDENSE lv_line.

      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.

      IF lv_line(1) = gc_symbol-star.
        CONTINUE.
      ENDIF.

      FIND FIRST OCCURRENCE OF '"' IN lv_line MATCH OFFSET lv_cmt_pos.
      IF sy-subrc = 0.
        lv_line = lv_line(lv_cmt_pos).
        CONDENSE lv_line.
        IF lv_line IS INITIAL.
          CONTINUE.
        ENDIF.
      ENDIF.

      IF lv_stmt IS INITIAL.
        lv_stmt = lv_line.
      ELSE.
        CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
      ENDIF.

      IF lv_line NS gc_symbol-dot.
        CONTINUE.
      ENDIF.

      lv_stmt_uc = lv_stmt.
      TRANSLATE lv_stmt_uc TO UPPER CASE.
      CONDENSE lv_stmt_uc.

      lv_work = lv_stmt_uc.
      REPLACE ALL OCCURRENCES OF '(' IN lv_work WITH ' ( '.
      REPLACE ALL OCCURRENCES OF ')' IN lv_work WITH ' ) '.
      REPLACE ALL OCCURRENCES OF ',' IN lv_work WITH ' , '.
      REPLACE ALL OCCURRENCES OF '.' IN lv_work WITH ' . '.
      REPLACE ALL OCCURRENCES OF '=' IN lv_work WITH ' = '.
      CONDENSE lv_work.

      CLEAR lt_tokens.
      SPLIT lv_work AT space INTO TABLE lt_tokens.

      lv_idx = 1.
      WHILE lv_idx <= lines( lt_tokens ).

        READ TABLE lt_tokens INTO lv_token INDEX lv_idx.
        IF sy-subrc <> 0.
          lv_idx = lv_idx + 1.
          CONTINUE.
        ENDIF.

        " Đọc các token tiếp theo và lưu vào các biến tạm
        IF lv_idx + 1 <= lines( lt_tokens ).
          lv_next = lt_tokens[ lv_idx + 1 ].
        ENDIF.

        IF lv_idx + 2 <= lines( lt_tokens ).
          lv_next2 = lt_tokens[ lv_idx + 2 ].
        ENDIF.

        IF lv_idx + 3 <= lines( lt_tokens ).
          lv_next3 = lt_tokens[ lv_idx + 3 ].
        ENDIF.

        lv_idx = lv_idx + 1.
      ENDWHILE.

      IF lv_token = gc_abap_token-from.

        lv_tabname = lv_next.
        REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_tabname WITH ''.
        CONDENSE lv_tabname NO-GAPS.
        TRANSLATE lv_tabname TO UPPER CASE.

        IF me->is_valid_table_name( lv_tabname ) = abap_true.
          CLEAR ls_stmt_tab.
          ls_stmt_tab-tab_name = lv_tabname.
          INSERT ls_stmt_tab INTO TABLE lt_all_stmt_tabs.
        ENDIF.

      ENDIF.

      IF lv_token = gc_abap_token-join.

        lv_join_tab = lv_next.
        REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_join_tab WITH ''.
        CONDENSE lv_join_tab NO-GAPS.
        TRANSLATE lv_join_tab TO UPPER CASE.

        IF me->is_valid_table_name( lv_join_tab ) = abap_true.
          CLEAR ls_stmt_tab.
          ls_stmt_tab-tab_name = lv_join_tab.
          INSERT ls_stmt_tab INTO TABLE lt_all_stmt_tabs.
        ENDIF.

      ENDIF.

    ENDLOOP.

    CLEAR lv_stmt.


    IF lt_all_stmt_tabs IS NOT INITIAL.

      SELECT tabname AS tab_name,
             fieldname AS field
        FROM dd03l
        INTO CORRESPONDING FIELDS OF TABLE @lt_all_ddic_keys
        FOR ALL ENTRIES IN @lt_all_stmt_tabs
        WHERE tabname  = @lt_all_stmt_tabs-tab_name
          AND keyflag  = 'X'
          AND as4local = @gc_ddic-as4local_active
          AND as4vers  = @gc_ddic-as4vers_active.

      LOOP AT lt_all_ddic_keys INTO ls_key.
        INSERT ls_key INTO TABLE lt_all_stmt_keys.
      ENDLOOP.

    ENDIF.

    CLEAR lv_stmt.

    LOOP AT it_source INTO lv_line.

      "========================================================
      " 0. Clean line
      "========================================================
      CONDENSE lv_line.

      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.

      " ABAP full-line comment
      IF lv_line(1) = gc_symbol-star.
        CONTINUE.
      ENDIF.

      " Inline comment
      FIND FIRST OCCURRENCE OF '"' IN lv_line MATCH OFFSET lv_cmt_pos.
      IF sy-subrc = 0.
        lv_line = lv_line(lv_cmt_pos).
        CONDENSE lv_line.
        IF lv_line IS INITIAL.
          CONTINUE.
        ENDIF.
      ENDIF.

      "========================================================
      " 1.Statement .
      "========================================================
      IF lv_stmt IS INITIAL.
        lv_stmt = lv_line.
      ELSE.
        CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
      ENDIF.

      IF lv_line NS '.'.
        CONTINUE.
      ENDIF.

      lv_stmt_uc = lv_stmt.
      TRANSLATE lv_stmt_uc TO UPPER CASE.
      CONDENSE lv_stmt_uc.

      lv_work = lv_stmt_uc.
      REPLACE ALL OCCURRENCES OF '(' IN lv_work WITH ' ( '.
      REPLACE ALL OCCURRENCES OF ')' IN lv_work WITH ' ) '.
      REPLACE ALL OCCURRENCES OF ',' IN lv_work WITH ' , '.
      REPLACE ALL OCCURRENCES OF '.' IN lv_work WITH ' . '.
      REPLACE ALL OCCURRENCES OF '=' IN lv_work WITH ' = '.
      CONDENSE lv_work.

      CLEAR lt_tokens.
      SPLIT lv_work AT space INTO TABLE lt_tokens.

      CLEAR: lt_alias, lt_used, lt_key, lv_main_tab, lv_has_join,
             lv_from_idx, lv_access.

      "========================================================
      " 2. Build alias map: FROM / JOIN
      "========================================================
      lv_idx = 1.
      WHILE lv_idx <= lines( lt_tokens ).

        READ TABLE lt_tokens INTO lv_token INDEX lv_idx.
        IF sy-subrc <> 0.
          lv_idx = lv_idx + 1.
          CONTINUE.
        ENDIF.

        CLEAR: lv_next, lv_next2, lv_next3.
        IF lv_idx + 1 <= lines( lt_tokens ).
          lv_next = lt_tokens[ lv_idx + 1 ].
        ENDIF.

        IF lv_idx + 2 <= lines( lt_tokens ).
          lv_next2 = lt_tokens[ lv_idx + 2 ].
        ENDIF.

        IF lv_idx + 3 <= lines( lt_tokens ).
          lv_next3 = lt_tokens[ lv_idx + 3 ].
        ENDIF.

        " FROM <table> [AS alias] , FROM <table> alias
        IF lv_token = gc_abap_token-from.

          lv_from_idx = lv_idx.
          lv_tabname = lv_next.
          REPLACE ALL OCCURRENCES OF '.' IN lv_tabname WITH ''.
          CONDENSE lv_tabname NO-GAPS.
          TRANSLATE lv_tabname TO UPPER CASE.

          IF me->is_valid_table_name( lv_tabname ) = abap_true.

            lv_main_tab = lv_tabname.

            CLEAR ls_alias.
            ls_alias-alias    = lv_tabname.
            ls_alias-tab_name = lv_tabname.
            APPEND ls_alias TO lt_alias.

            CLEAR lv_alias.
            IF lv_next2 = gc_abap_token-as AND lv_next3 IS NOT INITIAL.
              lv_alias = lv_next3.
            ELSEIF lv_next2 IS NOT INITIAL
       AND lv_next2 <> gc_abap_token-inner
       AND lv_next2 <> gc_abap_token-left
       AND lv_next2 <> gc_abap_token-right
       AND lv_next2 <> gc_abap_token-join
       AND lv_next2 <> gc_abap_token-where
       AND lv_next2 <> gc_abap_token-into
       AND lv_next2 <> gc_abap_token-on
       AND lv_next2 <> '.'.
              lv_alias = lv_next2.
            ENDIF.

            IF lv_alias IS NOT INITIAL.
              TRANSLATE lv_alias TO UPPER CASE.
              CONDENSE lv_alias NO-GAPS.

              CLEAR ls_alias.
              ls_alias-alias    = lv_alias.
              ls_alias-tab_name = lv_tabname.
              APPEND ls_alias TO lt_alias.
            ENDIF.

          ENDIF.
        ENDIF.

        " JOIN <table> [AS alias] , JOIN <table> alias
        IF lv_token = gc_abap_token-join.

          lv_has_join = abap_true.

          lv_join_tab = lv_next.
          REPLACE ALL OCCURRENCES OF '.' IN lv_join_tab WITH ''.
          CONDENSE lv_join_tab NO-GAPS.
          TRANSLATE lv_join_tab TO UPPER CASE.

          IF me->is_valid_table_name( lv_join_tab ) = abap_true.

            CLEAR ls_alias.
            ls_alias-alias    = lv_join_tab.
            ls_alias-tab_name = lv_join_tab.
            APPEND ls_alias TO lt_alias.

            CLEAR lv_alias.
            IF lv_next2 = gc_abap_token-as AND lv_next3 IS NOT INITIAL.
              lv_alias = lv_next3.
            ELSEIF lv_next2 IS NOT INITIAL
       AND lv_next2 <> gc_abap_token-on
       AND lv_next2 <> gc_abap_token-inner
       AND lv_next2 <> gc_abap_token-left
       AND lv_next2 <> gc_abap_token-right
       AND lv_next2 <> gc_abap_token-join
       AND lv_next2 <> gc_abap_token-where
       AND lv_next2 <> '.'.
              lv_alias = lv_next2.
            ENDIF.

            IF lv_alias IS NOT INITIAL.
              TRANSLATE lv_alias TO UPPER CASE.
              CONDENSE lv_alias NO-GAPS.

              CLEAR ls_alias.
              ls_alias-alias    = lv_alias.
              ls_alias-tab_name = lv_join_tab.
              APPEND ls_alias TO lt_alias.
            ENDIF.

          ENDIF.
        ENDIF.

        lv_idx = lv_idx + 1.
      ENDWHILE.

      "========================================================
      " 3. SELECT / SELECT SINGLE / JOIN
      "========================================================
      IF lv_stmt_uc CS gc_abap_token-select AND lv_main_tab IS NOT INITIAL.

        IF lv_stmt_uc CS gc_abap_token-select_single.
          lv_access = gc_table_access-select_single.
        ELSE.
          lv_access = gc_table_access-select.
        ENDIF.

        "------------------------------------------------------
        " 3.1 Used Fields: field list FROM
        "------------------------------------------------------
        CLEAR: lv_select_from, lv_select_to.

        READ TABLE lt_tokens INTO lv_token INDEX 1.
        IF lv_token = gc_abap_token-select.
          READ TABLE lt_tokens INTO lv_next INDEX 2.
          IF lv_next = gc_abap_token-single.
            lv_select_from = 3.
          ELSE.
            lv_select_from = 2.
          ENDIF.
        ENDIF.

        lv_select_to = lv_from_idx - 1.

        IF lv_select_from > 0 AND lv_select_to >= lv_select_from.

          " Tối ưu hóa vòng lặp DO bằng cách sử dụng một vòng lặp duy nhất
          lv_idx = lv_select_from.
          WHILE lv_idx <= lv_select_to.

            READ TABLE lt_tokens INTO lv_token INDEX lv_idx.
            IF sy-subrc <> 0.
              lv_idx = lv_idx + 1.
              CONTINUE.
            ENDIF.

            IF lv_token IS INITIAL
               OR lv_token = ','
               OR lv_token = '.'
               OR lv_token = '('
               OR lv_token = ')'
               OR lv_token = gc_abap_token-distinct
               OR lv_token = gc_abap_token-single
               OR lv_token = gc_abap_token-into
               OR lv_token = gc_abap_token-appending
               OR lv_token = gc_abap_token-up
               OR lv_token = gc_abap_token-package
               OR lv_token = gc_abap_token-bypassing
               OR lv_token = gc_abap_token-connection.
              lv_idx = lv_idx + 1.
              CONTINUE.
            ENDIF.

            " Xử lý với các token còn lại
            CLEAR: lv_alias, lv_field, lv_tabname.
            IF lv_token = '*'.
              lv_field = '*'.
              lv_tabname = lv_main_tab.
            ELSEIF lv_token CS '~'.
              SPLIT lv_token AT '~' INTO lv_alias lv_field.
              TRANSLATE lv_alias TO UPPER CASE.
              CONDENSE lv_alias NO-GAPS.

              SORT lt_alias BY alias.
              READ TABLE lt_alias INTO ls_alias WITH KEY alias = lv_alias BINARY SEARCH.
              IF sy-subrc <> 0.
                CONTINUE.
              ENDIF.

              lv_tabname = ls_alias-tab_name.
            ELSE.
              lv_field = lv_token.
              lv_tabname = lv_main_tab.
            ENDIF.

            REPLACE ALL OCCURRENCES OF ',' IN lv_field WITH ''.
            REPLACE ALL OCCURRENCES OF '.' IN lv_field WITH ''.
            CONDENSE lv_field NO-GAPS.
            TRANSLATE lv_field TO UPPER CASE.

            IF lv_field IS INITIAL.
              lv_idx = lv_idx + 1.
              CONTINUE.
            ENDIF.

            IF lv_field CP '''*'''
               OR lv_field CP '@*'
               OR lv_field = '('
               OR lv_field = ')'
               OR lv_field = '='
               OR lv_field = gc_sql_func-count
               OR lv_field = gc_sql_func-sum
               OR lv_field = gc_sql_func-avg
               OR lv_field = gc_sql_func-min
               OR lv_field = gc_sql_func-max.
              lv_idx = lv_idx + 1.
              CONTINUE.
            ENDIF.

            CLEAR ls_used.
            ls_used-tab_name = lv_tabname.
            ls_used-field    = lv_field.
            INSERT ls_used INTO TABLE lt_used.

            lv_idx = lv_idx + 1.
          ENDWHILE.
        ENDIF.

        "------------------------------------------------------
        " 3.2 Key Fields Used
        "------------------------------------------------------
        lv_idx = 1.
        WHILE lv_idx <= lines( lt_tokens ).

          READ TABLE lt_tokens INTO lv_token INDEX lv_idx.
          IF sy-subrc <> 0.
            lv_idx = lv_idx + 1.
            CONTINUE.
          ENDIF.

          IF lv_token = gc_symbol-c_equal.

            CLEAR: lv_prev, lv_next.
            READ TABLE lt_tokens INTO lv_prev INDEX lv_idx - 1.
            READ TABLE lt_tokens INTO lv_next INDEX lv_idx + 1.

            CLEAR lv_candidate.
            lv_candidate = lv_prev.

            WHILE lv_candidate IS NOT INITIAL.

              CLEAR: lv_alias, lv_field, lv_tabname.

              IF lv_candidate CS gc_symbol-tilde.
                SPLIT lv_candidate AT gc_symbol-tilde INTO lv_alias lv_field.
                TRANSLATE lv_alias TO UPPER CASE.
                CONDENSE lv_alias NO-GAPS.

                SORT lt_alias BY alias.
                READ TABLE lt_alias INTO ls_alias WITH KEY alias = lv_alias BINARY SEARCH.
                IF sy-subrc <> 0.
                  CLEAR lv_candidate.
                  CONTINUE.
                ENDIF.

                lv_tabname = ls_alias-tab_name.
              ELSE.
                lv_tabname = lv_main_tab.
                lv_field   = lv_candidate.
              ENDIF.

              REPLACE ALL OCCURRENCES OF '(' IN lv_field WITH ''.
              REPLACE ALL OCCURRENCES OF ')' IN lv_field WITH ''.
              REPLACE ALL OCCURRENCES OF gc_symbol-comma IN lv_field WITH ''.
              REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_field WITH ''.
              CONDENSE lv_field NO-GAPS.
              TRANSLATE lv_field TO UPPER CASE.

              IF lv_field IS NOT INITIAL
                 AND lv_field <> gc_abap_token-and
                 AND lv_field <> gc_abap_token-or
                 AND lv_field <> gc_abap_token-not
                 AND lv_field <> gc_abap_token-in
                 AND lv_field <> gc_abap_token-like
                 AND lv_field <> gc_abap_token-between.

                READ TABLE lt_all_stmt_keys TRANSPORTING NO FIELDS
                  WITH TABLE KEY tab_name = lv_tabname
                                 field    = lv_field.

                IF sy-subrc = 0.
                  CLEAR ls_key.
                  ls_key-tab_name = lv_tabname.
                  ls_key-field    = lv_field.
                  INSERT ls_key INTO TABLE lt_key.
                ENDIF.

              ENDIF.

              IF lv_candidate = lv_prev.
                lv_candidate = lv_next.
              ELSE.
                CLEAR lv_candidate.
              ENDIF.

            ENDWHILE.

          ENDIF.

          lv_idx = lv_idx + 1.

        ENDWHILE.

        "------------------------------------------------------
        " 3.3 Main SELECT row
        "------------------------------------------------------
        CLEAR ls_hit.
        ls_hit-tab_name = lv_main_tab.
        ls_hit-usa_type = gc_table_usage-read.
        ls_hit-acc_type = lv_access.
        ls_hit-src      = gc_table_source-select.

        lv_idx = 1.
        WHILE lv_idx <= lines( lt_used ).
          READ TABLE lt_used INTO ls_used INDEX lv_idx.
          IF sy-subrc = 0 AND ls_used-tab_name = lv_main_tab.
            IF ls_hit-use_fld IS INITIAL.
              ls_hit-use_fld = ls_used-field.
            ELSE.
              CONCATENATE ls_hit-use_fld ls_used-field
                INTO ls_hit-use_fld SEPARATED BY ', '.
            ENDIF.
          ENDIF.
          lv_idx = lv_idx + 1.
        ENDWHILE.

        lv_idx = 1.
        WHILE lv_idx <= lines( lt_key ).
          READ TABLE lt_key INTO ls_key INDEX lv_idx.
          IF sy-subrc = 0 AND ls_key-tab_name = lv_main_tab.
            IF ls_hit-key_fld IS INITIAL.
              ls_hit-key_fld = ls_key-field.
            ELSE.
              CONCATENATE ls_hit-key_fld ls_key-field
                INTO ls_hit-key_fld SEPARATED BY ', '.
            ENDIF.
          ENDIF.
          lv_idx = lv_idx + 1.
        ENDWHILE.

        IF me->is_valid_table_name( ls_hit-tab_name ) = abap_true.
          INSERT ls_hit INTO TABLE ct_tab_hits.
        ENDIF.

        "------------------------------------------------------
        " 3.4 JOIN rows
        "------------------------------------------------------
        lv_idx = 1.
        WHILE lv_idx <= lines( lt_alias ).

          READ TABLE lt_alias INTO ls_alias INDEX lv_idx.
          IF sy-subrc = 0 AND ls_alias-tab_name <> lv_main_tab.

            CLEAR ls_hit.
            ls_hit-tab_name = ls_alias-tab_name.
            ls_hit-usa_type = gc_table_usage-read.
            ls_hit-acc_type = gc_table_access-join.
            ls_hit-src      = gc_table_source-select.

            lv_idx2 = 1.
            WHILE lv_idx2 <= lines( lt_used ).
              READ TABLE lt_used INTO ls_used INDEX lv_idx2.
              IF sy-subrc = 0 AND ls_used-tab_name = ls_alias-tab_name.
                IF ls_hit-use_fld IS INITIAL.
                  ls_hit-use_fld = ls_used-field.
                ELSE.
                  CONCATENATE ls_hit-use_fld ls_used-field
                    INTO ls_hit-use_fld SEPARATED BY ', '.
                ENDIF.
              ENDIF.
              lv_idx2 = lv_idx2 + 1.
            ENDWHILE.

            lv_idx3 = 1.
            WHILE lv_idx3 <= lines( lt_key ).
              READ TABLE lt_key INTO ls_key INDEX lv_idx3.
              IF sy-subrc = 0 AND ls_key-tab_name = ls_alias-tab_name.
                IF ls_hit-key_fld IS INITIAL.
                  ls_hit-key_fld = ls_key-field.
                ELSE.
                  CONCATENATE ls_hit-key_fld ls_key-field
                    INTO ls_hit-key_fld SEPARATED BY ', '.
                ENDIF.
              ENDIF.
              lv_idx3 = lv_idx3 + 1.
            ENDWHILE.

            IF me->is_valid_table_name( ls_hit-tab_name ) = abap_true.
              INSERT ls_hit INTO TABLE ct_tab_hits.
            ENDIF.

          ENDIF.

          lv_idx = lv_idx + 1.

        ENDWHILE.
      ENDIF.
      "========================================================
      " 4. INSERT
      "========================================================
      CLEAR lv_tabname.

      FIND PCRE 'INSERT\s+INTO\s+([A-Z0-9_/]+)'
        IN lv_stmt_uc
        SUBMATCHES lv_tabname.

      IF sy-subrc <> 0 OR lv_tabname IS INITIAL.
        FIND PCRE 'INSERT\s+([A-Z0-9_/]+)\s+FROM'
          IN lv_stmt_uc
          SUBMATCHES lv_tabname.
      ENDIF.

      IF sy-subrc = 0 AND lv_tabname IS NOT INITIAL.

        TRANSLATE lv_tabname TO UPPER CASE.
        CONDENSE lv_tabname NO-GAPS.

        CLEAR ls_hit.
        ls_hit-tab_name = lv_tabname.
        ls_hit-usa_type = gc_table_usage-write.
        ls_hit-acc_type = gc_table_access-insert.
        ls_hit-src      = gc_table_source-db_write.

        IF me->is_valid_table_name( ls_hit-tab_name ) = abap_true.
          INSERT ls_hit INTO TABLE ct_tab_hits.
        ENDIF.

      ENDIF.

      "========================================================
      " 5. UPDATE
      "========================================================
      CLEAR lv_tabname.

      FIND PCRE 'UPDATE\s+([A-Z0-9_/]+)'
        IN lv_stmt_uc
        SUBMATCHES lv_tabname.

      IF sy-subrc = 0 AND lv_tabname IS NOT INITIAL.

        TRANSLATE lv_tabname TO UPPER CASE.
        CONDENSE lv_tabname NO-GAPS.

        CLEAR ls_hit.
        ls_hit-tab_name = lv_tabname.
        ls_hit-usa_type = gc_table_usage-write.
        ls_hit-acc_type = gc_table_access-update.
        ls_hit-src      = gc_table_source-db_write.

        IF me->is_valid_table_name( ls_hit-tab_name ) = abap_true.
          INSERT ls_hit INTO TABLE ct_tab_hits.
        ENDIF.

      ENDIF.

      "========================================================
      " 6. MODIFY
      "========================================================
      CLEAR lv_tabname.

      FIND PCRE 'MODIFY\s+([A-Z0-9_/]+)'
        IN lv_stmt_uc
        SUBMATCHES lv_tabname.

      IF sy-subrc = 0 AND lv_tabname IS NOT INITIAL.

        TRANSLATE lv_tabname TO UPPER CASE.
        CONDENSE lv_tabname NO-GAPS.

        CLEAR ls_hit.
        ls_hit-tab_name = lv_tabname.
        ls_hit-usa_type = gc_table_usage-write.
        ls_hit-acc_type = gc_table_access-modify.
        ls_hit-src      = gc_table_source-db_write.

        IF me->is_valid_table_name( ls_hit-tab_name ) = abap_true.
          INSERT ls_hit INTO TABLE ct_tab_hits.
        ENDIF.

      ENDIF.

      "========================================================
      " 7. DELETE
      "========================================================
      CLEAR lv_tabname.

      FIND PCRE 'DELETE\s+FROM\s+([A-Z0-9_/]+)'
        IN lv_stmt_uc
        SUBMATCHES lv_tabname.

      IF sy-subrc = 0 AND lv_tabname IS NOT INITIAL.

        TRANSLATE lv_tabname TO UPPER CASE.
        CONDENSE lv_tabname NO-GAPS.

        CLEAR ls_hit.
        ls_hit-tab_name = lv_tabname.
        ls_hit-usa_type = gc_table_usage-write.
        ls_hit-acc_type = gc_table_access-delete.
        ls_hit-src      = gc_table_source-db_write.

        IF me->is_valid_table_name( ls_hit-tab_name ) = abap_true.
          INSERT ls_hit INTO TABLE ct_tab_hits.
        ENDIF.

      ENDIF.

      CLEAR lv_stmt.

    ENDLOOP.

  ENDMETHOD.


  METHOD de_build_rows.

    TYPES: BEGIN OF lty_dd04l,
             rollname TYPE dd04l-rollname,
             datatype TYPE dd04l-datatype,
             leng     TYPE dd04l-leng,
             decimals TYPE dd04l-decimals,
             domname  TYPE dd04l-domname,
           END OF lty_dd04l.

    TYPES: BEGIN OF lty_dd04t,
             rollname  TYPE dd04t-rollname,
             ddtext    TYPE dd04t-ddtext,
             scrtext_s TYPE dd04t-scrtext_s,
             scrtext_m TYPE dd04t-scrtext_m,
             scrtext_l TYPE dd04t-scrtext_l,
           END OF lty_dd04t.

    TYPES: BEGIN OF lty_domain,
             domname TYPE dd04l-domname,
           END OF lty_domain.

    TYPES: BEGIN OF lty_dd01l,
             domname   TYPE dd01l-domname,
             entitytab TYPE dd01l-entitytab,
           END OF lty_dd01l.

    DATA: lt_rollnames TYPE gty_t_de_rollnames,
          lt_dd04l     TYPE STANDARD TABLE OF lty_dd04l WITH EMPTY KEY,
          ls_dd04l     TYPE lty_dd04l,
          lt_dd04t     TYPE STANDARD TABLE OF lty_dd04t WITH EMPTY KEY,
          ls_dd04t     TYPE lty_dd04t,
          lt_domains   TYPE SORTED TABLE OF lty_domain WITH UNIQUE KEY domname,
          ls_domain    TYPE lty_domain,
          lt_dd01l     TYPE STANDARD TABLE OF lty_dd01l WITH EMPTY KEY,
          ls_dd01l     TYPE lty_dd01l,
          ls_row       TYPE zst_dataelement,
          lv_no        TYPE i.

    CLEAR: rt_dataelement,
           lv_no,
           lt_rollnames,
           lt_dd04l,
           lt_dd04t,
           lt_domains,
           lt_dd01l.

    lt_rollnames = it_rollnames.

    DELETE lt_rollnames WHERE table_line IS INITIAL.

    IF lt_rollnames IS INITIAL.
      RETURN.
    ENDIF.

    "1. Lấy metadata Data Element - không SELECT *
    SELECT rollname,
           datatype,
           leng,
           decimals,
           domname
      FROM dd04l
      INTO TABLE @lt_dd04l
      FOR ALL ENTRIES IN @lt_rollnames
      WHERE rollname = @lt_rollnames-table_line
        AND as4local = @gc_ddic-as4local_active
        AND as4vers  = @gc_ddic-as4vers_active.

    IF lt_dd04l IS INITIAL.
      RETURN.
    ENDIF.

    "2. Lấy text Data Element
    SELECT rollname,
           ddtext,
           scrtext_s,
           scrtext_m,
           scrtext_l
      FROM dd04t
      INTO TABLE @lt_dd04t
      FOR ALL ENTRIES IN @lt_rollnames
      WHERE rollname   = @lt_rollnames-table_line
        AND ddlanguage = @sy-langu
        AND as4local   = @gc_ddic-as4local_active
        AND as4vers    = @gc_ddic-as4vers_active.

    "3. DOMAIN
    LOOP AT lt_dd04l INTO ls_dd04l.
      IF ls_dd04l-domname IS NOT INITIAL.
        CLEAR ls_domain.
        ls_domain-domname = ls_dd04l-domname.
        INSERT ls_domain INTO TABLE lt_domains.
      ENDIF.
    ENDLOOP.

    IF lt_domains IS NOT INITIAL.

      SELECT domname,
             entitytab
        FROM dd01l
        INTO TABLE @lt_dd01l
        FOR ALL ENTRIES IN @lt_domains
        WHERE domname  = @lt_domains-domname
          AND as4local = @gc_ddic-as4local_active
          AND as4vers  = @gc_ddic-as4vers_active.

    ENDIF.

    SORT lt_dd04l BY rollname.
    SORT lt_dd04t BY rollname.
    SORT lt_dd01l BY domname.

    LOOP AT lt_dd04l INTO ls_dd04l.

      CLEAR: ls_row, ls_dd04t, ls_dd01l.

      lv_no = lv_no + 1.

      READ TABLE lt_dd04t INTO ls_dd04t
        WITH KEY rollname = ls_dd04l-rollname
        BINARY SEARCH.

      READ TABLE lt_dd01l INTO ls_dd01l
        WITH KEY domname = ls_dd04l-domname
        BINARY SEARCH.

      ls_row-de_no       = lv_no.
      ls_row-de_name     = ls_dd04l-rollname.
      ls_row-de_type     = ls_dd04l-datatype.
      ls_row-de_des      = ls_dd04t-ddtext.
      ls_row-de_length   = ls_dd04l-leng.
      ls_row-de_decimals = ls_dd04l-decimals.
      ls_row-de_domain   = ls_dd04l-domname.
      ls_row-de_valtab   = ls_dd01l-entitytab.
      ls_row-de_short    = ls_dd04t-scrtext_s.
      ls_row-de_medium   = ls_dd04t-scrtext_m.
      ls_row-de_long     = ls_dd04t-scrtext_l.

      IF ls_row-de_des IS INITIAL.
        ls_row-de_des = ls_row-de_name.
      ENDIF.

      ls_row-de_name     = COND #( WHEN ls_row-de_name     IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_name ).
      ls_row-de_type     = COND #( WHEN ls_row-de_type     IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_type ).
      ls_row-de_des      = COND #( WHEN ls_row-de_des      IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_des ).
      ls_row-de_length   = COND #( WHEN ls_row-de_length   IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_length ).
      ls_row-de_decimals = COND #( WHEN ls_row-de_decimals IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_decimals ).
      ls_row-de_domain   = COND #( WHEN ls_row-de_domain   IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_domain ).
      ls_row-de_valtab   = COND #( WHEN ls_row-de_valtab   IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_valtab ).
      ls_row-de_short    = COND #( WHEN ls_row-de_short    IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_short ).
      ls_row-de_medium   = COND #( WHEN ls_row-de_medium   IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_medium ).
      ls_row-de_long     = COND #( WHEN ls_row-de_long     IS INITIAL THEN gc_export-kw_na ELSE ls_row-de_long ).

      APPEND ls_row TO rt_dataelement.

    ENDLOOP.

  ENDMETHOD.


  METHOD ensure_objects.
    IF go_fetch IS INITIAL.
      CREATE OBJECT go_fetch.
    ENDIF.
    IF go_check IS INITIAL.
      CREATE OBJECT go_check.
    ENDIF.
    IF mo_whereused IS INITIAL.
      CREATE OBJECT mo_whereused.
    ENDIF.
  ENDMETHOD.


  METHOD export_class_to_excel.

    DATA: lv_class_name    TYPE seoclsname,
          lv_class_objname TYPE sobj_name,
          lv_class_prog    TYPE progname,
          ls_overview      TYPE zcore_st_parameter,
          gs_excel         TYPE zst_gsp04_report,
          lv_desc          TYPE trdirt-text,
          lv_package       TYPE tadir-devclass,
          lv_status        TYPE string,
          lv_created_user  TYPE tadir-author,
          lv_created_date  TYPE reposrc-cdat,
          lv_last_user     TYPE reposrc-unam,
          lv_last_date     TYPE reposrc-udat,
          lv_tcode         TYPE tstc-tcode,
          lv_trkorr        TYPE e071-trkorr,
          lv_viewer_title  TYPE string.

    lv_class_name    = im_class_name.
    lv_class_objname = im_class_name.

    TRANSLATE lv_class_name TO UPPER CASE.
    CONDENSE lv_class_name NO-GAPS.

    TRANSLATE lv_class_objname TO UPPER CASE.
    CONDENSE lv_class_objname NO-GAPS.

    CLEAR lv_desc.
    SELECT SINGLE descript
      INTO @lv_desc
      FROM seoclasstx
      WHERE clsname = @lv_class_name
        AND langu   = @sy-langu.

    IF sy-subrc <> 0 OR lv_desc IS INITIAL.
      lv_desc = lv_class_name.
    ENDIF.

    CLEAR: lv_package, lv_created_user.
    SELECT SINGLE devclass, author
      INTO (@lv_package, @lv_created_user)
      FROM tadir
      WHERE pgmid    = @gc_export-kw_pgmid_r3tr
        AND object   = @gc_export-kw_obj_clas
        AND obj_name = @lv_class_name.

    IF sy-subrc <> 0 OR lv_package IS INITIAL.
      lv_package = gc_export-kw_na.
    ENDIF.

    SELECT SINGLE clsname
      INTO @DATA(lv_exists)
      FROM seoclass
      WHERE clsname = @lv_class_name.

    IF sy-subrc = 0.
      lv_status = gc_export-kw_active.
    ELSE.
      lv_status = gc_export-kw_inactive.
    ENDIF.

    CLEAR: lv_created_date, lv_last_user, lv_last_date, lv_class_prog.

    TRY.
        lv_class_prog = cl_oo_classname_service=>get_classpool_name( lv_class_name ).
      CATCH cx_root.
        CLEAR lv_class_prog.
    ENDTRY.

    IF lv_class_prog IS NOT INITIAL.
      SELECT SINGLE cdat, unam, udat
        INTO (@lv_created_date, @lv_last_user, @lv_last_date)
        FROM reposrc
        WHERE progname = @lv_class_prog
          AND r3state  = @gc_export-kw_r3state_active.
    ENDIF.

    CLEAR lv_trkorr.
    SELECT SINGLE trkorr
      INTO @lv_trkorr
      FROM e071
      WHERE pgmid    = @gc_export-kw_pgmid_r3tr
        AND object   = @gc_export-kw_obj_clas
        AND obj_name = @lv_class_name.

    ls_overview = me->fill_overview(
        iv_objtype     = gc_export-kw_obj_clas
        iv_objname     = lv_class_objname
        IV_description = lv_desc
        iv_package     = lv_package
        iv_status      = lv_status
        iv_created_by  = lv_created_user
        iv_created_on  = lv_created_date
        iv_changed_by  = lv_last_user
        iv_changed_on  = lv_last_date
        iv_trkorr      = lv_trkorr
        iv_tcode       = lv_tcode
        iv_version     = gc_export-kw_na ).

    gs_excel-overview = ls_overview.

    gs_excel-class_layout = me->fill_class_layout(
      im_class_name = lv_class_name ).

    gs_excel-data_element-item = me->fill_data_element(
      iv_objtype = gc_export-kw_obj_clas
      iv_objname = lv_class_objname
    ).
    gs_excel-table-tab_item = me->fill_table(
      iv_objtype = gc_export-kw_obj_clas
      iv_objname = lv_class_objname
    ).
    gs_excel-structure-struc_item = me->fill_structure(
      iv_objtype = gc_export-kw_obj_clas
      iv_objname = lv_class_objname
    ).

    lv_viewer_title = |CLASS_{ lv_class_name }|.

    CLEAR:
    gs_excel-show_overview,
    gs_excel-show_screen_layout,
    gs_excel-show_data_element,
    gs_excel-show_table,
    gs_excel-show_structure,
    gs_excel-show_fm_layout,
    gs_excel-show_class_layout.

    gs_excel-show_overview      = abap_true.
    gs_excel-show_screen_layout = abap_false.
    gs_excel-show_data_element  = abap_true.
    gs_excel-show_table         = abap_true.
    gs_excel-show_structure     = abap_true.
    gs_excel-show_fm_layout     = abap_false.
    gs_excel-show_class_layout  = abap_true.

    me->call_excel_form(
      im_excel        = gs_excel
      im_viewer_title = lv_viewer_title
      im_save_as      = |CLASS_{ lv_class_name }.xlsx| ).

  ENDMETHOD.


  METHOD export_fm_to_excel.

    DATA: lv_func_name    TYPE rs38l_fnam,
          lv_func_objname TYPE sobj_name,
          lv_progname     TYPE progname,
          lv_area         TYPE rs38l-area,
          ls_overview     TYPE zcore_st_parameter,
          gs_excel        TYPE zst_gsp04_report,
          lv_desc         TYPE trdirt-text,
          lv_package      TYPE tadir-devclass,
          lv_status       TYPE string,
          lv_created_user TYPE tadir-author,
          lv_created_date TYPE reposrc-cdat,
          lv_last_user    TYPE reposrc-unam,
          lv_last_date    TYPE reposrc-udat,
          lv_trkorr       TYPE e071-trkorr,
          lv_tcode        TYPE tstc-tcode.

    DATA: lt_params       TYPE STANDARD TABLE OF fupararef,
          ls_param        TYPE fupararef,
          ls_fm_row       TYPE zcore_st_parameter,
          lv_no_import    TYPE i,
          lv_no_export    TYPE i,
          lv_no_changing  TYPE i,
          lv_no_tables    TYPE i,
          lv_no_exception TYPE i,
          lv_desc_param   TYPE string,
          lv_param_kind   TYPE c LENGTH 1,
          lv_viewer_title TYPE string.

    lv_func_name = im_func_name.
    TRANSLATE lv_func_name TO UPPER CASE.
    CONDENSE lv_func_name NO-GAPS.

    lv_func_objname = lv_func_name.

    CLEAR: ls_overview,
           gs_excel,
           lv_progname,
           lv_area,
           lv_desc,
           lv_package,
           lv_status,
           lv_created_user,
           lv_created_date,
           lv_last_user,
           lv_last_date,
           lv_trkorr,
           lv_tcode,
           lv_no_import,
           lv_no_export,
           lv_no_changing,
           lv_no_tables,
           lv_no_exception,
           lv_desc_param,
           lv_param_kind.

    " Read function module technical info
    SELECT SINGLE pname_main
      INTO @lv_progname
      FROM tfdir
      WHERE funcname = @lv_func_name.

    IF sy-subrc <> 0 OR lv_progname IS INITIAL.
      SELECT SINGLE pname
        INTO @lv_progname
        FROM tfdir
        WHERE funcname = @lv_func_name.
    ENDIF.

    IF lv_progname CP 'SAPL*'.
      lv_area = lv_progname+4.
    ENDIF.

    " Description
    SELECT SINGLE stext
      INTO @lv_desc
      FROM tftit
      WHERE spras    = @sy-langu
        AND funcname = @lv_func_name.

    IF sy-subrc <> 0 OR lv_desc IS INITIAL.
      lv_desc = lv_func_name.
    ENDIF.

    " Status
    IF lv_progname IS NOT INITIAL.
      lv_status = gc_export-kw_active.
    ELSE.
      lv_status = gc_export-kw_inactive.
    ENDIF.

    " Package + Created By
    IF lv_area IS NOT INITIAL.
      SELECT SINGLE devclass, author
        INTO (@lv_package, @lv_created_user)
        FROM tadir
        WHERE pgmid    = @gc_export-kw_pgmid_r3tr
          AND object   = @gc_export-kw_obj_fugr
          AND obj_name = @lv_area.
    ENDIF.

    IF sy-subrc <> 0 OR lv_package IS INITIAL.
      lv_package = gc_export-kw_na.
    ENDIF.

    " Created On / Changed By / Changed On
    IF lv_progname IS NOT INITIAL.
      SELECT SINGLE cdat, unam, udat
        INTO (@lv_created_date, @lv_last_user, @lv_last_date)
        FROM reposrc
        WHERE progname = @lv_progname
          AND r3state  = @gc_export-kw_r3state_active.
    ENDIF.

    " Transport Request
    SELECT SINGLE trkorr
      INTO @lv_trkorr
      FROM e071
      WHERE pgmid    = @gc_export-kw_pgmid_r3tr
        AND object   = @gc_export-kw_obj_func
        AND obj_name = @lv_func_name.

    IF ( sy-subrc <> 0 OR lv_trkorr IS INITIAL ) AND lv_area IS NOT INITIAL.
      SELECT SINGLE trkorr
        INTO @lv_trkorr
        FROM e071
        WHERE pgmid    = @gc_export-kw_pgmid_r3tr
          AND object   = @gc_export-kw_obj_fugr
          AND obj_name = @lv_area.
    ENDIF.

    IF sy-subrc <> 0.
      CLEAR lv_trkorr.
    ENDIF.

    " Fill overview
    ls_overview = me->fill_overview(
      iv_objtype     = gc_export-kw_obj_func
      iv_objname     = lv_func_objname
      IV_description = lv_desc
      iv_package     = lv_package
      iv_status      = lv_status
      iv_created_by  = lv_created_user
      iv_created_on  = lv_created_date
      iv_changed_by  = lv_last_user
      iv_changed_on  = lv_last_date
      iv_trkorr      = lv_trkorr
      iv_version     = gc_export-kw_na ).

    " Read FM parameters
    SELECT *
      FROM fupararef
      INTO TABLE @lt_params
      WHERE funcname = @lv_func_name
      ORDER BY pposition.

    LOOP AT lt_params INTO ls_param.
      CLEAR: ls_fm_row,
             lv_desc_param,
             lv_param_kind.

      CASE ls_param-paramtype.
        WHEN 'I' OR 'E' OR 'C' OR 'T'.
          lv_param_kind = 'P'.
        WHEN 'X'.
          lv_param_kind = 'X'.
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.

      " Replaces old get_ddic_description method
      SELECT SINGLE stext
        INTO @lv_desc_param
        FROM funct
        WHERE funcname  = @lv_func_name
          AND parameter = @ls_param-parameter
          AND kind      = @lv_param_kind
          AND spras     = @sy-langu.

      IF sy-subrc <> 0 OR lv_desc_param IS INITIAL.
        SELECT SINGLE stext
          INTO @lv_desc_param
          FROM funct
          WHERE funcname  = @lv_func_name
            AND parameter = @ls_param-parameter
            AND kind      = @lv_param_kind
            AND spras     = 'E'.
      ENDIF.

      CASE ls_param-paramtype.

        WHEN 'I'.
          lv_no_import = lv_no_import + 1.
          ls_fm_row-parameter01 = lv_no_import.
          ls_fm_row-parameter02 = ls_param-parameter.

          IF ls_param-type = 'X'.
            ls_fm_row-parameter03 = 'TYPE'.
          ELSE.
            ls_fm_row-parameter03 = 'LIKE'.
          ENDIF.

          ls_fm_row-parameter04 = ls_param-structure.

          IF ls_param-optional = 'X'.
            ls_fm_row-parameter05 = 'X'.
          ELSE.
            CLEAR ls_fm_row-parameter05.
          ENDIF.

          ls_fm_row-parameter06 = ls_param-defaultval.
          ls_fm_row-parameter07 = lv_desc_param.

          IF ls_fm_row-parameter04 IS INITIAL.
            ls_fm_row-parameter04 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter05 IS INITIAL.
            ls_fm_row-parameter05 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter06 IS INITIAL.
            ls_fm_row-parameter06 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter07 IS INITIAL.
            ls_fm_row-parameter07 = gc_export-kw_na.
          ENDIF.

          APPEND ls_fm_row TO gs_excel-fm_import.

        WHEN 'E'.
          lv_no_export = lv_no_export + 1.
          ls_fm_row-parameter01 = lv_no_export.
          ls_fm_row-parameter02 = ls_param-parameter.

          IF ls_param-type = 'X'.
            ls_fm_row-parameter03 = 'TYPE'.
          ELSE.
            ls_fm_row-parameter03 = 'LIKE'.
          ENDIF.

          ls_fm_row-parameter04 = ls_param-structure.
          ls_fm_row-parameter05 = lv_desc_param.

          IF ls_fm_row-parameter04 IS INITIAL.
            ls_fm_row-parameter04 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter05 IS INITIAL.
            ls_fm_row-parameter05 = gc_export-kw_na.
          ENDIF.

          APPEND ls_fm_row TO gs_excel-fm_export.

        WHEN 'C'.
          lv_no_changing = lv_no_changing + 1.
          ls_fm_row-parameter01 = lv_no_changing.
          ls_fm_row-parameter02 = ls_param-parameter.

          IF ls_param-type = 'X'.
            ls_fm_row-parameter03 = 'TYPE'.
          ELSE.
            ls_fm_row-parameter03 = 'LIKE'.
          ENDIF.

          ls_fm_row-parameter04 = ls_param-structure.

          IF ls_param-optional = 'X'.
            ls_fm_row-parameter05 = 'X'.
          ELSE.
            CLEAR ls_fm_row-parameter05.
          ENDIF.

          ls_fm_row-parameter06 = ls_param-defaultval.
          ls_fm_row-parameter07 = lv_desc_param.

          IF ls_fm_row-parameter04 IS INITIAL.
            ls_fm_row-parameter04 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter05 IS INITIAL.
            ls_fm_row-parameter05 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter06 IS INITIAL.
            ls_fm_row-parameter06 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter07 IS INITIAL.
            ls_fm_row-parameter07 = gc_export-kw_na.
          ENDIF.

          APPEND ls_fm_row TO gs_excel-fm_changing.

        WHEN 'T'.
          lv_no_tables = lv_no_tables + 1.
          ls_fm_row-parameter01 = lv_no_tables.
          ls_fm_row-parameter02 = ls_param-parameter.

          IF ls_param-type = 'X'.
            ls_fm_row-parameter03 = 'TYPE'.
          ELSEIF ls_param-structure IS NOT INITIAL.
            ls_fm_row-parameter03 = 'STRUCTURE'.
          ELSE.
            ls_fm_row-parameter03 = 'LIKE'.
          ENDIF.

          ls_fm_row-parameter04 = ls_param-structure.
          ls_fm_row-parameter05 = lv_desc_param.

          IF ls_fm_row-parameter04 IS INITIAL.
            ls_fm_row-parameter04 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter05 IS INITIAL.
            ls_fm_row-parameter05 = gc_export-kw_na.
          ENDIF.

          APPEND ls_fm_row TO gs_excel-fm_tables.

        WHEN 'X'.
          lv_no_exception = lv_no_exception + 1.
          ls_fm_row-parameter01 = lv_no_exception.
          ls_fm_row-parameter02 = ls_param-parameter.
          ls_fm_row-parameter03 = lv_desc_param.

          APPEND ls_fm_row TO gs_excel-fm_exception.

      ENDCASE.
    ENDLOOP.

    gs_excel-overview = ls_overview.

    gs_excel-data_element-item = me->fill_data_element(
      iv_objtype = gc_export-kw_obj_func
      iv_objname = lv_func_objname ).

    gs_excel-table-tab_item = me->fill_table(
      iv_objtype = gc_export-kw_obj_func
      iv_objname = lv_func_objname ).

    gs_excel-structure-struc_item = me->fill_structure(
      iv_objtype = gc_export-kw_obj_func
      iv_objname = lv_func_objname ).

    lv_viewer_title      = |FM_{ lv_func_name }|.
    gv_xlwb_default_file = |FM_{ lv_func_name }|.

    CLEAR: gs_excel-show_overview,
           gs_excel-show_screen_layout,
           gs_excel-show_data_element,
           gs_excel-show_table,
           gs_excel-show_structure,
           gs_excel-show_fm_layout,
           gs_excel-show_class_layout.

    gs_excel-show_overview      = abap_true.
    gs_excel-show_screen_layout = abap_false.
    gs_excel-show_data_element  = abap_true.
    gs_excel-show_table         = abap_true.
    gs_excel-show_structure     = abap_true.
    gs_excel-show_fm_layout     = abap_true.
    gs_excel-show_class_layout  = abap_false.

    me->call_excel_form(
      im_excel           = gs_excel
      im_viewer_title    = lv_viewer_title
      im_direct_download = im_direct_download
      im_save_as         = im_save_as ).

  ENDMETHOD.


  METHOD export_fugr_to_excel.

    DATA: ls_fg_fm   TYPE ty_fg_fm,
          lv_fugr    TYPE rs38l-area,
          lo_salv    TYPE REF TO cl_salv_table,
          lo_columns TYPE REF TO cl_salv_columns_table,
          lo_column  TYPE REF TO cl_salv_column_table,
          lo_select  TYPE REF TO cl_salv_selections,
          lt_rows    TYPE salv_t_row,
          lv_row     TYPE salv_de_row,
          lv_ucomm   TYPE sy-ucomm.

    DATA: lv_filename TYPE string,
          lv_path     TYPE string,
          lv_fullpath TYPE string,
          lv_action   TYPE i.

    lv_fugr = im_fugr_name.
    TRANSLATE lv_fugr TO UPPER CASE.
    CONDENSE lv_fugr NO-GAPS.

    CLEAR gt_fg_fm.

    SELECT a~funcname AS fm_name,
           b~stext    AS description
      INTO CORRESPONDING FIELDS OF TABLE @gt_fg_fm
      FROM enlfdir AS a
      LEFT OUTER JOIN tftit AS b
        ON b~funcname = a~funcname
       AND b~spras    = @sy-langu
      WHERE a~area = @lv_fugr
      ORDER BY a~funcname.

    IF gt_fg_fm IS INITIAL.
      MESSAGE |Function Group { lv_fugr } has no Function Modules.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    LOOP AT gt_fg_fm INTO ls_fg_fm.
      IF ls_fg_fm-description IS INITIAL.
        ls_fg_fm-description = ls_fg_fm-fm_name.
      ENDIF.

      ls_fg_fm-download = icon_export.
      MODIFY gt_fg_fm FROM ls_fg_fm INDEX sy-tabix.
    ENDLOOP.

    DO.

      CLEAR: lo_salv,
             lo_columns,
             lo_column,
             lo_select,
             lt_rows,
             lv_row,
             lv_ucomm,
             lv_filename,
             lv_path,
             lv_fullpath,
             lv_action.

      TRY.
          cl_salv_table=>factory(
            IMPORTING
              r_salv_table = lo_salv
            CHANGING
              t_table      = gt_fg_fm ).

          lo_salv->set_screen_popup(
            start_column = 10
            end_column   = 120
            start_line   = 3
            end_line     = 20 ).

          lo_select = lo_salv->get_selections( ).
          lo_select->set_selection_mode( if_salv_c_selection_mode=>single ).

          lo_columns = lo_salv->get_columns( ).
          lo_columns->set_optimize( abap_false ).

          TRY.
              lo_column ?= lo_columns->get_column( 'FM_NAME' ).
              lo_column->set_long_text( 'FM Name' ).
              lo_column->set_medium_text( 'FM Name' ).
              lo_column->set_short_text( 'FM Name' ).
              lo_column->set_output_length( 35 ).
            CATCH cx_salv_not_found.
          ENDTRY.

          TRY.
              lo_column ?= lo_columns->get_column( 'DESCRIPTION' ).
              lo_column->set_long_text( 'Description' ).
              lo_column->set_medium_text( 'Description' ).
              lo_column->set_short_text( 'Desc' ).
              lo_column->set_output_length( 70 ).
            CATCH cx_salv_not_found.
          ENDTRY.

          TRY.
              lo_column ?= lo_columns->get_column( 'DOWNLOAD' ).
              lo_column->set_long_text( 'Export' ).
              lo_column->set_medium_text( 'Export' ).
              lo_column->set_short_text( 'Export' ).
              lo_column->set_icon( if_salv_c_bool_sap=>true ).
              lo_column->set_output_length( 10 ).
            CATCH cx_salv_not_found.
          ENDTRY.

          lo_salv->display( ).
          lv_ucomm = sy-ucomm.

        CATCH cx_salv_msg INTO DATA(lx_salv).
          MESSAGE lx_salv->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
      ENDTRY.

      "Select one FM row, then press the green check button to export.
      IF lv_ucomm <> '&ONT'.
        RETURN.
      ENDIF.

      lt_rows = lo_select->get_selected_rows( ).

      READ TABLE lt_rows INTO lv_row INDEX 1.
      IF sy-subrc <> 0.
        MESSAGE 'Please select one Function Module row first.' TYPE 'S' DISPLAY LIKE 'E'.
        CONTINUE.
      ENDIF.

      READ TABLE gt_fg_fm INTO ls_fg_fm INDEX lv_row.
      IF sy-subrc <> 0 OR ls_fg_fm-fm_name IS INITIAL.
        RETURN.
      ENDIF.

      lv_filename = |FM_{ ls_fg_fm-fm_name }|.

      cl_gui_frontend_services=>file_save_dialog(
        EXPORTING
          default_extension = 'xlsm'
          default_file_name = lv_filename
        CHANGING
          filename          = lv_filename
          path              = lv_path
          fullpath          = lv_fullpath
          user_action       = lv_action ).

      IF lv_action <> cl_gui_frontend_services=>action_ok
         OR lv_fullpath IS INITIAL.
        RETURN.
      ENDIF.

      me->export_fm_to_excel(
        im_func_name       = ls_fg_fm-fm_name
        im_direct_download = abap_true
        im_save_as         = lv_fullpath ).

    ENDDO.

  ENDMETHOD.


  METHOD export_program_to_excel.

    DATA: lv_prog_name    TYPE progname,
          ls_overview     TYPE zcore_st_parameter,
          gs_excel        TYPE zst_gsp04_report,
          lv_desc         TYPE trdirt-text,
          lv_package      TYPE tadir-devclass,
          lv_unam         TYPE trdir-unam,
          lv_udat         TYPE trdir-udat,
          lv_status       TYPE string,
          lv_author       TYPE tadir-author,
          lv_last_user    TYPE reposrc-unam,
          lv_last_date    TYPE reposrc-udat,
          lv_created_user TYPE reposrc-cnam,
          lv_created_date TYPE reposrc-cdat,
          lv_tcode        TYPE tstc-tcode,
          lv_trkorr       TYPE e071-trkorr,
          lv_viewer_title TYPE string.

    "Normalize input
    lv_prog_name = im_prog_name.
    TRANSLATE lv_prog_name TO UPPER CASE.
    CONDENSE lv_prog_name NO-GAPS.
    "--------------------------------------------------
    " Description
    "--------------------------------------------------
    CLEAR lv_desc.
    SELECT SINGLE text
      INTO @lv_desc
      FROM trdirt
      WHERE name  = @lv_prog_name
        AND sprsl = @sy-langu.

    IF sy-subrc <> 0 OR lv_desc IS INITIAL.
      lv_desc = lv_prog_name.
    ENDIF.

    "--------------------------------------------------
    " Package
    "--------------------------------------------------
    CLEAR lv_package.
    SELECT SINGLE devclass
      INTO @lv_package
      FROM tadir
      WHERE pgmid    = @gc_export-kw_pgmid_r3tr
        AND object   = @gc_export-kw_obj_prog
        AND obj_name = @lv_prog_name.

    IF sy-subrc <> 0 OR lv_package IS INITIAL.
      lv_package = gc_export-kw_na.
    ENDIF.

    "--------------------------------------------------
    " Status
    "--------------------------------------------------
    SELECT SINGLE name
      INTO @DATA(lv_prog_exists)
      FROM trdir
      WHERE name = @lv_prog_name.

    IF sy-subrc = 0.
      lv_status = gc_export-kw_active.
    ELSE.
      lv_status = gc_export-kw_inactive.
    ENDIF.

    "--------------------------------------------------
    " Created / Changed info from REPOSRC
    "--------------------------------------------------
    CLEAR: lv_created_user, lv_created_date, lv_last_user, lv_last_date.

    SELECT SINGLE cnam, cdat, unam, udat
      INTO (@lv_created_user, @lv_created_date, @lv_last_user, @lv_last_date)
      FROM reposrc
      WHERE progname = @lv_prog_name
        AND r3state  = @gc_export-kw_r3state_active.

    "--------------------------------------------------
    " Transport Request
    "--------------------------------------------------
    CLEAR lv_trkorr.
    SELECT SINGLE trkorr
      INTO @lv_trkorr
      FROM e071
      WHERE pgmid    = @gc_export-kw_pgmid_r3tr
        AND object   = @gc_export-kw_obj_prog
        AND obj_name = @lv_prog_name.

    IF sy-subrc <> 0.
      CLEAR lv_trkorr.
    ENDIF.

    "--------------------------------------------------
    " Fill overview
    "--------------------------------------------------
    ls_overview = me->fill_overview(
      iv_objtype     = gc_export-kw_obj_prog
      iv_objname     = lv_prog_name
      IV_description = lv_desc
      iv_package     = lv_package
      iv_status      = lv_status
      iv_created_by  = lv_created_user
      iv_created_on  = lv_created_date
      iv_changed_by  = lv_last_user
      iv_changed_on  = lv_last_date
      iv_trkorr      = lv_trkorr
      iv_tcode       = lv_tcode
      iv_version     = gc_export-kw_na ).

    me->fill_screen_layout(
    EXPORTING
      im_program_name  = lv_prog_name
    CHANGING
      ch_screen_layout = gs_excel-screen_layout ).

    gs_excel-overview = ls_overview.

    gs_excel-data_element-item = me->fill_data_element(
    iv_objtype = gc_export-kw_obj_prog
    iv_objname = lv_prog_name ).

    gs_excel-table-tab_item = me->fill_table(
      iv_objtype = gc_export-kw_obj_prog
      iv_objname = lv_prog_name ).

    gs_excel-structure-struc_item = me->fill_structure(
      iv_objtype = gc_export-kw_obj_prog
      iv_objname = lv_prog_name ).

    lv_viewer_title = |PROG_{ lv_prog_name }|.

    CLEAR:
    gs_excel-show_overview,
    gs_excel-show_screen_layout,
    gs_excel-show_data_element,
    gs_excel-show_table,
gs_excel-show_structure,
    gs_excel-show_fm_layout,
    gs_excel-show_class_layout.


    gs_excel-show_overview      = abap_true.
    gs_excel-show_screen_layout = abap_true.
    gs_excel-show_data_element  = abap_true.
    gs_excel-show_table         = abap_true.
    gs_excel-show_structure = abap_true.
    gs_excel-show_fm_layout     = abap_false.
    gs_excel-show_class_layout  = abap_false.

    me->call_excel_form(
      im_excel        = gs_excel
      im_viewer_title = lv_viewer_title
      im_save_as      = |PROG_{ lv_prog_name }.xlsx| ).

  ENDMETHOD.


  METHOD fill_class_layout.

    DATA: lv_class_name   TYPE seoclsname,
          lt_class_source TYPE tt_class_source.

    CLEAR re_layout.

    me->ensure_objects( ).

    lv_class_name = im_class_name.
    TRANSLATE lv_class_name TO UPPER CASE.
    CONDENSE lv_class_name NO-GAPS.

    lt_class_source = me->go_fetch->get_class( iv_class_name = lv_class_name ).

    me->fill_class_layout_classdef(
      EXPORTING
        im_class_name    = lv_class_name
      CHANGING
        ch_layout        = re_layout ).

    me->fill_class_layout_attr(
      EXPORTING
        im_class_name    = lv_class_name
        imt_class_source = lt_class_source
      CHANGING
        ch_layout        = re_layout ).

    me->fill_class_layout_method(
      EXPORTING
        im_class_name    = lv_class_name
        imt_class_source = lt_class_source
      CHANGING
        ch_layout        = re_layout ).

    me->fill_class_layout_param(
      EXPORTING
        im_class_name    = lv_class_name
        imt_class_source = lt_class_source
      CHANGING
        ch_layout        = re_layout ).

    me->normalize_class_layout(
      CHANGING
        ch_layout = re_layout ).

  ENDMETHOD.


  METHOD fill_class_layout_attr.

    CONSTANTS: gc_na TYPE string VALUE 'N/A'.

    TYPES: BEGIN OF ty_comp_meta,
             clsname    TYPE seoclsname,
             cmpname    TYPE seocmpname,
             version    TYPE seoversion,
             state      TYPE seostate,
             exposure   TYPE seoexpose,
             attdecltyp TYPE seoattdecl,
             attrdonly  TYPE seordonly,
             attvalue   TYPE seovalue,
             attdynamic TYPE seodynamic,
             attexpvirt TYPE seoexpose,
             mtddecltyp TYPE seomtddecl,
             mtdabstrct TYPE seoabstrct,
             mtdfinal   TYPE seofinal,
           END OF ty_comp_meta.

    TYPES: BEGIN OF ty_comp_text,
             clsname  TYPE seoclsname,
             cmpname  TYPE seocmpname,
             langu    TYPE sylangu,
             descript TYPE seodescr,
           END OF ty_comp_text.

    DATA: lv_class_name TYPE seoclsname,
          ls_attr       TYPE zst_src_class_attr,
          ls_comp       TYPE ty_comp_meta,
          ls_comp_txt   TYPE ty_comp_text,
          lt_comp_meta  TYPE STANDARD TABLE OF ty_comp_meta,
          lt_comp_text  TYPE STANDARD TABLE OF ty_comp_text.

    DATA: ls_clskey   TYPE seoclSkey,
          lt_seo_attr TYPE seoo_attributes_r,
          ls_seo_attr LIKE LINE OF lt_seo_attr.

    lv_class_name = im_class_name.
    TRANSLATE lv_class_name TO UPPER CASE.
    CONDENSE lv_class_name NO-GAPS.

    "============================================================
    " 1. Core metadata from SEOCOMPODF
    "============================================================
    CLEAR lt_comp_meta.
    SELECT clsname
           cmpname
           version
           state
           exposure
           attdecltyp
           attrdonly
           attvalue
           attdynamic
           attexpvirt
           mtddecltyp
           mtdabstrct
           mtdfinal
      INTO TABLE lt_comp_meta
      FROM seocompodf
      WHERE clsname = lv_class_name
        AND version = '1'
        AND state   = '1'.

    "============================================================
    " 2. Description from SEOCOMPOTX
    "============================================================
    CLEAR lt_comp_text.
    SELECT clsname
           cmpname
           langu
           descript
      INTO TABLE lt_comp_text
      FROM seocompotx
      WHERE clsname = lv_class_name
        AND langu   = sy-langu.

    "============================================================
    " 3. Additional info from SEO_CLASS_TYPEINFO_GET
    "============================================================
    CLEAR: ls_clskey, lt_seo_attr.
    ls_clskey-clsname = lv_class_name.

    CALL FUNCTION 'SEO_CLASS_TYPEINFO_GET'
      EXPORTING
        clskey            = ls_clskey
        state             = '1'
        with_descriptions = seox_true
      IMPORTING
        attributes        = lt_seo_attr
      EXCEPTIONS
        not_existing      = 1
        is_interface      = 2
        model_only        = 3
        OTHERS            = 4.

    "============================================================
    " 4. Build output
    "============================================================
    LOOP AT lt_comp_meta INTO ls_comp.
      IF ls_comp-cmpname IS INITIAL
         OR ls_comp-attdecltyp IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR ls_attr.
      ls_attr-attr_name = ls_comp-cmpname.
      TRANSLATE ls_attr-attr_name TO UPPER CASE.
      CONDENSE ls_attr-attr_name NO-GAPS.

      " Section
      CASE ls_comp-exposure.
        WHEN '0'.
          ls_attr-attr_section = 'PRIVATE'.
        WHEN '1'.
          ls_attr-attr_section = 'PROTECTED'.
        WHEN '2'.
          ls_attr-attr_section = 'PUBLIC'.
        WHEN OTHERS.
          ls_attr-attr_section = gc_na.
      ENDCASE.

      " Level
      CASE ls_comp-attdecltyp.
        WHEN '0'.
          ls_attr-attr_level = 'INSTANCE'.
        WHEN '1'.
          ls_attr-attr_level = 'STATIC'.
        WHEN '2'.
          ls_attr-attr_level = 'CONSTANT'.
        WHEN OTHERS.
          ls_attr-attr_level = ls_comp-attdecltyp.
      ENDCASE.

      " Read only from DB first
      IF ls_comp-attrdonly IS NOT INITIAL.
        ls_attr-read_only = 'X'.
      ELSE.
        ls_attr-read_only = gc_na.
      ENDIF.

      " Default value from DB first
      IF ls_comp-attvalue IS NOT INITIAL.
        ls_attr-default_value = ls_comp-attvalue.
      ELSE.
        ls_attr-default_value = gc_na.
      ENDIF.

      " Description from text table
      CLEAR ls_comp_txt.
      READ TABLE lt_comp_text INTO ls_comp_txt
        WITH KEY clsname = lv_class_name
                 cmpname = ls_comp-cmpname
                 langu   = sy-langu.
      IF sy-subrc = 0 AND ls_comp_txt-descript IS NOT INITIAL.
        ls_attr-attr_description = ls_comp_txt-descript.
      ELSE.
        ls_attr-attr_description = gc_na.
      ENDIF.

      " Default Type
      ls_attr-type_name = gc_na.

      "----------------------------------------------------------
      " Enrich from SEO_CLASS_TYPEINFO_GET result
      " Exact line type = LIKE LINE OF seo0_attributes_r
      "----------------------------------------------------------
      CLEAR ls_seo_attr.
      READ TABLE lt_seo_attr INTO ls_seo_attr
        WITH KEY cmpname = ls_comp-cmpname.

      IF sy-subrc = 0.

        " Read only fallback
        IF ( ls_attr-read_only IS INITIAL OR ls_attr-read_only = gc_na )
           AND ls_seo_attr-attrdonly IS NOT INITIAL.
          ls_attr-read_only = 'X'.
        ENDIF.

        " Default value fallback
        IF ( ls_attr-default_value IS INITIAL OR ls_attr-default_value = gc_na )
           AND ls_seo_attr-attvalue IS NOT INITIAL.
          ls_attr-default_value = ls_seo_attr-attvalue.
        ENDIF.

        " Description fallback if FM returns one on your system
        IF ( ls_attr-attr_description IS INITIAL OR ls_attr-attr_description = gc_na ).
          IF ls_seo_attr-descript IS NOT INITIAL.
            ls_attr-attr_description = ls_seo_attr-descript.
          ENDIF.
        ENDIF.

      ENDIF.

      IF ls_attr-type_name IS INITIAL.
        ls_attr-type_name = gc_na.
      ENDIF.
      IF ls_attr-read_only IS INITIAL.
        ls_attr-read_only = gc_na.
      ENDIF.
      IF ls_attr-default_value IS INITIAL.
        ls_attr-default_value = gc_na.
      ENDIF.
      IF ls_attr-attr_description IS INITIAL.
        ls_attr-attr_description = gc_na.
      ENDIF.

      APPEND ls_attr TO ch_layout-attributes.
    ENDLOOP.

    SORT ch_layout-attributes BY attr_name attr_section attr_level.
    DELETE ADJACENT DUPLICATES FROM ch_layout-attributes
      COMPARING attr_name attr_section attr_level.

  ENDMETHOD.


  METHOD fill_class_layout_classdef.

    DATA: lv_class_name TYPE seoclsname,
          lv_clstype    TYPE seoclass-clstype,
          lv_classpool  TYPE progname,
          lv_line       TYPE string,
          lv_stmt       TYPE string,
          lv_stmt_uc    TYPE string,
          lv_temp       TYPE string,
          lv_decl_stmt  TYPE string,
          lv_superclass TYPE string,
          lv_interfaces TYPE string,
          ls_class_def  TYPE zst_src_class_def,
          ls_rel        TYPE ty_rel_meta,
          lt_rel_meta   TYPE STANDARD TABLE OF ty_rel_meta,
          lt_pool_src   TYPE STANDARD TABLE OF string.

    lv_class_name = im_class_name.
    TRANSLATE lv_class_name TO UPPER CASE.
    CONDENSE lv_class_name NO-GAPS.

    CLEAR ls_class_def.
    ls_class_def-class_name = lv_class_name.

    CLEAR lv_clstype.
    SELECT SINGLE clstype
      INTO lv_clstype
      FROM seoclass
      WHERE clsname = lv_class_name.

    IF sy-subrc = 0.
      CASE lv_clstype.
        WHEN '0'.
          ls_class_def-class_type = 'Class'.
        WHEN '1'.
          ls_class_def-class_type = 'Interface'.
        WHEN OTHERS.
          ls_class_def-class_type = lv_clstype.
      ENDCASE.
    ENDIF.

    CLEAR lt_rel_meta.
    SELECT clsname
           refclsname
           version
           state
           reltype
           relname
           exposure
           impfinal
           impabstrct
      INTO TABLE lt_rel_meta
      FROM seometarel
      WHERE clsname = lv_class_name
        AND version = '1'
        AND state   = '1'.

    CLEAR lv_classpool.
    TRY.
        lv_classpool = cl_oo_classname_service=>get_classpool_name( lv_class_name ).
      CATCH cx_root.
        CLEAR lv_classpool.
    ENDTRY.

    CLEAR lt_pool_src.
    IF lv_classpool IS NOT INITIAL.
      lt_pool_src = me->go_fetch->get_source_code( iv_name = lv_classpool ).
    ENDIF.

    CLEAR: lv_stmt, lv_decl_stmt, lv_interfaces.
    LOOP AT lt_pool_src INTO lv_line.

      CONDENSE lv_line.
      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.

      IF lv_stmt IS INITIAL.
        lv_stmt = lv_line.
      ELSE.
        CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
      ENDIF.

      IF lv_line CS '.'.
        lv_stmt_uc = lv_stmt.
        TRANSLATE lv_stmt_uc TO UPPER CASE.

        IF lv_stmt_uc CS 'CLASS'
           AND lv_stmt_uc CS lv_class_name
           AND lv_stmt_uc CS 'DEFINITION'.
          lv_decl_stmt = lv_stmt.
        ENDIF.

        IF lv_stmt_uc CP 'INTERFACES *.'.
          CLEAR lv_temp.
          FIND PCRE 'INTERFACES\s+([A-Za-z0-9_/]+)'
            IN lv_stmt
            SUBMATCHES lv_temp.
          IF sy-subrc = 0 AND lv_temp IS NOT INITIAL.
            TRANSLATE lv_temp TO UPPER CASE.
            CONDENSE lv_temp NO-GAPS.
            IF lv_interfaces IS INITIAL.
              lv_interfaces = lv_temp.
            ELSEIF lv_interfaces NS lv_temp.
              CONCATENATE lv_interfaces lv_temp INTO lv_interfaces SEPARATED BY ', '.
            ENDIF.
          ENDIF.
        ENDIF.

        CLEAR lv_stmt.
      ENDIF.
    ENDLOOP.

    IF lv_decl_stmt IS NOT INITIAL.
      lv_stmt_uc = lv_decl_stmt.
      TRANSLATE lv_stmt_uc TO UPPER CASE.

      IF lv_stmt_uc CS ' FINAL'.
        ls_class_def-is_final = 'X'.
      ENDIF.

      IF lv_stmt_uc CS ' ABSTRACT'.
        ls_class_def-is_abstract = 'X'.
      ENDIF.

      IF lv_stmt_uc CS ' CREATE PUBLIC'.
        ls_class_def-create_visibility = 'PUBLIC'.
      ELSEIF lv_stmt_uc CS ' CREATE PROTECTED'.
        ls_class_def-create_visibility = 'PROTECTED'.
      ELSEIF lv_stmt_uc CS ' CREATE PRIVATE'.
        ls_class_def-create_visibility = 'PRIVATE'.
      ENDIF.

      CLEAR lv_superclass.
      FIND PCRE 'INHERITING\s+FROM\s+([A-Za-z0-9_/]+)'
        IN lv_stmt_uc
        SUBMATCHES lv_superclass.
      IF sy-subrc = 0 AND lv_superclass IS NOT INITIAL.
        ls_class_def-superclass = lv_superclass.
      ENDIF.
    ENDIF.

    IF ls_class_def-superclass IS INITIAL.
      LOOP AT lt_rel_meta INTO ls_rel.
        IF ls_rel-refclsname IS NOT INITIAL
           AND ls_rel-refclsname <> lv_class_name.
          ls_class_def-superclass = ls_rel-refclsname.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF lv_interfaces IS NOT INITIAL.
      ls_class_def-interfaces = lv_interfaces.
    ENDIF.

    ch_layout-class_def = ls_class_def.

  ENDMETHOD.


  METHOD fill_class_layout_method.

    DATA: lv_class_name   TYPE seoclsname,
          lv_line         TYPE string,
          lv_stmt         TYPE string,
          lv_stmt_uc      TYPE string,
          lv_temp         TYPE string,
          lv_section      TYPE char20,
          lv_keyword      TYPE string,
          lv_name         TYPE string,
          lv_method_part  TYPE string,
          lv_len          TYPE i,
          lv_idx          TYPE i,
          lv_depth        TYPE i,
          lv_offset       TYPE i,
          lv_char         TYPE c LENGTH 1,
          lv_buf          TYPE string,
          lv_is_section   TYPE abap_bool VALUE abap_false,
          ls_meth         TYPE zst_src_class_meth,
          ls_src          TYPE ty_class_source,
          ls_comp         TYPE ty_comp_meta,
          ls_comp_txt     TYPE ty_comp_text,
          lt_method_parts TYPE STANDARD TABLE OF string,
          lt_comp_meta    TYPE STANDARD TABLE OF ty_comp_meta,
          lt_comp_text    TYPE STANDARD TABLE OF ty_comp_text.

    FIELD-SYMBOLS: <ls_meth> TYPE zst_src_class_meth.

    lv_class_name = im_class_name.
    TRANSLATE lv_class_name TO UPPER CASE.
    CONDENSE lv_class_name NO-GAPS.

    CLEAR: lt_comp_meta, lt_comp_text.
    SELECT clsname
           cmpname
           version
           state
           exposure
           attdecltyp
           attrdonly
           attvalue
           attdynamic
           attexpvirt
           mtddecltyp
           mtdabstrct
           mtdfinal
      INTO TABLE lt_comp_meta
      FROM seocompodf
      WHERE clsname = lv_class_name
        AND version = '1'
        AND state   = '1'.

    SELECT clsname
           cmpname
           langu
           descript
      INTO TABLE lt_comp_text
      FROM seocompotx
      WHERE clsname = lv_class_name
        AND langu   = sy-langu.

    LOOP AT lt_comp_meta INTO ls_comp.
      IF ls_comp-cmpname IS NOT INITIAL
         AND ls_comp-mtddecltyp IS NOT INITIAL.

        CLEAR ls_meth.
        ls_meth-method_name = ls_comp-cmpname.
        TRANSLATE ls_meth-method_name TO UPPER CASE.
        CONDENSE ls_meth-method_name NO-GAPS.

        CASE ls_comp-exposure.
          WHEN '0'.
            ls_meth-visibility = 'PRIVATE'.
          WHEN '1'.
            ls_meth-visibility = 'PROTECTED'.
          WHEN '2'.
            ls_meth-visibility = 'PUBLIC'.
          WHEN OTHERS.
            ls_meth-visibility = gc_export-kw_na.
        ENDCASE.

        CASE ls_comp-mtddecltyp.
          WHEN '0'.
            ls_meth-method_level = 'INSTANCE'.
          WHEN '1'.
            ls_meth-method_level = 'STATIC'.
          WHEN OTHERS.
            ls_meth-method_level = ls_comp-mtddecltyp.
        ENDCASE.

        IF ls_meth-method_name = 'CONSTRUCTOR'.
          ls_meth-method_type = 'Constructor'.
        ELSEIF ls_meth-method_name = 'CLASS_CONSTRUCTOR'.
          ls_meth-method_type = 'Class Constructor'.
        ELSEIF ls_comp-mtdabstrct IS NOT INITIAL.
          ls_meth-method_type = 'Abstract'.
        ELSE.
          ls_meth-method_type = 'Normal'.
        ENDIF.

        CLEAR ls_comp_txt.
        READ TABLE lt_comp_text INTO ls_comp_txt
          WITH KEY clsname = lv_class_name
                   cmpname = ls_comp-cmpname
                   langu   = sy-langu.
        IF sy-subrc = 0 AND ls_comp_txt-descript IS NOT INITIAL.
          ls_meth-method_description = ls_comp_txt-descript.
        ELSE.
          CLEAR ls_src.
          READ TABLE imt_class_source INTO ls_src
            WITH KEY method_name = ls_meth-method_name.
          IF sy-subrc = 0 AND ls_src-description IS NOT INITIAL.
            ls_meth-method_description = ls_src-description.
          ELSE.
            ls_meth-method_description = gc_export-kw_na.
          ENDIF.
        ENDIF.

        APPEND ls_meth TO ch_layout-methods.
      ENDIF.
    ENDLOOP.

    CLEAR lv_section.

    LOOP AT imt_class_source INTO ls_src.

      CLEAR lv_is_section.
      IF ls_src-include_kind = 'SECTION'.
        lv_is_section = abap_true.
      ENDIF.

      IF lv_is_section = abap_false.

        IF ls_src-method_name IS NOT INITIAL.
          lv_name = ls_src-method_name.
          TRANSLATE lv_name TO UPPER CASE.
          CONDENSE lv_name NO-GAPS.

          READ TABLE ch_layout-methods ASSIGNING <ls_meth>
            WITH KEY method_name = lv_name.

          IF sy-subrc <> 0.
            CLEAR ls_meth.
            ls_meth-method_name = lv_name.

            IF ls_src-method_level IS NOT INITIAL.
              ls_meth-method_level = ls_src-method_level.
            ELSE.
              ls_meth-method_level = gc_export-kw_na.
            ENDIF.

            IF ls_src-section IS NOT INITIAL.
              ls_meth-visibility = ls_src-section.
            ELSE.
              ls_meth-visibility = gc_export-kw_na.
            ENDIF.

            IF lv_name = 'CONSTRUCTOR'.
              ls_meth-method_type = 'Constructor'.
            ELSEIF lv_name = 'CLASS_CONSTRUCTOR'.
              ls_meth-method_type = 'Class Constructor'.
            ELSE.
              ls_meth-method_type = 'Normal'.
            ENDIF.

            IF ls_src-description IS NOT INITIAL.
              ls_meth-method_description = ls_src-description.
            ELSE.
              ls_meth-method_description = gc_export-kw_na.
            ENDIF.

            APPEND ls_meth TO ch_layout-methods.

          ELSE.

            IF ( <ls_meth>-method_description IS INITIAL
              OR <ls_meth>-method_description = gc_export-kw_na )
              AND ls_src-description IS NOT INITIAL.
              <ls_meth>-method_description = ls_src-description.
            ENDIF.

            IF ( <ls_meth>-visibility IS INITIAL
              OR <ls_meth>-visibility = gc_export-kw_na )
              AND ls_src-section IS NOT INITIAL.
              <ls_meth>-visibility = ls_src-section.
            ENDIF.

            IF ( <ls_meth>-method_level IS INITIAL
              OR <ls_meth>-method_level = gc_export-kw_na )
              AND ls_src-method_level IS NOT INITIAL.
              <ls_meth>-method_level = ls_src-method_level.
            ENDIF.

          ENDIF.
        ENDIF.

        CONTINUE.
      ENDIF.

      lv_section = ls_src-section.
      TRANSLATE lv_section TO UPPER CASE.
      CONDENSE lv_section NO-GAPS.

      CLEAR lv_stmt.

      LOOP AT ls_src-source_code INTO lv_line.

        IF lv_line IS INITIAL.
          CONTINUE.
        ENDIF.

        IF lv_stmt IS INITIAL.
          lv_stmt = lv_line.
        ELSE.
          CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
        ENDIF.

        IF lv_line NS '.'.
          CONTINUE.
        ENDIF.

        CONDENSE lv_stmt.
        IF lv_stmt IS INITIAL.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        lv_stmt_uc = lv_stmt.
        TRANSLATE lv_stmt_uc TO UPPER CASE.

        IF lv_stmt_uc CP 'METHODS *.'
           OR lv_stmt_uc CP 'CLASS-METHODS *.'.

          CLEAR lt_method_parts.
          CLEAR: lv_keyword, lv_temp.

          FIND PCRE '^\s*(METHODS|CLASS-METHODS)\s*:(.*)$'
            IN lv_stmt
            SUBMATCHES lv_keyword lv_temp.

          IF sy-subrc <> 0.
            FIND PCRE '^\s*(METHODS|CLASS-METHODS)\s+(.+)$'
              IN lv_stmt
              SUBMATCHES lv_keyword lv_temp.
          ENDIF.

          IF sy-subrc = 0 AND lv_temp IS NOT INITIAL.

            CONDENSE lv_temp.
            lv_len = strlen( lv_temp ).
            IF lv_len > 0.
              lv_offset = lv_len - 1.
              IF lv_temp+lv_offset(1) = '.'.
                lv_temp = lv_temp(lv_offset).
              ENDIF.
            ENDIF.

            CLEAR: lv_buf, lv_depth.
            lv_len = strlen( lv_temp ).

            DO lv_len TIMES.
              lv_idx = sy-index - 1.
              lv_char = lv_temp+lv_idx(1).

              IF lv_char = '('.
                lv_depth = lv_depth + 1.
              ELSEIF lv_char = ')'.
                IF lv_depth > 0.
                  lv_depth = lv_depth - 1.
                ENDIF.
              ENDIF.

              IF lv_char = ',' AND lv_depth = 0.
                CONDENSE lv_buf.
                IF lv_buf IS NOT INITIAL.
                  APPEND lv_buf TO lt_method_parts.
                ENDIF.
                CLEAR lv_buf.
              ELSE.
                CONCATENATE lv_buf lv_char INTO lv_buf IN CHARACTER MODE.
              ENDIF.
            ENDDO.

            CONDENSE lv_buf.
            IF lv_buf IS NOT INITIAL.
              APPEND lv_buf TO lt_method_parts.
            ENDIF.

            LOOP AT lt_method_parts INTO lv_method_part.

              CONDENSE lv_method_part.
              IF lv_method_part IS INITIAL.
                CONTINUE.
              ENDIF.

              CLEAR: ls_meth, lv_name.

              FIND PCRE '^\s*([A-Za-z0-9_]+)'
                IN lv_method_part
                SUBMATCHES lv_name.
              IF sy-subrc <> 0 OR lv_name IS INITIAL.
                CONTINUE.
              ENDIF.

              TRANSLATE lv_name TO UPPER CASE.
              CONDENSE lv_name NO-GAPS.

              READ TABLE ch_layout-methods ASSIGNING <ls_meth>
                WITH KEY method_name = lv_name.

              IF sy-subrc <> 0.
                CLEAR ls_meth.
                ls_meth-method_name = lv_name.
                ls_meth-visibility  = lv_section.
                IF lv_keyword = 'CLASS-METHODS'.
                  ls_meth-method_level = 'STATIC'.
                ELSE.
                  ls_meth-method_level = 'INSTANCE'.
                ENDIF.

                IF lv_name = 'CONSTRUCTOR'.
                  ls_meth-method_type = 'Constructor'.
                ELSEIF lv_name = 'CLASS_CONSTRUCTOR'.
                  ls_meth-method_type = 'Class Constructor'.
                ELSEIF lv_stmt_uc CS 'ABSTRACT'.
                  ls_meth-method_type = 'Abstract'.
                ELSE.
                  ls_meth-method_type = 'Normal'.
                ENDIF.

                IF ls_meth-method_description IS INITIAL.
                  ls_meth-method_description = gc_export-kw_na.
                ENDIF.

                APPEND ls_meth TO ch_layout-methods.
                READ TABLE ch_layout-methods ASSIGNING <ls_meth>
                  WITH KEY method_name = lv_name.
              ENDIF.

              IF <ls_meth> IS ASSIGNED.
                IF <ls_meth>-visibility IS INITIAL OR <ls_meth>-visibility = gc_export-kw_na.
                  <ls_meth>-visibility = lv_section.
                ENDIF.

                IF <ls_meth>-method_level IS INITIAL OR <ls_meth>-method_level = gc_export-kw_na.
                  IF ls_src-method_level IS NOT INITIAL.
                    <ls_meth>-method_level = ls_src-method_level.
                  ELSEIF lv_keyword = 'CLASS-METHODS'.
                    <ls_meth>-method_level = 'STATIC'.
                  ELSE.
                    <ls_meth>-method_level = 'INSTANCE'.
                  ENDIF.
                ENDIF.

                IF ( <ls_meth>-method_description IS INITIAL
                  OR <ls_meth>-method_description = gc_export-kw_na )
                  AND ls_src-description IS NOT INITIAL.
                  <ls_meth>-method_description = ls_src-description.
                ENDIF.
              ENDIF.

            ENDLOOP.
          ENDIF.

          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        CLEAR lv_stmt.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD fill_class_layout_param.

    DATA: lv_class_name        TYPE seoclsname,
          lv_line              TYPE string,
          lv_stmt              TYPE string,
          lv_stmt_uc           TYPE string,
          lv_temp              TYPE string,
          lv_temp_uc           TYPE string,
          lv_keyword           TYPE string,
          lv_name              TYPE string,
          lv_method_part       TYPE string,
          lv_current_kind      TYPE string,
          lv_token             TYPE string,
          lv_len               TYPE i,
          lv_idx               TYPE i,
          lv_depth             TYPE i,
          lv_offset            TYPE i,
          lv_char              TYPE c LENGTH 1,
          lv_buf               TYPE string,
          lv_expect_value_name TYPE abap_bool VALUE abap_false,
          lv_expect_type_name  TYPE abap_bool VALUE abap_false,
          lv_expect_default    TYPE abap_bool VALUE abap_false,
          lv_expect_ref_to     TYPE abap_bool VALUE abap_false,
          lv_seen_ref          TYPE abap_bool VALUE abap_false,
          ls_param             TYPE zst_src_class_param,
          ls_src               TYPE ty_class_source,
          ls_subco             TYPE ty_subco_meta,
          ls_subcotx           TYPE ty_subco_text,
          lt_tokens            TYPE STANDARD TABLE OF string,
          lt_method_parts      TYPE STANDARD TABLE OF string,
          lt_subco_meta        TYPE STANDARD TABLE OF ty_subco_meta,
          lt_subco_text        TYPE STANDARD TABLE OF ty_subco_text.

    FIELD-SYMBOLS: <lv_token> TYPE any.

    lv_class_name = im_class_name.
    TRANSLATE lv_class_name TO UPPER CASE.
    CONDENSE lv_class_name NO-GAPS.

    CLEAR: lt_subco_meta, lt_subco_text.
    SELECT clsname
           cmpname
           sconame
           version
           pardecltyp
           parpasstyp
           typtype
           type
           tableof
           parvalue
           paroptionl
           parpreferd
      INTO TABLE lt_subco_meta
      FROM seosubcodf
      WHERE clsname = lv_class_name
        AND version = '1'.

    SELECT clsname
           cmpname
           sconame
           langu
           descript
      INTO TABLE lt_subco_text
      FROM seosubcotx
      WHERE clsname = lv_class_name
        AND langu   = sy-langu.

    LOOP AT lt_subco_meta INTO ls_subco.

      IF ls_subco-cmpname IS INITIAL OR ls_subco-sconame IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR ls_param.

      ls_param-method_name = ls_subco-cmpname.
      TRANSLATE ls_param-method_name TO UPPER CASE.
      CONDENSE ls_param-method_name NO-GAPS.

      ls_param-param_name = ls_subco-sconame.
      TRANSLATE ls_param-param_name TO UPPER CASE.
      CONDENSE ls_param-param_name NO-GAPS.

      CASE ls_subco-pardecltyp.
        WHEN '0'.
          ls_param-param_type = 'IMPORTING'.
        WHEN '1'.
          ls_param-param_type = 'EXPORTING'.
        WHEN '2'.
          ls_param-param_type = 'CHANGING'.
        WHEN '3'.
          ls_param-param_type = 'RETURNING'.
        WHEN OTHERS.
          ls_param-param_type = ls_subco-pardecltyp.
      ENDCASE.

      CASE ls_subco-parpasstyp.
        WHEN '0'.
          ls_param-pass_by_value = gc_export-kw_na.
        WHEN '1'.
          ls_param-pass_by_value = 'X'.
        WHEN OTHERS.
          ls_param-pass_by_value = ls_subco-parpasstyp.
      ENDCASE.

      CASE ls_subco-typtype.
        WHEN '0'.
          ls_param-typing_method = 'TYPE'.
        WHEN '1'.
          ls_param-typing_method = 'LIKE'.
        WHEN OTHERS.
          ls_param-typing_method = ls_subco-typtype.
      ENDCASE.

      IF ls_subco-type IS NOT INITIAL.
        ls_param-associated_type = ls_subco-type.
        IF ls_subco-tableof = 'X'.
          CONCATENATE 'TABLE OF' ls_param-associated_type
            INTO ls_param-associated_type
            SEPARATED BY space.
        ENDIF.
      ELSE.
        ls_param-associated_type = gc_export-kw_na.
      ENDIF.

      IF ls_subco-parvalue IS NOT INITIAL.
        ls_param-param_default_value = ls_subco-parvalue.
      ELSE.
        ls_param-param_default_value = gc_export-kw_na.
      ENDIF.

      IF ls_subco-paroptionl IS NOT INITIAL.
        ls_param-optional = 'X'.
      ELSE.
        ls_param-optional = gc_export-kw_na.
      ENDIF.

      READ TABLE lt_subco_text INTO ls_subcotx
        WITH KEY clsname = lv_class_name
                 cmpname = ls_subco-cmpname
                 sconame = ls_subco-sconame
                 langu   = sy-langu.
      IF sy-subrc = 0 AND ls_subcotx-descript IS NOT INITIAL.
        ls_param-param_description = ls_subcotx-descript.
      ELSE.
        ls_param-param_description = gc_export-kw_na.
      ENDIF.

      APPEND ls_param TO ch_layout-method_params.

    ENDLOOP.

    LOOP AT imt_class_source INTO ls_src.

      IF ls_src-include_kind <> 'SECTION'.
        CONTINUE.
      ENDIF.

      CLEAR lv_stmt.

      LOOP AT ls_src-source_code INTO lv_line.

        IF lv_line IS INITIAL.
          CONTINUE.
        ENDIF.

        IF lv_stmt IS INITIAL.
          lv_stmt = lv_line.
        ELSE.
          CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
        ENDIF.

        IF lv_line NS '.'.
          CONTINUE.
        ENDIF.

        CONDENSE lv_stmt.
        IF lv_stmt IS INITIAL.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        lv_stmt_uc = lv_stmt.
        TRANSLATE lv_stmt_uc TO UPPER CASE.

        IF lv_stmt_uc CP 'METHODS *.'
           OR lv_stmt_uc CP 'CLASS-METHODS *.'.

          CLEAR lt_method_parts.
          CLEAR: lv_keyword, lv_temp.

          FIND PCRE '^\s*(METHODS|CLASS-METHODS)\s*:(.*)$'
            IN lv_stmt
            SUBMATCHES lv_keyword lv_temp.

          IF sy-subrc <> 0.
            FIND PCRE '^\s*(METHODS|CLASS-METHODS)\s+(.+)$'
              IN lv_stmt
              SUBMATCHES lv_keyword lv_temp.
          ENDIF.

          IF sy-subrc = 0 AND lv_temp IS NOT INITIAL.

            CONDENSE lv_temp.
            lv_len = strlen( lv_temp ).
            IF lv_len > 0.
              lv_offset = lv_len - 1.
              IF lv_temp+lv_offset(1) = '.'.
                lv_temp = lv_temp(lv_offset).
              ENDIF.
            ENDIF.

            CLEAR: lv_buf, lv_depth.
            lv_len = strlen( lv_temp ).

            DO lv_len TIMES.
              lv_idx = sy-index - 1.
              lv_char = lv_temp+lv_idx(1).

              IF lv_char = '('.
                lv_depth = lv_depth + 1.
              ELSEIF lv_char = ')'.
                IF lv_depth > 0.
                  lv_depth = lv_depth - 1.
                ENDIF.
              ENDIF.

              IF lv_char = ',' AND lv_depth = 0.
                CONDENSE lv_buf.
                IF lv_buf IS NOT INITIAL.
                  APPEND lv_buf TO lt_method_parts.
                ENDIF.
                CLEAR lv_buf.
              ELSE.
                CONCATENATE lv_buf lv_char INTO lv_buf IN CHARACTER MODE.
              ENDIF.
            ENDDO.

            CONDENSE lv_buf.
            IF lv_buf IS NOT INITIAL.
              APPEND lv_buf TO lt_method_parts.
            ENDIF.

            LOOP AT lt_method_parts INTO lv_method_part.

              CONDENSE lv_method_part.
              IF lv_method_part IS INITIAL.
                CONTINUE.
              ENDIF.

              CLEAR lv_name.

              FIND PCRE '^\s*([A-Za-z0-9_]+)'
                IN lv_method_part
                SUBMATCHES lv_name.
              IF sy-subrc <> 0 OR lv_name IS INITIAL.
                CONTINUE.
              ENDIF.

              TRANSLATE lv_name TO UPPER CASE.
              CONDENSE lv_name NO-GAPS.

              CLEAR lt_tokens.
              lv_temp = lv_method_part.

              REPLACE ALL OCCURRENCES OF '(' IN lv_temp WITH ' ( '.
              REPLACE ALL OCCURRENCES OF ')' IN lv_temp WITH ' ) '.
              REPLACE ALL OCCURRENCES OF '.' IN lv_temp WITH ' . '.
              REPLACE ALL OCCURRENCES OF ':' IN lv_temp WITH ' : '.
              REPLACE ALL OCCURRENCES OF '!' IN lv_temp WITH ' !'.
              CONDENSE lv_temp.

              SPLIT lv_temp AT space INTO TABLE lt_tokens.

              CLEAR: ls_param,
                     lv_current_kind,
                     lv_expect_value_name,
                     lv_expect_type_name,
                     lv_expect_default,
                     lv_expect_ref_to,
                     lv_seen_ref.

              LOOP AT lt_tokens ASSIGNING <lv_token>.
                lv_token = <lv_token>.
                IF lv_token IS INITIAL.
                  CONTINUE.
                ENDIF.

                lv_temp_uc = lv_token.
                TRANSLATE lv_temp_uc TO UPPER CASE.

                IF lv_temp_uc = ':'.
                  CONTINUE.
                ENDIF.

                IF lv_temp_uc = 'IMPORTING'
                   OR lv_temp_uc = 'EXPORTING'
                   OR lv_temp_uc = 'CHANGING'
                   OR lv_temp_uc = 'RETURNING'.

                  IF ls_param-param_name IS NOT INITIAL.
                    IF ls_param-method_name IS INITIAL.
                      ls_param-method_name = lv_name.
                    ENDIF.
                    IF ls_param-param_type IS INITIAL.
                      ls_param-param_type = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-typing_method IS INITIAL.
                      ls_param-typing_method = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-associated_type IS INITIAL.
                      ls_param-associated_type = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-param_default_value IS INITIAL.
                      ls_param-param_default_value = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-param_description IS INITIAL.
                      ls_param-param_description = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-optional IS INITIAL.
                      ls_param-optional = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-pass_by_value IS INITIAL.
                      ls_param-pass_by_value = gc_export-kw_na.
                    ENDIF.
                    APPEND ls_param TO ch_layout-method_params.
                    CLEAR ls_param.
                  ENDIF.

                  CLEAR: lv_expect_value_name,
                         lv_expect_type_name,
                         lv_expect_default,
                         lv_expect_ref_to,
                         lv_seen_ref.

                  lv_current_kind = lv_temp_uc.
                  CONTINUE.
                ENDIF.

                IF lv_temp_uc = 'VALUE'.
                  CLEAR ls_param.
                  ls_param-method_name   = lv_name.
                  ls_param-param_type    = lv_current_kind.
                  ls_param-pass_by_value = 'X'.
                  lv_expect_value_name   = abap_true.
                  CONTINUE.
                ENDIF.

                IF lv_expect_value_name = abap_true.
                  IF lv_temp_uc = '(' OR lv_temp_uc = ')'.
                    CONTINUE.
                  ENDIF.
                  ls_param-method_name = lv_name.
                  ls_param-param_type  = lv_current_kind.
                  ls_param-param_name  = lv_token.
                  REPLACE ALL OCCURRENCES OF '!' IN ls_param-param_name WITH ''.
                  TRANSLATE ls_param-param_name TO UPPER CASE.
                  CONDENSE ls_param-param_name NO-GAPS.
                  lv_expect_value_name = abap_false.
                  CONTINUE.
                ENDIF.

                IF lv_temp_uc = 'TYPE'.
                  ls_param-typing_method = 'TYPE'.
                  lv_expect_type_name = abap_true.
                  lv_expect_ref_to    = abap_false.
                  lv_seen_ref         = abap_false.
                  CONTINUE.
                ENDIF.

                IF lv_temp_uc = 'LIKE'.
                  ls_param-typing_method = 'LIKE'.
                  lv_expect_type_name = abap_true.
                  lv_expect_ref_to    = abap_false.
                  lv_seen_ref         = abap_false.
                  CONTINUE.
                ENDIF.

                IF lv_expect_type_name = abap_true.

                  IF ls_param-typing_method = 'TYPE' AND lv_temp_uc = 'REF'.
                    lv_expect_ref_to = abap_true.
                    lv_seen_ref      = abap_true.
                    CONTINUE.
                  ENDIF.

                  IF lv_expect_ref_to = abap_true AND lv_temp_uc = 'TO'.
                    CONTINUE.
                  ENDIF.

                  IF lv_seen_ref = abap_true.
                    ls_param-typing_method = 'TYPE REF TO'.
                    CONCATENATE 'REF TO' lv_token
                      INTO ls_param-associated_type
                      SEPARATED BY space.
                  ELSE.
                    ls_param-associated_type = lv_token.
                  ENDIF.

                  lv_expect_type_name = abap_false.
                  lv_expect_ref_to    = abap_false.
                  lv_seen_ref         = abap_false.
                  CONTINUE.
                ENDIF.

                IF lv_temp_uc = 'OPTIONAL'.
                  ls_param-optional = 'X'.
                  CONTINUE.
                ENDIF.

                IF lv_temp_uc = 'DEFAULT'.
                  lv_expect_default = abap_true.
                  CONTINUE.
                ENDIF.

                IF lv_expect_default = abap_true.
                  ls_param-param_default_value = lv_token.
                  lv_expect_default = abap_false.
                  CONTINUE.
                ENDIF.

                IF lv_temp_uc = '(' OR lv_temp_uc = ')' OR lv_temp_uc = '.'.
                  CONTINUE.
                ENDIF.

                IF lv_current_kind IS NOT INITIAL.
                  IF ls_param-param_name IS NOT INITIAL
                     AND ( ls_param-associated_type IS NOT INITIAL
                        OR ls_param-typing_method IS NOT INITIAL ).

                    IF ls_param-method_name IS INITIAL.
                      ls_param-method_name = lv_name.
                    ENDIF.
                    IF ls_param-param_type IS INITIAL.
                      ls_param-param_type = lv_current_kind.
                    ENDIF.
                    IF ls_param-typing_method IS INITIAL.
                      ls_param-typing_method = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-associated_type IS INITIAL.
                      ls_param-associated_type = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-param_default_value IS INITIAL.
                      ls_param-param_default_value = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-param_description IS INITIAL.
                      ls_param-param_description = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-optional IS INITIAL.
                      ls_param-optional = gc_export-kw_na.
                    ENDIF.
                    IF ls_param-pass_by_value IS INITIAL.
                      ls_param-pass_by_value = gc_export-kw_na.
                    ENDIF.

                    READ TABLE ch_layout-method_params TRANSPORTING NO FIELDS
                      WITH KEY method_name = ls_param-method_name
                               param_name  = ls_param-param_name
                               param_type  = ls_param-param_type.
                    IF sy-subrc <> 0.
                      APPEND ls_param TO ch_layout-method_params.
                    ENDIF.

                    CLEAR ls_param.
                  ENDIF.

                  IF ls_param-param_name IS INITIAL.
                    ls_param-method_name = lv_name.
                    ls_param-param_type  = lv_current_kind.
                    ls_param-param_name  = lv_token.
                    REPLACE ALL OCCURRENCES OF '!' IN ls_param-param_name WITH ''.
                    TRANSLATE ls_param-param_name TO UPPER CASE.
                    CONDENSE ls_param-param_name NO-GAPS.
                    CONTINUE.
                  ENDIF.
                ENDIF.

              ENDLOOP.

              IF ls_param-param_name IS NOT INITIAL.
                IF ls_param-method_name IS INITIAL.
                  ls_param-method_name = lv_name.
                ENDIF.
                IF ls_param-param_type IS INITIAL.
                  ls_param-param_type = gc_export-kw_na.
                ENDIF.
                IF ls_param-typing_method IS INITIAL.
                  ls_param-typing_method = gc_export-kw_na.
                ENDIF.
                IF ls_param-associated_type IS INITIAL.
                  ls_param-associated_type = gc_export-kw_na.
                ENDIF.
                IF ls_param-param_default_value IS INITIAL.
                  ls_param-param_default_value = gc_export-kw_na.
                ENDIF.
                IF ls_param-param_description IS INITIAL.
                  ls_param-param_description = gc_export-kw_na.
                ENDIF.
                IF ls_param-optional IS INITIAL.
                  ls_param-optional = gc_export-kw_na.
                ENDIF.
                IF ls_param-pass_by_value IS INITIAL.
                  ls_param-pass_by_value = gc_export-kw_na.
                ENDIF.

                READ TABLE ch_layout-method_params TRANSPORTING NO FIELDS
                  WITH KEY method_name = ls_param-method_name
                           param_name  = ls_param-param_name
                           param_type  = ls_param-param_type.
                IF sy-subrc <> 0.
                  APPEND ls_param TO ch_layout-method_params.
                ENDIF.
                CLEAR ls_param.
              ENDIF.

            ENDLOOP.
          ENDIF.

          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        CLEAR lv_stmt.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


METHOD fill_data_element.

    DATA: lt_rollnames    TYPE gty_t_de_rollnames,
          lt_source       TYPE string_table,
          lt_sources      TYPE STANDARD TABLE OF zcl_program_fetch=>gty_program_source,
          ls_source       TYPE zcl_program_fetch=>gty_program_source,
          lt_fms          TYPE STANDARD TABLE OF rs38l-name WITH EMPTY KEY,
          lv_func_name    TYPE rs38l-name,
          lv_prog_name    TYPE progname,
          lv_fugr_name    TYPE rs38l-area,
          lv_class_name   TYPE seoclsname,
          lt_class_source TYPE zcl_program_fetch=>gty_t_class_source,
          ls_class_source TYPE zcl_program_fetch=>gty_class_source,
          lt_seen_prog    TYPE gty_t_seen_prog,
          lt_seen_type    TYPE gty_t_seen_type,
          lv_src_idx     TYPE sy-tabix.

    me->ensure_objects( ).

    CASE iv_objtype.

      WHEN gc_export-kw_obj_prog.

        lv_prog_name = iv_objname.
        TRANSLATE lv_prog_name TO UPPER CASE.
        CONDENSE lv_prog_name NO-GAPS.

        INSERT lv_prog_name INTO TABLE lt_seen_prog.

        lt_source = me->go_fetch->get_source_code(
          iv_name = lv_prog_name
        ).

        me->collect_from_source(
          EXPORTING
            it_source     = lt_source
            iv_follow_inc = abap_true
          CHANGING
            ct_rollnames  = lt_rollnames
            ct_seen_prog  = lt_seen_prog
            ct_seen_type  = lt_seen_type
        ).

      WHEN gc_export-kw_obj_func.

        lv_func_name = iv_objname.
        TRANSLATE lv_func_name TO UPPER CASE.
        CONDENSE lv_func_name NO-GAPS.

        lt_sources = me->go_fetch->get_function_module(
          iv_funcname = lv_func_name
        ).

        lv_src_idx = 1.
        WHILE lv_src_idx <= lines( lt_sources ).

          READ TABLE lt_sources INTO ls_source INDEX lv_src_idx.

          IF sy-subrc = 0 AND ls_source-source_code IS NOT INITIAL.
            me->collect_from_source(
              EXPORTING
                it_source    = ls_source-source_code
              CHANGING
                ct_rollnames = lt_rollnames
                ct_seen_prog = lt_seen_prog
                ct_seen_type = lt_seen_type
            ).
          ENDIF.

          lv_src_idx = lv_src_idx + 1.

        ENDWHILE.

        me->collect_from_meta(
          EXPORTING
            iv_objtype   = gc_export-kw_obj_func
            iv_objname   = CONV sobj_name( lv_func_name )
          CHANGING
            ct_rollnames = lt_rollnames
            ct_seen_type = lt_seen_type
        ).

      WHEN gc_export-kw_obj_fugr.

        lv_fugr_name = iv_objname.
        TRANSLATE lv_fugr_name TO UPPER CASE.
        CONDENSE lv_fugr_name NO-GAPS.

        SELECT funcname
          FROM enlfdir
          INTO TABLE @lt_fms
          WHERE area = @lv_fugr_name.

        LOOP AT lt_fms INTO lv_func_name.

          lt_sources = me->go_fetch->get_function_module(
            iv_funcname = lv_func_name
          ).

        lv_src_idx = 1.
        WHILE lv_src_idx <= lines( lt_sources ).

          READ TABLE lt_sources INTO ls_source INDEX lv_src_idx.

          IF sy-subrc = 0 AND ls_source-source_code IS NOT INITIAL.
            me->collect_from_source(
              EXPORTING
                it_source    = ls_source-source_code
              CHANGING
                ct_rollnames = lt_rollnames
                ct_seen_prog = lt_seen_prog
                ct_seen_type = lt_seen_type
            ).
          ENDIF.

          lv_src_idx = lv_src_idx + 1.

        ENDWHILE.

          me->collect_from_meta(
            EXPORTING
              iv_objtype   = gc_export-kw_obj_func
              iv_objname   = CONV sobj_name( lv_func_name )
            CHANGING
              ct_rollnames = lt_rollnames
              ct_seen_type = lt_seen_type
          ).

        ENDLOOP.

      WHEN gc_export-kw_obj_clas.

        lv_class_name = iv_objname.
        TRANSLATE lv_class_name TO UPPER CASE.
        CONDENSE lv_class_name NO-GAPS.

        lt_class_source = me->go_fetch->get_class(
          iv_class_name = lv_class_name
        ).

        LOOP AT lt_class_source INTO ls_class_source.  " Duyệt qua bảng class source mà không lặp lồng nhau
          IF ls_class_source-source_code IS NOT INITIAL.
            me->collect_from_source(
              EXPORTING
                it_source    = ls_class_source-source_code
              CHANGING
                ct_rollnames = lt_rollnames
                ct_seen_prog = lt_seen_prog
                ct_seen_type = lt_seen_type
            ).
          ENDIF.
        ENDLOOP.

        me->collect_from_meta(
          EXPORTING
            iv_objtype   = gc_export-kw_obj_clas
            iv_objname   = CONV sobj_name( lv_class_name )
          CHANGING
            ct_rollnames = lt_rollnames
            ct_seen_type = lt_seen_type
        ).

      WHEN OTHERS.
        RETURN.

    ENDCASE.

    rt_data_element = me->de_build_rows( lt_rollnames ).

  ENDMETHOD.


  METHOD fill_overview.
    CLEAR re_overview.

    " A. Document Info
    re_overview-parameter01 = |{ sy-datum DATE = USER }|.
    re_overview-parameter02 = sy-uname.

    IF iv_version IS NOT INITIAL.
      re_overview-parameter03 = iv_version.
    ELSE.
      re_overview-parameter03 = gc_export-kw_na.
    ENDIF.

    " B. Object General Info
    IF iv_objtype IS NOT INITIAL.
      re_overview-parameter04 = iv_objtype.
    ELSE.
      re_overview-parameter04 = gc_export-kw_na.
    ENDIF.

    IF iv_objname IS NOT INITIAL.
      re_overview-parameter05 = iv_objname.
    ELSE.
      re_overview-parameter05 = gc_export-kw_na.
    ENDIF.

    IF IV_description IS NOT INITIAL.
      re_overview-parameter06 = IV_description.
    ELSE.
      re_overview-parameter06 = gc_export-kw_na.
    ENDIF.

    IF iv_package IS NOT INITIAL.
      re_overview-parameter07 = iv_package.
    ELSE.
      re_overview-parameter07 = gc_export-kw_na.
    ENDIF.

    IF iv_status IS NOT INITIAL.
      re_overview-parameter08 = iv_status.
    ELSE.
      re_overview-parameter08 = gc_export-kw_na.
    ENDIF.

    " C. Technical Info
    IF iv_created_by IS NOT INITIAL.
      re_overview-parameter09 = iv_created_by.
    ELSE.
      re_overview-parameter09 = gc_export-kw_na.
    ENDIF.

    IF iv_created_on IS NOT INITIAL.
      re_overview-parameter10 = |{ iv_created_on DATE = USER }|.
    ELSE.
      re_overview-parameter10 = gc_export-kw_na.
    ENDIF.

    IF iv_changed_on IS NOT INITIAL.
      re_overview-parameter11 = |{ iv_changed_on DATE = USER }|.
    ELSE.
      re_overview-parameter11 = gc_export-kw_na.
    ENDIF.

    IF iv_changed_by IS NOT INITIAL.
      re_overview-parameter12 = iv_changed_by.
    ELSE.
      re_overview-parameter12 = gc_export-kw_na.
    ENDIF.

    IF iv_trkorr IS NOT INITIAL.
      re_overview-parameter14 = iv_trkorr.
    ELSE.
      re_overview-parameter14 = gc_export-kw_na.
    ENDIF.

    IF iv_tcode IS NOT INITIAL.
      re_overview-parameter15 = iv_tcode.
    ELSE.
      re_overview-parameter15 = gc_export-kw_na.
    ENDIF.
    " T-Code
    CASE iv_objtype.
      WHEN 'PROG' OR 'PROGRAM' OR 'REPS'.
        IF sy-tcode IS NOT INITIAL.
          re_overview-parameter15 = sy-tcode.
        ELSE.
          re_overview-parameter15 = gc_export-kw_na.
        ENDIF.

      WHEN 'CLAS' OR 'FUGR' OR 'FUNC' OR 'FM' OR 'METHOD'.
        re_overview-parameter15 = gc_export-kw_na.

      WHEN OTHERS.
        re_overview-parameter15 = gc_export-kw_na.
    ENDCASE.

  ENDMETHOD.


  METHOD fill_screen_layout.

    DATA: lt_sources             TYPE gty_t_program_source,
          ls_source              TYPE ty_program_source,
          lv_line                TYPE string,
          lv_line_uc             TYPE string,
          lv_stmt                TYPE string,
          lv_stmt_uc             TYPE string,
          lv_part                TYPE string,
          lv_part_uc             TYPE string,
          lv_body                TYPE string,
          lv_name                TYPE string,
          lv_type                TYPE string,
          lv_default             TYPE string,
          lv_msgtxt              TYPE string,
          lv_msgtype             TYPE string,
          lv_desc                TYPE string,
          lv_button              TYPE string,
          lv_len                 TYPE i,
          lv_offset              TYPE i,
          lv_newlen              TYPE i,
          lv_lastchr             TYPE c LENGTH 1,
          lv_numstr1             TYPE string,
          lv_numstr2             TYPE string,
          lv_tabname             TYPE tabname,
          lv_fieldname           TYPE fieldname,
          lv_ddic_len            TYPE dd03l-leng,
          lv_current_row         TYPE i VALUE 0,
          lv_pending_pos         TYPE i VALUE 0,
          lv_comment_pos         TYPE i VALUE 0,
          lv_comment_len         TYPE i VALUE 0,
          lv_field_col           TYPE i VALUE 0,
          lv_field_len           TYPE i VALUE 0,
          lv_in_validation_block TYPE abap_bool VALUE abap_false,
          lv_in_line             TYPE abap_bool VALUE abap_false.

    DATA: lt_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    DATA: ls_input  TYPE zst_scr_input,
          ls_visual TYPE zst_scr_visual,
          ls_msg    TYPE zst_scr_msg,
          ls_btn    TYPE zst_scr_btn.

    CLEAR ch_screen_layout.

    IF go_fetch IS INITIAL.
      CREATE OBJECT go_fetch.
    ENDIF.

    lt_sources = go_fetch->get_program_source( im_program_name ).

    LOOP AT lt_sources INTO ls_source.
      CLEAR lv_stmt.

      LOOP AT ls_source-source_code INTO lv_line.

        lv_line_uc = lv_line.
        TRANSLATE lv_line_uc TO UPPER CASE.
        CONDENSE lv_line_uc.

        "------------------------------------------
        " Track validation block by LINE
        "------------------------------------------
        IF lv_line_uc = 'AT SELECTION-SCREEN.'.
          lv_in_validation_block = abap_true.
        ELSEIF lv_line_uc = 'AT SELECTION-SCREEN OUTPUT.'
            OR lv_line_uc = 'START-OF-SELECTION.'
            OR lv_line_uc = 'INITIALIZATION.'
            OR lv_line_uc = 'END-OF-SELECTION.'.
          lv_in_validation_block = abap_false.
        ENDIF.

        IF lv_stmt IS INITIAL.
          lv_stmt = lv_line.
        ELSE.
          CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
        ENDIF.

        IF lv_line NS '.'.
          CONTINUE.
        ENDIF.

        lv_stmt_uc = lv_stmt.
        TRANSLATE lv_stmt_uc TO UPPER CASE.
        CONDENSE lv_stmt_uc.
        CONDENSE lv_stmt.

        "------------------------------------------
        " Visual layout state
        "------------------------------------------
        IF lv_stmt_uc CP 'SELECTION-SCREEN BEGIN OF BLOCK *'.
          lv_current_row = lv_current_row + 1.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        IF lv_stmt_uc = 'SELECTION-SCREEN BEGIN OF LINE.'.
          lv_in_line = abap_true.
          lv_current_row = lv_current_row + 1.
          CLEAR: lv_pending_pos, lv_comment_pos, lv_comment_len.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        IF lv_stmt_uc = 'SELECTION-SCREEN END OF LINE.'.
          lv_in_line = abap_false.
          CLEAR: lv_pending_pos, lv_comment_pos, lv_comment_len.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        IF lv_stmt_uc CP 'SELECTION-SCREEN POSITION *'.
          CLEAR lv_numstr1.
          FIND PCRE 'POSITION\s+([0-9]+)' IN lv_stmt_uc SUBMATCHES lv_numstr1.
          IF lv_numstr1 IS NOT INITIAL.
            lv_pending_pos = lv_numstr1.
          ENDIF.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        IF lv_stmt_uc CP 'SELECTION-SCREEN COMMENT *'.
          CLEAR: lv_numstr1, lv_numstr2.
          FIND PCRE 'COMMENT\s+([0-9]+)\(([0-9]+)\)' IN lv_stmt_uc
            SUBMATCHES lv_numstr1 lv_numstr2.
          IF lv_numstr1 IS NOT INITIAL.
            lv_comment_pos = lv_numstr1.
          ENDIF.
          IF lv_numstr2 IS NOT INITIAL.
            lv_comment_len = lv_numstr2.
          ENDIF.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        "------------------------------------------
        " A. PARAMETERS
        "------------------------------------------
        IF lv_stmt_uc CP 'PARAMETERS:*' OR lv_stmt_uc CP 'PARAMETERS *'.

          lv_body = lv_stmt.
          REPLACE FIRST OCCURRENCE OF PCRE '^\s*PARAMETERS\s*:?\s*'
            IN lv_body WITH ''.

          lv_len = strlen( lv_body ).
          IF lv_len > 0.
            lv_offset = lv_len - 1.
            lv_lastchr = lv_body+lv_offset(1).
            IF lv_lastchr = '.'.
              lv_newlen = lv_len - 1.
              lv_body = lv_body(lv_newlen).
            ENDIF.
          ENDIF.

          CLEAR lt_parts.
          SPLIT lv_body AT ',' INTO TABLE lt_parts.

          LOOP AT lt_parts INTO lv_part.
            CLEAR: ls_input, ls_visual,
                   lv_name, lv_type, lv_default, lv_desc,
                   lv_field_col, lv_field_len, lv_ddic_len,
                   lv_tabname, lv_fieldname, lv_numstr1.

            CONDENSE lv_part.
            IF lv_part IS INITIAL.
              CONTINUE.
            ENDIF.

            lv_part_uc = lv_part.
            TRANSLATE lv_part_uc TO UPPER CASE.
            CONDENSE lv_part_uc.

            FIND PCRE '^\s*([A-Z0-9_]+)' IN lv_part_uc SUBMATCHES lv_name.
            IF lv_name IS INITIAL.
              CONTINUE.
            ENDIF.

            CLEAR lv_type.
            FIND PCRE '\bTYPE\s+([A-Z0-9_\-]+)' IN lv_part_uc SUBMATCHES lv_type.

            IF lv_type IS INITIAL AND lv_part_uc CS 'AS CHECKBOX'.
              lv_type = 'CHECKBOX'.
            ENDIF.

            IF lv_type IS INITIAL AND lv_part_uc CS 'AS LISTBOX'.
              lv_type = 'LISTBOX'.
            ENDIF.

            IF lv_type IS INITIAL.
              lv_type = 'PARAMETER'.
            ENDIF.

            CLEAR lv_default.
            FIND PCRE '\bDEFAULT\s+(''[^'']*''|\S+)' IN lv_part
              SUBMATCHES lv_default.

            CLEAR ls_input.
            ls_input-name = lv_name.
            ls_input-type_name = lv_type.

            IF lv_part_uc CS 'OBLIGATORY'.
              ls_input-required = 'Yes'.
            ELSE.
              ls_input-required = 'No'.
            ENDIF.

            ls_input-single_multiple = 'Single'.
            ls_input-multiple        = 'No'.
            ls_input-interval        = 'No'.
            ls_input-extend          = 'No'.
            ls_input-default_value   = lv_default.
            ls_input-description     = ''.

            APPEND ls_input TO ch_screen_layout-input_rows.

            "------------------------------------------
            " Visual: Row / Column / Length
            "------------------------------------------
            CLEAR ls_visual.
            ls_visual-field_name = lv_name.

            IF lv_in_line = abap_true.
              ls_visual-row_no = lv_current_row.
            ELSE.
              lv_current_row = lv_current_row + 1.
              ls_visual-row_no = lv_current_row.
            ENDIF.

            " Column heuristic
            IF lv_in_line = abap_true.
              IF lv_pending_pos > 0.
                IF lv_comment_len > 0.
                  lv_field_col = lv_pending_pos + lv_comment_len.
                ELSE.
                  lv_field_col = lv_pending_pos.
                ENDIF.
              ELSEIF lv_comment_pos > 0.
                lv_field_col = lv_comment_pos + lv_comment_len.
              ELSE.
                lv_field_col = 1.
              ENDIF.
            ELSE.
              lv_field_col = 1.
            ENDIF.
            ls_visual-col_no = lv_field_col.

            " Length heuristic
            IF lv_part_uc CS 'AS CHECKBOX'.
              lv_field_len = 1.
            ELSE.
              CLEAR lv_numstr1.
              FIND PCRE '\bTYPE\s+CHAR([0-9]+)' IN lv_part_uc SUBMATCHES lv_numstr1.
              IF lv_numstr1 IS NOT INITIAL.
                lv_field_len = lv_numstr1.
              ELSE.
                CLEAR lv_ddic_len.
                IF lv_type CP '*-*'.
                  SPLIT lv_type AT '-' INTO lv_tabname lv_fieldname.
                  IF lv_tabname = 'SY' AND lv_fieldname = 'DATUM'.
                    lv_ddic_len = 8.
                  ELSE.
                    SELECT SINGLE leng
                      INTO @lv_ddic_len
                      FROM dd03l
                      WHERE tabname   = @lv_tabname
                        AND fieldname = @lv_fieldname
                        AND as4local  = 'A'.
                  ENDIF.
                ELSE.
                  SELECT SINGLE leng
                    INTO @lv_ddic_len
                    FROM dd04l
                    WHERE rollname  = @lv_type
                      AND as4local  = 'A'
                      AND as4vers   = '0000'.
                ENDIF.
                lv_field_len = lv_ddic_len.
              ENDIF.
            ENDIF.

            IF lv_field_len > 0.
              ls_visual-length = lv_field_len.
            ELSE.
              ls_visual-length = ''.
            ENDIF.

            IF lv_part_uc CS 'NO-DISPLAY'.
              ls_visual-visible = 'No'.
            ELSE.
              ls_visual-visible = 'Yes'.
            ENDIF.

            ls_visual-editable = 'Yes'.

            APPEND ls_visual TO ch_screen_layout-visual_rows.

            IF lv_in_line = abap_true.
              CLEAR: lv_pending_pos, lv_comment_pos, lv_comment_len.
            ENDIF.
          ENDLOOP.

          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        "------------------------------------------
        " A. SELECT-OPTIONS
        "------------------------------------------
        IF lv_stmt_uc CP 'SELECT-OPTIONS:*' OR lv_stmt_uc CP 'SELECT-OPTIONS *'.

          lv_body = lv_stmt.
          REPLACE FIRST OCCURRENCE OF PCRE '^\s*SELECT-OPTIONS\s*:?\s*'
            IN lv_body WITH ''.

          lv_len = strlen( lv_body ).
          IF lv_len > 0.
            lv_offset = lv_len - 1.
            lv_lastchr = lv_body+lv_offset(1).
            IF lv_lastchr = '.'.
              lv_newlen = lv_len - 1.
              lv_body = lv_body(lv_newlen).
            ENDIF.
          ENDIF.

          CLEAR lt_parts.
          SPLIT lv_body AT ',' INTO TABLE lt_parts.

          LOOP AT lt_parts INTO lv_part.
            CLEAR: ls_input, ls_visual,
                   lv_name, lv_type, lv_default,
                   lv_field_col, lv_field_len, lv_ddic_len,
                   lv_tabname, lv_fieldname.

            CONDENSE lv_part.
            IF lv_part IS INITIAL.
              CONTINUE.
            ENDIF.

            lv_part_uc = lv_part.
            TRANSLATE lv_part_uc TO UPPER CASE.
            CONDENSE lv_part_uc.

            FIND PCRE '^\s*([A-Z0-9_]+)' IN lv_part_uc SUBMATCHES lv_name.
            IF lv_name IS INITIAL.
              CONTINUE.
            ENDIF.

            CLEAR lv_type.
            FIND PCRE '\bFOR\s+([A-Z0-9_\-]+)' IN lv_part_uc SUBMATCHES lv_type.
            IF lv_type IS INITIAL.
              lv_type = 'SELECT-OPTION'.
            ENDIF.

            CLEAR ls_input.
            ls_input-name = lv_name.
            ls_input-type_name = lv_type.

            IF lv_part_uc CS 'OBLIGATORY'.
              ls_input-required = 'Yes'.
            ELSE.
              ls_input-required = 'No'.
            ENDIF.

            ls_input-single_multiple = 'Multiple'.
            ls_input-multiple        = 'Yes'.

            IF lv_part_uc CS 'NO INTERVALS' OR lv_part_uc CS 'NO-INTERVALS'.
              ls_input-interval = 'No'.
            ELSE.
              ls_input-interval = 'Yes'.
            ENDIF.

            IF lv_part_uc CS 'NO-EXTENSION' OR lv_part_uc CS 'NO EXTENSION'.
              ls_input-extend = 'No'.
            ELSE.
              ls_input-extend = 'Yes'.
            ENDIF.

            ls_input-default_value = ''.
            ls_input-description   = ''.

            APPEND ls_input TO ch_screen_layout-input_rows.

            CLEAR ls_visual.
            ls_visual-field_name = lv_name.

            IF lv_in_line = abap_true.
              ls_visual-row_no = lv_current_row.
            ELSE.
              lv_current_row = lv_current_row + 1.
              ls_visual-row_no = lv_current_row.
            ENDIF.

            IF lv_in_line = abap_true.
              IF lv_pending_pos > 0.
                IF lv_comment_len > 0.
                  lv_field_col = lv_pending_pos + lv_comment_len.
                ELSE.
                  lv_field_col = lv_pending_pos.
                ENDIF.
              ELSEIF lv_comment_pos > 0.
                lv_field_col = lv_comment_pos + lv_comment_len.
              ELSE.
                lv_field_col = 1.
              ENDIF.
            ELSE.
              lv_field_col = 1.
            ENDIF.
            ls_visual-col_no = lv_field_col.

            CLEAR lv_ddic_len.
            IF lv_type CP '*-*'.
              SPLIT lv_type AT '-' INTO lv_tabname lv_fieldname.
              IF lv_tabname = 'SY' AND lv_fieldname = 'DATUM'.
                lv_ddic_len = 8.
              ELSE.
                SELECT SINGLE leng
                  INTO @lv_ddic_len
                  FROM dd03l
                  WHERE tabname   = @lv_tabname
                    AND fieldname = @lv_fieldname
                    AND as4local  = 'A'.
              ENDIF.
            ELSE.
              SELECT SINGLE leng
                INTO @lv_ddic_len
                FROM dd04l
                WHERE rollname  = @lv_type
                  AND as4local  = 'A'
                  AND as4vers   = '0000'.
            ENDIF.

            lv_field_len = lv_ddic_len.
            IF lv_field_len > 0.
              ls_visual-length = lv_field_len.
            ELSE.
              ls_visual-length = ''.
            ENDIF.

            IF lv_part_uc CS 'NO-DISPLAY'.
              ls_visual-visible = 'No'.
            ELSE.
              ls_visual-visible = 'Yes'.
            ENDIF.

            ls_visual-editable = 'Yes'.

            APPEND ls_visual TO ch_screen_layout-visual_rows.

            IF lv_in_line = abap_true.
              CLEAR: lv_pending_pos, lv_comment_pos, lv_comment_len.
            ENDIF.
          ENDLOOP.

          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        "------------------------------------------
        " D. PUSHBUTTON
        "------------------------------------------
        IF lv_stmt_uc CP 'SELECTION-SCREEN PUSHBUTTON *'.

          CLEAR: ls_btn, lv_button, lv_desc.

          FIND PCRE 'PUSHBUTTON\s+[^()]*\(([^)]*)\)' IN lv_stmt_uc
            SUBMATCHES lv_button.
          FIND PCRE '''([^'']+)''' IN lv_stmt
            SUBMATCHES lv_desc.

          ls_btn-button      = lv_button.
          ls_btn-description = lv_desc.
          ls_btn-action      = 'AT SELECTION-SCREEN / USER-COMMAND'.

          APPEND ls_btn TO ch_screen_layout-button_rows.

          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        "------------------------------------------
        " C. MESSAGE / VALIDATION
        "------------------------------------------
        IF lv_in_validation_block = abap_true AND lv_stmt_uc CS 'MESSAGE '.

          CLEAR: ls_msg, lv_msgtype, lv_msgtxt.

          FIND PCRE 'MESSAGE\s+([EWIASX])([0-9]{3})?' IN lv_stmt_uc
            SUBMATCHES lv_msgtype.

          IF lv_msgtype IS INITIAL.
            FIND PCRE 'TYPE\s+''([EWIASX])''' IN lv_stmt_uc
              SUBMATCHES lv_msgtype.
          ENDIF.

          CLEAR lv_msgtxt.
          FIND PCRE '''([^'']+)''' IN lv_stmt
            SUBMATCHES lv_msgtxt.

          IF lv_msgtxt IS INITIAL.
            lv_msgtxt = lv_stmt.
          ENDIF.

          CLEAR ls_msg.
          ls_msg-msg_type  = lv_msgtype.
          ls_msg-msg_text  = lv_msgtxt.
          ls_msg-condition = 'AT SELECTION-SCREEN validation'.

          APPEND ls_msg TO ch_screen_layout-message_rows.

          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        CLEAR lv_stmt.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD fill_table.

    DATA: lt_tab_hits     TYPE gty_t_tab_hits,
          lt_source       TYPE string_table,
          lt_sources      TYPE gty_t_program_source,
          ls_source       TYPE ty_program_source,
          lt_class_source TYPE tt_class_source,
          ls_class_source TYPE ty_class_source,
          lv_prog_name    TYPE progname,
          lv_func_name    TYPE rs38l-name,
          lv_class_name   TYPE seoclsname.

    me->ensure_objects( ).

    CASE iv_objtype.

      WHEN gc_export-kw_obj_prog.

        lv_prog_name = iv_objname.
        TRANSLATE lv_prog_name TO UPPER CASE.
        CONDENSE lv_prog_name NO-GAPS.

        lt_source = me->go_fetch->get_source_code(
          iv_name = lv_prog_name
        ).

        me->collect_table_from_source(
          EXPORTING
            it_source   = lt_source
          CHANGING
            ct_tab_hits = lt_tab_hits
        ).

      WHEN gc_export-kw_obj_func.

        lv_func_name = iv_objname.
        TRANSLATE lv_func_name TO UPPER CASE.
        CONDENSE lv_func_name NO-GAPS.

        lt_sources = me->go_fetch->get_function_module(
          iv_funcname = lv_func_name
        ).

        LOOP AT lt_sources INTO ls_source.
          IF ls_source-source_code IS NOT INITIAL.
            me->collect_table_from_source(
              EXPORTING
                it_source   = ls_source-source_code
              CHANGING
                ct_tab_hits = lt_tab_hits
            ).
          ENDIF.
        ENDLOOP.

      WHEN gc_export-kw_obj_clas.

        lv_class_name = iv_objname.
        TRANSLATE lv_class_name TO UPPER CASE.
        CONDENSE lv_class_name NO-GAPS.

        lt_class_source = me->go_fetch->get_class(
          iv_class_name = lv_class_name
        ).

        LOOP AT lt_class_source INTO ls_class_source.
          IF ls_class_source-source_code IS NOT INITIAL.
            me->collect_table_from_source(
              EXPORTING
                it_source   = ls_class_source-source_code
              CHANGING
                ct_tab_hits = lt_tab_hits
            ).
          ENDIF.
        ENDLOOP.

      WHEN OTHERS.
        RETURN.

    ENDCASE.

    rt_table = me->build_table_rows( lt_tab_hits ).

  ENDMETHOD.


  METHOD is_valid_table_name.

    rv_ok = abap_false.

    IF iv_tabname IS INITIAL.
      RETURN.
    ENDIF.

    IF iv_tabname = gc_abap_token-select
     OR iv_tabname = gc_abap_token-update
     OR iv_tabname = gc_abap_token-delete
     OR iv_tabname = gc_abap_token-modify
     OR iv_tabname = gc_abap_token-insert
     OR iv_tabname = gc_abap_token-join
     OR iv_tabname = gc_abap_token-from
     OR iv_tabname = gc_abap_token-where
     OR iv_tabname = gc_abap_token-into.

      RETURN.

    ENDIF.

    IF iv_tabname CP 'LT_*'
       OR iv_tabname CP 'LS_*'
       OR iv_tabname CP 'LV_*'
       OR iv_tabname CP 'GT_*'
       OR iv_tabname CP 'GS_*'
       OR iv_tabname CP 'TY_*'
       OR iv_tabname CP '@LT_*'
       OR iv_tabname CP '@GT_*'
       OR iv_tabname CP '@DATA*'.

      RETURN.

    ENDIF.

    rv_ok = abap_true.

  ENDMETHOD.


  METHOD normalize_class_layout.

    DATA: ls_param TYPE zst_src_class_param.

    FIELD-SYMBOLS: <ls_attr> TYPE zst_src_class_attr,
                   <ls_meth> TYPE zst_src_class_meth.

    SORT ch_layout-attributes BY attr_name attr_section attr_level.
    DELETE ADJACENT DUPLICATES FROM ch_layout-attributes
      COMPARING attr_name attr_section attr_level.

    SORT ch_layout-methods BY method_name visibility method_level.
    DELETE ADJACENT DUPLICATES FROM ch_layout-methods
      COMPARING method_name visibility method_level.

    SORT ch_layout-method_params BY method_name param_name param_type.
    DELETE ADJACENT DUPLICATES FROM ch_layout-method_params
      COMPARING method_name param_name param_type.

    LOOP AT ch_layout-attributes ASSIGNING <ls_attr>.
      IF <ls_attr>-attr_section IS INITIAL.
        <ls_attr>-attr_section = gc_export-kw_na.
      ENDIF.
      IF <ls_attr>-attr_level IS INITIAL.
        <ls_attr>-attr_level = gc_export-kw_na.
      ENDIF.
      IF <ls_attr>-type_name IS INITIAL.
        <ls_attr>-type_name = gc_export-kw_na.
      ENDIF.
      IF <ls_attr>-read_only IS INITIAL.
        <ls_attr>-read_only = gc_export-kw_na.
      ENDIF.
      IF <ls_attr>-default_value IS INITIAL.
        <ls_attr>-default_value = gc_export-kw_na.
      ENDIF.
      IF <ls_attr>-attr_description IS INITIAL.
        <ls_attr>-attr_description = gc_export-kw_na.
      ENDIF.
    ENDLOOP.

    LOOP AT ch_layout-methods ASSIGNING <ls_meth>.
      IF <ls_meth>-method_level IS INITIAL.
        <ls_meth>-method_level = gc_export-kw_na.
      ENDIF.
      IF <ls_meth>-visibility IS INITIAL.
        <ls_meth>-visibility = gc_export-kw_na.
      ENDIF.
      IF <ls_meth>-method_type IS INITIAL.
        <ls_meth>-method_type = gc_export-kw_na.
      ENDIF.
      IF <ls_meth>-method_description IS INITIAL.
        <ls_meth>-method_description = gc_export-kw_na.
      ENDIF.
    ENDLOOP.

    LOOP AT ch_layout-method_params INTO ls_param.
      IF ls_param-method_name IS INITIAL.
        ls_param-method_name = gc_export-kw_na.
      ENDIF.
      IF ls_param-param_name IS INITIAL.
        ls_param-param_name = gc_export-kw_na.
      ENDIF.
      IF ls_param-param_type IS INITIAL.
        ls_param-param_type = gc_export-kw_na.
      ENDIF.
      IF ls_param-pass_by_value IS INITIAL.
        ls_param-pass_by_value = gc_export-kw_na.
      ENDIF.
      IF ls_param-optional IS INITIAL.
        ls_param-optional = gc_export-kw_na.
      ENDIF.
      IF ls_param-typing_method IS INITIAL.
        ls_param-typing_method = gc_export-kw_na.
      ENDIF.
      IF ls_param-associated_type IS INITIAL.
        ls_param-associated_type = gc_export-kw_na.
      ENDIF.
      IF ls_param-param_default_value IS INITIAL.
        ls_param-param_default_value = gc_export-kw_na.
      ENDIF.
      IF ls_param-param_description IS INITIAL.
        ls_param-param_description = gc_export-kw_na.
      ENDIF.
      MODIFY ch_layout-method_params FROM ls_param.
    ENDLOOP.

    IF ch_layout-class_def-class_type IS INITIAL.
      ch_layout-class_def-class_type = gc_export-kw_na.
    ENDIF.
    IF ch_layout-class_def-create_visibility IS INITIAL.
      ch_layout-class_def-create_visibility = gc_export-kw_na.
    ENDIF.
    IF ch_layout-class_def-superclass IS INITIAL.
      ch_layout-class_def-superclass = gc_export-kw_na.
    ENDIF.
    IF ch_layout-class_def-is_final IS INITIAL.
      ch_layout-class_def-is_final = gc_export-kw_na.
    ENDIF.
    IF ch_layout-class_def-is_abstract IS INITIAL.
      ch_layout-class_def-is_abstract = gc_export-kw_na.
    ENDIF.
    IF ch_layout-class_def-interfaces IS INITIAL.
      ch_layout-class_def-interfaces = gc_export-kw_na.
    ENDIF.

  ENDMETHOD.


  METHOD resolve_ddic_type.

    TYPES: BEGIN OF lty_dd03l,
             tabname   TYPE dd03l-tabname,
             fieldname TYPE dd03l-fieldname,
             rollname  TYPE dd03l-rollname,
           END OF lty_dd03l.

    DATA: lv_name      TYPE string,
          lv_objname   TYPE ddobjname,
          lv_rollname  TYPE rollname,
          lv_tabname   TYPE dd03l-tabname,
          lv_fieldname TYPE dd03l-fieldname,
          lv_rowtype   TYPE ddobjname.

    lv_name = iv_name.
    CONDENSE lv_name NO-GAPS.
    TRANSLATE lv_name TO UPPER CASE.

    REPLACE ALL OCCURRENCES OF gc_symbol-bang  IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_symbol-comma IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_symbol-dot   IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_symbol-colon IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF ')' IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF '(' IN lv_name WITH ''.

    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.

    IF lv_name = gc_de_skip-type_i
       OR lv_name = gc_de_skip-type_c
       OR lv_name = gc_de_skip-type_n
       OR lv_name = gc_de_skip-type_p
       OR lv_name = gc_de_skip-type_f
       OR lv_name = gc_de_skip-type_string
       OR lv_name = gc_de_skip-type_xstring
       OR lv_name = gc_de_skip-type_d
       OR lv_name = gc_de_skip-type_t
       OR lv_name = gc_de_skip-type_any
       OR lv_name = gc_de_skip-type_object
       OR lv_name CP gc_de_skip-pat_ty
       OR lv_name CP gc_de_skip-pat_lt
       OR lv_name CP gc_de_skip-pat_ls
       OR lv_name CP gc_de_skip-pat_lv
       OR lv_name CP gc_de_skip-pat_gt
       OR lv_name CP gc_de_skip-pat_gs
       OR lv_name CP gc_de_skip-pat_lo.
      RETURN.
    ENDIF.

    "1. TABLE-FIELD / STRUCTURE-FIELD
    IF lv_name CS gc_symbol-dash.

      SPLIT lv_name AT gc_symbol-dash INTO lv_tabname lv_fieldname.

      IF lv_tabname IS NOT INITIAL AND lv_fieldname IS NOT INITIAL.

        CLEAR lv_rollname.

        SELECT SINGLE rollname
          INTO @lv_rollname
          FROM dd03l
          WHERE tabname   = @lv_tabname
            AND fieldname = @lv_fieldname
            AND as4local  = @gc_ddic-as4local_active
            AND as4vers   = @gc_ddic-as4vers_active.

        IF sy-subrc = 0 AND lv_rollname IS NOT INITIAL.
          INSERT lv_rollname INTO TABLE ct_rollnames.
        ENDIF.

      ENDIF.

      RETURN.

    ENDIF.

    IF strlen( lv_name ) > 30.
      RETURN.
    ENDIF.

    lv_objname = lv_name.

    READ TABLE ct_seen_type WITH TABLE KEY table_line = lv_objname
      TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    INSERT lv_objname INTO TABLE ct_seen_type.

    "2. Data Element
    CLEAR lv_rollname.

    SELECT SINGLE rollname
      INTO @lv_rollname
      FROM dd04l
      WHERE rollname = @lv_objname
        AND as4local = @gc_ddic-as4local_active
        AND as4vers  = @gc_ddic-as4vers_active.

    IF sy-subrc = 0 AND lv_rollname IS NOT INITIAL.
      INSERT lv_rollname INTO TABLE ct_rollnames.
      RETURN.
    ENDIF.

    "3. DDIC Table Type -> Row Type
    CLEAR lv_rowtype.

    SELECT SINGLE rowtype
      INTO @lv_rowtype
      FROM dd40l
      WHERE typename = @lv_objname
        AND as4local = @gc_ddic-as4local_active.

    IF sy-subrc = 0 AND lv_rowtype IS NOT INITIAL.
      me->resolve_ddic_type(
        EXPORTING
          iv_name      = CONV string( lv_rowtype )
        CHANGING
          ct_rollnames = ct_rollnames
          ct_seen_type = ct_seen_type ).
      RETURN.
    ENDIF.

  ENDMETHOD.


  METHOD resolve_table_info.

    DATA: lv_tabclass TYPE dd02l-tabclass,
          lv_ddtext   TYPE dd02t-ddtext,
          lv_contflag TYPE dd02l-contflag.

    CLEAR: lv_tabclass, lv_ddtext, lv_contflag.

    SELECT SINGLE tabclass, contflag
      INTO (@lv_tabclass, @lv_contflag)
      FROM dd02l
      WHERE tabname  = @iv_tabname
  AND as4local = @gc_ddic-as4local_active
  AND as4vers  = @gc_ddic-as4vers_active.

    SELECT SINGLE ddtext
      INTO @lv_ddtext
      FROM dd02t
      WHERE tabname    = @iv_tabname
        AND ddlanguage = @sy-langu
        AND as4local   = 'A'
        AND as4vers    = '0000'.

    cs_row-tab_name = iv_tabname.
    cs_row-tab_des  = lv_ddtext.
    cs_row-tab_del_cls = lv_contflag.

    CASE lv_tabclass.
      WHEN gc_ddic-tabclass_transp.
        cs_row-tab_type = gc_ddic_text-transparent_table.
      WHEN gc_ddic-tabclass_view.
        cs_row-tab_type = gc_ddic_text-view.
      WHEN gc_ddic-tabclass_inttab.
        cs_row-tab_type = gc_ddic_text-internal_table.
      WHEN gc_ddic-tabclass_append.
        cs_row-tab_type = gc_ddic_text-append_structure.
      WHEN gc_ddic-tabclass_struct.
        cs_row-tab_type = gc_ddic_text-structure.
      WHEN OTHERS.
        cs_row-tab_type = lv_tabclass.
    ENDCASE.

    " Client dependent: Have field MANDT
    SELECT SINGLE fieldname
      INTO @DATA(lv_mandt)
      FROM dd03l
      WHERE tabname   = @iv_tabname
        AND fieldname = @gc_ddic-field_mandt
        AND as4local = @gc_ddic-as4local_active
  AND as4vers  = @gc_ddic-as4vers_active.

    IF sy-subrc = 0.
      cs_row-tab_cli_dep = 'X'.
    ENDIF.

  ENDMETHOD.


  METHOD build_structure_rows.

    TYPES: BEGIN OF lty_tabname,
             tabname TYPE tabname,
           END OF lty_tabname.

    TYPES: BEGIN OF lty_dd02t,
             tabname TYPE dd02t-tabname,
             ddtext  TYPE dd02t-ddtext,
           END OF lty_dd02t.

    TYPES: BEGIN OF lty_dd03l,
             tabname   TYPE dd03l-tabname,
             fieldname TYPE dd03l-fieldname,
           END OF lty_dd03l.

    TYPES: BEGIN OF lty_comp,
             tabname   TYPE tabname,
             comp_text TYPE string,
           END OF lty_comp.

    DATA: ls_hit       TYPE ty_str_hit,
          ls_row       TYPE zst_structure,
          lv_no        TYPE i,
          lv_ddtext    TYPE dd02t-ddtext,
          lv_comp_text TYPE string,
          ls_tabname   TYPE lty_tabname,
          lt_tabnames  TYPE SORTED TABLE OF lty_tabname WITH UNIQUE KEY tabname,
          lt_seen_name TYPE SORTED TABLE OF tabname WITH UNIQUE KEY table_line,
          lt_dd02t     TYPE SORTED TABLE OF lty_dd02t WITH UNIQUE KEY tabname,
          ls_dd02t     TYPE lty_dd02t,
          lt_dd03l     TYPE STANDARD TABLE OF lty_dd03l WITH EMPTY KEY,
          ls_dd03l     TYPE lty_dd03l,
          lt_comp      TYPE SORTED TABLE OF lty_comp WITH UNIQUE KEY tabname,
          ls_comp      TYPE lty_comp.

    FIELD-SYMBOLS: <ls_comp> TYPE lty_comp.

    CLEAR: rt_structure, lv_no.

    LOOP AT it_str_hits INTO ls_hit.
      IF ls_hit-str_name IS NOT INITIAL.
        ls_tabname-tabname = ls_hit-str_name.
        INSERT ls_tabname INTO TABLE lt_tabnames.
      ENDIF.
    ENDLOOP.

    IF lt_tabnames IS INITIAL.
      RETURN.
    ENDIF.

    SELECT tabname,
           ddtext
      FROM dd02t
      INTO TABLE @lt_dd02t
      FOR ALL ENTRIES IN @lt_tabnames
      WHERE tabname    = @lt_tabnames-tabname
        AND ddlanguage = @sy-langu
        AND as4local   = @gc_ddic-as4local_active
        AND as4vers    = @gc_ddic-as4vers_active.

    SELECT tabname,
           fieldname
      FROM dd03l
      INTO TABLE @lt_dd03l
      FOR ALL ENTRIES IN @lt_tabnames
      WHERE tabname   = @lt_tabnames-tabname
        AND as4local  = @gc_ddic-as4local_active
        AND as4vers   = @gc_ddic-as4vers_active
        AND fieldname NOT LIKE '.%'.

    SORT lt_dd03l BY tabname fieldname.

    LOOP AT lt_dd03l INTO ls_dd03l.

      IF ls_dd03l-fieldname IS INITIAL.
        CONTINUE.
      ENDIF.

      READ TABLE lt_comp ASSIGNING <ls_comp>
        WITH TABLE KEY tabname = ls_dd03l-tabname.

      IF sy-subrc <> 0.
        CLEAR ls_comp.
        ls_comp-tabname   = ls_dd03l-tabname.
        ls_comp-comp_text = ls_dd03l-fieldname.
        INSERT ls_comp INTO TABLE lt_comp.
      ELSE.
        CONCATENATE <ls_comp>-comp_text ls_dd03l-fieldname
          INTO <ls_comp>-comp_text
          SEPARATED BY cl_abap_char_utilities=>newline.
      ENDIF.

    ENDLOOP.

    LOOP AT it_str_hits INTO ls_hit.

      READ TABLE lt_seen_name WITH TABLE KEY table_line = ls_hit-str_name
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      INSERT ls_hit-str_name INTO TABLE lt_seen_name.

      CLEAR: ls_row, lv_ddtext, lv_comp_text, ls_dd02t, ls_comp.

      lv_no = lv_no + 1.

      READ TABLE lt_dd02t INTO ls_dd02t
        WITH TABLE KEY tabname = ls_hit-str_name.
      IF sy-subrc = 0.
        lv_ddtext = ls_dd02t-ddtext.
      ENDIF.

      READ TABLE lt_comp INTO ls_comp
        WITH TABLE KEY tabname = ls_hit-str_name.
      IF sy-subrc = 0.
        lv_comp_text = ls_comp-comp_text.
      ENDIF.

      ls_row-struc_no      = lv_no.
      ls_row-struc_name    = ls_hit-str_name.
      ls_row-struc_des     = lv_ddtext.
      ls_row-struc_usa_typ = ls_hit-usa_type.
      ls_row-struc_src     = ls_hit-src.
      ls_row-struc_comp    = lv_comp_text.

      ls_row-struc_name    = COND #( WHEN ls_row-struc_name    IS INITIAL THEN gc_export-kw_na ELSE ls_row-struc_name ).
      ls_row-struc_des     = COND #( WHEN ls_row-struc_des     IS INITIAL THEN gc_export-kw_na ELSE ls_row-struc_des ).
      ls_row-struc_usa_typ = COND #( WHEN ls_row-struc_usa_typ IS INITIAL THEN gc_export-kw_na ELSE ls_row-struc_usa_typ ).
      ls_row-struc_src     = COND #( WHEN ls_row-struc_src     IS INITIAL THEN gc_export-kw_na ELSE ls_row-struc_src ).
      ls_row-struc_comp    = COND #( WHEN ls_row-struc_comp    IS INITIAL THEN gc_export-kw_na ELSE ls_row-struc_comp ).

      APPEND ls_row TO rt_structure.

    ENDLOOP.

  ENDMETHOD.


METHOD collect_structure_from_meta.

  TYPES: BEGIN OF lty_dd40l,
           typename TYPE dd40l-typename,
           rowtype  TYPE dd40l-rowtype,
         END OF lty_dd40l.

  TYPES: BEGIN OF lty_dd02l,
           tabname  TYPE dd02l-tabname,
           tabclass TYPE dd02l-tabclass,
         END OF lty_dd02l.

  DATA: lv_tabclass TYPE dd02l-tabclass,
        lv_rowtype  TYPE dd40l-rowtype,
        lv_target   TYPE tabname,
        lv_typename TYPE dd40l-typename,
        ls_hit      TYPE ty_str_hit.

  DATA: lt_params TYPE STANDARD TABLE OF fupararef WITH EMPTY KEY,
        ls_param  TYPE fupararef.

  DATA: lt_subco TYPE STANDARD TABLE OF seosubcodf WITH EMPTY KEY,
        ls_subco TYPE seosubcodf.

  DATA: lt_typenames TYPE SORTED TABLE OF dd40l-typename WITH UNIQUE KEY table_line,
        lt_tabnames  TYPE SORTED TABLE OF dd02l-tabname WITH UNIQUE KEY table_line,
        lt_dd40l     TYPE SORTED TABLE OF lty_dd40l WITH UNIQUE KEY typename,
        ls_dd40l     TYPE lty_dd40l,
        lt_dd02l     TYPE SORTED TABLE OF lty_dd02l WITH UNIQUE KEY tabname,
        ls_dd02l     TYPE lty_dd02l.

  CASE iv_objtype.

    "========================================================
    " 1. FM parameter structure
    "========================================================
    WHEN gc_export-kw_obj_func.

      SELECT *
        INTO TABLE @lt_params
        FROM fupararef
        WHERE funcname = @iv_objname.

      LOOP AT lt_params INTO ls_param.

        IF ls_param-structure IS INITIAL.
          CONTINUE.
        ENDIF.

        lv_typename = ls_param-structure.
        CONDENSE lv_typename NO-GAPS.
        TRANSLATE lv_typename TO UPPER CASE.

        INSERT lv_typename INTO TABLE lt_typenames.

      ENDLOOP.

      IF lt_typenames IS NOT INITIAL.

        SELECT typename,
               rowtype
          FROM dd40l
          INTO TABLE @lt_dd40l
          FOR ALL ENTRIES IN @lt_typenames
          WHERE typename = @lt_typenames-table_line
            AND as4local = 'A'.

      ENDIF.

      LOOP AT lt_typenames INTO lv_typename.

        lv_target = lv_typename.

        READ TABLE lt_dd40l INTO ls_dd40l
          WITH TABLE KEY typename = lv_typename.

        IF sy-subrc = 0 AND ls_dd40l-rowtype IS NOT INITIAL.
          lv_target = ls_dd40l-rowtype.
        ENDIF.

        CONDENSE lv_target NO-GAPS.
        TRANSLATE lv_target TO UPPER CASE.

        INSERT lv_target INTO TABLE lt_tabnames.

      ENDLOOP.

      IF lt_tabnames IS NOT INITIAL.

        SELECT tabname,
               tabclass
          FROM dd02l
          INTO TABLE @lt_dd02l
          FOR ALL ENTRIES IN @lt_tabnames
          WHERE tabname  = @lt_tabnames-table_line
            AND as4local = 'A'
            AND as4vers  = '0000'.

      ENDIF.

      LOOP AT lt_params INTO ls_param.

        CLEAR: lv_target, lv_tabclass, lv_rowtype, lv_typename, ls_dd40l, ls_dd02l.

        IF ls_param-structure IS NOT INITIAL.
          lv_target = ls_param-structure.
        ELSE.
          CONTINUE.
        ENDIF.

        CONDENSE lv_target NO-GAPS.
        TRANSLATE lv_target TO UPPER CASE.

        lv_typename = lv_target.

        READ TABLE lt_dd40l INTO ls_dd40l
          WITH TABLE KEY typename = lv_typename.

        IF sy-subrc = 0 AND ls_dd40l-rowtype IS NOT INITIAL.
          lv_target = ls_dd40l-rowtype.
          CONDENSE lv_target NO-GAPS.
          TRANSLATE lv_target TO UPPER CASE.
        ENDIF.

        READ TABLE lt_dd02l INTO ls_dd02l
          WITH TABLE KEY tabname = lv_target.

        IF sy-subrc = 0.
          lv_tabclass = ls_dd02l-tabclass.
        ENDIF.

        IF sy-subrc = 0
           AND ( lv_tabclass = 'INTTAB'
              OR lv_tabclass = 'APPEND'
              OR lv_tabclass = 'STRUCT' ).

          CLEAR ls_hit.
          ls_hit-str_name = lv_target.
          ls_hit-usa_type = 'FM_PARAM'.
          ls_hit-src      = 'META'.

          INSERT ls_hit INTO TABLE ct_str_hits.

        ENDIF.

      ENDLOOP.

    "========================================================
    " 2. Class method parameter structure
    "========================================================
    WHEN gc_export-kw_obj_clas.

      SELECT *
        INTO TABLE @lt_subco
        FROM seosubcodf
        WHERE clsname  = @iv_objname
          AND version  = '1'.

      CLEAR: lt_typenames, lt_tabnames, lt_dd40l, lt_dd02l.

      LOOP AT lt_subco INTO ls_subco.

        IF ls_subco-type IS INITIAL.
          CONTINUE.
        ENDIF.

        lv_typename = ls_subco-type.
        CONDENSE lv_typename NO-GAPS.
        TRANSLATE lv_typename TO UPPER CASE.

        INSERT lv_typename INTO TABLE lt_typenames.

      ENDLOOP.

      IF lt_typenames IS NOT INITIAL.

        SELECT typename,
               rowtype
          FROM dd40l
          INTO TABLE @lt_dd40l
          FOR ALL ENTRIES IN @lt_typenames
          WHERE typename = @lt_typenames-table_line
            AND as4local = 'A'.

      ENDIF.

      LOOP AT lt_typenames INTO lv_typename.

        lv_target = lv_typename.

        READ TABLE lt_dd40l INTO ls_dd40l
          WITH TABLE KEY typename = lv_typename.

        IF sy-subrc = 0 AND ls_dd40l-rowtype IS NOT INITIAL.
          lv_target = ls_dd40l-rowtype.
        ENDIF.

        CONDENSE lv_target NO-GAPS.
        TRANSLATE lv_target TO UPPER CASE.

        INSERT lv_target INTO TABLE lt_tabnames.

      ENDLOOP.

      IF lt_tabnames IS NOT INITIAL.

        SELECT tabname,
               tabclass
          FROM dd02l
          INTO TABLE @lt_dd02l
          FOR ALL ENTRIES IN @lt_tabnames
          WHERE tabname  = @lt_tabnames-table_line
            AND as4local = 'A'
            AND as4vers  = '0000'.

      ENDIF.

      LOOP AT lt_subco INTO ls_subco.

        CLEAR: lv_target, lv_tabclass, lv_rowtype, lv_typename, ls_dd40l, ls_dd02l.

        IF ls_subco-type IS NOT INITIAL.
          lv_target = ls_subco-type.
        ELSE.
          CONTINUE.
        ENDIF.

        CONDENSE lv_target NO-GAPS.
        TRANSLATE lv_target TO UPPER CASE.

        lv_typename = lv_target.

        READ TABLE lt_dd40l INTO ls_dd40l
          WITH TABLE KEY typename = lv_typename.

        IF sy-subrc = 0 AND ls_dd40l-rowtype IS NOT INITIAL.
          lv_target = ls_dd40l-rowtype.
          CONDENSE lv_target NO-GAPS.
          TRANSLATE lv_target TO UPPER CASE.
        ENDIF.

        READ TABLE lt_dd02l INTO ls_dd02l
          WITH TABLE KEY tabname = lv_target.

        IF sy-subrc = 0.
          lv_tabclass = ls_dd02l-tabclass.
        ENDIF.

        IF sy-subrc = 0
           AND ( lv_tabclass = 'INTTAB'
              OR lv_tabclass = 'APPEND'
              OR lv_tabclass = 'STRUCT' ).

          CLEAR ls_hit.
          ls_hit-str_name = lv_target.
          ls_hit-usa_type = 'CLASS_PARAM'.
          ls_hit-src      = 'META'.

          INSERT ls_hit INTO TABLE ct_str_hits.

        ENDIF.

      ENDLOOP.

    WHEN OTHERS.
      RETURN.

  ENDCASE.

ENDMETHOD.


METHOD collect_structure_from_source.

  DATA: lv_line         TYPE string,
        lv_stmt         TYPE string,
        lv_work         TYPE string,
        lt_tokens       TYPE STANDARD TABLE OF string WITH EMPTY KEY,
        lv_token        TYPE string,
        lv_next         TYPE string,
        lv_next2        TYPE string,
        lv_next3        TYPE string,
        lv_next4        TYPE string,
        lv_target       TYPE string,
        lv_idx          TYPE sy-tabix,
        lv_tabclass     TYPE dd02l-tabclass,
        lv_rowtype      TYPE dd40l-rowtype,
        ls_hit          TYPE ty_str_hit,
        lt_dd40l        TYPE TABLE OF dd40l,
        lt_dd02l        TYPE TABLE OF dd02l,
        lv_rowtype_tmp  TYPE dd40l-rowtype,
        lv_tabclass_tmp TYPE dd02l-tabclass,
        lt_raw          TYPE SORTED TABLE OF ddobjname WITH UNIQUE KEY table_line.

  CLEAR lv_stmt.

  IF lt_raw IS NOT INITIAL.
    SELECT typename,
           rowtype
      FROM dd40l
      INTO CORRESPONDING FIELDS OF TABLE @lt_dd40l
      FOR ALL ENTRIES IN @lt_raw
      WHERE typename = @lt_raw-table_line
        AND as4local = @gc_ddic-as4local_active.
  ENDIF.

  IF lt_raw IS NOT INITIAL.
    SELECT tabname,
           tabclass
      FROM dd02l
      INTO CORRESPONDING FIELDS OF TABLE @lt_dd02l
      FOR ALL ENTRIES IN @lt_raw
      WHERE tabname  = @lt_raw-table_line
        AND as4local = @gc_ddic-as4local_active
        AND as4vers  = @gc_ddic-as4vers_active.
  ENDIF.

  LOOP AT it_source INTO lv_line.

    CONDENSE lv_line.

    IF lv_line IS INITIAL.
      CONTINUE.
    ENDIF.

    IF lv_line(1) = gc_symbol-star.
      CONTINUE.
    ENDIF.

    IF lv_stmt IS INITIAL.
      lv_stmt = lv_line.
    ELSE.
      CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
    ENDIF.

    IF lv_line NS gc_symbol-dot.
      CONTINUE.
    ENDIF.

    lv_work = lv_stmt.
    TRANSLATE lv_work TO UPPER CASE.

    REPLACE ALL OCCURRENCES OF '(' IN lv_work WITH ' ( '.
    REPLACE ALL OCCURRENCES OF ')' IN lv_work WITH ' ) '.
    REPLACE ALL OCCURRENCES OF gc_symbol-comma IN lv_work WITH ' , '.
    REPLACE ALL OCCURRENCES OF gc_symbol-dot   IN lv_work WITH ' . '.
    REPLACE ALL OCCURRENCES OF gc_symbol-colon IN lv_work WITH ' : '.
    REPLACE ALL OCCURRENCES OF gc_symbol-bang  IN lv_work WITH ''.
    CONDENSE lv_work.

    CLEAR lt_tokens.
    SPLIT lv_work AT space INTO TABLE lt_tokens.

    lv_idx = 1.
    WHILE lv_idx <= lines( lt_tokens ).

      lv_token = lt_tokens[ lv_idx ].

      CLEAR: lv_next, lv_next2, lv_next3, lv_next4,
             lv_target, lv_tabclass, lv_rowtype.

      IF lv_idx + 1 <= lines( lt_tokens ).
        lv_next  = lt_tokens[ lv_idx + 1 ].
      ENDIF.

      IF lv_idx + 2 <= lines( lt_tokens ).
        lv_next2 = lt_tokens[ lv_idx + 2 ].
      ENDIF.

      IF lv_idx + 3 <= lines( lt_tokens ).
        lv_next3 = lt_tokens[ lv_idx + 3 ].
      ENDIF.

      IF lv_idx + 4 <= lines( lt_tokens ).
        lv_next4 = lt_tokens[ lv_idx + 4 ].
      ENDIF.

      IF lv_token = gc_abap_token-type.

        IF lv_next = gc_de_token-ref.
          lv_idx = lv_idx + 1.
          CONTINUE.
        ENDIF.

        IF ( lv_next = gc_de_token-standard
          OR lv_next = gc_de_token-sorted
          OR lv_next = gc_de_token-hashed )
          AND lv_next2 = gc_de_token-table
          AND lv_next3 = gc_de_token-of.

          lv_target = lv_next4.

        ELSEIF lv_next = gc_de_token-table
           AND lv_next2 = gc_de_token-of.

          lv_target = lv_next3.

        ELSEIF lv_next = gc_de_token-line
           AND lv_next2 = gc_de_token-of.

          lv_target = lv_next3.

        ELSE.

          lv_target = lv_next.

        ENDIF.

      ENDIF.

      " LIKE / REFERENCES ...
      IF lv_token = gc_abap_token-like
         OR lv_token = gc_abap_token-references.

        IF lv_next = gc_de_token-line
           AND lv_next2 = gc_de_token-of.
          lv_target = lv_next3.
        ELSE.
          lv_target = lv_next.
        ENDIF.

      ENDIF.

      IF lv_target IS INITIAL.
        lv_idx = lv_idx + 1.
        CONTINUE.
      ENDIF.

      IF lv_target = gc_symbol-dot
         OR lv_target = gc_symbol-comma
         OR lv_target CP gc_de_skip-pat_ty
         OR lv_target CP gc_de_skip-pat_lt
         OR lv_target CP gc_de_skip-pat_ls
         OR lv_target CP gc_de_skip-pat_lv
         OR lv_target CP gc_de_skip-pat_gt
         OR lv_target CP gc_de_skip-pat_gs.
        lv_idx = lv_idx + 1.
        CONTINUE.
      ENDIF.

      CONDENSE lv_target NO-GAPS.
      TRANSLATE lv_target TO UPPER CASE.

      CLEAR lv_rowtype.

      SORT lt_dd40l BY typename.

      READ TABLE lt_dd40l INTO lv_rowtype WITH KEY typename = lv_target BINARY SEARCH.
      IF sy-subrc = 0 AND lv_rowtype IS NOT INITIAL.
        lv_target = lv_rowtype.
        CONDENSE lv_target NO-GAPS.
        TRANSLATE lv_target TO UPPER CASE.
      ENDIF.

      CLEAR lv_tabclass.

      SORT lt_dd02l BY tabname.

      READ TABLE lt_dd02l INTO lv_tabclass WITH KEY tabname = lv_target BINARY SEARCH.
      IF sy-subrc = 0
         AND ( lv_tabclass = gc_ddic-tabclass_inttab
            OR lv_tabclass = gc_ddic-tabclass_append
            OR lv_tabclass = gc_ddic-tabclass_struct ).

        CLEAR ls_hit.
        ls_hit-str_name = lv_target.
        ls_hit-usa_type = gc_abap_token-type.
        ls_hit-src      = gc_table_source-select.

        INSERT ls_hit INTO TABLE ct_str_hits.

      ENDIF.

      lv_idx = lv_idx + 1.

    ENDWHILE.

    CLEAR lv_stmt.

  ENDLOOP.

ENDMETHOD.


  METHOD fill_structure.

    DATA: lt_str_hits     TYPE gty_t_str_hits,
          lt_source       TYPE string_table,
          lt_sources      TYPE gty_t_program_source,
          ls_source       TYPE ty_program_source,
          lt_class_source TYPE tt_class_source,
          ls_class_source TYPE ty_class_source,
          lv_prog_name    TYPE progname,
          lv_func_name    TYPE rs38l-name,
          lv_class_name   TYPE seoclsname.

    me->ensure_objects( ).

    CASE iv_objtype.

      WHEN gc_export-kw_obj_prog.

        lv_prog_name = iv_objname.
        TRANSLATE lv_prog_name TO UPPER CASE.
        CONDENSE lv_prog_name NO-GAPS.

        lt_source = me->go_fetch->get_source_code(
          iv_name = lv_prog_name
        ).

        me->collect_structure_from_source(
          EXPORTING
            it_source   = lt_source
          CHANGING
            ct_str_hits = lt_str_hits
        ).

      WHEN gc_export-kw_obj_func.

        lv_func_name = iv_objname.
        TRANSLATE lv_func_name TO UPPER CASE.
        CONDENSE lv_func_name NO-GAPS.

        lt_sources = me->go_fetch->get_function_module(
          iv_funcname = lv_func_name
        ).

        LOOP AT lt_sources INTO ls_source.
          IF ls_source-source_code IS NOT INITIAL.
            me->collect_structure_from_source(
              EXPORTING
                it_source   = ls_source-source_code
              CHANGING
                ct_str_hits = lt_str_hits
            ).
          ENDIF.
        ENDLOOP.
        me->collect_structure_from_meta(
          EXPORTING
            iv_objtype  = gc_export-kw_obj_func
            iv_objname  = CONV sobj_name( lv_func_name )
          CHANGING
            ct_str_hits = lt_str_hits
        ).

      WHEN gc_export-kw_obj_clas.

        lv_class_name = iv_objname.
        TRANSLATE lv_class_name TO UPPER CASE.
        CONDENSE lv_class_name NO-GAPS.

        lt_class_source = me->go_fetch->get_class(
          iv_class_name = lv_class_name
        ).

        LOOP AT lt_class_source INTO ls_class_source.
          IF ls_class_source-source_code IS NOT INITIAL.
            me->collect_structure_from_source(
              EXPORTING
                it_source   = ls_class_source-source_code
              CHANGING
                ct_str_hits = lt_str_hits
            ).
          ENDIF.
        ENDLOOP.
        me->collect_structure_from_meta(
          EXPORTING
            iv_objtype  = gc_export-kw_obj_clas
            iv_objname  = CONV sobj_name( lv_class_name )
          CHANGING
            ct_str_hits = lt_str_hits
        ).

      WHEN OTHERS.
        RETURN.

    ENDCASE.

    rt_structure = me->build_structure_rows( lt_str_hits ).

  ENDMETHOD.
ENDCLASS.
