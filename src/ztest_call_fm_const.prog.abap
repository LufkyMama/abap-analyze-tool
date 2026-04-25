REPORT ztest_call_fm_const.

CONSTANTS gc_fm_test TYPE rs38l_fnam VALUE 'POPUP_TO_INFORM'.

CALL FUNCTION gc_fm_test
  EXPORTING
    titel = 'Test'
    txt1  = 'Using constant'
    txt2  = 'instead of literal'
  EXCEPTIONS
    OTHERS = 1.

IF sy-subrc = 0.
  WRITE: / 'Function module called successfully.'.
ELSE.
  WRITE: / 'Call failed. SY-SUBRC =', sy-subrc.
ENDIF.

" Khai báo biến ở Main Program nhưng sẽ được sử dụng bên trong Include
" Dùng để test Case 4.1.1.3 (Cross-source usage)
DATA: lv_cross_used TYPE i.

" Gọi Include chứa các Test Case Clean Code
INCLUDE ztest_analyze_cleancode_all.

START-OF-SELECTION.
  " Gọi FORM hợp lệ để chứng minh tool không bắt lỗi sai (False positive)
  PERFORM used_form.

  " Gọi Method để tránh lỗi unused
  lcl_clean_code_test=>do_something( ).

  " Gọi FORM chứa statics
  PERFORM test_statics_vars.

INCLUDE ZTEST_ANALYZE_HARDCODE_ALL.

INCLUDE ZTEST_ANALYZE_OBSOLETE_ALL.

INCLUDE ZTEST_ANALYZE_CLEANCODE_ALL.

INCLUDE ZTEST_ANALYZE_PERFORMANCE_ALL.
