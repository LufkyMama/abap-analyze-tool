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

INCLUDE ZTEST_ANALYZE_HARDCODE_ALL.

INCLUDE ZTEST_ANALYZE_OBSOLETE_ALL.
