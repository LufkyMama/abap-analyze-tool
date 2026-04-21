*&---------------------------------------------------------------------*
*& Include          Z_ANALYZE_TOOL_TOP
*&---------------------------------------------------------------------*
TABLES sscrfields.
INCLUDE <icon>.

* ======== SELECTION SCREEN ========
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_tr    TYPE trkorr     MATCHCODE OBJECT ZSH_TR_GSP04,
              p_fugr  TYPE rs38l-area,
*              p_prog  TYPE progname   MATCHCODE OBJECT progname,
              p_prog  TYPE RS38L-progname,
              p_func  TYPE rs38l-name MATCHCODE OBJECT funcname,
              p_class TYPE seoclsname MATCHCODE OBJECT seo_classes.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: rb_check RADIOBUTTON GROUP g1 DEFAULT 'X',
              rb_used  RADIOBUTTON GROUP g1,
              rb_exp   RADIOBUTTON GROUP g1,
              p_err    AS CHECKBOX DEFAULT abap_false.
SELECTION-SCREEN END OF BLOCK b2.


* ======== GLOBAL DATA ========
DATA: lo_controller        TYPE REF TO zcl_program_controller,
      lt_errors            TYPE ztt_error,
      go_alv               TYPE REF TO zcl_program_alv,
      lt_founds            TYPE zcl_program_whereused=>ty_founds.
