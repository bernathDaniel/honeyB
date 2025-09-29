agent_name = xlr_mem

trans_item = xlr_mem_tx

# Inputs

trans_var = rand logic [0:0][7:0][31:0] mem_rdata;

# Outputs

trans_var = logic [0:0][3:0] mem_addr; # 3=LOG2_LINES_PER_MEM in DUT
trans_var = logic [0:0][7:0][31:0] mem_wdata;
trans_var = logic [0:0][31:0] mem_be;
trans_var = logic [0:0] mem_rd;
trans_var = logic [0:0] mem_wr;

# Constraint for min / max possible number for each element

trans_var = constraint c_mem_rdata_0 { mem_rdata[0][0] inside {[0:20]}; }
trans_var = constraint c_mem_rdata_1 { mem_rdata[0][1] inside {[0:20]}; }
trans_var = constraint c_mem_rdata_2 { mem_rdata[0][2] inside {[0:20]}; }
trans_var = constraint c_mem_rdata_3 { mem_rdata[0][3] inside {[0:20]}; }
trans_var = constraint c_mem_rdata_4 { mem_rdata[0][4] inside {[0:20]}; }
trans_var = constraint c_mem_rdata_5 { mem_rdata[0][5] inside {[0:20]}; }
trans_var = constraint c_mem_rdata_6 { mem_rdata[0][6] inside {[0:20]}; }
trans_var = constraint c_mem_rdata_7 { mem_rdata[0][7] inside {[0:20]}; }

# Instantiate Driver, Monitor & Coverage :

driver_inc_inside_class = xlr_mem_driver_inc_inside_class.sv  inline
driver_inc_after_class  = xlr_mem_driver_inc_after_class.sv   inline
monitor_inc             = xlr_mem_do_mon.sv                   inline
agent_cover_inc         = xlr_mem_cover_inc.sv                inline

# Agent ports def.

if_port = logic [0:0][7:0][31:0] mem_rdata;
if_port = logic [0:0][3:0] mem_addr;
if_port = logic [0:0][7:0][31:0] mem_wdata;
if_port = logic [0:0][31:0] mem_be;
if_port = logic [0:0] mem_rd;
if_port = logic [0:0] mem_wr;
if_clock = clk
if_reset = rst_n

# NOTE - mem_rd defined in the driver - it can send transactions only if
# the device sends a request by xlr_mem_rd = 1'b1 !!