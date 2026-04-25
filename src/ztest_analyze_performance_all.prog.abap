*&---------------------------------------------------------------------*
*& Include          ZTEST_ANALYZE_PERFORMANCE_ALL
*&---------------------------------------------------------------------*
REPORT ZTEST_ANALYZE_PERFORMANCE_ALL.

DATA: lt_mara TYPE STANDARD TABLE OF mara,
      ls_mara TYPE mara,
      lt_marc TYPE STANDARD TABLE OF marc,
      ls_marc TYPE marc.

START-OF-SELECTION.


  SELECT * FROM mara INTO TABLE lt_mara UP TO 10 ROWS.


  SELECT matnr mtart FROM mara INTO CORRESPONDING FIELDS OF TABLE lt_mara UP TO 10 ROWS.



  LOOP AT lt_mara INTO ls_mara.
    SELECT SINGLE * FROM marc INTO ls_marc WHERE matnr = ls_mara-matnr.
  ENDLOOP.


  SELECT matnr werks FROM marc INTO CORRESPONDING FIELDS OF TABLE lt_marc UP TO 10 ROWS.
  LOOP AT lt_mara INTO ls_mara.

  ENDLOOP.


  SELECT matnr werks FROM marc INTO CORRESPONDING FIELDS OF TABLE lt_marc
    FOR ALL ENTRIES IN lt_mara
    WHERE matnr = lt_mara-matnr.


  IF lt_mara IS NOT INITIAL.
    SELECT matnr werks FROM marc INTO CORRESPONDING FIELDS OF TABLE lt_marc
      FOR ALL ENTRIES IN lt_mara
      WHERE matnr = lt_mara-matnr.
  ENDIF.



  READ TABLE lt_mara INTO ls_mara WITH KEY matnr = '1000'.


  READ TABLE lt_mara INTO ls_mara WITH KEY matnr = '1000' BINARY SEARCH.


  READ TABLE lt_mara INTO ls_mara WITH TABLE KEY matnr = '1000'.



  LOOP AT lt_mara INTO ls_mara.
    LOOP AT lt_marc INTO ls_marc WHERE matnr = ls_mara-matnr.

    ENDLOOP.
  ENDLOOP.
