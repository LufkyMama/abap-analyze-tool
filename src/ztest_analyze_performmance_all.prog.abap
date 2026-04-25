*&---------------------------------------------------------------------*
*& Include          ZTEST_ANALYZE_PERFORMMANCE_ALL
*&---------------------------------------------------------------------*

DATA: lt_mara TYPE STANDARD TABLE OF mara,
      ls_mara TYPE mara,
      lt_marc TYPE STANDARD TABLE OF marc,
      ls_marc TYPE marc.

START-OF-SELECTION.

  " ======================================================================
  " [5.1.1] Use of SELECT *
  " ======================================================================

  " 5.1.1.1 -> ZCLEAN sẽ báo lỗi (Dùng SELECT *)
  SELECT * FROM mara INTO TABLE lt_mara UP TO 10 ROWS.

  " 5.1.1.2 -> ZCLEAN KHÔNG báo lỗi (Chỉ định rõ field cụ thể)
  SELECT matnr mtart FROM mara INTO CORRESPONDING FIELDS OF TABLE lt_mara UP TO 10 ROWS.


  " ======================================================================
  " [5.1.2] Queries inside loops
  " ======================================================================

  " 5.1.2.1 -> ZCLEAN sẽ báo lỗi (SELECT nằm trong LOOP)
  LOOP AT lt_mara INTO ls_mara.
    SELECT SINGLE * FROM marc INTO ls_marc WHERE matnr = ls_mara-matnr.
  ENDLOOP.

  " 5.1.2.2 -> ZCLEAN KHÔNG báo lỗi (SELECT nằm ngoài LOOP)
  SELECT matnr werks FROM marc INTO CORRESPONDING FIELDS OF TABLE lt_marc UP TO 10 ROWS.
  LOOP AT lt_mara INTO ls_mara.
    " Xử lý logic không đụng Database
  ENDLOOP.


  " ======================================================================
  " [5.1.3] FOR ALL ENTRIES usage
  " ======================================================================

  " 5.1.3.1 -> ZCLEAN sẽ báo lỗi (Thiếu check IS NOT INITIAL ở ngoài)
  SELECT matnr werks FROM marc INTO CORRESPONDING FIELDS OF TABLE lt_marc
    FOR ALL ENTRIES IN lt_mara
    WHERE matnr = lt_mara-matnr.

  " 5.1.3.2 -> ZCLEAN KHÔNG báo lỗi (Đã bọc cẩn thận bằng lệnh IF)
  IF lt_mara IS NOT INITIAL.
    SELECT matnr werks FROM marc INTO CORRESPONDING FIELDS OF TABLE lt_marc
      FOR ALL ENTRIES IN lt_mara
      WHERE matnr = lt_mara-matnr.
  ENDIF.


  " ======================================================================
  " [5.2.1] READ TABLE efficiency
  " ======================================================================

  " 5.2.1.1 -> ZCLEAN sẽ báo lỗi (Dùng WITH KEY nhưng thiếu BINARY SEARCH)
  READ TABLE lt_mara INTO ls_mara WITH KEY matnr = '1000'.

  " 5.2.1.2 -> ZCLEAN KHÔNG báo lỗi (Đã tối ưu với BINARY SEARCH)
  READ TABLE lt_mara INTO ls_mara WITH KEY matnr = '1000' BINARY SEARCH.

  " 5.2.1.3 -> ZCLEAN KHÔNG báo lỗi (Sử dụng TABLE KEY chuẩn)
  READ TABLE lt_mara INTO ls_mara WITH TABLE KEY matnr = '1000'.


  " ======================================================================
  " [5.2.2] Nested Loops
  " ======================================================================

  " 5.2.2.1 -> ZCLEAN sẽ báo lỗi tại dòng LOOP thứ 2 (Vòng lặp lồng nhau)
  LOOP AT lt_mara INTO ls_mara.
    LOOP AT lt_marc INTO ls_marc WHERE matnr = ls_mara-matnr.
      " Logic xử lý nặng...
    ENDLOOP.
  ENDLOOP.
