//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_driver.sv
//=============================================================================
// Description: Driver for xlr_mem
//=============================================================================

`ifndef XLR_MEM_DRIVER_SV
`define XLR_MEM_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;


class xlr_mem_driver extends uvm_driver #(xlr_mem_tx);
  `uvm_component_utils(xlr_mem_driver)

  xlr_mem_pkg::xlr_mem_if_base m_xlr_mem_if;

  bit [NUM_MEMS-1:0] rd_mems;

  extern function new(string name, uvm_component parent);

  extern task run_phase(uvm_phase phase);
  extern task do_drive(); // User - Specific code for driver

  // Mem Driver Helpers:
  //----------------------
    extern function void flush_all();
    extern function void create_rd_req_report();
endclass : xlr_mem_driver 



function xlr_mem_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task xlr_mem_driver::run_phase(uvm_phase phase);
  `honeyb("MEM Driver", "  run_phase initialized...")
    // Report

  // Boot Sequence
  //===============
    m_xlr_mem_if.rst_n_negedge_wait();
    m_xlr_mem_if.pin_wig_rst();
    m_xlr_mem_if.rst_n_posedge_wait();
  //--------------------------------------------
  forever begin
    seq_item_port.get_next_item(req);
    
    `honeyb("MEM Driver", "New seq item received. driving...")
      // Report
    phase.raise_objection(this);
    do_drive();

    fork // drop delay
      begin // avoiding accidental early terminate
        repeat (10) m_xlr_mem_if.clk_posedge_wait();
        phase.drop_objection(this);
      end
    join_none
    seq_item_port.item_done();
  end
endtask : run_phase

task xlr_mem_driver::do_drive();
  m_xlr_mem_if.wait_for_dut_rd_request(); // DUT "Polling"

  rd_mems = m_xlr_mem_if.get_active_rd_mems();
  for (int m = 0; m < NUM_MEMS; m++) begin
      if (rd_mems[m]) begin 
                            m_xlr_mem_if.pin_wig_rdata(x_mem'(m), req.mem_rdata[m]);
      end 
  end // Drive req for READ requests

  create_rd_req_report();           // Useful for debugging
  m_xlr_mem_if.clk_posedge_wait();  // Hold mem_rdata 1 clk
endtask : do_drive

//=============================================
//            Driver Helper Methods
//=============================================

  function void xlr_mem_driver::flush_all(); 
    req.mem_addr = '0; req.mem_rdata = '0; req.mem_wdata = '0; req.mem_be = '0; req.mem_rd = '0; req.mem_wr = '0;
                                                                                rd_mems    = '0;
  endfunction // Complete flush for new incoming requests

  function void xlr_mem_driver::create_rd_req_report();
    string rd_req_report = "Read from | ";

    bit rd_rep_ok = 1'b0; // Flags ok

    for (int m = 0; m < NUM_MEMS; m++) begin
      if (rd_mems[m]) begin
        rd_rep_ok = 1'b1;
        $sformat(rd_req_report, {"%s", "MEM%0d | "}, rd_req_report, m);
      end
    end
    if (rd_rep_ok) `honeyb("MEM Driver", rd_req_report)
  endfunction // Full Debug Report On all memories operations through the driver

`endif // XLR_MEM_DRIVER_SV

