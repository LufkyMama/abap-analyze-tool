class ZCL_PROGRAM_FETCH definition
  public
  final
  create public .

public section.

  methods GET_FUNCTION_GROUP
    importing
      value(IV_FG_NAME) type RS38L-AREA
    exporting
      value(ET_SOURCE) type STRING_TABLE .
  methods GET_TR_SOURCE
    importing
      !IV_TRKORR type TRKORR
    returning
      value(RT_SOURCE) type STRING_TABLE .
  methods GET_SOURCE_CODE
    importing
      !IV_PROG_NAME type PROGNAME
    returning
      value(RT_SOURCE) type STRING_TABLE .
  methods GET_FUNCTION_MODULE
    importing
      !IV_FUNCNAME type RS38L-NAME
    exporting
      !EV_MAIN_PROG type PROGNAME
      !EV_INCLUDE type PROGNAME
    returning
      value(RT_SOURCE) type STRING_TABLE .
  methods GET_CLASS
    importing
      !IV_CLASS type SEOCLSNAME
    returning
      value(RT_SOURCE) type RSWSOURCET .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PROGRAM_FETCH IMPLEMENTATION.


METHOD get_class.

  DATA: lv_cp       TYPE program,
        lt_includes TYPE STANDARD TABLE OF progname,
        lv_include  TYPE progname,
        lt_source   TYPE rswsourcet.

  CLEAR rt_source.

  " Get correct classpool program name (…CP)
  TRY.
      lv_cp = cl_oo_classname_service=>get_classpool_name( iv_class ).
    CATCH cx_root.
      RETURN.
  ENDTRY.

  IF lv_cp IS INITIAL.
    RETURN.
  ENDIF.

  " Get all includes of classpool
  SELECT include
    FROM d010inc
    INTO TABLE @lt_includes
    WHERE master = @lv_cp.

  " Also read the CP itself
  APPEND lv_cp TO lt_includes.
  SORT lt_includes.
  DELETE ADJACENT DUPLICATES FROM lt_includes.

  LOOP AT lt_includes INTO lv_include.
    CLEAR lt_source.
    READ REPORT lv_include INTO lt_source.
    IF sy-subrc = 0 AND lt_source IS NOT INITIAL.
      APPEND LINES OF lt_source TO rt_source.
    ENDIF.
  ENDLOOP.

ENDMETHOD.


METHOD get_function_group.
  " Thao tác trực tiếp trên tham số ET_SOURCE
  CLEAR et_source.

  " 1. Lấy mã nguồn từ TOP include một cách an toàn
  DATA(lt_top_src) = me->get_source_code( |L{ iv_fg_name }TOP| ).
  IF lt_top_src IS NOT INITIAL.
    APPEND LINES OF lt_top_src TO et_source.
  ENDIF.

  " 2. Lấy danh sách tất cả các include thuộc về Function Group
  DATA: lt_incls TYPE STANDARD TABLE OF progname,
        lv_like  TYPE progname.

  " Sử dụng pattern chặt chẽ hơn để tránh lấy nhầm FG khác
  lv_like = |L{ iv_fg_name }%|.

  SELECT name FROM trdir
    WHERE name LIKE @lv_like
    INTO TABLE @lt_incls.

  " 3. Duyệt và gộp mã nguồn
  LOOP AT lt_incls INTO DATA(lv_incl).
    " Bỏ qua TOP (đã lấy ở trên) và các include rỗng/kỹ thuật không cần thiết
    IF lv_incl CP '*TOP' OR lv_incl CP '*UXX'.
      CONTINUE.
    ENDIF.

    DATA(lt_temp) = me->get_source_code( lv_incl ).
    IF lt_temp IS NOT INITIAL.
      " Thêm dòng ngăn cách giữa các Include để tránh lỗi SCAN nhầm dòng
      APPEND INITIAL LINE TO et_source.
      APPEND LINES OF lt_temp TO et_source.
    ENDIF.
  ENDLOOP.

  " 4. Kiểm tra cuối cùng: Nếu không có code, báo lỗi qua Controller
  IF et_source IS INITIAL.
    " Logic xử lý thông báo "No source code found"
  ENDIF.
ENDMETHOD.


METHOD get_function_module.
    DATA: lv_funcname TYPE rs38l-name,
          lv_pname    TYPE progname,
          lv_incno    TYPE tfdir-include,
          lv_include  TYPE progname.

    CLEAR rt_source.
    CLEAR: lv_pname, lv_incno, lv_include.
    CLEAR: ev_main_prog, ev_include.

    lv_funcname = iv_funcname.
    TRANSLATE lv_funcname TO UPPER CASE.

    "1) Lấy metadata từ TFDIR: program của function group + include number của FM
    SELECT SINGLE pname include
      INTO (lv_pname, lv_incno)
      FROM tfdir
      WHERE funcname = lv_funcname.

    IF sy-subrc <> 0 OR lv_pname IS INITIAL OR lv_incno IS INITIAL.
      "Không có FM / hoặc metadata thiếu -> trả rỗng
      RETURN.
    ENDIF.

    "2) Ghép ra tên include thật sự (L<group>Uxx...) từ include number
    CALL FUNCTION 'FUNCTION_INCLUDE_CONCATENATE'
      EXPORTING
        include_number = lv_incno
      IMPORTING
        include        = lv_include
      CHANGING
        program        = lv_pname
      EXCEPTIONS
        not_enough_input        = 1
        no_function_pool        = 2
        delimiter_wrong_position = 3
        OTHERS                  = 4.

    IF sy-subrc <> 0 OR lv_include IS INITIAL.
      RETURN.
    ENDIF.

    ev_main_prog = lv_pname.
    ev_include   = lv_include.

    "3) Đọc source include đó bằng READ REPORT
    rt_source = me->get_source_code( iv_prog_name = lv_include ).

  ENDMETHOD.


  METHOD get_source_code.
    CLEAR rt_source.
    " Tries to read the report (program) code into the table
    READ REPORT iv_prog_name INTO rt_source.

    IF sy-subrc <> 0.
      CLEAR rt_source.
    ENDIF.
  ENDMETHOD.


  METHOD get_tr_source.


    DATA: lt_e071 TYPE STANDARD TABLE OF e071,
          ls_e071 TYPE e071,
          lt_temp TYPE string_table,
          lt_fg   TYPE string_table,
          lv_prog TYPE progname,
          lv_fugr TYPE rs38l_area,
          lv_func TYPE rs38l-name.

    CLEAR rt_source.

    IF iv_trkorr IS INITIAL.
      RETURN.
    ENDIF.

    SELECT *
      FROM e071
      INTO TABLE lt_e071
      WHERE trkorr = iv_trkorr.

    IF lt_e071 IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_e071 INTO ls_e071.

      CLEAR lt_temp.

      CASE ls_e071-object.

        WHEN 'PROG'.
          CLEAR lv_prog.
          lv_prog = ls_e071-obj_name.

          lt_temp = me->get_source_code( iv_prog_name = lv_prog ).
          IF lt_temp IS NOT INITIAL.
            APPEND LINES OF lt_temp TO rt_source.
          ENDIF.

        WHEN 'FUGR'.
          CLEAR lv_fugr.
          lv_fugr = ls_e071-obj_name.

          CLEAR lt_fg.
          me->get_function_group(
            EXPORTING iv_fg_name = lv_fugr
            IMPORTING et_source  = lt_fg
          ).
          IF lt_fg IS NOT INITIAL.
            APPEND LINES OF lt_fg TO rt_source.
          ENDIF.

        WHEN 'FUNC'.
          CLEAR lv_func.
          lv_func = ls_e071-obj_name.     "convert type
          lt_temp = me->get_function_module( iv_funcname = lv_func ).

          IF lt_temp IS NOT INITIAL.
            APPEND LINES OF lt_temp TO rt_source.
          ENDIF.



        WHEN OTHERS.
          CONTINUE.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
