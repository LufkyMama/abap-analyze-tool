CLASS zcl_program_check DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_naming_ctx,
        obj_type  TYPE c LENGTH 10,
        obj_name  TYPE string,
        main_prog TYPE progname,
        include   TYPE progname,
      END OF ty_naming_ctx .

    DATA it_source TYPE string_table .

    METHODS analyze_clean_code
      IMPORTING
        is_ctx           TYPE ty_naming_ctx
        it_source        TYPE string_table
      RETURNING
        VALUE(rt_errors) TYPE ztt_error.
    METHODS analyze_hardcode
      IMPORTING
        !it_source       TYPE string_table
      RETURNING
        VALUE(rt_errors) TYPE ztt_error .
    METHODS analyze_obsolete
      IMPORTING
        !it_source       TYPE string_table
      RETURNING
        VALUE(et_errors) TYPE ztt_error .
    METHODS analyze_naming
      IMPORTING
        !is_ctx          TYPE ty_naming_ctx
        !it_source       TYPE string_table
      RETURNING
        VALUE(rt_errors) TYPE ztt_error .
  PROTECTED SECTION.
PRIVATE SECTION.

  CONSTANTS:
    BEGIN OF gc_obj_prefix,
      z TYPE c LENGTH 1 VALUE 'Z',
      y TYPE c LENGTH 1 VALUE 'Y',
    END OF gc_obj_prefix,

    BEGIN OF gc_severity,
      error   TYPE symsgty VALUE 'E',
      warning TYPE symsgty VALUE 'W',
    END OF gc_severity,

    BEGIN OF gc_token_type,
      identifier TYPE c LENGTH 1 VALUE 'I',
      list       TYPE c LENGTH 1 VALUE 'L',
    END OF gc_token_type,

    BEGIN OF gc_rule,
      obj_prefix         TYPE string VALUE 'NAMING_OBJ_PREFIX_ZY',
      source_empty       TYPE string VALUE 'NAMING_SOURCE_EMPTY',
      scan_error         TYPE string VALUE 'NAMING_SCAN_ERROR',
      scan_runtime       TYPE string VALUE 'NAMING_SCAN_RUNTIME',
      scan_unknown       TYPE string VALUE 'NAMING_SCAN_UNKNOWN',
      prefix_rule        TYPE string VALUE 'NAMING_PREFIX_RULE',
      wa_prefix_obsolete TYPE string VALUE 'NAMING_WA_PREFIX_OBSOLETE',
    END OF gc_rule,

    BEGIN OF gc_pat_local,
      lc  TYPE string VALUE 'LC_*',
      lv  TYPE string VALUE 'LV_*',
      ls  TYPE string VALUE 'LS_*',
      lt  TYPE string VALUE 'LT_*',
      lo  TYPE string VALUE 'LO_*',
      lr  TYPE string VALUE 'LR_*',
      lm  TYPE string VALUE 'LM_*',
      lty TYPE string VALUE 'LTY_*',
    END OF gc_pat_local,

    BEGIN OF gc_pat_global,
      gc  TYPE string VALUE 'GC_*',
      gv  TYPE string VALUE 'GV_*',
      gs  TYPE string VALUE 'GS_*',
      gt  TYPE string VALUE 'GT_*',
      gr  TYPE string VALUE 'GR_*',
      gm  TYPE string VALUE 'GM_*',
      st  TYPE string VALUE 'ST_*',
      gty TYPE string VALUE 'GTY_*',
    END OF gc_pat_global,

    BEGIN OF gc_pat_obsolete,
      wa TYPE string VALUE 'WA_*',
    END OF gc_pat_obsolete,

    BEGIN OF gc_keyword,
      data      TYPE string VALUE 'DATA',
      data_col  TYPE string VALUE 'DATA:',
      type      TYPE string VALUE 'TYPE',
      like      TYPE string VALUE 'LIKE',
      value     TYPE string VALUE 'VALUE',
      ref       TYPE string VALUE 'REF',
      to        TYPE string VALUE 'TO',
      table_kw  TYPE string VALUE 'TABLE',
      of_kw     TYPE string VALUE 'OF',
      standard  TYPE string VALUE 'STANDARD',
      sorted    TYPE string VALUE 'SORTED',
      hashed    TYPE string VALUE 'HASHED',
      with_kw   TYPE string VALUE 'WITH',
      key_kw    TYPE string VALUE 'KEY',
      default   TYPE string VALUE 'DEFAULT',
      empty     TYPE string VALUE 'EMPTY',
      initial   TYPE string VALUE 'INITIAL',
      line_kw   TYPE string VALUE 'LINE',
      length_kw TYPE string VALUE 'LENGTH',
      dot       TYPE string VALUE '.',
      comma     TYPE string VALUE ',',
      colon     TYPE string VALUE ':',
      lparen    TYPE string VALUE '(',
      rparen    TYPE string VALUE ')',
      equal     TYPE string VALUE '=',
      ">>> Scope keywords (simple)
      form      TYPE string VALUE 'FORM',
      endform   TYPE string VALUE 'ENDFORM',
      method    TYPE string VALUE 'METHOD',
      endmethod TYPE string VALUE 'ENDMETHOD',
      func      TYPE string VALUE 'FUNCTION',
      endfunc   TYPE string VALUE 'ENDFUNCTION',
      module    TYPE string VALUE 'MODULE',
      endmodule TYPE string VALUE 'ENDMODULE',
    END OF gc_keyword,
    "--------------------------------------------------
    " Obsolete single-token keywords
    " These can be checked directly from SCAN tokens
    "--------------------------------------------------
    BEGIN OF gc_kw_obsolete,
      move_kw      TYPE string VALUE 'MOVE',
      occurs_kw    TYPE string VALUE 'OCCURS',
      ranges_kw    TYPE string VALUE 'RANGES',
      compute_kw   TYPE string VALUE 'COMPUTE',
      tables_kw    TYPE string VALUE 'TABLES',
      extract_kw   TYPE string VALUE 'EXTRACT',
      field_groups TYPE string VALUE 'FIELD-GROUPS',
      data         TYPE string VALUE 'DATA',
    END OF gc_kw_obsolete,

    "--------------------------------------------------
    " Obsolete multi-word phrases
    " These must be checked on source lines, not token only
    "--------------------------------------------------
    BEGIN OF gc_phrase_obsolete,
      with_header_line TYPE string VALUE 'WITH HEADER LINE',
      on_change_of     TYPE string VALUE 'ON CHANGE OF',
      call_function    TYPE string VALUE 'CALL FUNCTION',
      like_line_of     TYPE string VALUE 'LIKE LINE OF',
    END OF gc_phrase_obsolete,

    "--------------------------------------------------
    " Rule IDs / codes for obsolete syntax
    " Useful if you want stable identifiers in ALV or logs
    "--------------------------------------------------
    BEGIN OF gc_rule_obsolete,
      move_rule         TYPE string VALUE 'OBSOLETE_MOVE',
      occurs_rule       TYPE string VALUE 'OBSOLETE_OCCURS',
      ranges_rule       TYPE string VALUE 'OBSOLETE_RANGES',
      compute_rule      TYPE string VALUE 'OBSOLETE_COMPUTE',
      tables_rule       TYPE string VALUE 'OBSOLETE_TABLES',
      extract_rule      TYPE string VALUE 'OBSOLETE_EXTRACT',
      field_groups_rule TYPE string VALUE 'OBSOLETE_FIELD_GROUPS',
      header_line_rule  TYPE string VALUE 'OBSOLETE_WITH_HEADER_LINE',
      on_change_rule    TYPE string VALUE 'OBSOLETE_ON_CHANGE_OF',
      call_func_rule    TYPE string VALUE 'OBSOLETE_CALL_FUNCTION',
      like_line_rule    TYPE string VALUE 'OBSOLETE_LIKE_LINE_OF',
    END OF gc_rule_obsolete.

  TYPES:
*  "Payload để add_error map sang ZST_ERROR
    BEGIN OF ty_error_payload,
      rule_id  TYPE string,
      severity TYPE c LENGTH 1,
      obj_type TYPE string,
      obj_name TYPE string,
      include  TYPE string,
      line     TYPE i,
      message  TYPE string,
    END OF ty_error_payload.

  TYPES: ty_tok_tab  TYPE STANDARD TABLE OF stokex WITH DEFAULT KEY,
         ty_stmt_tab TYPE STANDARD TABLE OF sstmnt WITH DEFAULT KEY.

  DATA rt_errors TYPE ztt_error.

  METHODS add_error
    IMPORTING
      !is_payload TYPE ty_error_payload
    CHANGING
      !ct_errors  TYPE ztt_error.
ENDCLASS.



CLASS ZCL_PROGRAM_CHECK IMPLEMENTATION.


METHOD add_error.
*  METHOD add_error.
*    DATA ls_err TYPE zst_error.
*    DATA lv_code TYPE string.
*
*    CLEAR ls_err.
*    CLEAR lv_code.
*
*    "Map đúng field thật của ZST_ERROR
*    ls_err-line = is_payload-line.
*    ls_err-sev  = is_payload-severity.
*    ls_err-msg  = is_payload-message.
*
*    "CODE: nhét metadata để trace (tuỳ bạn)
*    "Ví dụ: RULE|OBJTYPE|OBJNAME|INCLUDE
*    CONCATENATE is_payload-rule_id
*                is_payload-obj_type
*                is_payload-obj_name
*                is_payload-include
*           INTO lv_code
*           SEPARATED BY '|'.
*
*    ls_err-code = lv_code.
*
*    APPEND ls_err TO ct_errors.
*  ENDMETHOD.


  DATA: ls_err TYPE zst_error.

  CLEAR ls_err.

  " Core
  ls_err-line = is_payload-line.
  ls_err-sev  = is_payload-severity.
  ls_err-msg  = is_payload-message.

*  Code snippet
*  ls_err-code = is_payload-code.

  " Metadata theo đúng cột structure
  ls_err-rule     = is_payload-rule_id.
  ls_err-category = is_payload-obj_type.
  ls_err-objname  = is_payload-obj_name.
  ls_err-include  = is_payload-include.

  " Audit info
  ls_err-chk_date = sy-datum.
  ls_err-chk_usr  = sy-uname.

*  " Optional parameters
*  ls_err-param1 = is_payload-param1.
*  ls_err-param2 = is_payload-param2.

  APPEND ls_err TO ct_errors.

ENDMETHOD.


METHOD analyze_clean_code.

  "============================================================
  " A) SCAN + common payload
  "============================================================
  DATA lt_tokens  TYPE STANDARD TABLE OF stokex.
  DATA lt_stmts   TYPE STANDARD TABLE OF sstmnt.
  DATA ls_payload TYPE ty_error_payload.

  DATA lv_msg     TYPE string.  "dùng chung để build message
  DATA lv_subrc_s TYPE string.

  CLEAR rt_errors.

  CONSTANTS c_line_unknown      TYPE i     VALUE 0.
  CONSTANTS c_sev_e             TYPE char1 VALUE 'E'.
  CONSTANTS c_sev_w             TYPE char1 VALUE 'W'.  "dùng chung cho warning

  CONSTANTS c_rule_source_empty TYPE string VALUE 'CC_SOURCE_EMPTY'.
  CONSTANTS c_rule_scan_failed  TYPE string VALUE 'CC_SCAN_FAILED'.

  CONSTANTS c_msg_source_empty  TYPE string VALUE 'Source empty - cannot analyze clean code.'.
  CONSTANTS c_msg_scan_prefix   TYPE string VALUE 'SCAN failed (subrc='.
  CONSTANTS c_msg_scan_mid      TYPE string VALUE ') for'.
  CONSTANTS c_msg_dot           TYPE string VALUE '.'.

  "============================================================
  " B) RULE 1 - Blank lines
  "============================================================
  DATA lv_blank_run    TYPE i VALUE 0.
  DATA lv_blank_start  TYPE i VALUE 0.
  DATA lv_blank_warned TYPE abap_bool VALUE abap_false.

  DATA lv_line TYPE string.
  DATA lv_trim TYPE string.
  DATA lv_up   TYPE string.
  DATA lv_i    TYPE i.

  CONSTANTS c_blank_limit      TYPE i      VALUE 3.
  CONSTANTS c_rule_blank_lines TYPE string VALUE 'CC_BLANK_LINES'.
  CONSTANTS c_msg_blank_lines  TYPE string VALUE
    'More than 3 consecutive blank lines. Consider removing extra empty lines.'.

  "============================================================
  " C) RULE 2 - Unused
  "============================================================
  CONSTANTS c_unused_token_limit TYPE i      VALUE 1.
  CONSTANTS c_rule_unused_local  TYPE string VALUE 'CC_UNUSED_LOCAL'.
  CONSTANTS c_msg_unused_prefix  TYPE string VALUE 'Declared but not used:'.
  CONSTANTS c_msg_unused_suffix  TYPE string VALUE '. Remove if truly unused.'.

  CONSTANTS c_re_inline_data TYPE string VALUE `DATA\(([^)]+)\)`.

  CONSTANTS c_cmt_star  TYPE c LENGTH 1 VALUE '*'.
  CONSTANTS c_cmt_quote TYPE c LENGTH 1 VALUE '"'.

  CONSTANTS c_pat_data1  TYPE string VALUE 'DATA *'.
  CONSTANTS c_pat_data2  TYPE string VALUE 'DATA:*'.
  CONSTANTS c_pat_cons1  TYPE string VALUE 'CONSTANTS *'.
  CONSTANTS c_pat_cons2  TYPE string VALUE 'CONSTANTS:*'.
  CONSTANTS c_pat_types1 TYPE string VALUE 'TYPES *'.
  CONSTANTS c_pat_types2 TYPE string VALUE 'TYPES:*'.
  CONSTANTS c_pat_fs1    TYPE string VALUE 'FIELD-SYMBOLS *'.
  CONSTANTS c_pat_fs2    TYPE string VALUE 'FIELD-SYMBOLS:*'.

  CONSTANTS c_kw_data  TYPE string VALUE 'DATA'.
  CONSTANTS c_kw_cons  TYPE string VALUE 'CONSTANTS'.
  CONSTANTS c_kw_types TYPE string VALUE 'TYPES'.
  CONSTANTS c_kw_fs    TYPE string VALUE 'FIELD-SYMBOLS'.

  TYPES: BEGIN OF ty_decl,
           name TYPE string,
           line TYPE i,
         END OF ty_decl.
  DATA lt_decl TYPE HASHED TABLE OF ty_decl WITH UNIQUE KEY name.

  TYPES: BEGIN OF ty_cnt,
           name TYPE string,
           cnt  TYPE i,
         END OF ty_cnt.
  DATA lt_cnt TYPE HASHED TABLE OF ty_cnt WITH UNIQUE KEY name.

  DATA lt_strip_kw TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  DATA lt_kw       TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.

  "init keyword lists (đặt 1 lần ở đây)
  APPEND c_kw_data  TO lt_strip_kw.
  APPEND c_kw_cons  TO lt_strip_kw.
  APPEND c_kw_types TO lt_strip_kw.
  APPEND c_kw_fs    TO lt_strip_kw.

  INSERT c_kw_data  INTO TABLE lt_kw.
  INSERT c_kw_cons  INTO TABLE lt_kw.
  INSERT c_kw_types INTO TABLE lt_kw.
  INSERT c_kw_fs    INTO TABLE lt_kw.
  INSERT CONV string( 'IF' )        INTO TABLE lt_kw.
  INSERT CONV string( 'ELSE' )      INTO TABLE lt_kw.
  INSERT CONV string( 'ENDIF' )     INTO TABLE lt_kw.
  INSERT CONV string( 'LOOP' )      INTO TABLE lt_kw.
  INSERT CONV string( 'ENDLOOP' )   INTO TABLE lt_kw.
  INSERT CONV string( 'METHOD' )    INTO TABLE lt_kw.
  INSERT CONV string( 'ENDMETHOD' ) INTO TABLE lt_kw.

  "------------------------------------------------------------
  "0) Validate + SCAN deepest
  "------------------------------------------------------------
  IF it_source IS INITIAL.
    CLEAR ls_payload.
    ls_payload-rule_id  = c_rule_source_empty.
    ls_payload-severity = c_sev_e.
    ls_payload-obj_type = is_ctx-obj_type.
    ls_payload-obj_name = is_ctx-obj_name.
    ls_payload-include  = is_ctx-include.
    ls_payload-line     = c_line_unknown.
    ls_payload-message  = c_msg_source_empty.
    me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
    RETURN.
  ENDIF.

  SCAN ABAP-SOURCE it_source
    TOKENS     INTO lt_tokens
    STATEMENTS INTO lt_stmts
    WITH ANALYSIS.

  IF sy-subrc <> 0.
    lv_subrc_s = sy-subrc.

    CLEAR lv_msg.
    CONCATENATE
      c_msg_scan_prefix lv_subrc_s c_msg_scan_mid
      is_ctx-obj_type is_ctx-obj_name c_msg_dot
      INTO lv_msg SEPARATED BY space.

    CLEAR ls_payload.
    ls_payload-rule_id  = c_rule_scan_failed.
    ls_payload-severity = c_sev_e.
    ls_payload-obj_type = is_ctx-obj_type.
    ls_payload-obj_name = is_ctx-obj_name.
    ls_payload-include  = is_ctx-include.
    ls_payload-line     = c_line_unknown.
    ls_payload-message  = lv_msg.
    me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
    RETURN.
  ENDIF.

  "============================================================
  "RULE 1) Blank lines: > 3 consecutive blank lines => warning
  "============================================================
  lv_i = 0.
  LOOP AT it_source INTO lv_line.
    lv_i += 1.

    lv_trim = lv_line.
    SHIFT lv_trim LEFT  DELETING LEADING  space.
    SHIFT lv_trim RIGHT DELETING TRAILING space.

    SPLIT lv_trim AT '"' INTO lv_trim DATA(lv_cmt_dummy).
    SHIFT lv_trim RIGHT DELETING TRAILING space.

    IF lv_trim IS INITIAL.
      IF lv_blank_run = 0.
        lv_blank_start = lv_i.
      ENDIF.
      lv_blank_run += 1.

      IF lv_blank_run > c_blank_limit AND lv_blank_warned = abap_false.
        lv_blank_warned = abap_true.

        CLEAR ls_payload.
        ls_payload-rule_id  = c_rule_blank_lines.
        ls_payload-severity = c_sev_w.
        ls_payload-obj_type = is_ctx-obj_type.
        ls_payload-obj_name = is_ctx-obj_name.
        ls_payload-include  = is_ctx-include.
        ls_payload-line     = lv_blank_start.
        ls_payload-message  = c_msg_blank_lines.
        me->add_error( EXPORTING is_payload = ls_payload CHANGING  ct_errors = rt_errors ).
      ENDIF.
    ELSE.
      lv_blank_run    = 0.
      lv_blank_start  = 0.
      lv_blank_warned = abap_false.
    ENDIF.
  ENDLOOP.

  "============================================================
  "RULE 2) DEAD + UNUSED => warning
  "============================================================
  "============================================================
  "A) Collect declarations (inline DATA(x) + chained DATA:/TYPES:/...)
  "============================================================
  lv_i = 0.
  LOOP AT it_source INTO lv_line.
    lv_i += 1.

    lv_trim = lv_line.
    SHIFT lv_trim LEFT DELETING LEADING space.

    IF lv_trim IS INITIAL OR lv_trim(1) = c_cmt_star OR lv_trim(1) = c_cmt_quote.
      CONTINUE.
    ENDIF.

    lv_up = lv_trim.
    TRANSLATE lv_up TO UPPER CASE.

    "Inline DATA(x)
    FIND FIRST OCCURRENCE OF PCRE c_re_inline_data IN lv_up SUBMATCHES DATA(lv_inline).
    IF sy-subrc = 0 AND lv_inline IS NOT INITIAL.
      DATA(lv_in_name) = lv_inline.
      TRANSLATE lv_in_name TO UPPER CASE.
      CONDENSE lv_in_name NO-GAPS.
      INSERT VALUE ty_decl( name = lv_in_name line = lv_i ) INTO TABLE lt_decl.
    ENDIF.

    "Leading declarations (chained)
    IF    lv_up CP c_pat_data1  OR lv_up CP c_pat_data2
       OR lv_up CP c_pat_cons1  OR lv_up CP c_pat_cons2
       OR lv_up CP c_pat_types1 OR lv_up CP c_pat_types2
       OR lv_up CP c_pat_fs1    OR lv_up CP c_pat_fs2.

      "Build full statement until '.'
      DATA(lv_stmt) = lv_trim.
      SPLIT lv_stmt AT '"' INTO lv_stmt DATA(lv_cmt0).
      SHIFT lv_stmt RIGHT DELETING TRAILING space.

      DATA(lv_j) = lv_i.
      WHILE lv_stmt NS '.' AND lv_j < lines( it_source ).
        lv_j += 1.
        READ TABLE it_source INDEX lv_j INTO DATA(lv_next).
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        DATA(lv_next_trim) = lv_next.
        SHIFT lv_next_trim LEFT  DELETING LEADING  space.
        SHIFT lv_next_trim RIGHT DELETING TRAILING space.
        SPLIT lv_next_trim AT '"' INTO lv_next_trim DATA(lv_cmtx).
        SHIFT lv_next_trim RIGHT DELETING TRAILING space.

        IF lv_next_trim IS NOT INITIAL.
          CONCATENATE lv_stmt lv_next_trim INTO lv_stmt SEPARATED BY space.
        ENDIF.
      ENDWHILE.

      DATA(lv_rest) = lv_stmt.
      TRANSLATE lv_rest TO UPPER CASE.

      LOOP AT lt_strip_kw INTO DATA(lv_kw).
        REPLACE FIRST OCCURRENCE OF lv_kw IN lv_rest WITH ''.
      ENDLOOP.

      SHIFT lv_rest LEFT DELETING LEADING space.
      IF lv_rest CP ':*'. lv_rest = lv_rest+1. ENDIF.
      SHIFT lv_rest LEFT DELETING LEADING space.

      REPLACE ALL OCCURRENCES OF '.' IN lv_rest WITH ''.

      DATA lt_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY.
      SPLIT lv_rest AT ',' INTO TABLE lt_parts.

      LOOP AT lt_parts INTO DATA(lv_part).
        DATA(lv_name) = lv_part.
        SHIFT lv_name LEFT DELETING LEADING space.

        IF lv_name IS INITIAL.
          CONTINUE.
        ENDIF.

        SPLIT lv_name AT space INTO lv_name DATA(dummy).
        REPLACE ALL OCCURRENCES OF '(' IN lv_name WITH ''.
        REPLACE ALL OCCURRENCES OF ')' IN lv_name WITH ''.

        IF lv_name IS INITIAL.
          CONTINUE.
        ENDIF.

        READ TABLE lt_kw WITH TABLE KEY table_line = lv_name TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.

        INSERT VALUE ty_decl( name = lv_name line = lv_i ) INTO TABLE lt_decl.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  "============================================================
  "B) Count occurrences via tokens -> lt_cnt  (RUN ONCE)
  "============================================================
  FIELD-SYMBOLS <tok> TYPE stokex.
  LOOP AT lt_tokens ASSIGNING <tok>.
    DATA(lv_t) = <tok>-str.
    IF lv_t IS INITIAL.
      CONTINUE.
    ENDIF.
    TRANSLATE lv_t TO UPPER CASE.

    READ TABLE lt_decl WITH TABLE KEY name = lv_t INTO DATA(ls_decl).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    READ TABLE lt_cnt WITH TABLE KEY name = lv_t INTO DATA(ls_cnt).
    IF sy-subrc = 0.
      ls_cnt-cnt += 1.
      MODIFY TABLE lt_cnt FROM ls_cnt.
    ELSE.
      INSERT VALUE ty_cnt( name = lv_t cnt = 1 ) INTO TABLE lt_cnt.
    ENDIF.
  ENDLOOP.

  "============================================================
  "C) Raise warnings (RUN ONCE)
  "============================================================
  LOOP AT lt_decl INTO ls_decl.
    READ TABLE lt_cnt WITH TABLE KEY name = ls_decl-name INTO ls_cnt.
    DATA(lv_cnt) = COND i( WHEN sy-subrc = 0 THEN ls_cnt-cnt ELSE 0 ).

    IF lv_cnt <= c_unused_token_limit.
      CONCATENATE c_msg_unused_prefix ls_decl-name c_msg_unused_suffix
        INTO lv_msg SEPARATED BY space.

      CLEAR ls_payload.
      ls_payload-rule_id  = c_rule_unused_local.
      ls_payload-severity = c_sev_w.
      ls_payload-obj_type = is_ctx-obj_type.
      ls_payload-obj_name = is_ctx-obj_name.
      ls_payload-include  = is_ctx-include.
      ls_payload-line     = ls_decl-line.
      ls_payload-message  = lv_msg.

      me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
    ENDIF.
  ENDLOOP.

ENDMETHOD.


METHOD analyze_hardcode.
CLEAR rt_errors.
  CLEAR me->rt_errors.

  DATA: lt_tokens     TYPE STANDARD TABLE OF stokex,
        lt_statements TYPE STANDARD TABLE OF sstmnt,
        ls_token      TYPE stokex,
        ls_error      TYPE zst_error.

  DATA: lv_pat_sq   TYPE string,
        lv_pat_bt   TYPE string,
        lv_pat_pipe TYPE string.

  DATA: lv_tok       TYPE string,
        lv_line      TYPE string,
        lv_line_uc   TYPE string,
        lv_line_cd   TYPE string,
        lv_inside    TYPE string,
        lv_len       TYPE i,
        lv_sub_len   TYPE i,
        lv_pos_quote TYPE i.

  " Patterns nhận diện literal token (dùng CP, tránh regex & tránh lỗi template)
  lv_pat_sq   = '''*'''.   " pattern: '*'
  lv_pat_bt   = '`*`'.     " pattern: `*`
  lv_pat_pipe = '|*|'.     " pattern: |*|

  " 1) Parse ABAP source -> tokens/statements
  SCAN ABAP-SOURCE it_source
       TOKENS     INTO lt_tokens
       STATEMENTS INTO lt_statements
       WITH ANALYSIS.

  " 2) Duyệt tokens để bắt literal token
  LOOP AT lt_tokens INTO ls_token.

    lv_tok = ls_token-str.
    IF lv_tok IS INITIAL.
      CONTINUE.
    ENDIF.

    " 2.1) token có phải text literal / template không?
    IF lv_tok CP lv_pat_sq "CP = Covers Pattern
    OR lv_tok CP lv_pat_bt
    OR lv_tok CP lv_pat_pipe.
      " ok
    ELSE.
      CONTINUE.
    ENDIF.

    " 2.2) bỏ qua literal rỗng
    IF lv_tok = '''''' OR lv_tok = '``' OR lv_tok = '||'.
      CONTINUE.
    ENDIF.

    " 2.3) lấy dòng gốc để filter comment / constants
    CLEAR lv_line.
    READ TABLE it_source INDEX ls_token-row INTO lv_line.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_line_uc = lv_line.
    TRANSLATE lv_line_uc TO UPPER CASE.

    lv_line_cd = lv_line_uc.
    CONDENSE lv_line_cd.
    IF lv_line_cd IS INITIAL.
      CONTINUE.
    ENDIF.

    " full-line comment
    IF lv_line_cd+0(1) = '*'.
      CONTINUE.
    ENDIF.

    " inline comment: nếu có " nằm trước vị trí token thì bỏ
    CLEAR lv_pos_quote.
    FIND FIRST OCCURRENCE OF '"' IN lv_line MATCH OFFSET lv_pos_quote.
    IF sy-subrc = 0.
      " ls_token-col thường là 1-based => so với offset 0-based
      IF lv_pos_quote < ( ls_token-col - 1 ).
        CONTINUE.
      ENDIF.
    ENDIF.

    " bỏ qua CONSTANTS (literal ở constants là hợp lệ)
    IF lv_line_uc CS 'CONSTANTS'.
      CONTINUE.
    ENDIF.

    " 2.4) Với |...|: bỏ qua template chỉ gồm placeholder kiểu |{ lv_var }|
    " (không dùng PCRE để tương thích hệ cũ)
    IF lv_tok CP lv_pat_pipe.
      lv_len = strlen( lv_tok ).
      lv_sub_len = lv_len - 2.
      IF lv_len > 2.
        lv_inside = lv_tok+1(lv_sub_len).  " bỏ 2 dấu | |
        CONDENSE lv_inside NO-GAPS.      " bỏ space

        " nếu chỉ là { ... } thì skip
        IF lv_inside CP '{*}'
          AND lv_inside CS '{'
          AND lv_inside CS '}'.
          " NOTE: đây là check đơn giản, đủ để giảm false-positive
          CONTINUE.
        ENDIF.
      ENDIF.
    ENDIF.

    " 3) Report warning
    CLEAR ls_error.
    ls_error-line = ls_token-row.
    ls_error-sev  = 'W'.
    ls_error-code = lv_tok.
    ls_error-msg  = 'Hardcoded text literal found: Use CONSTANTS/TEXT symbols'.

    " --- thêm payload metadata (nếu ZST_ERROR có các field này) ---
    ls_error-rule     = 'HC_TEXT'.        " tên rule tuỳ bạn
    ls_error-category = 'HARDCODE'.       " nhóm lỗi
    " Nếu bạn có context object/include thì set, không thì để trống
    " ls_error-objname  = mv_objname.
    " ls_error-include  = mv_include.

    " --- thêm audit info ---
    ls_error-chk_date = sy-datum.
    ls_error-chk_usr  = sy-uname.

    APPEND ls_error TO me->rt_errors.

  ENDLOOP.

  rt_errors = me->rt_errors.

ENDMETHOD.


METHOD analyze_naming.
  CLEAR rt_errors.
  CLEAR me->rt_errors.

  "------------------------------------------------------------
  "A) Local data
  "   WITH ANALYSIS -> token table phải là STOKEX hoặc STOKESX
  "------------------------------------------------------------
  DATA lt_tokens  TYPE STANDARD TABLE OF stokex.
  DATA lt_stmts   TYPE STANDARD TABLE OF sstmnt.
  DATA lv_text    TYPE string.
  DATA ls_payload TYPE ty_error_payload.

  DATA: ls_tok          TYPE stokex,
        lv_in_data_decl TYPE abap_bool VALUE abap_false,
        lv_tok_u        TYPE string.

  "Chống duplicate (same variable same row) - normalize to UPPER
  TYPES: BEGIN OF ty_seen,
           name_u TYPE string,
           row    TYPE i,
         END OF ty_seen.
  DATA lt_seen TYPE HASHED TABLE OF ty_seen WITH UNIQUE KEY name_u row.

  CLEAR lt_seen.

  "------------------------------------------------------------
  "B) Object-name rules
  "------------------------------------------------------------
  IF is_ctx-obj_name IS NOT INITIAL
     AND is_ctx-obj_name(1) <> gc_obj_prefix-z
     AND is_ctx-obj_name(1) <> gc_obj_prefix-y.

    MESSAGE e008(z_gsp04_message) WITH is_ctx-obj_name INTO lv_text.

    CLEAR ls_payload.
    ls_payload-rule_id  = gc_rule-obj_prefix.
    ls_payload-severity = gc_severity-error.
    ls_payload-obj_type = is_ctx-obj_type.
    ls_payload-obj_name = is_ctx-obj_name.
    ls_payload-include  = is_ctx-include.
    ls_payload-line     = 0.
    ls_payload-message  = lv_text.

    me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
  ENDIF.

  "------------------------------------------------------------
  "C) Source empty -> add_error
  "------------------------------------------------------------
  IF it_source IS INITIAL.
    MESSAGE e006(z_gsp04_message) INTO lv_text.

    CLEAR ls_payload.
    ls_payload-rule_id  = gc_rule-source_empty.
    ls_payload-severity = gc_severity-error.
    ls_payload-obj_type = is_ctx-obj_type.
    ls_payload-obj_name = is_ctx-obj_name.
    ls_payload-include  = is_ctx-include.
    ls_payload-line     = 0.
    ls_payload-message  = lv_text.

    me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  "D) SCAN (WITH ANALYSIS -> STOKEX/STOKESX)
  "------------------------------------------------------------
  SCAN ABAP-SOURCE it_source
    TOKENS     INTO lt_tokens
    STATEMENTS INTO lt_stmts
    WITH ANALYSIS.

  "------------------------------------------------------------
  "D.1) Validate SCAN sy-subrc (0 ok, 4 scan error, 8 runtime/other)
  "------------------------------------------------------------
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 4.
        MESSAGE e013(z_gsp04_message) INTO lv_text.
        IF lv_text IS INITIAL.
          MESSAGE e009(z_gsp04_message) WITH is_ctx-obj_type is_ctx-obj_name INTO lv_text.
        ENDIF.

        CLEAR ls_payload.
        ls_payload-rule_id  = gc_rule-scan_error.  ">>> FIX: was source_empty
        ls_payload-severity = gc_severity-error.
        ls_payload-obj_type = is_ctx-obj_type.
        ls_payload-obj_name = is_ctx-obj_name.
        ls_payload-include  = is_ctx-include.
        ls_payload-line     = 0.
        ls_payload-message  = lv_text.

        me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
        RETURN.

      WHEN 8.
        MESSAGE e012(z_gsp04_message) WITH sy-subrc is_ctx-obj_type is_ctx-obj_name INTO lv_text.

        CLEAR ls_payload.
        ls_payload-rule_id  = gc_rule-scan_runtime.
        ls_payload-severity = gc_severity-error.
        ls_payload-obj_type = is_ctx-obj_type.
        ls_payload-obj_name = is_ctx-obj_name.
        ls_payload-include  = is_ctx-include.
        ls_payload-line     = 0.
        ls_payload-message  = lv_text.

        me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
        RETURN.

      WHEN OTHERS.
        MESSAGE e010(z_gsp04_message) WITH sy-subrc is_ctx-obj_type is_ctx-obj_name INTO lv_text.

        CLEAR ls_payload.
        ls_payload-rule_id  = gc_rule-scan_unknown.
        ls_payload-severity = gc_severity-error.
        ls_payload-obj_type = is_ctx-obj_type.
        ls_payload-obj_name = is_ctx-obj_name.
        ls_payload-include  = is_ctx-include.
        ls_payload-line     = 0.
        ls_payload-message  = lv_text.

        me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
        RETURN.
    ENDCASE.
  ENDIF.

  "------------------------------------------------------------
  "E) Rules theo source
  "   >>> Track scope depth: inside FORM/METHOD/FUNCTION/MODULE => local
  "------------------------------------------------------------
  DATA lv_scope_depth TYPE i VALUE 0.

  LOOP AT lt_stmts ASSIGNING FIELD-SYMBOL(<s>).

    IF <s>-from > <s>-to.
      CONTINUE.
    ENDIF.

    "Read first token of statement
    READ TABLE lt_tokens INDEX <s>-from INTO DATA(ls_first).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    DATA(lv_stmt_first_u) = ls_first-str.
    TRANSLATE lv_stmt_first_u TO UPPER CASE.

    ">>> Update scope depth (simple)
    CASE lv_stmt_first_u.
      WHEN gc_keyword-form OR gc_keyword-method OR gc_keyword-func OR gc_keyword-module.
        lv_scope_depth = lv_scope_depth + 1.
      WHEN gc_keyword-endform OR gc_keyword-endmethod OR gc_keyword-endfunc OR gc_keyword-endmodule.
        IF lv_scope_depth > 0.
          lv_scope_depth = lv_scope_depth - 1.
        ENDIF.
    ENDCASE.

    DATA(lv_is_local_scope) = xsdbool( lv_scope_depth > 0 ).

    "Only handle DATA statements for prefix rule
    IF lv_stmt_first_u <> gc_keyword-data AND lv_stmt_first_u <> gc_keyword-data_col.
      CONTINUE.
    ENDIF.

    "========================================================
    "A) Inline: DATA(lv_x) = ...
    "========================================================
    READ TABLE lt_tokens INDEX ( <s>-from + 1 ) INTO DATA(ls_next).
    IF sy-subrc = 0 AND ls_next-type = gc_token_type-list.

      DATA(lv_inline) = ls_next-str.
      SHIFT lv_inline LEFT  DELETING LEADING gc_keyword-lparen.
      SHIFT lv_inline RIGHT DELETING TRAILING gc_keyword-rparen.

      IF lv_inline IS NOT INITIAL.
        DATA(lv_inline_u) = lv_inline.
        TRANSLATE lv_inline_u TO UPPER CASE.

        READ TABLE lt_seen WITH TABLE KEY name_u = lv_inline_u row = ls_next-row TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          INSERT VALUE ty_seen( name_u = lv_inline_u row = ls_next-row ) INTO TABLE lt_seen.

          ">>> Prefix check by scope
          DATA(lv_ok_inline) = abap_false.
          IF lv_is_local_scope = abap_true.
            lv_ok_inline = xsdbool(
              lv_inline_u CP gc_pat_local-lc OR
              lv_inline_u CP gc_pat_local-lv OR
              lv_inline_u CP gc_pat_local-ls OR
              lv_inline_u CP gc_pat_local-lt OR
              lv_inline_u CP gc_pat_local-lo OR
              lv_inline_u CP gc_pat_local-lr OR
              lv_inline_u CP gc_pat_local-lm OR
              lv_inline_u CP gc_pat_local-lty
            ).
          ELSE.
            lv_ok_inline = xsdbool(
              lv_inline_u CP gc_pat_global-gc OR
              lv_inline_u CP gc_pat_global-gv OR
              lv_inline_u CP gc_pat_global-gs OR
              lv_inline_u CP gc_pat_global-gt OR
              lv_inline_u CP gc_pat_global-gr OR
              lv_inline_u CP gc_pat_global-gm OR
              lv_inline_u CP gc_pat_global-st OR
              lv_inline_u CP gc_pat_global-gty
            ).
          ENDIF.

          IF lv_ok_inline = abap_false.
            lv_text = |Variable { lv_inline } does not follow { COND string( WHEN lv_is_local_scope = abap_true THEN 'LOCAL (LV_/LS_/LT_/...)' ELSE 'GLOBAL (GV_/GS_/GT_/...)' ) } prefix rule.|.

            CLEAR ls_payload.
            ls_payload-rule_id  = gc_rule-prefix_rule.
            ls_payload-severity = gc_severity-error.
            ls_payload-obj_type = is_ctx-obj_type.
            ls_payload-obj_name = is_ctx-obj_name.
            ls_payload-include  = is_ctx-include.
            ls_payload-line     = ls_next-row.
            ls_payload-message  = lv_text.

            me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
          ENDIF.
        ENDIF.
      ENDIF.

      CONTINUE.
    ENDIF.

    "========================================================
    "B) DATA foo TYPE ... / DATA: foo TYPE ..., bar TYPE ...
    "   >>> Trigger only at TYPE/LIKE (NOT VALUE) to avoid catching type-name
    "========================================================
    DATA ls_prev_id TYPE stokex.
    CLEAR ls_prev_id.

    DO.
      DATA(lv_i) = sy-index + <s>-from.
      IF lv_i > <s>-to.
        EXIT.
      ENDIF.

      READ TABLE lt_tokens INDEX lv_i INTO DATA(ls_t).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lv_u) = ls_t-str.
      TRANSLATE lv_u TO UPPER CASE.

      "Remember last identifier that is not a keyword
      IF ls_t-type = gc_token_type-identifier.

        IF lv_u = gc_keyword-data
           OR lv_u = gc_keyword-data_col
           OR lv_u = gc_keyword-type
           OR lv_u = gc_keyword-like
           OR lv_u = gc_keyword-value
           OR lv_u = gc_keyword-ref
           OR lv_u = gc_keyword-to
           OR lv_u = gc_keyword-table_kw
           OR lv_u = gc_keyword-of_kw
           OR lv_u = gc_keyword-standard
           OR lv_u = gc_keyword-sorted
           OR lv_u = gc_keyword-hashed
           OR lv_u = gc_keyword-with_kw
           OR lv_u = gc_keyword-key_kw
           OR lv_u = gc_keyword-default
           OR lv_u = gc_keyword-empty
           OR lv_u = gc_keyword-initial
           OR lv_u = gc_keyword-line_kw
           OR lv_u = gc_keyword-length_kw.
          "skip
        ELSE.
          ls_prev_id = ls_t.
        ENDIF.

      ENDIF.

      ">>> Trigger at TYPE/LIKE only (removed VALUE)
      IF lv_u = gc_keyword-type OR lv_u = gc_keyword-like.

        IF ls_prev_id-str IS INITIAL.
          CONTINUE.
        ENDIF.

        DATA(lv_name)   = ls_prev_id-str.
        DATA(lv_name_u) = lv_name.
        TRANSLATE lv_name_u TO UPPER CASE.
        DATA(lv_row)    = ls_prev_id-row.

        READ TABLE lt_seen WITH TABLE KEY name_u = lv_name_u row = lv_row TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.
        INSERT VALUE ty_seen( name_u = lv_name_u row = lv_row ) INTO TABLE lt_seen.

        ">>> Prefix check by scope
        DATA(lv_ok) = abap_false.
        IF lv_is_local_scope = abap_true.
          lv_ok = xsdbool(
            lv_name_u CP gc_pat_local-lc OR
            lv_name_u CP gc_pat_local-lv OR
            lv_name_u CP gc_pat_local-ls OR
            lv_name_u CP gc_pat_local-lt OR
            lv_name_u CP gc_pat_local-lo OR
            lv_name_u CP gc_pat_local-lr OR
            lv_name_u CP gc_pat_local-lm OR
            lv_name_u CP gc_pat_local-lty
          ).
        ELSE.
          lv_ok = xsdbool(
            lv_name_u CP gc_pat_global-gc OR
            lv_name_u CP gc_pat_global-gv OR
            lv_name_u CP gc_pat_global-gs OR
            lv_name_u CP gc_pat_global-gt OR
            lv_name_u CP gc_pat_global-gr OR
            lv_name_u CP gc_pat_global-gm OR
            lv_name_u CP gc_pat_global-st OR
            lv_name_u CP gc_pat_global-gty
          ).
        ENDIF.

        IF lv_ok = abap_false.
          lv_text = |Variable { lv_name } does not follow { COND string( WHEN lv_is_local_scope = abap_true THEN 'LOCAL (LV_/LS_/LT_/...)' ELSE 'GLOBAL (GV_/GS_/GT_/...)' ) } prefix rule.|.

          CLEAR ls_payload.
          ls_payload-rule_id  = gc_rule-prefix_rule.
          ls_payload-severity = gc_severity-error.
          ls_payload-obj_type = is_ctx-obj_type.
          ls_payload-obj_name = is_ctx-obj_name.
          ls_payload-include  = is_ctx-include.
          ls_payload-line     = lv_row.
          ls_payload-message  = lv_text.

          me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
        ENDIF.

      ENDIF.

    ENDDO.

  ENDLOOP.

  "------------------------------------------------------------
  "OBSOLETE_PREFIX: WA_* (không phân biệt hoa thường)
  "------------------------------------------------------------
  LOOP AT lt_tokens INTO ls_tok.

    lv_tok_u = ls_tok-str.
    TRANSLATE lv_tok_u TO UPPER CASE.

    IF lv_tok_u = gc_keyword-dot.
      lv_in_data_decl = abap_false.
      CONTINUE.
    ENDIF.

    IF lv_tok_u = gc_keyword-data OR lv_tok_u = gc_keyword-data_col.
      lv_in_data_decl = abap_true.
      CONTINUE.
    ENDIF.

    IF lv_in_data_decl = abap_false.
      CONTINUE.
    ENDIF.

    IF lv_tok_u = gc_keyword-type
       OR lv_tok_u = gc_keyword-like
       OR lv_tok_u = gc_keyword-value
       OR lv_tok_u = gc_keyword-ref
       OR lv_tok_u = gc_keyword-to
       OR lv_tok_u = gc_keyword-comma
       OR lv_tok_u = gc_keyword-colon
       OR lv_tok_u = gc_keyword-lparen
       OR lv_tok_u = gc_keyword-rparen
       OR lv_tok_u = gc_keyword-equal.
      CONTINUE.
    ENDIF.

    IF lv_tok_u CP gc_pat_obsolete-wa.
      MESSAGE w011(z_gsp04_message) WITH ls_tok-str INTO lv_text.

      CLEAR ls_payload.
      ls_payload-rule_id  = gc_rule-wa_prefix_obsolete.
      ls_payload-severity = gc_severity-warning.
      ls_payload-obj_type = is_ctx-obj_type.
      ls_payload-obj_name = is_ctx-obj_name.
      ls_payload-include  = is_ctx-include.
      ls_payload-line     = ls_tok-row.
      ls_payload-message  = lv_text.

      me->add_error( EXPORTING is_payload = ls_payload CHANGING ct_errors = rt_errors ).
    ENDIF.

  ENDLOOP.

ENDMETHOD.


METHOD analyze_obsolete.

  "--------------------------------------------------
  " Clear output and internal error buffer
  "--------------------------------------------------
  CLEAR rt_errors.
  CLEAR me->rt_errors.

  "--------------------------------------------------
  " Local data for source scanning and error handling
  "--------------------------------------------------
  DATA: lt_tokens     TYPE STANDARD TABLE OF stokex,
        lt_statements TYPE STANDARD TABLE OF sstmnt,
        ls_token      TYPE stokex,
        ls_error      TYPE zst_error.

  "--------------------------------------------------
  " Table of obsolete single-token keywords
  " These are checked against SCAN token result
  "--------------------------------------------------
  DATA(lt_single_keywords) = VALUE string_table(
    ( gc_kw_obsolete-move_kw )
    ( gc_kw_obsolete-occurs_kw )
    ( gc_kw_obsolete-ranges_kw )
    ( gc_kw_obsolete-compute_kw )
    ( gc_kw_obsolete-tables_kw )
    ( gc_kw_obsolete-extract_kw )
    ( gc_kw_obsolete-field_groups )
    ( gc_kw_obsolete-data )
  ).

  "--------------------------------------------------
  " Parse ABAP source into tokens/statements
  "--------------------------------------------------
  SCAN ABAP-SOURCE it_source
       TOKENS     INTO lt_tokens
       STATEMENTS INTO lt_statements
       WITH ANALYSIS.

  "--------------------------------------------------
  " Check obsolete single-token keywords
  "--------------------------------------------------
  LOOP AT lt_tokens INTO ls_token.

    DATA(lv_token_uc) = to_upper( ls_token-str ).

    LOOP AT lt_single_keywords INTO DATA(lv_key).
      IF lv_token_uc = lv_key.

        CLEAR ls_error.
        ls_error-line = ls_token-row.
        ls_error-sev  = gc_severity-error.
        ls_error-msg  = |Obsolete keyword found: { lv_key }|.

        "----------------------------------------------
        " Assign stable error code by keyword
        "----------------------------------------------
        CASE lv_key.
          WHEN gc_kw_obsolete-move_kw.
            ls_error-code = gc_rule_obsolete-move_rule.

          WHEN gc_kw_obsolete-occurs_kw.
            ls_error-code = gc_rule_obsolete-occurs_rule.

          WHEN gc_kw_obsolete-ranges_kw.
            ls_error-code = gc_rule_obsolete-ranges_rule.

          WHEN gc_kw_obsolete-compute_kw.
            ls_error-code = gc_rule_obsolete-compute_rule.

          WHEN gc_kw_obsolete-tables_kw.
            ls_error-code = gc_rule_obsolete-tables_rule.

          WHEN gc_kw_obsolete-extract_kw.
            ls_error-code = gc_rule_obsolete-extract_rule.

          WHEN gc_kw_obsolete-field_groups.
            ls_error-code = gc_rule_obsolete-field_groups_rule.

          WHEN OTHERS.
            ls_error-code = lv_token_uc.
        ENDCASE.

        APPEND ls_error TO me->rt_errors.
      ENDIF.
    ENDLOOP.

  ENDLOOP.

  "--------------------------------------------------
  " Check obsolete multi-word phrases in source lines
  " These are easier to detect by line text than token
  "--------------------------------------------------
  LOOP AT it_source INTO DATA(lv_source_line).

    DATA(lv_source_uc) = to_upper( lv_source_line ).

    "----------------------------------------------
    " WITH HEADER LINE
    "----------------------------------------------
    IF lv_source_uc CP |*{ gc_phrase_obsolete-with_header_line }*|.
      CLEAR ls_error.
      ls_error-line = sy-tabix.
      ls_error-sev  = gc_severity-error.
      ls_error-msg  = |Obsolete syntax found: { gc_phrase_obsolete-with_header_line }|.
      ls_error-code = gc_rule_obsolete-header_line_rule.
      APPEND ls_error TO me->rt_errors.
    ENDIF.

    "----------------------------------------------
    " ON CHANGE OF
    "----------------------------------------------
    IF lv_source_uc CP |*{ gc_phrase_obsolete-on_change_of }*|.
      CLEAR ls_error.
      ls_error-line = sy-tabix.
      ls_error-sev  = gc_severity-error.
      ls_error-msg  = |Obsolete syntax found: { gc_phrase_obsolete-on_change_of }|.
      ls_error-code = gc_rule_obsolete-on_change_rule.
      APPEND ls_error TO me->rt_errors.
    ENDIF.

    "----------------------------------------------
    " CALL FUNCTION
    " Note: not always obsolete in all systems,
    " but include it here if your project rule says so
    "----------------------------------------------
    IF lv_source_uc CP |*{ gc_phrase_obsolete-call_function }*|.
      CLEAR ls_error.
      ls_error-line = sy-tabix.
      ls_error-sev  = gc_severity-error.
      ls_error-msg  = |Obsolete syntax found: { gc_phrase_obsolete-call_function }|.
      ls_error-code = gc_rule_obsolete-call_func_rule.
      APPEND ls_error TO me->rt_errors.
    ENDIF.

    "----------------------------------------------
    " LIKE LINE OF
    "----------------------------------------------
    IF lv_source_uc CP |*{ gc_phrase_obsolete-like_line_of }*|.
      CLEAR ls_error.
      ls_error-line = sy-tabix.
      ls_error-sev  = gc_severity-error.
      ls_error-msg  = |Obsolete syntax found: { gc_phrase_obsolete-like_line_of }|.
      ls_error-code = gc_rule_obsolete-like_line_rule.
      APPEND ls_error TO me->rt_errors.
    ENDIF.

  ENDLOOP.

  "--------------------------------------------------
  " Return collected errors
  "--------------------------------------------------
  et_errors = me->rt_errors.

ENDMETHOD.
ENDCLASS.
