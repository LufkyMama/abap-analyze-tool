"------------------------------------------------------------
" Include: ZTEST_ANALYZE_OBSOLETE_ALL
" Purpose: Source cases for testing ANALYZE_OBSOLETE
" Note   : Not intended to be executed
"------------------------------------------------------------

CONSTANTS:
  gc_txt_move        TYPE string VALUE 'MOVE',
  gc_txt_occurs      TYPE string VALUE 'OCCURS',
  gc_txt_header      TYPE string VALUE `WITH HEADER LINE`,
  gc_txt_like        TYPE string VALUE 'LIKE LINE OF',
  gc_txt_translate   TYPE string VALUE 'TRANSLATE',
  gc_txt_call_method TYPE string VALUE 'CALL METHOD',
  gc_txt_call_dialog TYPE string VALUE 'CALL DIALOG'.

DATA:
  lv_a    TYPE i VALUE 1,
  lv_b    TYPE i VALUE 2,
  lv_c    TYPE i,
  lv_text TYPE string VALUE 'abc',
  lv_lines TYPE i.

DATA lt_std TYPE STANDARD TABLE OF string WITH EMPTY KEY.

FIELD-SYMBOLS <fs_ok> TYPE any.

FORM test_analyze_obsolete_all.

  "----------------------------------------------------------
  " Cases that should NOT be detected
  "----------------------------------------------------------

* MOVE lv_a TO lv_b.

* OCCURS

* WITH HEADER LINE

* LIKE LINE OF

* CALL DIALOG

* CATCH SYSTEM-EXCEPTIONS

  lv_c = lv_a. " MOVE in inline comment
  lv_c = lv_b. " OCCURS in inline comment
  lv_text = 'CALL METHOD'.
  lv_text = `WITH HEADER LINE`.
  lv_text = 'LIKE LINE OF'.

  CALL TRANSACTION 'VA02' WITH AUTHORITY-CHECK.

  IF lv_a <= lv_b.
    lv_c = 1.
  ENDIF.

  lv_c = lv_a + lv_b.

  FIELD-SYMBOLS <fs_typed> TYPE any.

  "----------------------------------------------------------
  " Cases that SHOULD be detected
  "----------------------------------------------------------

  MOVE lv_a TO lv_b.

  COMPUTE lv_c = lv_a + lv_b.

  ADD 1 TO lv_a.
  SUBTRACT 1 FROM lv_a.
  MULTIPLY lv_a BY 2.
  DIVIDE lv_a BY 2.

  TRANSLATE lv_text TO UPPER CASE.
  TRANSLATE lv_text TO LOWER CASE.

  REFRESH lt_std.

  LEAVE.

  DATA: BEGIN OF gt_occurs OCCURS 0,
          col1 TYPE i,
          col2 TYPE c LENGTH 10,
        END OF gt_occurs.

  RANGES gr_bukrs FOR lv_a.

  FIELD-GROUPS fg_demo.

  DATA gt_header TYPE TABLE OF string WITH HEADER LINE.

  DATA gs_line LIKE LINE OF gt_header.

  ON CHANGE OF lv_a.
    lv_b = lv_a.
  ENDON.

  CALL TRANSACTION 'VA01'.

  CALL TRANSACTION 'VA03'
    USING lt_std.

  CALL TRANSACTION 'ME21N' WITHOUT AUTHORITY-CHECK.

  CALL DIALOG 'SCREEN_0100'.

  CATCH SYSTEM-EXCEPTIONS conversion_errors = 1.
    lv_c = lv_a / lv_b.
  ENDCATCH.

  DESCRIBE TABLE lt_std LINES lv_lines.

  CALL METHOD cl_demo_output=>display
    EXPORTING
      data = lv_text.

  FIELD-SYMBOLS <fs1>.


  IF lv_a >< lv_b.
    lv_c = 2.
  ENDIF.

  IF lv_a =< lv_b.
    lv_c = 3.
  ENDIF.

  IF lv_a => lv_b.
    lv_c = 4.
  ENDIF.

  "----------------------------------------------------------
  " Additional multiline cases
  "----------------------------------------------------------

  DATA:
    gt_header2 TYPE TABLE OF string
      WITH HEADER LINE,
    gs_line2   LIKE LINE OF gt_header2.

  CALL METHOD cl_demo_output=>display
    EXPORTING
      data = 'obsolete old call method form'.

  TRANSLATE lv_text
    TO UPPER CASE.

  DESCRIBE TABLE lt_std
    LINES lv_b.

  FIELD-SYMBOLS:
    <fs4>.


  "----------------------------------------------------------
  " Text-only occurrences that should NOT be detected
  "----------------------------------------------------------

  CONSTANTS:
    gc_msg1 TYPE string VALUE 'Please do not use MOVE',
    gc_msg2 TYPE string VALUE 'Pattern: OCCURS 0',
    gc_msg3 TYPE string VALUE `Legacy phrase WITH HEADER LINE found in document`,
    gc_msg4 TYPE string VALUE 'Use LIKE LINE OF only as sample text'.

  DATA lv_msg TYPE string.

  lv_msg = 'CALL DIALOG is obsolete text only'.
  lv_msg = `CATCH SYSTEM-EXCEPTIONS shown as documentation only`.
  lv_msg = 'DESCRIBE TABLE ... LINES'.
  lv_msg = 'TRANSLATE ... TO UPPER CASE'.

* CALL TRANSACTION 'VA01'.
* CALL METHOD cl_demo_output=>display.
* DESCRIBE TABLE lt_std LINES lv_c.
* FIELD-SYMBOLS <fs_bad>.

ENDFORM.
