
# XM-Sim Command File
# TOOL:	xmsim(64)	22.03-s002
#
#
# You can restore this configuration with:
#
#      xrun -f ../scripts/xrun_options.rtl -input /project/test_project/users/bernatd/ws/Mannix2/Mannix2/standalone/UVM/MatMul_2x2_Hybrid+Scrbrd/scripts/gpp_compare.tcl
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
set vcd_compact_mode 0
alias . run
alias quit exit
stop -create -name Randomize -randomize
database -open -shm -into waves.shm waves -default
probe -create -database waves top_tb.th._gpp_if.clk top_tb.th._gpp_if.host_regs_valid top_tb.th._gpp_if.host_regsi top_tb.th._gpp_if.host_regso top_tb.th._gpp_if.host_regso_valid top_tb.th._gpp_if.rst_n top_tb.th.dut.busy top_tb.th.dut.clk top_tb.th.dut.done top_tb.th.dut.host_regs top_tb.th.dut.host_regs_data_out top_tb.th.dut.host_regs_valid_out top_tb.th.dut.host_regs_valid_pulse top_tb.th.dut.mem_arr top_tb.th.dut.next_mem_arr top_tb.th.dut.next_state top_tb.th.dut.res_arr top_tb.th.dut.rst_n top_tb.th.dut.start top_tb.th.dut.state top_tb.th.dut.xlr_mem_addr top_tb.th.dut.xlr_mem_be top_tb.th.dut.xlr_mem_rd top_tb.th.dut.xlr_mem_rdata top_tb.th.dut.xlr_mem_wdata top_tb.th.dut.xlr_mem_wr

simvision -input gpp_compare.tcl.svcf
