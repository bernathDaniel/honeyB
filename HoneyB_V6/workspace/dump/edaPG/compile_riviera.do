
file delete -force work

alib work

# Compile the dut code
set cmd "alog -uvm -f ../dut/files.f"
eval $cmd

set cmd "alog -uvm "

set tb_name top
append cmd " +incdir+../tb/include "

# Compile the agents
set agent_list {\ 
    xlr_mem \
    xlr_gpp \
}
foreach  ele $agent_list {
  if {$ele != " "} {
    append cmd " +incdir+../tb/" $ele "/sv ../tb/" $ele "/sv/" $ele "_pkg.sv ../tb/" $ele "/sv/" $ele "_if.sv"
  }
}

# Compile the Syosil scoreboard
append cmd  " +incdir+../../../../syosil/src ../../../../syosil/src/pk_syoscb.sv"

# Compile the test and the modules
append cmd " +incdir+../tb/" $tb_name "/sv"
append cmd " ../tb/" $tb_name "/sv/" $tb_name "_pkg.sv"
append cmd " ../tb/" $tb_name "_test/sv/" $tb_name "_test_pkg.sv"
append cmd " ../tb/" $tb_name "_tb/sv/" $tb_name "_th.sv"
append cmd " ../tb/" $tb_name "_tb/sv/" $tb_name "_tb.sv"
eval $cmd

asim top_tb +UVM_TESTNAME=top_test  -voptargs=+acc -solvefaildebug -uvmcontrol=all -classdebug
run -all
quit
