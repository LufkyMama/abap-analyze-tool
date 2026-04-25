*&---------------------------------------------------------------------*
*& Include ZTEST_ANALYZE_CLEANCODE_ALL
*&
*&---------------------------------------------------------------------*


DATA: lv_unused_var TYPE string.


DATA: lv_used_var TYPE string.
lv_used_var = 'Hello World'.


CONSTANTS: lc_unused_const TYPE i VALUE 1.


FIELD-SYMBOLS: <fs_unused> TYPE any.



lv_cross_used = 100.
WRITE: / 'Cross used variable value:', lv_cross_used.



CLASS lcl_clean_code_test DEFINITION.
  PUBLIC SECTION.

    CLASS-DATA: cv_unused_cdata TYPE i.


    CLASS-DATA: cv_used_cdata TYPE i.


    CONSTANTS: cc_unused_cconst TYPE string VALUE 'DUMMY'.

    CLASS-METHODS: do_something.
ENDCLASS.

CLASS lcl_clean_code_test IMPLEMENTATION.
  METHOD do_something.
    cv_used_cdata = 10.
  ENDMETHOD.
ENDCLASS.



FORM test_statics_vars.

  STATICS: st_unused_stat TYPE i.


  STATICS: st_used_stat TYPE i.
  st_used_stat = st_used_stat + 1.
ENDFORM.

FORM unused_form.

  DATA: lv_dummy TYPE i.
ENDFORM.

FORM used_form.
  "
  WRITE: / 'This form is used'.
ENDFORM.


WRITE: / TEXT-001.


" ======================================================================
" ======================================================================


DATA: BEGIN OF ls_parent_used,
        comp1 TYPE i,
        comp2 TYPE string,
      END OF ls_parent_used.

CLEAR ls_parent_used.



DATA: BEGIN OF ls_parent_unused,
        comp1 TYPE i,
        comp2 TYPE string,
      END OF ls_parent_unused.


DATA: BEGIN OF ls_parent_mixed,
        comp_used   TYPE i,
        comp_unused TYPE string,
      END OF ls_parent_mixed.

ls_parent_mixed-comp_used = 10.


TYPES: ty_simple_unused TYPE i.


TYPES: BEGIN OF ty_root_used,
         comp1 TYPE i,
         comp2 TYPE string,
       END OF ty_root_used.

DATA: ls_type_used TYPE ty_root_used.
ls_type_used-comp1 = 100.
ls_type_used-comp2 = 'Test'.


TYPES: BEGIN OF ty_root_unused_child_used,
         child1 TYPE i,
         child2 TYPE c LENGTH 10,
       END OF ty_root_unused_child_used.


DATA: lv_only_child_used TYPE ty_root_unused_child_used-child1.
lv_only_child_used = 1.


TYPES: BEGIN OF ty_completely_unused,
         comp1 TYPE i,
         comp2 TYPE d,
       END OF ty_completely_unused.


" ======================================================================

" ======================================================================

INITIALIZATION.

  DATA: lv_init_unused TYPE i.

AT SELECTION-SCREEN.

  DATA: lv_screen_used TYPE i.
  lv_screen_used = 1.


  DATA: lv_screen_unused TYPE i.

TOP-OF-PAGE.

  DATA: lv_top_unused TYPE string.


START-OF-SELECTION.

  DATA: lv_start_unused TYPE d.


  DATA: lv_unused_var TYPE string.

  CONSTANTS: lc_unused_const TYPE i VALUE 1.

  FIELD-SYMBOLS: <fs_unused> TYPE any.

  DATA: lv_used_var TYPE string.
  lv_used_var = 'Hello World'.


  gv_cross_used = 100.


  DATA: BEGIN OF ls_parent_used,
          comp1 TYPE i,
          comp2 TYPE string,
        END OF ls_parent_used.
  CLEAR ls_parent_used.


  DATA: BEGIN OF ls_parent_unused,
          comp1 TYPE i,
          comp2 TYPE string,
        END OF ls_parent_unused.

  DATA: BEGIN OF ls_parent_mixed,
          comp_used   TYPE i,
          comp_unused TYPE string,
        END OF ls_parent_mixed.
  ls_parent_mixed-comp_used = 10.

  " ------------------------------------------------------------------


  lcl_test_class=>execute_logic( ).
  PERFORM used_form.

  DATA: ls_type_used TYPE ty_root_used.
  ls_type_used-comp1 = 10.

  DATA: lv_only_child_used TYPE ty_root_unused_child_used-child1.
  lv_only_child_used = 1.


  WRITE: / TEXT-001.


" ======================================================================

CLASS lcl_test_class IMPLEMENTATION.
  METHOD execute_logic.
    cv_used_cdata = 10.
  ENDMETHOD.
ENDCLASS.


FORM unused_form.
  DATA: lv_dummy TYPE i.
ENDFORM.


FORM used_form.

  DATA: lv_form_used TYPE i.
  lv_form_used = 5.

  DATA: lv_form_unused TYPE string.


  STATICS: st_unused_stat TYPE i.
  STATICS: st_used_stat TYPE i.
  st_used_stat = st_used_stat + 1.
ENDFORM.


" ======================================================================





DATA: lv_dummy_421 TYPE i.










DATA: lv_dummy_422 TYPE i.



" This comment resets the empty line counter in ZCLEAN.



DATA: lv_dummy_423 TYPE i.


" ======================================================================


  DATA: lv_used_text TYPE string.
  lv_used_text = TEXT-001.

  " ======================================================================


  DATA: lv_dynamic_form TYPE string VALUE 'DYNAMIC_FORM'.


  PERFORM normal_form.


  PERFORM (lv_dynamic_form).


  PERFORM ext_style_form(ztest_analyze_cleancode_all).


  PERFORM in_prog_form IN PROGRAM ztest_analyze_cleancode_all.


  PERFORM external_target IN PROGRAM saplstxddc.

" ======================================================================

FORM normal_form.
  WRITE: / 'Normal call'.
ENDFORM.


FORM unused_form_442.
  DATA: lv_dummy_442 TYPE i.
ENDFORM.


FORM dynamic_form.
  WRITE: / 'Dynamic call'.
ENDFORM.


FORM ext_style_form.
  WRITE: / 'External style call'.
ENDFORM.


FORM in_prog_form.
  WRITE: / 'IN PROGRAM current call'.
ENDFORM.


FORM external_target.
  WRITE: / 'Local form with same name as external call'.
ENDFORM.
