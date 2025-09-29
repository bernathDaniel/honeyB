#!/bin/sh
vcs -sverilog +acc +vpi -timescale=1ns/1ps -ntb_opts uvm-1.2 \
+incdir+../tb/include \
+incdir+../tb/xlr_mem/sv \
+incdir+../tb/xlr_gpp/sv \
+incdir+../../../../syosil/src\
+incdir+../tb/top/sv \
+incdir+../tb/top_test/sv \
+incdir+../tb/top_tb/sv \
-F ../dut/files.f \
../tb/xlr_mem/sv/xlr_mem_pkg.sv \
../tb/xlr_mem/sv/xlr_mem_if.sv \
../tb/xlr_gpp/sv/xlr_gpp_pkg.sv \
../tb/xlr_gpp/sv/xlr_gpp_if.sv \
../../../../syosil/src/pk_syoscb.sv \
../tb/top/sv/top_pkg.sv \
../tb/top_test/sv/top_test_pkg.sv \
../tb/top_tb/sv/top_th.sv \
../tb/top_tb/sv/top_tb.sv \
-R +UVM_TESTNAME=top_test  $* 
