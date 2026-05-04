*&---------------------------------------------------------------------*
*& Include          Z_ANALYZE_TOOL_TOP
*&---------------------------------------------------------------------*
TABLES sscrfields.
INCLUDE <icon>.

* ======== SELECTION SCREEN ========
SELECTION-SCREEN BEGIN OF BLOCK bl_b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_tr    TYPE trkorr         MATCHCODE OBJECT zsh_tr_gsp04 MODIF ID m2,
              p_fugr  TYPE rs38l-area,
              p_prog  TYPE rs38l-progname MATCHCODE OBJECT zsh_program_gsp04,
              p_func  TYPE rs38l-name     MATCHCODE OBJECT zsh_func_gsp04,
              p_class TYPE seoclsname     MATCHCODE OBJECT zsh_class_gsp04.
SELECTION-SCREEN END OF BLOCK bl_b1.

SELECTION-SCREEN BEGIN OF BLOCK bl_b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: rb_check RADIOBUTTON GROUP rg_1 DEFAULT 'X' USER-COMMAND click,
              rb_used  RADIOBUTTON GROUP rg_1,
              rb_exp   RADIOBUTTON GROUP rg_1,
              cb_err    AS CHECKBOX DEFAULT abap_false MODIF ID m1.
SELECTION-SCREEN END OF BLOCK bl_b2.


* ======== GLOBAL DATA ========
DATA: go_controller TYPE REF TO zcl_program_controller,
      gt_errors     TYPE ztt_error,
      go_alv        TYPE REF TO zcl_program_alv,
      gt_founds     TYPE zcl_program_whereused=>ty_founds.
CONSTANTS:
  gc_screen_group_check TYPE screen-group1 VALUE 'M1',
  gc_screen_group_tr    TYPE screen-group1 VALUE 'M2',
  gc_screen_active_on   TYPE c LENGTH 1 VALUE '1',
  gc_screen_active_off  TYPE c LENGTH 1 VALUE '0',

  gc_ucomm_execute      TYPE sy-ucomm VALUE 'ONLI',

  gc_xl_event_init      TYPE char50 VALUE 'CONTROLS_INIT',
  gc_xl_event_fcode     TYPE char50 VALUE 'FUNCTION_CODE',
  gc_xl_fcode_download  TYPE ui_func VALUE 'ZDOWNLOAD',
  gc_xl_text_download   TYPE text40 VALUE 'Download' ##NO_TEXT,
  gc_xl_memory_name     TYPE c LENGTH 32 VALUE 'ZGSP04_XLSX_NAME',

  gc_xl_default_name    TYPE string VALUE 'EXPORT.xlsx',
  gc_xl_window_title    TYPE string VALUE 'Save Excel File' ##NO_TEXT,
  gc_xl_default_ext     TYPE string VALUE 'xlsx',
  gc_xl_file_filter     TYPE string VALUE 'Excel Files (*.xlsx)|*.xlsx|' ##NO_TEXT,

  gc_xl_method_app      TYPE ole_verb VALUE 'Application' ##NO_TEXT,
  gc_xl_prop_workbook   TYPE ole_verb VALUE 'ActiveWorkbook' ##NO_TEXT,
  gc_xl_method_saveas   TYPE ole_verb VALUE 'SaveAs' ##NO_TEXT,

  gc_sev_error          TYPE c VALUE 'E'.
