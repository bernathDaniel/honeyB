function void reference::write_reference_0(xlr_mem_tx t);
  send_xlr_mem_input(t);
endfunction
  
function void reference::write_reference_1(xlr_gpp_tx t);
  send_xlr_gpp_input(t);
endfunction

// Mem Input 
// trans_var = rand logic [0:0][7:0][31:0] mem_rdata;
// trans_var = logic [0:0] mem_rd;
// trans_var = logic [0:0][3:0] mem_addr;

// Mem Output
// trans_var = logic [0:0][3:0] mem_addr;
// trans_var = logic [0:0][7:0][31:0] mem_wdata;
// trans_var = logic [0:0][31:0] mem_be;
// trans_var = logic [0:0]mem_rd;
// trans_var = logic [0:0]mem_wr;

function void reference::send_xlr_mem_input(xlr_mem_tx t);
  xlr_mem_tx tx;
  tx = xlr_mem_tx::type_id::create("tx");
  // calculation of 2x2 MatMul
  tx.mem_wdata[0][0] = t.mem_rdata[0][0]*t.mem_rdata[0][4] + t.mem_rdata[0][1]*t.mem_rdata[0][6];
  tx.mem_wdata[0][1] = t.mem_rdata[0][0]*t.mem_rdata[0][5] + t.mem_rdata[0][1]*t.mem_rdata[0][7];
  tx.mem_wdata[0][2] = t.mem_rdata[0][2]*t.mem_rdata[0][4] + t.mem_rdata[0][3]*t.mem_rdata[0][6];
  tx.mem_wdata[0][3] = t.mem_rdata[0][2]*t.mem_rdata[0][5] + t.mem_rdata[0][3]*t.mem_rdata[0][7];
  
  // the expected signals for writing back
  tx.mem_be[0] = 32'hFFFFFFFF; // En all bits
  tx.mem_wr[0] = 1'b1;
  tx.mem_rd[0] = 1'b1;
  tx.mem_addr[0] = 4'h1; // Write res into addr[1]
  analysis_port_0.write(tx);
  
  `uvm_info(get_type_name(), $sformatf("A11 = %0d, A12 = %0d, A21 = %0d, A22 = %0d", t.mem_rdata[0][0], t.mem_rdata[0][1], t.mem_rdata[0][2], t.mem_rdata[0][3]), UVM_HIGH)
  `uvm_info(get_type_name(), $sformatf("B11 = %0d, B12 = %0d, B21 = %0d, B22 = %0d", t.mem_rdata[0][4], t.mem_rdata[0][5], t.mem_rdata[0][6], t.mem_rdata[0][7]), UVM_HIGH)
  `uvm_info(get_type_name(), $sformatf("Reading from Address: %0d", t.mem_addr[0]), UVM_HIGH)
endfunction

// Control Reg Inputs
// trans_var = rand logic [31:0][31:0] host_regsi;
// trans_var = rand logic [31:0] host_regs_valid;

// Control Reg Outputs
// trans_var  = logic [31:0][31:0] host_regso;
// trans_var  = logic [31:0] host_regso_valid;

function void reference::send_xlr_gpp_input(xlr_gpp_tx t);
  xlr_gpp_tx tx;
  tx = xlr_gpp_tx::type_id::create("tx");
  tx.host_regso[1] = 32'h1; // Only assign 1 to host_regso[0] 
  tx.host_regso_valid = 32'h1; // Only assign 1 to host_regso_valid[0]
  analysis_port_1.write(tx); //
  `uvm_info(get_type_name(), $sformatf("host_regs[0][0] = %0d, host_regs_valid_pulse[0] = %0d", t.host_regsi[0][0], t.host_regs_valid[0]), UVM_HIGH)
endfunction