CLASS zcl_program_report DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS export_program_to_excel
      IMPORTING
        iv_prog_name TYPE progname .
    METHODS export_fm_to_excel
      IMPORTING
        iv_func_name       TYPE rs38l-name
        iv_direct_download TYPE abap_bool OPTIONAL
        iv_save_as         TYPE string OPTIONAL.
    METHODS export_fugr_to_excel
      IMPORTING
        iv_fugr_name TYPE rs38l-area.
    METHODS export_class_to_excel
      IMPORTING
        iv_class_name TYPE seoclsname .
  PRIVATE SECTION.

    "========TABLE TYPES======"
    TYPES: BEGIN OF gty_class_source,
             include      TYPE progname,
             include_kind TYPE char20,   " SECTION / METHOD / OTHER
             section      TYPE char20,   " PUBLIC / PROTECTED / PRIVATE
             method_level TYPE char20,
             description  TYPE seodescr,
             method_name  TYPE seocpdname,
             source_code  TYPE string_table,
           END OF gty_class_source .

    TYPES: gty_t_class_source TYPE STANDARD TABLE OF gty_class_source WITH EMPTY KEY .

    TYPES: BEGIN OF gty_program_source,
             include     TYPE programm,
             source_code TYPE string_table,
           END OF gty_program_source .

    TYPES: gty_t_program_source TYPE STANDARD TABLE OF gty_program_source WITH EMPTY KEY .
    TYPES: gty_t_de_rollnames TYPE SORTED TABLE OF rollname WITH UNIQUE KEY table_line .
    TYPES: gty_t_seen_prog TYPE SORTED TABLE OF progname WITH UNIQUE KEY table_line .
    TYPES: gty_t_seen_type TYPE SORTED TABLE OF ddobjname WITH UNIQUE KEY table_line .

    TYPES: BEGIN OF gty_comp_meta,
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
           END OF gty_comp_meta .

    TYPES: BEGIN OF gty_comp_text,
             clsname  TYPE seoclsname,
             cmpname  TYPE seocmpname,
             langu    TYPE sylangu,
             descript TYPE seodescr,
           END OF gty_comp_text .

    TYPES: BEGIN OF gty_subco_meta,
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
           END OF gty_subco_meta .

    TYPES: BEGIN OF gty_subco_text,
             clsname  TYPE seoclsname,
             cmpname  TYPE seocmpname,
             sconame  TYPE seosconame,
             langu    TYPE sylangu,
             descript TYPE seodescr,
           END OF gty_subco_text .

    TYPES: BEGIN OF gty_rel_meta,
             clsname    TYPE seoclsname,
             refclsname TYPE seoclsname,
             version    TYPE seoversion,
             state      TYPE seostate,
             reltype    TYPE seoreltype,
             relname    TYPE seorelname,
             exposure   TYPE seoexpose,
             impfinal   TYPE seofinal,
             impabstrct TYPE seoabstrct,
           END OF gty_rel_meta .

    TYPES: BEGIN OF gty_fg_fm,
             fm_name     TYPE rs38l-name,
             description TYPE tftit-stext,
             download    TYPE icon_d,
           END OF gty_fg_fm .

    TYPES: gty_t_fg_fm TYPE STANDARD TABLE OF gty_fg_fm WITH EMPTY KEY .

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

    TYPES: BEGIN OF gty_str_hit,
             str_name TYPE tabname,
             usa_type TYPE char20,
             src      TYPE char20,
           END OF gty_str_hit.

    TYPES: gty_t_str_hits TYPE SORTED TABLE OF gty_str_hit WITH UNIQUE KEY str_name usa_type src.

    DATA go_fetch TYPE REF TO zcl_program_fetch .
    DATA go_check TYPE REF TO zcl_program_check .
    DATA go_whereused TYPE REF TO zcl_program_whereused .
    DATA gt_fg_fm TYPE gty_t_fg_fm .

    "========METHODS======"
    METHODS helper_fugr_download
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING row column.

    METHODS fill_class_layout_attr
      IMPORTING
        !iv_class_name   TYPE seoclsname
        !it_class_source TYPE gty_t_class_source
      CHANGING
        !cs_layout       TYPE zst_class_layout .
    METHODS fill_class_layout_classdef
      IMPORTING
        !iv_class_name TYPE seoclsname
      CHANGING
        !cs_layout     TYPE zst_class_layout .
    METHODS fill_class_layout_method
      IMPORTING
        !iv_class_name   TYPE seoclsname
        !it_class_source TYPE gty_t_class_source
      CHANGING
        !cs_layout       TYPE zst_class_layout .
    METHODS fill_class_layout_param
      IMPORTING
        !iv_class_name   TYPE seoclsname
        !it_class_source TYPE gty_t_class_source
      CHANGING
        !cs_layout       TYPE zst_class_layout .
    METHODS normalize_class_layout
      CHANGING
        !cs_layout TYPE zst_class_layout .
    METHODS ensure_objects .
    METHODS fill_screen_layout
      IMPORTING
        !iv_program_name  TYPE progname
      CHANGING
        !cs_screen_layout TYPE zst_screen_layout .
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
        VALUE(rs_overview) TYPE zcore_st_parameter .
    METHODS call_excel_form
      IMPORTING
        !is_excel           TYPE zst_gsp04_report
        !iv_viewer_title    TYPE string OPTIONAL
        !iv_direct_download TYPE abap_bool OPTIONAL
        !iv_save_as         TYPE string OPTIONAL
        !iv_objtype         TYPE trobjtype OPTIONAL .

    METHODS fill_class_layout
      IMPORTING
        !iv_class_name   TYPE seoclsname
      RETURNING
        VALUE(rs_layout) TYPE zst_class_layout .
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
        kw_active         TYPE string    VALUE 'Active' ##NO_TEXT,
        kw_inactive       TYPE string    VALUE 'Inactive' ##NO_TEXT,

        kw_pgmid_r3tr     TYPE pgmid     VALUE 'R3TR',
        kw_r3state_active TYPE r3state   VALUE 'A',

        kw_obj_prog       TYPE trobjtype VALUE 'PROG',
        kw_obj_clas       TYPE trobjtype VALUE 'CLAS',
        kw_obj_fugr       TYPE trobjtype VALUE 'FUGR',
        kw_obj_func       TYPE trobjtype VALUE 'FUNC',

        fm_param          TYPE string VALUE 'FM_PARAM',
        meta              TYPE string VALUE 'META',
        class_param       TYPE string VALUE 'CLASS_PARAM',
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
        quote           TYPE string VALUE '"',
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
        lt           TYPE string VALUE '@LT_*',
        gt           TYPE string VALUE '@GT_*',
        data         TYPE string VALUE '@DATA_*',
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
        transparent_table TYPE string VALUE 'Transparent Table' ##NO_TEXT,
        view              TYPE string VALUE 'View' ##NO_TEXT,
        internal_table    TYPE string VALUE 'Internal Table' ##NO_TEXT,
        append_structure  TYPE string VALUE 'Append Structure' ##NO_TEXT,
        structure         TYPE string VALUE 'Structure' ##NO_TEXT,
      END OF gc_ddic_text.

    " =======================================================================
    " 1. EXCEL REPORT
    " =======================================================================
    CONSTANTS:
      gc_formname     TYPE char255   VALUE 'ZGSP04_REPORT',
      gc_ext_xlsx     TYPE string    VALUE '.xlsx',
      gc_ext_xlsm     TYPE string    VALUE 'xlsm', "
      gc_mem_id       TYPE char32    VALUE 'ZGSP04_XLSX_NAME',
      gc_cb_prog      TYPE progname  VALUE 'Z_ANALYZE_TOOL',
      gc_cb_form      TYPE char30    VALUE 'F_XLWB_VIEWER_CALLBACK',
      gc_mark_x       TYPE char1     VALUE 'X',
      gc_class_prefix TYPE string    VALUE 'CLASS_',
      gc_fm_prefix    TYPE string    VALUE 'FM_',
      gc_prog_prefix  TYPE string    VALUE 'PROG_',
      gc_empty        TYPE string    VALUE ''.

    " =======================================================================
    " 2. FUNCTION MODULE
    " =======================================================================
    CONSTANTS:
      gc_lang_e    TYPE sylangu   VALUE 'E',
      gc_param_i   TYPE char1     VALUE 'I',
      gc_param_e   TYPE char1     VALUE 'E',
      gc_param_c   TYPE char1     VALUE 'C',
      gc_param_t   TYPE char1     VALUE 'T',
      gc_param_x   TYPE char1     VALUE 'X',
      gc_param_p   TYPE char1     VALUE 'P',
      gc_type      TYPE string    VALUE 'TYPE',
      gc_like      TYPE string    VALUE 'LIKE',
      gc_structure TYPE string    VALUE 'STRUCTURE',
      gc_sapl      TYPE string    VALUE 'SAPL*'.

    " =======================================================================
    " 3. ALV FUNCTION GROUP
    " =======================================================================
    CONSTANTS:
      gc_col_fm_name        TYPE lvc_fname VALUE 'FM_NAME',
      gc_col_desc           TYPE lvc_fname VALUE 'DESCRIPTION',
      gc_col_download       TYPE lvc_fname VALUE 'DOWNLOAD',
      gc_text_fm_name       TYPE scrtext_l VALUE 'FM Name' ##NO_TEXT,


      gc_text_desc_long     TYPE scrtext_l VALUE 'Description' ##NO_TEXT,

      gc_text_desc_short    TYPE scrtext_s VALUE 'Desc' ##NO_TEXT,
      gc_text_export        TYPE scrtext_l VALUE 'Export' ##NO_TEXT,


      gc_ucomm_ont          TYPE sy-ucomm  VALUE '&ONT',
      gc_ucomm_double_click TYPE sy-ucomm  VALUE '&IC1'.

    " =======================================================================
    " 4. MESSAGE CLASS INFO
    " =======================================================================
    CONSTANTS:
      gc_msg_class_gsp TYPE arbgb     VALUE 'Z_GSP04_MESSAGE',
      gc_msg_no_083    TYPE symsgno   VALUE '083',
      gc_msg_no_082    TYPE symsgno   VALUE '082',
      gc_msgty_s       TYPE symsgty   VALUE 'S',
      gc_msgty_e       TYPE symsgty   VALUE 'E'.

    " =======================================================================
    " 5. SCREEN LAYOUT
    " =======================================================================
    CONSTANTS:
      gc_scr_at_sel       TYPE string    VALUE 'AT SELECTION-SCREEN.',
      gc_scr_at_sel_out   TYPE string    VALUE 'AT SELECTION-SCREEN OUTPUT.',
      gc_scr_start_sel    TYPE string    VALUE 'START-OF-SELECTION.',
      gc_scr_init         TYPE string    VALUE 'INITIALIZATION.',
      gc_scr_end_sel      TYPE string    VALUE 'END-OF-SELECTION.',
      gc_scr_beg_block    TYPE string    VALUE 'SELECTION-SCREEN BEGIN OF BLOCK *',
      gc_scr_beg_line     TYPE string    VALUE 'SELECTION-SCREEN BEGIN OF LINE.',
      gc_scr_end_line     TYPE string    VALUE 'SELECTION-SCREEN END OF LINE.',
      gc_scr_pos          TYPE string    VALUE 'SELECTION-SCREEN POSITION *',
      gc_scr_comment      TYPE string    VALUE 'SELECTION-SCREEN COMMENT *',
      gc_scr_param1       TYPE string    VALUE 'PARAMETERS:*',
      gc_scr_param2       TYPE string    VALUE 'PARAMETERS *',
      gc_scr_sel_opt1     TYPE string    VALUE 'SELECT-OPTIONS:*',
      gc_scr_sel_opt2     TYPE string    VALUE 'SELECT-OPTIONS *',
      gc_scr_pushbtn      TYPE string    VALUE 'SELECTION-SCREEN PUSHBUTTON *',
      gc_scr_as_chkbox    TYPE string    VALUE 'AS CHECKBOX',
      gc_scr_as_listbox   TYPE string    VALUE 'AS LISTBOX',
      gc_scr_obligatory   TYPE string    VALUE 'OBLIGATORY',
      gc_scr_no_disp      TYPE string    VALUE 'NO-DISPLAY',
      gc_scr_no_int1      TYPE string    VALUE 'NO INTERVALS',
      gc_scr_no_int2      TYPE string    VALUE 'NO-INTERVALS',
      gc_scr_no_ext1      TYPE string    VALUE 'NO-EXTENSION',
      gc_scr_no_ext2      TYPE string    VALUE 'NO EXTENSION',
      gc_scr_msg          TYPE string    VALUE 'MESSAGE ',
      gc_scr_type_chkbox  TYPE string    VALUE 'CHECKBOX',
      gc_scr_type_listbox TYPE string    VALUE 'LISTBOX',
      gc_scr_type_param   TYPE string    VALUE 'PARAMETER',
      gc_scr_type_selopt  TYPE string    VALUE 'SELECT-OPTION',
      gc_scr_yes          TYPE string    VALUE 'Yes',
      gc_scr_no           TYPE string    VALUE 'No',
      gc_scr_single       TYPE string    VALUE 'Single' ##NO_TEXT,
      gc_scr_multiple     TYPE string    VALUE 'Multiple' ##NO_TEXT,
      gc_scr_act_sel      TYPE string    VALUE 'AT SELECTION-SCREEN / USER-COMMAND',
      gc_scr_act_val      TYPE string    VALUE 'AT SELECTION-SCREEN validation' ##NO_TEXT,
      gc_tab_sy           TYPE tabname   VALUE 'SY',
      gc_fld_datum        TYPE fieldname VALUE 'DATUM',
      gc_fn_ddif          TYPE string    VALUE 'DDIF_FIELDINFO_GET',
      gc_na               TYPE string    VALUE 'N/A',
      gc_pat_dash         TYPE string    VALUE '*-*'.

    " =======================================================================
    " 7. REGEX
    " =======================================================================
    CONSTANTS:
      gc_pcre_pos        TYPE string    VALUE 'POSITION\s+([0-9]+)' ##NO_TEXT,
      gc_pcre_comment    TYPE string    VALUE 'COMMENT\s+([0-9]+)\(([0-9]+)\)' ##NO_TEXT,
      gc_pcre_param_clr  TYPE string    VALUE '^\s*PARAMETERS\s*:?\s*',
      gc_pcre_name       TYPE string    VALUE '^\s*([A-Z0-9_]+)' ##NO_TEXT,
      gc_pcre_type       TYPE string    VALUE '\bTYPE\s+([A-Z0-9_\-]+)' ##NO_TEXT,
      gc_pcre_default    TYPE string    VALUE '\bDEFAULT\s+(''[^'']*''|\S+)',
      gc_pcre_type_char  TYPE string    VALUE '\bTYPE\s+CHAR([0-9]+)' ##NO_TEXT,
      gc_pcre_selopt_clr TYPE string    VALUE '^\s*SELECT-OPTIONS\s*:?\s*' ##NO_TEXT,
      gc_pcre_for        TYPE string    VALUE '\bFOR\s+([A-Z0-9_\-]+)' ##NO_TEXT,
      gc_pcre_pushbtn    TYPE string    VALUE 'PUSHBUTTON\s+[^()]*\(([^)]*)\)',
      gc_pcre_desc       TYPE string    VALUE '''([^'']+)''',
      gc_pcre_msg1       TYPE string    VALUE 'MESSAGE\s+([EWIASX])([0-9]{3})?' ##NO_TEXT,
      gc_pcre_msg2       TYPE string    VALUE 'TYPE\s+''([EWIASX])'''.

    " =======================================================================
    " 8. OBJECT TYPES KEYWORDS
    " =======================================================================
    CONSTANTS:
      gc_kw_prog      TYPE string    VALUE 'PROG',
      gc_kw_program   TYPE string    VALUE 'PROGRAM',
      gc_kw_reps      TYPE string    VALUE 'REPS',
      gc_kw_report    TYPE string    VALUE 'REPORT',
      gc_kw_inc       TYPE string    VALUE 'INC',
      gc_kw_include   TYPE string    VALUE 'INCLUDE',
      gc_kw_fugr      TYPE string    VALUE 'FUGR',
      gc_kw_funcgrp   TYPE string    VALUE 'FUNCTIONGROUP',
      gc_kw_func      TYPE string    VALUE 'FUNC',
      gc_kw_fm        TYPE string    VALUE 'FM',
      gc_kw_funcmod   TYPE string    VALUE 'FUNCTIONMODULE',
      gc_kw_clas      TYPE string    VALUE 'CLAS',
      gc_kw_class     TYPE string    VALUE 'CLASS',
      gc_kw_intf      TYPE string    VALUE 'INTF',
      gc_kw_interface TYPE string    VALUE 'INTERFACE',
      gc_kw_method    TYPE string    VALUE 'METHOD'.

    " =======================================================================
    " 9. CLASS COMPONENT METADATA
    " =======================================================================
    CONSTANTS:
      gc_comp_exp_0      TYPE char1     VALUE '0',
      gc_comp_exp_1      TYPE char1     VALUE '1',
      gc_comp_exp_2      TYPE char1     VALUE '2',
      gc_comp_sec_priv   TYPE string    VALUE 'PRIVATE',
      gc_comp_sec_prot   TYPE string    VALUE 'PROTECTED',
      gc_comp_sec_pub    TYPE string    VALUE 'PUBLIC',
      gc_comp_decl_0     TYPE char1     VALUE '0',
      gc_comp_decl_1     TYPE char1     VALUE '1',
      gc_comp_decl_2     TYPE char1     VALUE '2',
      gc_comp_lvl_inst   TYPE string    VALUE 'INSTANCE',
      gc_comp_lvl_stat   TYPE string    VALUE 'STATIC',
      gc_comp_lvl_const  TYPE string    VALUE 'CONSTANT',
      gc_fn_seo_typeinfo TYPE string    VALUE 'SEO_CLASS_TYPEINFO_GET'.

    " =======================================================================
    " 10. CLASS DEFINITION KEYWORDS
    " =======================================================================
    CONSTANTS:
      gc_clstype_0         TYPE char1     VALUE '0',
      gc_clstype_1         TYPE char1     VALUE '1',
      gc_cls_type_class    TYPE string    VALUE 'Class' ##NO_TEXT,
      gc_cls_type_intf     TYPE string    VALUE 'Interface' ##NO_TEXT,
      gc_kw_class_def      TYPE string    VALUE 'DEFINITION',
      gc_kw_interfaces_pat TYPE string    VALUE 'INTERFACES *.',
      gc_kw_final          TYPE string    VALUE ' FINAL',
      gc_kw_abstract       TYPE string    VALUE ' ABSTRACT',
      gc_kw_create_pub     TYPE string    VALUE ' CREATE PUBLIC',
      gc_kw_create_prot    TYPE string    VALUE ' CREATE PROTECTED',
      gc_kw_create_priv    TYPE string    VALUE ' CREATE PRIVATE',
      gc_comma_space       TYPE string    VALUE ', ',
      gc_dot               TYPE string    VALUE '.',
      gc_pcre_intf         TYPE string    VALUE 'INTERFACES\s+([A-Za-z0-9_/]+)' ##NO_TEXT,
      gc_pcre_inher        TYPE string    VALUE 'INHERITING\s+FROM\s+([A-Za-z0-9_/]+)' ##NO_TEXT.

    " =======================================================================
    " 11. CLASS PARAMETER & METHOD METADATA
    " =======================================================================
    CONSTANTS:
      gc_param_decl_0      TYPE char1     VALUE '0',
      gc_param_decl_1      TYPE char1     VALUE '1',
      gc_param_decl_2      TYPE char1     VALUE '2',
      gc_param_decl_3      TYPE char1     VALUE '3',
      gc_param_type_imp    TYPE string    VALUE 'IMPORTING',
      gc_param_type_exp    TYPE string    VALUE 'EXPORTING',
      gc_param_type_cha    TYPE string    VALUE 'CHANGING',
      gc_param_type_ret    TYPE string    VALUE 'RETURNING',
      gc_param_pass_0      TYPE char1     VALUE '0',
      gc_param_pass_1      TYPE char1     VALUE '1',
      gc_param_typ_0       TYPE char1     VALUE '0',
      gc_param_typ_1       TYPE char1     VALUE '1',
      gc_param_typ_type    TYPE string    VALUE 'TYPE',
      gc_param_typ_like    TYPE string    VALUE 'LIKE',
      gc_table_of          TYPE string    VALUE 'TABLE OF',
      gc_meth_constr       TYPE string    VALUE 'CONSTRUCTOR',
      gc_meth_cls_constr   TYPE string    VALUE 'CLASS_CONSTRUCTOR',
      gc_meth_type_constr  TYPE string    VALUE 'Constructor' ##NO_TEXT,
      gc_meth_type_cls_con TYPE string    VALUE 'Class Constructor' ##NO_TEXT,
      gc_meth_type_abstr   TYPE string    VALUE 'Abstract' ##NO_TEXT,
      gc_meth_type_norm    TYPE string    VALUE 'Normal' ##NO_TEXT,
      gc_kw_methods_pat    TYPE string    VALUE 'METHODS *.',
      gc_kw_cls_meth_pat   TYPE string    VALUE 'CLASS-METHODS *.',
      gc_kw_class_methods  TYPE string    VALUE 'CLASS-METHODS',
      gc_kw_abstract_pat   TYPE string    VALUE 'ABSTRACT',
      gc_pcre_meth_decl1   TYPE string    VALUE '^\s*(METHODS|CLASS-METHODS)\s*:(.*)$' ##NO_TEXT,
      gc_pcre_meth_decl2   TYPE string    VALUE '^\s*(METHODS|CLASS-METHODS)\s+(.+)$' ##NO_TEXT,
      gc_pcre_meth_name    TYPE string    VALUE '^\s*([A-Za-z0-9_]+)' ##NO_TEXT,
      gc_section_kw        TYPE string    VALUE 'SECTION'.
    CONSTANTS:
      gc_state_active   TYPE seostate VALUE '1'.

    CONSTANTS:
      gc_version_active TYPE seoversion VALUE '1',
      gc_pcre_include   TYPE string    VALUE '^\s*INCLUDE\s+([A-Z0-9_]+)\.' ##NO_TEXT.
    CONSTANTS:
      gc_pcre_insert_into TYPE string    VALUE 'INSERT\s+INTO\s+([A-Z0-9_/]+)' ##NO_TEXT,
      gc_pcre_insert_from TYPE string    VALUE 'INSERT\s+([A-Z0-9_/]+)\s+FROM' ##NO_TEXT,
      gc_pcre_update      TYPE string    VALUE 'UPDATE\s+([A-Z0-9_/]+)' ##NO_TEXT,
      gc_pcre_modify      TYPE string    VALUE 'MODIFY\s+([A-Z0-9_/]+)' ##NO_TEXT,
      gc_pcre_delete      TYPE string    VALUE 'DELETE\s+FROM\s+([A-Z0-9_/]+)' ##NO_TEXT.
    CONSTANTS:
      gc_as4local_a      TYPE string    VALUE 'A',
      gc_pat_dot_percent TYPE string    VALUE '.%',
      gc_as4vers_0000    TYPE string    VALUE '0000'.
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

    DATA: lv_formname     TYPE char255,
          lv_viewer_title TYPE string,
          lv_save_as      TYPE string.

    lv_formname = gc_formname.
    lv_viewer_title = iv_viewer_title.
    CONDENSE lv_viewer_title NO-GAPS.

    IF lv_viewer_title IS INITIAL.
      lv_viewer_title = lv_formname.
    ENDIF.

    lv_save_as = iv_save_as.
    IF lv_save_as IS INITIAL.
      lv_save_as = |{ lv_viewer_title }{ gc_ext_xlsx }|.
    ENDIF.

    EXPORT lv_save_as = lv_save_as TO MEMORY ID gc_mem_id.

    IF iv_direct_download = abap_true.

      CALL FUNCTION 'ZXLWB_CALLFORM'
        EXPORTING
          iv_formname        = lv_formname
          iv_context_ref     = is_excel
          iv_viewer_suppress = gc_mark_x
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
        iv_context_ref          = is_excel
        iv_viewer_title         = lv_viewer_title
        iv_viewer_inplace       = gc_mark_x
        iv_viewer_callback_prog = gc_cb_prog
        iv_viewer_callback_form = gc_cb_form
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
        FIND PCRE gc_pcre_include IN lv_inc_uc
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

      REPLACE ALL OCCURRENCES OF gc_symbol-lparen  IN lv_work WITH gc_symbol-lparen.
      REPLACE ALL OCCURRENCES OF gc_symbol-rparen  IN lv_work WITH gc_symbol-rparen.
      REPLACE ALL OCCURRENCES OF gc_symbol-comma IN lv_work WITH gc_symbol-comma.
      REPLACE ALL OCCURRENCES OF gc_symbol-dot   IN lv_work WITH gc_symbol-dot.
      REPLACE ALL OCCURRENCES OF gc_symbol-colon IN lv_work WITH gc_symbol-colon.
      REPLACE ALL OCCURRENCES OF gc_symbol-c_equal         IN lv_work WITH gc_symbol-c_equal.
      REPLACE ALL OCCURRENCES OF gc_symbol-bang  IN lv_work WITH gc_symbol-bang.
      CONDENSE lv_work.

      CLEAR lt_tokens.
      SPLIT lv_work AT space INTO TABLE lt_tokens.

      lv_idx = 1.
      WHILE lv_idx <= lines( lt_tokens ).

        READ TABLE lt_tokens INTO lv_token INDEX lv_idx.

        CLEAR: lv_next, lv_next2, lv_next3, lv_next4, lv_target.

        READ TABLE lt_tokens INTO lv_next  INDEX lv_idx + 1.
        READ TABLE lt_tokens INTO lv_next2 INDEX lv_idx + 2.
        READ TABLE lt_tokens INTO lv_next3 INDEX lv_idx + 3.
        READ TABLE lt_tokens INTO lv_next4 INDEX lv_idx + 4.

        " Table
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
        lt_alias         TYPE SORTED TABLE OF lty_alias_map WITH NON-UNIQUE KEY alias,
        ls_used          TYPE lty_field_map,
        lt_used          TYPE SORTED TABLE OF lty_field_map WITH UNIQUE KEY tab_name field,
        ls_key           TYPE lty_field_map,
        lt_key           TYPE SORTED TABLE OF lty_field_map WITH UNIQUE KEY tab_name field,
        ls_hit           TYPE gty_tab_hit,
        lv_access        TYPE char20,
        ls_stmt_tab      TYPE lty_stmt_tab,
        lt_all_stmt_tabs TYPE SORTED TABLE OF lty_stmt_tab WITH UNIQUE KEY tab_name,
        lt_all_ddic_keys TYPE STANDARD TABLE OF lty_field_map WITH EMPTY KEY,
        lt_all_stmt_keys TYPE SORTED TABLE OF lty_field_map WITH UNIQUE KEY tab_name field,
        lv_idx2          TYPE sy-tabix,
        lv_idx3          TYPE sy-tabix.

  CLEAR: lv_stmt,
         lt_all_stmt_keys.

  " PRE-SCAN
  LOOP AT it_source INTO lv_line.

    CONDENSE lv_line.

    IF lv_line IS INITIAL.
      CONTINUE.
    ENDIF.

    IF lv_line(1) = gc_symbol-star.
      CONTINUE.
    ENDIF.

    FIND FIRST OCCURRENCE OF gc_symbol-quote IN lv_line MATCH OFFSET lv_cmt_pos.
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
    REPLACE ALL OCCURRENCES OF gc_symbol-lparen IN lv_work WITH gc_symbol-lparen.
    REPLACE ALL OCCURRENCES OF gc_symbol-rparen IN lv_work WITH gc_symbol-rparen.
    REPLACE ALL OCCURRENCES OF gc_symbol-comma IN lv_work WITH gc_symbol-comma.
    REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_work WITH gc_symbol-dot.
    REPLACE ALL OCCURRENCES OF gc_symbol-c_equal IN lv_work WITH gc_symbol-c_equal.
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
      REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_tabname WITH gc_empty.
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
      REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_join_tab WITH gc_empty.
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
        AND keyflag  = @gc_mark_x
        AND as4local = @gc_ddic-as4local_active
        AND as4vers  = @gc_ddic-as4vers_active.

    LOOP AT lt_all_ddic_keys INTO ls_key.
      INSERT ls_key INTO TABLE lt_all_stmt_keys.
    ENDLOOP.

  ENDIF.

  CLEAR lv_stmt.

  LOOP AT it_source INTO lv_line.

    " 0. Clean line
    CONDENSE lv_line.

    IF lv_line IS INITIAL.
      CONTINUE.
    ENDIF.

    IF lv_line(1) = gc_symbol-star.
      CONTINUE.
    ENDIF.

    FIND FIRST OCCURRENCE OF gc_symbol-quote IN lv_line MATCH OFFSET lv_cmt_pos.
    IF sy-subrc = 0.
      lv_line = lv_line(lv_cmt_pos).
      CONDENSE lv_line.
      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.
    ENDIF.

    " 1.Statement .
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
    REPLACE ALL OCCURRENCES OF gc_symbol-lparen IN lv_work WITH gc_symbol-lparen.
    REPLACE ALL OCCURRENCES OF gc_symbol-rparen IN lv_work WITH gc_symbol-rparen.
    REPLACE ALL OCCURRENCES OF gc_symbol-comma IN lv_work WITH gc_symbol-comma.
    REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_work WITH gc_symbol-dot.
    REPLACE ALL OCCURRENCES OF gc_symbol-c_equal IN lv_work WITH gc_symbol-c_equal.
    CONDENSE lv_work.

    CLEAR lt_tokens.
    SPLIT lv_work AT space INTO TABLE lt_tokens.

    CLEAR: lt_alias, lt_used, lt_key, lv_main_tab,
           lv_from_idx, lv_access.


    " 2. Build alias map: FROM / JOIN
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
        REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_tabname WITH gc_empty.
        CONDENSE lv_tabname NO-GAPS.
        TRANSLATE lv_tabname TO UPPER CASE.

        IF me->is_valid_table_name( lv_tabname ) = abap_true.

          lv_main_tab = lv_tabname.

          CLEAR ls_alias.
          ls_alias-alias    = lv_tabname.
          ls_alias-tab_name = lv_tabname.
          INSERT ls_alias INTO TABLE lt_alias.

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
     AND lv_next2 <> gc_symbol-dot.
            lv_alias = lv_next2.
          ENDIF.

          IF lv_alias IS NOT INITIAL.
            TRANSLATE lv_alias TO UPPER CASE.
            CONDENSE lv_alias NO-GAPS.

            CLEAR ls_alias.
            ls_alias-alias    = lv_alias.
            ls_alias-tab_name = lv_tabname.
            INSERT ls_alias INTO TABLE lt_alias.
          ENDIF.

        ENDIF.
      ENDIF.

      " JOIN <table> [AS alias] , JOIN <table> alias
      IF lv_token = gc_abap_token-join.

        lv_join_tab = lv_next.
        REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_join_tab WITH gc_empty.
        CONDENSE lv_join_tab NO-GAPS.
        TRANSLATE lv_join_tab TO UPPER CASE.

        IF me->is_valid_table_name( lv_join_tab ) = abap_true.

          CLEAR ls_alias.
          ls_alias-alias    = lv_join_tab.
          ls_alias-tab_name = lv_join_tab.
          INSERT ls_alias INTO TABLE lt_alias.

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
           AND lv_next2 <> gc_symbol-dot.
            lv_alias = lv_next2.
          ENDIF.

          IF lv_alias IS NOT INITIAL.
            TRANSLATE lv_alias TO UPPER CASE.
            CONDENSE lv_alias NO-GAPS.

            CLEAR ls_alias.
            ls_alias-alias    = lv_alias.
            ls_alias-tab_name = lv_join_tab.
            INSERT ls_alias INTO TABLE lt_alias.
          ENDIF.

        ENDIF.
      ENDIF.

      lv_idx = lv_idx + 1.
    ENDWHILE.

    " 3. SELECT / SELECT SINGLE / JOIN
    IF lv_stmt_uc CS gc_abap_token-select AND lv_main_tab IS NOT INITIAL.

      IF lv_stmt_uc CS gc_abap_token-select_single.
        lv_access = gc_table_access-select_single.
      ELSE.
        lv_access = gc_table_access-select.
      ENDIF.

      " 3.1 Used Fields: field list FROM
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


        lv_idx = lv_select_from.
        WHILE lv_idx <= lv_select_to.

          READ TABLE lt_tokens INTO lv_token INDEX lv_idx.
          IF sy-subrc <> 0.
            lv_idx = lv_idx + 1.
            CONTINUE.
          ENDIF.

          IF lv_token IS INITIAL
             OR lv_token = gc_symbol-comma
             OR lv_token = gc_symbol-dot
             OR lv_token = gc_symbol-lparen
             OR lv_token = gc_symbol-rparen
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


          CLEAR: lv_alias, lv_field, lv_tabname.
          IF lv_token = gc_symbol-star.
            lv_field = gc_symbol-star.
            lv_tabname = lv_main_tab.
          ELSEIF lv_token CS gc_symbol-tilde .
            SPLIT lv_token AT gc_symbol-tilde  INTO lv_alias lv_field.
            TRANSLATE lv_alias TO UPPER CASE.
            CONDENSE lv_alias NO-GAPS.


            READ TABLE lt_alias INTO ls_alias WITH KEY alias = lv_alias BINARY SEARCH.
            IF sy-subrc <> 0.
              CONTINUE.
            ENDIF.

            lv_tabname = ls_alias-tab_name.
          ELSE.
            lv_field = lv_token.
            lv_tabname = lv_main_tab.
          ENDIF.

          REPLACE ALL OCCURRENCES OF gc_symbol-comma  IN lv_field WITH gc_empty.
          REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_field WITH gc_empty.
          CONDENSE lv_field NO-GAPS.
          TRANSLATE lv_field TO UPPER CASE.

          IF lv_field IS INITIAL.
            lv_idx = lv_idx + 1.
            CONTINUE.
          ENDIF.

          IF lv_field CP gc_symbol-pattern_literal
             OR lv_field CP gc_symbol-pattern_var
             OR lv_field = gc_symbol-lparen
             OR lv_field = gc_symbol-rparen
             OR lv_field = gc_symbol-c_equal
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

      " 3.2 Key Fields Used
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

            REPLACE ALL OCCURRENCES OF gc_symbol-lparen IN lv_field WITH gc_empty.
            REPLACE ALL OCCURRENCES OF gc_symbol-rparen IN lv_field WITH gc_empty.
            REPLACE ALL OCCURRENCES OF gc_symbol-comma IN lv_field WITH gc_empty.
            REPLACE ALL OCCURRENCES OF gc_symbol-dot IN lv_field WITH gc_empty.
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

      " 3.3 Main SELECT row
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

      " 3.4 JOIN rows
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

    " 4. INSERT
    CLEAR lv_tabname.

    FIND PCRE gc_pcre_insert_into
      IN lv_stmt_uc
      SUBMATCHES lv_tabname.

    IF sy-subrc <> 0 OR lv_tabname IS INITIAL.
      FIND PCRE gc_pcre_insert_from
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

    " 5. UPDATE
    CLEAR lv_tabname.

    FIND PCRE gc_pcre_update
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

    " 6. MODIFY
    CLEAR lv_tabname.

    FIND PCRE gc_pcre_modify
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

    " 7. DELETE
    CLEAR lv_tabname.

    FIND PCRE gc_pcre_delete
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

    "1. Lấy metadata Data Element
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
    IF go_whereused IS INITIAL.
      CREATE OBJECT go_whereused.
    ENDIF.
  ENDMETHOD.


  METHOD export_class_to_excel.

    DATA: lv_class_name    TYPE seoclsname,
          lv_class_objname TYPE sobj_name,
          lv_class_prog    TYPE progname,
          ls_overview      TYPE zcore_st_parameter,
          ls_excel         TYPE zst_gsp04_report,
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

    lv_class_name    = iv_class_name.
    lv_class_objname = iv_class_name.

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
    SELECT trkorr
      UP TO 1 ROWS
      INTO @lv_trkorr
      FROM e071
      WHERE pgmid    = @gc_export-kw_pgmid_r3tr
        AND object   = @gc_export-kw_obj_clas
        AND obj_name = @lv_class_name
      ORDER BY trkorr DESCENDING.
    ENDSELECT.
    IF sy-subrc <> 0.
      CLEAR lv_trkorr.
    ENDIF.

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

    ls_excel-overview = ls_overview.

    ls_excel-class_layout = me->fill_class_layout(
      iv_class_name = lv_class_name ).

    ls_excel-data_element-item = me->fill_data_element(
      iv_objtype = gc_export-kw_obj_clas
      iv_objname = lv_class_objname
    ).
    ls_excel-table-tab_item = me->fill_table(
      iv_objtype = gc_export-kw_obj_clas
      iv_objname = lv_class_objname
    ).
    ls_excel-structure-struc_item = me->fill_structure(
      iv_objtype = gc_export-kw_obj_clas
      iv_objname = lv_class_objname
    ).

    lv_viewer_title = |{ gc_class_prefix }{ lv_class_name }|.

    CLEAR:
    ls_excel-show_overview,
    ls_excel-show_screen_layout,
    ls_excel-show_data_element,
    ls_excel-show_table,
    ls_excel-show_structure,
    ls_excel-show_fm_layout,
    ls_excel-show_class_layout.

    ls_excel-show_overview      = abap_true.
    ls_excel-show_screen_layout = abap_false.
    ls_excel-show_data_element  = abap_true.
    ls_excel-show_table         = abap_true.
    ls_excel-show_structure     = abap_true.
    ls_excel-show_fm_layout     = abap_false.
    ls_excel-show_class_layout  = abap_true.

    me->call_excel_form(
      is_excel        = ls_excel
      iv_viewer_title = lv_viewer_title
      iv_save_as      = |{ gc_class_prefix }{ lv_class_name }{ gc_ext_xlsx }| ).

  ENDMETHOD.


  METHOD export_fm_to_excel.

    DATA: lv_func_name    TYPE rs38l_fnam,
          lv_func_objname TYPE sobj_name,
          lv_progname     TYPE progname,
          lv_area         TYPE rs38l-area,
          ls_overview     TYPE zcore_st_parameter,
          ls_excel        TYPE zst_gsp04_report,
          lv_desc         TYPE trdirt-text,
          lv_package      TYPE tadir-devclass,
          lv_status       TYPE string,
          lv_created_user TYPE tadir-author,
          lv_created_date TYPE reposrc-cdat,
          lv_last_user    TYPE reposrc-unam,
          lv_last_date    TYPE reposrc-udat,
          lv_trkorr       TYPE e071-trkorr.

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

    lv_func_name = iv_func_name.
    TRANSLATE lv_func_name TO UPPER CASE.
    CONDENSE lv_func_name NO-GAPS.

    lv_func_objname = lv_func_name.

    CLEAR: ls_overview,
           ls_excel,
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

    IF lv_progname CP gc_sapl.
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
    CLEAR lv_trkorr.

    SELECT trkorr
      UP TO 1 ROWS
      INTO @lv_trkorr
      FROM e071
      WHERE pgmid    = @gc_export-kw_pgmid_r3tr
        AND object   = @gc_export-kw_obj_func
        AND obj_name = @lv_func_name
      ORDER BY trkorr DESCENDING.
    ENDSELECT.

    IF ( sy-subrc <> 0 OR lv_trkorr IS INITIAL ) AND lv_area IS NOT INITIAL.
      SELECT trkorr
        UP TO 1 ROWS
        INTO @lv_trkorr
        FROM e071
        WHERE pgmid    = @gc_export-kw_pgmid_r3tr
          AND object   = @gc_export-kw_obj_fugr
          AND obj_name = @lv_area
        ORDER BY trkorr DESCENDING.
      ENDSELECT.
    ENDIF.

    IF sy-subrc <> 0.
      CLEAR lv_trkorr.
    ENDIF.

    " Fill overview
    ls_overview = me->fill_overview(
      iv_objtype     = gc_export-kw_obj_func
      iv_objname     = lv_func_objname
      iv_description = lv_desc
      iv_package     = lv_package
      iv_status      = lv_status
      iv_created_by  = lv_created_user
      iv_created_on  = lv_created_date
      iv_changed_by  = lv_last_user
      iv_changed_on  = lv_last_date
      iv_trkorr      = lv_trkorr
      iv_version     = gc_export-kw_na ).

    " Read FM parameters
    SELECT parameter, paramtype, pposition, type, structure, optional, defaultval
      FROM fupararef
      INTO CORRESPONDING FIELDS OF TABLE @lt_params
      WHERE funcname = @lv_func_name.

    SORT lt_params BY pposition.

    TYPES: BEGIN OF lty_funct,
             parameter TYPE funct-parameter,
             kind      TYPE funct-kind,
             spras     TYPE funct-spras,
             stext     TYPE funct-stext,
           END OF lty_funct.
    DATA: lt_funct TYPE TABLE OF lty_funct,
          ls_funct TYPE lty_funct.

    SELECT parameter, kind, spras, stext
      INTO TABLE @lt_funct
      FROM funct
      WHERE funcname = @lv_func_name
        AND spras    = @sy-langu.

    IF sy-langu <> gc_lang_e.
      SELECT parameter, kind, spras, stext
        APPENDING TABLE @lt_funct
        FROM funct
        WHERE funcname = @lv_func_name
          AND spras    = @gc_lang_e.
    ENDIF.

    SORT lt_funct BY parameter kind spras.

    LOOP AT lt_params INTO ls_param.
      CLEAR: ls_fm_row,
             lv_desc_param,
             lv_param_kind.

      CASE ls_param-paramtype.
        WHEN gc_param_i OR gc_param_e OR gc_param_c OR gc_param_t.
          lv_param_kind = gc_param_p.
        WHEN gc_param_x.
          lv_param_kind = gc_param_x.
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.

      READ TABLE lt_funct INTO ls_funct
                 WITH KEY parameter = ls_param-parameter
                          kind      = lv_param_kind
                          spras     = sy-langu
               BINARY SEARCH.

      IF sy-subrc = 0 AND ls_funct-stext IS NOT INITIAL.
        lv_desc_param = ls_funct-stext.
      ELSE.
        READ TABLE lt_funct INTO ls_funct
             WITH KEY parameter = ls_param-parameter
                      kind      = lv_param_kind
                      spras     = gc_lang_e
             BINARY SEARCH.
        IF sy-subrc = 0.
          lv_desc_param = ls_funct-stext.
        ENDIF.
      ENDIF.

      CASE ls_param-paramtype.

        WHEN gc_param_i.
          lv_no_import = lv_no_import + 1.
          ls_fm_row-parameter01 = lv_no_import.
          ls_fm_row-parameter02 = ls_param-parameter.

          IF ls_param-type = gc_mark_x.
            ls_fm_row-parameter03 = gc_type.
          ELSE.
            ls_fm_row-parameter03 = gc_like.
          ENDIF.

          ls_fm_row-parameter04 = ls_param-structure.

          IF ls_param-optional = gc_mark_x.
            ls_fm_row-parameter05 = gc_mark_x.
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

          APPEND ls_fm_row TO ls_excel-fm_import.

        WHEN gc_param_e.
          lv_no_export = lv_no_export + 1.
          ls_fm_row-parameter01 = lv_no_export.
          ls_fm_row-parameter02 = ls_param-parameter.

          IF ls_param-type = gc_mark_x.
            ls_fm_row-parameter03 = gc_type.
          ELSE.
            ls_fm_row-parameter03 = gc_like.
          ENDIF.

          ls_fm_row-parameter04 = ls_param-structure.
          ls_fm_row-parameter05 = lv_desc_param.

          IF ls_fm_row-parameter04 IS INITIAL.
            ls_fm_row-parameter04 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter05 IS INITIAL.
            ls_fm_row-parameter05 = gc_export-kw_na.
          ENDIF.

          APPEND ls_fm_row TO ls_excel-fm_export.

        WHEN gc_param_c.
          lv_no_changing = lv_no_changing + 1.
          ls_fm_row-parameter01 = lv_no_changing.
          ls_fm_row-parameter02 = ls_param-parameter.

          IF ls_param-type = gc_mark_x.
            ls_fm_row-parameter03 = gc_type.
          ELSE.
            ls_fm_row-parameter03 = gc_like.
          ENDIF.

          ls_fm_row-parameter04 = ls_param-structure.

          IF ls_param-optional = gc_mark_x.
            ls_fm_row-parameter05 = gc_mark_x.
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

          APPEND ls_fm_row TO ls_excel-fm_changing.

        WHEN gc_param_t.
          lv_no_tables = lv_no_tables + 1.
          ls_fm_row-parameter01 = lv_no_tables.
          ls_fm_row-parameter02 = ls_param-parameter.

          IF ls_param-type = gc_mark_x.
            ls_fm_row-parameter03 = gc_type.
          ELSEIF ls_param-structure IS NOT INITIAL.
            ls_fm_row-parameter03 = gc_structure.
          ELSE.
            ls_fm_row-parameter03 = gc_like.
          ENDIF.

          ls_fm_row-parameter04 = ls_param-structure.
          ls_fm_row-parameter05 = lv_desc_param.

          IF ls_fm_row-parameter04 IS INITIAL.
            ls_fm_row-parameter04 = gc_export-kw_na.
          ENDIF.
          IF ls_fm_row-parameter05 IS INITIAL.
            ls_fm_row-parameter05 = gc_export-kw_na.
          ENDIF.

          APPEND ls_fm_row TO ls_excel-fm_tables.

        WHEN gc_param_x.
          lv_no_exception = lv_no_exception + 1.
          ls_fm_row-parameter01 = lv_no_exception.
          ls_fm_row-parameter02 = ls_param-parameter.
          ls_fm_row-parameter03 = lv_desc_param.

          IF ls_fm_row-parameter03 IS INITIAL.
            ls_fm_row-parameter03 = gc_export-kw_na.
          ENDIF.

          APPEND ls_fm_row TO ls_excel-fm_exception.

      ENDCASE.
    ENDLOOP.

    " Fill empty FM parameter sections with one N/A row
    IF ls_excel-fm_import IS INITIAL.
      CLEAR ls_fm_row.
      ls_fm_row-parameter01 = gc_export-kw_na.
      ls_fm_row-parameter02 = gc_export-kw_na.
      ls_fm_row-parameter03 = gc_export-kw_na.
      ls_fm_row-parameter04 = gc_export-kw_na.
      ls_fm_row-parameter05 = gc_export-kw_na.
      ls_fm_row-parameter06 = gc_export-kw_na.
      ls_fm_row-parameter07 = gc_export-kw_na.
      APPEND ls_fm_row TO ls_excel-fm_import.
    ENDIF.

    IF ls_excel-fm_export IS INITIAL.
      CLEAR ls_fm_row.
      ls_fm_row-parameter01 = gc_export-kw_na.
      ls_fm_row-parameter02 = gc_export-kw_na.
      ls_fm_row-parameter03 = gc_export-kw_na.
      ls_fm_row-parameter04 = gc_export-kw_na.
      ls_fm_row-parameter05 = gc_export-kw_na.
      APPEND ls_fm_row TO ls_excel-fm_export.
    ENDIF.

    IF ls_excel-fm_changing IS INITIAL.
      CLEAR ls_fm_row.
      ls_fm_row-parameter01 = gc_export-kw_na.
      ls_fm_row-parameter02 = gc_export-kw_na.
      ls_fm_row-parameter03 = gc_export-kw_na.
      ls_fm_row-parameter04 = gc_export-kw_na.
      ls_fm_row-parameter05 = gc_export-kw_na.
      ls_fm_row-parameter06 = gc_export-kw_na.
      ls_fm_row-parameter07 = gc_export-kw_na.
      APPEND ls_fm_row TO ls_excel-fm_changing.
    ENDIF.

    IF ls_excel-fm_tables IS INITIAL.
      CLEAR ls_fm_row.
      ls_fm_row-parameter01 = gc_export-kw_na.
      ls_fm_row-parameter02 = gc_export-kw_na.
      ls_fm_row-parameter03 = gc_export-kw_na.
      ls_fm_row-parameter04 = gc_export-kw_na.
      ls_fm_row-parameter05 = gc_export-kw_na.
      APPEND ls_fm_row TO ls_excel-fm_tables.
    ENDIF.

    IF ls_excel-fm_exception IS INITIAL.
      CLEAR ls_fm_row.
      ls_fm_row-parameter01 = gc_export-kw_na.
      ls_fm_row-parameter02 = gc_export-kw_na.
      ls_fm_row-parameter03 = gc_export-kw_na.
      APPEND ls_fm_row TO ls_excel-fm_exception.
    ENDIF.

    ls_excel-overview = ls_overview.

    ls_excel-data_element-item = me->fill_data_element(
      iv_objtype = gc_export-kw_obj_func
      iv_objname = lv_func_objname ).

    ls_excel-table-tab_item = me->fill_table(
      iv_objtype = gc_export-kw_obj_func
      iv_objname = lv_func_objname ).

    ls_excel-structure-struc_item = me->fill_structure(
      iv_objtype = gc_export-kw_obj_func
      iv_objname = lv_func_objname ).

    lv_viewer_title      = |{ gc_fm_prefix }{ lv_func_name }|.

    CLEAR: ls_excel-show_overview,
           ls_excel-show_screen_layout,
           ls_excel-show_data_element,
           ls_excel-show_table,
           ls_excel-show_structure,
           ls_excel-show_fm_layout,
           ls_excel-show_class_layout.

    ls_excel-show_overview      = abap_true.
    ls_excel-show_screen_layout = abap_false.
    ls_excel-show_data_element  = abap_true.
    ls_excel-show_table         = abap_true.
    ls_excel-show_structure     = abap_true.
    ls_excel-show_fm_layout     = abap_true.
    ls_excel-show_class_layout  = abap_false.

    me->call_excel_form(
      is_excel           = ls_excel
      iv_viewer_title    = lv_viewer_title
      iv_direct_download = iv_direct_download
      iv_save_as         = iv_save_as ).

  ENDMETHOD.


  METHOD export_fugr_to_excel.

    DATA: ls_fg_fm   TYPE gty_fg_fm,
          lv_fugr    TYPE rs38l-area,
          lo_salv    TYPE REF TO cl_salv_table,
          lo_columns TYPE REF TO cl_salv_columns_table,
          lo_column  TYPE REF TO cl_salv_column_table,
          lo_select  TYPE REF TO cl_salv_selections,
          lo_events  TYPE REF TO cl_salv_events_table,
          lt_rows    TYPE salv_t_row,
          lv_row     TYPE salv_de_row,
          lv_ucomm   TYPE sy-ucomm.

    lv_fugr = iv_fugr_name.
    TRANSLATE lv_fugr TO UPPER CASE.
    CONDENSE lv_fugr NO-GAPS.

    CLEAR gt_fg_fm.


    TYPES: BEGIN OF lty_enlfdir,
             funcname TYPE enlfdir-funcname,
           END OF lty_enlfdir.
    DATA lt_enlfdir TYPE STANDARD TABLE OF lty_enlfdir.

    SELECT funcname
      INTO TABLE @lt_enlfdir
      FROM enlfdir
      WHERE area = @lv_fugr.                          "#EC CI_SGLSELECT

    IF lt_enlfdir IS INITIAL.
      MESSAGE ID gc_msg_class_gsp TYPE gc_msgty_s NUMBER gc_msg_no_083 WITH lv_fugr DISPLAY LIKE gc_msgty_e.
      RETURN.
    ENDIF.


    TYPES: BEGIN OF lty_tftit,
             funcname TYPE tftit-funcname,
             stext    TYPE tftit-stext,
           END OF lty_tftit.

    DATA lt_tftit TYPE STANDARD TABLE OF lty_tftit.

    SELECT funcname, stext
      INTO TABLE @lt_tftit
      FROM tftit
      FOR ALL ENTRIES IN @lt_enlfdir
      WHERE funcname = @lt_enlfdir-funcname
        AND spras    = @sy-langu.


    SORT lt_tftit BY funcname.

    LOOP AT lt_enlfdir INTO DATA(ls_enlfdir).
      ls_fg_fm-fm_name = ls_enlfdir-funcname.

      READ TABLE lt_tftit INTO DATA(ls_text)
           WITH KEY funcname = ls_enlfdir-funcname BINARY SEARCH.

      IF sy-subrc = 0 AND ls_text-stext IS NOT INITIAL.
        ls_fg_fm-description = ls_text-stext.
      ELSE.
        ls_fg_fm-description = ls_enlfdir-funcname.
      ENDIF.

      ls_fg_fm-download = icon_export.
      APPEND ls_fg_fm TO gt_fg_fm.
      CLEAR ls_fg_fm.
    ENDLOOP.

    SORT gt_fg_fm BY fm_name.

    DO.
      CLEAR: lo_salv, lo_columns, lo_column, lo_select, lo_events, lt_rows, lv_row, lv_ucomm.

      TRY.
          cl_salv_table=>factory(
            IMPORTING r_salv_table = lo_salv
            CHANGING  t_table      = gt_fg_fm ).

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
              lo_column ?= lo_columns->get_column( gc_col_fm_name ).
              lo_column->set_long_text( gc_text_fm_name ).
              lo_column->set_medium_text( CONV #( gc_text_fm_name ) ).
              lo_column->set_short_text( CONV #( gc_text_fm_name ) ).
              lo_column->set_output_length( 35 ).
            CATCH cx_salv_not_found.
          ENDTRY.

          TRY.
              lo_column ?= lo_columns->get_column( gc_col_desc ).
              lo_column->set_long_text( gc_text_desc_long ).
              lo_column->set_medium_text( CONV #( gc_text_desc_long ) ).
              lo_column->set_short_text( gc_text_desc_short ).
              lo_column->set_output_length( 70 ).
            CATCH cx_salv_not_found.
          ENDTRY.

          TRY.
              lo_column ?= lo_columns->get_column( gc_col_download ).
              lo_column->set_long_text( gc_text_export ).
              lo_column->set_medium_text( CONV #( gc_text_export ) ).
              lo_column->set_short_text( CONV #( gc_text_export ) ).
              lo_column->set_icon( if_salv_c_bool_sap=>true ).
              lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
              lo_column->set_output_length( 10 ).
            CATCH cx_salv_not_found.
          ENDTRY.

          lo_events = lo_salv->get_event( ).
          SET HANDLER me->helper_fugr_download FOR lo_events.

          lo_salv->display( ).
          lv_ucomm = sy-ucomm.

        CATCH cx_salv_msg INTO DATA(lx_salv).
          MESSAGE lx_salv->get_text( ) TYPE gc_msgty_s DISPLAY LIKE gc_msgty_e.
          RETURN.
      ENDTRY.

      CASE lv_ucomm.
        WHEN gc_ucomm_ont.
          lt_rows = lo_select->get_selected_rows( ).
          READ TABLE lt_rows INTO lv_row INDEX 1.
          IF sy-subrc <> 0.
            MESSAGE ID gc_msg_class_gsp TYPE gc_msgty_s NUMBER gc_msg_no_082 DISPLAY LIKE gc_msgty_e.
            CONTINUE.
          ENDIF.

          READ TABLE gt_fg_fm INTO ls_fg_fm INDEX lv_row.
          IF sy-subrc <> 0 OR ls_fg_fm-fm_name IS INITIAL.
            CONTINUE.
          ENDIF.

          me->export_fm_to_excel(
            iv_func_name       = ls_fg_fm-fm_name
            iv_direct_download = abap_false
            iv_save_as         = gc_empty ).
          CONTINUE.

        WHEN gc_ucomm_double_click.
          CONTINUE.

        WHEN OTHERS.
          RETURN.
      ENDCASE.
    ENDDO.

  ENDMETHOD.


  METHOD export_program_to_excel.

    DATA: lv_prog_name    TYPE progname,
          ls_overview     TYPE zcore_st_parameter,
          ls_excel        TYPE zst_gsp04_report,
          lv_desc         TYPE trdirt-text,
          lv_package      TYPE tadir-devclass,
          lv_status       TYPE string,
          lv_last_user    TYPE reposrc-unam,
          lv_last_date    TYPE reposrc-udat,
          lv_created_user TYPE reposrc-cnam,
          lv_created_date TYPE reposrc-cdat,
          lv_tcode        TYPE tstc-tcode,
          lv_trkorr       TYPE e071-trkorr,
          lv_viewer_title TYPE string.

    "Normalize input
    lv_prog_name = iv_prog_name.
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
    SELECT trkorr
        UP TO 1 ROWS
        INTO @lv_trkorr
        FROM e071
        WHERE pgmid    = @gc_export-kw_pgmid_r3tr
          AND object   = @gc_export-kw_obj_prog
          AND obj_name = @lv_prog_name
        ORDER BY trkorr DESCENDING.
    ENDSELECT.

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
      iv_program_name  = lv_prog_name
    CHANGING
      cs_screen_layout = ls_excel-screen_layout ).

    ls_excel-overview = ls_overview.

    ls_excel-data_element-item = me->fill_data_element(
    iv_objtype = gc_export-kw_obj_prog
    iv_objname = lv_prog_name ).

    ls_excel-table-tab_item = me->fill_table(
      iv_objtype = gc_export-kw_obj_prog
      iv_objname = lv_prog_name ).

    ls_excel-structure-struc_item = me->fill_structure(
      iv_objtype = gc_export-kw_obj_prog
      iv_objname = lv_prog_name ).


    lv_viewer_title = |{ gc_prog_prefix }{ lv_prog_name }|.

    CLEAR:
    ls_excel-show_overview,
    ls_excel-show_screen_layout,
    ls_excel-show_data_element,
    ls_excel-show_table,
    ls_excel-show_structure,
    ls_excel-show_fm_layout,
    ls_excel-show_class_layout.

    ls_excel-show_overview      = abap_true.
    ls_excel-show_screen_layout = abap_true.
    ls_excel-show_data_element  = abap_true.
    ls_excel-show_table         = abap_true.
    ls_excel-show_structure     = abap_true.
    ls_excel-show_fm_layout     = abap_false.
    ls_excel-show_class_layout  = abap_false.

    me->call_excel_form(
      is_excel        = ls_excel
      iv_viewer_title = lv_viewer_title

      iv_save_as      = |{ gc_prog_prefix }{ lv_prog_name }{ gc_ext_xlsx }| ).

  ENDMETHOD.


  METHOD fill_class_layout.

    DATA: lv_class_name   TYPE seoclsname,
          lt_class_source TYPE gty_t_class_source.

    CLEAR rs_layout.

    me->ensure_objects( ).

    lv_class_name = iv_class_name.
    TRANSLATE lv_class_name TO UPPER CASE.
    CONDENSE lv_class_name NO-GAPS.

    lt_class_source = me->go_fetch->get_class( iv_class_name = lv_class_name ).

    me->fill_class_layout_classdef(
      EXPORTING
        iv_class_name    = lv_class_name
      CHANGING
        cs_layout        = rs_layout ).

    me->fill_class_layout_attr(
      EXPORTING
        iv_class_name    = lv_class_name
        it_class_source  = lt_class_source
      CHANGING
        cs_layout        = rs_layout ).

    me->fill_class_layout_method(
      EXPORTING
        iv_class_name    = lv_class_name
        it_class_source = lt_class_source
      CHANGING
        cs_layout        = rs_layout ).

    me->fill_class_layout_param(
      EXPORTING
        iv_class_name    = lv_class_name
        it_class_source  = lt_class_source
      CHANGING
        cs_layout        = rs_layout ).

    me->normalize_class_layout(
      CHANGING
        cs_layout = rs_layout ).

  ENDMETHOD.


  METHOD fill_class_layout_attr.

    TYPES: BEGIN OF lty_comp_meta,
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
           END OF lty_comp_meta.

    TYPES: BEGIN OF lty_comp_text,
             clsname  TYPE seoclsname,
             cmpname  TYPE seocmpname,
             langu    TYPE sylangu,
             descript TYPE seodescr,
           END OF lty_comp_text.

    DATA: lv_class_name TYPE seoclsname,
          ls_attr       TYPE zst_src_class_attr,
          ls_comp       TYPE lty_comp_meta,
          ls_comp_txt   TYPE lty_comp_text,
          lt_comp_meta  TYPE STANDARD TABLE OF lty_comp_meta,
          lt_comp_text  TYPE STANDARD TABLE OF lty_comp_text.

    DATA: ls_clskey   TYPE seoclskey,
          lt_seo_attr TYPE seoo_attributes_r.

    DATA: lv_col_index TYPE i.

    FIELD-SYMBOLS: <lfs_attr_dummy> TYPE any,
                   <lfs_field_dyn>  TYPE any.

    " 1. Prepare Class Name
    lv_class_name = iv_class_name.
    TRANSLATE lv_class_name TO UPPER CASE.
    CONDENSE lv_class_name NO-GAPS.

    " 2. Fetch Metadata from SEOCOMPODF
    CLEAR lt_comp_meta.
    SELECT clsname cmpname version state exposure attdecltyp attrdonly
           attvalue attdynamic attexpvirt mtddecltyp mtdabstrct mtdfinal
      INTO TABLE lt_comp_meta
      FROM seocompodf
      WHERE clsname = lv_class_name
        AND version = gc_version_active
        AND state   = gc_state_active.

    " 3. Fetch Texts from SEOCOMPOTX
    CLEAR lt_comp_text.
    SELECT clsname cmpname langu descript
      INTO TABLE lt_comp_text
      FROM seocompotx
      WHERE clsname = lv_class_name
        AND langu   = sy-langu.

    " 4. Call SEO Typeinfo for extended attributes (Fix SLIN here)
    CLEAR: ls_clskey, lt_seo_attr.
    ls_clskey-clsname = lv_class_name.

    CALL FUNCTION gc_fn_seo_typeinfo
      EXPORTING
        clskey            = ls_clskey
        state             = gc_state_active
        with_descriptions = seox_true
      IMPORTING
        attributes        = lt_seo_attr
      EXCEPTIONS
        not_existing      = 1
        is_interface      = 2
        model_only        = 3
        OTHERS            = 4.
    CASE sy-subrc.
      WHEN 0.
        " OK

      WHEN 1. " not_existing
        CLEAR lt_seo_attr.

      WHEN 2. " is_interface
        CLEAR lt_seo_attr.

      WHEN 3. " model_only
        CLEAR lt_seo_attr.

      WHEN 4. " others
        CLEAR lt_seo_attr.

      WHEN OTHERS.
        CLEAR lt_seo_attr.
    ENDCASE.
    SORT lt_comp_text BY clsname cmpname langu.
    SORT lt_seo_attr BY cmpname.
    IF sy-subrc <> 0.
      CLEAR lt_seo_attr. " Prevent processing garbage data if FM fails
    ENDIF.

    " 5. Map attributes to Layout Structure
    LOOP AT lt_comp_meta INTO ls_comp.
      IF ls_comp-cmpname IS INITIAL OR ls_comp-attdecltyp IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR ls_attr.

      ls_attr-attr_name = ls_comp-cmpname.
      TRANSLATE ls_attr-attr_name TO UPPER CASE.
      CONDENSE ls_attr-attr_name NO-GAPS.

      " Map Exposure (Visibility: Public, Protected, Private)
      CASE ls_comp-exposure.
        WHEN gc_comp_exp_0.
          ls_attr-attr_section = gc_comp_sec_priv.
        WHEN gc_comp_exp_1.
          ls_attr-attr_section = gc_comp_sec_prot.
        WHEN gc_comp_exp_2.
          ls_attr-attr_section = gc_comp_sec_pub.
        WHEN OTHERS.
          ls_attr-attr_section = gc_na.
      ENDCASE.

      " Map Declaration Type (Instance, Static, Constant)
      CASE ls_comp-attdecltyp.
        WHEN gc_comp_decl_0.
          ls_attr-attr_level = gc_comp_lvl_inst.
        WHEN gc_comp_decl_1.
          ls_attr-attr_level = gc_comp_lvl_stat.
        WHEN gc_comp_decl_2.
          ls_attr-attr_level = gc_comp_lvl_const.
        WHEN OTHERS.
          ls_attr-attr_level = ls_comp-attdecltyp.
      ENDCASE.

      " Map Read-Only flag
      IF ls_comp-attrdonly IS NOT INITIAL.
        ls_attr-read_only = gc_mark_x.
      ELSE.
        ls_attr-read_only = gc_na.
      ENDIF.

      " Map Default Value
      IF ls_comp-attvalue IS NOT INITIAL.
        ls_attr-default_value = ls_comp-attvalue.
      ELSE.
        ls_attr-default_value = gc_na.
      ENDIF.

      " Get Description
      CLEAR ls_comp_txt.
      READ TABLE lt_comp_text INTO ls_comp_txt
        WITH KEY clsname = lv_class_name
                 cmpname = ls_comp-cmpname
                 langu   = sy-langu
                 BINARY SEARCH.

      IF sy-subrc = 0 AND ls_comp_txt-descript IS NOT INITIAL.
        ls_attr-attr_description = ls_comp_txt-descript.
      ELSE.
        ls_attr-attr_description = gc_na.
      ENDIF.

      ls_attr-type_name = gc_na.

      " Enhance mapping with SEO Typeinfo data
      READ TABLE lt_seo_attr ASSIGNING FIELD-SYMBOL(<lfs_seo_attr>)
        WITH KEY cmpname = ls_comp-cmpname
        BINARY SEARCH.

      IF sy-subrc = 0.
        IF ( ls_attr-read_only IS INITIAL OR ls_attr-read_only = gc_na ) AND <lfs_seo_attr>-attrdonly IS NOT INITIAL.
          ls_attr-read_only = gc_mark_x.
        ENDIF.

        IF ( ls_attr-default_value IS INITIAL OR ls_attr-default_value = gc_na ) AND <lfs_seo_attr>-attvalue IS NOT INITIAL.
          ls_attr-default_value = <lfs_seo_attr>-attvalue.
        ENDIF.

        IF ( ls_attr-attr_description IS INITIAL OR ls_attr-attr_description = gc_na ).
          IF <lfs_seo_attr>-descript IS NOT INITIAL.
            ls_attr-attr_description = <lfs_seo_attr>-descript.
          ENDIF.
        ENDIF.
      ENDIF.

      " Fallback N/A for empty fields
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

      APPEND ls_attr TO cs_layout-attributes.
    ENDLOOP.

    " 6. Sort and Remove Duplicates
    SORT cs_layout-attributes BY attr_name attr_section attr_level.
    DELETE ADJACENT DUPLICATES FROM cs_layout-attributes
      COMPARING attr_name attr_section attr_level.

    " 7. Handle Empty Attributes Table (Create Dummy N/A Line)
    IF cs_layout-attributes IS INITIAL.
      APPEND INITIAL LINE TO cs_layout-attributes ASSIGNING <lfs_attr_dummy>.
      IF <lfs_attr_dummy> IS ASSIGNED.
        lv_col_index = 1.
        DO.
          ASSIGN COMPONENT lv_col_index OF STRUCTURE <lfs_attr_dummy> TO <lfs_field_dyn>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          TRY.
              <lfs_field_dyn> = gc_na.
            CATCH cx_root.
              " Ignore type mismatch errors if field cannot hold gc_na
          ENDTRY.

          lv_col_index = lv_col_index + 1.
        ENDDO.
      ENDIF.
    ENDIF.

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
          ls_rel        TYPE gty_rel_meta,
          lt_rel_meta   TYPE STANDARD TABLE OF gty_rel_meta,
          lt_pool_src   TYPE STANDARD TABLE OF string.

    lv_class_name = iv_class_name.
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
        WHEN gc_clstype_0.
          ls_class_def-class_type = gc_cls_type_class.
        WHEN gc_clstype_1.
          ls_class_def-class_type = gc_cls_type_intf.
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
        AND version = gc_clstype_1
        AND state   = gc_clstype_1
      ORDER BY reltype refclsname.

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

      IF lv_line CS gc_dot.
        lv_stmt_uc = lv_stmt.
        TRANSLATE lv_stmt_uc TO UPPER CASE.

        IF lv_stmt_uc CS gc_kw_class
           AND lv_stmt_uc CS lv_class_name
           AND lv_stmt_uc CS gc_kw_class_def.
          lv_decl_stmt = lv_stmt.
        ENDIF.

        IF lv_stmt_uc CP gc_kw_interfaces_pat.
          CLEAR lv_temp.
          FIND PCRE gc_pcre_intf
            IN lv_stmt
            SUBMATCHES lv_temp.
          IF sy-subrc = 0 AND lv_temp IS NOT INITIAL.
            TRANSLATE lv_temp TO UPPER CASE.
            CONDENSE lv_temp NO-GAPS.
            IF lv_interfaces IS INITIAL.
              lv_interfaces = lv_temp.
            ELSEIF lv_interfaces NS lv_temp.
              CONCATENATE lv_interfaces lv_temp INTO lv_interfaces SEPARATED BY gc_comma_space.
            ENDIF.
          ENDIF.
        ENDIF.

        CLEAR lv_stmt.
      ENDIF.
    ENDLOOP.

    IF lv_decl_stmt IS NOT INITIAL.
      lv_stmt_uc = lv_decl_stmt.
      TRANSLATE lv_stmt_uc TO UPPER CASE.

      IF lv_stmt_uc CS gc_kw_final.
        ls_class_def-is_final = gc_mark_x.
      ENDIF.

      IF lv_stmt_uc CS gc_kw_abstract.
        ls_class_def-is_abstract = gc_mark_x.
      ENDIF.

      IF lv_stmt_uc CS gc_kw_create_pub.
        ls_class_def-create_visibility = gc_comp_sec_pub.
      ELSEIF lv_stmt_uc CS gc_kw_create_prot.
        ls_class_def-create_visibility = gc_comp_sec_prot.
      ELSEIF lv_stmt_uc CS gc_kw_create_priv.
        ls_class_def-create_visibility = gc_comp_sec_priv.
      ENDIF.

      CLEAR lv_superclass.
      FIND PCRE gc_pcre_inher
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

    cs_layout-class_def = ls_class_def.

  ENDMETHOD.


  METHOD fill_class_layout_method.

    TYPES: BEGIN OF lty_method_idx,
             method_name TYPE string,
             tabix       TYPE sy-tabix,
           END OF lty_method_idx.

    DATA: lv_class_name        TYPE seoclsname,
          lv_line              TYPE string,
          lv_stmt              TYPE string,
          lv_stmt_uc           TYPE string,
          lv_temp              TYPE string,
          lv_section           TYPE char20,
          lv_keyword           TYPE string,
          lv_name              TYPE string,
          lv_method_part       TYPE string,
          lv_len               TYPE i,
          lv_idx               TYPE i,
          lv_depth             TYPE i,
          lv_offset            TYPE i,
          lv_char              TYPE c LENGTH 1,
          lv_buf               TYPE string,
          lv_is_section        TYPE abap_bool VALUE abap_false,
          lv_method_tabix      TYPE sy-tabix,
          ls_meth              TYPE zst_src_class_meth,
          ls_src               TYPE gty_class_source,
          ls_comp              TYPE gty_comp_meta,
          ls_comp_txt          TYPE gty_comp_text,
          ls_method_idx        TYPE lty_method_idx,
          lt_method_parts      TYPE STANDARD TABLE OF string,
          lt_comp_meta         TYPE STANDARD TABLE OF gty_comp_meta,
          lt_comp_text         TYPE STANDARD TABLE OF gty_comp_text,
          lt_class_source_sort TYPE STANDARD TABLE OF gty_class_source,
          lt_method_idx        TYPE HASHED TABLE OF lty_method_idx
                               WITH UNIQUE KEY method_name.

    DATA: lv_lines_src   TYPE i,
          lv_idx_src     TYPE i,
          lv_lines_parts TYPE i,
          lv_idx_parts   TYPE i,
          lv_col_index   TYPE i.

    FIELD-SYMBOLS: <lfs_meth>      TYPE zst_src_class_meth,
                   <lfs_field_dyn> TYPE any.

    lv_class_name = iv_class_name.
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
        AND version = gc_comp_exp_1
        AND state   = gc_comp_exp_1.

    SELECT clsname
           cmpname
           langu
           descript
      INTO TABLE lt_comp_text
      FROM seocompotx
      WHERE clsname = lv_class_name
        AND langu   = sy-langu.

    SORT lt_comp_text BY clsname cmpname langu.

    lt_class_source_sort = it_class_source.
    SORT lt_class_source_sort BY method_name.

    LOOP AT lt_comp_meta INTO ls_comp.
      IF ls_comp-cmpname IS NOT INITIAL
         AND ls_comp-mtddecltyp IS NOT INITIAL.

        CLEAR ls_meth.
        ls_meth-method_name = ls_comp-cmpname.
        TRANSLATE ls_meth-method_name TO UPPER CASE.
        CONDENSE ls_meth-method_name NO-GAPS.

        CASE ls_comp-exposure.
          WHEN gc_comp_exp_0.
            ls_meth-visibility = gc_comp_sec_priv.
          WHEN gc_comp_exp_1.
            ls_meth-visibility = gc_comp_sec_prot.
          WHEN gc_comp_exp_2.
            ls_meth-visibility = gc_comp_sec_pub.
          WHEN OTHERS.
            ls_meth-visibility = gc_na.
        ENDCASE.

        CASE ls_comp-mtddecltyp.
          WHEN gc_comp_decl_0.
            ls_meth-method_level = gc_comp_lvl_inst.
          WHEN gc_comp_decl_1.
            ls_meth-method_level = gc_comp_lvl_stat.
          WHEN OTHERS.
            ls_meth-method_level = ls_comp-mtddecltyp.
        ENDCASE.

        IF ls_meth-method_name = gc_meth_constr.
          ls_meth-method_type = gc_meth_type_constr.
        ELSEIF ls_meth-method_name = gc_meth_cls_constr.
          ls_meth-method_type = gc_meth_type_cls_con.
        ELSEIF ls_comp-mtdabstrct IS NOT INITIAL.
          ls_meth-method_type = gc_meth_type_abstr.
        ELSE.
          ls_meth-method_type = gc_meth_type_norm.
        ENDIF.

        CLEAR ls_comp_txt.
        READ TABLE lt_comp_text INTO ls_comp_txt
          WITH KEY clsname = lv_class_name
                   cmpname = ls_comp-cmpname
                   langu   = sy-langu
          BINARY SEARCH.
        IF sy-subrc = 0 AND ls_comp_txt-descript IS NOT INITIAL.
          ls_meth-method_description = ls_comp_txt-descript.
        ELSE.
          CLEAR ls_src.
          READ TABLE lt_class_source_sort INTO ls_src
            WITH KEY method_name = ls_meth-method_name
            BINARY SEARCH.
          IF sy-subrc = 0 AND ls_src-description IS NOT INITIAL.
            ls_meth-method_description = ls_src-description.
          ELSE.
            ls_meth-method_description = gc_na.
          ENDIF.
        ENDIF.

        APPEND ls_meth TO cs_layout-methods.
      ENDIF.
    ENDLOOP.

    CLEAR lt_method_idx.

    LOOP AT cs_layout-methods INTO ls_meth.
      IF ls_meth-method_name IS INITIAL.
        CONTINUE.
      ENDIF.

      INSERT VALUE lty_method_idx(
        method_name = ls_meth-method_name
        tabix       = sy-tabix
      ) INTO TABLE lt_method_idx.
    ENDLOOP.

    CLEAR lv_section.

    LOOP AT it_class_source INTO ls_src.

      CLEAR lv_is_section.
      IF ls_src-include_kind = gc_section_kw.
        lv_is_section = abap_true.
      ENDIF.

      IF lv_is_section = abap_false.

        IF ls_src-method_name IS NOT INITIAL.
          lv_name = ls_src-method_name.
          TRANSLATE lv_name TO UPPER CASE.
          CONDENSE lv_name NO-GAPS.

          UNASSIGN <lfs_meth>.
          CLEAR ls_method_idx.

          READ TABLE lt_method_idx INTO ls_method_idx
            WITH TABLE KEY method_name = lv_name.

          IF sy-subrc = 0.
            READ TABLE cs_layout-methods ASSIGNING <lfs_meth>
              INDEX ls_method_idx-tabix.
          ENDIF.

          IF <lfs_meth> IS NOT ASSIGNED.
            CLEAR ls_meth.
            ls_meth-method_name = lv_name.

            IF ls_src-method_level IS NOT INITIAL.
              ls_meth-method_level = ls_src-method_level.
            ELSE.
              ls_meth-method_level = gc_na.
            ENDIF.

            IF ls_src-section IS NOT INITIAL.
              ls_meth-visibility = ls_src-section.
            ELSE.
              ls_meth-visibility = gc_na.
            ENDIF.

            IF lv_name = gc_meth_constr.
              ls_meth-method_type = gc_meth_type_constr.
            ELSEIF lv_name = gc_meth_cls_constr.
              ls_meth-method_type = gc_meth_type_cls_con.
            ELSE.
              ls_meth-method_type = gc_meth_type_norm.
            ENDIF.

            IF ls_src-description IS NOT INITIAL.
              ls_meth-method_description = ls_src-description.
            ELSE.
              ls_meth-method_description = gc_na.
            ENDIF.

            APPEND ls_meth TO cs_layout-methods.
            lv_method_tabix = lines( cs_layout-methods ).

            INSERT VALUE lty_method_idx(
              method_name = ls_meth-method_name
              tabix       = lv_method_tabix
            ) INTO TABLE lt_method_idx.
            READ TABLE cs_layout-methods ASSIGNING <lfs_meth>
              INDEX lv_method_tabix.
          ELSE.

            IF ( <lfs_meth>-method_description IS INITIAL
              OR <lfs_meth>-method_description = gc_na )
              AND ls_src-description IS NOT INITIAL.
              <lfs_meth>-method_description = ls_src-description.
            ENDIF.

            IF ( <lfs_meth>-visibility IS INITIAL
              OR <lfs_meth>-visibility = gc_na )
              AND ls_src-section IS NOT INITIAL.
              <lfs_meth>-visibility = ls_src-section.
            ENDIF.

            IF ( <lfs_meth>-method_level IS INITIAL
              OR <lfs_meth>-method_level = gc_na )
              AND ls_src-method_level IS NOT INITIAL.
              <lfs_meth>-method_level = ls_src-method_level.
            ENDIF.

          ENDIF.
        ENDIF.

        CONTINUE.
      ENDIF.

      lv_section = ls_src-section.
      TRANSLATE lv_section TO UPPER CASE.
      CONDENSE lv_section NO-GAPS.

      CLEAR lv_stmt.

      lv_lines_src = lines( ls_src-source_code ).
      lv_idx_src   = 1.

      WHILE lv_idx_src <= lv_lines_src.
        READ TABLE ls_src-source_code INTO lv_line INDEX lv_idx_src.
        lv_idx_src = lv_idx_src + 1.

        IF lv_line IS INITIAL.
          CONTINUE.
        ENDIF.

        IF lv_stmt IS INITIAL.
          lv_stmt = lv_line.
        ELSE.
          CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
        ENDIF.

        IF lv_line NS gc_dot.
          CONTINUE.
        ENDIF.

        CONDENSE lv_stmt.
        IF lv_stmt IS INITIAL.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        lv_stmt_uc = lv_stmt.
        TRANSLATE lv_stmt_uc TO UPPER CASE.

        IF lv_stmt_uc CP gc_kw_methods_pat
           OR lv_stmt_uc CP gc_kw_cls_meth_pat.

          CLEAR lt_method_parts.
          CLEAR: lv_keyword, lv_temp.

          FIND PCRE gc_pcre_meth_decl1
            IN lv_stmt
            SUBMATCHES lv_keyword lv_temp.

          IF sy-subrc <> 0.
            FIND PCRE gc_pcre_meth_decl2
              IN lv_stmt
              SUBMATCHES lv_keyword lv_temp.
          ENDIF.

          IF sy-subrc = 0 AND lv_temp IS NOT INITIAL.

            CONDENSE lv_temp.
            lv_len = strlen( lv_temp ).
            IF lv_len > 0.
              lv_offset = lv_len - 1.
              IF lv_temp+lv_offset(1) = gc_dot.
                lv_temp = lv_temp(lv_offset).
              ENDIF.
            ENDIF.

            CLEAR: lv_buf, lv_depth.
            lv_len = strlen( lv_temp ).

            DO lv_len TIMES.
              lv_idx = sy-index - 1.
              lv_char = lv_temp+lv_idx(1).

              IF lv_char = gc_symbol-lparen .
                lv_depth = lv_depth + 1.
              ELSEIF lv_char = gc_symbol-rparen .
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

            " ====================================================================
            lv_lines_parts = lines( lt_method_parts ).
            lv_idx_parts   = 1.

            WHILE lv_idx_parts <= lv_lines_parts.
              READ TABLE lt_method_parts INTO lv_method_part INDEX lv_idx_parts.
              lv_idx_parts = lv_idx_parts + 1.

              CONDENSE lv_method_part.
              IF lv_method_part IS INITIAL.
                CONTINUE.
              ENDIF.

              CLEAR: ls_meth, lv_name.

              FIND PCRE gc_pcre_meth_name
                IN lv_method_part
                SUBMATCHES lv_name.
              IF sy-subrc <> 0 OR lv_name IS INITIAL.
                CONTINUE.
              ENDIF.

              TRANSLATE lv_name TO UPPER CASE.
              CONDENSE lv_name NO-GAPS.

              UNASSIGN <lfs_meth>.
              CLEAR ls_method_idx.

              READ TABLE lt_method_idx INTO ls_method_idx
                WITH TABLE KEY method_name = lv_name.

              IF sy-subrc = 0.
                READ TABLE cs_layout-methods ASSIGNING <lfs_meth>
                  INDEX ls_method_idx-tabix.
              ENDIF.

              IF <lfs_meth> IS NOT ASSIGNED.
                CLEAR ls_meth.
                ls_meth-method_name = lv_name.
                ls_meth-visibility  = lv_section.
                IF lv_keyword = gc_kw_class_methods.
                  ls_meth-method_level = gc_comp_lvl_stat.
                ELSE.
                  ls_meth-method_level = gc_comp_lvl_inst.
                ENDIF.

                IF lv_name = gc_meth_constr.
                  ls_meth-method_type = gc_meth_type_constr.
                ELSEIF lv_name = gc_meth_cls_constr.
                  ls_meth-method_type = gc_meth_type_cls_con.
                ELSEIF lv_stmt_uc CS gc_kw_abstract_pat.
                  ls_meth-method_type = gc_meth_type_abstr.
                ELSE.
                  ls_meth-method_type = gc_meth_type_norm.
                ENDIF.

                IF ls_meth-method_description IS INITIAL.
                  ls_meth-method_description = gc_na.
                ENDIF.

                APPEND ls_meth TO cs_layout-methods.
                lv_method_tabix = lines( cs_layout-methods ).

                INSERT VALUE lty_method_idx(
                  method_name = ls_meth-method_name
                  tabix       = lv_method_tabix
                ) INTO TABLE lt_method_idx.

                READ TABLE cs_layout-methods ASSIGNING <lfs_meth>
                  INDEX lv_method_tabix.
              ENDIF.

              IF <lfs_meth> IS ASSIGNED.
                IF <lfs_meth>-visibility IS INITIAL OR <lfs_meth>-visibility = gc_na.
                  <lfs_meth>-visibility = lv_section.
                ENDIF.

                IF <lfs_meth>-method_level IS INITIAL OR <lfs_meth>-method_level = gc_na.
                  IF ls_src-method_level IS NOT INITIAL.
                    <lfs_meth>-method_level = ls_src-method_level.
                  ELSEIF lv_keyword = gc_kw_class_methods.
                    <lfs_meth>-method_level = gc_comp_lvl_stat.
                  ELSE.
                    <lfs_meth>-method_level = gc_comp_lvl_inst.
                  ENDIF.
                ENDIF.

                IF ( <lfs_meth>-method_description IS INITIAL
                  OR <lfs_meth>-method_description = gc_na )
                  AND ls_src-description IS NOT INITIAL.
                  <lfs_meth>-method_description = ls_src-description.
                ENDIF.
              ENDIF.

            ENDWHILE.
          ENDIF.

          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        CLEAR lv_stmt.

      ENDWHILE.
    ENDLOOP.

    IF cs_layout-methods IS INITIAL.
      APPEND INITIAL LINE TO cs_layout-methods ASSIGNING <lfs_meth>.
      IF <lfs_meth> IS ASSIGNED.

        lv_col_index = 1.
        DO.
          ASSIGN COMPONENT lv_col_index OF STRUCTURE <lfs_meth> TO <lfs_field_dyn>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          TRY.
              <lfs_field_dyn> = gc_na.
            CATCH cx_root.
          ENDTRY.

          lv_col_index = lv_col_index + 1.
        ENDDO.

      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD fill_class_layout_param.

    DATA: lv_class_name TYPE seoclsname,
          lv_line       TYPE string,
          lv_stmt       TYPE string,
          lv_stmt_uc    TYPE string,
          lv_temp       TYPE string,
          lv_keyword    TYPE string,
          lv_len        TYPE i,
          lv_offset     TYPE i,
          ls_param      TYPE zst_src_class_param,
          ls_src        TYPE gty_class_source,
          ls_subco      TYPE gty_subco_meta,
          ls_subcotx    TYPE gty_subco_text,
          lt_subco_meta TYPE STANDARD TABLE OF gty_subco_meta,
          lt_subco_text TYPE STANDARD TABLE OF gty_subco_text.


    DATA: lv_lines_src TYPE i,
          lv_idx_src   TYPE i,
          lv_col_index TYPE i.

    FIELD-SYMBOLS: <lfs_param_dummy> TYPE any,
                   <lfs_field_dyn>   TYPE any.

    lv_class_name = iv_class_name.
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
        AND version = gc_comp_exp_1. " Tái sử dụng hằng số '1'


    SELECT clsname
           cmpname
           sconame
           langu
           descript
      INTO TABLE lt_subco_text
      FROM seosubcotx
      WHERE clsname = lv_class_name
        AND langu   = sy-langu.
      SORT lt_subco_text BY clsname cmpname sconame langu.
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
        WHEN gc_param_decl_0.
          ls_param-param_type = gc_param_type_imp.
        WHEN gc_param_decl_1.
          ls_param-param_type = gc_param_type_exp.
        WHEN gc_param_decl_2.
          ls_param-param_type = gc_param_type_cha.
        WHEN gc_param_decl_3.
          ls_param-param_type = gc_param_type_ret.
        WHEN OTHERS.
          ls_param-param_type = ls_subco-pardecltyp.
      ENDCASE.

      CASE ls_subco-parpasstyp.
        WHEN gc_param_pass_0.
          ls_param-pass_by_value = gc_na.
        WHEN gc_param_pass_1.
          ls_param-pass_by_value = gc_mark_x.
        WHEN OTHERS.
          ls_param-pass_by_value = ls_subco-parpasstyp.
      ENDCASE.

      CASE ls_subco-typtype.
        WHEN gc_param_typ_0.
          ls_param-typing_method = gc_param_typ_type.
        WHEN gc_param_typ_1.
          ls_param-typing_method = gc_param_typ_like.
        WHEN OTHERS.
          ls_param-typing_method = ls_subco-typtype.
      ENDCASE.

      IF ls_subco-type IS NOT INITIAL.
        ls_param-associated_type = ls_subco-type.
        IF ls_subco-tableof = gc_mark_x.
          CONCATENATE gc_table_of ls_param-associated_type
            INTO ls_param-associated_type
            SEPARATED BY space.
        ENDIF.
      ELSE.
        ls_param-associated_type = gc_na.
      ENDIF.

      IF ls_subco-parvalue IS NOT INITIAL.
        ls_param-param_default_value = ls_subco-parvalue.
      ELSE.
        ls_param-param_default_value = gc_na.
      ENDIF.

      IF ls_subco-paroptionl IS NOT INITIAL.
        ls_param-optional = gc_mark_x.
      ELSE.
        ls_param-optional = gc_na.
      ENDIF.

      READ TABLE lt_subco_text INTO ls_subcotx
        WITH KEY clsname = lv_class_name
                 cmpname = ls_subco-cmpname
                 sconame = ls_subco-sconame
                 langu   = sy-langu
        BINARY SEARCH.
      IF sy-subrc = 0 AND ls_subcotx-descript IS NOT INITIAL.
        ls_param-param_description = ls_subcotx-descript.
      ELSE.
        ls_param-param_description = gc_na.
      ENDIF.

      APPEND ls_param TO cs_layout-method_params.

    ENDLOOP.

    LOOP AT it_class_source INTO ls_src.

      IF ls_src-include_kind <> gc_section_kw.
        CONTINUE.
      ENDIF.

      CLEAR lv_stmt.

      lv_lines_src = lines( ls_src-source_code ).
      lv_idx_src   = 1.

      WHILE lv_idx_src <= lv_lines_src.
        READ TABLE ls_src-source_code INTO lv_line INDEX lv_idx_src.
        lv_idx_src = lv_idx_src + 1.

        IF lv_line IS INITIAL.
          CONTINUE.
        ENDIF.

        IF lv_stmt IS INITIAL.
          lv_stmt = lv_line.
        ELSE.
          CONCATENATE lv_stmt lv_line INTO lv_stmt SEPARATED BY space.
        ENDIF.

        IF lv_line NS gc_dot.
          CONTINUE.
        ENDIF.

        CONDENSE lv_stmt.
        IF lv_stmt IS INITIAL.
          CLEAR lv_stmt.
          CONTINUE.
        ENDIF.

        lv_stmt_uc = lv_stmt.
        TRANSLATE lv_stmt_uc TO UPPER CASE.

        IF lv_stmt_uc CP gc_kw_methods_pat OR lv_stmt_uc CP gc_kw_cls_meth_pat.

          CLEAR: lv_keyword, lv_temp.
          FIND PCRE gc_pcre_meth_decl1
            IN lv_stmt
            SUBMATCHES lv_keyword lv_temp.

          IF sy-subrc <> 0.
            FIND PCRE gc_pcre_meth_decl2
              IN lv_stmt
              SUBMATCHES lv_keyword lv_temp.
          ENDIF.

          IF sy-subrc = 0 AND lv_temp IS NOT INITIAL.
            CONDENSE lv_temp.
            lv_len = strlen( lv_temp ).
            IF lv_len > 0.
              lv_offset = lv_len - 1.
              IF lv_temp+lv_offset(1) = gc_dot.
                lv_temp = lv_temp(lv_offset).
              ENDIF.
            ENDIF.

          ENDIF.

        ENDIF.

        CLEAR lv_stmt.

      ENDWHILE.
    ENDLOOP.

    IF cs_layout-method_params IS INITIAL.
      APPEND INITIAL LINE TO cs_layout-method_params ASSIGNING <lfs_param_dummy>.
      IF <lfs_param_dummy> IS ASSIGNED.

        ASSIGN COMPONENT 1 OF STRUCTURE <lfs_param_dummy> TO <lfs_field_dyn>.
        IF sy-subrc = 0. TRY. <lfs_field_dyn> = gc_empty. CATCH cx_root. ENDTRY. ENDIF.


        lv_col_index = 2.
        DO.
          ASSIGN COMPONENT lv_col_index OF STRUCTURE <lfs_param_dummy> TO <lfs_field_dyn>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          TRY.
              <lfs_field_dyn> = gc_na.
            CATCH cx_root.
          ENDTRY.

          lv_col_index = lv_col_index + 1.
        ENDDO.

      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD fill_data_element.

    DATA: lt_rollnames    TYPE gty_t_de_rollnames,
          lt_source       TYPE string_table,
          lt_sources      TYPE STANDARD TABLE OF zcl_program_fetch=>gty_program_source,
          lt_all_sources  TYPE STANDARD TABLE OF zcl_program_fetch=>gty_program_source,
          ls_source       TYPE zcl_program_fetch=>gty_program_source,
          lt_fms          TYPE STANDARD TABLE OF rs38l-name WITH EMPTY KEY,
          lv_func_name    TYPE rs38l-name,
          lv_prog_name    TYPE progname,
          lv_fugr_name    TYPE rs38l-area,
          lv_class_name   TYPE seoclsname,
          lt_class_source TYPE zcl_program_fetch=>gty_t_class_source,
          ls_class_source TYPE zcl_program_fetch=>gty_class_source,
          lt_seen_prog    TYPE gty_t_seen_prog,
          lt_seen_type    TYPE gty_t_seen_type.

    DATA: lv_lines_fms TYPE i,
          lv_idx_fms   TYPE i,
          lv_lines_src TYPE i,
          lv_idx_src   TYPE i,
          lv_col_index TYPE i.

    FIELD-SYMBOLS: <lfs_data_elem> TYPE any,
                   <lfs_field>     TYPE any.

    me->ensure_objects( ).

    CASE iv_objtype.

      WHEN gc_export-kw_obj_prog.

        lv_prog_name = iv_objname.
        TRANSLATE lv_prog_name TO UPPER CASE.
        CONDENSE lv_prog_name NO-GAPS.

        INSERT lv_prog_name INTO TABLE lt_seen_prog.

        lt_source = me->go_fetch->get_source_code( iv_name = lv_prog_name ).

        IF lt_source IS NOT INITIAL.
          me->collect_from_source(
            EXPORTING
              it_source     = lt_source
              iv_follow_inc = abap_true
            CHANGING
              ct_rollnames  = lt_rollnames
              ct_seen_prog  = lt_seen_prog
              ct_seen_type  = lt_seen_type
          ).
        ENDIF.

      WHEN gc_export-kw_obj_func.

        lv_func_name = iv_objname.
        TRANSLATE lv_func_name TO UPPER CASE.
        CONDENSE lv_func_name NO-GAPS.

        lt_sources = me->go_fetch->get_function_module( iv_funcname = lv_func_name ).

        lv_lines_src = lines( lt_sources ).
        lv_idx_src   = 1.

        WHILE lv_idx_src <= lv_lines_src.
          READ TABLE lt_sources INTO ls_source INDEX lv_idx_src.
          lv_idx_src = lv_idx_src + 1.

          IF ls_source-source_code IS NOT INITIAL.
            me->collect_from_source(
              EXPORTING
                it_source    = ls_source-source_code
              CHANGING
                ct_rollnames = lt_rollnames
                ct_seen_prog = lt_seen_prog
                ct_seen_type = lt_seen_type
          ).
          ENDIF.
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
          WHERE area = @lv_fugr_name.                 "#EC CI_SGLSELECT

        SORT lt_fms BY table_line.

        CLEAR lt_all_sources.
        lv_lines_fms = lines( lt_fms ).
        lv_idx_fms   = 1.

        WHILE lv_idx_fms <= lv_lines_fms.
          READ TABLE lt_fms INTO lv_func_name INDEX lv_idx_fms.
          lv_idx_fms = lv_idx_fms + 1.

          lt_sources = me->go_fetch->get_function_module( iv_funcname = lv_func_name ).
          APPEND LINES OF lt_sources TO lt_all_sources.

          me->collect_from_meta(
            EXPORTING
              iv_objtype   = gc_export-kw_obj_func
              iv_objname   = CONV sobj_name( lv_func_name )
            CHANGING
              ct_rollnames = lt_rollnames
              ct_seen_type = lt_seen_type
          ).
        ENDWHILE.


        lv_lines_src = lines( lt_all_sources ).
        lv_idx_src   = 1.

        WHILE lv_idx_src <= lv_lines_src.
          READ TABLE lt_all_sources INTO ls_source INDEX lv_idx_src.
          lv_idx_src = lv_idx_src + 1.

          IF ls_source-source_code IS NOT INITIAL.
            me->collect_from_source(
              EXPORTING
                it_source    = ls_source-source_code
              CHANGING
                ct_rollnames = lt_rollnames
                ct_seen_prog = lt_seen_prog
                ct_seen_type = lt_seen_type
            ).
          ENDIF.
        ENDWHILE.

      WHEN gc_export-kw_obj_clas.

        lv_class_name = iv_objname.
        TRANSLATE lv_class_name TO UPPER CASE.
        CONDENSE lv_class_name NO-GAPS.

        lt_class_source = me->go_fetch->get_class( iv_class_name = lv_class_name ).

        lv_lines_src = lines( lt_class_source ).
        lv_idx_src   = 1.

        WHILE lv_idx_src <= lv_lines_src.
          READ TABLE lt_class_source INTO ls_class_source INDEX lv_idx_src.
          lv_idx_src = lv_idx_src + 1.

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
        ENDWHILE.

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


    IF rt_data_element IS NOT INITIAL.

      lv_lines_src = lines( rt_data_element ).
      lv_idx_src   = 1.

      WHILE lv_idx_src <= lv_lines_src.
        READ TABLE rt_data_element ASSIGNING <lfs_data_elem> INDEX lv_idx_src.
        IF sy-subrc = 0.

          lv_col_index = 1.
          DO.
            ASSIGN COMPONENT lv_col_index OF STRUCTURE <lfs_data_elem> TO <lfs_field>.
            IF sy-subrc <> 0.
              EXIT.
            ENDIF.

            IF <lfs_field> IS INITIAL.
              TRY.
                  <lfs_field> = gc_na.
                CATCH cx_root.

              ENDTRY.
            ENDIF.

            lv_col_index = lv_col_index + 1.
          ENDDO.

        ENDIF.
        lv_idx_src = lv_idx_src + 1.
      ENDWHILE.

    ELSE.

      APPEND INITIAL LINE TO rt_data_element ASSIGNING <lfs_data_elem>.
      IF <lfs_data_elem> IS ASSIGNED.

        ASSIGN COMPONENT 1 OF STRUCTURE <lfs_data_elem> TO <lfs_field>.
        IF sy-subrc = 0.
          TRY.
              <lfs_field> = 0.
            CATCH cx_root.
          ENDTRY.
        ENDIF.

        lv_col_index = 2.
        DO.
          ASSIGN COMPONENT lv_col_index OF STRUCTURE <lfs_data_elem> TO <lfs_field>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          TRY.
              <lfs_field> = gc_na.
            CATCH cx_root.
          ENDTRY.

          lv_col_index = lv_col_index + 1.
        ENDDO.

      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD fill_overview.

    DATA: lv_vrsd_objtype  TYPE vrsd-objtype,
          lv_vrsd_objname  TYPE vrsd-objname,
          lv_objtype_uc    TYPE string,
          lv_version_count TYPE i.

    CLEAR rs_overview.

    " A. Document Info
    rs_overview-parameter01 = |{ sy-datum DATE = USER }|.
    rs_overview-parameter02 = sy-uname.

    lv_objtype_uc = iv_objtype.
    TRANSLATE lv_objtype_uc TO UPPER CASE.
    CONDENSE lv_objtype_uc NO-GAPS.

    lv_vrsd_objname = iv_objname.
    TRANSLATE lv_vrsd_objname TO UPPER CASE.
    CONDENSE lv_vrsd_objname NO-GAPS.

    CASE lv_objtype_uc.
      WHEN gc_kw_prog OR gc_kw_program OR gc_kw_reps OR gc_kw_report OR gc_kw_inc OR gc_kw_include.
        lv_vrsd_objtype = gc_kw_reps.
      WHEN gc_kw_fugr OR gc_kw_funcgrp.
        lv_vrsd_objtype = gc_kw_fugr.
      WHEN gc_kw_func OR gc_kw_fm OR gc_kw_funcmod.
        lv_vrsd_objtype = gc_kw_func.
      WHEN gc_kw_clas OR gc_kw_class.
        lv_vrsd_objtype = gc_kw_clas.
      WHEN gc_kw_intf OR gc_kw_interface.
        lv_vrsd_objtype = gc_kw_intf.
      WHEN OTHERS.
        lv_vrsd_objtype = lv_objtype_uc(4).
    ENDCASE.

    SELECT COUNT( * )
      INTO @lv_version_count
      FROM vrsd
      WHERE objtype = @lv_vrsd_objtype
        AND objname = @lv_vrsd_objname.

    IF sy-subrc = 0 AND lv_version_count > 0.
      rs_overview-parameter03 = |{ lv_version_count }|.
    ELSEIF iv_version IS NOT INITIAL.
      rs_overview-parameter03 = iv_version.
    ELSE.
      rs_overview-parameter03 = gc_export-kw_na.
    ENDIF.

    " B. Object General Info
    IF iv_objtype IS NOT INITIAL.
      rs_overview-parameter04 = iv_objtype.
    ELSE.
      rs_overview-parameter04 = gc_export-kw_na.
    ENDIF.

    IF iv_objname IS NOT INITIAL.
      rs_overview-parameter05 = iv_objname.
    ELSE.
      rs_overview-parameter05 = gc_export-kw_na.
    ENDIF.

    IF iv_description IS NOT INITIAL.
      rs_overview-parameter06 = iv_description.
    ELSE.
      rs_overview-parameter06 = gc_export-kw_na.
    ENDIF.

    IF iv_package IS NOT INITIAL.
      rs_overview-parameter07 = iv_package.
    ELSE.
      rs_overview-parameter07 = gc_export-kw_na.
    ENDIF.

    IF iv_status IS NOT INITIAL.
      rs_overview-parameter08 = iv_status.
    ELSE.
      rs_overview-parameter08 = gc_export-kw_na.
    ENDIF.

    " C. Technical Info
    IF iv_created_by IS NOT INITIAL.
      rs_overview-parameter09 = iv_created_by.
    ELSE.
      rs_overview-parameter09 = gc_export-kw_na.
    ENDIF.

    IF iv_created_on IS NOT INITIAL.
      rs_overview-parameter10 = |{ iv_created_on DATE = USER }|.
    ELSE.
      rs_overview-parameter10 = gc_export-kw_na.
    ENDIF.

    IF iv_changed_on IS NOT INITIAL.
      rs_overview-parameter11 = |{ iv_changed_on DATE = USER }|.
    ELSE.
      rs_overview-parameter11 = gc_export-kw_na.
    ENDIF.

    IF iv_changed_by IS NOT INITIAL.
      rs_overview-parameter12 = iv_changed_by.
    ELSE.
      rs_overview-parameter12 = gc_export-kw_na.
    ENDIF.

    IF iv_trkorr IS NOT INITIAL.
      rs_overview-parameter14 = iv_trkorr.
    ELSE.
      rs_overview-parameter14 = gc_export-kw_na.
    ENDIF.

    " T-Code
    CASE lv_objtype_uc.
      WHEN gc_kw_prog OR gc_kw_program OR gc_kw_reps OR gc_kw_report.
        IF sy-tcode IS NOT INITIAL.
          rs_overview-parameter15 = sy-tcode.
        ELSE.
          rs_overview-parameter15 = gc_export-kw_na.
        ENDIF.
      WHEN gc_kw_clas OR gc_kw_class OR gc_kw_fugr OR gc_kw_func OR gc_kw_fm OR gc_kw_method.
        rs_overview-parameter15 = gc_export-kw_na.
      WHEN OTHERS.
        IF iv_tcode IS NOT INITIAL.
          rs_overview-parameter15 = iv_tcode.
        ELSE.
          rs_overview-parameter15 = gc_export-kw_na.
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD fill_screen_layout.

    DATA: lt_sources             TYPE gty_t_program_source,
          ls_source              TYPE gty_program_source,
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
          lv_in_line             TYPE abap_bool VALUE abap_false,
          lv_lines_parts         TYPE i,
          lv_idx_parts           TYPE i.

    DATA: lt_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    DATA: ls_input  TYPE zst_scr_input,
          ls_visual TYPE zst_scr_visual,
          ls_msg    TYPE zst_scr_msg,
          ls_btn    TYPE zst_scr_btn.

    DATA: lt_all_source_lines TYPE STANDARD TABLE OF string.

    DATA: lt_dfies          TYPE STANDARD TABLE OF dfies,
          ls_dfies          TYPE dfies,
          lv_call_tabname   TYPE ddobjname,
          lv_call_fieldname TYPE dfies-fieldname.

    CLEAR cs_screen_layout.

    IF go_fetch IS INITIAL.
      CREATE OBJECT go_fetch.
    ENDIF.

    lt_sources = go_fetch->get_program_source( iv_program_name ).

    CLEAR lt_all_source_lines.
    LOOP AT lt_sources INTO ls_source.
      APPEND LINES OF ls_source-source_code TO lt_all_source_lines.
    ENDLOOP.

    CLEAR lv_stmt.

    LOOP AT lt_all_source_lines INTO lv_line.

      lv_line_uc = lv_line.
      TRANSLATE lv_line_uc TO UPPER CASE.
      CONDENSE lv_line_uc.

      IF lv_line_uc = gc_scr_at_sel.
        lv_in_validation_block = abap_true.
      ELSEIF lv_line_uc = gc_scr_at_sel_out
          OR lv_line_uc = gc_scr_start_sel
          OR lv_line_uc = gc_scr_init
          OR lv_line_uc = gc_scr_end_sel.
        lv_in_validation_block = abap_false.
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
      CONDENSE lv_stmt.

      " Visual layout state
      IF lv_stmt_uc CP gc_scr_beg_block.
        lv_current_row = lv_current_row + 1.
        CLEAR lv_stmt.
        CONTINUE.
      ENDIF.

      IF lv_stmt_uc = gc_scr_beg_line.
        lv_in_line = abap_true.
        lv_current_row = lv_current_row + 1.
        CLEAR: lv_pending_pos, lv_comment_pos, lv_comment_len.
        CLEAR lv_stmt.
        CONTINUE.
      ENDIF.

      IF lv_stmt_uc = gc_scr_end_line.
        lv_in_line = abap_false.
        CLEAR: lv_pending_pos, lv_comment_pos, lv_comment_len.
        CLEAR lv_stmt.
        CONTINUE.
      ENDIF.

      IF lv_stmt_uc CP gc_scr_pos.
        CLEAR lv_numstr1.
        FIND PCRE gc_pcre_pos IN lv_stmt_uc SUBMATCHES lv_numstr1.
        IF lv_numstr1 IS NOT INITIAL.
          lv_pending_pos = lv_numstr1.
        ENDIF.
        CLEAR lv_stmt.
        CONTINUE.
      ENDIF.

      IF lv_stmt_uc CP gc_scr_comment.
        CLEAR: lv_numstr1, lv_numstr2.
        FIND PCRE gc_pcre_comment IN lv_stmt_uc
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

      " A. PARAMETERS
      IF lv_stmt_uc CP gc_scr_param1 OR lv_stmt_uc CP gc_scr_param2.

        lv_body = lv_stmt.
        REPLACE FIRST OCCURRENCE OF PCRE gc_pcre_param_clr
          IN lv_body WITH gc_empty.

        lv_len = strlen( lv_body ).
        IF lv_len > 0.
          lv_offset = lv_len - 1.
          lv_lastchr = lv_body+lv_offset(1).
          IF lv_lastchr = gc_symbol-dot.
            lv_newlen = lv_len - 1.
            lv_body = lv_body(lv_newlen).
          ENDIF.
        ENDIF.

        CLEAR lt_parts.
        SPLIT lv_body AT gc_symbol-comma INTO TABLE lt_parts.

        lv_lines_parts = lines( lt_parts ).
        lv_idx_parts   = 1.

        WHILE lv_idx_parts <= lv_lines_parts.
          READ TABLE lt_parts INTO lv_part INDEX lv_idx_parts.
          lv_idx_parts = lv_idx_parts + 1.

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

          FIND PCRE gc_pcre_name IN lv_part_uc SUBMATCHES lv_name.
          IF lv_name IS INITIAL.
            CONTINUE.
          ENDIF.

          CLEAR lv_type.
          FIND PCRE gc_pcre_type IN lv_part_uc SUBMATCHES lv_type.

          IF lv_type IS INITIAL AND lv_part_uc CS gc_scr_as_chkbox.
            lv_type = gc_scr_type_chkbox.
          ENDIF.

          IF lv_type IS INITIAL AND lv_part_uc CS gc_scr_as_listbox.
            lv_type = gc_scr_type_listbox.
          ENDIF.

          IF lv_type IS INITIAL.
            lv_type = gc_scr_type_param.
          ENDIF.

          CLEAR lv_default.
          FIND PCRE gc_pcre_default IN lv_part
            SUBMATCHES lv_default.

          CLEAR ls_input.
          ls_input-name = lv_name.
          ls_input-type_name = lv_type.

          IF lv_part_uc CS gc_scr_obligatory.
            ls_input-required = gc_scr_yes.
          ELSE.
            ls_input-required = gc_scr_no.
          ENDIF.

          ls_input-single_multiple = gc_scr_single.
          ls_input-multiple        = gc_scr_no.
          ls_input-interval        = gc_scr_no.
          ls_input-extend          = gc_scr_no.

          IF lv_default IS NOT INITIAL.
            ls_input-default_value = lv_default.
          ELSE.
            ls_input-default_value = gc_na.
          ENDIF.

          ls_input-description     = gc_na.

          APPEND ls_input TO cs_screen_layout-input_rows.

          " Visual: Row / Column / Length
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

          IF lv_part_uc CS gc_scr_as_chkbox.
            lv_field_len = 1.
          ELSE.
            CLEAR lv_numstr1.
            FIND PCRE gc_pcre_type_char IN lv_part_uc SUBMATCHES lv_numstr1.
            IF lv_numstr1 IS NOT INITIAL.
              lv_field_len = lv_numstr1.
            ELSE.
              CLEAR lv_ddic_len.
              IF lv_type CP gc_pat_dash.
                SPLIT lv_type AT gc_symbol-dash INTO lv_tabname lv_fieldname.
                IF lv_tabname = gc_tab_sy AND lv_fieldname = gc_fld_datum.
                  lv_ddic_len = 8.
                ELSE.
                  lv_call_tabname   = lv_tabname.
                  lv_call_fieldname = lv_fieldname.
                  CLEAR lt_dfies.
                  CALL FUNCTION gc_fn_ddif
                    EXPORTING
                      tabname   = lv_call_tabname
                      fieldname = lv_call_fieldname
                    TABLES
                      dfies_tab = lt_dfies
                    EXCEPTIONS
                      OTHERS    = 1.
                  IF sy-subrc = 0.
                    READ TABLE lt_dfies INTO ls_dfies INDEX 1.
                    IF sy-subrc = 0.
                      lv_ddic_len = ls_dfies-leng.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ELSE.
                lv_call_tabname = lv_type.
                CLEAR lt_dfies.
                CALL FUNCTION gc_fn_ddif
                  EXPORTING
                    tabname   = lv_call_tabname
                  TABLES
                    dfies_tab = lt_dfies
                  EXCEPTIONS
                    OTHERS    = 1.
                IF sy-subrc = 0.
                  READ TABLE lt_dfies INTO ls_dfies INDEX 1.
                  IF sy-subrc = 0.
                    lv_ddic_len = ls_dfies-leng.
                  ENDIF.
                ENDIF.
              ENDIF.
              lv_field_len = lv_ddic_len.
            ENDIF.
          ENDIF.

          IF lv_field_len > 0.
            ls_visual-length = lv_field_len.
          ELSE.
            ls_visual-length = gc_na.
          ENDIF.

          IF lv_part_uc CS gc_scr_no_disp.
            ls_visual-visible = gc_scr_no.
          ELSE.
            ls_visual-visible = gc_scr_yes.
          ENDIF.

          ls_visual-editable = gc_scr_yes.

          APPEND ls_visual TO cs_screen_layout-visual_rows.

          IF lv_in_line = abap_true.
            CLEAR: lv_pending_pos, lv_comment_pos, lv_comment_len.
          ENDIF.
        ENDWHILE.

        CLEAR lv_stmt.
        CONTINUE.
      ENDIF.

      " B. SELECT-OPTIONS
      IF lv_stmt_uc CP gc_scr_sel_opt1 OR lv_stmt_uc CP gc_scr_sel_opt2.

        lv_body = lv_stmt.
        REPLACE FIRST OCCURRENCE OF PCRE gc_pcre_selopt_clr
          IN lv_body WITH gc_empty.

        lv_len = strlen( lv_body ).
        IF lv_len > 0.
          lv_offset = lv_len - 1.
          lv_lastchr = lv_body+lv_offset(1).
          IF lv_lastchr = gc_symbol-dot.
            lv_newlen = lv_len - 1.
            lv_body = lv_body(lv_newlen).
          ENDIF.
        ENDIF.

        CLEAR lt_parts.
        SPLIT lv_body AT gc_symbol-comma INTO TABLE lt_parts.

        lv_lines_parts = lines( lt_parts ).
        lv_idx_parts   = 1.

        WHILE lv_idx_parts <= lv_lines_parts.
          READ TABLE lt_parts INTO lv_part INDEX lv_idx_parts.
          lv_idx_parts = lv_idx_parts + 1.

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

          FIND PCRE gc_pcre_name IN lv_part_uc SUBMATCHES lv_name.
          IF lv_name IS INITIAL.
            CONTINUE.
          ENDIF.

          CLEAR lv_type.
          FIND PCRE gc_pcre_for IN lv_part_uc SUBMATCHES lv_type.
          IF lv_type IS INITIAL.
            lv_type = gc_scr_type_selopt.
          ENDIF.

          CLEAR ls_input.
          ls_input-name = lv_name.
          ls_input-type_name = lv_type.

          IF lv_part_uc CS gc_scr_obligatory.
            ls_input-required = gc_scr_yes.
          ELSE.
            ls_input-required = gc_scr_no.
          ENDIF.

          ls_input-single_multiple = gc_scr_multiple.
          ls_input-multiple        = gc_scr_yes.

          IF lv_part_uc CS gc_scr_no_int1 OR lv_part_uc CS gc_scr_no_int2.
            ls_input-interval = gc_scr_no.
          ELSE.
            ls_input-interval = gc_scr_yes.
          ENDIF.

          IF lv_part_uc CS gc_scr_no_ext1 OR lv_part_uc CS gc_scr_no_ext2.
            ls_input-extend = gc_scr_no.
          ELSE.
            ls_input-extend = gc_scr_yes.
          ENDIF.

          ls_input-default_value = gc_na.
          ls_input-description   = gc_na.

          APPEND ls_input TO cs_screen_layout-input_rows.

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
          IF lv_type CP gc_pat_dash.
            SPLIT lv_type AT gc_symbol-dash INTO lv_tabname lv_fieldname.
            IF lv_tabname = gc_tab_sy AND lv_fieldname = gc_fld_datum.
              lv_ddic_len = 8.
            ELSE.
              lv_call_tabname   = lv_tabname.
              lv_call_fieldname = lv_fieldname.
              CLEAR lt_dfies.
              CALL FUNCTION gc_fn_ddif
                EXPORTING
                  tabname   = lv_call_tabname
                  fieldname = lv_call_fieldname
                TABLES
                  dfies_tab = lt_dfies
                EXCEPTIONS
                  OTHERS    = 1.
              IF sy-subrc = 0.
                READ TABLE lt_dfies INTO ls_dfies INDEX 1.
                IF sy-subrc = 0.
                  lv_ddic_len = ls_dfies-leng.
                ENDIF.
              ENDIF.
            ENDIF.
          ELSE.
            lv_call_tabname = lv_type.
            CLEAR lt_dfies.
            CALL FUNCTION gc_fn_ddif
              EXPORTING
                tabname   = lv_call_tabname
              TABLES
                dfies_tab = lt_dfies
              EXCEPTIONS
                OTHERS    = 1.
            IF sy-subrc = 0.
              READ TABLE lt_dfies INTO ls_dfies INDEX 1.
              IF sy-subrc = 0.
                lv_ddic_len = ls_dfies-leng.
              ENDIF.
            ENDIF.
          ENDIF.

          lv_field_len = lv_ddic_len.

          IF lv_field_len > 0.
            ls_visual-length = lv_field_len.
          ELSE.
            ls_visual-length = gc_na.
          ENDIF.

          IF lv_part_uc CS gc_scr_no_disp.
            ls_visual-visible = gc_scr_no.
          ELSE.
            ls_visual-visible = gc_scr_yes.
          ENDIF.

          ls_visual-editable = gc_scr_yes.

          APPEND ls_visual TO cs_screen_layout-visual_rows.

          IF lv_in_line = abap_true.
            CLEAR: lv_pending_pos, lv_comment_pos, lv_comment_len.
          ENDIF.
        ENDWHILE.

        CLEAR lv_stmt.
        CONTINUE.
      ENDIF.

      " D. PUSHBUTTON
      IF lv_stmt_uc CP gc_scr_pushbtn.

        CLEAR: ls_btn, lv_button, lv_desc.

        FIND PCRE gc_pcre_pushbtn IN lv_stmt_uc
          SUBMATCHES lv_button.
        FIND PCRE gc_pcre_desc IN lv_stmt
          SUBMATCHES lv_desc.

        ls_btn-button      = lv_button.
        IF ls_btn-button IS INITIAL.
          ls_btn-button = gc_na.
        ENDIF.

        ls_btn-description = lv_desc.
        IF ls_btn-description IS INITIAL.
          ls_btn-description = gc_na.
        ENDIF.

        ls_btn-action      = gc_scr_act_sel.

        APPEND ls_btn TO cs_screen_layout-button_rows.

        CLEAR lv_stmt.
        CONTINUE.
      ENDIF.

      " C. MESSAGE / VALIDATION
      IF lv_in_validation_block = abap_true AND lv_stmt_uc CS gc_scr_msg.

        CLEAR: ls_msg, lv_msgtype, lv_msgtxt.

        FIND PCRE gc_pcre_msg1 IN lv_stmt_uc
          SUBMATCHES lv_msgtype.

        IF lv_msgtype IS INITIAL.
          FIND PCRE gc_pcre_msg2 IN lv_stmt_uc
            SUBMATCHES lv_msgtype.
        ENDIF.

        CLEAR lv_msgtxt.
        FIND PCRE gc_pcre_desc IN lv_stmt
          SUBMATCHES lv_msgtxt.

        IF lv_msgtxt IS INITIAL.
          lv_msgtxt = lv_stmt.
        ENDIF.

        CLEAR ls_msg.

        ls_msg-msg_type  = lv_msgtype.
        IF ls_msg-msg_type IS INITIAL.
          ls_msg-msg_type = gc_na.
        ENDIF.

        ls_msg-msg_text  = lv_msgtxt.
        IF ls_msg-msg_text IS INITIAL.
          ls_msg-msg_text = gc_na.
        ENDIF.

        ls_msg-condition = gc_scr_act_val.

        APPEND ls_msg TO cs_screen_layout-message_rows.

        CLEAR lv_stmt.
        CONTINUE.
      ENDIF.

      CLEAR lv_stmt.
    ENDLOOP.

    IF cs_screen_layout-button_rows IS INITIAL.
      CLEAR ls_btn.
      ls_btn-button      = gc_na.
      ls_btn-description = gc_na.
      ls_btn-action      = gc_na.
      APPEND ls_btn TO cs_screen_layout-button_rows.
    ENDIF.

    IF cs_screen_layout-message_rows IS INITIAL.
      CLEAR ls_msg.
      ls_msg-msg_type  = gc_na.
      ls_msg-msg_text  = gc_na.
      ls_msg-condition = gc_na.
      APPEND ls_msg TO cs_screen_layout-message_rows.
    ENDIF.

  ENDMETHOD.


  METHOD fill_table.

    DATA: lt_tab_hits     TYPE gty_t_tab_hits,
          lt_source       TYPE string_table,
          lt_sources      TYPE gty_t_program_source,
          ls_source       TYPE gty_program_source,
          lt_class_source TYPE gty_t_class_source,
          ls_class_source TYPE gty_class_source,
          lv_prog_name    TYPE progname,
          lv_func_name    TYPE rs38l-name,
          lv_class_name   TYPE seoclsname.

    FIELD-SYMBOLS: <lfs_table> TYPE any,
                   <lfs_field> TYPE any.

    DATA: lv_col_index TYPE i.

    me->ensure_objects( ).

    CASE iv_objtype.

      WHEN gc_export-kw_obj_prog.
        lv_prog_name = iv_objname.
        TRANSLATE lv_prog_name TO UPPER CASE.
        CONDENSE lv_prog_name NO-GAPS.

        lt_source = me->go_fetch->get_source_code( iv_name = lv_prog_name ).
        me->collect_table_from_source( EXPORTING it_source = lt_source CHANGING ct_tab_hits = lt_tab_hits ).

      WHEN gc_export-kw_obj_func.
        lv_func_name = iv_objname.
        TRANSLATE lv_func_name TO UPPER CASE.
        CONDENSE lv_func_name NO-GAPS.

        lt_sources = me->go_fetch->get_function_module( iv_funcname = lv_func_name ).
        LOOP AT lt_sources INTO ls_source.
          IF ls_source-source_code IS NOT INITIAL.
            me->collect_table_from_source( EXPORTING it_source = ls_source-source_code CHANGING ct_tab_hits = lt_tab_hits ).
          ENDIF.
        ENDLOOP.

      WHEN gc_export-kw_obj_clas.
        lv_class_name = iv_objname.
        TRANSLATE lv_class_name TO UPPER CASE.
        CONDENSE lv_class_name NO-GAPS.

        lt_class_source = me->go_fetch->get_class( iv_class_name = lv_class_name ).
        LOOP AT lt_class_source INTO ls_class_source.
          IF ls_class_source-source_code IS NOT INITIAL.
            me->collect_table_from_source( EXPORTING it_source = ls_class_source-source_code CHANGING ct_tab_hits = lt_tab_hits ).
          ENDIF.
        ENDLOOP.

      WHEN OTHERS.
        RETURN.

    ENDCASE.

    rt_table = me->build_table_rows( lt_tab_hits ).


    IF rt_table IS INITIAL.
      APPEND INITIAL LINE TO rt_table ASSIGNING <lfs_table>.
      IF <lfs_table> IS ASSIGNED.

        lv_col_index = 1.
        DO.
          ASSIGN COMPONENT lv_col_index OF STRUCTURE <lfs_table> TO <lfs_field>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          TRY.
              <lfs_field> = gc_na.
            CATCH cx_root.

          ENDTRY.

          lv_col_index = lv_col_index + 1.
        ENDDO.

      ENDIF.
    ENDIF.

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

    IF iv_tabname CP gc_de_skip-pat_lt
       OR iv_tabname CP gc_de_skip-pat_ls
       OR iv_tabname CP gc_de_skip-pat_lv
       OR iv_tabname CP gc_de_skip-pat_gt
       OR iv_tabname CP gc_de_skip-pat_gs
       OR iv_tabname CP gc_de_skip-pat_ty
       OR iv_tabname CP gc_de_skip-lt
       OR iv_tabname CP gc_de_skip-gt
       OR iv_tabname CP gc_de_skip-data.

      RETURN.

    ENDIF.

    rv_ok = abap_true.

  ENDMETHOD.


  METHOD normalize_class_layout.

    DATA: ls_param TYPE zst_src_class_param.

    FIELD-SYMBOLS: <lfs_attr> TYPE zst_src_class_attr,
                   <lfs_meth> TYPE zst_src_class_meth.

    SORT cs_layout-attributes BY attr_name attr_section attr_level.
    DELETE ADJACENT DUPLICATES FROM cs_layout-attributes
      COMPARING attr_name attr_section attr_level.

    SORT cs_layout-methods BY method_name visibility method_level.
    DELETE ADJACENT DUPLICATES FROM cs_layout-methods
      COMPARING method_name visibility method_level.

    SORT cs_layout-method_params BY method_name param_name param_type.
    DELETE ADJACENT DUPLICATES FROM cs_layout-method_params
      COMPARING method_name param_name param_type.

    LOOP AT cs_layout-attributes ASSIGNING <lfs_attr>.
      IF <lfs_attr>-attr_section IS INITIAL.
        <lfs_attr>-attr_section = gc_export-kw_na.
      ENDIF.
      IF <lfs_attr>-attr_level IS INITIAL.
        <lfs_attr>-attr_level = gc_export-kw_na.
      ENDIF.
      IF <lfs_attr>-type_name IS INITIAL.
        <lfs_attr>-type_name = gc_export-kw_na.
      ENDIF.
      IF <lfs_attr>-read_only IS INITIAL.
        <lfs_attr>-read_only = gc_export-kw_na.
      ENDIF.
      IF <lfs_attr>-default_value IS INITIAL.
        <lfs_attr>-default_value = gc_export-kw_na.
      ENDIF.
      IF <lfs_attr>-attr_description IS INITIAL.
        <lfs_attr>-attr_description = gc_export-kw_na.
      ENDIF.
    ENDLOOP.

    LOOP AT cs_layout-methods ASSIGNING <lfs_meth>.
      IF <lfs_meth>-method_level IS INITIAL.
        <lfs_meth>-method_level = gc_export-kw_na.
      ENDIF.
      IF <lfs_meth>-visibility IS INITIAL.
        <lfs_meth>-visibility = gc_export-kw_na.
      ENDIF.
      IF <lfs_meth>-method_type IS INITIAL.
        <lfs_meth>-method_type = gc_export-kw_na.
      ENDIF.
      IF <lfs_meth>-method_description IS INITIAL.
        <lfs_meth>-method_description = gc_export-kw_na.
      ENDIF.
    ENDLOOP.

    LOOP AT cs_layout-method_params INTO ls_param.
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
      MODIFY cs_layout-method_params FROM ls_param.
    ENDLOOP.

    IF cs_layout-class_def-class_type IS INITIAL.
      cs_layout-class_def-class_type = gc_export-kw_na.
    ENDIF.
    IF cs_layout-class_def-create_visibility IS INITIAL.
      cs_layout-class_def-create_visibility = gc_export-kw_na.
    ENDIF.
    IF cs_layout-class_def-superclass IS INITIAL.
      cs_layout-class_def-superclass = gc_export-kw_na.
    ENDIF.
    IF cs_layout-class_def-is_final IS INITIAL.
      cs_layout-class_def-is_final = gc_export-kw_na.
    ENDIF.
    IF cs_layout-class_def-is_abstract IS INITIAL.
      cs_layout-class_def-is_abstract = gc_export-kw_na.
    ENDIF.
    IF cs_layout-class_def-interfaces IS INITIAL.
      cs_layout-class_def-interfaces = gc_export-kw_na.
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

    REPLACE ALL OCCURRENCES OF gc_symbol-bang   IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_symbol-comma  IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_symbol-dot    IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_symbol-colon  IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_symbol-rparen IN lv_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_symbol-lparen IN lv_name WITH ''.

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

        SELECT rollname
          INTO @lv_rollname
          FROM dd03l
          UP TO 1 ROWS
          WHERE tabname   = @lv_tabname
            AND fieldname = @lv_fieldname
            AND as4local  = @gc_ddic-as4local_active
            AND as4vers   = @gc_ddic-as4vers_active
          ORDER BY PRIMARY KEY.
        ENDSELECT.

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

    SELECT rollname
      INTO @lv_rollname
      FROM dd04l
      UP TO 1 ROWS
      WHERE rollname = @lv_objname
        AND as4local = @gc_ddic-as4local_active
        AND as4vers  = @gc_ddic-as4vers_active
      ORDER BY PRIMARY KEY.
    ENDSELECT.

    IF sy-subrc = 0 AND lv_rollname IS NOT INITIAL.
      INSERT lv_rollname INTO TABLE ct_rollnames.
      RETURN.
    ENDIF.

    "3. DDIC Table Type -> Row Type
    CLEAR lv_rowtype.

    SELECT rowtype
      INTO @lv_rowtype
      FROM dd40l
      UP TO 1 ROWS
      WHERE typename = @lv_objname
        AND as4local = @gc_ddic-as4local_active
      ORDER BY PRIMARY KEY.
    ENDSELECT.

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
          lv_contflag TYPE dd02l-contflag,
          lv_mandt    TYPE dd03l-fieldname.

    CLEAR: lv_tabclass, lv_ddtext, lv_contflag, lv_mandt.

    SELECT tabclass, contflag
      INTO (@lv_tabclass, @lv_contflag)
      FROM dd02l
      UP TO 1 ROWS
      WHERE tabname  = @iv_tabname
        AND as4local = @gc_ddic-as4local_active
        AND as4vers  = @gc_ddic-as4vers_active
      ORDER BY PRIMARY KEY.
    ENDSELECT.

    SELECT ddtext
      INTO @lv_ddtext
      FROM dd02t
      UP TO 1 ROWS
      WHERE tabname    = @iv_tabname
        AND ddlanguage = @sy-langu
        AND as4local   = @gc_as4local_a
        AND as4vers    = @gc_as4vers_0000
      ORDER BY PRIMARY KEY.
    ENDSELECT.

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
    SELECT fieldname
      INTO @lv_mandt
      FROM dd03l
      UP TO 1 ROWS
      WHERE tabname   = @iv_tabname
        AND fieldname = @gc_ddic-field_mandt
        AND as4local  = @gc_ddic-as4local_active
        AND as4vers   = @gc_ddic-as4vers_active
      ORDER BY PRIMARY KEY.
    ENDSELECT.

    IF sy-subrc = 0 AND lv_mandt IS NOT INITIAL.
      cs_row-tab_cli_dep = gc_mark_x.
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

    DATA: ls_hit       TYPE gty_str_hit,
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

    FIELD-SYMBOLS: <lfs_comp> TYPE lty_comp.

    CLEAR: rt_structure, lv_no.

    LOOP AT it_str_hits INTO ls_hit.
      IF ls_hit-str_name IS NOT INITIAL.
        ls_tabname-tabname = ls_hit-str_name.
        INSERT ls_tabname INTO TABLE lt_tabnames.
      ENDIF.
    ENDLOOP.

IF lt_tabnames IS NOT INITIAL.

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
      AND fieldname NOT LIKE @gc_pat_dot_percent.

ENDIF.

    SORT lt_dd03l BY tabname fieldname.

    LOOP AT lt_dd03l INTO ls_dd03l.

      IF ls_dd03l-fieldname IS INITIAL.
        CONTINUE.
      ENDIF.

      READ TABLE lt_comp ASSIGNING <lfs_comp>
        WITH TABLE KEY tabname = ls_dd03l-tabname.

      IF sy-subrc <> 0.
        CLEAR ls_comp.
        ls_comp-tabname   = ls_dd03l-tabname.
        ls_comp-comp_text = ls_dd03l-fieldname.
        INSERT ls_comp INTO TABLE lt_comp.
      ELSE.
        CONCATENATE <lfs_comp>-comp_text ls_dd03l-fieldname
          INTO <lfs_comp>-comp_text
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
          lv_target   TYPE tabname,
          lv_typename TYPE dd40l-typename,
          ls_hit      TYPE gty_str_hit.

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

        SELECT funcname, structure
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

          CLEAR: lv_target, lv_tabclass, lv_typename, ls_dd40l, ls_dd02l.

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
             AND ( lv_tabclass = gc_ddic-tabclass_inttab
                OR lv_tabclass = gc_ddic-tabclass_append
                OR lv_tabclass = gc_ddic-tabclass_struct ).

            CLEAR ls_hit.
            ls_hit-str_name = lv_target.
            ls_hit-usa_type = gc_export-fm_param.
            ls_hit-src      = gc_export-meta.

            INSERT ls_hit INTO TABLE ct_str_hits.

          ENDIF.

        ENDLOOP.

        "========================================================
        " 2. Class method parameter structure
        "========================================================
      WHEN gc_export-kw_obj_clas.

        SELECT type
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

          CLEAR: lv_target, lv_tabclass, lv_typename, ls_dd40l, ls_dd02l.

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
             AND ( lv_tabclass = gc_ddic-tabclass_inttab
                OR lv_tabclass = gc_ddic-tabclass_append
                OR lv_tabclass = gc_ddic-tabclass_struct ).

            CLEAR ls_hit.
            ls_hit-str_name = lv_target.
            ls_hit-usa_type = gc_export-class_param.
            ls_hit-src      = gc_export-meta.

            INSERT ls_hit INTO TABLE ct_str_hits.

          ENDIF.

        ENDLOOP.

      WHEN OTHERS.
        RETURN.

    ENDCASE.

  ENDMETHOD.


METHOD collect_structure_from_source.

  DATA: lv_line     TYPE string,
        lv_stmt     TYPE string,
        lv_work     TYPE string,
        lt_tokens   TYPE STANDARD TABLE OF string WITH EMPTY KEY,
        lv_token    TYPE string,
        lv_next     TYPE string,
        lv_next2    TYPE string,
        lv_next3    TYPE string,
        lv_next4    TYPE string,
        lv_target   TYPE string,
        lv_idx      TYPE sy-tabix,
        lv_tabclass TYPE dd02l-tabclass,
        lv_rowtype  TYPE dd40l-rowtype,
        ls_hit      TYPE gty_str_hit,
        lt_dd40l    TYPE TABLE OF dd40l,
        lt_dd02l    TYPE TABLE OF dd02l,
        lt_raw      TYPE SORTED TABLE OF ddobjname WITH UNIQUE KEY table_line.

  CLEAR lv_stmt.

  IF lt_raw IS NOT INITIAL.
    SELECT typename,
           rowtype
      FROM dd40l
      INTO CORRESPONDING FIELDS OF TABLE @lt_dd40l
      FOR ALL ENTRIES IN @lt_raw
      WHERE typename = @lt_raw-table_line
        AND as4local = @gc_ddic-as4local_active.

    SORT lt_dd40l BY typename.
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

    SORT lt_dd02l BY tabname.
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

    REPLACE ALL OCCURRENCES OF gc_symbol-lparen  IN lv_work WITH ' ( '.
    REPLACE ALL OCCURRENCES OF gc_symbol-rparen  IN lv_work WITH ' ) '.
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

      READ TABLE lt_dd40l INTO lv_rowtype WITH KEY typename = lv_target BINARY SEARCH.
      IF sy-subrc = 0 AND lv_rowtype IS NOT INITIAL.
        lv_target = lv_rowtype.
        CONDENSE lv_target NO-GAPS.
        TRANSLATE lv_target TO UPPER CASE.
      ENDIF.

      CLEAR lv_tabclass.

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
          ls_source       TYPE gty_program_source,
          lt_class_source TYPE gty_t_class_source,
          ls_class_source TYPE gty_class_source,
          lv_prog_name    TYPE progname,
          lv_func_name    TYPE rs38l-name,
          lv_class_name   TYPE seoclsname.

    FIELD-SYMBOLS: <lfs_structure> TYPE any,
                   <lfs_field>     TYPE any.

    DATA: lv_col_index TYPE i.

    me->ensure_objects( ).

    CASE iv_objtype.

      WHEN gc_export-kw_obj_prog.
        lv_prog_name = iv_objname.
        TRANSLATE lv_prog_name TO UPPER CASE.
        CONDENSE lv_prog_name NO-GAPS.

        lt_source = me->go_fetch->get_source_code( iv_name = lv_prog_name ).
        me->collect_structure_from_source( EXPORTING it_source = lt_source CHANGING ct_str_hits = lt_str_hits ).

      WHEN gc_export-kw_obj_func.
        lv_func_name = iv_objname.
        TRANSLATE lv_func_name TO UPPER CASE.
        CONDENSE lv_func_name NO-GAPS.

        lt_sources = me->go_fetch->get_function_module( iv_funcname = lv_func_name ).
        LOOP AT lt_sources INTO ls_source.
          IF ls_source-source_code IS NOT INITIAL.
            me->collect_structure_from_source( EXPORTING it_source = ls_source-source_code CHANGING ct_str_hits = lt_str_hits ).
          ENDIF.
        ENDLOOP.

        me->collect_structure_from_meta( EXPORTING iv_objtype = gc_export-kw_obj_func iv_objname = CONV sobj_name( lv_func_name ) CHANGING ct_str_hits = lt_str_hits ).

      WHEN gc_export-kw_obj_clas.
        lv_class_name = iv_objname.
        TRANSLATE lv_class_name TO UPPER CASE.
        CONDENSE lv_class_name NO-GAPS.

        lt_class_source = me->go_fetch->get_class( iv_class_name = lv_class_name ).
        LOOP AT lt_class_source INTO ls_class_source.
          IF ls_class_source-source_code IS NOT INITIAL.
            me->collect_structure_from_source( EXPORTING it_source = ls_class_source-source_code CHANGING ct_str_hits = lt_str_hits ).
          ENDIF.
        ENDLOOP.

        me->collect_structure_from_meta( EXPORTING iv_objtype = gc_export-kw_obj_clas iv_objname = CONV sobj_name( lv_class_name ) CHANGING ct_str_hits = lt_str_hits ).

      WHEN OTHERS.
        RETURN.

    ENDCASE.

    rt_structure = me->build_structure_rows( lt_str_hits ).


    IF rt_structure IS INITIAL.
      APPEND INITIAL LINE TO rt_structure ASSIGNING <lfs_structure>.
      IF <lfs_structure> IS ASSIGNED.

        ASSIGN COMPONENT 1 OF STRUCTURE <lfs_structure> TO <lfs_field>.
        IF sy-subrc = 0.
          CLEAR <lfs_field>.
        ENDIF.


        lv_col_index = 2.
        DO.
          ASSIGN COMPONENT lv_col_index OF STRUCTURE <lfs_structure> TO <lfs_field>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          TRY.
              <lfs_field> = gc_na.
            CATCH cx_root.

          ENDTRY.

          lv_col_index = lv_col_index + 1.
        ENDDO.

      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD helper_fugr_download.

    DATA: ls_fg_fm    TYPE gty_fg_fm,
          lv_filename TYPE string,
          lv_path     TYPE string,
          lv_fullpath TYPE string,
          lv_action   TYPE i.

    IF column <> gc_col_download.
      RETURN.
    ENDIF.

    READ TABLE gt_fg_fm INTO ls_fg_fm INDEX row.
    IF sy-subrc <> 0 OR ls_fg_fm-fm_name IS INITIAL.
      RETURN.
    ENDIF.


    lv_filename = |{ gc_fm_prefix }{ ls_fg_fm-fm_name }|.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        default_extension = gc_ext_xlsm "
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
      iv_func_name       = ls_fg_fm-fm_name
      iv_direct_download = abap_true
      iv_save_as         = lv_fullpath ).

  ENDMETHOD.
ENDCLASS.
