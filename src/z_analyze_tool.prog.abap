REPORT z_analyze_tool.

INCLUDE z_analyze_tool_top.   " Global data
INCLUDE z_analyze_tool_o01.   " PBO / screen output
INCLUDE z_analyze_tool_i01.   " PAI / input processing
INCLUDE z_analyze_tool_f01.   " Subroutines

START-OF-SELECTION.
  PERFORM start_of_selection_main.
