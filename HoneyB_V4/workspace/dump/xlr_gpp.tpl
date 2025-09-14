agent_name = xlr_gpp

trans_item = xlr_gpp_tx

# Inputs

trans_var = rand logic [31:0][31:0] host_regsi;
trans_var = rand logic [31:0] host_regs_valid;

# Output regs defined for syncing agents

trans_var  = logic [31:0][31:0] host_regso;
trans_var  = logic [31:0] host_regso_valid;

# Constrain host regs only to work with host_regs[0] :

trans_var  = constraint c_gpp_data { host_regsi[0][0] inside {0, 1}; }
trans_var  = constraint c_gpp_null { host_regsi[0][31:1] inside {0}; }
trans_var  = constraint c_gpp_nullr { host_regsi[31:1][31:0] inside {0}; }

# Constraint valid pulse only to host_regs_valid = 32'h1 or 32'h0

trans_var  = constraint c_gpp_valid_data { host_regs_valid[0] inside {0, 1}; }
trans_var  = constraint c_gpp_valid_null { host_regs_valid[31:1] inside {0}; }

# Constraint to make 1,1 5 times more likely than 0,0 / 0,1 / 1,0

trans_var  = constraint c_gpp_valid_data_dist { host_regs_valid[0] dist {0 := 1, 1 := 5}; host_regsi[0][0] dist {0 := 1, 1 := 5}; }

# Instantiate Driver, Monitor & Coverage :

driver_inc_inside_class = xlr_gpp_driver_inc_inside_class.sv  inline
driver_inc_after_class  = xlr_gpp_driver_inc_after_class.sv   inline
monitor_inc             = xlr_gpp_do_mon.sv                   inline
agent_cover_inc         = xlr_gpp_cover_inc.sv                inline

# Agent ports def.

if_port  = logic [31:0][31:0] host_regsi;
if_port  = logic [31:0] host_regs_valid;
if_port  = logic [31:0][31:0] host_regso;
if_port  = logic [31:0] host_regso_valid;
if_clock = clk
if_reset = rst_n