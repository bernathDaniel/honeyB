//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_gpp_driver.sv
//=============================================================================
// Description: Driver for xlr_gpp
//=============================================================================

`ifndef XLR_GPP_DRIVER_SV
`define XLR_GPP_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class xlr_gpp_driver extends uvm_driver #(xlr_gpp_tx);

  `uvm_component_utils(xlr_gpp_driver)

  virtual xlr_gpp_if vif;

  extern function new(string name, uvm_component parent);

  extern task run_phase(uvm_phase phase);
  extern task do_drive(); // User - Specific code for driver

endclass : xlr_gpp_driver 


function xlr_gpp_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task xlr_gpp_driver::run_phase(uvm_phase phase);

  // Declares that run phase starts
  `uvm_info("", "run_phase", UVM_MEDIUM)
  
  forever
  begin
    if (!vif.rst_n) begin
      vif.host_regsi <= '0;
      vif.host_regs_valid <= '0;

      @(posedge vif.rst_n);
      continue; // go to next interation once rst_n is deasserted.
    end
    seq_item_port.get_next_item(req);
    
    // Debug Statement - Tx logging of the driver
    `uvm_info("", "New seq item received in GPP Driver !", UVM_MEDIUM)

    phase.raise_objection(this);

    do_drive(); // User - Specific code for driver
    
    fork
      begin
        repeat (10) @(posedge vif.clk);
        phase.drop_objection(this);
      end
    join_none

    //Notified UVM that the current transaction is done
    seq_item_port.item_done();
  end
endtask : run_phase

task xlr_gpp_driver::do_drive(); // User - Specific code for driver
  int wait2start = 0;
  `uvm_info("", "GPP Driver received START Signal :", UVM_LOW)
  foreach (req.host_regsi[i]) begin
    if (req.host_regsi[i] != 32'h0)
      `uvm_info("", $sformatf("host_regsi[%0d] = %0d", i, req.host_regsi[i]), UVM_LOW)
  end
  `uvm_info("", $sformatf("host_regs_valid = %0d", req.host_regs_valid[0]), UVM_LOW)
  
  @(negedge vif.clk); // wait for 1 clk

  // Drive host_regsi value
  vif.host_regsi <= req.host_regsi;
  // Drive valid pulse for one cycle
  vif.host_regs_valid <= req.host_regs_valid;
  
  @(negedge vif.clk); // Need to make sure that waiting a single positive clock is valid

  vif.host_regsi <= '0;
  vif.host_regs_valid <= '0;
    
  // If this was a start signal, wait for busy to clear and done to assert
  if (req.host_regsi[0][0] && req.host_regs_valid[0]) begin
    `uvm_info("", "gpp driver waiting for 'done signal'", UVM_MEDIUM)
    while(vif.host_regso[1][0] != 1'b1 && vif.host_regso_valid[1] != 1'b1) @(negedge vif.clk);
    // Wait for done to clear - done is in GPR[1], GPR[0] holds busy signal !
    `uvm_info("", "gpp driver got 'done signal' moving on...", UVM_MEDIUM)
    wait2start = $urandom_range(1,5); // Add delay until next start
    repeat(wait2start) @(negedge vif.clk);
  end
endtask : do_drive

`endif // XLR_GPP_DRIVER_SV

