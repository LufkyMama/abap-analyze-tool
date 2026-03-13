class ZCL_PROGRAM_ALV definition
  public
  final
  create public .

public section.

  methods ALV_DISPLAY
    importing
      !IT_DATA type ZTT_ERROR optional .
protected section.
private section.
ENDCLASS.



CLASS ZCL_PROGRAM_ALV IMPLEMENTATION.


  METHOD alv_display.

  DATA: lt_data TYPE ztt_error, "local copy, để tránh lỗi IT_DATA read-only
        lo_alv  TYPE REF TO cl_salv_table.

  lt_data = it_data.

  cl_salv_table=>factory(
    IMPORTING
      r_salv_table = lo_alv
    CHANGING
      t_table      = lt_data
  ).

  lo_alv->get_functions( )->set_all( abap_true ).
  lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
  lo_alv->get_columns( )->set_optimize( abap_true ).

  lo_alv->display( ).

ENDMETHOD.
ENDCLASS.
