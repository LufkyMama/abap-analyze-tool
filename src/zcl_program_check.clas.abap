CLASS zcl_program_check DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF gty_naming_ctx,
        obj_type  TYPE tadir-object,
        obj_name  TYPE sobj_name,
        main_prog TYPE progname,
        include   TYPE progname,
      END OF gty_naming_ctx .

    METHODS analyze_clean_code
      IMPORTING
        !is_ctx               TYPE gty_naming_ctx
        !it_source            TYPE string_table
        !iv_check_unused_text TYPE abap_bool DEFAULT abap_true
        !it_usage_source      TYPE string_table OPTIONAL
      RETURNING
        VALUE(rt_errors)      TYPE ztt_error .
    METHODS analyze_hardcode
      IMPORTING
        !is_ctx          TYPE gty_naming_ctx
        !it_source       TYPE string_table
      RETURNING
        VALUE(rt_errors) TYPE ztt_error .
    METHODS analyze_obsolete
      IMPORTING
        !is_ctx          TYPE gty_naming_ctx
        !it_source       TYPE string_table
      RETURNING
        VALUE(rt_errors) TYPE ztt_error .
    METHODS analyze_naming
      IMPORTING
        !is_ctx              TYPE gty_naming_ctx
        !it_source           TYPE string_table
        !it_class_sig_source TYPE string_table OPTIONAL "NEW
      RETURNING
        VALUE(rt_errors)     TYPE ztt_error .
    METHODS analyze_performance
      IMPORTING
        !is_ctx          TYPE gty_naming_ctx
        !it_source       TYPE string_table
      RETURNING
        VALUE(rt_errors) TYPE ztt_error .
  PROTECTED SECTION.
PRIVATE SECTION.

  "------------------------------------------------------------
  " Shared technical TYPES
  "------------------------------------------------------------
  TYPES: gty_t_tok_tab         TYPE STANDARD TABLE OF stokex WITH DEFAULT KEY .
  TYPES: gty_t_stmt_tab        TYPE STANDARD TABLE OF sstmnt WITH DEFAULT KEY .

  TYPES: BEGIN OF gty_src_line,
           row        TYPE i,
           no_comment TYPE string,
           upper      TYPE string,
           is_blank   TYPE abap_bool,
           is_star    TYPE abap_bool,
           is_quote   TYPE abap_bool,
         END OF gty_src_line .

  TYPES: gty_t_src_line TYPE STANDARD TABLE OF gty_src_line WITH EMPTY KEY .

  TYPES: BEGIN OF gty_cnt,
           name TYPE string,
           cnt  TYPE i,
         END OF gty_cnt .

  TYPES: gty_t_cnt TYPE HASHED TABLE OF gty_cnt WITH UNIQUE KEY name .

  "------------------------------------------------------------
  " Shared Naming TYPES
  "------------------------------------------------------------
  TYPES: BEGIN OF gty_global_decl,
           name_u TYPE string,
           name   TYPE string,
           row    TYPE i,
         END OF gty_global_decl .

  TYPES: gty_t_global_decl TYPE HASHED TABLE OF gty_global_decl WITH UNIQUE KEY name_u .
  TYPES: gty_t_routine_set TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line .

  TYPES: BEGIN OF gty_use,
           name_u   TYPE string,
           routines TYPE gty_t_routine_set,
         END OF gty_use .

  TYPES: gty_t_use TYPE HASHED TABLE OF gty_use WITH UNIQUE KEY name_u .

  TYPES: BEGIN OF gty_pending,
           name_u          TYPE string,
           name            TYPE string,
           row             TYPE i,
           msg             TYPE string,
           is_local_prefix TYPE abap_bool,
         END OF gty_pending .

  TYPES: gty_t_pending TYPE STANDARD TABLE OF gty_pending WITH EMPTY KEY .

  TYPES: BEGIN OF gty_stmt_info,
           from            TYPE i,
           to              TYPE i,
           first_u         TYPE string,
           is_local_scope  TYPE abap_bool,
           is_data_stmt    TYPE abap_bool,
           current_routine TYPE string,
         END OF gty_stmt_info .

  TYPES: gty_t_stmt_info TYPE STANDARD TABLE OF gty_stmt_info WITH EMPTY KEY .
  TYPES: gty_nm_kind TYPE c LENGTH 1 .

  TYPES: BEGIN OF gty_name_kind,
           name_u    TYPE string,
           kind      TYPE gty_nm_kind,
           line_kind TYPE gty_nm_kind,
         END OF gty_name_kind .

  TYPES: gty_t_name_kind TYPE HASHED TABLE OF gty_name_kind WITH UNIQUE KEY name_u .

  TYPES: BEGIN OF gty_nm_method_ret,
           method_name TYPE string,
           return_kind TYPE gty_nm_kind,
         END OF gty_nm_method_ret .

  TYPES: gty_t_nm_method_ret TYPE HASHED TABLE OF gty_nm_method_ret WITH UNIQUE KEY method_name .

  CONSTANTS:
    "------------------------------------------------------------
    "     CONSTANTS
    "------------------------------------------------------------
    BEGIN OF gc_severity,
      error   TYPE symsgty VALUE 'E',
      warning TYPE symsgty VALUE 'W',
    END OF gc_severity .
  CONSTANTS:
    BEGIN OF gc_token_type,
      identifier TYPE c LENGTH 1 VALUE 'I',
    END OF gc_token_type .
  CONSTANTS:
    BEGIN OF gc_obj_type,
      prog    TYPE tadir-object VALUE 'PROG',
      clas    TYPE tadir-object VALUE 'CLAS',
      reps    TYPE tadir-object VALUE 'REPS',
      incl    TYPE tadir-object VALUE 'INCL',
      fugr    TYPE tadir-object VALUE 'FUGR',
      func    TYPE tadir-object VALUE 'FUNC',
      fm      TYPE tadir-object VALUE 'FM',
      r3tr    TYPE tadir-pgmid  VALUE 'R3TR',
      sapl    TYPE string       VALUE 'SAPL',
      unknown TYPE syuname      VALUE 'UNKNOWN',
    END OF gc_obj_type .
  CONSTANTS:
    BEGIN OF gc_category,
      hardcode    TYPE string VALUE 'HARDCODE',
      naming      TYPE string VALUE 'NAMING',
      performance TYPE string VALUE 'PERFORMANCE',
      obsolete    TYPE string VALUE 'OBSOLETE',
      clean_code  TYPE string VALUE 'CLEAN_CODE',
    END OF gc_category .
  CONSTANTS:
    BEGIN OF gc_keyword,
      " Declaration / definition keywords
      class_constants      TYPE string VALUE 'CLASS-CONSTANTS',
      class_constants_col  TYPE string VALUE 'CLASS-CONSTANTS:',
      class_data           TYPE string VALUE 'CLASS-DATA',
      class_data_col       TYPE string VALUE 'CLASS-DATA:',
      class_methods        TYPE string VALUE 'CLASS-METHODS',
      class_methods_col    TYPE string VALUE 'CLASS-METHODS:',
      constants            TYPE string VALUE 'CONSTANTS',
      constants_col        TYPE string VALUE 'CONSTANTS:',
      data                 TYPE string VALUE 'DATA',
      data_col             TYPE string VALUE 'DATA:',
      field_symbol         TYPE string VALUE 'FIELD-SYMBOL',
      field_symbols        TYPE string VALUE 'FIELD-SYMBOLS',
      field_symbols_col    TYPE string VALUE 'FIELD-SYMBOLS:',
      field_symbol_lparen  TYPE string VALUE 'FIELD-SYMBOL(',
      field_symbol_lparen2 TYPE string VALUE 'FIELD-SYMBOL (',
      field_symbol_star    TYPE string VALUE 'FIELD-SYMBOL(*)',
      methods              TYPE string VALUE 'METHODS',
      methods_col          TYPE string VALUE 'METHODS:',
      parameter            TYPE string VALUE 'PARAMETER',
      parameters           TYPE string VALUE 'PARAMETERS',
      parameters_col       TYPE string VALUE 'PARAMETERS:',
      program              TYPE string VALUE 'PROGRAM',
      select_options       TYPE string VALUE 'SELECT-OPTIONS',
      select_options_col   TYPE string VALUE 'SELECT-OPTIONS:',
      statics              TYPE string VALUE 'STATICS',
      statics_col          TYPE string VALUE 'STATICS:',
      types                TYPE string VALUE 'TYPES',
      types_col            TYPE string VALUE 'TYPES:',

      " Block / routine / event keywords
      at                   TYPE string VALUE 'AT',
      at_line_selection    TYPE string VALUE 'AT LINE-SELECTION',
      at_selection_screen  TYPE string VALUE 'AT SELECTION-SCREEN',
      at_sel_screen_on     TYPE string VALUE 'AT SELECTION-SCREEN ON',
      at_sel_screen_out    TYPE string VALUE 'AT SELECTION-SCREEN OUTPUT',
      at_user_command      TYPE string VALUE 'AT USER-COMMAND',
      begin                TYPE string VALUE 'BEGIN',
      block                TYPE string VALUE 'BLOCK',
      define               TYPE string VALUE 'DEFINE',
      end                  TYPE string VALUE 'END',
      end_of_definition    TYPE string VALUE 'END-OF-DEFENITION',
      end_of_page          TYPE string VALUE 'END-OF-PAGE',
      end_of_selection     TYPE string VALUE 'END-OF-SELECTION',
      endform              TYPE string VALUE 'ENDFORM',
      endfunc              TYPE string VALUE 'ENDFUNCTION',
      endmethod            TYPE string VALUE 'ENDMETHOD',
      endmodule            TYPE string VALUE 'ENDMODULE',
      form                 TYPE string VALUE 'FORM',
      func                 TYPE string VALUE 'FUNCTION',
      func_pat             TYPE string VALUE 'FUNCTION *.',
      include              TYPE string VALUE 'INCLUDE',
      include_pat          TYPE string VALUE 'INCLUDE *',
      initialization       TYPE string VALUE 'INITIALIZATION',
      line_selection       TYPE string VALUE 'LINE-SELECTION',
      method               TYPE string VALUE 'METHOD',
      module               TYPE string VALUE 'MODULE',
      perform              TYPE string VALUE 'PERFORM',
      select               TYPE string VALUE 'SELECT',
      selection_screen     TYPE string VALUE 'SELECTION-SCREEN',
      start_of_selection   TYPE string VALUE 'START-OF-SELECTION',
      top_of_page          TYPE string VALUE 'TOP-OF-PAGE',
      user_command         TYPE string VALUE 'USER-COMMAND',
      where                TYPE string VALUE 'WHERE',

      " General statement keywords
      call                 TYPE string VALUE 'CALL',
      message              TYPE string VALUE 'MESSAGE',

      " Signature / typing / option keywords
      add                  TYPE string VALUE 'ADD',
      at_data_inline       TYPE string VALUE '@DATA(*)',
      append               TYPE string VALUE 'APPEND',
      appending            TYPE string VALUE 'APPENDING',
      assign               TYPE string VALUE 'ASSIGN',
      assigning            TYPE string VALUE 'ASSIGNING',
      cast                 TYPE string VALUE 'CAST',
      changing             TYPE string VALUE 'CHANGING',
      checkbox             TYPE string VALUE 'CHECKBOX',
      clear                TYPE string VALUE 'CLEAR',
      collect              TYPE string VALUE 'COLLECT',
      conv                 TYPE string VALUE 'CONV',
      corresponding        TYPE string VALUE 'CORRESPONDING',
      count                TYPE string VALUE 'COUNT',
      data_inline          TYPE string VALUE 'DATA(*)',
      data_lparen          TYPE string VALUE 'DATA(',
      default              TYPE string VALUE 'DEFAULT',
      delete               TYPE string VALUE 'DELETE',
      describe             TYPE string VALUE 'DESCRIBE',
      empty                TYPE string VALUE 'EMPTY',
      exceptions           TYPE string VALUE 'EXCEPTIONS',
      exporting            TYPE string VALUE 'EXPORTING',
      for                  TYPE string VALUE 'FOR',
      free                 TYPE string VALUE 'FREE',
      from                 TYPE string VALUE 'FROM',
      group                TYPE string VALUE 'GROUP',
      hashed               TYPE string VALUE 'HASHED',
      in                   TYPE string VALUE 'IN',
      importing            TYPE string VALUE 'IMPORTING',
      initial              TYPE string VALUE 'INITIAL',
      into                 TYPE string VALUE 'INTO',
      key                  TYPE string VALUE 'KEY',
      length               TYPE string VALUE 'LENGTH',
      like                 TYPE string VALUE 'LIKE',
      line                 TYPE string VALUE 'LINE',
      lines                TYPE string VALUE 'LINES',
      modify               TYPE string VALUE 'MODIFY',
      move                 TYPE string VALUE 'MOVE',
      new                  TYPE string VALUE 'NEW',
      of                   TYPE string VALUE 'OF',
      on                   TYPE string VALUE 'ON',
      optional             TYPE string VALUE 'OPTIONAL',
      output               TYPE string VALUE 'OUTPUT',
      preferred            TYPE string VALUE 'PREFERRED',
      radiobutton          TYPE string VALUE 'RADIOBUTTON',
      raising              TYPE string VALUE 'RAISING',
      receiving            TYPE string VALUE 'RECEIVING',
      ref                  TYPE string VALUE 'REF',
      reference            TYPE string VALUE 'REFERENCE',
      reference_lparen     TYPE string VALUE 'REFERENCE(',
      ref_inline           TYPE string VALUE 'REFERENCE(*)',
      refresh              TYPE string VALUE 'REFRESH',
      returning            TYPE string VALUE 'RETURNING',
      single               TYPE string VALUE 'SINGLE',
      sorted               TYPE string VALUE 'SORTED',
      sort                 TYPE string VALUE 'SORT',
      standard             TYPE string VALUE 'STANDARD',
      structure            TYPE string VALUE 'STRUCTURE',
      subtract             TYPE string VALUE 'SUBTRACT',
      sy_subrc             TYPE string VALUE 'SY-SUBRC',
      table                TYPE string VALUE 'TABLE',
      tables               TYPE string VALUE 'TABLES',
      to                   TYPE string VALUE 'TO',
      type                 TYPE string VALUE 'TYPE',
      using                TYPE string VALUE 'USING',
      value                TYPE string VALUE 'VALUE',
      value_star           TYPE string VALUE 'VALUE(*)',
      value_lparen         TYPE string VALUE 'VALUE(',
      with                 TYPE string VALUE 'WITH',

      " Symbols / text / pattern literals
      at_sign              TYPE c LENGTH 1 VALUE '@',
      at_data_lparen       TYPE string     VALUE '@DATA(',
      colon                TYPE string     VALUE ':',
      comma                TYPE string     VALUE ',',
      comment_quote        TYPE string     VALUE '*"',
      comment_quote_rev    TYPE string     VALUE '"*',
      count_lparen         TYPE string     VALUE 'COUNT(',
      dash                 TYPE c LENGTH 1 VALUE '-',
      empty_string         TYPE string     VALUE '',
      dot                  TYPE string     VALUE '.',
      empty_bt             TYPE string     VALUE '``',
      empty_single_bt      TYPE string     VALUE '`',
      empty_pipe           TYPE string     VALUE '||',
      empty_single_pipe    TYPE string     VALUE '|',
      empty_sq             TYPE string     VALUE '''''',
      empty_single_sq      TYPE string     VALUE '''',
      equal                TYPE string     VALUE '=',
      exclamation_mark     TYPE string     VALUE '!',
      field_symbol_pat     TYPE string     VALUE '<*>',
      hash                 TYPE string     VALUE '#',
      invalid_assign_pat   TYPE string     VALUE '*===*',
      instance_call        TYPE string     VALUE '->',
      lbrace               TYPE c LENGTH 1 VALUE '{',
      lbracket             TYPE string     VALUE '[',
      cast_assign          TYPE string     VALUE '?=',
      exact_cast_assign    TYPE string     VALUE '??=',
      lit_space            TYPE c LENGTH 1 VALUE ' ',
      lparen               TYPE string     VALUE '(',
      pat_bt               TYPE string     VALUE '`*`',
      pat_pipe             TYPE string     VALUE '|*|',
      pat_sq               TYPE string     VALUE '''*''',
      plus                 TYPE string     VALUE '+',
      quote                TYPE string     VALUE '"',
      rbrace               TYPE c LENGTH 1 VALUE '}',
      rparen               TYPE string     VALUE ')',
      semicolon            TYPE c LENGTH 1 VALUE ';',
      slash                TYPE c LENGTH 1 VALUE '/',
      spec_star            TYPE string     VALUE '{*}',
      star                 TYPE string     VALUE '*',
      static_call          TYPE string     VALUE '=>',
      underscore           TYPE c LENGTH 1 VALUE '_',
    END OF gc_keyword .
  CONSTANTS:
    "--------------------------------------------------
    " Naming convention
    "--------------------------------------------------
    BEGIN OF gc_sig_nm,
      changing  TYPE c LENGTH 1 VALUE 'C',
      exporting TYPE c LENGTH 1 VALUE 'E',
      importing TYPE c LENGTH 1 VALUE 'I',
      returning TYPE c LENGTH 1 VALUE 'R',
      tables    TYPE c LENGTH 1 VALUE 'T',
      using     TYPE c LENGTH 1 VALUE 'U',
    END OF gc_sig_nm .
  CONSTANTS:
    BEGIN OF gc_kind_nm,
      data_ref  TYPE c LENGTH 1 VALUE 'D',
      object    TYPE c LENGTH 1 VALUE 'O',
      range     TYPE c LENGTH 1 VALUE 'R',
      structure TYPE c LENGTH 1 VALUE 'S',
      table     TYPE c LENGTH 1 VALUE 'T',
      unknown   TYPE c LENGTH 1 VALUE 'U',
      value     TYPE c LENGTH 1 VALUE 'V',
    END OF gc_kind_nm .
  CONSTANTS:
    BEGIN OF gc_msg_nm,
      global        TYPE string VALUE 'Global' ##NO_TEXT,
      global_inline TYPE string VALUE 'Global inline' ##NO_TEXT,
      inline        TYPE string VALUE 'Inline' ##NO_TEXT,
      local         TYPE string VALUE 'Local' ##NO_TEXT,
    END OF gc_msg_nm .
  CONSTANTS:
    BEGIN OF gc_builtin_type_nm,
      abap_string     TYPE string VALUE 'STRING',
      abap_xstring    TYPE string VALUE 'XSTRING',
      abap_c          TYPE string VALUE 'C',
      abap_n          TYPE string VALUE 'N',
      abap_d          TYPE string VALUE 'D',
      abap_t          TYPE string VALUE 'T',
      abap_i          TYPE string VALUE 'I',
      abap_int8       TYPE string VALUE 'INT8',
      abap_f          TYPE string VALUE 'F',
      abap_p          TYPE string VALUE 'P',
      abap_decfloat16 TYPE string VALUE 'DECFLOAT16',
      abap_decfloat34 TYPE string VALUE 'DECFLOAT34',
      abap_utclong    TYPE string VALUE 'UTCLONG',
    END OF gc_builtin_type_nm .
  CONSTANTS:
    BEGIN OF gc_rx_nm,
      like_name TYPE string VALUE 'LIKE\s+([A-Z0-9_=>\-]+)' ##NO_TEXT,
      type_name TYPE string VALUE 'TYPE\s+([A-Z0-9_=>\-]+)' ##NO_TEXT,
      fm_value  TYPE string VALUE 'VALUE\(([A-Z0-9_!]+)\)' ##NO_TEXT,
    END OF gc_rx_nm .
  CONSTANTS:
    BEGIN OF gc_iface_phrase_nm,
      hashed_table   TYPE string VALUE ' HASHED TABLE ',
      sorted_table   TYPE string VALUE ' SORTED TABLE ',
      standard_table TYPE string VALUE ' STANDARD TABLE ',
      structure      TYPE string VALUE ' STRUCTURE ',
      table_of       TYPE string VALUE ' TABLE OF ',
    END OF gc_iface_phrase_nm .
  CONSTANTS:
    BEGIN OF gc_rule_nm,
      prefix_rule TYPE string VALUE 'NM_PREFIX_RULE',
    END OF gc_rule_nm .
  CONSTANTS:
    BEGIN OF gc_scope,
      global TYPE string VALUE '<<GLOBAL>>',
      block  TYPE string VALUE '<<BLOCK>>',
    END OF gc_scope .
  CONSTANTS:
    "--------------------------------------------------
    " Clean code
    "--------------------------------------------------
    BEGIN OF gc_rule_cc,
      blank_lines        TYPE string VALUE 'CC_BLANK_LINES',
      unused_local       TYPE string VALUE 'CC_UNUSED_LOCAL',
      unused_text_symbol TYPE string VALUE 'CC_UNUSED_TEXT_SYMBOL',
      unused_subroutine  TYPE string VALUE 'CC_UNUSED_SUBROUTINE',
    END OF gc_rule_cc .
  CONSTANTS:
    BEGIN OF gc_clean_code,
      blank_limit        TYPE i VALUE 3,
      unused_token_limit TYPE i VALUE 1,
      textpool_i         TYPE textpool-id VALUE 'I',
      text_symbol        TYPE string VALUE `TEXT-([0-9][0-9][0-9]|[A-Z][0-9][0-9])` ##NO_TEXT,
      rx_identifier      TYPE string VALUE '[A-Z_][A-Z0-9_]*' ##NO_TEXT,
    END OF gc_clean_code .
  "--------------------------------------------------
  " Obsolete
  "--------------------------------------------------
  CONSTANTS gc_digits TYPE string VALUE '0123456789' ##NO_TEXT.
  CONSTANTS gc_tech_e TYPE string VALUE 'E' ##NO_TEXT.
  CONSTANTS gc_tech_w TYPE string VALUE 'W' ##NO_TEXT.
  CONSTANTS gc_tech_i TYPE string VALUE 'I' ##NO_TEXT.
  CONSTANTS gc_tech_s TYPE string VALUE 'S' ##NO_TEXT.
  CONSTANTS gc_tech_a TYPE string VALUE 'A' ##NO_TEXT.
  CONSTANTS gc_tech_x TYPE string VALUE 'X' ##NO_TEXT.
  CONSTANTS gc_tech_eq TYPE string VALUE 'EQ' ##NO_TEXT.
  CONSTANTS gc_tech_ne TYPE string VALUE 'NE' ##NO_TEXT.
  CONSTANTS gc_tech_bt TYPE string VALUE 'BT' ##NO_TEXT.
  CONSTANTS gc_tech_cp TYPE string VALUE 'CP' ##NO_TEXT.
  CONSTANTS gc_tech_ge TYPE string VALUE 'GE' ##NO_TEXT.
  CONSTANTS gc_tech_le TYPE string VALUE 'LE' ##NO_TEXT.
  CONSTANTS gc_tech_gt TYPE string VALUE 'GT' ##NO_TEXT.
  CONSTANTS gc_tech_lt TYPE string VALUE 'LT' ##NO_TEXT.
  CONSTANTS:
    BEGIN OF gc_kw_obsolete,
      move_kw         TYPE string VALUE 'MOVE',
      occurs_kw       TYPE string VALUE 'OCCURS',
      ranges_kw       TYPE string VALUE 'RANGES',
      compute_kw      TYPE string VALUE 'COMPUTE',
      extract_kw      TYPE string VALUE 'EXTRACT',
      field_groups_kw TYPE string VALUE 'FIELD-GROUPS',
      refresh_kw      TYPE string VALUE 'REFRESH',
      leave_kw        TYPE string VALUE 'LEAVE',
      add_kw          TYPE string VALUE 'ADD',
      subtract_kw     TYPE string VALUE 'SUBTRACT',
      multiply_kw     TYPE string VALUE 'MULTIPLY',
      divide_kw       TYPE string VALUE 'DIVIDE',
      local_kw        TYPE string VALUE 'LOCAL',
      supply_kw       TYPE string VALUE 'SUPPLY',
      from_kw         TYPE string VALUE 'FROM',
      by_kw           TYPE string VALUE 'BY',
      control_kw      TYPE string VALUE 'CONTROL',
      catch_kw        TYPE string VALUE 'CATCH',
    END OF gc_kw_obsolete .
  CONSTANTS:
    BEGIN OF gc_phrase_obsolete,
      with_header_line     TYPE string VALUE 'WITH HEADER LINE',
      on_change_of         TYPE string VALUE 'ON CHANGE OF',
      call_transaction     TYPE string VALUE 'CALL TRANSACTION',
      with_authority_check TYPE string VALUE 'WITH AUTHORITY-CHECK',
      without_auth_check   TYPE string VALUE 'WITHOUT AUTHORITY-CHECK',
      call_dialog          TYPE string VALUE 'CALL DIALOG',
      catch_system_exc     TYPE string VALUE 'CATCH SYSTEM-EXCEPTIONS',
      call_method          TYPE string VALUE 'CALL METHOD',
    END OF gc_phrase_obsolete .
  CONSTANTS:
    BEGIN OF gc_old_relop,
      not_equal_1 TYPE string VALUE '><',
      less_equal  TYPE string VALUE '=<',
      greater_eq  TYPE string VALUE '=>',
    END OF gc_old_relop .
  CONSTANTS:
    BEGIN OF gc_msg_obsolete,
      old_relop            TYPE string VALUE 'OLD RELATIONAL OPERATOR',
      field_symbols_typing TYPE string VALUE 'FIELD-SYMBOLS obsolete typing' ##NO_TEXT,
*      describe_table_lines TYPE string VALUE 'DESCRIBE TABLE ... LINES',
    END OF gc_msg_obsolete .
  CONSTANTS:
    BEGIN OF gc_pat_obsolete,
      field_symbols_any TYPE string VALUE 'FIELD-SYMBOLS*',
    END OF gc_pat_obsolete .
  CONSTANTS:
    BEGIN OF gc_rule_obsolete,
      move_rule              TYPE string VALUE 'OBSOLETE_MOVE',
      occurs_rule            TYPE string VALUE 'OBSOLETE_OCCURS',
      ranges_rule            TYPE string VALUE 'OBSOLETE_RANGES',
      compute_rule           TYPE string VALUE 'OBSOLETE_COMPUTE',

      extract_rule           TYPE string VALUE 'OBSOLETE_EXTRACT',
      field_groups_rule      TYPE string VALUE 'OBSOLETE_FIELD_GROUPS',
      refresh_rule           TYPE string VALUE 'OBSOLETE_REFRESH',
      add_rule               TYPE string VALUE 'OBSOLETE_ADD',
      subtract_rule          TYPE string VALUE 'OBSOLETE_SUBTRACT',
      multiply_rule          TYPE string VALUE 'OBSOLETE_MULTIPLY',
      divide_rule            TYPE string VALUE 'OBSOLETE_DIVIDE',
      local_rule             TYPE string VALUE 'OBSOLETE_LOCAL',
      supply_rule            TYPE string VALUE 'OBSOLETE_SUPPLY',
      leave_rule             TYPE string VALUE 'OBSOLETE_LEAVE',

      call_dialog_rule       TYPE string VALUE 'OBSOLETE_CALL_DIALOG',
      catch_system_exc_rule  TYPE string VALUE 'OBSOLETE_CATCH_SYSTEM_EXC',

      call_method_rule       TYPE string VALUE 'OBSOLETE_CALL_METHOD',
      header_line_rule       TYPE string VALUE 'OBSOLETE_WITH_HEADER_LINE',
      on_change_rule         TYPE string VALUE 'OBSOLETE_ON_CHANGE_OF',
      relop_rule             TYPE string VALUE 'OBSOLETE_REL_OPERATOR',

      field_symbol_type_rule TYPE string VALUE 'OBSOLETE_FIELD_SYMBOL_TYPING',
      auth_check_rule        TYPE string VALUE 'OBSOLETE_CALL_TRANSACTION_AUTH',
    END OF gc_rule_obsolete .
  CONSTANTS:
    BEGIN OF gc_rx_obsolete,

      " Remove literals
      sq_literal           TYPE string VALUE `'(?:''|[^'])*'`,
      bt_literal           TYPE string VALUE '`(?:``|[^`])*`',

      " Common regex fragments
      right_boundary       TYPE string VALUE `([^A-Z0-9_]|$)` ##NO_TEXT,
      occurs_left_boundary TYPE string VALUE `(^|[^A-Z0-9_-])` ##NO_TEXT,
      stmt_begin           TYPE string VALUE `^\s*`,
      stmt_end             TYPE string VALUE `$`,
      ws0                  TYPE string VALUE `\s*`,
      ws1                  TYPE string VALUE `\s+`,
      anything             TYPE string VALUE `.+`,
      dot_esc              TYPE string VALUE `\.`,
      opt_colon            TYPE string VALUE `:?`,
      alt                  TYPE string VALUE '|',

      " FIELD-SYMBOLS fragments
      fs_name              TYPE string VALUE `<[^>]+>`,
      fs_more_names        TYPE string VALUE `(\s*,\s*<[^>]+>)*`,

    END OF gc_rx_obsolete .
  CONSTANTS:
    "--------------------------------------------------
    " Performance
    "--------------------------------------------------
    BEGIN OF gc_perf_kw,
      loop_at        TYPE string VALUE 'LOOP AT',
      endloop        TYPE string VALUE 'ENDLOOP',
      read_table     TYPE string VALUE 'READ TABLE',
      with_key       TYPE string VALUE 'WITH KEY',
      binary_search  TYPE string VALUE 'BINARY SEARCH',
      with_table_key TYPE string VALUE 'WITH TABLE KEY',
      sort           TYPE string VALUE 'SORT',
      select         TYPE string VALUE 'SORT',
    END OF gc_perf_kw .
  CONSTANTS:
    BEGIN OF gc_rule_perf,
      select_star     TYPE string VALUE 'PERF_SELECT_STAR',
      nested_loop     TYPE string VALUE 'PERF_NESTED_LOOP',
      select_in_loop  TYPE string VALUE 'PERF_SELECT_IN_LOOP',
      read_no_binary  TYPE string VALUE 'PERF_READ_NO_BINARY',
      fae_empty_check TYPE string VALUE 'PERF_FAE_EMPTY_CHECK',
      sort_in_loop    TYPE string VALUE 'SORT_IN_LOOP',
    END OF gc_rule_perf .
  CONSTANTS:
    BEGIN OF gc_perf_regex,
      loop_at_table        TYPE string VALUE `\bLOOP\s+AT\s+([A-Z][A-Z0-9_\->]*)\b` ##NO_TEXT,
      select_stmt          TYPE string VALUE `^\s*SELECT\b` ##NO_TEXT,
      select_all           TYPE string VALUE `^\s*SELECT\s+\*` ##NO_TEXT,
      sort_table           TYPE string VALUE `^\s*SORT\s+([A-Z][A-Z0-9_\->]*)\b` ##NO_TEXT,
      fae_table            TYPE string VALUE `FOR\s+ALL\s+ENTRIES\s+IN\s+@?([A-Z0-9_<>\-]+)` ##NO_TEXT,
      loop_filter_or_range TYPE string VALUE `\b(WHERE|FROM|TO)\b`,
      loop_assign_fs       TYPE string VALUE 'LOOP\s+AT\s+\S+.*\s+ASSIGNING\s+(?:FIELD-SYMBOL\s*\(\s*)?(<[A-Z0-9_]+>)(?:\s*\))?' ##NO_TEXT,
      fs_assign_sp         TYPE string VALUE '-* = *',
      fs_assign            TYPE string VALUE '-*=*',
    END OF gc_perf_regex .
  CONSTANTS:
    BEGIN OF gc_perf_cfg,
      fae_guard_lookback TYPE i VALUE 5,
      heavy_depth_min    TYPE i VALUE 1,
      zero               TYPE i VALUE 0,
    END OF gc_perf_cfg .
  CONSTANTS:
    BEGIN OF gc_perf_guard,
      if_kw              TYPE string VALUE 'IF',
      check_kw           TYPE string VALUE 'CHECK',
      assert_kw          TYPE string VALUE 'ASSERT',
      is_not_initial_pat TYPE string VALUE 'IS NOT INITIAL.*',
    END OF gc_perf_guard .
  CONSTANTS:
    BEGIN OF gc_perf_ignore_read,
      rtts_methods    TYPE string VALUE '->METHODS',
      rtts_parameters TYPE string VALUE '-PARAMETERS',
    END OF gc_perf_ignore_read.
  "------------------------------------------------------------
  " METHODS
  "------------------------------------------------------------
  METHODS nm_data_checks
    IMPORTING
      !it_tokens          TYPE gty_t_tok_tab
      !it_stmt_info       TYPE gty_t_stmt_info
      !iv_curr_src_lines  TYPE i
      !it_method_ret_kind TYPE gty_t_nm_method_ret OPTIONAL "NEW NEW NEW
    CHANGING
      !ct_global_decl     TYPE gty_t_global_decl
      !ct_use             TYPE gty_t_use
      !ct_pending         TYPE gty_t_pending
      !ct_errors          TYPE ztt_error .
  METHODS nm_additional_naming_checks
    IMPORTING
      !it_source         TYPE string_table
      !it_tokens         TYPE gty_t_tok_tab
      !it_stmts          TYPE gty_t_stmt_tab
      !it_stmt_info      TYPE gty_t_stmt_info
      !it_global_decl    TYPE gty_t_global_decl
      !it_use            TYPE gty_t_use
      !it_pending        TYPE gty_t_pending
      !iv_curr_src_lines TYPE i
    CHANGING
      !ct_errors         TYPE ztt_error .
  METHODS nm_resolve_type_kind
    IMPORTING
      !iv_type_name  TYPE string
    EXPORTING
      !ev_kind       TYPE gty_nm_kind
      !ev_line_kind  TYPE gty_nm_kind
    CHANGING
      !ct_type_cache TYPE gty_t_name_kind .
  METHODS nm_resolve_sig_kind
    IMPORTING
      !it_tokens     TYPE gty_t_tok_tab
      !iv_from       TYPE sy-tabix
      !iv_to         TYPE sy-tabix
    EXPORTING
      !ev_kind       TYPE c
      !ev_last_idx   TYPE sy-tabix
    CHANGING
      !ct_type_cache TYPE gty_t_name_kind .
  METHODS cc_preprocess_source
    IMPORTING
      !it_source    TYPE string_table
    RETURNING
      VALUE(rt_src) TYPE gty_t_src_line .
  METHODS cc_add_usage_count
    IMPORTING
      !iv_name TYPE string
    CHANGING
      !ct_cnt  TYPE gty_t_cnt .
  METHODS cc_unused_variables
    IMPORTING
      !it_source       TYPE string_table
      !it_usage_source TYPE string_table OPTIONAL
      !it_tokens       TYPE gty_t_tok_tab OPTIONAL
      !it_stmts        TYPE gty_t_stmt_tab OPTIONAL
    RETURNING
      VALUE(rt_errors) TYPE ztt_error .
  METHODS cc_unused_text_symbols
    IMPORTING
      !it_source       TYPE string_table
      !is_ctx          TYPE gty_naming_ctx
    RETURNING
      VALUE(rt_errors) TYPE ztt_error .
  METHODS get_object_author
    IMPORTING
      !iv_obj_type     TYPE tadir-object
      !iv_obj_name     TYPE sobj_name
    RETURNING
      VALUE(rv_author) TYPE syuname .

  METHODS nm_build_method_ret_kind
    IMPORTING
      !it_tokens           TYPE gty_t_tok_tab
    CHANGING
      !ct_type_cache       TYPE gty_t_name_kind
      !ct_method_ret_cache TYPE gty_t_nm_method_ret .
  METHODS nm_resolve_called_method_kind
    IMPORTING
      !iv_probe_u         TYPE string
      !iv_prev_u          TYPE string
      !iv_next_u          TYPE string
      !iv_probe_idx       TYPE sy-tabix
      !it_tokens          TYPE gty_t_tok_tab
      !it_method_ret_kind TYPE gty_t_nm_method_ret
    RETURNING
      VALUE(rv_kind)      TYPE gty_nm_kind .
ENDCLASS.



CLASS ZCL_PROGRAM_CHECK IMPLEMENTATION.


METHOD analyze_clean_code.
  CLEAR: rt_errors.

  "------------------------------------------------------------
  " A) Local types
  "------------------------------------------------------------
  TYPES: BEGIN OF lty_form_decl,
           name_u TYPE string,
           name   TYPE string,
           row    TYPE i,
           cnt    TYPE i,
         END OF lty_form_decl.
  TYPES lty_t_form_decl TYPE HASHED TABLE OF lty_form_decl WITH UNIQUE KEY name_u.

  TYPES: BEGIN OF lty_name,
           name_u TYPE string,
         END OF lty_name.
  TYPES lty_t_name TYPE HASHED TABLE OF lty_name WITH UNIQUE KEY name_u.

  "------------------------------------------------------------
  " B) Local data
  "------------------------------------------------------------
  DATA lt_tokens       TYPE gty_t_tok_tab.
  DATA lt_stmts        TYPE gty_t_stmt_tab.
  DATA lt_usage_source TYPE string_table.
  DATA lt_words        TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  DATA lv_text                TYPE string.
  DATA lv_trim                TYPE string.
  DATA lv_i                   TYPE i.
  DATA lv_off                 TYPE i.
  DATA lv_word1               TYPE string.
  DATA lv_word2               TYPE string.
  DATA lv_name                TYPE string.
  DATA lv_up                  TYPE string.

  "------------------------------------------------------------
  " C) RULE 1 - Declared but not used
  "------------------------------------------------------------

  " Build source to scan once
  CLEAR lt_usage_source.

  IF it_usage_source IS NOT INITIAL.
    lt_usage_source = it_usage_source.
  ELSE.
    lt_usage_source = it_source.
  ENDIF.

  "------------------------------------------------------------
  " Scan source once
  "------------------------------------------------------------
  CLEAR: lt_tokens,
         lt_stmts.

  SCAN ABAP-SOURCE lt_usage_source
    TOKENS     INTO lt_tokens
    STATEMENTS INTO lt_stmts
    WITH ANALYSIS.

  DATA(lt_temp_errors) = cc_unused_variables(
    it_source       = it_source
    it_usage_source = lt_usage_source
    it_tokens       = lt_tokens
    it_stmts        = lt_stmts ).

  APPEND LINES OF lt_temp_errors TO rt_errors.

  "------------------------------------------------------------
  " D) RULE 2 - Blank lines
  "------------------------------------------------------------
  DATA(lt_src_curr) = cc_preprocess_source( it_source ).

  DATA(lv_blank_run)   = 0.
  DATA(lv_blank_start) = 0.

  LOOP AT lt_src_curr INTO DATA(ls_src_blank).
    IF ls_src_blank-is_blank = abap_true.
      IF lv_blank_run = 0.
        lv_blank_start = ls_src_blank-row.
      ENDIF.

      lv_blank_run += 1.

      IF lv_blank_run = gc_clean_code-blank_limit + 1.
        MESSAGE w022(z_gsp04_message) INTO lv_text.

        APPEND VALUE zst_error(
          rule     = gc_rule_cc-blank_lines
          sev      = gc_severity-warning
          line     = lv_blank_start
          msg      = lv_text
          category = gc_category-clean_code
        ) TO rt_errors.
      ENDIF.

      CONTINUE.
    ENDIF.

    CLEAR: lv_blank_run,
           lv_blank_start.
  ENDLOOP.

  "------------------------------------------------------------
  " E) RULE 3 - Unused text symbols
  "------------------------------------------------------------
  IF iv_check_unused_text = abap_true.
    CLEAR lt_temp_errors.

    lt_temp_errors = cc_unused_text_symbols(
      it_source = it_source
      is_ctx    = is_ctx ).

    APPEND LINES OF lt_temp_errors TO rt_errors.
  ENDIF.

  "------------------------------------------------------------
  " G) RULE 4 - Unused subroutine
  "------------------------------------------------------------
  DATA lt_forms TYPE lty_t_form_decl.
  DATA lt_called TYPE lty_t_name.
  DATA lv_stmt TYPE string.
  DATA lv_stmt_start TYPE i.
  DATA lv_prog TYPE progname.

  CLEAR: lt_forms,
         lt_called,
         lv_stmt,
         lv_stmt_start.

  " Collect FORM declarations from current source only
  lt_src_curr = cc_preprocess_source( it_source ).

  LOOP AT lt_src_curr INTO DATA(ls_src_form).
    IF ls_src_form-no_comment IS INITIAL.
      CONTINUE.
    ENDIF.

    IF lv_stmt IS INITIAL.
      lv_stmt_start = ls_src_form-row.
    ENDIF.

    CONCATENATE lv_stmt ls_src_form-no_comment
      INTO lv_stmt
      SEPARATED BY space.

    lv_i = strlen( ls_src_form-no_comment ).
    IF lv_i = 0.
      CONTINUE.
    ENDIF.

    lv_off = lv_i - 1.
    IF ls_src_form-no_comment+lv_off(1) <> gc_keyword-dot.
      CONTINUE.
    ENDIF.

    lv_trim = lv_stmt.
    CONDENSE lv_trim.

    CLEAR: lt_words,
           lv_word1,
           lv_word2,
           lv_name.
    SPLIT lv_trim AT space INTO TABLE lt_words.

    READ TABLE lt_words INDEX 1 INTO lv_word1.
    READ TABLE lt_words INDEX 2 INTO lv_word2.
    lv_word1 = to_upper( lv_word1 ).

    IF lv_word1 = gc_keyword-form.
      lv_name = lv_word2.
      REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_name WITH ''.
      lv_name = to_upper( lv_name ).

      IF lv_name IS NOT INITIAL.
        INSERT VALUE lty_form_decl(
          name_u = lv_name
          name   = lv_name
          row    = lv_stmt_start
          cnt    = 0
        ) INTO TABLE lt_forms.
      ENDIF.
    ENDIF.

    CLEAR: lv_stmt,
           lv_stmt_start.
  ENDLOOP.

  " Collect called FORM names from full scanned source
  lv_up = is_ctx-main_prog.
  IF lv_up IS INITIAL.
    lv_up = is_ctx-obj_name.
  ENDIF.
  lv_up = to_upper( lv_up ).

  LOOP AT lt_stmts INTO DATA(ls_perf_stmt).

    READ TABLE lt_tokens INDEX ls_perf_stmt-from INTO DATA(ls_perf_tok1).
    IF sy-subrc <> 0 OR ls_perf_tok1-str IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_word1 = ls_perf_tok1-str.
    lv_word1 = to_upper( lv_word1 ).
    IF lv_word1 <> gc_keyword-perform.
      CONTINUE.
    ENDIF.

    READ TABLE lt_tokens INDEX ls_perf_stmt-from + 1 INTO DATA(ls_perf_tok2).
    IF sy-subrc <> 0 OR ls_perf_tok2-str IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_name = ls_perf_tok2-str.
    REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_name WITH ''.
    lv_name = to_upper( lv_name ).

    IF lv_name IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR: lv_prog,
           lv_word2.

    lv_i = ls_perf_stmt-from + 2.
    WHILE lv_i <= ls_perf_stmt-to.
      READ TABLE lt_tokens INDEX lv_i INTO DATA(ls_perf_tokx).
      IF sy-subrc <> 0 OR ls_perf_tokx-str IS INITIAL.
        lv_i += 1.
        CONTINUE.
      ENDIF.

      lv_word1 = ls_perf_tokx-str.
      lv_word1 = to_upper( lv_word1 ).

      IF lv_word1 = gc_keyword-in.
        READ TABLE lt_tokens INDEX lv_i + 1 INTO DATA(ls_perf_toky).
        IF sy-subrc = 0 AND ls_perf_toky-str IS NOT INITIAL.
          lv_word2 = ls_perf_toky-str.
          REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_word2 WITH ''.
          lv_word2 = to_upper( lv_word2 ).

          IF lv_word2 = gc_keyword-program.
            READ TABLE lt_tokens INDEX lv_i + 2 INTO DATA(ls_perf_tokz).
            IF sy-subrc = 0 AND ls_perf_tokz-str IS NOT INITIAL.
              lv_prog = ls_perf_tokz-str.
              REPLACE ALL OCCURRENCES OF gc_keyword-dot   IN lv_prog WITH ''.
              REPLACE ALL OCCURRENCES OF gc_keyword-quote IN lv_prog WITH ''.
              lv_prog = to_upper( lv_prog ).
            ENDIF.
            EXIT.
          ENDIF.
        ENDIF.
      ENDIF.

      lv_i += 1.
    ENDWHILE.

    IF lv_word2 = gc_keyword-program
       AND ( lv_prog IS INITIAL OR lv_prog <> lv_up ).
      CONTINUE.
    ENDIF.

    INSERT VALUE lty_name( name_u = lv_name ) INTO TABLE lt_called.

  ENDLOOP.

  " Emit unused subroutine warnings only
  LOOP AT lt_forms INTO DATA(ls_form).

    READ TABLE lt_called
      WITH TABLE KEY name_u = ls_form-name_u TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    MESSAGE w025(z_gsp04_message) WITH ls_form-name INTO lv_text.

    APPEND VALUE zst_error(
      line     = ls_form-row
      msg      = lv_text
      sev      = gc_severity-warning
      category = gc_category-clean_code
      rule     = gc_rule_cc-unused_subroutine
    ) TO rt_errors.
  ENDLOOP.

ENDMETHOD.


METHOD analyze_hardcode.

  CLEAR rt_errors.

  DATA: lt_tokens     TYPE gty_t_tok_tab,
        lt_statements TYPE gty_t_stmt_tab,
        ls_token      TYPE stokex,
        ls_error      TYPE zst_error.

  DATA: lv_msg            TYPE string,
        lv_tok            TYPE string,
        lv_inner          TYPE string,
        lv_line           TYPE string,
        lv_line_uc        TYPE string,
        lv_line_cd        TYPE string,
        lv_inside         TYPE string,
        lv_len            TYPE i,
        lv_sub_len        TYPE i,
        lv_pos_quote      TYPE i,
        lv_token_idx      TYPE sy-tabix,
        lv_token_count    TYPE i,
        lv_has_alpha      TYPE abap_bool,
        lv_has_space      TYPE abap_bool,
        lv_is_suspect     TYPE abap_bool,
        lv_inside_nogaps  TYPE string,
        lv_inner_cd       TYPE string,
        lv_inner_uc       TYPE string,
        lv_inner_lc       TYPE string,
        lv_first_word     TYPE string,
        lv_prev1          TYPE string,
        lv_prev2          TYPE string,
        lv_hit_text       TYPE string.

  DATA: ls_prev1 TYPE stokex,
        ls_prev2 TYPE stokex.

  DATA: lv_collect_row          TYPE i,
        lv_collect_hits         TYPE string,
        lv_collect_has_template TYPE abap_bool,
        lv_has_collect          TYPE abap_bool.

  SCAN ABAP-SOURCE it_source
       TOKENS     INTO lt_tokens
       STATEMENTS INTO lt_statements
       WITH ANALYSIS.

  LOOP AT lt_statements INTO DATA(ls_stmt).

    READ TABLE lt_tokens INTO DATA(ls_first_tok) INDEX ls_stmt-from.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_first_word = ls_first_tok-str.
    TRANSLATE lv_first_word TO UPPER CASE.

    " Do not report literals that are already centralized as constants/statics
    IF lv_first_word = gc_keyword-constants
       OR lv_first_word = gc_keyword-statics.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Special rule for MESSAGE
    " Parse raw source line directly instead of token table
    "------------------------------------------------------------
    IF lv_first_word = gc_keyword-message.

      DATA: lv_stmt_line       TYPE string,
            lv_msg_hits        TYPE string,
            lv_msg_hit         TYPE string,
            lv_msg_hit_inner   TYPE string,
            lv_msg_row         TYPE i,
            lv_comment_pos     TYPE i,
            lv_pos             TYPE i,
            lv_stmt_len        TYPE i,
            lv_start           TYPE i,
            lv_piece_len       TYPE i,
            lv_ch              TYPE c LENGTH 1,
            lv_quote           TYPE c LENGTH 1,
            lv_msg_hit_len     TYPE i,
            lv_msg_hit_sub_len TYPE i.

      CLEAR: lv_stmt_line,
             lv_msg_hits,
             lv_msg_hit,
             lv_msg_hit_inner,
             lv_msg_row,
             lv_comment_pos,
             lv_pos,
             lv_stmt_len,
             lv_start,
             lv_piece_len,
             lv_ch,
             lv_quote,
             lv_msg_hit_len,
             lv_msg_hit_sub_len.

      " Read the source line of the MESSAGE statement
      READ TABLE it_source INDEX ls_first_tok-row INTO lv_stmt_line.
      IF sy-subrc <> 0 OR lv_stmt_line IS INITIAL.
        CONTINUE.
      ENDIF.

      lv_msg_row = ls_first_tok-row.

      " Remove trailing comment after "
      FIND FIRST OCCURRENCE OF gc_keyword-quote
        IN lv_stmt_line
        MATCH OFFSET lv_comment_pos.

      IF sy-subrc = 0.
        lv_stmt_line = lv_stmt_line(lv_comment_pos).
      ENDIF.

      lv_stmt_len = strlen( lv_stmt_line ).
      lv_pos = 0.

      WHILE lv_pos < lv_stmt_len.

        lv_ch = lv_stmt_line+lv_pos(1).

        " Start of literal: '...', `...`, |...|
        IF lv_ch = gc_keyword-empty_single_sq
           OR lv_ch = gc_keyword-empty_single_bt
           OR lv_ch = gc_keyword-empty_single_pipe.

          lv_quote = lv_ch.
          lv_start = lv_pos.
          lv_pos   = lv_pos + 1.

          WHILE lv_pos < lv_stmt_len.

            lv_ch = lv_stmt_line+lv_pos(1).

            IF lv_ch = lv_quote.

              lv_piece_len = lv_pos - lv_start + 1.
              lv_msg_hit   = lv_stmt_line+lv_start(lv_piece_len).

              " Get inner content for filtering technical message type literals
              lv_msg_hit_inner = lv_msg_hit.
              lv_msg_hit_len   = strlen( lv_msg_hit ).

              IF lv_msg_hit_len > 2.
                lv_msg_hit_sub_len = lv_msg_hit_len - 2.
                lv_msg_hit_inner   = lv_msg_hit+1(lv_msg_hit_sub_len).
              ENDIF.

              CONDENSE lv_msg_hit_inner.

              " Skip empty literals and technical message type literals:
              " MESSAGE 'Text' TYPE 'I' -> report only 'Text', not 'I'
              IF lv_msg_hit_inner IS INITIAL.
                EXIT.
              ENDIF.

              CASE lv_msg_hit_inner.
                WHEN gc_tech_e
                  OR gc_tech_w
                  OR gc_tech_i
                  OR gc_tech_s
                  OR gc_tech_a
                  OR gc_tech_x.
                  EXIT.
              ENDCASE.

              " Build final display text immediately
              IF lv_msg_hits IS INITIAL.
                lv_msg_hits = lv_msg_hit.
              ELSE.
                CONCATENATE lv_msg_hits lv_msg_hit
                  INTO lv_msg_hits
                  SEPARATED BY ', '.
              ENDIF.

              EXIT.

            ENDIF.

            lv_pos = lv_pos + 1.

          ENDWHILE.

        ENDIF.

        lv_pos = lv_pos + 1.

      ENDWHILE.

      IF lv_msg_hits IS NOT INITIAL.

        CLEAR: ls_error, lv_msg.

        ls_error-line     = lv_msg_row.
        ls_error-sev      = gc_severity-warning.
        ls_error-rule     = gc_category-hardcode.
        ls_error-category = gc_category-hardcode.

        MESSAGE w017(z_gsp04_message) WITH lv_msg_hits INTO lv_msg.
        ls_error-msg = lv_msg.

        APPEND ls_error TO rt_errors.

      ENDIF.

      CONTINUE.

    ENDIF.

    "------------------------------------------------------------
    " Normal literal checking
    " Avoid nested LOOP AT lt_tokens by using DO + READ TABLE INDEX
    "------------------------------------------------------------
    lv_token_count = ls_stmt-to - ls_stmt-from + 1.

    IF lv_token_count <= 0.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Reset streaming collector for each statement.
    "------------------------------------------------------------
    CLEAR: lv_collect_row,
           lv_collect_hits,
           lv_collect_has_template,
           lv_has_collect.

    DO lv_token_count TIMES.

      lv_token_idx = ls_stmt-from + sy-index - 1.

      READ TABLE lt_tokens INTO ls_token INDEX lv_token_idx.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      CLEAR: lv_msg,
             lv_tok,
             lv_inner,
             lv_line,
             lv_line_uc,
             lv_line_cd,
             lv_inside,
             lv_len,
             lv_sub_len,
             lv_pos_quote,
             lv_has_alpha,
             lv_has_space,
             lv_is_suspect,
             lv_inside_nogaps,
             lv_inner_cd,
             lv_inner_uc,
             lv_inner_lc,
             lv_prev1,
             lv_prev2,
             ls_prev1,
             ls_prev2,
             lv_hit_text.

      lv_tok = ls_token-str.

      IF lv_tok IS INITIAL.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Step 1: only inspect text literal / backtick / template
      "------------------------------------------------------------
      IF lv_tok NP gc_keyword-pat_sq
         AND lv_tok NP gc_keyword-pat_bt
         AND lv_tok NP gc_keyword-pat_pipe.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Step 2: skip empty literals
      "------------------------------------------------------------
      IF lv_tok = gc_keyword-empty_sq
         OR lv_tok = gc_keyword-empty_bt
         OR lv_tok = gc_keyword-empty_pipe.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Step 3: get original source line
      "------------------------------------------------------------
      READ TABLE it_source INDEX ls_token-row INTO lv_line.
      IF sy-subrc <> 0 OR lv_line IS INITIAL.
        CONTINUE.
      ENDIF.

      lv_line_uc = lv_line.
      TRANSLATE lv_line_uc TO UPPER CASE.

      lv_line_cd = lv_line_uc.
      CONDENSE lv_line_cd.

      IF lv_line_cd IS INITIAL.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Step 4: skip comments
      "------------------------------------------------------------
      IF lv_line_cd+0(1) = gc_keyword-star.
        CONTINUE.
      ENDIF.

      CLEAR lv_pos_quote.

      FIND FIRST OCCURRENCE OF gc_keyword-quote
        IN lv_line
        MATCH OFFSET lv_pos_quote.

      IF sy-subrc = 0.
        IF lv_pos_quote < ( ls_token-col - 1 ).
          CONTINUE.
        ENDIF.
      ENDIF.

      "------------------------------------------------------------
      " Step 5: skip CALL FUNCTION '...'
      " Technical FM name is not hardcoded business text
      "------------------------------------------------------------
      IF lv_line_uc CS gc_keyword-call
         AND lv_line_uc CS gc_keyword-func.

        IF lv_token_idx > 2.

          READ TABLE lt_tokens INTO ls_prev1 INDEX lv_token_idx - 1.
          READ TABLE lt_tokens INTO ls_prev2 INDEX lv_token_idx - 2.

          IF ls_prev1-str IS NOT INITIAL
             AND ls_prev2-str IS NOT INITIAL.

            lv_prev1 = ls_prev1-str.
            lv_prev2 = ls_prev2-str.

            TRANSLATE lv_prev1 TO UPPER CASE.
            TRANSLATE lv_prev2 TO UPPER CASE.

            IF lv_prev1 = gc_keyword-func
               AND lv_prev2 = gc_keyword-call.
              CONTINUE.
            ENDIF.

          ENDIF.

        ENDIF.

      ENDIF.

      "------------------------------------------------------------
      " Step 6: normalize inner content
      "------------------------------------------------------------
      lv_inner = lv_tok.
      lv_len   = strlen( lv_tok ).

      IF lv_tok CP gc_keyword-pat_sq
         OR lv_tok CP gc_keyword-pat_bt.

        IF lv_len > 2.
          lv_sub_len = lv_len - 2.
          lv_inner   = lv_tok+1(lv_sub_len).
        ENDIF.

      ENDIF.

      "------------------------------------------------------------
      " Step 7: special handling for templates |...|
      "------------------------------------------------------------
      IF lv_tok CP gc_keyword-pat_pipe.

        IF lv_len <= 2.
          CONTINUE.
        ENDIF.

        lv_sub_len = lv_len - 2.
        lv_inside  = lv_tok+1(lv_sub_len).

        lv_inside_nogaps = lv_inside.
        CONDENSE lv_inside_nogaps NO-GAPS.

        " Pure placeholder only -> skip
        IF lv_inside_nogaps CS gc_keyword-lbrace
           AND lv_inside_nogaps CS gc_keyword-rbrace
           AND lv_inside_nogaps CP gc_keyword-spec_star.
          CONTINUE.
        ENDIF.

        lv_inner = lv_inside.

      ENDIF.

      lv_inner_cd = lv_inner.
      CONDENSE lv_inner_cd.

      IF lv_inner_cd IS INITIAL.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Step 8: skip common technical literals
      "------------------------------------------------------------
      CASE lv_inner_cd.
        WHEN gc_tech_e
          OR gc_tech_w
          OR gc_tech_i
          OR gc_tech_s
          OR gc_tech_a
          OR gc_tech_x
          OR gc_tech_eq
          OR gc_tech_ne
          OR gc_tech_bt
          OR gc_tech_cp
          OR gc_tech_ge
          OR gc_tech_le
          OR gc_tech_gt
          OR gc_tech_lt.
          CONTINUE.
      ENDCASE.

      IF lv_inner = space
         OR lv_inner = gc_keyword-lit_space.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Step 9: skip pure numeric literals
      "------------------------------------------------------------
      IF lv_inner_cd CO gc_digits.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Step 10: skip short technical separators
      "------------------------------------------------------------
      IF strlen( lv_inner_cd ) = 1.

        CASE lv_inner_cd.
          WHEN gc_keyword-dash
            OR gc_keyword-slash
            OR gc_keyword-colon
            OR gc_keyword-comma
            OR gc_keyword-dot
            OR gc_keyword-underscore
            OR gc_keyword-semicolon
            OR gc_keyword-lparen
            OR gc_keyword-rparen.
            CONTINUE.
        ENDCASE.

      ENDIF.

      "------------------------------------------------------------
      " Step 11: suspicion heuristics
      "------------------------------------------------------------
      IF lv_inner CS space.
        lv_has_space = abap_true.
      ENDIF.

      lv_inner_uc = lv_inner.
      lv_inner_lc = lv_inner.

      TRANSLATE lv_inner_uc TO UPPER CASE.
      TRANSLATE lv_inner_lc TO LOWER CASE.

      IF lv_inner_uc <> lv_inner_lc.
        lv_has_alpha = abap_true.
      ENDIF.

      IF lv_has_space = abap_true
         OR lv_has_alpha = abap_true
         OR strlen( lv_inner_cd ) > 2.
        lv_is_suspect = abap_true.
      ENDIF.

      IF lv_is_suspect = abap_false.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Step 12: collect warning hit by source line
      "------------------------------------------------------------
      lv_hit_text = lv_tok.

      IF lv_has_collect = abap_false.

        lv_collect_row  = ls_token-row.
        lv_collect_hits = lv_hit_text.

        IF lv_tok CP gc_keyword-pat_pipe.
          lv_collect_has_template = abap_true.
        ELSE.
          lv_collect_has_template = abap_false.
        ENDIF.

        lv_has_collect = abap_true.

      ELSEIF lv_collect_row = ls_token-row.

        CONCATENATE lv_collect_hits lv_hit_text
          INTO lv_collect_hits
          SEPARATED BY ', '.

        IF lv_tok CP gc_keyword-pat_pipe.
          lv_collect_has_template = abap_true.
        ENDIF.

      ELSE.

        "--------------------------------------------------------
        " Flush previous source line before starting a new one.
        "--------------------------------------------------------
        IF lv_collect_hits IS NOT INITIAL.

          CLEAR: ls_error, lv_msg.

          ls_error-line     = lv_collect_row.
          ls_error-sev      = gc_severity-warning.
          ls_error-rule     = gc_category-hardcode.
          ls_error-category = gc_category-hardcode.

          IF lv_collect_has_template = abap_true.
            MESSAGE w016(z_gsp04_message) WITH lv_collect_hits INTO lv_msg.
          ELSE.
            MESSAGE w015(z_gsp04_message) WITH lv_collect_hits INTO lv_msg.
          ENDIF.

          ls_error-msg = lv_msg.

          APPEND ls_error TO rt_errors.

        ENDIF.

        "--------------------------------------------------------
        " Start collecting the new source line.
        "--------------------------------------------------------
        lv_collect_row  = ls_token-row.
        lv_collect_hits = lv_hit_text.

        IF lv_tok CP gc_keyword-pat_pipe.
          lv_collect_has_template = abap_true.
        ELSE.
          lv_collect_has_template = abap_false.
        ENDIF.

        lv_has_collect = abap_true.

      ENDIF.

    ENDDO.

    "------------------------------------------------------------
    " Flush the last collected source line after all tokens of the
    " current statement have been checked.
    "------------------------------------------------------------
    IF lv_has_collect = abap_true
       AND lv_collect_hits IS NOT INITIAL.

      CLEAR: ls_error, lv_msg.

      ls_error-line     = lv_collect_row.
      ls_error-sev      = gc_severity-warning.
      ls_error-rule     = gc_category-hardcode.
      ls_error-category = gc_category-hardcode.

      IF lv_collect_has_template = abap_true.
        MESSAGE w016(z_gsp04_message) WITH lv_collect_hits INTO lv_msg.
      ELSE.
        MESSAGE w015(z_gsp04_message) WITH lv_collect_hits INTO lv_msg.
      ENDIF.

      ls_error-msg = lv_msg.

      APPEND ls_error TO rt_errors.

    ENDIF.

  ENDLOOP.

ENDMETHOD.


METHOD analyze_naming.
  CLEAR: rt_errors.

  TYPES: BEGIN OF lty_err_seen,
           rule         TYPE string,
           sev          TYPE string,
           category     TYPE string,
           include_name TYPE progname,
           line         TYPE i,
           msg          TYPE string,
         END OF lty_err_seen.
  TYPES lty_t_err_seen TYPE HASHED TABLE OF lty_err_seen
    WITH UNIQUE KEY rule sev category include_name line msg.

  TYPES: BEGIN OF lty_scope_rule,
           keyword TYPE string,
           action  TYPE c LENGTH 1,
         END OF lty_scope_rule.
  TYPES lty_t_scope_rule TYPE SORTED TABLE OF lty_scope_rule
    WITH UNIQUE KEY keyword.

  TYPES: BEGIN OF lty_nm_scope_state,
           depth           TYPE i,
           in_event_local  TYPE abap_bool,
           current_routine TYPE string,
         END OF lty_nm_scope_state.

  CONSTANTS:
    lc_action_begin        TYPE c LENGTH 1 VALUE 'B',
    lc_action_end          TYPE c LENGTH 1 VALUE 'E',
    lc_action_global_event TYPE c LENGTH 1 VALUE 'G'.

  DATA lt_tokens       TYPE gty_t_tok_tab.
  DATA lt_stmts        TYPE gty_t_stmt_tab.
  DATA lt_scan_source  TYPE string_table.
  DATA lt_global_decl  TYPE gty_t_global_decl.
  DATA lt_use          TYPE gty_t_use.
  DATA lt_pending      TYPE gty_t_pending.
  DATA lt_stmt_info    TYPE gty_t_stmt_info.
  DATA lt_errors_final TYPE STANDARD TABLE OF zst_error WITH EMPTY KEY.
  DATA lt_err_seen     TYPE lty_t_err_seen.

  DATA lt_scope_rule TYPE lty_t_scope_rule.
  DATA ls_state      TYPE lty_nm_scope_state.

  "------------------------------------------------------------
  " Build method return-kind support
  "------------------------------------------------------------
  DATA lt_sig_tokens      TYPE gty_t_tok_tab.
  DATA lt_sig_stmts       TYPE gty_t_stmt_tab.
  DATA lt_type_cache      TYPE gty_t_name_kind.
  DATA lt_method_ret_kind TYPE gty_t_nm_method_ret.

  "------------------------------------------------------------
  " SCAN
  "------------------------------------------------------------
  CLEAR: lt_tokens,
         lt_stmts,
         lt_scan_source.

  " Current source phải đứng đầu để line report không bị lệch
  APPEND LINES OF it_source
    TO lt_scan_source.

  IF it_class_sig_source IS NOT INITIAL.
    APPEND LINES OF it_class_sig_source
      TO lt_scan_source.
  ENDIF.

  REPLACE ALL OCCURRENCES OF gc_keyword-static_call
    IN TABLE lt_scan_source WITH | { gc_keyword-static_call } |.

  REPLACE ALL OCCURRENCES OF gc_keyword-instance_call
    IN TABLE lt_scan_source WITH | { gc_keyword-instance_call } |.

  REPLACE ALL OCCURRENCES OF gc_keyword-field_symbol_lparen
    IN TABLE lt_scan_source WITH gc_keyword-field_symbol_lparen2.

  SCAN ABAP-SOURCE lt_scan_source
    TOKENS     INTO lt_tokens
    STATEMENTS INTO lt_stmts
    WITH ANALYSIS.

  "------------------------------------------------------------
  " Build method return-kind
  "------------------------------------------------------------
  CLEAR: lt_sig_tokens,
         lt_sig_stmts,
         lt_type_cache,
         lt_method_ret_kind.

  IF it_class_sig_source IS NOT INITIAL.

    SCAN ABAP-SOURCE it_class_sig_source
      TOKENS     INTO lt_sig_tokens
      STATEMENTS INTO lt_sig_stmts
      WITH ANALYSIS.

    me->nm_build_method_ret_kind(
      EXPORTING
        it_tokens           = lt_sig_tokens
      CHANGING
        ct_type_cache       = lt_type_cache
        ct_method_ret_cache = lt_method_ret_kind ).

  ENDIF.

  "------------------------------------------------------------
  " Build statement info
  "------------------------------------------------------------
  CLEAR lt_stmt_info.

  lt_scope_rule = VALUE #(
    ( keyword = gc_keyword-form               action = lc_action_begin )
    ( keyword = gc_keyword-method             action = lc_action_begin )
    ( keyword = gc_keyword-func               action = lc_action_begin )
    ( keyword = gc_keyword-module             action = lc_action_begin )

    ( keyword = gc_keyword-endform            action = lc_action_end )
    ( keyword = gc_keyword-endmethod          action = lc_action_end )
    ( keyword = gc_keyword-endfunc            action = lc_action_end )
    ( keyword = gc_keyword-endmodule          action = lc_action_end )

    ( keyword = gc_keyword-initialization     action = lc_action_global_event )
    ( keyword = gc_keyword-start_of_selection action = lc_action_global_event )
    ( keyword = gc_keyword-end_of_selection   action = lc_action_global_event )
    ( keyword = gc_keyword-top_of_page        action = lc_action_global_event )
    ( keyword = gc_keyword-end_of_page        action = lc_action_global_event ) ).

  ls_state = VALUE #(
    depth           = 0
    in_event_local  = abap_false
    current_routine = gc_scope-global ).

  LOOP AT lt_stmts ASSIGNING FIELD-SYMBOL(<lfs_stmt>).

    IF <lfs_stmt>-from > <lfs_stmt>-to.
      CONTINUE.
    ENDIF.

    READ TABLE lt_tokens
      REFERENCE INTO DATA(lr_first)
      INDEX <lfs_stmt>-from.

    IF sy-subrc <> 0 OR lr_first IS NOT BOUND.
      CONTINUE.
    ENDIF.

    DATA(lv_first_u) = to_upper( lr_first->str ).

    READ TABLE lt_scope_rule
      WITH TABLE KEY keyword = lv_first_u
      INTO DATA(ls_scope_rule).

    IF sy-subrc = 0.

      CASE ls_scope_rule-action.

        WHEN lc_action_begin.

          ls_state-depth += 1.
          ls_state-in_event_local = abap_false.

          READ TABLE lt_tokens
            REFERENCE INTO DATA(lr_routine_name)
            INDEX ( <lfs_stmt>-from + 1 ).

          IF sy-subrc = 0 AND lr_routine_name IS BOUND.
            ls_state-current_routine = to_upper( lr_routine_name->str ).
          ELSE.
            ls_state-current_routine = gc_scope-block.
          ENDIF.

        WHEN lc_action_end.

          IF ls_state-depth > 0.
            ls_state-depth -= 1.
          ENDIF.

          ls_state-in_event_local = abap_false.

          IF ls_state-depth = 0.
            ls_state-current_routine = gc_scope-global.
          ENDIF.

        WHEN lc_action_global_event.

          ls_state-in_event_local  = abap_false.
          ls_state-current_routine = lv_first_u.

      ENDCASE.

    ELSEIF lv_first_u = gc_keyword-at.

      DATA(lv_at_next_u)  = ``.
      DATA(lv_at_third_u) = ``.

      READ TABLE lt_tokens
        REFERENCE INTO DATA(lr_at_next)
        INDEX ( <lfs_stmt>-from + 1 ).

      IF sy-subrc = 0 AND lr_at_next IS BOUND.
        lv_at_next_u = to_upper( lr_at_next->str ).
      ENDIF.

      READ TABLE lt_tokens
        REFERENCE INTO DATA(lr_at_third)
        INDEX ( <lfs_stmt>-from + 2 ).

      IF sy-subrc = 0 AND lr_at_third IS BOUND.
        lv_at_third_u = to_upper( lr_at_third->str ).
      ENDIF.

      CASE lv_at_next_u.

        WHEN gc_keyword-selection_screen.

          ls_state-in_event_local = abap_true.

          ls_state-current_routine = COND string(
            WHEN lv_at_third_u = gc_keyword-output
            THEN gc_keyword-at_sel_screen_out
            WHEN lv_at_third_u = gc_keyword-on
            THEN gc_keyword-at_sel_screen_on
            ELSE gc_keyword-at_selection_screen ).

        WHEN gc_keyword-line_selection.

          ls_state-in_event_local  = abap_false.
          ls_state-current_routine = gc_keyword-at_line_selection.

        WHEN gc_keyword-user_command.

          ls_state-in_event_local  = abap_false.
          ls_state-current_routine = gc_keyword-at_user_command.

        WHEN OTHERS.

          ls_state-in_event_local = abap_false.

          IF lv_at_next_u IS INITIAL.
            ls_state-current_routine = gc_keyword-at.
          ELSE.
            ls_state-current_routine = |{ gc_keyword-at } { lv_at_next_u }|.
          ENDIF.

      ENDCASE.

    ENDIF.

    APPEND VALUE gty_stmt_info(
      from            = <lfs_stmt>-from
      to              = <lfs_stmt>-to
      first_u         = lv_first_u
      is_local_scope  = xsdbool(
                          ls_state-depth > 0
                          OR ls_state-in_event_local = abap_true )
      is_data_stmt    = xsdbool(
                          lv_first_u = gc_keyword-data
                          OR lv_first_u = gc_keyword-data_col
                          OR lv_first_u = gc_keyword-class_data
                          OR lv_first_u = gc_keyword-class_data_col )
      current_routine = ls_state-current_routine
    ) TO lt_stmt_info.

  ENDLOOP.

  "------------------------------------------------------------
  " DATA checks + usage collection
  "------------------------------------------------------------
  nm_data_checks(
    EXPORTING
      it_tokens          = lt_tokens
      it_stmt_info       = lt_stmt_info
      iv_curr_src_lines  = lines( it_source )
      it_method_ret_kind = lt_method_ret_kind
    CHANGING
      ct_global_decl = lt_global_decl
      ct_use         = lt_use
      ct_pending     = lt_pending
      ct_errors      = rt_errors ).

  "------------------------------------------------------------
  " Additional naming checks
  "------------------------------------------------------------
  nm_additional_naming_checks(
    EXPORTING
      it_source         = it_source
      it_tokens         = lt_tokens
      it_stmts          = lt_stmts
      it_stmt_info      = lt_stmt_info
      it_global_decl    = lt_global_decl
      it_use            = lt_use
      it_pending        = lt_pending
      iv_curr_src_lines = lines( it_source )
    CHANGING
      ct_errors = rt_errors ).

  "------------------------------------------------------------
  " Deduplicate errors
  "------------------------------------------------------------
  CLEAR: lt_errors_final,
         lt_err_seen.

  LOOP AT rt_errors ASSIGNING FIELD-SYMBOL(<lfs_err>).

    INSERT VALUE lty_err_seen(
      rule         = <lfs_err>-rule
      sev          = <lfs_err>-sev
      category     = <lfs_err>-category
      include_name = <lfs_err>-include
      line         = <lfs_err>-line
      msg          = <lfs_err>-msg
    ) INTO TABLE lt_err_seen.

    IF sy-subrc = 0.
      APPEND <lfs_err> TO lt_errors_final.
    ENDIF.

  ENDLOOP.

  rt_errors     = lt_errors_final.

ENDMETHOD.


METHOD analyze_obsolete.

  CLEAR rt_errors.

  DATA: lt_tokens     TYPE gty_t_tok_tab,
        lt_statements TYPE gty_t_stmt_tab,
        ls_token      TYPE stokex,
        ls_stmt       TYPE sstmnt.

  DATA: lv_msg           TYPE string,
        lv_stmt_text     TYPE string,
        lv_stmt_text_uc  TYPE string,
        lv_stmt_line     TYPE string,
        lv_stmt_row      TYPE i,
        lv_stmt_trow     TYPE i,
        lv_idx           TYPE i,
        lv_quote_pos     TYPE i,
        lv_next_idx      TYPE i,
        lv_first_tok     TYPE string,
        lv_second_tok    TYPE string,
        lv_third_tok     TYPE string,
        lv_hit_row       TYPE i,
        lv_check_line    TYPE string,
        lv_check_line_uc TYPE string,
        lv_line_quote_pos TYPE i.

  DATA: lv_rx_old_relop     TYPE string,
        lv_rx_occurs        TYPE string,
        lv_rx_move          TYPE string,
        lv_rx_ranges        TYPE string,
        lv_rx_compute       TYPE string,
        lv_rx_extract       TYPE string,
        lv_rx_field_groups  TYPE string,
        lv_rx_leave_plain   TYPE string,
        lv_rx_add           TYPE string,
        lv_rx_subtract      TYPE string,
        lv_rx_multiply      TYPE string,
        lv_rx_divide        TYPE string,
        lv_rx_local         TYPE string,
        lv_rx_supply        TYPE string,
        lv_rx_call_method   TYPE string,
        lv_rx_fs_no_type    TYPE string,
        lv_phrase_type      TYPE string,
        lv_phrase_like      TYPE string,
        lv_phrase_structure TYPE string.

  FIELD-SYMBOLS: <lfs_src>   TYPE string,
                 <lfs_error> TYPE zst_error.

  DEFINE add_obsolete_error.
    APPEND INITIAL LINE TO rt_errors ASSIGNING <lfs_error>.
    <lfs_error>-line     = &1.
    <lfs_error>-sev      = gc_severity-error.
    <lfs_error>-msg      = &2.
    <lfs_error>-rule     = &3.
    <lfs_error>-category = gc_category-obsolete.
  END-OF-DEFINITION.

  DEFINE find_hit_row_pcre.

    &2 = lv_stmt_row.

    DO lv_stmt_trow - lv_stmt_row + 1 TIMES.

      lv_idx = lv_stmt_row + sy-index - 1.

      READ TABLE it_source INDEX lv_idx INTO lv_check_line.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_check_line_uc = lv_check_line.
      TRANSLATE lv_check_line_uc TO UPPER CASE.
      SHIFT lv_check_line_uc LEFT DELETING LEADING space.

      IF lv_check_line_uc IS INITIAL.
        CONTINUE.
      ENDIF.

      IF lv_check_line_uc+0(1) = gc_keyword-star.
        CONTINUE.
      ENDIF.

      CLEAR lv_line_quote_pos.
      FIND FIRST OCCURRENCE OF gc_keyword-quote
        IN lv_check_line_uc
        MATCH OFFSET lv_line_quote_pos.

      IF sy-subrc = 0.
        lv_check_line_uc = lv_check_line_uc(lv_line_quote_pos).
      ENDIF.

      REPLACE ALL OCCURRENCES OF PCRE gc_rx_obsolete-sq_literal
        IN lv_check_line_uc WITH space.

      REPLACE ALL OCCURRENCES OF PCRE gc_rx_obsolete-bt_literal
        IN lv_check_line_uc WITH space.

      CONDENSE lv_check_line_uc.

      IF lv_check_line_uc IS INITIAL.
        CONTINUE.
      ENDIF.

      FIND PCRE &1 IN lv_check_line_uc.
      IF sy-subrc = 0.
        &2 = lv_idx.
        EXIT.
      ENDIF.

    ENDDO.

  END-OF-DEFINITION.

  DEFINE find_hit_row_text.

    &2 = lv_stmt_row.

    DO lv_stmt_trow - lv_stmt_row + 1 TIMES.

      lv_idx = lv_stmt_row + sy-index - 1.

      READ TABLE it_source INDEX lv_idx INTO lv_check_line.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_check_line_uc = lv_check_line.
      TRANSLATE lv_check_line_uc TO UPPER CASE.
      SHIFT lv_check_line_uc LEFT DELETING LEADING space.

      IF lv_check_line_uc IS INITIAL.
        CONTINUE.
      ENDIF.

      IF lv_check_line_uc+0(1) = gc_keyword-star.
        CONTINUE.
      ENDIF.

      CLEAR lv_line_quote_pos.
      FIND FIRST OCCURRENCE OF gc_keyword-quote
        IN lv_check_line_uc
        MATCH OFFSET lv_line_quote_pos.

      IF sy-subrc = 0.
        lv_check_line_uc = lv_check_line_uc(lv_line_quote_pos).
      ENDIF.

      REPLACE ALL OCCURRENCES OF PCRE gc_rx_obsolete-sq_literal
        IN lv_check_line_uc WITH space.

      REPLACE ALL OCCURRENCES OF PCRE gc_rx_obsolete-bt_literal
        IN lv_check_line_uc WITH space.

      CONDENSE lv_check_line_uc.

      IF lv_check_line_uc IS INITIAL.
        CONTINUE.
      ENDIF.

      IF lv_check_line_uc CS &1.
        &2 = lv_idx.
        EXIT.
      ENDIF.

    ENDDO.

  END-OF-DEFINITION.

  "============================================================
  " Scan source once
  "============================================================
  SCAN ABAP-SOURCE it_source
       TOKENS     INTO lt_tokens
       STATEMENTS INTO lt_statements
       WITH ANALYSIS.
  "============================================================
  " Build dynamic regex once before checking statements
  "============================================================

  " Old relational operators: ><, =<, =>
  " Require whitespace around the operator to avoid false positive
  " for static access such as CL_CLASS=>METHOD.
  lv_rx_old_relop =
    |{ gc_rx_obsolete-ws1 }| &&
    |({ gc_old_relop-not_equal_1 }{ gc_rx_obsolete-alt }| &&
    |{ gc_old_relop-less_equal }{ gc_rx_obsolete-alt }| &&
    |{ gc_old_relop-greater_eq })| &&
    |{ gc_rx_obsolete-ws1 }|.

  lv_rx_occurs =
    gc_rx_obsolete-occurs_left_boundary &&
    gc_kw_obsolete-occurs_kw &&
    gc_rx_obsolete-right_boundary.

  lv_rx_move =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-move_kw }| &&
    |({ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-alt }| &&
    |{ gc_rx_obsolete-ws0 }:{ gc_rx_obsolete-ws0 })|.

  lv_rx_ranges =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-ranges_kw }| &&
    |({ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-alt }| &&
    |{ gc_rx_obsolete-ws0 }:{ gc_rx_obsolete-ws0 })|.

  lv_rx_compute =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-compute_kw }| &&
    |({ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-alt }| &&
    |{ gc_rx_obsolete-ws0 }:{ gc_rx_obsolete-ws0 })|.

  lv_rx_extract =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-extract_kw }| &&
    |({ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-alt }| &&
    |{ gc_rx_obsolete-ws0 }:{ gc_rx_obsolete-ws0 })|.

  lv_rx_field_groups =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-field_groups_kw }| &&
    |({ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-alt }| &&
    |{ gc_rx_obsolete-ws0 }:{ gc_rx_obsolete-ws0 })|.

  lv_rx_leave_plain =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-leave_kw }| &&
    |{ gc_rx_obsolete-ws0 }| &&
    |{ gc_rx_obsolete-dot_esc }| &&
    |{ gc_rx_obsolete-ws0 }| &&
    |{ gc_rx_obsolete-stmt_end }|.

  lv_rx_add =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-add_kw }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-anything }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_keyword-to }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-anything }|.

  lv_rx_subtract =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-subtract_kw }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-anything }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_kw_obsolete-from_kw }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-anything }|.

  lv_rx_multiply =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-multiply_kw }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-anything }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_kw_obsolete-by_kw }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-anything }|.

  lv_rx_divide =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-divide_kw }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-anything }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_kw_obsolete-by_kw }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-anything }|.

  lv_rx_local =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-local_kw }| &&
    |({ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-alt }| &&
    |{ gc_rx_obsolete-ws0 }:{ gc_rx_obsolete-ws0 })|.

  lv_rx_supply =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_kw_obsolete-supply_kw }| &&
    |({ gc_rx_obsolete-ws1 }| &&
    |{ gc_rx_obsolete-alt }| &&
    |{ gc_rx_obsolete-ws0 }:{ gc_rx_obsolete-ws0 })|.

  lv_rx_call_method =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_keyword-call }| &&
    |{ gc_rx_obsolete-ws1 }| &&
    |{ gc_keyword-method }| &&
    |{ gc_rx_obsolete-ws1 }|.

  lv_rx_fs_no_type =
    |{ gc_rx_obsolete-stmt_begin }| &&
    |{ gc_keyword-field_symbols }| &&
    |{ gc_rx_obsolete-opt_colon }| &&
    |{ gc_rx_obsolete-ws0 }| &&
    |{ gc_rx_obsolete-fs_name }| &&
    |{ gc_rx_obsolete-fs_more_names }| &&
    |{ gc_rx_obsolete-ws0 }| &&
    |{ gc_rx_obsolete-dot_esc }| &&
    |{ gc_rx_obsolete-ws0 }| &&
    |{ gc_rx_obsolete-stmt_end }|.

  lv_phrase_type      = | { gc_keyword-type } |.
  lv_phrase_like      = | { gc_keyword-like } |.
  lv_phrase_structure = | { gc_keyword-structure } |.

  "============================================================
  " Statement / phrase / context checks
  "============================================================
  LOOP AT lt_statements INTO ls_stmt.

    CLEAR: lv_stmt_text,
           lv_stmt_text_uc,
           lv_msg,
           lv_stmt_row,
           lv_stmt_trow,
           lv_first_tok,
           lv_second_tok,
           lv_third_tok,
           lv_hit_row.

    "----------------------------------------------------------
    " Get first token and start/end row of statement
    "----------------------------------------------------------
    READ TABLE lt_tokens INDEX ls_stmt-from INTO ls_token.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_first_tok = ls_token-str.
    TRANSLATE lv_first_tok TO UPPER CASE.

    lv_stmt_row  = ls_token-row.
    lv_stmt_trow = ls_stmt-trow.

    IF lv_stmt_row IS INITIAL OR lv_stmt_trow IS INITIAL.
      CONTINUE.
    ENDIF.

    IF lv_stmt_trow < lv_stmt_row.
      CONTINUE.
    ENDIF.

    "----------------------------------------------------------
    " Skip constant declaration blocks
    " These blocks often contain syntax patterns as strings.
    " They must not be checked as executable obsolete syntax.
    "----------------------------------------------------------
    IF lv_first_tok = gc_keyword-constants
       OR lv_first_tok = gc_keyword-constants_col
       OR lv_first_tok = gc_keyword-class_constants
       OR lv_first_tok = gc_keyword-class_constants_col.
      CONTINUE.
    ENDIF.

    "----------------------------------------------------------
    " Get second token for CALL METHOD / REFRESH CONTROL checks
    "----------------------------------------------------------
    lv_next_idx = ls_stmt-from + 1.

    READ TABLE lt_tokens INDEX lv_next_idx INTO ls_token.
    IF sy-subrc = 0.
      lv_second_tok = ls_token-str.
      TRANSLATE lv_second_tok TO UPPER CASE.
    ENDIF.

    "----------------------------------------------------------
    " Get third token for CALL METHOD OF
    "----------------------------------------------------------
    lv_next_idx = ls_stmt-from + 2.

    READ TABLE lt_tokens INDEX lv_next_idx INTO ls_token.
    IF sy-subrc = 0.
      lv_third_tok = ls_token-str.
      TRANSLATE lv_third_tok TO UPPER CASE.
    ENDIF.

    "----------------------------------------------------------
    " Join all source lines of current statement
    "----------------------------------------------------------
    DO lv_stmt_trow - lv_stmt_row + 1 TIMES.

      lv_idx = lv_stmt_row + sy-index - 1.

      READ TABLE it_source INDEX lv_idx ASSIGNING <lfs_src>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_stmt_line = <lfs_src>.
      TRANSLATE lv_stmt_line TO UPPER CASE.
      SHIFT lv_stmt_line LEFT DELETING LEADING space.

      IF lv_stmt_line IS INITIAL.
        CONTINUE.
      ENDIF.

      " Full-line comment
      IF lv_stmt_line+0(1) = gc_keyword-star.
        CONTINUE.
      ENDIF.

      " Inline comment
      CLEAR lv_quote_pos.
      FIND FIRST OCCURRENCE OF gc_keyword-quote
        IN lv_stmt_line
        MATCH OFFSET lv_quote_pos.

      IF sy-subrc = 0.
        lv_stmt_line = lv_stmt_line(lv_quote_pos).
      ENDIF.

      CONDENSE lv_stmt_line.

      IF lv_stmt_line IS INITIAL.
        CONTINUE.
      ENDIF.

      IF lv_stmt_text IS INITIAL.
        lv_stmt_text = lv_stmt_line.
      ELSE.
        lv_stmt_text = |{ lv_stmt_text } { lv_stmt_line }|.
      ENDIF.

    ENDDO.

    IF lv_stmt_text IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_stmt_text_uc = lv_stmt_text.

    "----------------------------------------------------------
    " Remove literals before checking rules
    "----------------------------------------------------------
    REPLACE ALL OCCURRENCES OF PCRE gc_rx_obsolete-sq_literal
      IN lv_stmt_text_uc WITH space.

    REPLACE ALL OCCURRENCES OF PCRE gc_rx_obsolete-bt_literal
      IN lv_stmt_text_uc WITH space.

    CONDENSE lv_stmt_text_uc.

    IF lv_stmt_text_uc IS INITIAL.
      CONTINUE.
    ENDIF.

    "----------------------------------------------------------
    " MOVE
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-move_kw.
      FIND PCRE lv_rx_move IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-move_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_move lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-move_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " RANGES
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-ranges_kw.
      FIND PCRE lv_rx_ranges IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-ranges_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_ranges lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-ranges_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " COMPUTE
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-compute_kw.
      FIND PCRE lv_rx_compute IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-compute_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_compute lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-compute_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " EXTRACT
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-extract_kw.
      FIND PCRE lv_rx_extract IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-extract_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_extract lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-extract_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " FIELD-GROUPS
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-field_groups_kw.
      FIND PCRE lv_rx_field_groups IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-field_groups_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_field_groups lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-field_groups_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " OCCURS
    "----------------------------------------------------------
    FIND PCRE lv_rx_occurs IN lv_stmt_text_uc.
    IF sy-subrc = 0.
      MESSAGE e040(z_gsp04_message)
        WITH gc_kw_obsolete-occurs_kw
        INTO lv_msg.

      lv_hit_row = lv_stmt_row.
      find_hit_row_pcre lv_rx_occurs lv_hit_row.

      add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-occurs_rule.
    ENDIF.

    "----------------------------------------------------------
    " WITH HEADER LINE
    "----------------------------------------------------------
    IF lv_stmt_text_uc CS gc_phrase_obsolete-with_header_line.
      MESSAGE e040(z_gsp04_message)
        WITH gc_phrase_obsolete-with_header_line
        INTO lv_msg.

      lv_hit_row = lv_stmt_row.
      find_hit_row_text gc_phrase_obsolete-with_header_line lv_hit_row.

      add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-header_line_rule.
    ENDIF.

    "----------------------------------------------------------
    " ON CHANGE OF
    "----------------------------------------------------------
    IF lv_stmt_text_uc CS gc_phrase_obsolete-on_change_of.
      MESSAGE e040(z_gsp04_message)
        WITH gc_phrase_obsolete-on_change_of
        INTO lv_msg.

      lv_hit_row = lv_stmt_row.
      find_hit_row_text gc_phrase_obsolete-on_change_of lv_hit_row.

      add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-on_change_rule.
    ENDIF.

    "----------------------------------------------------------
    " Old relational operators: ><, =<, =>
    "----------------------------------------------------------
    FIND PCRE lv_rx_old_relop IN lv_stmt_text_uc.
    IF sy-subrc = 0.
      MESSAGE e040(z_gsp04_message)
        WITH gc_msg_obsolete-old_relop
        INTO lv_msg.

      lv_hit_row = lv_stmt_row.
      find_hit_row_pcre lv_rx_old_relop lv_hit_row.

      add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-relop_rule.
    ENDIF.

    "----------------------------------------------------------
    " REFRESH itab
    " Ignore REFRESH CONTROL ...
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-refresh_kw
       AND lv_second_tok <> gc_kw_obsolete-control_kw.

      MESSAGE e040(z_gsp04_message)
        WITH gc_kw_obsolete-refresh_kw
        INTO lv_msg.

      add_obsolete_error lv_stmt_row lv_msg gc_rule_obsolete-refresh_rule.

    ENDIF.

    "----------------------------------------------------------
    " Plain LEAVE.
    " Only catch: LEAVE.
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-leave_kw.
      FIND PCRE lv_rx_leave_plain IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-leave_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_leave_plain lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-leave_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " ADD ... TO ...
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-add_kw.
      FIND PCRE lv_rx_add IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-add_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_add lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-add_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " SUBTRACT ... FROM ...
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-subtract_kw.
      FIND PCRE lv_rx_subtract IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-subtract_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_subtract lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-subtract_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " MULTIPLY ... BY ...
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-multiply_kw.
      FIND PCRE lv_rx_multiply IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-multiply_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_multiply lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-multiply_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " DIVIDE ... BY ...
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-divide_kw.
      FIND PCRE lv_rx_divide IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-divide_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_divide lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-divide_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " LOCAL
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-local_kw.
      FIND PCRE lv_rx_local IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-local_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_local lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-local_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " SUPPLY
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-supply_kw.
      FIND PCRE lv_rx_supply IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_kw_obsolete-supply_kw
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_supply lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-supply_rule.
      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " CALL TRANSACTION
    "----------------------------------------------------------
    IF lv_first_tok = gc_keyword-call
       AND lv_stmt_text_uc CS gc_phrase_obsolete-call_transaction.

      IF lv_stmt_text_uc NS gc_phrase_obsolete-with_authority_check
         AND lv_stmt_text_uc NS gc_phrase_obsolete-without_auth_check.

        MESSAGE e040(z_gsp04_message)
          WITH gc_phrase_obsolete-call_transaction
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_text gc_phrase_obsolete-call_transaction lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-auth_check_rule.

      ENDIF.
    ENDIF.

    "----------------------------------------------------------
    " CALL DIALOG
    "----------------------------------------------------------
    IF lv_first_tok = gc_keyword-call
       AND lv_stmt_text_uc CS gc_phrase_obsolete-call_dialog.

      MESSAGE e040(z_gsp04_message)
        WITH gc_phrase_obsolete-call_dialog
        INTO lv_msg.

      lv_hit_row = lv_stmt_row.
      find_hit_row_text gc_phrase_obsolete-call_dialog lv_hit_row.

      add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-call_dialog_rule.

    ENDIF.

    "----------------------------------------------------------
    " CATCH SYSTEM-EXCEPTIONS
    "----------------------------------------------------------
    IF lv_first_tok = gc_kw_obsolete-catch_kw
       AND lv_stmt_text_uc CS gc_phrase_obsolete-catch_system_exc.

      MESSAGE e040(z_gsp04_message)
        WITH gc_phrase_obsolete-catch_system_exc
        INTO lv_msg.

      lv_hit_row = lv_stmt_row.
      find_hit_row_text gc_phrase_obsolete-catch_system_exc lv_hit_row.

      add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-catch_system_exc_rule.

    ENDIF.

    "----------------------------------------------------------
    " CALL METHOD old form
    " Ignore OLE Automation:
    "   CALL METHOD OF ...
    "----------------------------------------------------------
    IF lv_first_tok = gc_keyword-call
       AND lv_second_tok = gc_keyword-method
       AND lv_third_tok <> gc_keyword-of.

      FIND PCRE lv_rx_call_method IN lv_stmt_text_uc.
      IF sy-subrc = 0.
        MESSAGE e040(z_gsp04_message)
          WITH gc_phrase_obsolete-call_method
          INTO lv_msg.

        lv_hit_row = lv_stmt_row.
        find_hit_row_pcre lv_rx_call_method lv_hit_row.

        add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-call_method_rule.
      ENDIF.

    ENDIF.

    "----------------------------------------------------------
    " FIELD-SYMBOLS obsolete typing
    "----------------------------------------------------------
    IF lv_first_tok = gc_keyword-field_symbols
       OR lv_first_tok = gc_keyword-field_symbols_col
       OR lv_stmt_text_uc CP gc_pat_obsolete-field_symbols_any.

      IF lv_stmt_text_uc NS lv_phrase_type
         AND lv_stmt_text_uc NS lv_phrase_like
         AND lv_stmt_text_uc NS lv_phrase_structure.

        FIND PCRE lv_rx_fs_no_type IN lv_stmt_text_uc.
        IF sy-subrc = 0.
          MESSAGE e040(z_gsp04_message)
            WITH gc_msg_obsolete-field_symbols_typing
            INTO lv_msg.

          lv_hit_row = lv_stmt_row.
          find_hit_row_pcre lv_rx_fs_no_type lv_hit_row.

          add_obsolete_error lv_hit_row lv_msg gc_rule_obsolete-field_symbol_type_rule.
        ENDIF.

      ENDIF.
    ENDIF.

  ENDLOOP.

  "============================================================
  " Final cleanup
  "============================================================
  SORT rt_errors BY line rule msg.
  DELETE ADJACENT DUPLICATES FROM rt_errors COMPARING line rule msg.

ENDMETHOD.


METHOD analyze_performance.

  CLEAR rt_errors.

  "============================================================
  " Local types
  "============================================================
  TYPES: BEGIN OF lty_stmt,
           stmt_idx   TYPE i,
           line       TYPE i,
           first_word TYPE string,
           text       TYPE string,
           tokens     TYPE STANDARD TABLE OF string WITH EMPTY KEY,
         END OF lty_stmt,
         lty_t_stmt TYPE STANDARD TABLE OF lty_stmt WITH EMPTY KEY.

  TYPES: BEGIN OF lty_name_kind,
           name TYPE string,
           kind TYPE string,
         END OF lty_name_kind,
         lty_t_name_kind TYPE HASHED TABLE OF lty_name_kind
           WITH UNIQUE KEY name.

  TYPES: BEGIN OF lty_guard,
           table_name TYPE string,
           scope      TYPE string,
           level      TYPE i,
         END OF lty_guard,
         lty_t_guard TYPE STANDARD TABLE OF lty_guard WITH EMPTY KEY.

  TYPES: BEGIN OF lty_loop_ctx,
           table_name TYPE string,
           line       TYPE i,
         END OF lty_loop_ctx,
         lty_t_loop_ctx TYPE STANDARD TABLE OF lty_loop_ctx WITH EMPTY KEY.

  "============================================================
  " Local constants
  "============================================================
  CONSTANTS:
    lc_scope_global TYPE string VALUE 'GLOBAL',
    lc_scope_block  TYPE string VALUE 'BLOCK',

    lc_kind_standard TYPE string VALUE 'STANDARD',
    lc_kind_sorted   TYPE string VALUE 'SORTED',
    lc_kind_hashed   TYPE string VALUE 'HASHED',
    lc_kind_unknown  TYPE string VALUE 'UNKNOWN',

    lc_kw_data        TYPE string VALUE 'DATA',
    lc_kw_class_data  TYPE string VALUE 'CLASS-DATA',
    lc_kw_statics     TYPE string VALUE 'STATICS',
    lc_kw_types       TYPE string VALUE 'TYPES',
    lc_kw_fs          TYPE string VALUE 'FIELD-SYMBOLS',

    lc_kw_type        TYPE string VALUE 'TYPE',
    lc_kw_like        TYPE string VALUE 'LIKE',
    lc_kw_standard    TYPE string VALUE 'STANDARD',
    lc_kw_sorted      TYPE string VALUE 'SORTED',
    lc_kw_hashed      TYPE string VALUE 'HASHED',
    lc_kw_table       TYPE string VALUE 'TABLE',
    lc_kw_of          TYPE string VALUE 'OF',

    lc_kw_if          TYPE string VALUE 'IF',
    lc_kw_else        TYPE string VALUE 'ELSE',
    lc_kw_elseif      TYPE string VALUE 'ELSEIF',
    lc_kw_endif       TYPE string VALUE 'ENDIF',

    lc_kw_loop        TYPE string VALUE 'LOOP',
    lc_kw_endloop     TYPE string VALUE 'ENDLOOP',
    lc_kw_do          TYPE string VALUE 'DO',
    lc_kw_enddo       TYPE string VALUE 'ENDDO',
    lc_kw_while       TYPE string VALUE 'WHILE',
    lc_kw_endwhile    TYPE string VALUE 'ENDWHILE',
    lc_kw_case        TYPE string VALUE 'CASE',
    lc_kw_endcase     TYPE string VALUE 'ENDCASE',

    lc_kw_check       TYPE string VALUE 'CHECK',
    lc_kw_assert      TYPE string VALUE 'ASSERT',
    lc_kw_is          TYPE string VALUE 'IS',
    lc_kw_not         TYPE string VALUE 'NOT',
    lc_kw_initial     TYPE string VALUE 'INITIAL',

    lc_kw_return      TYPE string VALUE 'RETURN',
    lc_kw_exit        TYPE string VALUE 'EXIT',
    lc_kw_continue    TYPE string VALUE 'CONTINUE',
    lc_kw_raise       TYPE string VALUE 'RAISE',

    lc_kw_clear       TYPE string VALUE 'CLEAR',
    lc_kw_refresh     TYPE string VALUE 'REFRESH',
    lc_kw_free        TYPE string VALUE 'FREE',
    lc_kw_delete      TYPE string VALUE 'DELETE',

    lc_kw_select      TYPE string VALUE 'SELECT',
    lc_kw_sort        TYPE string VALUE 'SORT',
    lc_kw_read        TYPE string VALUE 'READ',

    lc_kw_for         TYPE string VALUE 'FOR',
    lc_kw_all         TYPE string VALUE 'ALL',
    lc_kw_entries     TYPE string VALUE 'ENTRIES',
    lc_kw_in          TYPE string VALUE 'IN',
    lc_kw_into        TYPE string VALUE 'INTO',

    lc_kw_with        TYPE string VALUE 'WITH',
    lc_kw_key         TYPE string VALUE 'KEY',
    lc_kw_binary      TYPE string VALUE 'BINARY',
    lc_kw_search      TYPE string VALUE 'SEARCH',
    lc_kw_using       TYPE string VALUE 'USING',
    lc_kw_where       TYPE string VALUE 'WHERE',
    lc_kw_from        TYPE string VALUE 'FROM',
    lc_kw_to          TYPE string VALUE 'TO',

    lc_sym_colon      TYPE string VALUE ':',
    lc_sym_comma      TYPE string VALUE ',',
    lc_sym_equal      TYPE string VALUE '=',
    lc_sym_star       TYPE string VALUE '*',
    lc_sym_lbracket   TYPE string VALUE '[',
    lc_sym_rbracket   TYPE string VALUE ']'.

  "============================================================
  " Local data
  "============================================================
  DATA:
    lt_scan_tokens TYPE STANDARD TABLE OF stokex,
    lt_scan_stmt   TYPE STANDARD TABLE OF sstmnt,
    lt_stmt        TYPE lty_t_stmt,
    lt_type_meta   TYPE lty_t_name_kind,
    lt_itab_meta   TYPE lty_t_name_kind,
    lt_guard       TYPE lty_t_guard,
    lt_loop_stack  TYPE lty_t_loop_ctx,

    ls_stmt        TYPE lty_stmt,
    ls_error       TYPE zst_error,

    lv_msg         TYPE string,
    lv_rule        TYPE string,

    lv_tok         TYPE string,
    lv_prev        TYPE string,
    lv_next        TYPE string,
    lv_next2       TYPE string,
    lv_next3       TYPE string,
    lv_name        TYPE string,
    lv_kind        TYPE string,
    lv_idx         TYPE i,
    lv_idx2        TYPE i,
    lv_lines       TYPE i,

    lv_block_level TYPE i VALUE 0,

    lv_guard_tab   TYPE string,
    lv_changed_tab TYPE string,
    lv_fae_table   TYPE string,
    lv_read_table  TYPE string,
    lv_loop_table  TYPE string,
    lv_sort_table  TYPE string,

    lv_has_guard   TYPE abap_bool,
    lv_has_reduce  TYPE abap_bool,
    lv_exit_found  TYPE abap_bool,
    lv_else_found  TYPE abap_bool,
    lv_nested_if   TYPE i.

  FIELD-SYMBOLS:
    <ls_scan_stmt> TYPE sstmnt,
    <ls_scan_tok>  TYPE stokex,
    <lv_token>     TYPE string.

  "============================================================
  " Local macro: add performance error
  "============================================================
  DEFINE add_perf_error.
    CLEAR ls_error.
    ls_error-line     = &1.
    ls_error-sev      = &2.
    ls_error-msg      = &3.
    ls_error-rule     = &4.
    ls_error-category = gc_category-performance.
    APPEND ls_error TO rt_errors.
  END-OF-DEFINITION.

  "============================================================
  " Step 1: Scan ABAP source into tokens and statements
  "============================================================
  SCAN ABAP-SOURCE it_source
    TOKENS     INTO lt_scan_tokens
    STATEMENTS INTO lt_scan_stmt
    WITH ANALYSIS.

  LOOP AT lt_scan_stmt ASSIGNING <ls_scan_stmt>.

    CLEAR ls_stmt.
    ls_stmt-stmt_idx = sy-tabix.

    LOOP AT lt_scan_tokens ASSIGNING <ls_scan_tok>
      FROM <ls_scan_stmt>-from
      TO   <ls_scan_stmt>-to.

      lv_tok = <ls_scan_tok>-str.
      TRANSLATE lv_tok TO UPPER CASE.

      " Normalize escaped host variable: @lt_tab -> LT_TAB
      IF lv_tok CP '@*'.
        SHIFT lv_tok LEFT DELETING LEADING '@'.
      ENDIF.

      " Normalize table body notation if token is LT_TAB[]
      REPLACE ALL OCCURRENCES OF '[]' IN lv_tok WITH ''.

      APPEND lv_tok TO ls_stmt-tokens.

      IF ls_stmt-line IS INITIAL
         OR <ls_scan_tok>-row < ls_stmt-line.
        ls_stmt-line = <ls_scan_tok>-row.
      ENDIF.

      IF ls_stmt-text IS INITIAL.
        ls_stmt-text = lv_tok.
      ELSE.
        ls_stmt-text = |{ ls_stmt-text } { lv_tok }|.
      ENDIF.

    ENDLOOP.

    READ TABLE ls_stmt-tokens INDEX 1 INTO ls_stmt-first_word.
    APPEND ls_stmt TO lt_stmt.

  ENDLOOP.

  "============================================================
  " Step 2: Collect local table/type metadata
  " Purpose:
  "   - STANDARD TABLE -> READ TABLE may need BINARY SEARCH
  "   - SORTED/HASHED TABLE -> do not suggest BINARY SEARCH
  "============================================================
  LOOP AT lt_stmt INTO ls_stmt.

    CHECK ls_stmt-first_word = lc_kw_types
       OR ls_stmt-first_word = lc_kw_data
       OR ls_stmt-first_word = lc_kw_class_data
       OR ls_stmt-first_word = lc_kw_statics
       OR ls_stmt-first_word = lc_kw_fs.

    lv_lines = lines( ls_stmt-tokens ).

    DO lv_lines TIMES.

      lv_idx = sy-index.

      CLEAR: lv_tok, lv_prev, lv_next, lv_next2, lv_kind, lv_name.

      READ TABLE ls_stmt-tokens INDEX lv_idx INTO lv_tok.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      CHECK lv_tok = lc_kw_type OR lv_tok = lc_kw_like.

      READ TABLE ls_stmt-tokens INDEX lv_idx - 1 INTO lv_prev.
      READ TABLE ls_stmt-tokens INDEX lv_idx + 1 INTO lv_next.
      READ TABLE ls_stmt-tokens INDEX lv_idx + 2 INTO lv_next2.

      lv_name = lv_prev.

      IF lv_name IS INITIAL
         OR lv_name = lc_sym_colon
         OR lv_name = lc_sym_comma.
        CONTINUE.
      ENDIF.

      REPLACE ALL OCCURRENCES OF '@'  IN lv_name WITH ''.
      REPLACE ALL OCCURRENCES OF '[]' IN lv_name WITH ''.

      CLEAR lv_kind.

      " Direct table declaration
      IF lv_next = lc_kw_standard
         AND lv_next2 = lc_kw_table.

        lv_kind = lc_kind_standard.

      ELSEIF lv_next = lc_kw_sorted
         AND lv_next2 = lc_kw_table.

        lv_kind = lc_kind_sorted.

      ELSEIF lv_next = lc_kw_hashed
         AND lv_next2 = lc_kw_table.

        lv_kind = lc_kind_hashed.

      ELSEIF lv_next = lc_kw_table
         AND lv_next2 = lc_kw_of.

        " TYPE TABLE OF ... means STANDARD TABLE by default
        lv_kind = lc_kind_standard.

      ELSE.

        " Declaration by local table type:
        "   TYPES ty_t_x TYPE STANDARD TABLE OF ...
        "   DATA lt_x TYPE ty_t_x.
        READ TABLE lt_type_meta INTO DATA(ls_type_meta)
          WITH TABLE KEY name = lv_next.

        IF sy-subrc = 0.
          lv_kind = ls_type_meta-kind.
        ENDIF.

      ENDIF.

      IF lv_kind IS INITIAL.
        CONTINUE.
      ENDIF.

      IF ls_stmt-first_word = lc_kw_types.

        DELETE TABLE lt_type_meta WITH TABLE KEY name = lv_name.
        INSERT VALUE #( name = lv_name
                        kind = lv_kind ) INTO TABLE lt_type_meta.

      ELSE.

        DELETE TABLE lt_itab_meta WITH TABLE KEY name = lv_name.
        INSERT VALUE #( name = lv_name
                        kind = lv_kind ) INTO TABLE lt_itab_meta.

      ENDIF.

    ENDDO.

  ENDLOOP.

  "============================================================
  " Step 3: Analyze performance rules by statement context
  "============================================================
  LOOP AT lt_stmt INTO ls_stmt.

    lv_idx = sy-tabix.

    "----------------------------------------------------------
    " 3.1 End of block handling
    "----------------------------------------------------------
    IF ls_stmt-first_word = lc_kw_endif
       OR ls_stmt-first_word = lc_kw_endcase
       OR ls_stmt-first_word = lc_kw_enddo
       OR ls_stmt-first_word = lc_kw_endwhile
       OR ls_stmt-first_word = lc_kw_endloop.

      DELETE lt_guard
        WHERE scope = lc_scope_block
          AND level >= lv_block_level.

      IF ls_stmt-first_word = lc_kw_endloop.

        lv_lines = lines( lt_loop_stack ).

        IF lv_lines > 0.
          DELETE lt_loop_stack INDEX lv_lines.
        ENDIF.

      ENDIF.

      IF lv_block_level > 0.
        lv_block_level = lv_block_level - 1.
      ENDIF.

      CONTINUE.

    ENDIF.

    "----------------------------------------------------------
    " 3.2 ELSE / ELSEIF handling
    " Guard from IF branch must not leak into ELSE branch.
    "----------------------------------------------------------
    IF ls_stmt-first_word = lc_kw_else
       OR ls_stmt-first_word = lc_kw_elseif.

      DELETE lt_guard
        WHERE scope = lc_scope_block
          AND level = lv_block_level.

      " ELSEIF lt_tab IS NOT INITIAL.
      IF ls_stmt-first_word = lc_kw_elseif.

        CLEAR lv_guard_tab.

        lv_lines = lines( ls_stmt-tokens ).

        DO lv_lines TIMES.

          READ TABLE ls_stmt-tokens INDEX sy-index INTO lv_tok.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          IF lv_tok = lc_kw_is.

            READ TABLE ls_stmt-tokens INDEX sy-index - 1 INTO lv_prev.
            READ TABLE ls_stmt-tokens INDEX sy-index + 1 INTO lv_next.
            READ TABLE ls_stmt-tokens INDEX sy-index + 2 INTO lv_next2.

            IF lv_next = lc_kw_not
               AND lv_next2 = lc_kw_initial.

              lv_guard_tab = lv_prev.
              EXIT.

            ENDIF.

          ENDIF.

        ENDDO.

        IF lv_guard_tab IS NOT INITIAL.

          REPLACE ALL OCCURRENCES OF '@'  IN lv_guard_tab WITH ''.
          REPLACE ALL OCCURRENCES OF '[]' IN lv_guard_tab WITH ''.

          APPEND VALUE #( table_name = lv_guard_tab
                          scope      = lc_scope_block
                          level      = lv_block_level ) TO lt_guard.

        ENDIF.

      ENDIF.

      CONTINUE.

    ENDIF.

    "----------------------------------------------------------
    " 3.3 Start block handling
    "----------------------------------------------------------
    IF ls_stmt-first_word = lc_kw_if
       OR ls_stmt-first_word = lc_kw_case
       OR ls_stmt-first_word = lc_kw_do
       OR ls_stmt-first_word = lc_kw_while.

      lv_block_level = lv_block_level + 1.

    ENDIF.

    "----------------------------------------------------------
    " 3.4 IF/CHECK/ASSERT guard detection for FOR ALL ENTRIES
    " Supports:
    "   CHECK lt_tab IS NOT INITIAL.
    "   IF lt_tab IS NOT INITIAL. ... SELECT FAE ... ENDIF.
    "   IF lt_tab IS INITIAL. RETURN/EXIT/CONTINUE/RAISE ... ENDIF.
    "----------------------------------------------------------
    IF ls_stmt-first_word = lc_kw_check
       OR ls_stmt-first_word = lc_kw_assert
       OR ls_stmt-first_word = lc_kw_if.

      CLEAR lv_guard_tab.

      lv_lines = lines( ls_stmt-tokens ).

      DO lv_lines TIMES.

        READ TABLE ls_stmt-tokens INDEX sy-index INTO lv_tok.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        IF lv_tok = lc_kw_is.

          READ TABLE ls_stmt-tokens INDEX sy-index - 1 INTO lv_prev.
          READ TABLE ls_stmt-tokens INDEX sy-index + 1 INTO lv_next.
          READ TABLE ls_stmt-tokens INDEX sy-index + 2 INTO lv_next2.

          " lt_tab IS NOT INITIAL
          IF lv_next = lc_kw_not
             AND lv_next2 = lc_kw_initial.

            lv_guard_tab = lv_prev.
            EXIT.

          ENDIF.

        ENDIF.

      ENDDO.

      IF lv_guard_tab IS NOT INITIAL.

        REPLACE ALL OCCURRENCES OF '@'  IN lv_guard_tab WITH ''.
        REPLACE ALL OCCURRENCES OF '[]' IN lv_guard_tab WITH ''.

        IF ls_stmt-first_word = lc_kw_if.

          " Guard is valid only inside IF branch
          APPEND VALUE #( table_name = lv_guard_tab
                          scope      = lc_scope_block
                          level      = lv_block_level ) TO lt_guard.

        ELSE.

          " CHECK at top-level protects the following code.
          " CHECK inside a block protects the following statements in that block.
          APPEND VALUE #( table_name = lv_guard_tab
                          scope      = COND string(
                                         WHEN lv_block_level > 0
                                         THEN lc_scope_block
                                         ELSE lc_scope_global )
                          level      = lv_block_level ) TO lt_guard.

        ENDIF.

      ENDIF.

    ENDIF.

    "----------------------------------------------------------
    " 3.5 IF lt_tab IS INITIAL. RETURN/EXIT/CONTINUE/RAISE. ENDIF.
    " This means code after the IF is guarded, even if SELECT is not
    " directly wrapped by IF lt_tab IS NOT INITIAL.
    "----------------------------------------------------------
    IF ls_stmt-first_word = lc_kw_if.

      CLEAR: lv_guard_tab,
             lv_exit_found,
             lv_else_found,
             lv_nested_if.

      lv_lines = lines( ls_stmt-tokens ).

      DO lv_lines TIMES.

        READ TABLE ls_stmt-tokens INDEX sy-index INTO lv_tok.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        IF lv_tok = lc_kw_is.

          READ TABLE ls_stmt-tokens INDEX sy-index - 1 INTO lv_prev.
          READ TABLE ls_stmt-tokens INDEX sy-index + 1 INTO lv_next.

          " lt_tab IS INITIAL
          IF lv_next = lc_kw_initial.
            lv_guard_tab = lv_prev.
            EXIT.
          ENDIF.

        ENDIF.

      ENDDO.

      IF lv_guard_tab IS NOT INITIAL.

        REPLACE ALL OCCURRENCES OF '@'  IN lv_guard_tab WITH ''.
        REPLACE ALL OCCURRENCES OF '[]' IN lv_guard_tab WITH ''.

        " Look ahead until matching ENDIF
        lv_idx2 = lv_idx.

        WHILE lv_idx2 < lines( lt_stmt ).

          lv_idx2 = lv_idx2 + 1.

          READ TABLE lt_stmt INTO DATA(ls_ahead) INDEX lv_idx2.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          IF ls_ahead-first_word = lc_kw_if.
            lv_nested_if = lv_nested_if + 1.
            CONTINUE.
          ENDIF.

          IF ls_ahead-first_word = lc_kw_endif.

            IF lv_nested_if > 0.
              lv_nested_if = lv_nested_if - 1.
              CONTINUE.
            ELSE.
              EXIT.
            ENDIF.

          ENDIF.

          CHECK lv_nested_if = 0.

          IF ls_ahead-first_word = lc_kw_else
             OR ls_ahead-first_word = lc_kw_elseif.
            lv_else_found = abap_true.
            EXIT.
          ENDIF.

          IF ls_ahead-first_word = lc_kw_return
             OR ls_ahead-first_word = lc_kw_exit
             OR ls_ahead-first_word = lc_kw_continue
             OR ls_ahead-first_word = lc_kw_raise.

            lv_exit_found = abap_true.

          ENDIF.

        ENDWHILE.

        IF lv_exit_found = abap_true
           AND lv_else_found = abap_false.

          APPEND VALUE #( table_name = lv_guard_tab
                          scope      = COND string(
                                         WHEN lv_block_level > 0
                                         THEN lc_scope_block
                                         ELSE lc_scope_global )
                          level      = lv_block_level ) TO lt_guard.

        ENDIF.

      ENDIF.

    ENDIF.

    "----------------------------------------------------------
    " 3.6 Invalidate FAE guards if table content may be reset
    "----------------------------------------------------------
    CLEAR lv_changed_tab.

    IF ls_stmt-first_word = lc_kw_clear
       OR ls_stmt-first_word = lc_kw_refresh
       OR ls_stmt-first_word = lc_kw_free.

      LOOP AT ls_stmt-tokens INTO lv_changed_tab FROM 2.

        IF lv_changed_tab IS INITIAL
           OR lv_changed_tab = lc_sym_colon
           OR lv_changed_tab = lc_sym_comma.
          CONTINUE.
        ENDIF.

        REPLACE ALL OCCURRENCES OF '@'  IN lv_changed_tab WITH ''.
        REPLACE ALL OCCURRENCES OF '[]' IN lv_changed_tab WITH ''.

        DELETE lt_guard WHERE table_name = lv_changed_tab.

      ENDLOOP.

    ELSEIF ls_stmt-first_word = lc_kw_delete.

      READ TABLE ls_stmt-tokens INDEX 2 INTO lv_changed_tab.

      IF lv_changed_tab = lc_kw_table.
        READ TABLE ls_stmt-tokens INDEX 3 INTO lv_changed_tab.
      ENDIF.

      IF lv_changed_tab IS NOT INITIAL.

        REPLACE ALL OCCURRENCES OF '@'  IN lv_changed_tab WITH ''.
        REPLACE ALL OCCURRENCES OF '[]' IN lv_changed_tab WITH ''.

        DELETE lt_guard WHERE table_name = lv_changed_tab.

      ENDIF.

    ELSE.

      " Assignment: lt_tab = ...
      READ TABLE ls_stmt-tokens INDEX 2 INTO lv_tok.

      IF lv_tok = lc_sym_equal.

        READ TABLE ls_stmt-tokens INDEX 1 INTO lv_changed_tab.

        REPLACE ALL OCCURRENCES OF '@'  IN lv_changed_tab WITH ''.
        REPLACE ALL OCCURRENCES OF '[]' IN lv_changed_tab WITH ''.

        DELETE lt_guard WHERE table_name = lv_changed_tab.

      ENDIF.

      " SELECT ... INTO TABLE lt_tab resets/fills table, result may be empty
      IF ls_stmt-first_word = lc_kw_select.

        lv_lines = lines( ls_stmt-tokens ).

        DO lv_lines TIMES.

          READ TABLE ls_stmt-tokens INDEX sy-index INTO lv_tok.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          IF lv_tok = lc_kw_into.

            READ TABLE ls_stmt-tokens INDEX sy-index + 1 INTO lv_next.
            READ TABLE ls_stmt-tokens INDEX sy-index + 2 INTO lv_next2.

            IF lv_next = lc_kw_table
               AND lv_next2 IS NOT INITIAL.

              lv_changed_tab = lv_next2.

              REPLACE ALL OCCURRENCES OF '@'  IN lv_changed_tab WITH ''.
              REPLACE ALL OCCURRENCES OF '[]' IN lv_changed_tab WITH ''.

              DELETE lt_guard WHERE table_name = lv_changed_tab.

              EXIT.

            ENDIF.

          ENDIF.

        ENDDO.

      ENDIF.

    ENDIF.

    "----------------------------------------------------------
    " 3.7 LOOP AT handling + nested loop detection
    " A nested loop means:
    "   current LOOP AT starts while another LOOP AT has not ended yet.
    "----------------------------------------------------------
    IF ls_stmt-first_word = lc_kw_loop
       AND ls_stmt-text CS 'LOOP AT'.

      CLEAR: lv_loop_table,
             lv_has_reduce.

      READ TABLE ls_stmt-tokens INDEX 3 INTO lv_loop_table.

      IF lv_loop_table IS INITIAL.
        lv_loop_table = gc_obj_type-unknown.
      ENDIF.

      REPLACE ALL OCCURRENCES OF '@'  IN lv_loop_table WITH ''.
      REPLACE ALL OCCURRENCES OF '[]' IN lv_loop_table WITH ''.

      IF ls_stmt-text CS lc_kw_where
         OR ls_stmt-text CS lc_kw_from
         OR ls_stmt-text CS lc_kw_to
         OR ls_stmt-text CS 'USING KEY'.

        lv_has_reduce = abap_true.

      ENDIF.

      IF lines( lt_loop_stack ) > 0.

        lv_rule = gc_rule_perf-nested_loop.

        IF lv_has_reduce = abap_true.

          MESSAGE w078(z_gsp04_message)
            WITH lv_loop_table
            INTO lv_msg.

          add_perf_error ls_stmt-line gc_severity-warning lv_msg lv_rule.

        ELSE.

          MESSAGE e037(z_gsp04_message)
            WITH lv_loop_table
            INTO lv_msg.

          add_perf_error ls_stmt-line gc_severity-error lv_msg lv_rule.

        ENDIF.

      ENDIF.

      APPEND VALUE #( table_name = lv_loop_table
                      line       = ls_stmt-line ) TO lt_loop_stack.

      lv_block_level = lv_block_level + 1.

      CONTINUE.

    ENDIF.

    "----------------------------------------------------------
    " 3.8 SELECT * detection
    " Exclude COUNT(*), because it is not fetching all columns.
    "----------------------------------------------------------
    IF ls_stmt-first_word = lc_kw_select
       AND ls_stmt-text CS lc_sym_star
       AND ls_stmt-text NS 'COUNT ( * )'
       AND ls_stmt-text NS 'COUNT(*)'.

      lv_rule = gc_rule_perf-select_star.

      MESSAGE e036(z_gsp04_message)
        INTO lv_msg.

      add_perf_error ls_stmt-line gc_severity-error lv_msg lv_rule.

    ENDIF.

    "----------------------------------------------------------
    " 3.9 FOR ALL ENTRIES guard check
    " Does not require IF to directly wrap SELECT.
    " It only requires that the FAE table was already proven non-empty
    " and not reset before this SELECT.
    "----------------------------------------------------------
    CLEAR lv_fae_table.

    lv_lines = lines( ls_stmt-tokens ).

    DO lv_lines TIMES.

      READ TABLE ls_stmt-tokens INDEX sy-index INTO lv_tok.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF lv_tok = lc_kw_for.

        READ TABLE ls_stmt-tokens INDEX sy-index + 1 INTO lv_next.
        READ TABLE ls_stmt-tokens INDEX sy-index + 2 INTO lv_next2.
        READ TABLE ls_stmt-tokens INDEX sy-index + 3 INTO lv_next3.

        IF lv_next  = lc_kw_all
           AND lv_next2 = lc_kw_entries
           AND lv_next3 = lc_kw_in.

          READ TABLE ls_stmt-tokens INDEX sy-index + 4 INTO lv_fae_table.
          EXIT.

        ENDIF.

      ENDIF.

    ENDDO.

    IF lv_fae_table IS NOT INITIAL.

      REPLACE ALL OCCURRENCES OF '@'  IN lv_fae_table WITH ''.
      REPLACE ALL OCCURRENCES OF '[]' IN lv_fae_table WITH ''.

      lv_has_guard = abap_false.

      READ TABLE lt_guard TRANSPORTING NO FIELDS
        WITH KEY table_name = lv_fae_table.

      IF sy-subrc = 0.
        lv_has_guard = abap_true.
      ENDIF.

      IF lv_has_guard = abap_false.

        lv_rule = gc_rule_perf-fae_empty_check.

        MESSAGE e043(z_gsp04_message)
          WITH lv_fae_table
          INTO lv_msg.

        add_perf_error ls_stmt-line gc_severity-error lv_msg lv_rule.

      ENDIF.

    ENDIF.

    "----------------------------------------------------------
    " 3.10 SELECT inside LOOP
    "----------------------------------------------------------
    IF lines( lt_loop_stack ) > 0
       AND ls_stmt-first_word = lc_kw_select.

      lv_rule = gc_rule_perf-select_in_loop.

      MESSAGE e038(z_gsp04_message)
        INTO lv_msg.

      add_perf_error ls_stmt-line gc_severity-error lv_msg lv_rule.

    ENDIF.

    "----------------------------------------------------------
    " 3.11 SORT inside LOOP
    "----------------------------------------------------------
    IF lines( lt_loop_stack ) > 0
       AND ls_stmt-first_word = lc_kw_sort.

      CLEAR lv_sort_table.
      READ TABLE ls_stmt-tokens INDEX 2 INTO lv_sort_table.

      IF lv_sort_table IS INITIAL.
        lv_sort_table = gc_obj_type-unknown.
      ENDIF.

      REPLACE ALL OCCURRENCES OF '@'  IN lv_sort_table WITH ''.
      REPLACE ALL OCCURRENCES OF '[]' IN lv_sort_table WITH ''.

      lv_rule = gc_rule_perf-sort_in_loop.

      MESSAGE e084(z_gsp04_message)
        WITH lv_sort_table
        INTO lv_msg.

      add_perf_error ls_stmt-line gc_severity-error lv_msg lv_rule.

    ENDIF.

    "----------------------------------------------------------
    " 3.12 READ TABLE ... WITH KEY without BINARY SEARCH
    " Important:
    "   Only report for STANDARD TABLE.
    "   Do not report for SORTED/HASHED TABLE.
    "----------------------------------------------------------
    IF ls_stmt-first_word = lc_kw_read
       AND ls_stmt-text CS 'READ TABLE'
       AND ls_stmt-text CS 'WITH KEY'
       AND ls_stmt-text NS 'BINARY SEARCH'
       AND ls_stmt-text NS 'WITH TABLE KEY'
       AND ls_stmt-text NS 'USING KEY'.

      CLEAR: lv_read_table,
             lv_kind.

      " READ TABLE <itab> ...
      READ TABLE ls_stmt-tokens INDEX 3 INTO lv_read_table.

      IF lv_read_table IS NOT INITIAL.

        REPLACE ALL OCCURRENCES OF '@'  IN lv_read_table WITH ''.
        REPLACE ALL OCCURRENCES OF '[]' IN lv_read_table WITH ''.

        READ TABLE lt_itab_meta INTO DATA(ls_itab_meta)
          WITH TABLE KEY name = lv_read_table.

        IF sy-subrc = 0.
          lv_kind = ls_itab_meta-kind.
        ELSE.
          lv_kind = lc_kind_unknown.
        ENDIF.

        CASE lv_kind.

          WHEN lc_kind_standard.

            lv_rule = gc_rule_perf-read_no_binary.

            MESSAGE e039(z_gsp04_message)
              INTO lv_msg.

            add_perf_error ls_stmt-line gc_severity-error lv_msg lv_rule.

          WHEN lc_kind_sorted OR lc_kind_hashed.

            " Do not report.
            " SORTED and HASHED tables already have optimized key access.

          WHEN OTHERS.

            " Unknown table kind:
            " Do not report as error to avoid false positive.
            CONTINUE.

        ENDCASE.

      ENDIF.

    ENDIF.

  ENDLOOP.

  SORT rt_errors BY line rule msg.
  DELETE ADJACENT DUPLICATES FROM rt_errors COMPARING line rule msg.

ENDMETHOD.


METHOD cc_add_usage_count.
  FIELD-SYMBOLS <lfs_cnt> TYPE gty_cnt.

  IF iv_name IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE ct_cnt ASSIGNING <lfs_cnt> WITH TABLE KEY name = iv_name.
  IF sy-subrc = 0.
    <lfs_cnt>-cnt += 1.
  ELSE.
    INSERT VALUE gty_cnt(
      name = iv_name
      cnt  = 1
    ) INTO TABLE ct_cnt.
  ENDIF.
ENDMETHOD.


METHOD cc_preprocess_source.
  DATA ls_src  TYPE gty_src_line.
  DATA lv_line TYPE string.
  DATA lv_trim TYPE string.
  DATA lv_off  TYPE i.
  DATA lv_i    TYPE i.

  CLEAR rt_src.
  lv_i = 0.

  LOOP AT it_source INTO lv_line.
    lv_i += 1.
    CLEAR ls_src.

    ls_src-row = lv_i.

    lv_trim = lv_line.
    SHIFT lv_trim LEFT  DELETING LEADING  space.
    SHIFT lv_trim RIGHT DELETING TRAILING space.

    IF lv_trim IS INITIAL.
      ls_src-is_blank = abap_true.
    ENDIF.

    IF lv_line IS NOT INITIAL
       AND lv_line+0(1) = gc_keyword-star.
      ls_src-is_star = abap_true.
    ENDIF.

    IF lv_trim IS NOT INITIAL
       AND lv_trim(1) = gc_keyword-quote.
      ls_src-is_quote = abap_true.
    ENDIF.

    IF ls_src-is_star = abap_true OR ls_src-is_quote = abap_true.
      CLEAR ls_src-no_comment.
    ELSE.
      ls_src-no_comment = lv_line.
      CLEAR lv_off.

      FIND FIRST OCCURRENCE OF gc_keyword-quote
        IN ls_src-no_comment
        MATCH OFFSET lv_off.

      IF sy-subrc = 0.
        ls_src-no_comment = ls_src-no_comment(lv_off).
      ENDIF.

      SHIFT ls_src-no_comment LEFT  DELETING LEADING  space.
      SHIFT ls_src-no_comment RIGHT DELETING TRAILING space.
    ENDIF.

    ls_src-upper = ls_src-no_comment.
    TRANSLATE ls_src-upper TO UPPER CASE.

    APPEND ls_src TO rt_src.
  ENDLOOP.
ENDMETHOD.


  METHOD get_object_author.

    DATA: lv_author TYPE syuname.

    CLEAR rv_author.

    CASE iv_obj_type.

        " Program / Include
      WHEN gc_obj_type-prog OR gc_obj_type-reps OR gc_obj_type-incl.
        SELECT SINGLE unam
          INTO lv_author
          FROM trdir
          WHERE name = iv_obj_name.

        " Class
      WHEN gc_obj_type-clas.
        SELECT SINGLE author
          INTO lv_author
          FROM tadir
          WHERE pgmid    = gc_obj_type-r3tr
            AND object   = gc_obj_type-clas
            AND obj_name = iv_obj_name.

        " Function Group
      WHEN gc_obj_type-fugr.
        SELECT SINGLE author
          INTO lv_author
          FROM tadir
          WHERE pgmid    = gc_obj_type-r3tr
            AND object   = gc_obj_type-fugr
            AND obj_name = iv_obj_name.

        " Function Module
      WHEN gc_obj_type-func OR gc_obj_type-fm.

        DATA: lv_pname TYPE tfdir-pname,
              lv_fugr  TYPE rs38l-area.

        CLEAR: lv_pname, lv_fugr.

        SELECT SINGLE pname
          INTO lv_pname
          FROM tfdir
          WHERE funcname = iv_obj_name.

        IF sy-subrc = 0 AND lv_pname IS NOT INITIAL.

          " Remove SAPL prefix
          lv_fugr = lv_pname+4.

          SELECT SINGLE author
            INTO lv_author
            FROM tadir
            WHERE pgmid    = gc_obj_type-r3tr
              AND object   = gc_obj_type-fugr
              AND obj_name = lv_fugr.

        ENDIF.

      WHEN OTHERS.

    ENDCASE.

    IF lv_author IS INITIAL.
      rv_author = gc_obj_type-unknown.
    ELSE.
      rv_author = lv_author.
    ENDIF.

  ENDMETHOD.


METHOD nm_additional_naming_checks.

  "============================================================
  " Naming policy - customizable by project/company
  "============================================================
  CONSTANTS:
    BEGIN OF lc_pattern,
      global_type_struct      TYPE string VALUE 'GTY_*',
      global_type_table       TYPE string VALUE 'GTY_T_*',
      local_type_struct       TYPE string VALUE 'LTY_*',
      local_type_table        TYPE string VALUE 'LTY_T_*',

      global_constant         TYPE string VALUE 'GC_*',
      local_constant          TYPE string VALUE 'LC_*',
      statics                 TYPE string VALUE 'ST_*',

      global_field_symbol     TYPE string VALUE '<GFS_*>',
      local_field_symbol      TYPE string VALUE '<LFS_*>',

      selection_parameter     TYPE string VALUE 'P_*',
      selection_checkbox      TYPE string VALUE 'CB_*',
      selection_radiobutton   TYPE string VALUE 'RB_*',
      selection_group         TYPE string VALUE 'RG*',
      selection_select_option TYPE string VALUE 'S_*',
      selection_block         TYPE string VALUE 'BL_*',

      form_name               TYPE string VALUE 'F_*',

      changing_structure      TYPE string VALUE 'CS_*',
      changing_table          TYPE string VALUE 'CT_*',
      changing_value          TYPE string VALUE 'CV_*',
      exporting_structure     TYPE string VALUE 'ES_*',
      exporting_table         TYPE string VALUE 'ET_*',
      exporting_value         TYPE string VALUE 'EV_*',
      importing_structure     TYPE string VALUE 'IS_*',
      importing_table         TYPE string VALUE 'IT_*',
      importing_value         TYPE string VALUE 'IV_*',
      form_using_structure    TYPE string VALUE 'PS_*',
      form_using_table        TYPE string VALUE 'PT_*',
      form_using_value        TYPE string VALUE 'PV_*',
      returning_structure     TYPE string VALUE 'RS_*',
      returning_table         TYPE string VALUE 'RT_*',
      returning_value         TYPE string VALUE 'RV_*',
      fm_tables               TYPE string VALUE 'TT_*',
    END OF lc_pattern,

    BEGIN OF lc_desc,
      internal_table TYPE string VALUE 'internal-table',
      structure      TYPE string VALUE 'structure',
      value          TYPE string VALUE 'value',
    END OF lc_desc.


  DATA: lv_sig_kind        TYPE c LENGTH 1,
        lv_sig_probe_idx   TYPE sy-tabix,
        lv_sig_type_name   TYPE string,
        lv_sig_type_name_u TYPE string.

  DATA lt_type_cache TYPE gty_t_name_kind.

  DATA: lv_stmt_idx2          TYPE sy-tabix,
        lv_u                  TYPE string,
        lv_name               TYPE string,
        lv_name_u             TYPE string,
        lv_row                TYPE i,
        lv_ok                 TYPE abap_bool,
        lv_text               TYPE string,
        lv_tok_u              TYPE string,
        lv_const_exp          TYPE abap_bool,
        lv_const_begin_depth  TYPE i,
        lv_expect_struct_name TYPE abap_bool,
        lv_struct_name        TYPE string,
        lv_struct_name_u      TYPE string,
        lv_stat_exp           TYPE abap_bool,
        lv_fs_exp             TYPE abap_bool,
        lv_type_has_begin     TYPE abap_bool VALUE abap_false,
        lv_type_has_comma     TYPE abap_bool VALUE abap_false,
        lv_type_is_tab        TYPE abap_bool VALUE abap_false,
        lv_type_scan_u        TYPE string,
        lv_type_name          TYPE string,
        lv_type_name_u        TYPE string,
        lv_type_ok            TYPE abap_bool,
        lv_par_exp            TYPE abap_bool,
        lv_par_pat            TYPE string,
        lv_sel_exp            TYPE abap_bool,
        lv_dummy_fm           TYPE string,
        lv_in_fm_iface        TYPE abap_bool VALUE abap_false,
        lv_type_is_line_of    TYPE abap_bool VALUE abap_false.

  DATA: lv_sig_sec      TYPE c LENGTH 1,
        lv_sig_name     TYPE string,
        lv_sig_name_u   TYPE string,
        lv_sig_row      TYPE i,
        lv_sig_wait     TYPE abap_bool,
        lv_expected_msg TYPE string,
        lv_tok_idx2     TYPE sy-tabix,
        ls_tok          TYPE stokex.

  "------------------------------------------------------------
  "E.2) Additional statement-based naming checks
  "------------------------------------------------------------
  LOOP AT it_stmts INTO DATA(ls_stmt).
    lv_stmt_idx2 = sy-tabix.

    READ TABLE it_stmt_info INDEX lv_stmt_idx2 INTO DATA(ls_stmt_info2).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    READ TABLE it_tokens INDEX ls_stmt-from INTO DATA(ls_first2).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF ls_first2-row > iv_curr_src_lines.
      CONTINUE.
    ENDIF.

    " E.2.3a) Inline FIELD-SYMBOL(...)
    lv_tok_idx2 = ls_stmt-from.

    WHILE lv_tok_idx2 < ls_stmt-to.
      lv_tok_idx2 += 1.

      READ TABLE it_tokens INDEX lv_tok_idx2 INTO ls_tok.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      CLEAR: lv_name,
             lv_name_u,
             lv_row.

      lv_u = to_upper( ls_tok-str ).

      " Case 1: compact token FIELD-SYMBOL(<fs>)
      IF lv_u CP gc_keyword-field_symbol_star.

        lv_name = ls_tok-str.
        lv_row  = ls_tok-row.

        REPLACE FIRST OCCURRENCE OF gc_keyword-field_symbol_lparen
          IN lv_name WITH '' IGNORING CASE.
        REPLACE FIRST OCCURRENCE OF gc_keyword-field_symbol
          IN lv_name WITH '' IGNORING CASE.
        REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_name WITH ''.
        REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_name WITH ''.
        CONDENSE lv_name NO-GAPS.

      " Case 2: split token FIELD-SYMBOL + next token
      ELSEIF lv_u = gc_keyword-field_symbol.

        DATA(lv_inline_fs_idx) = lv_tok_idx2.

        WHILE lv_inline_fs_idx < ls_stmt-to.
          lv_inline_fs_idx += 1.

          READ TABLE it_tokens INDEX lv_inline_fs_idx INTO DATA(ls_inline_fs_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_name = ls_inline_fs_tok-str.
          lv_row  = ls_inline_fs_tok-row.

          REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_name WITH ''.
          REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_name WITH ''.
          CONDENSE lv_name NO-GAPS.

          IF lv_name CP gc_keyword-field_symbol_pat.
            EXIT.
          ENDIF.

          CLEAR: lv_name, lv_row.
        ENDWHILE.

      ELSE.
        CONTINUE.
      ENDIF.

      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.

      REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_name WITH ''.
      REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_name WITH ''.
      CONDENSE lv_name NO-GAPS.

      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.

      lv_name_u = to_upper( lv_name ).

      lv_ok = COND abap_bool(
        WHEN ls_stmt_info2-is_local_scope = abap_true
        THEN xsdbool( lv_name_u CP lc_pattern-local_field_symbol )
        ELSE xsdbool( lv_name_u CP lc_pattern-global_field_symbol ) ).

      IF lv_ok = abap_false.

        IF ls_stmt_info2-is_local_scope = abap_true.
          MESSAGE w054(z_gsp04_message)
            WITH lv_name lc_pattern-local_field_symbol
            INTO lv_text.
        ELSE.
          MESSAGE w055(z_gsp04_message)
            WITH lv_name lc_pattern-global_field_symbol
            INTO lv_text.
        ENDIF.

        APPEND VALUE zst_error(
          rule     = gc_rule_nm-prefix_rule
          sev      = gc_severity-warning
          line     = lv_row
          msg      = lv_text
          category = gc_category-naming
        ) TO ct_errors.
      ENDIF.

    ENDWHILE.

    CASE to_upper( ls_first2-str ).

        "======================================================
        " E.2.1) CONSTANTS / CLASS-CONSTANTS
        "======================================================
      WHEN gc_keyword-constants
        OR gc_keyword-constants_col
        OR gc_keyword-class_constants
        OR gc_keyword-class_constants_col.

        CLEAR: lv_name, lv_row, lv_expect_struct_name.
        lv_const_exp = abap_true.

        lv_tok_idx2 = ls_stmt-from.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_const_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_u = to_upper( ls_const_tok-str ).

          CLEAR lv_tok_u.
          READ TABLE it_tokens INDEX ( lv_tok_idx2 + 1 ) INTO DATA(ls_next).
          IF sy-subrc = 0.
            lv_tok_u = to_upper( ls_next-str ).
          ENDIF.

          IF lv_u = gc_keyword-begin
             AND lv_tok_u = gc_keyword-of.
            lv_expect_struct_name = abap_true.
            lv_const_begin_depth += 1.
            CONTINUE.
          ENDIF.

          IF lv_const_begin_depth > 0.

            IF lv_expect_struct_name = abap_true.
              IF lv_u = gc_keyword-of.
                CONTINUE.
              ENDIF.

              IF ls_const_tok-type = gc_token_type-identifier.
                lv_struct_name = ls_const_tok-str.
                SHIFT lv_struct_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

                lv_struct_name_u = to_upper( lv_struct_name ).

                lv_ok = COND abap_bool(
                  WHEN ls_stmt_info2-is_local_scope = abap_true
                  THEN xsdbool( lv_struct_name_u CP lc_pattern-local_constant )
                  ELSE xsdbool( lv_struct_name_u CP lc_pattern-global_constant ) ).

                IF lv_ok = abap_false.
                  IF ls_stmt_info2-is_local_scope = abap_true.
                    MESSAGE w051(z_gsp04_message) WITH lv_struct_name lc_pattern-local_constant INTO lv_text.
                  ELSE.
                    MESSAGE w050(z_gsp04_message) WITH lv_struct_name lc_pattern-global_constant INTO lv_text.
                  ENDIF.

                  APPEND VALUE zst_error(
                    rule     = gc_rule_nm-prefix_rule
                    sev      = gc_severity-warning
                    line     = ls_const_tok-row
                    msg      = lv_text
                    category = gc_category-naming
                  ) TO ct_errors.
                ENDIF.

                lv_expect_struct_name = abap_false.
              ENDIF.
              CONTINUE.
            ENDIF.

            IF lv_u = gc_keyword-end
              AND lv_tok_u = gc_keyword-of.
              lv_const_begin_depth = lv_const_begin_depth - 1.
              CLEAR: lv_name, lv_row, lv_expect_struct_name.
              lv_const_exp = abap_true.
            ENDIF.
            CONTINUE.
          ENDIF.

          IF lv_u = gc_keyword-colon OR lv_u = gc_keyword-comma.
            CLEAR: lv_name, lv_row.
            lv_const_exp = abap_true.
            CONTINUE.
          ENDIF.

          IF lv_const_exp = abap_true
             AND ls_const_tok-type = gc_token_type-identifier.
            lv_name = ls_const_tok-str.
            SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_row = ls_const_tok-row.
            lv_const_exp = abap_false.
            CONTINUE.
          ENDIF.

          IF lv_name IS NOT INITIAL
             AND ( lv_u = gc_keyword-type
                OR lv_u = gc_keyword-like
                OR lv_u = gc_keyword-value ).

            lv_name_u = to_upper( lv_name ).

            lv_ok = COND abap_bool(
              WHEN ls_stmt_info2-is_local_scope = abap_true
              THEN xsdbool( lv_name_u CP lc_pattern-local_constant )
              ELSE xsdbool( lv_name_u CP lc_pattern-global_constant ) ).

            IF lv_ok = abap_false.
              IF ls_stmt_info2-is_local_scope = abap_true.
                MESSAGE w051(z_gsp04_message) WITH lv_name lc_pattern-local_constant INTO lv_text.
              ELSE.
                MESSAGE w052(z_gsp04_message) WITH lv_name lc_pattern-global_constant INTO lv_text.
              ENDIF.

              APPEND VALUE zst_error(
                rule     = gc_rule_nm-prefix_rule
                sev      = gc_severity-warning
                line     = lv_row
                msg      = lv_text
                category = gc_category-naming
              ) TO ct_errors.
            ENDIF.

            CLEAR: lv_name, lv_row.
          ENDIF.
        ENDWHILE.

        "======================================================
        " E.2.2) STATICS
        "======================================================
      WHEN gc_keyword-statics OR gc_keyword-statics_col.

        CLEAR: lv_name, lv_row.
        lv_stat_exp = abap_true.

        lv_tok_idx2 = ls_stmt-from.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_stat_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_u = to_upper( ls_stat_tok-str ).

          IF lv_u = gc_keyword-colon OR lv_u = gc_keyword-comma.
            CLEAR: lv_name, lv_row.
            lv_stat_exp = abap_true.
            CONTINUE.
          ENDIF.

          IF lv_stat_exp = abap_true
             AND ls_stat_tok-type = gc_token_type-identifier.
            lv_name = ls_stat_tok-str.
            SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_row      = ls_stat_tok-row.
            lv_stat_exp = abap_false.
            CONTINUE.
          ENDIF.

          IF lv_name IS NOT INITIAL
             AND ( lv_u = gc_keyword-type
                OR lv_u = gc_keyword-like
                OR lv_u = gc_keyword-value ).

            lv_name_u = to_upper( lv_name ).

            IF lv_name_u NP lc_pattern-statics.
              MESSAGE w053(z_gsp04_message) WITH lv_name lc_pattern-statics INTO lv_text.
              APPEND VALUE zst_error(
                rule     = gc_rule_nm-prefix_rule
                sev      = gc_severity-warning
                line     = lv_row
                msg      = lv_text
                category = gc_category-naming
              ) TO ct_errors.
            ENDIF.

            CLEAR: lv_name, lv_row.
          ENDIF.
        ENDWHILE.

        "======================================================
        " E.2.3) FIELD-SYMBOLS
        "======================================================
      WHEN gc_keyword-field_symbols OR gc_keyword-field_symbols_col.

        CLEAR: lv_name, lv_row.
        lv_fs_exp = abap_true.

        lv_tok_idx2 = ls_stmt-from.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_fs_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_u = to_upper( ls_fs_tok-str ).

          IF lv_u = gc_keyword-colon OR lv_u = gc_keyword-comma.
            CLEAR: lv_name, lv_row.
            lv_fs_exp = abap_true.
            CONTINUE.
          ENDIF.

          IF lv_fs_exp = abap_true
             AND ( ls_fs_tok-type = gc_token_type-identifier
                OR ls_fs_tok-str CP gc_keyword-field_symbol_pat ).
            lv_name = ls_fs_tok-str.
            lv_row  = ls_fs_tok-row.
            lv_fs_exp = abap_false.
            CONTINUE.
          ENDIF.

          IF lv_name IS NOT INITIAL
             AND ( lv_u = gc_keyword-type OR lv_u = gc_keyword-like ).
            lv_name_u = to_upper( lv_name ).

            lv_ok = COND abap_bool(
              WHEN ls_stmt_info2-is_local_scope = abap_true
              THEN xsdbool( lv_name_u CP lc_pattern-local_field_symbol )
              ELSE xsdbool( lv_name_u CP lc_pattern-global_field_symbol ) ).

            IF lv_ok = abap_false.
              IF ls_stmt_info2-is_local_scope = abap_true.
                MESSAGE w054(z_gsp04_message) WITH lv_name lc_pattern-local_field_symbol INTO lv_text.
              ELSE.
                MESSAGE w055(z_gsp04_message) WITH lv_name lc_pattern-global_field_symbol INTO lv_text.
              ENDIF.

              APPEND VALUE zst_error(
                rule     = gc_rule_nm-prefix_rule
                sev      = gc_severity-warning
                line     = lv_row
                msg      = lv_text
                category = gc_category-naming
              ) TO ct_errors.
            ENDIF.

            CLEAR: lv_name, lv_row.
          ENDIF.
        ENDWHILE.

        "======================================================
        " E.2.4) TYPES
        "======================================================
      WHEN gc_keyword-types OR gc_keyword-types_col.

        IF lv_type_has_begin = abap_true.
          lv_tok_idx2 = ls_stmt-from.
          WHILE lv_tok_idx2 < ls_stmt-to.
            lv_tok_idx2 += 1.

            READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_type_scan_tok).
            IF sy-subrc <> 0.
              EXIT.
            ENDIF.

            lv_type_scan_u = to_upper( ls_type_scan_tok-str ).

            IF lv_type_scan_u = gc_keyword-end.
              CLEAR lv_type_has_begin.
              EXIT.
            ENDIF.
          ENDWHILE.
          CONTINUE.
        ENDIF.

        CLEAR: lv_type_has_comma,
               lv_type_is_tab,
               lv_type_is_line_of,
               lv_type_name,
               lv_type_name_u.

        lv_tok_idx2 = ls_stmt-from.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO ls_type_scan_tok.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_type_scan_u = to_upper( ls_type_scan_tok-str ).

          IF lv_type_scan_u = gc_keyword-begin.

            READ TABLE it_tokens INDEX ( lv_tok_idx2 + 1 ) INTO ls_next.
            IF sy-subrc = 0.
              lv_u = to_upper( ls_next-str ).

              IF lv_u = gc_keyword-of.
                READ TABLE it_tokens INDEX ( lv_tok_idx2 + 2 ) INTO DATA(ls_type_name_tok).
                IF sy-subrc = 0
                   AND ls_type_name_tok-type = gc_token_type-identifier.

                  lv_type_name = ls_type_name_tok-str.
                  SHIFT lv_type_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

                  lv_type_name_u = to_upper( lv_type_name ).

                  lv_type_ok = COND abap_bool(
                    WHEN ls_stmt_info2-is_local_scope = abap_true
                    THEN xsdbool( lv_type_name_u CP lc_pattern-local_type_struct )
                    ELSE xsdbool( lv_type_name_u CP lc_pattern-global_type_struct ) ).

                  IF lv_type_ok = abap_false.

                    IF ls_stmt_info2-is_local_scope = abap_true.
                      MESSAGE w057(z_gsp04_message)
                        WITH lv_type_name lc_pattern-local_type_struct
                        INTO lv_text.
                    ELSE.
                      MESSAGE w059(z_gsp04_message)
                        WITH lv_type_name lc_pattern-global_type_struct
                        INTO lv_text.
                    ENDIF.

                    APPEND VALUE zst_error(
                      rule     = gc_rule_nm-prefix_rule
                      sev      = gc_severity-warning
                      line     = ls_type_name_tok-row
                      msg      = lv_text
                      category = gc_category-naming
                    ) TO ct_errors.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.

            lv_type_has_begin = abap_true.
            EXIT.
          ENDIF.

          IF lv_type_scan_u = gc_keyword-comma.
            lv_type_has_comma = abap_true.
          ENDIF.

          IF lv_type_scan_u = gc_keyword-line.
            READ TABLE it_tokens INDEX ( lv_tok_idx2 + 1 ) INTO ls_next.
            IF sy-subrc = 0.
              lv_u = to_upper( ls_next-str ).

              IF lv_u = gc_keyword-of.
                lv_type_is_line_of = abap_true.
              ENDIF.
            ENDIF.
          ENDIF.

          IF lv_type_scan_u = gc_keyword-table
             OR lv_type_scan_u = gc_keyword-standard
             OR lv_type_scan_u = gc_keyword-sorted
             OR lv_type_scan_u = gc_keyword-hashed.
            lv_type_is_tab = abap_true.
          ENDIF.
        ENDWHILE.

        IF lv_type_has_begin = abap_true OR lv_type_has_comma = abap_true.
          CONTINUE.
        ENDIF.

        READ TABLE it_tokens INDEX ( ls_stmt-from + 1 ) INTO ls_type_name_tok.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        lv_type_name = ls_type_name_tok-str.
        SHIFT lv_type_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

        lv_type_name_u = to_upper( lv_type_name ).

        IF lv_type_name_u = gc_keyword-end
           OR lv_type_name_u = gc_keyword-of.
          CONTINUE.
        ENDIF.

        lv_type_ok = COND abap_bool(
          WHEN ls_stmt_info2-is_local_scope = abap_true
               AND lv_type_is_line_of = abap_true
          THEN xsdbool(
                 lv_type_name_u CP lc_pattern-local_type_struct
                 AND lv_type_name_u NP lc_pattern-local_type_table )

          WHEN ls_stmt_info2-is_local_scope = abap_true
               AND lv_type_is_tab = abap_true
          THEN xsdbool( lv_type_name_u CP lc_pattern-local_type_table )

          WHEN ls_stmt_info2-is_local_scope = abap_true
          THEN xsdbool( lv_type_name_u CP lc_pattern-local_type_struct )

          WHEN lv_type_is_line_of = abap_true
          THEN xsdbool(
                 lv_type_name_u CP lc_pattern-global_type_struct
                 AND lv_type_name_u NP lc_pattern-global_type_table )

          WHEN lv_type_is_tab = abap_true
          THEN xsdbool( lv_type_name_u CP lc_pattern-global_type_table )

          ELSE xsdbool( lv_type_name_u CP lc_pattern-global_type_struct )
        ).

        IF lv_type_ok = abap_false.
          IF ls_stmt_info2-is_local_scope = abap_true AND lv_type_is_tab = abap_true.
            MESSAGE w056(z_gsp04_message) WITH lv_type_name lc_pattern-local_type_table INTO lv_text.
          ELSEIF ls_stmt_info2-is_local_scope = abap_true.
            MESSAGE w057(z_gsp04_message) WITH lv_type_name lc_pattern-local_type_struct INTO lv_text.
          ELSEIF lv_type_is_tab = abap_true.
            MESSAGE w058(z_gsp04_message) WITH lv_type_name lc_pattern-global_type_table INTO lv_text.
          ELSE.
            MESSAGE w059(z_gsp04_message) WITH lv_type_name lc_pattern-global_type_struct INTO lv_text.
          ENDIF.

          APPEND VALUE zst_error(
            rule     = gc_rule_nm-prefix_rule
            sev      = gc_severity-warning
            line     = ls_type_name_tok-row
            msg      = lv_text
            category = gc_category-naming
          ) TO ct_errors.
        ENDIF.

        "======================================================
        " E.2.5) PARAMETERS
        "======================================================
      WHEN gc_keyword-parameters OR gc_keyword-parameters_col.

        CLEAR: lv_name, lv_row.
        lv_par_exp = abap_true.

        lv_tok_idx2 = ls_stmt-from.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_par_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_u = to_upper( ls_par_tok-str ).

          IF lv_u = gc_keyword-colon OR lv_u = gc_keyword-comma.
            CLEAR: lv_name, lv_row.
            lv_par_exp = abap_true.
            CONTINUE.
          ENDIF.

          IF lv_par_exp = abap_true
             AND ls_par_tok-type = gc_token_type-identifier.
            lv_name = ls_par_tok-str.
            SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_row     = ls_par_tok-row.
            lv_par_exp = abap_false.
            CONTINUE.
          ENDIF.

          IF lv_name IS NOT INITIAL
             AND ( lv_u = gc_keyword-type
                OR lv_u = gc_keyword-like
                OR lv_u = gc_keyword-checkbox
                OR lv_u = gc_keyword-radiobutton ).

            lv_name_u = to_upper( lv_name ).

            IF lv_u = gc_keyword-checkbox.
              lv_par_pat = lc_pattern-selection_checkbox.
              lv_ok      = xsdbool( lv_name_u CP lc_pattern-selection_checkbox ).
            ELSEIF lv_u = gc_keyword-radiobutton.
              lv_par_pat = lc_pattern-selection_radiobutton.
              lv_ok      = xsdbool( lv_name_u CP lc_pattern-selection_radiobutton ).
            ELSE.
              lv_par_pat = lc_pattern-selection_parameter.
              lv_ok      = xsdbool( lv_name_u CP lc_pattern-selection_parameter ).
            ENDIF.

            IF strlen( lv_name_u ) > 8.
              lv_ok = abap_false.
            ENDIF.

            IF lv_ok = abap_false.
              MESSAGE w060(z_gsp04_message) WITH lv_name lv_par_pat INTO lv_text.
              APPEND VALUE zst_error(
                rule     = gc_rule_nm-prefix_rule
                sev      = gc_severity-warning
                line     = lv_row
                msg      = lv_text
                category = gc_category-naming
              ) TO ct_errors.
            ENDIF.

            CLEAR: lv_name, lv_row.
          ENDIF.

          IF lv_u = gc_keyword-group.
            READ TABLE it_tokens INDEX ( lv_tok_idx2 + 1 ) INTO DATA(ls_rg_tok).
            IF sy-subrc = 0.
              lv_name = ls_rg_tok-str.
              SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

              lv_name_u = to_upper( lv_name ).
              lv_row = ls_rg_tok-row.

              IF lv_name_u NP lc_pattern-selection_group OR strlen( lv_name_u ) > 4.
                MESSAGE w061(z_gsp04_message) WITH lv_name lc_pattern-selection_group INTO lv_text.
                APPEND VALUE zst_error(
                  rule     = gc_rule_nm-prefix_rule
                  sev      = gc_severity-warning
                  line     = lv_row
                  msg      = lv_text
                  category = gc_category-naming
                ) TO ct_errors.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDWHILE.

        "======================================================
        " E.2.6) SELECT-OPTIONS
        "======================================================
      WHEN gc_keyword-select_options OR gc_keyword-select_options_col.

        CLEAR: lv_name, lv_row.
        lv_sel_exp = abap_true.

        lv_tok_idx2 = ls_stmt-from.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_sel_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_u = to_upper( ls_sel_tok-str ).

          IF lv_u = gc_keyword-colon OR lv_u = gc_keyword-comma.
            CLEAR: lv_name, lv_row.
            lv_sel_exp = abap_true.
            CONTINUE.
          ENDIF.

          IF lv_sel_exp = abap_true
             AND ls_sel_tok-type = gc_token_type-identifier.
            lv_name = ls_sel_tok-str.
            SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_row     = ls_sel_tok-row.
            lv_sel_exp = abap_false.
            CONTINUE.
          ENDIF.

          IF lv_name IS NOT INITIAL
             AND ( lv_u = gc_keyword-for
                OR lv_u = gc_keyword-type
                OR lv_u = gc_keyword-like ).

            lv_name_u = to_upper( lv_name ).

            IF lv_name_u NP lc_pattern-selection_select_option OR strlen( lv_name_u ) > 8.
              MESSAGE w062(z_gsp04_message) WITH lv_name lc_pattern-selection_select_option INTO lv_text.
              APPEND VALUE zst_error(
                rule     = gc_rule_nm-prefix_rule
                sev      = gc_severity-warning
                line     = lv_row
                msg      = lv_text
                category = gc_category-naming
              ) TO ct_errors.
            ENDIF.

            CLEAR: lv_name, lv_row.
          ENDIF.
        ENDWHILE.

        "======================================================
        " E.2.7) SELECTION-SCREEN BLOCK
        "======================================================
      WHEN gc_keyword-selection_screen.

        lv_tok_idx2 = ls_stmt-from.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_blk_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_u = to_upper( ls_blk_tok-str ).

          IF lv_u <> gc_keyword-block.
            CONTINUE.
          ENDIF.

          READ TABLE it_tokens INDEX ( lv_tok_idx2 + 1 ) INTO ls_next.
          IF sy-subrc = 0.
            lv_name = ls_next-str.
            SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

            lv_name_u = to_upper( lv_name ).
            lv_row = ls_next-row.

            IF lv_name_u NP lc_pattern-selection_block.
              MESSAGE w063(z_gsp04_message) WITH lv_name lc_pattern-selection_block INTO lv_text.
              APPEND VALUE zst_error(
                rule     = gc_rule_nm-prefix_rule
                sev      = gc_severity-warning
                line     = lv_row
                msg      = lv_text
                category = gc_category-naming
              ) TO ct_errors.
            ENDIF.
          ENDIF.
          EXIT.
        ENDWHILE.

        "======================================================
        " E.2.8) FORM name + params
        "======================================================
      WHEN gc_keyword-form.

        READ TABLE it_tokens INDEX ( ls_stmt-from + 1 ) INTO ls_next.
        IF sy-subrc = 0.
          lv_name = ls_next-str.
          SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

          lv_name_u = to_upper( lv_name ).
          lv_row = ls_next-row.

          IF lv_name_u NP lc_pattern-form_name.
            MESSAGE w064(z_gsp04_message) WITH lv_name lc_pattern-form_name INTO lv_text.
            APPEND VALUE zst_error(
              rule     = gc_rule_nm-prefix_rule
              sev      = gc_severity-warning
              line     = lv_row
              msg      = lv_text
              category = gc_category-naming
            ) TO ct_errors.
          ENDIF.
        ENDIF.

        CLEAR: lv_sig_sec, lv_sig_name, lv_sig_row, lv_expected_msg, lv_sig_kind.
        lv_sig_wait = abap_false.

        lv_tok_idx2 = ls_stmt-from + 1.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_form_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_u = to_upper( ls_form_tok-str ).

          CASE lv_u.
            WHEN gc_keyword-tables
              OR gc_keyword-using
              OR gc_keyword-changing.

              CLEAR lv_sig_name.
              CASE lv_u.
                WHEN gc_keyword-tables.
                  lv_sig_sec = gc_sig_nm-tables.
                WHEN gc_keyword-using.
                  lv_sig_sec = gc_sig_nm-using.
                WHEN gc_keyword-changing.
                  lv_sig_sec = gc_sig_nm-changing.
              ENDCASE.
              lv_sig_wait = abap_true.
              CONTINUE.

            WHEN gc_keyword-comma OR gc_keyword-dot.
            WHEN OTHERS.
          ENDCASE.

          IF lv_sig_wait = abap_true
           AND ( lv_u = gc_keyword-default
              OR lv_u = gc_keyword-optional ).
            CONTINUE.
          ENDIF.

          IF lv_sig_wait = abap_true.
            READ TABLE it_tokens INDEX ( lv_tok_idx2 - 1 ) INTO DATA(ls_prev_sig_tok).
            IF sy-subrc = 0
               AND to_upper( ls_prev_sig_tok-str ) = gc_keyword-default.
              CONTINUE.
            ENDIF.
          ENDIF.

          IF lv_sig_wait = abap_true
            AND ls_form_tok-type = gc_token_type-identifier.
            lv_sig_name = ls_form_tok-str.
            SHIFT lv_sig_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_sig_row  = ls_form_tok-row.
            lv_sig_kind = gc_kind_nm-value.
            lv_sig_wait = abap_false.
            CONTINUE.
          ENDIF.

          IF lv_sig_name IS NOT INITIAL
           AND ( lv_u = gc_keyword-type
              OR lv_u = gc_keyword-like
              OR lv_u = gc_keyword-structure
              OR lv_u = gc_keyword-comma
              OR lv_u = gc_keyword-dot ).

            lv_sig_name_u = to_upper( lv_sig_name ).

            IF lv_sig_sec = gc_sig_nm-tables
               OR lv_u = gc_keyword-structure.
              lv_sig_kind = gc_kind_nm-table.

            ELSEIF lv_u = gc_keyword-type OR lv_u = gc_keyword-like.
              nm_resolve_sig_kind(
                EXPORTING
                  it_tokens            = it_tokens
                  iv_from              = lv_tok_idx2
                  iv_to                = ls_stmt-to
                IMPORTING
                  ev_kind              = lv_sig_kind
                  ev_last_idx          = lv_sig_probe_idx
                CHANGING
                  ct_type_cache        = lt_type_cache ).

              lv_tok_idx2 = lv_sig_probe_idx.
            ENDIF.

            CLEAR lv_expected_msg.
            CASE lv_sig_sec.
              WHEN gc_sig_nm-tables.
                lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-form_using_table ).
                MESSAGE w044(z_gsp04_message)
                  WITH gc_keyword-tables lc_desc-internal_table lv_sig_name lc_pattern-form_using_table INTO lv_expected_msg.

              WHEN gc_sig_nm-using.
                CASE lv_sig_kind.
                  WHEN gc_kind_nm-table.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-form_using_table ).
                    MESSAGE w044(z_gsp04_message)
                      WITH gc_keyword-using lc_desc-internal_table lv_sig_name lc_pattern-form_using_table INTO lv_expected_msg.
                  WHEN gc_kind_nm-structure.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-form_using_structure ).
                    MESSAGE w044(z_gsp04_message)
                      WITH gc_keyword-using lc_desc-structure lv_sig_name lc_pattern-form_using_structure INTO lv_expected_msg.
                  WHEN OTHERS.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-form_using_value ).
                    MESSAGE w044(z_gsp04_message)
                      WITH gc_keyword-using lc_desc-value lv_sig_name lc_pattern-form_using_value INTO lv_expected_msg.
                ENDCASE.

              WHEN gc_sig_nm-changing.
                CASE lv_sig_kind.
                  WHEN gc_kind_nm-table.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_table ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-changing lc_desc-internal_table lv_sig_name lc_pattern-changing_table INTO lv_expected_msg.
                  WHEN gc_kind_nm-structure.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_structure ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-changing lc_desc-structure lv_sig_name lc_pattern-changing_structure INTO lv_expected_msg.
                  WHEN OTHERS.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_value ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-changing lc_desc-value lv_sig_name lc_pattern-changing_value INTO lv_expected_msg.
                ENDCASE.

              WHEN OTHERS.
                lv_ok = abap_true.
            ENDCASE.

            IF lv_ok = abap_false AND lv_expected_msg IS NOT INITIAL.
              APPEND VALUE zst_error(
                rule     = gc_rule_nm-prefix_rule
                sev      = gc_severity-warning
                line     = lv_sig_row
                msg      = lv_expected_msg
                category = gc_category-naming
              ) TO ct_errors.
            ENDIF.

            CLEAR lv_sig_name.
            lv_sig_wait = xsdbool(
              lv_sig_sec IS NOT INITIAL
              AND lv_u <> gc_keyword-dot ).
          ENDIF.
        ENDWHILE.

        "======================================================
        " E.2.9) METHODS / CLASS-METHODS params
        "======================================================
      WHEN gc_keyword-methods
        OR gc_keyword-methods_col
        OR gc_keyword-class_methods
        OR gc_keyword-class_methods_col.

        CLEAR: lv_sig_sec, lv_sig_name, lv_sig_row, lv_expected_msg, lv_sig_kind.
        lv_sig_wait = abap_false.

        lv_tok_idx2 = ls_stmt-from.
        WHILE lv_tok_idx2 < ls_stmt-to.
          lv_tok_idx2 += 1.

          READ TABLE it_tokens INDEX lv_tok_idx2 INTO DATA(ls_meth_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_u = to_upper( ls_meth_tok-str ).

          IF lv_u CP gc_keyword-value_star.
            lv_u = gc_keyword-value.
          ENDIF.

          CASE lv_u.
            WHEN gc_keyword-importing
              OR gc_keyword-exporting
              OR gc_keyword-changing.

              CLEAR lv_sig_name.
              CASE lv_u.
                WHEN gc_keyword-importing.
                  lv_sig_sec = gc_sig_nm-importing.
                WHEN gc_keyword-exporting.
                  lv_sig_sec = gc_sig_nm-exporting.
                WHEN gc_keyword-changing.
                  lv_sig_sec = gc_sig_nm-changing.
              ENDCASE.
              lv_sig_wait = abap_true.
              CONTINUE.

            WHEN gc_keyword-returning.
              CLEAR lv_sig_name.
              lv_sig_sec  = gc_sig_nm-returning.
              lv_sig_wait = abap_false.
              CONTINUE.

            WHEN gc_keyword-value.

              IF lv_sig_sec <> gc_sig_nm-returning
                 AND lv_sig_wait = abap_true.

                IF to_upper( ls_meth_tok-str ) CP gc_keyword-value_star.

                  lv_sig_name = ls_meth_tok-str.
                  lv_sig_row  = ls_meth_tok-row.

                  REPLACE FIRST OCCURRENCE OF gc_keyword-value_lparen
                    IN lv_sig_name WITH '' IGNORING CASE.

                ELSE.
                  READ TABLE it_tokens INDEX ( lv_tok_idx2 + 1 ) INTO ls_next.
                  IF sy-subrc <> 0.
                    CONTINUE.
                  ENDIF.

                  IF ls_next-str = gc_keyword-lparen.
                    READ TABLE it_tokens INDEX ( lv_tok_idx2 + 2 ) INTO ls_next.
                    IF sy-subrc <> 0.
                      CONTINUE.
                    ENDIF.
                    lv_tok_idx2 = lv_tok_idx2 + 2.
                  ELSE.
                    lv_tok_idx2 = lv_tok_idx2 + 1.
                  ENDIF.

                  lv_sig_name = ls_next-str.
                  lv_sig_row  = ls_next-row.
                ENDIF.

                REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_sig_name WITH ''.
                REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_sig_name WITH ''.
                CONDENSE lv_sig_name NO-GAPS.
                SHIFT lv_sig_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

                IF lv_sig_name IS INITIAL.
                  CONTINUE.
                ENDIF.

                lv_sig_kind = gc_kind_nm-value.
                lv_sig_wait = abap_false.
                CONTINUE.
              ENDIF.

              IF lv_sig_sec = gc_sig_nm-returning.

                IF to_upper( ls_meth_tok-str ) CP gc_keyword-value_star.
                  lv_name = ls_meth_tok-str.
                  lv_row  = ls_meth_tok-row.
                  REPLACE FIRST OCCURRENCE OF gc_keyword-value_lparen
                    IN lv_name WITH '' IGNORING CASE.
                ELSE.

                  READ TABLE it_tokens INDEX ( lv_tok_idx2 + 1 ) INTO ls_next.
                  IF sy-subrc <> 0.
                    CONTINUE.
                  ENDIF.

                  IF ls_next-str = gc_keyword-lparen.
                    READ TABLE it_tokens INDEX ( lv_tok_idx2 + 2 ) INTO ls_next.
                    IF sy-subrc <> 0.
                      CONTINUE.
                    ENDIF.
                    lv_tok_idx2 = lv_tok_idx2 + 2.
                  ELSE.
                    lv_tok_idx2 = lv_tok_idx2 + 1.
                  ENDIF.

                  lv_name = ls_next-str.
                  lv_row  = ls_next-row.

                ENDIF.

                REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_name WITH ''.
                REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_name WITH ''.
                CONDENSE lv_name NO-GAPS.
                SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

                IF lv_name IS INITIAL.
                  CONTINUE.
                ENDIF.

                lv_name_u = to_upper( lv_name ).

                nm_resolve_sig_kind(
                  EXPORTING
                    it_tokens     = it_tokens
                    iv_from       = lv_tok_idx2
                    iv_to         = ls_stmt-to
                  IMPORTING
                    ev_kind       = lv_sig_kind
                  CHANGING
                    ct_type_cache = lt_type_cache ).

                CASE lv_sig_kind.
                  WHEN gc_kind_nm-table.
                    lv_ok = xsdbool( lv_name_u CP lc_pattern-returning_table ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-returning lc_desc-internal_table lv_name lc_pattern-returning_table
                      INTO lv_text.

                  WHEN gc_kind_nm-structure.
                    lv_ok = xsdbool( lv_name_u CP lc_pattern-returning_structure ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-returning lc_desc-structure lv_name lc_pattern-returning_structure
                      INTO lv_text.

                  WHEN OTHERS.
                    lv_ok = xsdbool( lv_name_u CP lc_pattern-returning_value ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-returning lc_desc-value lv_name lc_pattern-returning_value
                      INTO lv_text.
                ENDCASE.

                IF lv_ok = abap_false.
                  APPEND VALUE zst_error(
                    rule     = gc_rule_nm-prefix_rule
                    sev      = gc_severity-warning
                    line     = lv_row
                    msg      = lv_text
                    category = gc_category-naming
                  ) TO ct_errors.
                ENDIF.

              ENDIF.

              CONTINUE.

            WHEN gc_keyword-comma OR gc_keyword-dot.
            WHEN OTHERS.
          ENDCASE.

          IF lv_sig_wait = abap_true
           AND ( lv_u = gc_keyword-default
              OR lv_u = gc_keyword-optional ).
            CONTINUE.
          ENDIF.

          IF lv_sig_wait = abap_true.
            READ TABLE it_tokens INDEX ( lv_tok_idx2 - 1 ) INTO ls_prev_sig_tok.
            IF sy-subrc = 0
               AND to_upper( ls_prev_sig_tok-str ) = gc_keyword-default.
              CONTINUE.
            ENDIF.
          ENDIF.

          IF lv_sig_wait = abap_true
            AND ls_meth_tok-type = gc_token_type-identifier.
            lv_sig_name = ls_meth_tok-str.
            SHIFT lv_sig_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_sig_row  = ls_meth_tok-row.
            lv_sig_kind = gc_kind_nm-value.
            lv_sig_wait = abap_false.
            CONTINUE.
          ENDIF.

          IF lv_sig_name IS NOT INITIAL
             AND ( lv_u = gc_keyword-type
                OR lv_u = gc_keyword-like
                OR lv_u = gc_keyword-comma
                OR lv_u = gc_keyword-dot ).

            IF to_upper( lv_sig_name ) CP gc_keyword-value_star.
              REPLACE FIRST OCCURRENCE OF gc_keyword-value_lparen IN lv_sig_name WITH '' IGNORING CASE.
            ENDIF.

            REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_sig_name WITH ''.
            REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_sig_name WITH ''.
            CONDENSE lv_sig_name NO-GAPS.
            SHIFT lv_sig_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

            lv_sig_name_u = to_upper( lv_sig_name ).

            IF lv_u = gc_keyword-type OR lv_u = gc_keyword-like.
              nm_resolve_sig_kind(
                EXPORTING
                  it_tokens            = it_tokens
                  iv_from              = lv_tok_idx2
                  iv_to                = ls_stmt-to
                IMPORTING
                  ev_kind              = lv_sig_kind
                  ev_last_idx          = lv_sig_probe_idx
                CHANGING
                  ct_type_cache        = lt_type_cache ).

              lv_tok_idx2 = lv_sig_probe_idx.
            ENDIF.

            CLEAR lv_expected_msg.
            CASE lv_sig_sec.
              WHEN gc_sig_nm-importing.
                CASE lv_sig_kind.
                  WHEN gc_kind_nm-table.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-importing_table ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-importing lc_desc-internal_table lv_sig_name lc_pattern-importing_table INTO lv_expected_msg.
                  WHEN gc_kind_nm-structure.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-importing_structure ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-importing lc_desc-structure lv_sig_name lc_pattern-importing_structure INTO lv_expected_msg.
                  WHEN OTHERS.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-importing_value ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-importing lc_desc-value lv_sig_name lc_pattern-importing_value INTO lv_expected_msg.
                ENDCASE.

              WHEN gc_sig_nm-exporting.
                CASE lv_sig_kind.
                  WHEN gc_kind_nm-table.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-exporting_table ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-exporting lc_desc-internal_table lv_sig_name lc_pattern-exporting_table INTO lv_expected_msg.
                  WHEN gc_kind_nm-structure.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-exporting_structure ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-exporting lc_desc-structure lv_sig_name lc_pattern-exporting_structure INTO lv_expected_msg.
                  WHEN OTHERS.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-exporting_value ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-exporting lc_desc-value lv_sig_name lc_pattern-exporting_value INTO lv_expected_msg.
                ENDCASE.

              WHEN gc_sig_nm-changing.
                CASE lv_sig_kind.
                  WHEN gc_kind_nm-table.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_table ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-changing lc_desc-internal_table lv_sig_name lc_pattern-changing_table INTO lv_expected_msg.
                  WHEN gc_kind_nm-structure.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_structure ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-changing lc_desc-structure lv_sig_name lc_pattern-changing_structure INTO lv_expected_msg.
                  WHEN OTHERS.
                    lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_value ).
                    MESSAGE w046(z_gsp04_message)
                      WITH gc_keyword-changing lc_desc-value lv_sig_name lc_pattern-changing_value INTO lv_expected_msg.
                ENDCASE.

              WHEN OTHERS.
                lv_ok = abap_true.
            ENDCASE.

            IF lv_ok = abap_false AND lv_expected_msg IS NOT INITIAL.
              APPEND VALUE zst_error(
                rule     = gc_rule_nm-prefix_rule
                sev      = gc_severity-warning
                line     = lv_sig_row
                msg      = lv_expected_msg
                category = gc_category-naming
              ) TO ct_errors.
            ENDIF.

            CLEAR lv_sig_name.
            lv_sig_wait = xsdbool(
              lv_sig_sec IS NOT INITIAL
              AND lv_u <> gc_keyword-dot ).
          ENDIF.
        ENDWHILE.
    ENDCASE.
  ENDLOOP.

  "------------------------------------------------------------
  " E.3) Function module interface comments (IMPORT/EXPORT/...)
  "------------------------------------------------------------
  LOOP AT it_source INTO DATA(lv_fm_src_line).
    DATA(lv_fm_src_row) = sy-tabix.
    DATA(lv_fm_src_u)   = to_upper( lv_fm_src_line ).

    SHIFT lv_fm_src_u LEFT DELETING LEADING space.

    IF lv_fm_src_u CP gc_keyword-func_pat.
      lv_in_fm_iface = abap_true.
      CLEAR lv_sig_sec.
      CONTINUE.
    ENDIF.

    IF lv_in_fm_iface = abap_false
       OR lv_fm_src_u IS INITIAL.
      CONTINUE.
    ENDIF.

    IF strlen( lv_fm_src_u ) < 2
       OR lv_fm_src_u(2) <> gc_keyword-comment_quote.

      IF lv_fm_src_u(1) <> gc_keyword-star.
        lv_in_fm_iface = abap_false.
        CLEAR lv_sig_sec.
      ENDIF.

      CONTINUE.
    ENDIF.

    DATA(lv_fm_iface_line) = lv_fm_src_u.

    REPLACE FIRST OCCURRENCE OF gc_keyword-comment_quote
      IN lv_fm_iface_line
      WITH ''.

    SHIFT lv_fm_iface_line LEFT DELETING LEADING space.

    IF lv_fm_iface_line IS INITIAL
       OR lv_fm_iface_line CO gc_keyword-dash.
      CONTINUE.
    ENDIF.

    CASE lv_fm_iface_line.
      WHEN gc_keyword-importing.
        lv_sig_sec = gc_sig_nm-importing.
        CONTINUE.

      WHEN gc_keyword-exporting.
        lv_sig_sec = gc_sig_nm-exporting.
        CONTINUE.

      WHEN gc_keyword-changing.
        lv_sig_sec = gc_sig_nm-changing.
        CONTINUE.

      WHEN gc_keyword-tables.
        lv_sig_sec = gc_sig_nm-tables.
        CONTINUE.

      WHEN gc_keyword-exceptions.
        CLEAR lv_sig_sec.
        CONTINUE.
    ENDCASE.

    IF lv_sig_sec IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_sig_name = ``.     "CLEAR

    FIND FIRST OCCURRENCE OF PCRE gc_rx_nm-fm_value
      IN lv_fm_iface_line
      SUBMATCHES lv_sig_name.

    IF lv_sig_name IS INITIAL.
      SPLIT lv_fm_iface_line AT space INTO lv_sig_name lv_dummy_fm.
    ENDIF.

    SHIFT lv_sig_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

    IF lv_sig_name IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_sig_name_u = to_upper( lv_sig_name ).
    lv_sig_kind   = gc_kind_nm-value.

    IF lv_sig_sec = gc_sig_nm-tables.

      lv_sig_kind = gc_kind_nm-table.

    ELSEIF lv_fm_iface_line CS gc_iface_phrase_nm-structure.

      lv_sig_kind = gc_kind_nm-structure.

    ELSEIF lv_fm_iface_line CS gc_iface_phrase_nm-standard_table
        OR lv_fm_iface_line CS gc_iface_phrase_nm-sorted_table
        OR lv_fm_iface_line CS gc_iface_phrase_nm-hashed_table
        OR lv_fm_iface_line CS gc_iface_phrase_nm-table_of.

      lv_sig_kind = gc_kind_nm-table.

    ELSE.

      lv_sig_type_name = ``.     "CLEAR

      FIND FIRST OCCURRENCE OF PCRE gc_rx_nm-type_name
        IN lv_fm_iface_line
        SUBMATCHES lv_sig_type_name.

      IF lv_sig_type_name IS INITIAL.
        FIND FIRST OCCURRENCE OF PCRE gc_rx_nm-like_name
          IN lv_fm_iface_line
          SUBMATCHES lv_sig_type_name.
      ENDIF.

      IF lv_sig_type_name IS NOT INITIAL.
        SHIFT lv_sig_type_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

        lv_sig_type_name_u = to_upper( lv_sig_type_name ).

        IF lv_sig_type_name_u CP lc_pattern-global_type_table
           OR lv_sig_type_name_u CP lc_pattern-local_type_table.

          lv_sig_kind = gc_kind_nm-table.

        ELSEIF lv_sig_type_name_u CP lc_pattern-global_type_struct
            OR lv_sig_type_name_u CP lc_pattern-local_type_struct.
          lv_sig_kind = gc_kind_nm-structure.

        ELSE.
          nm_resolve_type_kind(
            EXPORTING
              iv_type_name  = lv_sig_type_name_u
            IMPORTING
              ev_kind       = lv_sig_kind
            CHANGING
              ct_type_cache = lt_type_cache ).
        ENDIF.
      ENDIF.
    ENDIF.

    CLEAR lv_expected_msg.

    CASE lv_sig_sec.

      WHEN gc_sig_nm-importing.

        CASE lv_sig_kind.
          WHEN gc_kind_nm-table.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-importing_table ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-importing
                   lc_desc-internal_table
                   lv_sig_name
                   lc_pattern-importing_table
              INTO lv_expected_msg.

          WHEN gc_kind_nm-structure.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-importing_structure ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-importing
                   lc_desc-structure
                   lv_sig_name
                   lc_pattern-importing_structure
              INTO lv_expected_msg.

          WHEN OTHERS.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-importing_value ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-importing
                   lc_desc-value
                   lv_sig_name
                   lc_pattern-importing_value
              INTO lv_expected_msg.
        ENDCASE.

      WHEN gc_sig_nm-exporting.

        CASE lv_sig_kind.
          WHEN gc_kind_nm-table.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-exporting_table ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-exporting
                   lc_desc-internal_table
                   lv_sig_name
                   lc_pattern-exporting_table
              INTO lv_expected_msg.

          WHEN gc_kind_nm-structure.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-exporting_structure ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-exporting
                   lc_desc-structure
                   lv_sig_name
                   lc_pattern-exporting_structure
              INTO lv_expected_msg.

          WHEN OTHERS.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-exporting_value ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-exporting
                   lc_desc-value
                   lv_sig_name
                   lc_pattern-exporting_value
              INTO lv_expected_msg.
        ENDCASE.

      WHEN gc_sig_nm-changing.

        CASE lv_sig_kind.
          WHEN gc_kind_nm-table.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_table ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-changing
                   lc_desc-internal_table
                   lv_sig_name
                   lc_pattern-changing_table
              INTO lv_expected_msg.

          WHEN gc_kind_nm-structure.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_structure ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-changing
                   lc_desc-structure
                   lv_sig_name
                   lc_pattern-changing_structure
              INTO lv_expected_msg.

          WHEN OTHERS.
            lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-changing_value ).
            MESSAGE w047(z_gsp04_message)
              WITH gc_keyword-changing
                   lc_desc-value
                   lv_sig_name
                   lc_pattern-changing_value
              INTO lv_expected_msg.
        ENDCASE.

      WHEN gc_sig_nm-tables.

        lv_ok = xsdbool( lv_sig_name_u CP lc_pattern-fm_tables ).
        MESSAGE w047(z_gsp04_message)
          WITH gc_keyword-tables
               lc_desc-internal_table
               lv_sig_name
               lc_pattern-fm_tables
          INTO lv_expected_msg.

      WHEN OTHERS.

        lv_ok = abap_true.

    ENDCASE.

    IF lv_ok = abap_false
       AND lv_expected_msg IS NOT INITIAL.

      APPEND VALUE zst_error(
        rule     = gc_rule_nm-prefix_rule
        sev      = gc_severity-warning
        line     = lv_fm_src_row
        msg      = lv_expected_msg
        category = gc_category-naming
      ) TO ct_errors.

    ENDIF.
  ENDLOOP.

  "------------------------------------------------------------
  " F) Post-processing
  "------------------------------------------------------------
  LOOP AT it_pending INTO DATA(ls_p).
    APPEND VALUE zst_error(
      rule     = gc_rule_nm-prefix_rule
      sev      = gc_severity-warning
      line     = ls_p-row
      msg      = ls_p-msg
      category = gc_category-naming
    ) TO ct_errors.
  ENDLOOP.
ENDMETHOD.


METHOD nm_data_checks.

  "============================================================
  " Naming policy - customizable by project/company
  "============================================================
  CONSTANTS:
    BEGIN OF lc_pattern,
      global_type_struct  TYPE string VALUE 'GTY_*',
      global_type_table   TYPE string VALUE 'GTY_T_*',
      local_type_struct   TYPE string VALUE 'LTY_*',
      local_type_table    TYPE string VALUE 'LTY_T_*',

      global_constant     TYPE string VALUE 'GC_*',
      global_value        TYPE string VALUE 'GV_*',
      global_structure    TYPE string VALUE 'GS_*',
      global_table        TYPE string VALUE 'GT_*',
      global_data_ref     TYPE string VALUE 'GR_*',
      global_object_ref   TYPE string VALUE 'GO_*',
      global_macro        TYPE string VALUE 'GM_*',
      global_field_symbol TYPE string VALUE '<GFS_*>',

      local_constant      TYPE string VALUE 'LC_*',
      local_value         TYPE string VALUE 'LV_*',
      local_structure     TYPE string VALUE 'LS_*',
      local_table         TYPE string VALUE 'LT_*',
      local_data_ref      TYPE string VALUE 'LR_*',
      local_object_ref    TYPE string VALUE 'LO_*',
      local_macro         TYPE string VALUE 'LM_*',
      local_field_symbol  TYPE string VALUE '<LFS_*>',
    END OF lc_pattern.

  TYPES: BEGIN OF lty_seen,
           name_u TYPE string,
           row    TYPE i,
         END OF lty_seen.

  DATA: lt_seen            TYPE HASHED TABLE OF lty_seen WITH UNIQUE KEY name_u row,
        lt_type_kind       TYPE gty_t_name_kind,
        lt_decl_kind_map   TYPE gty_t_name_kind,
        lt_type_cache      TYPE gty_t_name_kind,
        lt_method_ret_kind TYPE gty_t_nm_method_ret. "NEW NEW NEW

  DATA: ls_prev_id          TYPE stokex,
        ls_prev2            TYPE stokex,
        ls_prev3            TYPE stokex,
        lv_text             TYPE string,
        lv_stmt_idx         TYPE sy-tabix VALUE 0,
        lv_tok_idx          TYPE sy-tabix,
        lv_probe_idx        TYPE sy-tabix,
        lv_scan_idx         TYPE sy-tabix,
        lv_inline           TYPE string,
        lv_inline_u         TYPE string,
        lv_probe_u          TYPE string,
        lv_prev_u           TYPE string,
        lv_prev2_u          TYPE string,
        lv_prev3_u          TYPE string,
        lv_decl_kind        TYPE c LENGTH 1,
        lv_line_kind        TYPE c LENGTH 1,
        lv_resolved_kind    TYPE c LENGTH 1,
        lv_resolved_line    TYPE c LENGTH 1,
        lv_ok_inline        TYPE abap_bool,
        lv_id_u             TYPE string,
        lv_u                TYPE string,
        lv_name             TYPE string,
        lv_name_u           TYPE string,
        lv_ref_name         TYPE string,
        lv_ref_name_u       TYPE string,
        lv_row              TYPE i,
        lv_has_local_prefix TYPE abap_bool,
        lv_ok               TYPE abap_bool,
        lv_stmt_is_inline   TYPE abap_bool VALUE abap_false.

  CLEAR: lt_seen,
         lt_type_kind,
         lt_decl_kind_map,
         lv_stmt_idx,
         lv_stmt_is_inline,
         ls_prev_id.

  "------------------------------------------------------------
  " A) Build semantic type map for local TYPES
  "------------------------------------------------------------
  LOOP AT it_stmt_info INTO DATA(ls_stmt_info).

    DATA(lv_type_stmt_start) = ls_stmt_info-from.
    DATA(lv_is_types_stmt)   = abap_false.

    READ TABLE it_tokens INDEX ls_stmt_info-from INTO DATA(ls_t).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_u = to_upper( ls_t-str ).

    IF lv_u = gc_keyword-types
       OR lv_u = gc_keyword-types_col.
      lv_is_types_stmt = abap_true.
    ENDIF.

    " Chained TYPES:
    IF lv_is_types_stmt = abap_false.

      DATA(lv_prefix_idx_nm) = ls_stmt_info-from - 1.
      WHILE lv_prefix_idx_nm > 0.
        READ TABLE it_tokens INDEX lv_prefix_idx_nm INTO DATA(ls_type_prefix_tok).
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        DATA(lv_prefix_u_nm) = to_upper( ls_type_prefix_tok-str ).
        IF lv_prefix_u_nm = gc_keyword-dot.
          EXIT.
        ENDIF.

        IF lv_prefix_u_nm = gc_keyword-types
           OR lv_prefix_u_nm = gc_keyword-types_col.
          lv_is_types_stmt   = abap_true.
          lv_type_stmt_start = ls_stmt_info-from - 1.

          IF lv_type_stmt_start < 0.
            lv_type_stmt_start = 0.
          ENDIF.
          EXIT.
        ENDIF.

        IF lv_prefix_u_nm = gc_keyword-colon
           OR lv_prefix_u_nm = gc_keyword-comma.
          lv_prefix_idx_nm -= 1.
          CONTINUE.
        ENDIF.

        lv_prefix_idx_nm -= 1.
      ENDWHILE.
    ENDIF.

    IF lv_is_types_stmt = abap_false.
      CONTINUE.
    ENDIF.

    CLEAR: lv_name,
           lv_name_u,
           lv_decl_kind,
           lv_line_kind,
           lv_ref_name,
           lv_ref_name_u.

    lv_probe_idx = lv_type_stmt_start.

    " Find declared type name
    WHILE lv_probe_idx < ls_stmt_info-to.
      lv_probe_idx += 1.

      READ TABLE it_tokens INDEX lv_probe_idx INTO DATA(ls_probe).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_probe_u = to_upper( ls_probe-str ).

      IF lv_probe_u = gc_keyword-begin.
        WHILE lv_probe_idx < ls_stmt_info-to.
          lv_probe_idx += 1.

          READ TABLE it_tokens INDEX lv_probe_idx INTO ls_probe.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_probe_u = to_upper( ls_probe-str ).

          IF lv_probe_u = gc_keyword-of.
            CONTINUE.
          ENDIF.

          IF ls_probe-type = gc_token_type-identifier.
            lv_name = ls_probe-str.
            SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_name_u = to_upper( lv_name ).
            lv_decl_kind = gc_kind_nm-structure.
            EXIT.
          ENDIF.
        ENDWHILE.
        EXIT.
      ENDIF.

      IF ls_probe-type = gc_token_type-identifier
         AND lv_probe_u <> gc_keyword-of.
        lv_name = ls_probe-str.
        SHIFT lv_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
        lv_name_u = to_upper( lv_name ).
        EXIT.
      ENDIF.
    ENDWHILE.

    IF lv_name_u IS INITIAL.
      CONTINUE.
    ENDIF.

    IF lv_decl_kind IS INITIAL.
      lv_decl_kind = gc_kind_nm-value.

      WHILE lv_probe_idx < ls_stmt_info-to.
        lv_probe_idx += 1.

        READ TABLE it_tokens INDEX lv_probe_idx INTO ls_probe.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        lv_probe_u = to_upper( ls_probe-str ).

        IF lv_probe_u = gc_keyword-ref.
          lv_decl_kind = gc_kind_nm-object.
          EXIT.
        ENDIF.

        IF lv_probe_u = gc_keyword-table
           OR lv_probe_u = gc_keyword-standard
           OR lv_probe_u = gc_keyword-sorted
           OR lv_probe_u = gc_keyword-hashed.
          lv_decl_kind = gc_kind_nm-table.
          CONTINUE.
        ENDIF.

        IF lv_probe_u = gc_keyword-of
          AND lv_decl_kind = gc_kind_nm-table.

          CLEAR: lv_ref_name,
                 lv_ref_name_u,
                 lv_resolved_kind,
                 lv_resolved_line.

          READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO DATA(ls_next).
          IF sy-subrc = 0.
            lv_ref_name = ls_next-str.
            SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_ref_name_u = to_upper( lv_ref_name ).

            IF lv_ref_name_u = gc_builtin_type_nm-abap_string
               OR lv_ref_name_u = gc_builtin_type_nm-abap_xstring
               OR lv_ref_name_u = gc_builtin_type_nm-abap_c
               OR lv_ref_name_u = gc_builtin_type_nm-abap_n
               OR lv_ref_name_u = gc_builtin_type_nm-abap_d
               OR lv_ref_name_u = gc_builtin_type_nm-abap_t
               OR lv_ref_name_u = gc_builtin_type_nm-abap_i
               OR lv_ref_name_u = gc_builtin_type_nm-abap_int8
               OR lv_ref_name_u = gc_builtin_type_nm-abap_f
               OR lv_ref_name_u = gc_builtin_type_nm-abap_p
               OR lv_ref_name_u = gc_builtin_type_nm-abap_decfloat16
               OR lv_ref_name_u = gc_builtin_type_nm-abap_decfloat34
               OR lv_ref_name_u = gc_builtin_type_nm-abap_utclong.
              lv_line_kind = gc_kind_nm-value.
              EXIT.
            ENDIF.

            READ TABLE lt_type_kind WITH TABLE KEY name_u = lv_ref_name_u INTO DATA(ls_kind).
            IF sy-subrc = 0.
              IF ls_kind-kind = gc_kind_nm-table.
                IF ls_kind-line_kind IS NOT INITIAL.
                  lv_line_kind = ls_kind-line_kind.
                ELSE.
                  lv_line_kind = gc_kind_nm-structure.
                ENDIF.
              ELSE.
                lv_line_kind = ls_kind-kind.
              ENDIF.
              EXIT.
            ENDIF.

            CLEAR: lv_resolved_kind,
                   lv_resolved_line.

            nm_resolve_type_kind(
              EXPORTING
                iv_type_name  = lv_ref_name_u
              IMPORTING
                ev_kind       = lv_resolved_kind
                ev_line_kind  = lv_resolved_line
              CHANGING
                ct_type_cache = lt_type_cache ).

            IF lv_resolved_kind = gc_kind_nm-table.
              IF lv_resolved_line IS NOT INITIAL.
                lv_line_kind = lv_resolved_line.
              ELSE.
                lv_line_kind = gc_kind_nm-structure.
              ENDIF.
            ELSEIF lv_resolved_kind IS NOT INITIAL.
              lv_line_kind = lv_resolved_kind.
            ENDIF.

          ENDIF.
          EXIT.
        ENDIF.

        IF lv_probe_u = gc_keyword-line.
          READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO ls_next.
          IF sy-subrc = 0.
            lv_u = to_upper( ls_next-str ).

            IF lv_u = gc_keyword-of.
              READ TABLE it_tokens INDEX ( lv_probe_idx + 2 ) INTO ls_next.
              IF sy-subrc = 0.
                lv_ref_name = ls_next-str.
                SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
                lv_ref_name_u = to_upper( lv_ref_name ).

                " 1) Resolve from previously built TYPES map
                READ TABLE lt_type_kind WITH TABLE KEY name_u = lv_ref_name_u INTO ls_kind.
                IF sy-subrc = 0.
                  IF ls_kind-kind = gc_kind_nm-table OR ls_kind-kind = gc_kind_nm-range.
                    IF ls_kind-line_kind IS NOT INITIAL.
                      lv_decl_kind = ls_kind-line_kind.
                    ELSE.
                      lv_decl_kind = gc_kind_nm-structure.
                    ENDIF.
                  ELSE.
                    lv_decl_kind = ls_kind-kind.
                  ENDIF.
                  EXIT.
                ENDIF.

                " 2) Resolve from cache / DDIC
                lv_resolved_kind = ``.     "CLEAR
                lv_resolved_line = ``.     "CLEAR

                nm_resolve_type_kind(
                  EXPORTING
                    iv_type_name  = lv_ref_name_u
                  IMPORTING
                    ev_kind       = lv_resolved_kind
                    ev_line_kind  = lv_resolved_line
                  CHANGING
                    ct_type_cache = lt_type_cache ).

                IF lv_resolved_kind = gc_kind_nm-table.
                  IF lv_resolved_line IS NOT INITIAL.
                    lv_line_kind = lv_resolved_line.
                  ELSE.
                    lv_line_kind = gc_kind_nm-structure.
                  ENDIF.
                ELSEIF lv_resolved_kind IS NOT INITIAL.
                  lv_line_kind = lv_resolved_kind.
                ENDIF.

                EXIT.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.

        IF lv_probe_u = gc_builtin_type_nm-abap_string
           OR lv_probe_u = gc_builtin_type_nm-abap_xstring
           OR lv_probe_u = gc_builtin_type_nm-abap_c
           OR lv_probe_u = gc_builtin_type_nm-abap_n
           OR lv_probe_u = gc_builtin_type_nm-abap_d
           OR lv_probe_u = gc_builtin_type_nm-abap_t
           OR lv_probe_u = gc_builtin_type_nm-abap_i
           OR lv_probe_u = gc_builtin_type_nm-abap_int8
           OR lv_probe_u = gc_builtin_type_nm-abap_f
           OR lv_probe_u = gc_builtin_type_nm-abap_p
           OR lv_probe_u = gc_builtin_type_nm-abap_decfloat16
           OR lv_probe_u = gc_builtin_type_nm-abap_decfloat34
           OR lv_probe_u = gc_builtin_type_nm-abap_utclong.
          lv_decl_kind = gc_kind_nm-value.
          EXIT.
        ENDIF.

        IF ls_probe-type = gc_token_type-identifier
          AND lv_probe_u <> gc_keyword-type
          AND lv_probe_u <> gc_keyword-like.
          lv_ref_name = ls_probe-str.
          SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
          lv_ref_name_u = to_upper( lv_ref_name ).

          READ TABLE lt_type_kind WITH TABLE KEY name_u = lv_ref_name_u INTO ls_kind.
          IF sy-subrc = 0.
            lv_decl_kind = ls_kind-kind.
            lv_line_kind = ls_kind-line_kind.
            EXIT.
          ENDIF.

          nm_resolve_type_kind(
            EXPORTING
              iv_type_name  = lv_ref_name_u
            IMPORTING
              ev_kind       = lv_decl_kind
              ev_line_kind  = lv_line_kind
            CHANGING
              ct_type_cache = lt_type_cache ).
          EXIT.
        ENDIF.
      ENDWHILE.
    ENDIF.

    READ TABLE lt_type_kind WITH TABLE KEY name_u = lv_name_u TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      INSERT VALUE gty_name_kind(
        name_u    = lv_name_u
        kind      = lv_decl_kind
        line_kind = lv_line_kind
      ) INTO TABLE lt_type_kind.
    ENDIF.
  ENDLOOP.

  "------------------------------------------------------------
  " B) Inline DATA(...) in any statement
  "------------------------------------------------------------
  CLEAR lv_stmt_idx.
  "NEW NEW NEW
  IF it_method_ret_kind IS NOT INITIAL.

    lt_method_ret_kind = it_method_ret_kind.

  ELSE.

    me->nm_build_method_ret_kind(
      EXPORTING
        it_tokens           = it_tokens
      CHANGING
        ct_type_cache       = lt_type_cache
        ct_method_ret_cache = lt_method_ret_kind ).

  ENDIF.

  LOOP AT it_tokens INTO ls_t.
    lv_tok_idx = sy-tabix.

    IF lv_stmt_idx = 0.
      lv_stmt_idx += 1.
      READ TABLE it_stmt_info INDEX lv_stmt_idx INTO ls_stmt_info.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
    ELSEIF lv_tok_idx > ls_stmt_info-to.
      lv_stmt_idx += 1.
      READ TABLE it_stmt_info INDEX lv_stmt_idx INTO ls_stmt_info.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
    ENDIF.

    IF ls_t-row > iv_curr_src_lines
        OR lv_tok_idx = 1.
      CONTINUE.
    ENDIF.

    CLEAR: ls_prev_id,
           ls_prev2,
           ls_prev3,
           lv_prev_u,
           lv_prev2_u,
           lv_prev3_u,
           lv_inline,
           lv_inline_u.

    lv_u = to_upper( ls_t-str ).

    " Compact token: DATA(name) / @DATA(name)
    IF lv_u CS gc_keyword-data_lparen.
      READ TABLE it_tokens INDEX ( lv_tok_idx - 1 ) INTO ls_prev_id.
      IF sy-subrc = 0.
        lv_prev_u = to_upper( ls_prev_id-str ).
      ENDIF.

      READ TABLE it_tokens INDEX ( lv_tok_idx - 2 ) INTO ls_prev2.
      IF sy-subrc = 0.
        lv_prev2_u = to_upper( ls_prev2-str ).
      ENDIF.

      READ TABLE it_tokens INDEX ( lv_tok_idx - 3 ) INTO ls_prev3.
      IF sy-subrc = 0.
        lv_prev3_u = to_upper( ls_prev3-str ).
      ENDIF.

      lv_inline = ls_t-str.
      REPLACE FIRST OCCURRENCE OF gc_keyword-at_data_lparen IN lv_inline WITH ''.
      IF lv_inline = ls_t-str.
        REPLACE FIRST OCCURRENCE OF gc_keyword-data_lparen IN lv_inline WITH ''.
      ENDIF.
      REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_inline WITH ''.

      " Split token: DATA ( name )
    ELSEIF ls_t-str = gc_keyword-lparen.
      READ TABLE it_tokens INDEX ( lv_tok_idx - 1 ) INTO ls_prev_id.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_prev_u = to_upper( ls_prev_id-str ).
      IF lv_prev_u <> gc_keyword-data.
        CONTINUE.
      ENDIF.

      READ TABLE it_tokens INDEX ( lv_tok_idx + 1 ) INTO ls_next.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_inline = ls_next-str.

      READ TABLE it_tokens INDEX ( lv_tok_idx - 2 ) INTO ls_prev2.
      IF sy-subrc = 0.
        lv_prev2_u = to_upper( ls_prev2-str ).
      ENDIF.

      READ TABLE it_tokens INDEX ( lv_tok_idx - 3 ) INTO ls_prev3.
      IF sy-subrc = 0.
        lv_prev3_u = to_upper( ls_prev3-str ).
      ENDIF.

    ELSE.
      CONTINUE.
    ENDIF.

    IF lv_inline IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_inline_u = to_upper( lv_inline ).

    READ TABLE lt_seen
      WITH TABLE KEY name_u = lv_inline_u row = ls_t-row TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    INSERT VALUE lty_seen(
      name_u = lv_inline_u
      row    = ls_t-row
    ) INTO TABLE lt_seen.

    CLEAR: lv_decl_kind,
           lv_line_kind.
    lv_decl_kind = gc_kind_nm-unknown.

    " 1) Context before DATA(...)
    IF lv_u CS gc_keyword-data_lparen.
      IF lv_prev_u = gc_keyword-table
         AND ( lv_prev2_u = gc_keyword-into OR lv_prev2_u = gc_keyword-appending ).
        lv_decl_kind = gc_kind_nm-table.

      ELSEIF lv_prev_u = gc_keyword-into.
        CLEAR: lv_ref_name,
               lv_ref_name_u.

        lv_scan_idx = lv_tok_idx - 1.
        WHILE lv_scan_idx >= ls_stmt_info-from.
          READ TABLE it_tokens INDEX lv_scan_idx INTO ls_probe.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_probe_u = to_upper( ls_probe-str ).

          IF lv_probe_u = gc_keyword-count
             OR lv_probe_u CS gc_keyword-count_lparen.
            lv_decl_kind = gc_kind_nm-value.
            EXIT.
          ENDIF.

          IF lv_probe_u = gc_keyword-reference.
            lv_decl_kind = gc_kind_nm-data_ref.
            EXIT.
          ENDIF.

          IF ls_probe-type = gc_token_type-identifier
             AND lv_probe_u <> gc_keyword-type
             AND lv_probe_u <> gc_keyword-like.
            lv_ref_name = ls_probe-str.
            SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_ref_name_u = to_upper( lv_ref_name ).

            READ TABLE lt_decl_kind_map WITH TABLE KEY name_u = lv_ref_name_u INTO ls_kind.
            IF sy-subrc = 0 AND ( ls_kind-kind = gc_kind_nm-table OR ls_kind-kind = gc_kind_nm-range ).
              IF ls_kind-line_kind IS NOT INITIAL.
                lv_decl_kind = ls_kind-line_kind.
              ELSE.
                lv_decl_kind = gc_kind_nm-structure.
              ENDIF.
              EXIT.
            ENDIF.
          ENDIF.

          lv_scan_idx = lv_scan_idx - 1.
        ENDWHILE.
      ENDIF.

    ELSE.

      IF lv_prev2_u = gc_keyword-table
         AND ( lv_prev3_u = gc_keyword-into OR lv_prev3_u = gc_keyword-appending ).
        lv_decl_kind = gc_kind_nm-table.

      ELSEIF lv_prev2_u = gc_keyword-into.
        CLEAR: lv_ref_name,
               lv_ref_name_u.

        lv_scan_idx = lv_tok_idx - 3.
        WHILE lv_scan_idx >= ls_stmt_info-from.
          READ TABLE it_tokens INDEX lv_scan_idx INTO ls_probe.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_probe_u = to_upper( ls_probe-str ).

          IF ls_probe-type = gc_token_type-identifier
             AND lv_probe_u <> gc_keyword-type
             AND lv_probe_u <> gc_keyword-like.
            lv_ref_name = ls_probe-str.
            SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_ref_name_u = to_upper( lv_ref_name ).

            READ TABLE lt_decl_kind_map WITH TABLE KEY name_u = lv_ref_name_u INTO ls_kind.
            IF sy-subrc = 0 AND ( ls_kind-kind = gc_kind_nm-table OR ls_kind-kind = gc_kind_nm-range ).
              IF ls_kind-line_kind IS NOT INITIAL.
                lv_decl_kind = ls_kind-line_kind.
              ELSE.
                lv_decl_kind = gc_kind_nm-structure.
              ENDIF.
              EXIT.
            ENDIF.
          ENDIF.

          lv_scan_idx = lv_scan_idx - 1.
        ENDWHILE.

      ELSEIF lv_prev2_u = gc_keyword-count OR lv_prev3_u = gc_keyword-count
         OR lv_prev2_u CS gc_keyword-count_lparen OR lv_prev3_u CS gc_keyword-count_lparen.
        lv_decl_kind = gc_kind_nm-value.

      ELSEIF lv_prev3_u = gc_keyword-reference AND lv_prev2_u = gc_keyword-into.
        lv_decl_kind = gc_kind_nm-data_ref.
      ENDIF.
    ENDIF.

    " 2) Context after DATA(...)
    IF lv_decl_kind = gc_kind_nm-unknown.
      CLEAR: lv_resolved_kind,
             lv_resolved_line.

      lv_probe_idx = lv_tok_idx.

      WHILE lv_probe_idx < ls_stmt_info-to.
        lv_probe_idx += 1.

        READ TABLE it_tokens INDEX lv_probe_idx INTO ls_probe.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        lv_probe_u = to_upper( ls_probe-str ).

        IF lv_probe_u = gc_keyword-equal
           OR lv_probe_u = gc_keyword-cast_assign
           OR lv_probe_u = gc_keyword-exact_cast_assign.
          CONTINUE.
        ENDIF.

        IF ls_probe-type = gc_token_type-identifier
           AND lv_probe_u NS gc_keyword-static_call
           AND lv_probe_u NS gc_keyword-instance_call
           AND lv_probe_u NS gc_keyword-value
           AND lv_probe_u NS gc_keyword-corresponding
           AND lv_probe_u NS gc_keyword-conv
           AND lv_probe_u NS gc_keyword-new
           AND lv_probe_u NS gc_keyword-cast.

          CLEAR lv_u.
          READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO ls_next.
          IF sy-subrc = 0.
            lv_u = to_upper( ls_next-str ).
          ENDIF.

          IF lv_probe_u CS gc_keyword-lparen
           OR lv_u = gc_keyword-lparen.

            CLEAR lv_prev_u.
            READ TABLE it_tokens INDEX ( lv_probe_idx - 1 ) INTO ls_prev_id.
            IF sy-subrc = 0.
              lv_prev_u = to_upper( ls_prev_id-str ).
            ENDIF.

            lv_resolved_kind = me->nm_resolve_called_method_kind(
              iv_probe_u         = lv_probe_u
              iv_prev_u          = lv_prev_u
              iv_next_u          = lv_u
              iv_probe_idx       = lv_probe_idx
              it_tokens          = it_tokens
              it_method_ret_kind = lt_method_ret_kind ).

            IF lv_resolved_kind IS NOT INITIAL.
              lv_decl_kind = lv_resolved_kind.
              EXIT.
            ENDIF.

            IF lv_prev_u = gc_keyword-instance_call
               OR lv_prev_u = gc_keyword-static_call
               OR lv_probe_u CS gc_keyword-instance_call
               OR lv_probe_u CS gc_keyword-static_call.
              CONTINUE.
            ENDIF.

            lv_decl_kind = gc_kind_nm-value.
            EXIT.

          ENDIF.
        ENDIF.

        IF ls_probe-type = gc_token_type-identifier.

          CLEAR lv_prev_u.
          READ TABLE it_tokens INDEX ( lv_probe_idx - 1 ) INTO ls_prev_id.
          IF sy-subrc = 0.
            lv_prev_u = to_upper( ls_prev_id-str ).
          ENDIF.

          CLEAR lv_u.
          READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO ls_next.
          IF sy-subrc = 0.
            lv_u = to_upper( ls_next-str ).
          ENDIF.

          "Resolve method call returning kind
          CLEAR lv_resolved_kind.

          lv_resolved_kind = me->nm_resolve_called_method_kind(
            iv_probe_u         = lv_probe_u
            iv_prev_u          = lv_prev_u
            iv_next_u          = lv_u
            iv_probe_idx       = lv_probe_idx
            it_tokens          = it_tokens
            it_method_ret_kind = lt_method_ret_kind ).

          IF lv_resolved_kind IS NOT INITIAL.
            lv_decl_kind = lv_resolved_kind.
            EXIT.
          ENDIF.

          "Method call without known return type:
          "Do not assume object only because of -> or =>
          IF lv_probe_u CS gc_keyword-static_call
             OR lv_probe_u CS gc_keyword-instance_call
             OR lv_prev_u = gc_keyword-static_call
             OR lv_prev_u = gc_keyword-instance_call
             OR lv_u = gc_keyword-static_call
             OR lv_u = gc_keyword-instance_call.
            CONTINUE.
          ENDIF.
        ENDIF.

        IF lv_probe_u = gc_keyword-new
           OR lv_probe_u = gc_keyword-cast.
          lv_decl_kind = gc_kind_nm-object.
          EXIT.
        ENDIF.

        IF lv_probe_u = gc_keyword-ref.
          lv_decl_kind = gc_kind_nm-data_ref.
          EXIT.
        ENDIF.

        IF lv_probe_u = gc_keyword-value
           OR lv_probe_u = gc_keyword-corresponding
           OR lv_probe_u = gc_keyword-conv.

          READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO ls_next.
          IF sy-subrc = 0.
            lv_ref_name = ls_next-str.

            READ TABLE it_tokens INDEX ( lv_probe_idx + 2 ) INTO ls_probe.
            IF sy-subrc = 0
               AND to_upper( ls_probe-str ) = gc_keyword-static_call.

              READ TABLE it_tokens INDEX ( lv_probe_idx + 3 ) INTO ls_next.
              IF sy-subrc = 0
                 AND ls_next-type = gc_token_type-identifier.
                lv_ref_name = |{ lv_ref_name }{ gc_keyword-static_call }{ ls_next-str }|.
              ENDIF.
            ENDIF.

            REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_ref_name WITH ''.
            REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_ref_name WITH ''.
            CONDENSE lv_ref_name NO-GAPS.
            SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
            lv_ref_name_u = to_upper( lv_ref_name ).

            READ TABLE lt_type_kind
              WITH TABLE KEY name_u = lv_ref_name_u
              INTO ls_kind.
            IF sy-subrc = 0.
              lv_decl_kind = ls_kind-kind.
              lv_line_kind = ls_kind-line_kind.
              EXIT.
            ENDIF.

            READ TABLE lt_decl_kind_map
              WITH TABLE KEY name_u = lv_ref_name_u
              INTO ls_kind.
            IF sy-subrc = 0.
              lv_decl_kind = ls_kind-kind.
              lv_line_kind = ls_kind-line_kind.
              EXIT.
            ENDIF.

            nm_resolve_type_kind(
              EXPORTING
                iv_type_name  = lv_ref_name_u
              IMPORTING
                ev_kind       = lv_decl_kind
                ev_line_kind  = lv_line_kind
              CHANGING
                ct_type_cache = lt_type_cache ).

            IF lv_decl_kind <> gc_kind_nm-value
               OR lv_line_kind IS NOT INITIAL.
              EXIT.
            ENDIF.

            EXIT.
          ENDIF.
        ENDIF.

        IF lv_probe_u = gc_builtin_type_nm-abap_string
           OR lv_probe_u = gc_builtin_type_nm-abap_xstring
           OR lv_probe_u = gc_builtin_type_nm-abap_c
           OR lv_probe_u = gc_builtin_type_nm-abap_n
           OR lv_probe_u = gc_builtin_type_nm-abap_d
           OR lv_probe_u = gc_builtin_type_nm-abap_t
           OR lv_probe_u = gc_builtin_type_nm-abap_i
           OR lv_probe_u = gc_builtin_type_nm-abap_int8
           OR lv_probe_u = gc_builtin_type_nm-abap_f
           OR lv_probe_u = gc_builtin_type_nm-abap_p
           OR lv_probe_u = gc_builtin_type_nm-abap_decfloat16
           OR lv_probe_u = gc_builtin_type_nm-abap_decfloat34
           OR lv_probe_u = gc_builtin_type_nm-abap_utclong.
          lv_decl_kind = gc_kind_nm-value.
          EXIT.
        ENDIF.
      ENDWHILE.
    ENDIF.

    IF lv_decl_kind = gc_kind_nm-unknown.
      lv_ok_inline = COND abap_bool(
        WHEN ls_stmt_info-is_local_scope = abap_true
        THEN xsdbool(
           lv_inline_u CP lc_pattern-local_constant     OR
           lv_inline_u CP lc_pattern-local_value        OR
           lv_inline_u CP lc_pattern-local_structure    OR
           lv_inline_u CP lc_pattern-local_table        OR
           lv_inline_u CP lc_pattern-local_data_ref     OR
           lv_inline_u CP lc_pattern-local_macro        OR
           lv_inline_u CP lc_pattern-local_type_struct  OR
           lv_inline_u CP lc_pattern-local_type_table   OR
           lv_inline_u CP lc_pattern-local_field_symbol OR
           lv_inline_u CP lc_pattern-local_object_ref )
    ELSE xsdbool(
           lv_inline_u CP lc_pattern-global_constant     OR
           lv_inline_u CP lc_pattern-global_value        OR
           lv_inline_u CP lc_pattern-global_structure    OR
           lv_inline_u CP lc_pattern-global_table        OR
           lv_inline_u CP lc_pattern-global_data_ref     OR
           lv_inline_u CP lc_pattern-global_macro        OR
           lv_inline_u CP lc_pattern-global_type_struct  OR
           lv_inline_u CP lc_pattern-global_type_table   OR
           lv_inline_u CP lc_pattern-global_field_symbol OR
           lv_inline_u CP lc_pattern-global_object_ref )
      ).
    ELSE.
      lv_ok_inline = COND abap_bool(
        WHEN ls_stmt_info-is_local_scope = abap_true AND lv_decl_kind = gc_kind_nm-data_ref
        THEN xsdbool( lv_inline_u CP lc_pattern-local_data_ref )
        WHEN ls_stmt_info-is_local_scope = abap_true AND lv_decl_kind = gc_kind_nm-object
        THEN xsdbool( lv_inline_u CP lc_pattern-local_object_ref )
        WHEN ls_stmt_info-is_local_scope = abap_true AND lv_decl_kind = gc_kind_nm-table
        THEN xsdbool( lv_inline_u CP lc_pattern-local_table )
        WHEN ls_stmt_info-is_local_scope = abap_true AND lv_decl_kind = gc_kind_nm-structure
        THEN xsdbool( lv_inline_u CP lc_pattern-local_structure )
        WHEN ls_stmt_info-is_local_scope = abap_true
        THEN xsdbool( lv_inline_u CP lc_pattern-local_value )

        WHEN lv_decl_kind = gc_kind_nm-data_ref
        THEN xsdbool( lv_inline_u CP lc_pattern-global_data_ref )
        WHEN lv_decl_kind = gc_kind_nm-object
        THEN xsdbool( lv_inline_u CP lc_pattern-global_object_ref )
        WHEN lv_decl_kind = gc_kind_nm-table
        THEN xsdbool( lv_inline_u CP lc_pattern-global_table )
        WHEN lv_decl_kind = gc_kind_nm-structure
        THEN xsdbool( lv_inline_u CP lc_pattern-global_structure )
        ELSE xsdbool( lv_inline_u CP lc_pattern-global_value )
      ).

      READ TABLE lt_decl_kind_map WITH TABLE KEY name_u = lv_inline_u TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        DELETE TABLE lt_decl_kind_map WITH TABLE KEY name_u = lv_inline_u.
      ENDIF.

      INSERT VALUE gty_name_kind(
        name_u    = lv_inline_u
        kind      = lv_decl_kind
        line_kind = lv_line_kind
      ) INTO TABLE lt_decl_kind_map.
    ENDIF.

    IF lv_ok_inline = abap_false AND lv_decl_kind <> gc_kind_nm-unknown.
      IF ls_stmt_info-is_local_scope = abap_true.
        CASE lv_decl_kind.
          WHEN gc_kind_nm-data_ref.
            MESSAGE w049(z_gsp04_message) WITH gc_msg_nm-inline lv_inline lc_pattern-local_data_ref INTO lv_text.
          WHEN gc_kind_nm-object.
            MESSAGE w049(z_gsp04_message) WITH gc_msg_nm-inline lv_inline lc_pattern-local_object_ref INTO lv_text.
          WHEN gc_kind_nm-table.
            MESSAGE w066(z_gsp04_message) WITH gc_msg_nm-inline lv_inline lc_pattern-local_table INTO lv_text.
          WHEN gc_kind_nm-structure.
            MESSAGE w067(z_gsp04_message) WITH gc_msg_nm-inline lv_inline lc_pattern-local_structure INTO lv_text.
          WHEN OTHERS.
            MESSAGE w068(z_gsp04_message) WITH gc_msg_nm-inline lv_inline lc_pattern-local_value INTO lv_text.
        ENDCASE.
      ELSE.
        CASE lv_decl_kind.
          WHEN gc_kind_nm-data_ref.
            MESSAGE w049(z_gsp04_message) WITH gc_msg_nm-global_inline lv_inline lc_pattern-global_data_ref INTO lv_text.
          WHEN gc_kind_nm-object.
            MESSAGE w049(z_gsp04_message) WITH gc_msg_nm-global_inline lv_inline lc_pattern-global_object_ref INTO lv_text.
          WHEN gc_kind_nm-table.
            MESSAGE w066(z_gsp04_message) WITH gc_msg_nm-global_inline lv_inline lc_pattern-global_table INTO lv_text.
          WHEN gc_kind_nm-structure.
            MESSAGE w067(z_gsp04_message) WITH gc_msg_nm-global_inline lv_inline lc_pattern-global_structure INTO lv_text.
          WHEN OTHERS.
            MESSAGE w068(z_gsp04_message) WITH gc_msg_nm-global_inline lv_inline lc_pattern-global_value INTO lv_text.
        ENDCASE.
      ENDIF.

      APPEND VALUE zst_error(
        rule     = gc_rule_nm-prefix_rule
        sev      = gc_severity-warning
        line     = ls_t-row
        msg      = lv_text
        category = gc_category-naming
      ) TO ct_errors.
    ENDIF.
  ENDLOOP.

  "------------------------------------------------------------
  " C) Regular DATA / CLASS-DATA declarations
  "------------------------------------------------------------
  CLEAR: lv_stmt_idx,
         ls_prev_id,
         lv_stmt_is_inline.

  LOOP AT it_tokens INTO ls_t.
    lv_tok_idx = sy-tabix.

    IF lv_stmt_idx = 0.
      lv_stmt_idx += 1.
      READ TABLE it_stmt_info INDEX lv_stmt_idx INTO ls_stmt_info.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      CLEAR: ls_prev_id,
             lv_stmt_is_inline.

    ELSEIF lv_tok_idx > ls_stmt_info-to.
      lv_stmt_idx += 1.
      READ TABLE it_stmt_info INDEX lv_stmt_idx INTO ls_stmt_info.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      CLEAR: ls_prev_id,
             lv_stmt_is_inline.
    ENDIF.

    IF ls_t-row > iv_curr_src_lines.
      CONTINUE.
    ENDIF.

    " Skip inline DATA(...) declaration handled above
    IF ls_stmt_info-is_data_stmt = abap_true
       AND lv_tok_idx = ls_stmt_info-from.

      READ TABLE it_tokens INDEX ( ls_stmt_info-from + 1 ) INTO ls_next.
      IF sy-subrc = 0
         AND ls_next-str IS NOT INITIAL
         AND ls_next-str(1) = gc_keyword-lparen.
        lv_stmt_is_inline = abap_true.
      ENDIF.
    ENDIF.

    IF ls_stmt_info-is_data_stmt = abap_false
       OR lv_stmt_is_inline = abap_true.
      CONTINUE.
    ENDIF.

    lv_u = to_upper( ls_t-str ).

    IF ls_t-type = gc_token_type-identifier.
      IF lv_u <> gc_keyword-data
         AND lv_u <> gc_keyword-data_col
         AND lv_u <> gc_keyword-class_data
         AND lv_u <> gc_keyword-class_data_col
         AND lv_u <> gc_keyword-type
         AND lv_u <> gc_keyword-like
         AND lv_u <> gc_keyword-value
         AND lv_u <> gc_keyword-ref
         AND lv_u <> gc_keyword-to
         AND lv_u <> gc_keyword-table
         AND lv_u <> gc_keyword-of
         AND lv_u <> gc_keyword-standard
         AND lv_u <> gc_keyword-sorted
         AND lv_u <> gc_keyword-hashed
         AND lv_u <> gc_keyword-with
         AND lv_u <> gc_keyword-key
         AND lv_u <> gc_keyword-default
         AND lv_u <> gc_keyword-empty
         AND lv_u <> gc_keyword-initial
         AND lv_u <> gc_keyword-line
         AND lv_u <> gc_keyword-length.
        ls_prev_id = ls_t.
      ENDIF.
    ENDIF.

    IF lv_u <> gc_keyword-type
       AND lv_u <> gc_keyword-like.
      CONTINUE.
    ENDIF.

    IF ls_prev_id-str IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_name   = ls_prev_id-str.
    lv_name_u = to_upper( lv_name ).
    lv_row    = ls_prev_id-row.

    READ TABLE lt_seen
      WITH TABLE KEY name_u = lv_name_u row = lv_row TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    INSERT VALUE lty_seen(
      name_u = lv_name_u
      row    = lv_row
    ) INTO TABLE lt_seen.

    lv_has_local_prefix = xsdbool(
           lv_inline_u CP lc_pattern-local_constant     OR
           lv_inline_u CP lc_pattern-local_value        OR
           lv_inline_u CP lc_pattern-local_structure    OR
           lv_inline_u CP lc_pattern-local_table        OR
           lv_inline_u CP lc_pattern-local_data_ref     OR
           lv_inline_u CP lc_pattern-local_macro        OR
           lv_inline_u CP lc_pattern-local_type_struct  OR
           lv_inline_u CP lc_pattern-local_type_table   OR
           lv_inline_u CP lc_pattern-local_field_symbol OR
           lv_inline_u CP lc_pattern-local_object_ref   ).


    CLEAR: lv_decl_kind,
           lv_line_kind.
    lv_decl_kind = gc_kind_nm-value.


    lv_probe_idx = lv_tok_idx.
    WHILE lv_probe_idx < ls_stmt_info-to.
      lv_probe_idx += 1.

      READ TABLE it_tokens INDEX lv_probe_idx INTO ls_probe.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_probe_u = to_upper( ls_probe-str ).

      IF lv_probe_u = gc_keyword-ref.
        lv_decl_kind = gc_kind_nm-object.
        EXIT.
      ENDIF.

      IF lv_probe_u = gc_keyword-line.
        READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO ls_next.
        IF sy-subrc = 0.
          lv_u = to_upper( ls_next-str ).

          IF lv_u = gc_keyword-of.
            READ TABLE it_tokens INDEX ( lv_probe_idx + 2 ) INTO ls_next.
            IF sy-subrc = 0.
              lv_ref_name = ls_next-str.
              SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
              lv_ref_name_u = to_upper( lv_ref_name ).

              " 1) Resolve from declaration map built in this method
              READ TABLE lt_decl_kind_map WITH TABLE KEY name_u = lv_ref_name_u INTO ls_kind.
              IF sy-subrc = 0.
                IF ls_kind-kind = gc_kind_nm-table.
                  IF ls_kind-line_kind IS NOT INITIAL.
                    lv_decl_kind = ls_kind-line_kind.
                  ELSE.
                    lv_decl_kind = gc_kind_nm-structure.
                  ENDIF.
                ELSE.
                  lv_decl_kind = ls_kind-kind.
                ENDIF.
                EXIT.
              ENDIF.

              " 2) Resolve from TYPES map
              lv_resolved_kind = ``.     "CLEAR
              lv_resolved_line = ``.     "CLEAR

              nm_resolve_type_kind(
                EXPORTING
                  iv_type_name  = lv_ref_name_u
                IMPORTING
                  ev_kind       = lv_resolved_kind
                  ev_line_kind  = lv_resolved_line
                CHANGING
                  ct_type_cache = lt_type_cache ).

              IF lv_resolved_kind = gc_kind_nm-table.
                IF lv_resolved_line IS NOT INITIAL.
                  lv_line_kind = lv_resolved_line.
                ELSE.
                  lv_line_kind = gc_kind_nm-structure.
                ENDIF.
              ELSEIF lv_resolved_kind IS NOT INITIAL.
                lv_line_kind = lv_resolved_kind.
              ENDIF.
              EXIT.
            ENDIF.

            " 3) Resolve from DDIC/runtime type info
            nm_resolve_type_kind(
              EXPORTING
                iv_type_name  = lv_ref_name_u
              IMPORTING
                ev_kind       = lv_decl_kind
                ev_line_kind  = lv_line_kind
              CHANGING
                ct_type_cache = lt_type_cache ).
            EXIT.
          ENDIF.

        ENDIF.
      ENDIF.

      IF lv_probe_u = gc_keyword-table
         OR lv_probe_u = gc_keyword-standard
         OR lv_probe_u = gc_keyword-sorted
         OR lv_probe_u = gc_keyword-hashed.
        lv_decl_kind = gc_kind_nm-table.
        CONTINUE.
      ENDIF.

      IF lv_probe_u = gc_keyword-of
        AND lv_decl_kind = gc_kind_nm-table.

        CLEAR: lv_ref_name,
               lv_ref_name_u,
               lv_resolved_kind,
               lv_resolved_line.

        READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO ls_next.
        IF sy-subrc = 0.
          lv_ref_name = ls_next-str.
          SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
          lv_ref_name_u = to_upper( lv_ref_name ).

          IF lv_ref_name_u = gc_builtin_type_nm-abap_string
             OR lv_ref_name_u = gc_builtin_type_nm-abap_xstring
             OR lv_ref_name_u = gc_builtin_type_nm-abap_c
             OR lv_ref_name_u = gc_builtin_type_nm-abap_n
             OR lv_ref_name_u = gc_builtin_type_nm-abap_d
             OR lv_ref_name_u = gc_builtin_type_nm-abap_t
             OR lv_ref_name_u = gc_builtin_type_nm-abap_i
             OR lv_ref_name_u = gc_builtin_type_nm-abap_int8
             OR lv_ref_name_u = gc_builtin_type_nm-abap_f
             OR lv_ref_name_u = gc_builtin_type_nm-abap_p
             OR lv_ref_name_u = gc_builtin_type_nm-abap_decfloat16
             OR lv_ref_name_u = gc_builtin_type_nm-abap_decfloat34
             OR lv_ref_name_u = gc_builtin_type_nm-abap_utclong.
            lv_line_kind = gc_kind_nm-value.
            EXIT.
          ENDIF.

          READ TABLE lt_type_kind WITH TABLE KEY name_u = lv_ref_name_u INTO ls_kind.
          IF sy-subrc = 0.
            IF ls_kind-kind = gc_kind_nm-table.
              IF ls_kind-line_kind IS NOT INITIAL.
                lv_line_kind = ls_kind-line_kind.
              ELSE.
                lv_line_kind = gc_kind_nm-structure.
              ENDIF.
            ELSE.
              lv_line_kind = ls_kind-kind.
            ENDIF.
            EXIT.
          ENDIF.

          CLEAR: lv_resolved_kind,
                 lv_resolved_line.

          nm_resolve_type_kind(
            EXPORTING
              iv_type_name  = lv_ref_name_u
            IMPORTING
              ev_kind       = lv_resolved_kind
              ev_line_kind  = lv_resolved_line
            CHANGING
              ct_type_cache = lt_type_cache ).

          IF lv_resolved_kind = gc_kind_nm-table.
            IF lv_resolved_line IS NOT INITIAL.
              lv_line_kind = lv_resolved_line.
            ELSE.
              lv_line_kind = gc_kind_nm-structure.
            ENDIF.
          ELSEIF lv_resolved_kind IS NOT INITIAL.
            lv_line_kind = lv_resolved_kind.
          ENDIF.
        ENDIF.
        EXIT.
      ENDIF.

      IF lv_probe_u = gc_builtin_type_nm-abap_string
         OR lv_probe_u = gc_builtin_type_nm-abap_xstring
         OR lv_probe_u = gc_builtin_type_nm-abap_c
         OR lv_probe_u = gc_builtin_type_nm-abap_n
         OR lv_probe_u = gc_builtin_type_nm-abap_d
         OR lv_probe_u = gc_builtin_type_nm-abap_t
         OR lv_probe_u = gc_builtin_type_nm-abap_i
         OR lv_probe_u = gc_builtin_type_nm-abap_int8
         OR lv_probe_u = gc_builtin_type_nm-abap_f
         OR lv_probe_u = gc_builtin_type_nm-abap_p
         OR lv_probe_u = gc_builtin_type_nm-abap_decfloat16
         OR lv_probe_u = gc_builtin_type_nm-abap_decfloat34
         OR lv_probe_u = gc_builtin_type_nm-abap_utclong.
        lv_decl_kind = gc_kind_nm-value.
        EXIT.
      ENDIF.

      IF ls_probe-type = gc_token_type-identifier.
        lv_ref_name = ls_probe-str.

        "TYPE zcl_program_fetch=>gty_t_class_source
        READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO DATA(ls_type_sep_data).
        IF sy-subrc = 0
           AND to_upper( ls_type_sep_data-str ) = gc_keyword-static_call.

          READ TABLE it_tokens INDEX ( lv_probe_idx + 2 ) INTO DATA(ls_type_comp_data).
          IF sy-subrc = 0
             AND ls_type_comp_data-type = gc_token_type-identifier.
            lv_ref_name = |{ lv_ref_name }{ gc_keyword-static_call }{ ls_type_comp_data-str }|.
            lv_probe_idx = lv_probe_idx + 2.
          ENDIF.
        ENDIF.

        SHIFT lv_ref_name LEFT DELETING LEADING gc_keyword-exclamation_mark.
        lv_ref_name_u = to_upper( lv_ref_name ).

        READ TABLE lt_type_kind WITH TABLE KEY name_u = lv_ref_name_u INTO ls_kind.
        IF sy-subrc = 0.
          lv_decl_kind = ls_kind-kind.
          lv_line_kind = ls_kind-line_kind.
          EXIT.
        ENDIF.

        READ TABLE lt_decl_kind_map WITH TABLE KEY name_u = lv_ref_name_u INTO ls_kind.
        IF sy-subrc = 0.
          lv_decl_kind = ls_kind-kind.
          lv_line_kind = ls_kind-line_kind.
          EXIT.
        ENDIF.

        nm_resolve_type_kind(
          EXPORTING
            iv_type_name  = lv_ref_name_u
          IMPORTING
            ev_kind       = lv_decl_kind
            ev_line_kind  = lv_line_kind
          CHANGING
            ct_type_cache = lt_type_cache ).
        EXIT.
      ENDIF.
    ENDWHILE.

    IF ls_stmt_info-is_local_scope = abap_false.
      READ TABLE ct_global_decl
        WITH TABLE KEY name_u = lv_name_u TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        INSERT VALUE gty_global_decl(
          name_u = lv_name_u
          name   = lv_name
          row    = lv_row
        ) INTO TABLE ct_global_decl.
      ENDIF.
    ENDIF.

    READ TABLE lt_decl_kind_map WITH TABLE KEY name_u = lv_name_u TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      DELETE TABLE lt_decl_kind_map WITH TABLE KEY name_u = lv_name_u.
    ENDIF.

    INSERT VALUE gty_name_kind(
      name_u    = lv_name_u
      kind      = lv_decl_kind
      line_kind = lv_line_kind
    ) INTO TABLE lt_decl_kind_map.

    lv_ok = COND abap_bool(
      WHEN ls_stmt_info-is_local_scope = abap_true AND lv_decl_kind = gc_kind_nm-data_ref
      THEN xsdbool( lv_name_u CP lc_pattern-local_data_ref )
      WHEN ls_stmt_info-is_local_scope = abap_true AND lv_decl_kind = gc_kind_nm-object
      THEN xsdbool( lv_name_u CP lc_pattern-local_object_ref )
      WHEN ls_stmt_info-is_local_scope = abap_true AND lv_decl_kind = gc_kind_nm-table
      THEN xsdbool( lv_name_u CP lc_pattern-local_table )
      WHEN ls_stmt_info-is_local_scope = abap_true AND lv_decl_kind = gc_kind_nm-structure
      THEN xsdbool( lv_name_u CP lc_pattern-local_structure )
      WHEN ls_stmt_info-is_local_scope = abap_true
      THEN xsdbool( lv_name_u CP lc_pattern-local_value )

      WHEN lv_decl_kind = gc_kind_nm-data_ref
      THEN xsdbool( lv_name_u CP lc_pattern-global_data_ref )
      WHEN lv_decl_kind = gc_kind_nm-object
      THEN xsdbool( lv_name_u CP lc_pattern-global_object_ref )
      WHEN lv_decl_kind = gc_kind_nm-table
      THEN xsdbool( lv_name_u CP lc_pattern-global_table )
      WHEN lv_decl_kind = gc_kind_nm-structure
      THEN xsdbool( lv_name_u CP lc_pattern-global_structure )
      ELSE xsdbool( lv_name_u CP lc_pattern-global_value )
    ).

    IF lv_ok = abap_false.
      IF ls_stmt_info-is_local_scope = abap_true.
        CASE lv_decl_kind.
          WHEN gc_kind_nm-data_ref.
            MESSAGE w049(z_gsp04_message) WITH gc_msg_nm-local lv_name lc_pattern-local_data_ref INTO lv_text.
          WHEN gc_kind_nm-object.
            MESSAGE w049(z_gsp04_message) WITH gc_msg_nm-local lv_name lc_pattern-local_object_ref INTO lv_text.
          WHEN gc_kind_nm-table.
            MESSAGE w066(z_gsp04_message) WITH gc_msg_nm-local lv_name lc_pattern-local_table INTO lv_text.
          WHEN gc_kind_nm-structure.
            MESSAGE w067(z_gsp04_message) WITH gc_msg_nm-local lv_name lc_pattern-local_structure INTO lv_text.
          WHEN OTHERS.
            MESSAGE w068(z_gsp04_message) WITH gc_msg_nm-local lv_name lc_pattern-local_value INTO lv_text.
        ENDCASE.
      ELSE.
        CASE lv_decl_kind.
          WHEN gc_kind_nm-data_ref.
            MESSAGE w049(z_gsp04_message) WITH gc_msg_nm-global lv_name lc_pattern-global_data_ref INTO lv_text.
          WHEN gc_kind_nm-object.
            MESSAGE w049(z_gsp04_message) WITH gc_msg_nm-global lv_name lc_pattern-global_object_ref INTO lv_text.
          WHEN gc_kind_nm-table.
            MESSAGE w066(z_gsp04_message) WITH gc_msg_nm-global lv_name lc_pattern-global_table INTO lv_text.
          WHEN gc_kind_nm-structure.
            MESSAGE w067(z_gsp04_message) WITH gc_msg_nm-global lv_name lc_pattern-global_structure INTO lv_text.
          WHEN OTHERS.
            MESSAGE w068(z_gsp04_message) WITH gc_msg_nm-global lv_name lc_pattern-global_value INTO lv_text.
        ENDCASE.
      ENDIF.

      IF ls_stmt_info-is_local_scope = abap_true.
        APPEND VALUE zst_error(
          rule     = gc_rule_nm-prefix_rule
          sev      = gc_severity-warning
          line     = lv_row
          msg      = lv_text
          category = gc_category-naming
        ) TO ct_errors.
      ELSE.
        APPEND VALUE gty_pending(
          name            = lv_name
          name_u          = lv_name_u
          row             = lv_row
          msg             = lv_text
          is_local_prefix = lv_has_local_prefix
        ) TO ct_pending.
      ENDIF.
    ENDIF.
  ENDLOOP.

  "------------------------------------------------------------
  " D) Global usage collection
  "------------------------------------------------------------
  CLEAR: lv_stmt_idx,
         ls_prev_id,
         lv_stmt_is_inline.

  LOOP AT it_tokens INTO ls_t.
    lv_tok_idx = sy-tabix.

    IF lv_stmt_idx = 0.
      lv_stmt_idx += 1.
      READ TABLE it_stmt_info INDEX lv_stmt_idx INTO ls_stmt_info.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

    ELSEIF lv_tok_idx > ls_stmt_info-to.
      lv_stmt_idx += 1.
      READ TABLE it_stmt_info INDEX lv_stmt_idx INTO ls_stmt_info.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
    ENDIF.

    IF ls_stmt_info-is_local_scope = abap_false
       OR ls_t-type <> gc_token_type-identifier.
      CONTINUE.
    ENDIF.

    lv_id_u = to_upper( ls_t-str ).

    READ TABLE ct_global_decl
      WITH TABLE KEY name_u = lv_id_u TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    READ TABLE ct_use
      WITH TABLE KEY name_u = lv_id_u
      INTO DATA(ls_u).
    IF sy-subrc <> 0.
      CLEAR ls_u.
      ls_u-name_u = lv_id_u.
    ENDIF.

    INSERT ls_stmt_info-current_routine INTO TABLE ls_u-routines.
    MODIFY TABLE ct_use FROM ls_u.
  ENDLOOP.
ENDMETHOD.


METHOD nm_resolve_type_kind.

  "============================================================
  " Naming policy - customizable by project/company
  "============================================================
  CONSTANTS:
    BEGIN OF lc_pattern,
      global_structure  TYPE string VALUE 'GTY_*',
      global_table_type TYPE string VALUE 'GTY_T_*',
      local_structure   TYPE string VALUE 'LTY_*',
      local_table_type  TYPE string VALUE 'LTY_T_*',
    END OF lc_pattern.

  DATA(lv_type_name_upper) = to_upper( iv_type_name ).

  DATA lo_runtime_type_descr TYPE REF TO cl_abap_typedescr.
  DATA lo_table_type_descr   TYPE REF TO cl_abap_tabledescr.
  DATA lo_table_line_descr   TYPE REF TO cl_abap_typedescr.
  DATA lv_cache_allowed      TYPE abap_bool VALUE abap_true.
  DATA lv_fallback_name_u    TYPE string.
  DATA lv_dummy_name_u       TYPE string.

  SHIFT lv_type_name_upper LEFT DELETING LEADING gc_keyword-exclamation_mark.

  lv_fallback_name_u = lv_type_name_upper.

  "Handle class/interface component type:
  "Example: ZCL_PROGRAM_FETCH=>GTY_T_CLASS_SOURCE
  "Fallback should check only GTY_T_CLASS_SOURCE
  IF lv_fallback_name_u CS gc_keyword-static_call.
    SPLIT lv_fallback_name_u AT gc_keyword-static_call
      INTO lv_dummy_name_u lv_fallback_name_u.
  ENDIF.

  CLEAR: ev_kind,
         ev_line_kind.

  IF lv_type_name_upper IS INITIAL.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " Catch invalid token must not go into RTTI
  "------------------------------------------------------------
  IF lv_type_name_upper = gc_keyword-equal
   OR lv_type_name_upper = gc_keyword-hash
   OR lv_type_name_upper = gc_keyword-lparen
   OR lv_type_name_upper = gc_keyword-rparen
   OR lv_type_name_upper CS gc_keyword-lparen
   OR lv_type_name_upper CS gc_keyword-rparen
   OR lv_type_name_upper CS gc_keyword-comma
   OR lv_type_name_upper CS gc_keyword-colon
   OR lv_type_name_upper CS gc_keyword-semicolon
   OR lv_type_name_upper CS gc_keyword-quote
   OR lv_type_name_upper CS gc_keyword-empty_single_bt
   OR lv_type_name_upper CS gc_keyword-empty_single_pipe
   OR lv_type_name_upper CP gc_keyword-invalid_assign_pat.

    ev_kind          = gc_kind_nm-value.
    ev_line_kind     = ``.
    lv_cache_allowed = abap_false.
    RETURN.

  ENDIF.

  "------------------------------------------------------------
  " 1) Cache first - avoid repeated RTTI/DDIC calls
  "------------------------------------------------------------
  READ TABLE ct_type_cache
    ASSIGNING FIELD-SYMBOL(<lfs_cached_type>)
    WITH TABLE KEY name_u = lv_type_name_upper.

  IF sy-subrc = 0.
    ev_kind      = <lfs_cached_type>-kind.
    ev_line_kind = <lfs_cached_type>-line_kind.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " 2) Built-in ABAP types are scalar/value types
  "------------------------------------------------------------
  IF lv_type_name_upper = gc_builtin_type_nm-abap_string
     OR lv_type_name_upper = gc_builtin_type_nm-abap_xstring
     OR lv_type_name_upper = gc_builtin_type_nm-abap_c
     OR lv_type_name_upper = gc_builtin_type_nm-abap_n
     OR lv_type_name_upper = gc_builtin_type_nm-abap_d
     OR lv_type_name_upper = gc_builtin_type_nm-abap_t
     OR lv_type_name_upper = gc_builtin_type_nm-abap_i
     OR lv_type_name_upper = gc_builtin_type_nm-abap_int8
     OR lv_type_name_upper = gc_builtin_type_nm-abap_f
     OR lv_type_name_upper = gc_builtin_type_nm-abap_p
     OR lv_type_name_upper = gc_builtin_type_nm-abap_decfloat16
     OR lv_type_name_upper = gc_builtin_type_nm-abap_decfloat34
     OR lv_type_name_upper = gc_builtin_type_nm-abap_utclong.

    ev_kind = gc_kind_nm-value.

  ELSE.

    "----------------------------------------------------------
    " 3) Try real runtime/DDIC type resolution
    "----------------------------------------------------------
    cl_abap_typedescr=>describe_by_name(
      EXPORTING
        p_name         = lv_type_name_upper
      RECEIVING
        p_descr_ref    = lo_runtime_type_descr
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2 ).

    IF sy-subrc = 0 AND lo_runtime_type_descr IS BOUND.

      IF lo_runtime_type_descr IS INSTANCE OF cl_abap_tabledescr.
        ev_kind = gc_kind_nm-table.

        lo_table_type_descr ?= lo_runtime_type_descr.
        lo_table_line_descr = lo_table_type_descr->get_table_line_type( ).

        IF lo_table_line_descr IS INSTANCE OF cl_abap_structdescr.
          ev_line_kind = gc_kind_nm-structure.
        ELSEIF lo_table_line_descr IS INSTANCE OF cl_abap_refdescr.
          ev_line_kind = gc_kind_nm-object.
        ELSE.
          ev_line_kind = gc_kind_nm-value.
        ENDIF.

      ELSEIF lo_runtime_type_descr IS INSTANCE OF cl_abap_structdescr.
        ev_kind = gc_kind_nm-structure.

      ELSEIF lo_runtime_type_descr IS INSTANCE OF cl_abap_refdescr.
        ev_kind = gc_kind_nm-object.

      ELSE.
        ev_kind = gc_kind_nm-value.
      ENDIF.

    "----------------------------------------------------------
    " 4) Project/company fallback naming convention
    "----------------------------------------------------------
    ELSEIF lv_fallback_name_u CP lc_pattern-global_table_type
        OR lv_fallback_name_u CP lc_pattern-local_table_type.

      ev_kind      = gc_kind_nm-table.
      ev_line_kind = gc_kind_nm-unknown.

    ELSEIF lv_fallback_name_u CP lc_pattern-global_structure
        OR lv_fallback_name_u CP lc_pattern-local_structure.

      ev_kind = gc_kind_nm-structure.

    ELSE.
      ev_kind          = gc_kind_nm-value.
      ev_line_kind     = ``.
      lv_cache_allowed = abap_false.
    ENDIF.
  ENDIF.

  "------------------------------------------------------------
  " 5) Store resolved result in cache
  "------------------------------------------------------------
  IF lv_cache_allowed = abap_true.
    READ TABLE ct_type_cache
      WITH TABLE KEY name_u = lv_type_name_upper
      TRANSPORTING NO FIELDS.

    IF sy-subrc <> 0.
      INSERT VALUE gty_name_kind(
        name_u    = lv_type_name_upper
        kind      = ev_kind
        line_kind = ev_line_kind
      ) INTO TABLE ct_type_cache.
    ENDIF.
  ENDIF.

ENDMETHOD.


METHOD nm_resolve_sig_kind.

  DATA: lv_probe_idx      TYPE sy-tabix,
        lv_tok_u          TYPE string,
        lv_type_name      TYPE string,
        lv_type_name_u    TYPE string,
        lv_resolved_kind  TYPE gty_nm_kind,
        lv_line_kind      TYPE gty_nm_kind,
        lv_table_context  TYPE abap_bool.

  CLEAR: ev_kind,
         ev_last_idx.

  ev_kind         = gc_kind_nm-value.
  ev_last_idx     = iv_from.
  lv_probe_idx    = iv_from.
  lv_table_context = abap_false.

  WHILE lv_probe_idx < iv_to.
    lv_probe_idx += 1.

    READ TABLE it_tokens INDEX lv_probe_idx INTO DATA(ls_tok).
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    lv_tok_u = to_upper( ls_tok-str ).

    IF lv_tok_u = gc_keyword-comma
       OR lv_tok_u = gc_keyword-dot.
      EXIT.
    ENDIF.

    IF lv_tok_u = gc_keyword-type
       OR lv_tok_u = gc_keyword-like.
      CONTINUE.
    ENDIF.

    " TYPE REF TO <class/data>
    IF lv_tok_u = gc_keyword-ref.
      READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO DATA(ls_ref_to).
      IF sy-subrc = 0
         AND to_upper( ls_ref_to-str ) = gc_keyword-to.

        READ TABLE it_tokens INDEX ( lv_probe_idx + 2 ) INTO DATA(ls_ref_target).
        IF sy-subrc = 0.
          DATA(lv_ref_target_u) = to_upper( ls_ref_target-str ).

          IF lv_ref_target_u = gc_keyword-data.
            ev_kind = gc_kind_nm-data_ref.
          ELSE.
            ev_kind = gc_kind_nm-object.
          ENDIF.

          lv_probe_idx = lv_probe_idx + 2.
          EXIT.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_tok_u = gc_keyword-table
       OR lv_tok_u = gc_keyword-standard
       OR lv_tok_u = gc_keyword-sorted
       OR lv_tok_u = gc_keyword-hashed.
      ev_kind = gc_kind_nm-table.
      lv_table_context = abap_true.
      CONTINUE.
    ENDIF.

    IF lv_tok_u = gc_keyword-line.
      READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO DATA(ls_next).
      IF sy-subrc = 0
         AND to_upper( ls_next-str ) = gc_keyword-of.
        ev_kind = gc_kind_nm-structure.
        ev_last_idx = lv_probe_idx + 1.
        EXIT.
      ENDIF.
    ENDIF.

    IF ls_tok-type <> gc_token_type-identifier.
      CONTINUE.
    ENDIF.

    lv_type_name = ls_tok-str.

    " TYPE zcl_program_fetch=>gty_t_class_source
    READ TABLE it_tokens INDEX ( lv_probe_idx + 1 ) INTO DATA(ls_type_sep_sig).
    IF sy-subrc = 0
       AND to_upper( ls_type_sep_sig-str ) = gc_keyword-static_call.

      READ TABLE it_tokens INDEX ( lv_probe_idx + 2 ) INTO DATA(ls_type_comp_sig).
      IF sy-subrc = 0
         AND ls_type_comp_sig-type = gc_token_type-identifier.

        lv_type_name = |{ lv_type_name }{ gc_keyword-static_call }{ ls_type_comp_sig-str }|.
        lv_probe_idx = lv_probe_idx + 2.

      ENDIF.
    ENDIF.

    REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_type_name WITH ''.
    REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_type_name WITH ''.
    CONDENSE lv_type_name NO-GAPS.
    SHIFT lv_type_name LEFT DELETING LEADING gc_keyword-exclamation_mark.

    lv_type_name_u = to_upper( lv_type_name ).

    CLEAR: lv_resolved_kind,
           lv_line_kind.

    nm_resolve_type_kind(
      EXPORTING
        iv_type_name  = lv_type_name_u
      IMPORTING
        ev_kind       = lv_resolved_kind
        ev_line_kind  = lv_line_kind
      CHANGING
        ct_type_cache = ct_type_cache ).

    IF lv_table_context = abap_true.
      ev_kind = gc_kind_nm-table.
    ELSEIF lv_resolved_kind IS INITIAL.
      ev_kind = gc_kind_nm-value.
    ELSE.
      ev_kind = lv_resolved_kind.
    ENDIF.

    EXIT.
  ENDWHILE.

  ev_last_idx = lv_probe_idx.

ENDMETHOD.


METHOD cc_unused_text_symbols.

  CLEAR rt_errors.

  TYPES: BEGIN OF lty_used,
           key TYPE textpool-key,
         END OF lty_used.

  TYPES lty_t_used TYPE HASHED TABLE OF lty_used WITH UNIQUE KEY key.

  DATA lt_textpool         TYPE STANDARD TABLE OF textpool WITH EMPTY KEY.
  DATA lt_used             TYPE lty_t_used.
  DATA lt_src_curr         TYPE gty_t_src_line.
  DATA lt_src_part_text    TYPE string_table.
  DATA lt_words_inc_text   TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  DATA lt_prog_queue_text  TYPE STANDARD TABLE OF progname WITH EMPTY KEY.

  "------------------------------------------------------------
  " Added:
  " Hash set used only for fast duplicate check.
  " lt_prog_queue_text still keeps FIFO queue order.
  "------------------------------------------------------------
  DATA lt_prog_queued_text TYPE HASHED TABLE OF progname
                            WITH UNIQUE KEY table_line.

  DATA lt_prog_seen_text   TYPE HASHED TABLE OF progname
                            WITH UNIQUE KEY table_line.

  DATA lt_method_includes  TYPE seop_methods_w_include.

  DATA lv_text             TYPE string.
  DATA lv_textpool_prog    TYPE progname.
  DATA lv_classpool_prog   TYPE progname.
  DATA lv_inc_prog         TYPE progname.
  DATA lv_word1            TYPE string.
  DATA lv_word2            TYPE string.
  DATA lv_i                TYPE i.
  DATA lv_off              TYPE i.
  DATA lv_name             TYPE string.
  DATA lv_stack_idx        TYPE i.

  CLEAR: lv_textpool_prog,
         lt_used,
         lt_prog_queue_text,
         lt_prog_queued_text,
         lt_prog_seen_text,
         lt_method_includes,
         lv_classpool_prog.

  CASE is_ctx-obj_type.

    WHEN gc_obj_type-prog
      OR gc_obj_type-reps
      OR gc_obj_type-incl.

      IF is_ctx-main_prog IS NOT INITIAL.
        lv_textpool_prog = is_ctx-main_prog.
      ELSEIF is_ctx-obj_name IS NOT INITIAL.
        lv_textpool_prog = is_ctx-obj_name.
      ELSEIF is_ctx-include IS NOT INITIAL.
        lv_textpool_prog = is_ctx-include.
      ENDIF.

      IF lv_textpool_prog IS NOT INITIAL.
        lv_textpool_prog = to_upper( lv_textpool_prog ).
        APPEND lv_textpool_prog TO lt_prog_queue_text.
        INSERT lv_textpool_prog INTO TABLE lt_prog_queued_text.
      ENDIF.

    WHEN gc_obj_type-fugr.

      IF is_ctx-main_prog IS NOT INITIAL.
        lv_textpool_prog = is_ctx-main_prog.
      ELSEIF is_ctx-obj_name IS NOT INITIAL.
        lv_textpool_prog = |{ gc_obj_type-sapl }{ is_ctx-obj_name }|.
      ENDIF.

      IF lv_textpool_prog IS NOT INITIAL.
        lv_textpool_prog = to_upper( lv_textpool_prog ).
        APPEND lv_textpool_prog TO lt_prog_queue_text.
        INSERT lv_textpool_prog INTO TABLE lt_prog_queued_text.
      ENDIF.

    WHEN gc_obj_type-func
      OR gc_obj_type-fm.

      IF is_ctx-main_prog IS NOT INITIAL.
        lv_textpool_prog = is_ctx-main_prog.
      ENDIF.

      IF lv_textpool_prog IS NOT INITIAL.
        lv_textpool_prog = to_upper( lv_textpool_prog ).
        APPEND lv_textpool_prog TO lt_prog_queue_text.
        INSERT lv_textpool_prog INTO TABLE lt_prog_queued_text.
      ENDIF.

    WHEN gc_obj_type-clas.

      IF is_ctx-main_prog IS NOT INITIAL.
        CLEAR lt_src_part_text.

        READ REPORT is_ctx-main_prog INTO lt_src_part_text.

        IF sy-subrc = 0 AND lt_src_part_text IS NOT INITIAL.
          lv_classpool_prog = is_ctx-main_prog.
        ENDIF.
      ENDIF.

      IF lv_classpool_prog IS INITIAL
         AND is_ctx-obj_name IS NOT INITIAL.

        TRY.
            lv_classpool_prog =
              cl_oo_classname_service=>get_classpool_name(
                clsname = CONV seoclsname( is_ctx-obj_name ) ).

          CATCH cx_root.
            CLEAR lv_classpool_prog.
        ENDTRY.

      ENDIF.

      lv_textpool_prog = lv_classpool_prog.

      IF lv_textpool_prog IS NOT INITIAL.
        lv_textpool_prog = to_upper( lv_textpool_prog ).
        APPEND lv_textpool_prog TO lt_prog_queue_text.
        INSERT lv_textpool_prog INTO TABLE lt_prog_queued_text.
      ENDIF.

      IF is_ctx-obj_name IS NOT INITIAL.

        TRY.
            lt_method_includes =
              cl_oo_classname_service=>get_all_method_includes(
                CONV seoclsname( is_ctx-obj_name ) ).

          CATCH cx_root.
            CLEAR lt_method_includes.
        ENDTRY.

      ENDIF.

      LOOP AT lt_method_includes ASSIGNING FIELD-SYMBOL(<lfs_method_inc_text>).

        lv_inc_prog = <lfs_method_inc_text>-incname.

        IF lv_inc_prog IS INITIAL.
          CONTINUE.
        ENDIF.

        lv_inc_prog = to_upper( lv_inc_prog ).

        "--------------------------------------------------------
        " Changed:
        " Old logic checked lt_prog_queue_text with READ TABLE
        " WITH KEY, which is linear search on a standard queue.
        "
        " New logic checks lt_prog_queued_text hashed set.
        "--------------------------------------------------------
        READ TABLE lt_prog_queued_text
          WITH TABLE KEY table_line = lv_inc_prog
          TRANSPORTING NO FIELDS.

        IF sy-subrc <> 0.
          APPEND lv_inc_prog TO lt_prog_queue_text.
          INSERT lv_inc_prog INTO TABLE lt_prog_queued_text.
        ENDIF.

      ENDLOOP.

    WHEN OTHERS.
      CLEAR lv_textpool_prog.

  ENDCASE.

  IF lv_textpool_prog IS NOT INITIAL.

    READ TEXTPOOL lv_textpool_prog INTO lt_textpool LANGUAGE sy-langu.

    IF sy-subrc = 0 AND lt_textpool IS NOT INITIAL.

      WHILE lt_prog_queue_text IS NOT INITIAL.

        READ TABLE lt_prog_queue_text INDEX 1 INTO DATA(lv_prog_text).
        DELETE lt_prog_queue_text INDEX 1.

        IF sy-subrc <> 0 OR lv_prog_text IS INITIAL.
          CONTINUE.
        ENDIF.

        READ TABLE lt_prog_seen_text
          WITH TABLE KEY table_line = lv_prog_text
          TRANSPORTING NO FIELDS.

        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.

        INSERT lv_prog_text INTO TABLE lt_prog_seen_text.

        CLEAR lt_src_part_text.

        READ REPORT lv_prog_text INTO lt_src_part_text.

        IF sy-subrc <> 0 OR lt_src_part_text IS INITIAL.
          CONTINUE.
        ENDIF.

        lt_src_curr = cc_preprocess_source( lt_src_part_text ).

        LOOP AT lt_src_curr INTO DATA(ls_src_text).

          DATA(lv_work_inc_text) = ls_src_text-no_comment.
          lv_work_inc_text = to_upper( lv_work_inc_text ).

          IF lv_work_inc_text IS INITIAL.
            CONTINUE.
          ENDIF.

          CLEAR: lt_words_inc_text,
                 lv_word1,
                 lv_word2.

          SPLIT lv_work_inc_text AT space INTO TABLE lt_words_inc_text.
          DELETE lt_words_inc_text WHERE table_line IS INITIAL.

          READ TABLE lt_words_inc_text INDEX 1 INTO lv_word1.
          READ TABLE lt_words_inc_text INDEX 2 INTO lv_word2.

          lv_word1 = to_upper( lv_word1 ).
          lv_word2 = to_upper( lv_word2 ).

          IF lv_word1 = gc_keyword-include
             AND lv_word2 IS NOT INITIAL.

            lv_inc_prog = lv_word2.

            REPLACE ALL OCCURRENCES OF gc_keyword-dot
              IN lv_inc_prog WITH ''.

            REPLACE ALL OCCURRENCES OF gc_keyword-quote
              IN lv_inc_prog WITH ''.

            CONDENSE lv_inc_prog NO-GAPS.
            lv_inc_prog = to_upper( lv_inc_prog ).

            IF lv_inc_prog IS NOT INITIAL
               AND lv_inc_prog <> gc_keyword-methods
               AND lv_inc_prog <> gc_keyword-type
               AND lv_inc_prog <> gc_keyword-structure.

              READ TABLE lt_prog_seen_text
                WITH TABLE KEY table_line = lv_inc_prog
                TRANSPORTING NO FIELDS.

              IF sy-subrc <> 0.

                "------------------------------------------------
                " Changed:
                " Do not search lt_prog_queue_text by key.
                " Use hashed queued set instead.
                "------------------------------------------------
                READ TABLE lt_prog_queued_text
                  WITH TABLE KEY table_line = lv_inc_prog
                  TRANSPORTING NO FIELDS.

                IF sy-subrc <> 0.
                  APPEND lv_inc_prog TO lt_prog_queue_text.
                  INSERT lv_inc_prog INTO TABLE lt_prog_queued_text.
                ENDIF.

              ENDIF.

            ENDIF.

          ENDIF.

          CLEAR: lv_i,
                 lv_off,
                 lv_name.

          WHILE lv_i < strlen( lv_work_inc_text ).

            lv_name = lv_work_inc_text+lv_i.

            FIND FIRST OCCURRENCE OF PCRE gc_clean_code-text_symbol
              IN lv_name IGNORING CASE
              MATCH OFFSET lv_off
              MATCH LENGTH lv_stack_idx.

            IF sy-subrc <> 0.
              EXIT.
            ENDIF.

            lv_word1 = lv_name+lv_off(lv_stack_idx).
            lv_word1 = to_upper( lv_word1 ).

            IF strlen( lv_word1 ) >= 8.

              INSERT VALUE lty_used(
                key = lv_word1+5(3)
              ) INTO TABLE lt_used.

            ENDIF.

            lv_i += lv_off + lv_stack_idx.

          ENDWHILE.

        ENDLOOP.

      ENDWHILE.

      LOOP AT lt_textpool INTO DATA(ls_text)
           WHERE id = gc_clean_code-textpool_i
             AND key IS NOT INITIAL.

        READ TABLE lt_used
          WITH TABLE KEY key = ls_text-key
          TRANSPORTING NO FIELDS.

        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.

        MESSAGE w024(z_gsp04_message)
          WITH |{ ls_text-key }| ls_text-entry
          INTO lv_text.

        APPEND VALUE zst_error(
          line     = 0
          msg      = lv_text
          sev      = gc_severity-warning
          category = gc_category-clean_code
          rule     = gc_rule_cc-unused_text_symbol
        ) TO rt_errors.

      ENDLOOP.

    ENDIF.

  ENDIF.

ENDMETHOD.


METHOD cc_unused_variables.
  CLEAR rt_errors.

  "------------------------------------------------------------
  " Local types
  "------------------------------------------------------------
  TYPES: BEGIN OF lty_decl,
           name     TYPE string,
           line     TYPE i,
           scope_id TYPE string,
           base_cnt TYPE i,
         END OF lty_decl.
  TYPES lty_t_decl TYPE HASHED TABLE OF lty_decl WITH UNIQUE KEY name scope_id.

  TYPES: BEGIN OF lty_struct_type_root,
           name_u TYPE string,
         END OF lty_struct_type_root.
  TYPES lty_t_struct_type_root TYPE HASHED TABLE OF lty_struct_type_root WITH UNIQUE KEY name_u.

  TYPES: BEGIN OF lty_decl_prefix,
           prefix    TYPE string,
           full_name TYPE string,
           ambiguous TYPE abap_bool,
         END OF lty_decl_prefix.
  TYPES lty_t_decl_prefix TYPE HASHED TABLE OF lty_decl_prefix WITH UNIQUE KEY prefix.

  TYPES: BEGIN OF lty_stmt_ctx,
           from      TYPE i,
           to        TYPE i,
           prefixlen TYPE i,
           first_u   TYPE string,
           second_u  TYPE string,
           scope_id  TYPE string,
           skip_decl TYPE abap_bool,
         END OF lty_stmt_ctx.
  TYPES lty_t_stmt_ctx TYPE STANDARD TABLE OF lty_stmt_ctx WITH EMPTY KEY.

  "------------------------------------------------------------
  " Local data
  "------------------------------------------------------------
  DATA lt_tokens            TYPE gty_t_tok_tab.
  DATA lt_stmts             TYPE gty_t_stmt_tab.
  DATA lt_decl              TYPE lty_t_decl.
  DATA lt_decl_seq          TYPE STANDARD TABLE OF lty_decl WITH EMPTY KEY.
  DATA lt_cnt               TYPE gty_t_cnt.
  DATA lt_struct_type_roots TYPE lty_t_struct_type_root.
  DATA lt_usage_source      TYPE string_table.
  DATA lt_struct_stack      TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  DATA lt_decl_prefix       TYPE lty_t_decl_prefix.
  DATA lt_stmt_ctx          TYPE lty_t_stmt_ctx.

  DATA lv_text                TYPE string.
  DATA lv_curr_scope          TYPE string.
  DATA lv_cnt_key             TYPE string.
  DATA lv_fm_scope            TYPE string.
  DATA lv_fm_if_section       TYPE string.

  DATA lv_i             TYPE i.
  DATA lv_off           TYPE i.
  DATA lv_word1         TYPE string.
  DATA lv_word2         TYPE string.
  DATA lv_name          TYPE string.
  DATA lv_parent_struct TYPE string.
  DATA lv_ignore        TYPE string.
  DATA lv_match_scope   TYPE string.
  DATA lv_use_tok1      TYPE string.
  DATA lv_use_tok2      TYPE string.
  DATA lv_use_tok3      TYPE string.
  DATA lv_use_full      TYPE string.
  DATA lv_use_parent    TYPE string.
  DATA lv_use_comp      TYPE string.
  DATA lv_name_row      TYPE i.
  DATA lv_tok_u         TYPE string.
  DATA lv_prev_u        TYPE string.
  DATA lv_prev2_u       TYPE string.
  DATA lv_stack_idx     TYPE i.
  DATA lv_use_src_line  TYPE string.

  FIELD-SYMBOLS <lfs_prefix> TYPE lty_decl_prefix.

  "------------------------------------------------------------
  " Use scanner result from caller only
  "------------------------------------------------------------
  lt_tokens = it_tokens.
  lt_stmts  = it_stmts.

  CLEAR lt_usage_source.

  IF it_usage_source IS NOT INITIAL.
    lt_usage_source = it_usage_source.
  ELSE.
    lt_usage_source = it_source.
  ENDIF.

  IF lt_tokens IS INITIAL OR lt_stmts IS INITIAL.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " D) RULE 1 - Declared but not used
  "------------------------------------------------------------

  " Build statement context once
  CLEAR lt_stmt_ctx.
  lv_curr_scope = gc_scope-global.

  LOOP AT lt_stmts INTO DATA(ls_ctx_stmt).

    CLEAR: lv_word1,
           lv_word2.

    READ TABLE lt_tokens INDEX ls_ctx_stmt-from INTO DATA(ls_ctx_tok1).
    IF sy-subrc = 0 AND ls_ctx_tok1-str IS NOT INITIAL.
      lv_word1 = ls_ctx_tok1-str.
      REPLACE ALL OCCURRENCES OF gc_keyword-dot   IN lv_word1 WITH gc_keyword-empty_string.
      REPLACE ALL OCCURRENCES OF gc_keyword-colon IN lv_word1 WITH gc_keyword-empty_string.
      lv_word1 = to_upper( lv_word1 ).
    ENDIF.

    READ TABLE lt_tokens INDEX ls_ctx_stmt-from + 1 INTO DATA(ls_ctx_tok2).
    IF sy-subrc = 0 AND ls_ctx_tok2-str IS NOT INITIAL.
      lv_word2 = ls_ctx_tok2-str.
      REPLACE ALL OCCURRENCES OF gc_keyword-dot   IN lv_word2 WITH gc_keyword-empty_string.
      REPLACE ALL OCCURRENCES OF gc_keyword-colon IN lv_word2 WITH gc_keyword-empty_string.
      lv_word2 = to_upper( lv_word2 ).
    ENDIF.

    DATA(lv_skip_decl) = abap_false.

    CASE lv_word1.
      WHEN gc_keyword-method
        OR gc_keyword-form
        OR gc_keyword-func
        OR gc_keyword-module.

        IF lv_word2 IS INITIAL.
          lv_curr_scope = lv_word1.
        ELSE.
          lv_curr_scope = |{ lv_word1 };{ lv_word2 }|.
        ENDIF.

        lv_skip_decl = abap_true.

      WHEN gc_keyword-endmethod
        OR gc_keyword-endform
        OR gc_keyword-endfunc
        OR gc_keyword-endmodule.

        lv_curr_scope = gc_scope-global.
        lv_skip_decl  = abap_true.

      WHEN gc_keyword-initialization
        OR gc_keyword-start_of_selection
        OR gc_keyword-end_of_selection
        OR gc_keyword-top_of_page
        OR gc_keyword-end_of_page.

        lv_curr_scope = lv_word1.
        lv_skip_decl  = abap_true.

      WHEN gc_keyword-at.
        IF lv_word2 = gc_keyword-selection_screen.
          lv_curr_scope = gc_keyword-at_selection_screen.
          lv_skip_decl  = abap_true.
        ENDIF.
    ENDCASE.

    APPEND VALUE lty_stmt_ctx(
      from      = ls_ctx_stmt-from
      to        = ls_ctx_stmt-to
      prefixlen = ls_ctx_stmt-prefixlen
      first_u   = lv_word1
      second_u  = lv_word2
      scope_id  = lv_curr_scope
      skip_decl = lv_skip_decl
    ) TO lt_stmt_ctx.

  ENDLOOP.

  "------------------------------------------------------------
  " Collect declarations from current source only
  "------------------------------------------------------------
  CLEAR lt_struct_stack.

  LOOP AT lt_stmt_ctx INTO DATA(ls_decl_stmt).
    CLEAR: lv_name_row,
           lv_tok_u,
           lv_prev_u,
           lv_prev2_u,
           lv_parent_struct,
           lv_name.

    DATA(lv_stmt_from) = ls_decl_stmt-from.
    DATA(lv_stmt_to)   = ls_decl_stmt-to.

    IF lv_stmt_from <= 0 OR lv_stmt_to < lv_stmt_from.
      CONTINUE.
    ENDIF.

    READ TABLE lt_tokens INDEX lv_stmt_from INTO DATA(ls_first_tok).
    IF sy-subrc <> 0
       OR ls_first_tok-str IS INITIAL
       OR ls_first_tok-row > lines( it_source ).
      CONTINUE.
    ENDIF.

    DATA(lv_stmt_kind)      = ls_decl_stmt-first_u.
    DATA(lv_idx_decl_start) = lv_stmt_from + 1.
    lv_curr_scope           = ls_decl_stmt-scope_id.

    IF ls_decl_stmt-skip_decl = abap_true.
      CONTINUE.
    ENDIF.

    IF ls_decl_stmt-prefixlen > 0.
      DATA(lv_prefix_idx) = lv_stmt_from - ls_decl_stmt-prefixlen.
      IF lv_prefix_idx < 1.
        lv_prefix_idx = 1.
      ENDIF.

      READ TABLE lt_tokens INDEX lv_prefix_idx INTO DATA(lfs_prefix_tok).
      IF sy-subrc = 0 AND lfs_prefix_tok-str IS NOT INITIAL.
        DATA(lv_prefix_tok) = lfs_prefix_tok-str.
        REPLACE ALL OCCURRENCES OF gc_keyword-dot   IN lv_prefix_tok WITH gc_keyword-empty_string.
        REPLACE ALL OCCURRENCES OF gc_keyword-colon IN lv_prefix_tok WITH gc_keyword-empty_string.
        lv_prefix_tok = to_upper( lv_prefix_tok ).

        CASE lv_prefix_tok.
          WHEN gc_keyword-data
            OR gc_keyword-constants
            OR gc_keyword-types
            OR gc_keyword-field_symbols
            OR gc_keyword-statics
            OR gc_keyword-class_data
            OR gc_keyword-class_constants.
            lv_stmt_kind      = lv_prefix_tok.
            lv_idx_decl_start = lv_stmt_from.
        ENDCASE.
      ENDIF.
    ENDIF.

    " Inline DATA declarations inside any statement:
    DATA(lv_inline_idx)      = lv_stmt_from.
    DATA lv_inline_tok       TYPE string.
    DATA lv_inline_src_line  TYPE string.
    DATA lv_inline_off1      TYPE i.
    DATA lv_inline_off2      TYPE i.
    DATA lv_inline_len       TYPE i.

    WHILE lv_inline_idx <= lv_stmt_to.

      CLEAR: lv_inline_tok,
             lv_inline_src_line,
             lv_inline_off1,
             lv_inline_off2,
             lv_inline_len,
             lv_name,
             lv_name_row.

      READ TABLE lt_tokens INDEX lv_inline_idx INTO DATA(ls_inline_tok).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_inline_tok = ls_inline_tok-str.

      IF ls_inline_tok-row > 0
         AND ls_inline_tok-row <= lines( lt_usage_source ).

        READ TABLE lt_usage_source INDEX ls_inline_tok-row INTO lv_inline_src_line.
        IF sy-subrc = 0
           AND ls_inline_tok-len > 0.
          DATA(lv_inline_line_len) = strlen( lv_inline_src_line ).

          IF ls_inline_tok-col < lv_inline_line_len.
            lv_inline_len = ls_inline_tok-len.
            IF ls_inline_tok-col + lv_inline_len > lv_inline_line_len.
              lv_inline_len = lv_inline_line_len - ls_inline_tok-col.
            ENDIF.
            lv_inline_tok = lv_inline_src_line+ls_inline_tok-col(lv_inline_len).
          ENDIF.
        ENDIF.
      ENDIF.

      lv_inline_tok = to_upper( lv_inline_tok ).

      "Case 1: compact token, for example DATA(LV_X) or @DATA(LV_X)
      IF lv_inline_tok CP gc_keyword-data_inline
         OR lv_inline_tok CP gc_keyword-at_data_inline.

        FIND FIRST OCCURRENCE OF gc_keyword-lparen
          IN lv_inline_tok
          MATCH OFFSET lv_inline_off1.

        FIND FIRST OCCURRENCE OF gc_keyword-rparen
          IN lv_inline_tok
          MATCH OFFSET lv_inline_off2.

        IF sy-subrc = 0
           AND lv_inline_off2 > lv_inline_off1.

          lv_inline_off1 = lv_inline_off1 + 1.
          lv_inline_len  = lv_inline_off2 - lv_inline_off1.
          lv_name        = lv_inline_tok+lv_inline_off1(lv_inline_len).

          REPLACE ALL OCCURRENCES OF gc_keyword-dot    IN lv_name WITH gc_keyword-empty_string.
          REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_name WITH gc_keyword-empty_string.
          REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_name WITH gc_keyword-empty_string.
          REPLACE ALL OCCURRENCES OF gc_keyword-at_sign IN lv_name WITH gc_keyword-empty_string.
          CONDENSE lv_name NO-GAPS.
          lv_name = to_upper( lv_name ).

          IF lv_name IS NOT INITIAL.
            lv_name_row = ls_inline_tok-row.

            READ TABLE lt_decl
              WITH TABLE KEY
                name     = lv_name
                scope_id = lv_curr_scope
              TRANSPORTING NO FIELDS.

            IF sy-subrc <> 0.
              INSERT VALUE lty_decl(
                name     = lv_name
                line     = lv_name_row
                scope_id = lv_curr_scope
                base_cnt = gc_clean_code-unused_token_limit
              ) INTO TABLE lt_decl.
            ENDIF.
          ENDIF.
        ENDIF.

        lv_inline_idx += 1.
        CONTINUE.
      ENDIF.

      "Case 2: separated tokens in non-DATA statements:
      IF lv_stmt_kind <> gc_keyword-data.

        DATA(lv_inline_key) = lv_inline_tok.

        IF lv_inline_key(1) = gc_keyword-at_sign.
          SHIFT lv_inline_key BY 1 PLACES LEFT.
        ENDIF.

        IF lv_inline_key = gc_keyword-data
           AND lv_inline_idx + 3 <= lv_stmt_to.

          READ TABLE lt_tokens INDEX lv_inline_idx + 1 INTO DATA(ls_inline_lpar).
          READ TABLE lt_tokens INDEX lv_inline_idx + 2 INTO DATA(ls_inline_name).
          READ TABLE lt_tokens INDEX lv_inline_idx + 3 INTO DATA(ls_inline_rpar).

          IF sy-subrc = 0
             AND ls_inline_lpar-str = gc_keyword-lparen
             AND ls_inline_rpar-str = gc_keyword-rparen
             AND ls_inline_name-type = gc_token_type-identifier.

            lv_name = ls_inline_name-str.

            REPLACE ALL OCCURRENCES OF gc_keyword-dot    IN lv_name WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_name WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_name WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-at_sign IN lv_name WITH gc_keyword-empty_string.
            CONDENSE lv_name NO-GAPS.
            lv_name = to_upper( lv_name ).

            IF lv_name IS NOT INITIAL.
              lv_name_row = ls_inline_name-row.

              READ TABLE lt_decl
                WITH TABLE KEY
                  name     = lv_name
                  scope_id = lv_curr_scope
                TRANSPORTING NO FIELDS.

              IF sy-subrc <> 0.
                INSERT VALUE lty_decl(
                  name     = lv_name
                  line     = lv_name_row
                  scope_id = lv_curr_scope
                  base_cnt = 0
                ) INTO TABLE lt_decl.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      lv_inline_idx += 1.
    ENDWHILE.

    CASE lv_stmt_kind.
      WHEN gc_keyword-data
        OR gc_keyword-constants
        OR gc_keyword-types
        OR gc_keyword-field_symbols
        OR gc_keyword-statics
        OR gc_keyword-class_data
        OR gc_keyword-class_constants.
      WHEN OTHERS.
        CONTINUE.
    ENDCASE.

    DATA(lv_stmt_is_types)    = xsdbool( lv_stmt_kind = gc_keyword-types ).
    DATA(lv_expect_decl_name) = abap_true.
    DATA(lv_paren_depth)      = 0.

    DATA(lv_idx_decl) = lv_idx_decl_start.

    WHILE lv_idx_decl <= lv_stmt_to.
      READ TABLE lt_tokens INDEX lv_idx_decl INTO DATA(ls_decl_tok).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_tok_u = ls_decl_tok-str.
      lv_tok_u = to_upper( lv_tok_u ).

      CASE lv_tok_u.
        WHEN gc_keyword-lparen.
          lv_paren_depth += 1.
          lv_idx_decl += 1.
          CONTINUE.

        WHEN gc_keyword-rparen.
          IF lv_paren_depth > 0.
            lv_paren_depth -= 1.
          ENDIF.
          lv_idx_decl += 1.
          CONTINUE.

        WHEN gc_keyword-comma.
          IF lv_paren_depth = 0.
            lv_expect_decl_name = abap_true.
          ENDIF.
          lv_idx_decl += 1.
          CONTINUE.
      ENDCASE.

      IF lv_expect_decl_name = abap_true
         AND lv_tok_u = gc_keyword-include.
        lv_expect_decl_name = abap_false.
        lv_idx_decl += 1.
        CONTINUE.
      ENDIF.

      IF ls_decl_tok-type <> gc_token_type-identifier.
        lv_idx_decl += 1.
        CONTINUE.
      ENDIF.

      CLEAR: lv_prev_u,
             lv_prev2_u,
             lv_parent_struct,
             lv_name.

      DATA(lv_is_begin_of)    = abap_false.
      DATA(lv_is_end_of)      = abap_false.
      DATA(lv_is_root_struct) = abap_false.

      READ TABLE lt_tokens INDEX lv_idx_decl - 1 INTO DATA(ls_prev_tok).
      IF sy-subrc = 0.
        lv_prev_u = ls_prev_tok-str.
        lv_prev_u = to_upper( lv_prev_u ).
      ENDIF.

      READ TABLE lt_tokens INDEX lv_idx_decl - 2 INTO DATA(ls_prev2_tok).
      IF sy-subrc = 0.
        lv_prev2_u = ls_prev2_tok-str.
        lv_prev2_u = to_upper( lv_prev2_u ).
      ENDIF.

      CLEAR lv_word1.
      READ TABLE lt_tokens INDEX lv_idx_decl + 1 INTO DATA(ls_next_tok).
      IF sy-subrc = 0 AND ls_next_tok-str IS NOT INITIAL.
        lv_word1 = ls_next_tok-str.
        lv_word1 = to_upper( lv_word1 ).
      ENDIF.

      IF ( lv_tok_u = gc_keyword-begin OR lv_tok_u = gc_keyword-end )
         AND lv_word1 = gc_keyword-of.
        lv_idx_decl += 1.
        CONTINUE.
      ENDIF.

      IF lv_tok_u = gc_keyword-of
         AND ( lv_prev_u = gc_keyword-begin OR lv_prev_u = gc_keyword-end ).
        lv_idx_decl += 1.
        CONTINUE.
      ENDIF.

      IF lv_prev2_u = gc_keyword-begin
         AND lv_prev_u  = gc_keyword-of.
        lv_name        = lv_tok_u.
        lv_name_row    = ls_decl_tok-row.
        lv_is_begin_of = abap_true.

      ELSEIF lv_prev2_u = gc_keyword-end
         AND lv_prev_u  = gc_keyword-of.
        lv_is_end_of = abap_true.

      ELSE.
        IF lv_expect_decl_name = abap_false.
          lv_idx_decl += 1.
          CONTINUE.
        ENDIF.

        lv_name     = lv_tok_u.
        lv_name_row = ls_decl_tok-row.
      ENDIF.

      IF lv_is_end_of = abap_true.
        lv_stack_idx = lines( lt_struct_stack ).
        IF lv_stack_idx > 0.
          DELETE lt_struct_stack INDEX lv_stack_idx.
        ENDIF.

        lv_expect_decl_name = abap_false.
        lv_idx_decl += 1.
        CONTINUE.
      ENDIF.

      IF lv_name IS INITIAL.
        lv_idx_decl += 1.
        CONTINUE.
      ENDIF.

      lv_stack_idx = lines( lt_struct_stack ).

      lv_is_root_struct = xsdbool(
        lv_is_begin_of = abap_true
        AND lv_stack_idx = 0 ).

      IF lv_stack_idx > 0.
        READ TABLE lt_struct_stack
          INDEX lv_stack_idx
          INTO lv_parent_struct.
        IF sy-subrc <> 0 OR lv_parent_struct IS INITIAL.
          lv_idx_decl += 1.
          CONTINUE.
        ENDIF.

        lv_name = |{ lv_parent_struct }-{ lv_name }|.
      ENDIF.

      INSERT VALUE lty_decl(
        name     = lv_name
        line     = lv_name_row
        scope_id = lv_curr_scope
        base_cnt = COND i(
          WHEN lv_name CS gc_keyword-dash
          THEN 0
          ELSE gc_clean_code-unused_token_limit )
      ) INTO TABLE lt_decl.

      IF lv_is_begin_of = abap_true.
        APPEND lv_name TO lt_struct_stack.

        IF lv_stmt_is_types = abap_true
           AND lv_is_root_struct = abap_true.
          lv_cnt_key = |{ lv_curr_scope };{ lv_name }|.
          INSERT VALUE lty_struct_type_root(
            name_u = lv_cnt_key
          ) INTO TABLE lt_struct_type_roots.
        ENDIF.
      ENDIF.

      lv_expect_decl_name = abap_false.
      lv_idx_decl += 1.
    ENDWHILE.
  ENDLOOP.

  "------------------------------------------------------------
  " D.1) Extra declarations - FORM params, FM params
  "------------------------------------------------------------
  DATA lv_sig_kind    TYPE string.
  DATA lv_sig_scope   TYPE string.
  DATA lv_sig_owner   TYPE string.
  DATA lv_sig_section TYPE string.
  DATA lv_sig_idx     TYPE i.
  DATA lv_sig_name    TYPE string.
  DATA lv_sig_row     TYPE i.
  DATA lv_sig_next    TYPE string.
  DATA lv_ref_name    TYPE string.
  DATA lv_ref_off     TYPE i.
  DATA lv_ref_end     TYPE i.
  DATA lv_ref_len     TYPE i.

  CLEAR lv_fm_scope.

  LOOP AT lt_stmts INTO DATA(ls_sig_stmt).

    IF ls_sig_stmt-from <= 0 OR ls_sig_stmt-to < ls_sig_stmt-from.
      CONTINUE.
    ENDIF.

    READ TABLE lt_tokens INDEX ls_sig_stmt-from INTO DATA(ls_sig_tok1).
    IF sy-subrc <> 0
       OR ls_sig_tok1-str IS INITIAL
       OR ls_sig_tok1-row > lines( it_source ).
      CONTINUE.
    ENDIF.

    lv_sig_kind = ls_sig_tok1-str.
    lv_sig_kind = to_upper( lv_sig_kind ).

    IF lv_sig_kind = gc_keyword-func.
      READ TABLE lt_tokens INDEX ls_sig_stmt-from + 1 INTO DATA(ls_fm_name_tok).
      IF sy-subrc = 0 AND ls_fm_name_tok-str IS NOT INITIAL.
        lv_sig_owner = ls_fm_name_tok-str.
        REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_sig_owner WITH gc_keyword-empty_string.
        lv_sig_owner = to_upper( lv_sig_owner ).
        lv_fm_scope = |{ gc_keyword-func };{ lv_sig_owner }|.
      ENDIF.
      CONTINUE.
    ENDIF.

    IF lv_sig_kind <> gc_keyword-form.
      CONTINUE.
    ENDIF.

    READ TABLE lt_tokens INDEX ls_sig_stmt-from + 1 INTO DATA(ls_sig_owner_tok).
    IF sy-subrc <> 0 OR ls_sig_owner_tok-str IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_sig_owner = ls_sig_owner_tok-str.
    REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_sig_owner WITH gc_keyword-empty_string.
    REPLACE ALL OCCURRENCES OF gc_keyword-exclamation_mark IN lv_sig_owner WITH gc_keyword-empty_string.
    lv_sig_owner = to_upper( lv_sig_owner ).

    IF lv_sig_owner IS INITIAL.
      CONTINUE.
    ENDIF.

    IF lv_sig_kind = gc_keyword-form.
      lv_sig_scope = |{ gc_keyword-form };{ lv_sig_owner }|.
    ELSE.
      lv_sig_scope = |{ gc_keyword-method };{ lv_sig_owner }|.
    ENDIF.

    CLEAR lv_sig_section.
    lv_sig_idx = ls_sig_stmt-from + 2.

    WHILE lv_sig_idx <= ls_sig_stmt-to.

      CLEAR: lv_sig_name,
             lv_sig_next,
             lv_sig_row,
             lv_ref_name,
             lv_ref_off,
             lv_ref_end,
             lv_ref_len.

      READ TABLE lt_tokens INDEX lv_sig_idx INTO DATA(ls_sig_tok).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_sig_name = ls_sig_tok-str.
      REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_sig_name WITH gc_keyword-empty_string.
      REPLACE ALL OCCURRENCES OF gc_keyword-exclamation_mark IN lv_sig_name WITH gc_keyword-empty_string.
      lv_sig_name = to_upper( lv_sig_name ).

      " Handle compact token from SCAN:
      IF lv_sig_name CP gc_keyword-value_star
         OR lv_sig_name CP gc_keyword-ref_inline.

        FIND FIRST OCCURRENCE OF gc_keyword-lparen
          IN lv_sig_name
          MATCH OFFSET lv_ref_off.

        IF sy-subrc = 0.
          FIND FIRST OCCURRENCE OF gc_keyword-rparen
            IN lv_sig_name
            MATCH OFFSET lv_ref_end.

          IF sy-subrc = 0
             AND lv_ref_end > lv_ref_off.

            lv_ref_off = lv_ref_off + 1.
            lv_ref_len = lv_ref_end - lv_ref_off.
            lv_ref_name = lv_sig_name+lv_ref_off(lv_ref_len).

            REPLACE ALL OCCURRENCES OF gc_keyword-dot    IN lv_ref_name WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-exclamation_mark IN lv_ref_name WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_ref_name WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_ref_name WITH gc_keyword-empty_string.
            CONDENSE lv_ref_name NO-GAPS.
            lv_ref_name = to_upper( lv_ref_name ).

            IF lv_ref_name IS NOT INITIAL.
              lv_sig_name = lv_ref_name.
              lv_sig_row  = ls_sig_tok-row.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      CASE lv_sig_name.
        WHEN gc_keyword-using
          OR gc_keyword-importing
          OR gc_keyword-exporting
          OR gc_keyword-changing
          OR gc_keyword-returning
          OR gc_keyword-tables.
          lv_sig_section = lv_sig_name.
          lv_sig_idx += 1.
          CONTINUE.

        WHEN gc_keyword-raising
          OR gc_keyword-exceptions.
          CLEAR lv_sig_section.
          lv_sig_idx += 1.
          CONTINUE.
      ENDCASE.

      IF lv_sig_section IS INITIAL.
        lv_sig_idx += 1.
        CONTINUE.
      ENDIF.

      " VALUE rv_x / REFERENCE iv_x when SCAN separates tokens:
      IF lv_sig_name = gc_keyword-value
         OR lv_sig_name = gc_keyword-reference.

        READ TABLE lt_tokens INDEX lv_sig_idx + 1 INTO DATA(ls_sig_lpar).
        READ TABLE lt_tokens INDEX lv_sig_idx + 2 INTO DATA(ls_sig_value_name).

        IF sy-subrc = 0
           AND ls_sig_lpar-str = gc_keyword-lparen
           AND ls_sig_value_name-type = gc_token_type-identifier.

          lv_sig_name = ls_sig_value_name-str.
          REPLACE ALL OCCURRENCES OF gc_keyword-dot    IN lv_sig_name WITH gc_keyword-empty_string.
          REPLACE ALL OCCURRENCES OF gc_keyword-exclamation_mark IN lv_sig_name WITH gc_keyword-empty_string.
          REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_sig_name WITH gc_keyword-empty_string.
          REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_sig_name WITH gc_keyword-empty_string.
          CONDENSE lv_sig_name NO-GAPS.
          lv_sig_name = to_upper( lv_sig_name ).
          lv_sig_row  = ls_sig_value_name-row.

          IF lv_sig_name IS NOT INITIAL.
            INSERT VALUE lty_decl(
              name     = lv_sig_name
              line     = lv_sig_row
              scope_id = lv_sig_scope
              base_cnt = COND i(
                WHEN lv_sig_kind = gc_keyword-form
                THEN 0
                ELSE gc_clean_code-unused_token_limit )
            ) INTO TABLE lt_decl.
          ENDIF.

          lv_sig_idx += 4.
          CONTINUE.
        ENDIF.
      ENDIF.

      IF ls_sig_tok-type <> gc_token_type-identifier.
        lv_sig_idx += 1.
        CONTINUE.
      ENDIF.

      CASE lv_sig_name.
        WHEN gc_keyword-type
          OR gc_keyword-like
          OR gc_keyword-structure
          OR gc_keyword-optional
          OR gc_keyword-default
          OR gc_keyword-preferred
          OR gc_keyword-parameter
          OR gc_keyword-raising
          OR gc_keyword-exceptions
          OR gc_keyword-value
          OR gc_keyword-reference.
          lv_sig_idx += 1.
          CONTINUE.
      ENDCASE.

      READ TABLE lt_tokens INDEX lv_sig_idx + 1 INTO DATA(ls_sig_next_tok).
      IF sy-subrc = 0 AND ls_sig_next_tok-str IS NOT INITIAL.
        lv_sig_next = ls_sig_next_tok-str.
        REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_sig_next WITH gc_keyword-empty_string.
        lv_sig_next = to_upper( lv_sig_next ).
      ENDIF.

      IF lv_sig_next = gc_keyword-type
         OR lv_sig_next = gc_keyword-like
         OR lv_sig_next = gc_keyword-structure.

        IF lv_sig_row IS INITIAL.
          lv_sig_row = ls_sig_tok-row.
        ENDIF.

        INSERT VALUE lty_decl(
          name     = lv_sig_name
          line     = lv_sig_row
          scope_id = lv_sig_scope
          base_cnt = COND i(
            WHEN lv_sig_kind = gc_keyword-form
             AND lv_ref_name IS NOT INITIAL
            THEN 1
            WHEN lv_sig_kind = gc_keyword-form
            THEN 0
            ELSE gc_clean_code-unused_token_limit )
        ) INTO TABLE lt_decl.
      ENDIF.

      lv_sig_idx += 1.
    ENDWHILE.
  ENDLOOP.

  "------------------------------------------------------------
  " D.2) FM interface params from generated comment block
  "------------------------------------------------------------
  IF lv_fm_scope IS NOT INITIAL.

    DATA lt_words TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_raw_work TYPE string.
    DATA lv_raw_name TYPE string.
    DATA lv_raw_off  TYPE i.
    DATA lv_raw_len  TYPE i.

    CLEAR lv_fm_if_section.

    LOOP AT it_source INTO DATA(lv_raw_line).

      lv_raw_work = lv_raw_line.
      lv_raw_work = to_upper( lv_raw_work ).

      IF lv_raw_work CS gc_keyword-comment_quote
         OR lv_raw_work CS gc_keyword-comment_quote_rev.

        REPLACE ALL OCCURRENCES OF gc_keyword-comment_quote IN lv_raw_work WITH space.
        REPLACE ALL OCCURRENCES OF gc_keyword-comment_quote_rev IN lv_raw_work WITH space.
        CONDENSE lv_raw_work.

        IF lv_raw_work IS INITIAL.
          CONTINUE.
        ENDIF.

        CLEAR lt_words.
        SPLIT lv_raw_work AT space INTO TABLE lt_words.
        DELETE lt_words WHERE table_line IS INITIAL.

        CLEAR lv_word1.
        READ TABLE lt_words INDEX 1 INTO lv_word1.
        lv_word1 = to_upper( lv_word1 ).

        CASE lv_word1.
          WHEN gc_keyword-importing
            OR gc_keyword-exporting
            OR gc_keyword-changing
            OR gc_keyword-tables.
            lv_fm_if_section = lv_word1.
            CONTINUE.

          WHEN gc_keyword-exceptions
            OR gc_keyword-raising.
            CLEAR lv_fm_if_section.
            CONTINUE.
        ENDCASE.

        IF lv_fm_if_section IS INITIAL.
          CONTINUE.
        ENDIF.

        CLEAR lv_raw_name.

        FIND FIRST OCCURRENCE OF gc_keyword-value_lparen
          IN lv_raw_work
          MATCH OFFSET lv_raw_off
          MATCH LENGTH lv_raw_len.

        IF sy-subrc = 0.
          lv_raw_off = lv_raw_off + lv_raw_len.
          lv_raw_name = lv_raw_work+lv_raw_off.
          FIND FIRST OCCURRENCE OF gc_keyword-rparen
            IN lv_raw_name
            MATCH OFFSET lv_raw_len.
          IF sy-subrc = 0.
            lv_raw_name = lv_raw_name(lv_raw_len).
          ENDIF.
        ELSE.
          FIND FIRST OCCURRENCE OF gc_keyword-reference_lparen
            IN lv_raw_work
            MATCH OFFSET lv_raw_off
            MATCH LENGTH lv_raw_len.

          IF sy-subrc = 0.
            lv_raw_off = lv_raw_off + lv_raw_len.
            lv_raw_name = lv_raw_work+lv_raw_off.
            FIND FIRST OCCURRENCE OF gc_keyword-rparen
              IN lv_raw_name
              MATCH OFFSET lv_raw_len.
            IF sy-subrc = 0.
              lv_raw_name = lv_raw_name(lv_raw_len).
            ENDIF.
          ELSE.
            CLEAR lt_words.
            SPLIT lv_raw_work AT space INTO TABLE lt_words.
            DELETE lt_words WHERE table_line IS INITIAL.
            READ TABLE lt_words INDEX 1 INTO lv_raw_name.
          ENDIF.
        ENDIF.

        REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_raw_name WITH gc_keyword-empty_string.
        REPLACE ALL OCCURRENCES OF gc_keyword-exclamation_mark IN lv_raw_name WITH gc_keyword-empty_string.
        REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_raw_name WITH gc_keyword-empty_string.
        REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_raw_name WITH gc_keyword-empty_string.
        CONDENSE lv_raw_name NO-GAPS.
        lv_raw_name = to_upper( lv_raw_name ).

        IF lv_raw_name IS INITIAL
           OR lv_raw_name = gc_keyword-value
           OR lv_raw_name = gc_keyword-reference
           OR lv_raw_name = gc_keyword-type
           OR lv_raw_name = gc_keyword-like
           OR lv_raw_name = gc_keyword-structure.
          CONTINUE.
        ENDIF.

        INSERT VALUE lty_decl(
          name     = lv_raw_name
          line     = sy-tabix
          scope_id = lv_fm_scope
          base_cnt = gc_clean_code-unused_token_limit
        ) INTO TABLE lt_decl.

      ENDIF.
    ENDLOOP.
  ENDIF.

  lt_decl_seq = VALUE #( FOR ls_decl_seq IN lt_decl
                        ( ls_decl_seq ) ).

  "------------------------------------------------------------
  " Count usages from full scanned source
  "------------------------------------------------------------
  CLEAR: lt_cnt,
         lt_decl_prefix.


  LOOP AT lt_decl INTO DATA(ls_decl_prefix_src)
       WHERE name CS gc_keyword-dash.                   "#EC CI_HASHSEQ

    CLEAR lv_off.
    FIND FIRST OCCURRENCE OF gc_keyword-dash
      IN ls_decl_prefix_src-name
      MATCH OFFSET lv_off.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_stack_idx = strlen( ls_decl_prefix_src-name ).

    IF lv_off + 2 > lv_stack_idx - 1.
      CONTINUE.
    ENDIF.

    lv_i = lv_off + 2.
    WHILE lv_i < lv_stack_idx.
      lv_name = ls_decl_prefix_src-name(lv_i).

      READ TABLE lt_decl_prefix
        ASSIGNING <lfs_prefix>
        WITH TABLE KEY prefix = lv_name.

      IF sy-subrc <> 0.
        INSERT VALUE lty_decl_prefix(
          prefix    = lv_name
          full_name = ls_decl_prefix_src-name
          ambiguous = abap_false
        ) INTO TABLE lt_decl_prefix.

      ELSEIF <lfs_prefix>-full_name <> ls_decl_prefix_src-name.
        <lfs_prefix>-ambiguous = abap_true.
        CLEAR <lfs_prefix>-full_name.
      ENDIF.

      lv_i += 1.
    ENDWHILE.
  ENDLOOP.

    LOOP AT lt_stmt_ctx INTO DATA(ls_use_stmt).

    " Do not count declaration statements as usage.
    IF ls_use_stmt-skip_decl = abap_true.
      CONTINUE.
    ENDIF.

    CASE ls_use_stmt-first_u.
      WHEN gc_keyword-data
        OR gc_keyword-constants
        OR gc_keyword-field_symbols
        OR gc_keyword-statics
        OR gc_keyword-class_data
        OR gc_keyword-class_constants.
        CONTINUE.
    ENDCASE.

    DATA(lv_use_idx) = ls_use_stmt-from.
    lv_curr_scope    = ls_use_stmt-scope_id.
    lv_word1         = ls_use_stmt-first_u.
    lv_word2         = ls_use_stmt-second_u.

    WHILE lv_use_idx <= ls_use_stmt-to.
      CLEAR: lv_use_tok1,
             lv_use_tok2,
             lv_use_tok3,
             lv_use_full,
             lv_use_parent,
             lv_use_comp,
             lv_use_src_line.

      DATA(lv_use_tok_idx) = lv_use_idx.
      DATA(lv_skip_usage)  = abap_false.

      READ TABLE lt_tokens INDEX lv_use_idx INTO DATA(ls_use_tok1).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_use_tok1 = ls_use_tok1-str.
      IF ls_use_tok1-row > 0
         AND ls_use_tok1-row <= lines( lt_usage_source ).

        READ TABLE lt_usage_source INDEX ls_use_tok1-row INTO lv_use_src_line.
        IF sy-subrc = 0
           AND ls_use_tok1-len > 0.

          DATA(lv_use_line_len) = strlen( lv_use_src_line ).
          DATA(lv_use_len_full) = ls_use_tok1-len.

          IF ls_use_tok1-col < lv_use_line_len.
            IF ls_use_tok1-col + lv_use_len_full > lv_use_line_len.
              lv_use_len_full = lv_use_line_len - ls_use_tok1-col.
            ENDIF.
            lv_use_tok1 = lv_use_src_line+ls_use_tok1-col(lv_use_len_full).
          ENDIF.
        ENDIF.
      ENDIF.

      IF lv_use_tok1 IS INITIAL.
        lv_use_idx += 1.
        CONTINUE.
      ENDIF.

      lv_use_tok1 = to_upper( lv_use_tok1 ).

      IF lv_use_tok1(1) = gc_keyword-at_sign.
        SHIFT lv_use_tok1 BY 1 PLACES LEFT.
      ENDIF.

      IF lv_use_tok1 IS INITIAL.
        lv_use_idx += 1.
        CONTINUE.
      ENDIF.

      IF lv_use_tok1 = gc_keyword-value
         AND lv_use_idx + 1 <= ls_use_stmt-to.
        READ TABLE lt_tokens INDEX lv_use_idx + 1 INTO DATA(ls_value_type_tok).

        IF sy-subrc = 0 AND ls_value_type_tok-str IS NOT INITIAL.
          lv_use_idx  += 1.
          lv_use_tok1  = to_upper( ls_value_type_tok-str ).
          ls_use_tok1-type = gc_token_type-identifier.
          REPLACE ALL OCCURRENCES OF gc_keyword-dot    IN lv_use_tok1 WITH gc_keyword-empty_string.
          REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_use_tok1 WITH gc_keyword-empty_string.
          CONDENSE lv_use_tok1 NO-GAPS.
        ENDIF.
      ENDIF.

      " Skip write-only positions.
      IF ls_use_tok1-type = gc_token_type-identifier.

        READ TABLE lt_tokens INDEX lv_use_tok_idx - 1 INTO DATA(ls_usage_prev1).
        DATA(lv_usage_prev1) = COND string(
          WHEN sy-subrc = 0 THEN to_upper( ls_usage_prev1-str )
          ELSE gc_keyword-empty_string ).

        READ TABLE lt_tokens INDEX lv_use_tok_idx - 2 INTO DATA(ls_usage_prev2).
        DATA(lv_usage_prev2) = COND string(
          WHEN sy-subrc = 0 THEN to_upper( ls_usage_prev2-str )
          ELSE gc_keyword-empty_string ).

        READ TABLE lt_tokens INDEX lv_use_tok_idx + 1 INTO DATA(ls_usage_next1).
        DATA(lv_usage_next1) = COND string(
          WHEN sy-subrc = 0 THEN to_upper( ls_usage_next1-str )
          ELSE gc_keyword-empty_string ).

        REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_usage_prev1 WITH gc_keyword-empty_string.
        REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_usage_prev2 WITH gc_keyword-empty_string.
        REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_usage_next1 WITH gc_keyword-empty_string.

        IF lv_usage_prev1 IS NOT INITIAL
           AND lv_usage_prev1(1) = gc_keyword-at_sign.
          SHIFT lv_usage_prev1 BY 1 PLACES LEFT.
        ENDIF.

        IF lv_usage_prev2 IS NOT INITIAL
           AND lv_usage_prev2(1) = gc_keyword-at_sign.
          SHIFT lv_usage_prev2 BY 1 PLACES LEFT.
        ENDIF.

        IF lv_usage_next1 IS NOT INITIAL
           AND lv_usage_next1(1) = gc_keyword-at_sign.
          SHIFT lv_usage_next1 BY 1 PLACES LEFT.
        ENDIF.

        "Direct assignment left side:
        "  lv_x = ...
        "Do not treat comparison IF lv_x = ... as write.
        IF lv_use_tok_idx = ls_use_stmt-from
           AND lv_usage_next1 = gc_keyword-equal
           AND lv_use_tok1 NP gc_keyword-field_symbol_pat.
          lv_skip_usage = abap_true.
        ENDIF.

        "CLEAR / FREE / REFRESH only write/reset the variable.
        IF lv_word1 = gc_keyword-clear
           OR lv_word1 = gc_keyword-free
           OR lv_word1 = gc_keyword-refresh.
          lv_skip_usage = abap_true.
        ENDIF.

        "Target after INTO:
        IF lv_usage_prev1 = gc_keyword-into.
          lv_skip_usage = abap_true.
        ENDIF.

        "Target after INTO TABLE:
        IF lv_usage_prev1 = gc_keyword-table
           AND lv_usage_prev2 = gc_keyword-into.
          lv_skip_usage = abap_true.
        ENDIF.

        "Target after ASSIGNING:
        IF lv_usage_prev1 = gc_keyword-assigning.
          lv_skip_usage = abap_true.
        ENDIF.

        "Target after TO for write statements.
        IF lv_usage_prev1 = gc_keyword-to
           AND ( lv_word1 = gc_keyword-assign
              OR lv_word1 = gc_keyword-append
              OR lv_word1 = gc_keyword-move
              OR lv_word1 = gc_keyword-add
              OR lv_word1 = gc_keyword-subtract
              OR lv_word1 = gc_keyword-collect ).
          lv_skip_usage = abap_true.
        ENDIF.

        IF lv_usage_prev1 = gc_keyword-from
           AND lv_word1 = gc_keyword-subtract.
          lv_skip_usage = abap_true.
        ENDIF.

        "First data object modified by table-changing statements.
        IF lv_use_tok_idx = ls_use_stmt-from + 1
           AND ( lv_word1 = gc_keyword-modify
              OR lv_word1 = gc_keyword-delete
              OR lv_word1 = gc_keyword-sort ).
          lv_skip_usage = abap_true.
        ENDIF.

        "Output target after LINES:
        IF lv_word1 = gc_keyword-describe
           AND lv_usage_prev1 = gc_keyword-lines.
          lv_skip_usage = abap_true.
        ENDIF.

        "Method/FM output parameter target:
        IF lv_usage_prev1 = gc_keyword-equal.
          DATA(lv_usage_section)  = gc_keyword-empty_string.
          DATA(lv_usage_back_idx) = lv_use_tok_idx - 1.

          WHILE lv_usage_back_idx >= ls_use_stmt-from.

            READ TABLE lt_tokens INDEX lv_usage_back_idx INTO DATA(ls_usage_back).
            IF sy-subrc <> 0.
              EXIT.
            ENDIF.

            DATA(lv_usage_back) = to_upper( ls_usage_back-str ).
            REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_usage_back WITH gc_keyword-empty_string.

            CASE lv_usage_back.
              WHEN gc_keyword-importing
                OR gc_keyword-exporting
                OR gc_keyword-changing
                OR gc_keyword-tables
                OR gc_keyword-receiving
                OR gc_keyword-returning.
                lv_usage_section = lv_usage_back.
                EXIT.
            ENDCASE.

            lv_usage_back_idx -= 1.
          ENDWHILE.

          IF lv_usage_section = gc_keyword-importing
             OR lv_usage_section = gc_keyword-receiving
             OR lv_usage_section = gc_keyword-returning.
            lv_skip_usage = abap_true.
          ENDIF.
        ENDIF.
      ENDIF.

      " Generic read usage inside compound expression tokens.
      DATA(lv_compound_expr) = xsdbool(
        ls_use_tok1-type = gc_token_type-identifier
        AND (
             lv_use_tok1 CS gc_keyword-plus
          OR lv_use_tok1 CS gc_keyword-lbracket
          OR lv_use_tok1 CS gc_keyword-instance_call
          OR lv_use_tok1 CS gc_keyword-static_call
          OR ( lv_use_tok1 CS gc_keyword-lparen
               AND lv_use_tok1 NP gc_keyword-data_inline
               AND lv_use_tok1 NP gc_keyword-at_data_inline
               AND lv_use_tok1 NP gc_keyword-value_star
               AND lv_use_tok1 NP gc_keyword-ref_inline ) ) ).

      IF lv_compound_expr = abap_true.

        DATA(lv_skip_first_expr_name) = xsdbool(
          lv_skip_usage = abap_true
          AND ( lv_use_tok_idx = ls_use_stmt-from
             OR lv_word1 = gc_keyword-clear
             OR lv_word1 = gc_keyword-free
             OR lv_word1 = gc_keyword-refresh ) ).

        FIND ALL OCCURRENCES OF PCRE gc_clean_code-rx_identifier
          IN lv_use_tok1
          RESULTS DATA(lt_expr_hits).

        DATA(lv_expr_name_no) = 0.
        DATA(lv_expr_hit_idx) = 0.

        WHILE lv_expr_hit_idx < lines( lt_expr_hits ).

          lv_expr_hit_idx += 1.

          READ TABLE lt_expr_hits INDEX lv_expr_hit_idx INTO DATA(ls_expr_hit).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          lv_expr_name_no += 1.

          IF lv_skip_first_expr_name = abap_true
             AND lv_expr_name_no = 1.
            CONTINUE.
          ENDIF.

          DATA(lv_expr_name) =
            lv_use_tok1+ls_expr_hit-offset(ls_expr_hit-length).

          REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_expr_name WITH gc_keyword-empty_string.
          CONDENSE lv_expr_name NO-GAPS.
          lv_expr_name = to_upper( lv_expr_name ).

          IF lv_expr_name IS INITIAL.
            CONTINUE.
          ENDIF.

          CLEAR lv_match_scope.

          READ TABLE lt_decl
            WITH TABLE KEY
              name     = lv_expr_name
              scope_id = lv_curr_scope
            TRANSPORTING NO FIELDS.

          IF sy-subrc = 0.
            lv_match_scope = lv_curr_scope.

          ELSEIF lv_curr_scope <> gc_scope-global.
            READ TABLE lt_decl
              WITH TABLE KEY
                name     = lv_expr_name
                scope_id = gc_scope-global
              TRANSPORTING NO FIELDS.

            IF sy-subrc = 0.
              lv_match_scope = gc_scope-global.
            ENDIF.
          ENDIF.

          IF lv_match_scope IS INITIAL.
            CONTINUE.
          ENDIF.

          lv_cnt_key = |{ lv_match_scope };{ lv_expr_name }|.

          cc_add_usage_count(
            EXPORTING
              iv_name = lv_cnt_key
            CHANGING
              ct_cnt  = lt_cnt ).

        ENDWHILE.

        lv_use_idx += 1.
        CONTINUE.
      ENDIF.

      IF ls_use_tok1-type = gc_token_type-identifier
        AND lv_use_tok1 CS gc_keyword-dash.

        lv_use_full = lv_use_tok1.

        REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_use_full WITH gc_keyword-empty_string.
        CONDENSE lv_use_full NO-GAPS.

        SPLIT lv_use_full AT gc_keyword-dash INTO lv_use_parent lv_use_comp.

        lv_use_full = to_upper( lv_use_full ).
        lv_use_parent = to_upper( lv_use_parent ).
        lv_use_comp = to_upper( lv_use_comp ).

        lv_use_idx += 1.

      ELSEIF ls_use_tok1-type = gc_token_type-identifier
         AND lv_use_idx + 2 <= ls_use_stmt-to.

        READ TABLE lt_tokens INDEX lv_use_idx + 1 INTO DATA(ls_use_tok2).
        IF sy-subrc = 0.
          READ TABLE lt_tokens INDEX lv_use_idx + 2 INTO DATA(ls_use_tok3).
        ENDIF.

        IF sy-subrc = 0.
          lv_use_tok2 = ls_use_tok2-str.
          lv_use_tok3 = ls_use_tok3-str.

          lv_use_tok2 = to_upper( lv_use_tok2 ).
          lv_use_tok3 = to_upper( lv_use_tok3 ).

          IF lv_use_tok2 = gc_keyword-dash
             AND ls_use_tok3-type = gc_token_type-identifier.

            lv_use_parent = lv_use_tok1.
            lv_use_comp   = lv_use_tok3.
            lv_use_full   = |{ lv_use_parent }-{ lv_use_comp }|.

            REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_use_full WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_use_parent WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-dot IN lv_use_comp WITH gc_keyword-empty_string.

            CONDENSE lv_use_full   NO-GAPS.
            CONDENSE lv_use_parent NO-GAPS.
            CONDENSE lv_use_comp   NO-GAPS.

            lv_use_parent = to_upper( lv_use_parent ).
            lv_use_full = to_upper( lv_use_full ).

            lv_use_idx += 3.
          ELSE.
            lv_use_idx += 1.
          ENDIF.
        ELSE.
          lv_use_idx += 1.
        ENDIF.

      ELSE.
        lv_use_idx += 1.
      ENDIF.

      IF lv_use_full IS NOT INITIAL.

        CLEAR lv_match_scope.

        READ TABLE lt_decl
          WITH TABLE KEY
            name     = lv_use_full
            scope_id = lv_curr_scope
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          lv_match_scope = lv_curr_scope.
        ELSEIF lv_curr_scope <> gc_scope-global.
          READ TABLE lt_decl
            WITH TABLE KEY
              name     = lv_use_full
              scope_id = gc_scope-global
            TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            lv_match_scope = gc_scope-global.
          ENDIF.
        ENDIF.

        IF lv_match_scope IS INITIAL
          AND lv_use_full CS gc_keyword-dash.

          READ TABLE lt_decl_prefix
            ASSIGNING <lfs_prefix>
            WITH TABLE KEY prefix = lv_use_full.

          IF sy-subrc = 0
             AND <lfs_prefix>-ambiguous = abap_false
             AND <lfs_prefix>-full_name IS NOT INITIAL.

            lv_use_full = <lfs_prefix>-full_name.

            READ TABLE lt_decl
              WITH TABLE KEY
                name     = lv_use_full
                scope_id = lv_curr_scope
              TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              lv_match_scope = lv_curr_scope.
            ELSEIF lv_curr_scope <> gc_scope-global.
              READ TABLE lt_decl
                WITH TABLE KEY
                  name     = lv_use_full
                  scope_id = gc_scope-global
                TRANSPORTING NO FIELDS.
              IF sy-subrc = 0.
                lv_match_scope = gc_scope-global.
              ENDIF.
            ENDIF.

          ELSE.
            DATA(lv_up) = lv_use_src_line.
            lv_up = to_upper( lv_up ).

            CLEAR: lv_name,
                   lv_match_scope.

            DATA(lv_decl_try_idx) = 0.

            WHILE lv_decl_try_idx < lines( lt_decl_seq ).

              lv_decl_try_idx += 1.

              READ TABLE lt_decl_seq INDEX lv_decl_try_idx INTO DATA(ls_decl_try).
              IF sy-subrc <> 0.
                EXIT.
              ENDIF.

              IF ls_decl_try-name NP |{ lv_use_full }{ gc_keyword-star }|.
                CONTINUE.
              ENDIF.

              IF ls_decl_try-scope_id <> lv_curr_scope
                 AND ls_decl_try-scope_id <> gc_scope-global.
                CONTINUE.
              ENDIF.

              IF lv_up CS ls_decl_try-name.
                lv_name        = ls_decl_try-name.
                lv_match_scope = ls_decl_try-scope_id.
                EXIT.
              ENDIF.

            ENDWHILE..

            IF lv_name IS NOT INITIAL.
              lv_use_full = lv_name.
            ELSE.
              CLEAR lv_use_full.
            ENDIF.

          ENDIF.
        ENDIF.

        IF lv_use_full IS NOT INITIAL
           AND lv_match_scope IS NOT INITIAL
           AND lv_skip_usage = abap_false.
          lv_cnt_key = |{ lv_match_scope };{ lv_use_full }|.

          cc_add_usage_count(
            EXPORTING
              iv_name = lv_cnt_key
            CHANGING
              ct_cnt  = lt_cnt ).
        ENDIF.

        IF lv_use_parent IS NOT INITIAL.
          CLEAR lv_match_scope.

          READ TABLE lt_decl
            WITH TABLE KEY
              name     = lv_use_parent
              scope_id = lv_curr_scope
            TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            lv_match_scope = lv_curr_scope.
          ELSEIF lv_curr_scope <> gc_scope-global.
            READ TABLE lt_decl
              WITH TABLE KEY
                name     = lv_use_parent
                scope_id = gc_scope-global
              TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              lv_match_scope = gc_scope-global.
            ENDIF.
          ENDIF.

          IF lv_match_scope IS NOT INITIAL
           AND ( lv_skip_usage = abap_false
              OR lv_use_parent CP gc_keyword-field_symbol_pat ).
            lv_cnt_key = |{ lv_match_scope };{ lv_use_parent }|.

            cc_add_usage_count(
              EXPORTING
                iv_name = lv_cnt_key
              CHANGING
                ct_cnt  = lt_cnt ).
          ENDIF.
        ENDIF.

        CONTINUE.
      ENDIF.

      IF ls_use_tok1-type = gc_token_type-identifier.
        CLEAR lv_match_scope.

        READ TABLE lt_decl
          WITH TABLE KEY
            name     = lv_use_tok1
            scope_id = lv_curr_scope
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          lv_match_scope = lv_curr_scope.
        ELSEIF lv_curr_scope <> gc_scope-global.
          READ TABLE lt_decl
            WITH TABLE KEY
              name     = lv_use_tok1
              scope_id = gc_scope-global
            TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            lv_match_scope = gc_scope-global.
          ENDIF.
        ENDIF.

        IF lv_match_scope IS NOT INITIAL
           AND lv_skip_usage = abap_false.
          lv_cnt_key = |{ lv_match_scope };{ lv_use_tok1 }|.

          cc_add_usage_count(
            EXPORTING
              iv_name = lv_cnt_key
            CHANGING
              ct_cnt  = lt_cnt ).
        ENDIF.
      ENDIF.

    ENDWHILE.
  ENDLOOP.

  "------------------------------------------------------------
  " Count raw usage inside DEFINE ... END-OF-DEFINITION
  "------------------------------------------------------------
  lv_i = 0.

  WHILE lv_i < lines( lt_usage_source ).
    lv_i += 1.
    READ TABLE lt_usage_source INDEX lv_i INTO lv_use_src_line.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    lv_use_tok1 = lv_use_src_line.
    TRANSLATE lv_use_tok1 TO UPPER CASE.

    FIND FIRST OCCURRENCE OF gc_keyword-quote
      IN lv_use_tok1
      MATCH OFFSET lv_off.

    IF sy-subrc = 0.
      lv_use_tok1 = lv_use_tok1(lv_off).
    ENDIF.

    CONDENSE lv_use_tok1.

    IF lv_use_tok1 <> gc_keyword-define
       AND lv_use_tok1 NP |{ gc_keyword-define } { gc_keyword-star }|.
      CONTINUE.
    ENDIF.

    lv_i += 1.

    WHILE lv_i <= lines( lt_usage_source ).

      READ TABLE lt_usage_source INDEX lv_i INTO lv_use_src_line.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_use_tok1 = lv_use_src_line.
      TRANSLATE lv_use_tok1 TO UPPER CASE.

      FIND FIRST OCCURRENCE OF gc_keyword-quote
        IN lv_use_tok1
        MATCH OFFSET lv_off.

      IF sy-subrc = 0.
        lv_use_tok1 = lv_use_tok1(lv_off).
      ENDIF.

      CONDENSE lv_use_tok1.

      IF lv_use_tok1 CP |{ gc_keyword-end_of_definition }{ gc_keyword-star }|.
        EXIT.
      ENDIF.

      IF lv_use_tok1 IS INITIAL.
        lv_i += 1.
        CONTINUE.
      ENDIF.

      REPLACE ALL OCCURRENCES OF gc_keyword-lparen IN lv_use_tok1 WITH space.
      REPLACE ALL OCCURRENCES OF gc_keyword-rparen IN lv_use_tok1 WITH space.
      REPLACE ALL OCCURRENCES OF gc_keyword-comma  IN lv_use_tok1 WITH space.
      REPLACE ALL OCCURRENCES OF gc_keyword-dot    IN lv_use_tok1 WITH space.
      REPLACE ALL OCCURRENCES OF gc_keyword-equal  IN lv_use_tok1 WITH space.
      REPLACE ALL OCCURRENCES OF gc_keyword-colon  IN lv_use_tok1 WITH space.

      CONDENSE lv_use_tok1.
      lv_use_tok1 = | { lv_use_tok1 } |.

      LOOP AT lt_decl INTO DATA(ls_define_decl).

        CLEAR: lv_match_scope,
               lv_name.

        lv_name = ls_define_decl-name.
        TRANSLATE lv_name TO UPPER CASE.

        IF lv_name IS INITIAL.
          CONTINUE.
        ENDIF.

        IF lv_use_tok1 CS | { lv_name } |
           OR lv_use_tok1 CS | { lv_name }{ gc_keyword-dash }|.
          lv_cnt_key = |{ ls_define_decl-scope_id };{ ls_define_decl-name }|.
          cc_add_usage_count(
            EXPORTING
              iv_name = lv_cnt_key
            CHANGING
              ct_cnt  = lt_cnt ).
        ENDIF.
      ENDLOOP.
      lv_i += 1.
    ENDWHILE.

  ENDWHILE.

  "------------------------------------------------------------
  " Emit warnings
  "------------------------------------------------------------
  LOOP AT lt_decl INTO DATA(ls_decl).

    lv_cnt_key = |{ ls_decl-scope_id };{ ls_decl-name }|.

    READ TABLE lt_cnt
      WITH TABLE KEY name = lv_cnt_key
      INTO DATA(ls_cnt).

    DATA(lv_cnt) = ls_decl-base_cnt.
    IF sy-subrc = 0.
      lv_cnt += ls_cnt-cnt.
    ENDIF.

    IF ls_decl-name CS gc_keyword-dash.
      IF lv_cnt > 0.
        CONTINUE.
      ENDIF.
    ELSE.
      IF lv_cnt > gc_clean_code-unused_token_limit.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF ls_decl-name CS gc_keyword-dash.
      SPLIT ls_decl-name AT gc_keyword-dash INTO DATA(lv_parent_name_u) lv_ignore.
      lv_parent_name_u = to_upper( lv_parent_name_u ).

      lv_cnt_key = |{ ls_decl-scope_id };{ lv_parent_name_u }|.

      READ TABLE lt_struct_type_roots
        WITH TABLE KEY name_u = lv_cnt_key TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.

        READ TABLE lt_cnt
          WITH TABLE KEY name = lv_cnt_key
          INTO ls_cnt.

        IF sy-subrc = 0
           AND ls_cnt-cnt > gc_clean_code-unused_token_limit.
          CONTINUE.
        ENDIF.
      ENDIF.
    ENDIF.

    " Suppress safe SELECT SINGLE existence-check dummy target
    CLEAR lv_match_scope.
    DATA(lv_exist_stmt_idx) = 0.

    WHILE lv_exist_stmt_idx < lines( lt_stmt_ctx ).
      lv_exist_stmt_idx += 1.
      READ TABLE lt_stmt_ctx INDEX lv_exist_stmt_idx INTO DATA(ls_exist_stmt).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      CLEAR: lv_use_full,
             lv_use_tok1,
             lv_use_tok2,
             lv_use_tok3.

      IF ls_exist_stmt-first_u <> gc_keyword-select
         OR ls_exist_stmt-second_u <> gc_keyword-single.
        CONTINUE.
      ENDIF.

      READ TABLE lt_tokens INDEX ls_exist_stmt-from INTO DATA(ls_exist_from_tok).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      READ TABLE lt_tokens INDEX ls_exist_stmt-to INTO DATA(ls_exist_to_tok).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF ls_decl-line < ls_exist_from_tok-row
         OR ls_decl-line > ls_exist_to_tok-row.
        CONTINUE.
      ENDIF.

      "Build full SELECT statement text
      lv_i = ls_exist_from_tok-row.

      WHILE lv_i <= ls_exist_to_tok-row.

        READ TABLE lt_usage_source INDEX lv_i INTO lv_use_src_line.
        IF sy-subrc = 0.
          TRANSLATE lv_use_src_line TO UPPER CASE.

          FIND FIRST OCCURRENCE OF gc_keyword-quote
            IN lv_use_src_line
            MATCH OFFSET lv_off.

          IF sy-subrc = 0.
            lv_use_src_line = lv_use_src_line(lv_off).
          ENDIF.

          CONCATENATE lv_use_full lv_use_src_line
            INTO lv_use_full
            SEPARATED BY space.
        ENDIF.

        lv_i += 1.
      ENDWHILE.

      CONDENSE lv_use_full.

      IF lv_use_full NS ls_decl-name.
        CONTINUE.
      ENDIF.

      "Selected field after SELECT SINGLE
      READ TABLE lt_tokens INDEX ( ls_exist_stmt-from + 2 ) INTO DATA(ls_exist_select_tok).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_use_tok1 = to_upper( ls_exist_select_tok-str ).
      REPLACE ALL OCCURRENCES OF gc_keyword-at_sign IN lv_use_tok1 WITH gc_keyword-empty_string.
      REPLACE ALL OCCURRENCES OF gc_keyword-dot     IN lv_use_tok1 WITH gc_keyword-empty_string.
      CONDENSE lv_use_tok1 NO-GAPS.

      "Find first field after WHERE
      CLEAR lv_use_tok2.
      lv_i = ls_exist_stmt-from.

      WHILE lv_i <= ls_exist_stmt-to.

        READ TABLE lt_tokens INDEX lv_i INTO DATA(ls_exist_where_tok).
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        IF to_upper( ls_exist_where_tok-str ) = gc_keyword-where.

          READ TABLE lt_tokens INDEX ( lv_i + 1 ) INTO DATA(ls_exist_where_field).
          IF sy-subrc = 0.
            lv_use_tok2 = to_upper( ls_exist_where_field-str ).
            REPLACE ALL OCCURRENCES OF gc_keyword-at_sign IN lv_use_tok2 WITH gc_keyword-empty_string.
            REPLACE ALL OCCURRENCES OF gc_keyword-dot     IN lv_use_tok2 WITH gc_keyword-empty_string.
            CONDENSE lv_use_tok2 NO-GAPS.
          ENDIF.
          EXIT.

        ENDIF.

        lv_i += 1.

      ENDWHILE.

      IF lv_use_tok1 IS INITIAL
         OR lv_use_tok2 IS INITIAL
         OR lv_use_tok1 <> lv_use_tok2.
        CONTINUE.
      ENDIF.

      "Check next few lines after SELECT statement for SY-SUBRC
      CLEAR lv_use_tok3.
      lv_i = ls_exist_to_tok-row + 1.

      WHILE lv_i <= lines( lt_usage_source )
        AND lv_i <= ls_exist_to_tok-row + 5.

        READ TABLE lt_usage_source INDEX lv_i INTO lv_use_src_line.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        TRANSLATE lv_use_src_line TO UPPER CASE.

        FIND FIRST OCCURRENCE OF gc_keyword-quote
          IN lv_use_src_line
          MATCH OFFSET lv_off.

        IF sy-subrc = 0.
          lv_use_src_line = lv_use_src_line(lv_off).
        ENDIF.

        CONDENSE lv_use_src_line.

        IF lv_use_src_line IS INITIAL.
          lv_i += 1.
          CONTINUE.
        ENDIF.

        IF lv_use_src_line CS gc_keyword-sy_subrc.
          lv_use_tok3 = abap_true.
        ENDIF.
        EXIT.

      ENDWHILE.

      IF lv_use_tok3 = abap_true.
        lv_match_scope = abap_true.
        EXIT.
      ENDIF.

    ENDWHILE.

    IF lv_match_scope = abap_true.
      CONTINUE.
    ENDIF.

    MESSAGE w023(z_gsp04_message) WITH ls_decl-name INTO lv_text.

    APPEND VALUE zst_error(
      rule     = gc_rule_cc-unused_local
      sev      = gc_severity-warning
      line     = ls_decl-line
      msg      = lv_text
      category = gc_category-clean_code
    ) TO rt_errors.

  ENDLOOP.

ENDMETHOD.


METHOD nm_build_method_ret_kind.

  DATA: lv_idx         TYPE sy-tabix,
        lv_probe_idx   TYPE sy-tabix,
        lv_return_idx  TYPE sy-tabix,
        lv_type_idx    TYPE sy-tabix,
        lv_method_name TYPE string,
        lv_return_kind TYPE gty_nm_kind.

  CLEAR ct_method_ret_cache.

  LOOP AT it_tokens INTO DATA(ls_tok).

    lv_idx = sy-tabix.

    DATA(lv_tok_u) = to_upper( ls_tok-str ).

    " Only read method declarations in class definition:
    " METHODS get_xxx ... RETURNING VALUE(...) TYPE ...
    IF lv_tok_u <> gc_keyword-methods
       AND lv_tok_u <> gc_keyword-methods_col.
      CONTINUE.
    ENDIF.

    " Next token should be method name
    READ TABLE it_tokens INDEX ( lv_idx + 1 ) INTO DATA(ls_method_tok).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF ls_method_tok-type <> gc_token_type-identifier.
      CONTINUE.
    ENDIF.

    lv_method_name = to_upper( ls_method_tok-str ).
    CONDENSE lv_method_name NO-GAPS.

    CLEAR: lv_probe_idx,
           lv_return_idx,
           lv_type_idx,
           lv_return_kind.

    lv_probe_idx = lv_idx + 1.

    " Search RETURNING in the same method declaration statement
    WHILE lv_probe_idx <= lines( it_tokens ).

      READ TABLE it_tokens INDEX lv_probe_idx INTO DATA(ls_probe).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      DATA(lv_probe_u) = to_upper( ls_probe-str ).

      " Stop at end of declaration
      IF lv_probe_u = gc_keyword-dot.
        EXIT.
      ENDIF.

      IF lv_probe_u = gc_keyword-returning.

        lv_return_idx = lv_probe_idx + 1.

        " Find TYPE or LIKE after RETURNING VALUE(...)
        WHILE lv_return_idx <= lines( it_tokens ).

          READ TABLE it_tokens INDEX lv_return_idx INTO DATA(ls_return_tok).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          DATA(lv_return_u) = to_upper( ls_return_tok-str ).

          IF lv_return_u = gc_keyword-dot
             OR lv_return_u = gc_keyword-comma.
            EXIT.
          ENDIF.

          IF lv_return_u = gc_keyword-type
             OR lv_return_u = gc_keyword-like.
            lv_type_idx = lv_return_idx.
            EXIT.
          ENDIF.

          lv_return_idx += 1.

        ENDWHILE.

        IF lv_type_idx IS NOT INITIAL.

          CLEAR: lv_return_kind.

          me->nm_resolve_sig_kind(
            EXPORTING
              it_tokens     = it_tokens
              iv_from       = lv_type_idx
              iv_to         = lines( it_tokens )
            IMPORTING
              ev_kind       = lv_return_kind
            CHANGING
              ct_type_cache = ct_type_cache ).

          IF lv_return_kind IS NOT INITIAL.

            READ TABLE ct_method_ret_cache
              WITH TABLE KEY method_name = lv_method_name
              TRANSPORTING NO FIELDS.

            IF sy-subrc <> 0.
              INSERT VALUE gty_nm_method_ret(
                method_name = lv_method_name
                return_kind = lv_return_kind )
                INTO TABLE ct_method_ret_cache.
            ENDIF.

          ENDIF.

        ENDIF.

        EXIT.

      ENDIF.

      lv_probe_idx += 1.

    ENDWHILE.

  ENDLOOP.

ENDMETHOD.


METHOD nm_resolve_called_method_kind.

  DATA: lt_candidates    TYPE string_table,
        lv_candidate     TYPE string,
        lv_expr          TYPE string,
        lv_after         TYPE string,
        lv_before        TYPE string,
        lv_called_method TYPE string.

  CLEAR rv_kind.

  "Candidate 1: previous token
  "Example: iv_prev_u = ME->GET_SOURCE_CODE(
  APPEND iv_prev_u TO lt_candidates.

  "Candidate 2: current token
  "Example: iv_probe_u = ME->GET_SOURCE_CODE(
  APPEND iv_probe_u TO lt_candidates.

  "Split-token case:
  "Example: ME -> GET_SOURCE_CODE (
  IF iv_prev_u = gc_keyword-instance_call
     OR iv_prev_u = gc_keyword-static_call.
    APPEND iv_probe_u TO lt_candidates.

    "Build full static call candidate:
    "Example: CL_ABAP_TYPEDESCR => DESCRIBE_BY_NAME
    IF iv_prev_u = gc_keyword-static_call.
      READ TABLE it_tokens INDEX ( iv_probe_idx - 2 ) INTO DATA(ls_prev2_call).
      IF sy-subrc = 0.
        APPEND |{ ls_prev2_call-str }{ gc_keyword-static_call }{ iv_probe_u }|
          TO lt_candidates.
      ENDIF.
    ENDIF.
  ENDIF.

  "Split-token receiver case:
  "Example: current token = CL_ABAP_TYPEDESCR, next token = =>, method name = token + 2
  IF iv_next_u = gc_keyword-instance_call
     OR iv_next_u = gc_keyword-static_call.

    READ TABLE it_tokens INDEX ( iv_probe_idx + 2 ) INTO DATA(ls_next2).
    IF sy-subrc = 0.
      APPEND ls_next2-str TO lt_candidates.

      IF iv_next_u = gc_keyword-static_call.
        APPEND |{ iv_probe_u }{ gc_keyword-static_call }{ ls_next2-str }|
          TO lt_candidates.
      ENDIF.
    ENDIF.

  ENDIF.

  LOOP AT lt_candidates INTO lv_candidate.

    CLEAR: lv_expr,
           lv_after,
           lv_before,
           lv_called_method.

    lv_expr = to_upper( lv_candidate ).
    CONDENSE lv_expr NO-GAPS.

    IF lv_expr IS INITIAL.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Precise static method return-kind by RTTS
    " Example: CL_ABAP_TYPEDESCR=>DESCRIBE_BY_NAME
    "------------------------------------------------------------
    IF lv_expr CS gc_keyword-static_call.

      SPLIT lv_expr AT gc_keyword-static_call
        INTO lv_before lv_after.

      lv_called_method = lv_after.

      IF lv_called_method CS gc_keyword-lparen.
        SPLIT lv_called_method AT gc_keyword-lparen
          INTO lv_called_method lv_after.
      ENDIF.

      REPLACE ALL OCCURRENCES OF gc_keyword-lparen
        IN lv_called_method WITH ''.

      REPLACE ALL OCCURRENCES OF gc_keyword-rparen
        IN lv_called_method WITH ''.

      CONDENSE lv_called_method NO-GAPS.

      IF lv_before IS NOT INITIAL
         AND lv_called_method IS NOT INITIAL.

        TRY.

            cl_abap_classdescr=>describe_by_name(
              EXPORTING
                p_name      = lv_before
              RECEIVING
                p_descr_ref = DATA(lo_type_descr)
              EXCEPTIONS
                type_not_found = 1
                OTHERS         = 2 ).

            IF sy-subrc = 0
               AND lo_type_descr IS BOUND
               AND lo_type_descr IS INSTANCE OF cl_abap_classdescr.

              DATA(lo_class_descr) = CAST cl_abap_classdescr( lo_type_descr ).

              READ TABLE lo_class_descr->methods
                INTO DATA(ls_method_descr)
                WITH KEY name = lv_called_method
                BINARY SEARCH..

              IF sy-subrc = 0.
                READ TABLE ls_method_descr-parameters
                INTO DATA(ls_param_descr)
                WITH KEY parm_kind = cl_abap_objectdescr=>returning
                BINARY SEARCH.

                IF sy-subrc = 0.

                  DATA(lo_param_type) = lo_class_descr->get_method_parameter_type(
                    p_method_name    = lv_called_method
                    p_parameter_name = ls_param_descr-name ).

                  IF lo_param_type IS INSTANCE OF cl_abap_tabledescr.
                    rv_kind = gc_kind_nm-table.
                    RETURN.

                  ELSEIF lo_param_type IS INSTANCE OF cl_abap_structdescr.
                    rv_kind = gc_kind_nm-structure.
                    RETURN.

                  ELSEIF lo_param_type IS INSTANCE OF cl_abap_refdescr.

                    DATA(lo_ref_descr) = CAST cl_abap_refdescr( lo_param_type ).
                    DATA(lo_ref_type)  = lo_ref_descr->get_referenced_type( ).

                    IF lo_ref_type IS INSTANCE OF cl_abap_objectdescr.
                      rv_kind = gc_kind_nm-object.
                    ELSE.
                      rv_kind = gc_kind_nm-data_ref.
                    ENDIF.

                    RETURN.

                  ELSE.
                    rv_kind = gc_kind_nm-value.
                    RETURN.
                  ENDIF.

                ENDIF.

              ENDIF.
            ENDIF.

          CATCH cx_root.
            CLEAR rv_kind.
        ENDTRY.
      ENDIF.
    ENDIF.

    "------------------------------------------------------------
    " Existing cache fallback
    "------------------------------------------------------------
    CLEAR: lv_after,
           lv_before,
           lv_called_method.

    "Compact instance call: ME->GET_SOURCE_CODE(
    IF lv_expr CS gc_keyword-instance_call.

      SPLIT lv_expr AT gc_keyword-instance_call
        INTO lv_before lv_after.

      lv_called_method = lv_after.

      "Compact static call: ZCL_CLASS=>GET_SOURCE_CODE(
    ELSEIF lv_expr CS gc_keyword-static_call.

      SPLIT lv_expr AT gc_keyword-static_call
        INTO lv_before lv_after.

      lv_called_method = lv_after.

    ELSE.

      "Already method name, e.g. GET_SOURCE_CODE
      lv_called_method = lv_expr.

    ENDIF.

    "Remove parameter bracket
    IF lv_called_method CS gc_keyword-lparen.
      SPLIT lv_called_method AT gc_keyword-lparen
        INTO lv_called_method lv_after.
    ENDIF.

    REPLACE ALL OCCURRENCES OF gc_keyword-lparen
      IN lv_called_method WITH ''.

    REPLACE ALL OCCURRENCES OF gc_keyword-rparen
      IN lv_called_method WITH ''.

    CONDENSE lv_called_method NO-GAPS.

    IF lv_called_method IS INITIAL.
      CONTINUE.
    ENDIF.

    READ TABLE it_method_ret_kind INTO DATA(ls_method_ret_kind)
      WITH TABLE KEY method_name = lv_called_method.

    IF sy-subrc = 0.
      rv_kind = ls_method_ret_kind-return_kind.
      RETURN.
    ENDIF.

  ENDLOOP.

ENDMETHOD.
ENDCLASS.
