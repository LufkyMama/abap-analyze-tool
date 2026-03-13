*&---------------------------------------------------------------------*
*& Report Z_MAIN_PROGRAM
*&---------------------------------------------------------------------*
REPORT Z_MAIN_PROGRAM.
TABLES SSCRFIELDS.

*--------------------------------------------------------------------*
* 1. SELECTION SCREEN (The User Interface)
*--------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK B1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: P_TR   TYPE TRKORR MATCHCODE OBJECT TR_REQUEST_CHOICE,
              P_FUGR TYPE RS38L-AREA,
              P_PROG TYPE PROGNAME MATCHCODE OBJECT PROGNAME,
              P_FUNC TYPE RS38L-NAME MATCHCODE OBJECT FUNCNAME,
              P_CLAS TYPE SEOCLSNAME MATCHCODE OBJECT SEO_CLASSES.
SELECTION-SCREEN END OF BLOCK B1.

SELECTION-SCREEN BEGIN OF BLOCK B2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: CB_NAME  AS CHECKBOX DEFAULT 'X', " Naming Convention
              CB_HARD  AS CHECKBOX DEFAULT 'X', " Hardcode Check
              CB_CLEAN AS CHECKBOX DEFAULT 'X', " Clean Code
              CB_PERF  AS CHECKBOX DEFAULT 'X', " Performance
              CB_OBS   AS CHECKBOX DEFAULT 'X', " Obsolete
              CB_USED  AS CHECKBOX.             " Where Used
SELECTION-SCREEN END OF BLOCK B2.

*--------------------------------------------------------------------*
* 2. DATA DEFINITIONS
*--------------------------------------------------------------------*
DATA: LO_CONTROLLER TYPE REF TO ZCL_PROGRAM_CONTROLLER,
      LT_ERRORS     TYPE ZTT_ERROR,
      LT_FOUNDS     TYPE ZCL_PROGRAM_WHEREUSED=>TY_FOUNDS.

*--------------------------------------------------------------------*
* 3. VALIDATION ON SELECTION SCREEN
*--------------------------------------------------------------------*
AT SELECTION-SCREEN.
  PERFORM NORMALIZE USING: P_PROG, P_TR, P_FUGR, P_FUNC, P_CLAS.

  DATA(LV_CNT) = 0.
  IF P_PROG IS NOT INITIAL. LV_CNT += 1. ENDIF.
  IF P_TR   IS NOT INITIAL. LV_CNT += 1. ENDIF.
  IF P_FUGR IS NOT INITIAL. LV_CNT += 1. ENDIF.
  IF P_FUNC IS NOT INITIAL. LV_CNT += 1. ENDIF.
  IF P_CLAS IS NOT INITIAL. LV_CNT += 1. ENDIF.

  IF LV_CNT = 0.
    MESSAGE E001(Z_GSP04_MESSAGE).
  ELSEIF LV_CNT > 1.
    MESSAGE E004(Z_GSP04_MESSAGE) WITH P_PROG P_TR.
  ENDIF.

  " Validate tồn tại cho Program, TR, FG
  IF P_PROG IS NOT INITIAL.
    SELECT SINGLE NAME FROM TRDIR WHERE NAME = @P_PROG INTO @DATA(LV_PROG_CHECK).
    IF SY-SUBRC <> 0. MESSAGE E002(Z_GSP04_MESSAGE) WITH P_PROG. ENDIF.
  ENDIF.

  IF P_TR IS NOT INITIAL.
    SELECT SINGLE TRKORR FROM E070 WHERE TRKORR = @P_TR INTO @DATA(LV_TR_CHECK).
    IF SY-SUBRC <> 0. MESSAGE E003(Z_GSP04_MESSAGE) WITH P_TR. ENDIF.
  ENDIF.

  IF P_FUGR IS NOT INITIAL.
    SELECT SINGLE AREA FROM TLIBG WHERE AREA = @P_FUGR INTO @DATA(LV_AREA).
    IF SY-SUBRC <> 0.
      MESSAGE |Function Group { P_FUGR } does not exist!| TYPE 'E'.
    ENDIF.
  ENDIF.

*--------------------------------------------------------------------*
* 4. CONTROLLER LOGIC (Start of Selection)
*--------------------------------------------------------------------*
START-OF-SELECTION.
  LO_CONTROLLER = NEW ZCL_PROGRAM_CONTROLLER( ).

  " Điều phối xử lý theo loại đối tượng
  IF P_FUNC IS NOT INITIAL.
    LT_ERRORS = LO_CONTROLLER->RUN_CHECK_FM(
      IV_FUNCNAME = P_FUNC IV_CHECK_NAMING = CB_NAME
      IV_CHECK_CLEAN = CB_CLEAN IV_CHECK_PERF = CB_PERF IV_CHECK_USED = CB_USED ).

  ELSEIF P_FUGR IS NOT INITIAL.
    LT_ERRORS = LO_CONTROLLER->RUN_CHECK_FUGR(
      IV_FUGR = P_FUGR
 IV_CHECK_NAMING = CB_NAME
 IV_CHECK_HARD = CB_HARD
IV_CHECK_OBSOLETE = CB_OBS
 ).

  ELSEIF P_TR IS NOT INITIAL.
    LT_ERRORS = LO_CONTROLLER->RUN_CHECK_TR(
      IV_TRKORR = P_TR IV_CHECK_NAMING = CB_NAME
      IV_CHECK_PERF = CB_PERF IV_CHECK_USED = CB_USED ).
  ELSE.
    LT_ERRORS = LO_CONTROLLER->RUN_CHECK_PROGRAM(
      IV_PROG_NAME = P_PROG IV_CHECK_NAMING = CB_NAME IV_CHECK_PERF = CB_PERF
      IV_CHECK_OBSOLETE = CB_OBS IV_CHECK_CLEAN = CB_CLEAN IV_CHECK_HARDCODE = CB_HARD ).
  ENDIF.

  " Xử lý Where-used list
  IF CB_USED = ABAP_TRUE.
    LT_FOUNDS = LO_CONTROLLER->RUN_WHERE_USED(
      IV_TR = P_TR IV_FUGR = P_FUGR IV_PROG = P_PROG IV_FUNC = P_FUNC IV_CLAS = P_CLAS ).
  ENDIF.

  "--- HIỂN THỊ KẾT QUẢ ---
  IF LT_ERRORS IS INITIAL.
    " Thông báo thành công nếu không có lỗi nào
    MESSAGE S005(Z_GSP04_MESSAGE).
  ELSE.
    " Hiển thị bảng lỗi qua ALV chuyên nghiệp
    DATA(LO_ALV) = NEW ZCL_PROGRAM_ALV( ).
    LO_ALV->ALV_DISPLAY( IT_DATA = LT_ERRORS ).
  ENDIF.

*--------------------------------------------------------------------*
* FORM normalize
*--------------------------------------------------------------------*
FORM NORMALIZE USING P_ANY TYPE ANY.
  IF P_ANY IS NOT INITIAL.
    CONDENSE P_ANY NO-GAPS.
    TRANSLATE P_ANY TO UPPER CASE.
  ENDIF.
ENDFORM.
