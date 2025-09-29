//=============================================================================
// Project  : HoneyB V4
// File Name: xlr_gpp_driver.sv
//=============================================================================
// Description: Driver for xlr_gpp
//=============================================================================

`ifndef XLR_GPP_DRIVER_SV
`define XLR_GPP_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_gpp_pkg::*;

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

  // Update Statement
  `honeyb("GPP Driver", "run_phase initialized...")

  forever begin
    if (!vif.rst_n) begin
      vif.host_regsi      <= '0;
      vif.host_regs_valid <= '0;

      @(posedge vif.rst_n);
      continue; // go to next interation once rst_n is deasserted.
    end
    seq_item_port.get_next_item(req);
    
    // Updated Statement
    `honeyb("GPP Driver", "New seq item received. driving...")

    phase.raise_objection(this);

    do_drive(); // User - Specific code for driver
    
    fork
      begin
        repeat (10) @(posedge vif.clk);
        phase.drop_objection(this);
      end
    join_none

    seq_item_port.item_done();
  end
endtask : run_phase

task xlr_gpp_driver::do_drive();              // User - Specific code for driver
  int wait2start = 0;
  
  @(negedge vif.clk);                         // wait for 1 clk

  //vif.host_regsi      <= req.host_regsi;      // Drive Control & Status Signals.
  //vif.host_regs_valid <= req.host_regs_valid; // Drive valid pulse for one cycle
  
  // Drive only meaningful registers
  for (int csr_idx = 0; csr_idx < 32; csr_idx++) begin /* Explicit Check for START (for clarity)
  ----------------------------------------------------------------------------------------------                                                                       */
  if (csr_idx == START_IDX_REG && req.host_regs_valid[csr_idx] == 1'b1) begin
    vif.host_regsi     [START_IDX_REG]  <= req.host_regsi[START_IDX_REG];
    vif.host_regs_valid[START_IDX_REG]  <= 1'b1;                                                                                                                                  /*
  ----------------------------------------------------------------------------------------------                                                                       */
  end else if (req.host_regs_valid[csr_idx] == 1'b1) begin
    vif.host_regsi[csr_idx]       <= req.host_regsi[csr_idx];
    vif.host_regs_valid[csr_idx]  <= 1'b1;
  end
  // No else - let the undriven maintain state (REALISTIC CPU BEHAVIOR, REDUCES UNNECESSARY CYCLES)
end
    

  if (is_start_asserted(req.host_regsi[START_IDX_REG], req.host_regs_valid[START_IDX_REG])) begin

    @(negedge vif.clk); // Hold START = 1 for 1 clk cycle                       

    vif.host_regsi      [START_IDX_REG]  <= '0; // de-assert
    vif.host_regs_valid [START_IDX_REG]  <= '0;

    // Report
    `honeyb("GPP Driver", "waiting for DONE signal...")

    while(done_is_deasserted( vif.host_regso      [DONE_IDX_REG],     // Wait for DONE assertion + Sudden RST Handling
                              vif.host_regso_valid[DONE_IDX_REG]) &&  // Do this while:
                              vif.rst_n)                              @(negedge vif.clk);

    // Report
    `honeyb("GPP Driver", "Received DONE signal, moving on...")
    if (!vif.rst_n) begin
      wait2start = $urandom_range(1,5); // Add delay until next start
      repeat(wait2start) @(negedge vif.clk);
    end
  end
endtask : do_drive

`endif // XLR_GPP_DRIVER_SV

