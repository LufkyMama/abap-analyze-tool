class ZCL_DEMO_FULL definition
  public
  final
  create public
  for testing .

public section.

  methods CONSTRUCTOR
    importing
      !IV_START type I default 0 .
  methods CREATE_PERSON .
  methods GET_COUNTER .
  class-methods GET_TOTAL_CREATED .
protected section.

  methods ADD_PERSON_INTERNAL .
private section.

  methods OBSOLETE_EXAMPLE .
ENDCLASS.



CLASS ZCL_DEMO_FULL IMPLEMENTATION.


  method ADD_PERSON_INTERNAL.
  endmethod.


  method CONSTRUCTOR.
  endmethod.


  method CREATE_PERSON.
  endmethod.


  method GET_COUNTER.
  endmethod.


  method GET_TOTAL_CREATED.
  endmethod.


  method OBSOLETE_EXAMPLE.
  endmethod.
ENDCLASS.
