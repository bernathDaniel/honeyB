//=============================================================================
// Project  : HoneyB V7
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

  //        Helper Methods
  //------------------------------
    extern task clk_posedge_wait();
    extern task clk_negedge_wait();
    extern function logic get_rst_n();
    extern task pin_wig_rst();
    extern task rst_n_negedge_wait();
    extern task rst_n_posedge_wait();
endclass // Boilerplate + Helpers


function xlr_gpp_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction // Boilerplate


task xlr_gpp_driver::run_phase(uvm_phase phase);
  int wait2start = 0;
  `honeyb("GPP Driver", "  run_phase initialized...")
    // Report

  // Boot Sequence
  //===============
  rst_n_negedge_wait();
  pin_wig_rst();
  rst_n_posedge_wait();

  forever begin
    seq_item_port.get_next_item(req);

    `honeyb("GPP Driver", "New seq. item received, driving...")
    phase.raise_objection(this);

    do_drive(); // Drive on posedge timing
      
    fork // drop_delay
      begin // avoiding accidental early terminate
        repeat(10) clk_posedge_wait();
        phase.drop_objection(this);
      end
    join_none

    seq_item_port.item_done();

    if (get_rst_n()) begin
      wait2start = $urandom_range(1,3);
      repeat(wait2start) clk_posedge_wait();
    end // rand delay until next start
  end
endtask // Boilerplate + Boot Seq + Report


task xlr_gpp_driver::do_drive(); // - OK - // - Final - //
  
  clk_posedge_wait();
  
  // Drive only meaningful registers
  // Explicit Check for START (for clarity)
  // ======================================
  for (int csr_idx = 0; csr_idx < 32; csr_idx++) begin
    if (csr_idx == START_IDX_REG && req.host_regs_valid[csr_idx] == 1'b1) begin
      vif.host_regsi     [START_IDX_REG]  <= req.host_regsi[START_IDX_REG];
      vif.host_regs_valid[START_IDX_REG]  <= 1'b1;
    end else if (req.host_regs_valid[csr_idx] == 1'b1) begin
      vif.host_regsi[csr_idx]       <= req.host_regsi[csr_idx];
      vif.host_regs_valid[csr_idx]  <= 1'b1;
    end
      // No else - let the undriven maintain state (REALISTIC CPU BEHAVIOR, REDUCES UNNECESSARY CYCLES)
  end
    

  if (is_start_asserted  (req.host_regsi[START_IDX_REG] , req.host_regs_valid[START_IDX_REG]) ||
      is_calcopy_asserted(req.host_regsi[START_IDX_REG] , req.host_regs_valid[START_IDX_REG])
  ) begin
    clk_posedge_wait(); // Hold START = 1 for 1 clk cycle                       

    vif.host_regsi      [START_IDX_REG]  <= '0; // de-assert
    vif.host_regs_valid [START_IDX_REG]  <= '0;

    `honeyb("GPP Driver", "waiting for DONE status...")
      // Report
    req.set_e_mode("start");
    while(done_is_deasserted( vif.host_regso      [DONE_IDX_REG],     // Wait for DONE assertion + Sudden RST Handling
                              vif.host_regso_valid[DONE_IDX_REG]) &&  // Do this while:
                              vif.rst_n)                              clk_posedge_wait();
    `honeyb("GPP Driver", "  DONE status received, moving on!")
      // Report
  end
endtask // Start Wiggling + Report

//=========================================================
//                    HELPER METHODS
//=========================================================

  // Clock Methods
  // =============

  task xlr_gpp_driver::clk_posedge_wait(); @(posedge vif.clk); endtask
  task xlr_gpp_driver::clk_negedge_wait(); @(negedge vif.clk); endtask

  // Reset Methods
  // =============

  function logic xlr_gpp_driver::get_rst_n(); return vif.rst_n; endfunction

  task xlr_gpp_driver::pin_wig_rst();
    vif.host_regsi <= '0;
    vif.host_regs_valid <= '0;
  endtask

  task xlr_gpp_driver::rst_n_negedge_wait(); @(negedge vif.rst_n); endtask
  task xlr_gpp_driver::rst_n_posedge_wait(); @(posedge vif.rst_n); endtask
`endif // XLR_GPP_DRIVER_SV