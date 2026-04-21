REPORT z_test_perf_bad.
*
*TABLES: mara.
*
*DATA: lt_mara  TYPE STANDARD TABLE OF mara,
*      lt_marc  TYPE STANDARD TABLE OF marc,
*      lt_vbak  TYPE STANDARD TABLE OF vbak,
*      lt_vbap  TYPE STANDARD TABLE OF vbap,
*      ls_mara  TYPE mara,
*      ls_vbak  TYPE vbak,
*      ls_vbap  TYPE vbap,
*      lv_matnr TYPE matnr,
*      lv_sum   TYPE i.
*
*RANGES: lr_matnr FOR mara-matnr.
*
*DATA lt_old OCCURS 0 WITH HEADER LINE.
*DATA lt_head TYPE STANDARD TABLE OF mara WITH HEADER LINE.
*DATA ls_like LIKE LINE OF lt_mara.
*
*"--- analyze_chained_data: SHOULD trigger
*DATA: gv_chain_a TYPE i,
*      gv_chain_b TYPE i.
*
*"--- analyze_chained_data: SHOULD NOT trigger
*DATA gv_single_ok TYPE i.
*
*"--- analyze_chained_data: SHOULD NOT trigger if BEGIN OF is excluded correctly
*DATA: BEGIN OF gs_ok_struct,
*        matnr TYPE matnr,
*        mtart TYPE mtart,
*      END OF gs_ok_struct.
*
*START-OF-SELECTION.
* data: test type string value 'abcd'.
*
*  "========================
*  " OBSOLETE
*  "========================
*  MOVE 'MAT001' TO lv_matnr.
*  COMPUTE lv_sum = 1 + 2.
*
*  FIELD-GROUPS: fg1.
*
*  CALL FUNCTION 'GUI_UPLOAD'
*    EXPORTING
*      filename = 'C:\TEMP\A.TXT'
*    EXCEPTIONS
*      OTHERS   = 1.
*
*  "========================
*  " SQL
*  "========================
*  DATA: lt_matnr TYPE TABLE OF mara-matnr.
*
*SELECT matnr
*  FROM mara
*  INTO TABLE lt_matnr
*  UP TO 10 ROWS.
*
*SELECT *
*  FROM mara
*  INTO TABLE lt_mara
*  FOR ALL ENTRIES IN lt_matnr
*  WHERE matnr = lt_matnr-table_line.
*  SELECT * FROM mara
*    INTO TABLE lt_mara
*    UP TO 20 ROWS.
*
*  READ TABLE lt_mara INTO ls_mara WITH KEY matnr = 'MAT001'.
*
*  SELECT * FROM vbak
*    INTO TABLE lt_vbak
*    UP TO 10 ROWS.
*
*  SELECT * FROM vbap
*    INTO TABLE lt_vbap
*    UP TO 20 ROWS.
*
*  LOOP AT lt_vbak INTO ls_vbak.
*
*    ON CHANGE OF ls_vbak-auart.
*      WRITE: / ls_vbak-auart.
*    ENDON.
*
*    LOOP AT lt_vbap INTO ls_vbap WHERE vbeln = ls_vbak-vbeln.
*      WRITE: / ls_vbap-vbeln.
*    ENDLOOP.
*
*  ENDLOOP.
*
*  LOOP AT lt_mara INTO ls_mara.
*    SELECT * FROM marc
*      INTO TABLE lt_marc
*      WHERE matnr = ls_mara-matnr.
*  ENDLOOP.
*
*  "========================================================
*  " TEST FOR ANALYZE_UNUSED_TEXT_SYMBOLS
*  "========================================================
*  "Bạn phải tạo text symbols trong Text Elements:
*  "001 = Used text 001
*  "002 = Used text 002
*  "003 = Unused text 003
*  "004 = Comment only
*  "005 = String only
*  "006 = Unused text 006
*
*  WRITE: / TEXT-001.
*  WRITE: / TEXT-002.
*
*  " text-004   " chỉ nằm trong comment -> SHOULD remain unused
*  DATA(lv_text_probe) = `text-005`. " chỉ nằm trong string
*
*  IF lv_text_probe = `X`.
*    WRITE: / lv_text_probe.
*  ENDIF.
*
*  "========================================================
*  " TEST FOR ANALYZE_CHAINED_DATA
*  "========================================================
*  DATA: lv_local_chain_a TYPE i,
*        lv_local_chain_b TYPE i.
*
*  DATA lv_local_ok TYPE i.
*
*  "========================================================
*  " TEST FOR ANALYZE_SUBROUTINE_ISSUES
*  "========================================================
*  PERFORM normalize USING lv_matnr CHANGING lv_matnr.
*  PERFORM helper_ok.
*
*  "========================================================
*  " FORM
*  "========================================================
*  FORM normalize USING    iv_matnr TYPE matnr
*               CHANGING cv_matnr TYPE matnr.
*
*  "--- analyze_chained_data: SHOULD trigger inside FORM too
*  DATA: lv_form_chain_a TYPE i,
*        lv_form_chain_b TYPE i.
*
*  cv_matnr = iv_matnr.
*  ENDFORM.
*
*  FORM helper_ok.
*    DATA lv_dummy TYPE i.
*    lv_dummy = 1.
*  ENDFORM.
*
*  FORM helper_never_called.
*    DATA lv_never_called TYPE i.
*    lv_never_called = 2.
*  ENDFORM.
