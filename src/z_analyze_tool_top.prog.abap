*&---------------------------------------------------------------------*
*& Include          Z_ANALYZE_TOOL_TOP
*&---------------------------------------------------------------------*
TABLES sscrfields.
INCLUDE <icon>.

* ======== SELECTION SCREEN ========
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_tr    TYPE trkorr         MATCHCODE OBJECT ZSH_TR_GSP04 MODIF ID m2,
              p_fugr  TYPE rs38l-area,
              p_prog  TYPE rs38l-progname MATCHCODE OBJECT ZSH_PROGRAM_GSP04,
              p_func  TYPE rs38l-name     MATCHCODE OBJECT ZSH_FUNC_GSP04,
              p_class TYPE seoclsname     MATCHCODE OBJECT ZSH_CLASS_GSP04.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: rb_check RADIOBUTTON GROUP g1 DEFAULT 'X' USER-COMMAND click,
              rb_used  RADIOBUTTON GROUP g1,
              rb_exp   RADIOBUTTON GROUP g1,
              p_err    AS CHECKBOX DEFAULT abap_false MODIF ID m1.
SELECTION-SCREEN END OF BLOCK b2.


* ======== GLOBAL DATA ========
DATA: lo_controller        TYPE REF TO zcl_program_controller,
      lt_errors            TYPE ztt_error,
      go_alv               TYPE REF TO zcl_program_alv,
      lt_founds            TYPE zcl_program_whereused=>ty_founds.
DATA: gc_sev_error         TYPE c VALUE 'E',
      gc_sev_warning       TYPE c VALUE 'W'.
