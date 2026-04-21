*---------------------------------------------------------------------*
* Include ZTEST_ANALYZE_HARDCODE_ALL
* Purpose: syntax-valid source patterns for analyze_hardcode
* This FORM is not intended to be executed.
*---------------------------------------------------------------------*

FORM hardcode_patterns_dummy.

  DATA: lv_file   TYPE string,
        lv_num    TYPE i,
        lv_text   TYPE string,
        lv_flag   TYPE abap_bool,
        lv_kunnr  TYPE string,
        lv_opt    TYPE string,
        lv_sep    TYPE c LENGTH 1,
        lv_belnr  TYPE string.

  FIELD-SYMBOLS <lv_any> TYPE any.

  "============================================================
  " 1. Skip whole statement
  "============================================================

  CONSTANTS gc_text TYPE string VALUE 'Approved'.
  CONSTANTS gc_type TYPE string VALUE 'E'.
  STATICS   gv_text TYPE string VALUE 'Error text'.

  "============================================================
  " 2. Special rule for MESSAGE
  "============================================================

  MESSAGE 'Invalid input' TYPE gc_type.
  MESSAGE 'Field'  TYPE 'E'.
  MESSAGE `Upload failed` TYPE 'E'.
  MESSAGE |Upload failed for { lv_file }| TYPE 'E'.
  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno.

  "============================================================
  " 3. Detect only string literals / backticks / templates
  "============================================================

  lv_num  = 100.
  lv_text = 'Customer not found'.
  lv_text = `Customer not found`.
  lv_text = |Customer { lv_kunnr } not found|.

  "============================================================
  " 4. Skip empty literals
  "============================================================

  lv_text = ''.
  lv_text = ``.
  lv_text = ||.

  "============================================================
  " 5. Skip comments
  "============================================================

* lv_text = 'Do not detect me'.
  lv_flag = abap_true. " 'Do not detect me'
  lv_text = 'Real text'. " note

  "============================================================
  " 6. CALL FUNCTION handling
  "============================================================

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename = lv_text.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename = lv_text
      filetype = 'ASC'.

  lv_text = 'CALL FUNCTION error'.

  "============================================================
  " 7. String template handling
  "============================================================

  lv_text = |{ lv_belnr }|.
  lv_text = |Document { lv_belnr } created|.
  lv_text = |   |.

  "============================================================
  " 8. Technical / space / separator
  "============================================================

  lv_text = ' '.

ENDFORM.
