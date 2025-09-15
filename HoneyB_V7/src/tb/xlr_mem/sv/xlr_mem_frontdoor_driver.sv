//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_frontdoor_driver.sv
//=============================================================================
// Description: FRONTDOOR Driver for xlr_mem
//=============================================================================

`ifndef XLR_MEM_FRONTDOOR_DRIVER_SV
`define XLR_MEM_FRONTDOOR_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;

class xlr_mem_frontdoor_driver extends xlr_mem_driver;
  `uvm_component_utils(xlr_mem_frontdoor_driver)

  uvm_blocking_transport_port#(
    xlr_mem_tx, // req
    xlr_mem_tx  // rsp
  ) model_bt;

  xlr_mem_if_base m_xlr_mem_if;

  xlr_mem_tx req; // Mem-Service TXs
  xlr_mem_tx rsp;

  bit [NUM_MEMS-1:0] rd_mems;
  bit [NUM_MEMS-1:0] wr_mems;

  extern function         new          (string name, uvm_component parent);
  extern function void    build_phase  (uvm_phase phase);
  extern task             run_phase    (uvm_phase phase);
  extern task             do_drive(); // User - Specific code for driver

  // Mem Service Helpers:
  //----------------------
    extern function void flush_all();
    extern function void create_req(int m);
    extern function void create_req_report();
endclass // Boilerplate + b_transport + Helpers


function xlr_mem_frontdoor_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction // Boilerplate


function void xlr_mem_frontdoor_driver::build_phase (uvm_phase phase);
  super.build_phase(phase);
  model_bt = new("model_bt", this);
endfunction // Boilerplate


task xlr_mem_frontdoor_driver::run_phase(uvm_phase phase);
  `honeyb("MEM Driver", "  run_phase initialized...")
  req = xlr_mem_tx::type_id::create("req"); // Factorizing
  rsp = xlr_mem_tx::type_id::create("rsp");

  // Boot Sequence
  //===============
  m_xlr_mem_if.rst_n_negedge_wait();
  m_xlr_mem_if.pin_wig_rst();
  m_xlr_mem_if.rst_n_posedge_wait();

  do_drive();
endtask // Boilerplate + Boot Seq + Report


task xlr_mem_frontdoor_driver::do_drive(); // - OK - // - FINAL - //
  forever begin
    flush_all(); // Refresh the Req TX + "*_mems" arrays

    m_xlr_mem_if.wait_for_dut_request(); // "Polling" Step

    rd_mems = m_xlr_mem_if.get_active_rd_mems(); // Active Memory
    wr_mems = m_xlr_mem_if.get_active_wr_mems(); // Identification

    for (int m = 0; m < NUM_MEMS; m++) begin
      if (rd_mems[m] || wr_mems[m]) begin
        create_req(m);
      end
    end // Req Creations Step

    model_bt.transport(req, rsp); // Req transportation Step

    for (int m = 0; m < NUM_MEMS; m++) begin
      if (rd_mems[m]) begin 
                            m_xlr_mem_if.pin_wig_rdata(x_mem'(m), rsp.mem_rdata[m]);
      end 
    end // Drive response for READ requests

    create_req_report();              // RD Valid & Mem ACK Debugging report 
    m_xlr_mem_if.clk_posedge_wait();  // Hold mem_rdata for 1 clk cycle !
  end // Compensating for missing IF signals (VAL & ACK)
endtask // Memory Service + Report

//=============================================
//            Driver Helper Methods
//=============================================

  function void xlr_mem_frontdoor_driver::flush_all(); 
    req.mem_addr = '0; req.mem_rdata = '0; req.mem_wdata = '0; req.mem_be = '0; req.mem_rd = '0; req.mem_wr = '0;
                                                                                rd_mems    = '0; wr_mems    = '0;
  endfunction // Complete flush for new incoming requests

  function void xlr_mem_frontdoor_driver::create_req(int m);
              req.mem_addr[m]  = m_xlr_mem_if.get_addr  (x_mem'(m));
              req.mem_rd[m]    = m_xlr_mem_if.get_rd    (x_mem'(m));
              req.mem_wr[m]    = m_xlr_mem_if.get_wr    (x_mem'(m));
              req.mem_wdata[m] = m_xlr_mem_if.get_wdata (x_mem'(m));
              req.mem_be[m]    = m_xlr_mem_if.get_be    (x_mem'(m));
  endfunction // Create a complete request - memory deals with it.

  function void xlr_mem_frontdoor_driver::create_req_report();
    string rd_req_report = "Read from Memories: | ";
    string wr_req_report = "Write to Memories : | ";

    bit rd_rep_ok = 1'b0; // Flags ok
    bit wr_rep_ok = 1'b0;

    for (int m = 0; m < NUM_MEMS; m++) begin
      if (rd_mems[m]) begin
        rd_rep_ok = 1'b1;
        $sformat(rd_req_report, {"%s", "MEM%0d | "}, rd_req_report, m);
      end
      if (wr_mems[m]) begin
        wr_rep_ok = 1'b1;
        $sformat(wr_req_report, {"%s", "MEM%0d | "}, wr_req_report, m);
      end
    end

    if (rd_rep_ok) `honeyb("MEM Driver", rd_req_report)
    if (wr_rep_ok) `honeyb("MEM Driver", wr_req_report)
  endfunction // Full Debug Report On all memories operations through the driver

//===============================
// Old Do_Drive() for Reference
//===============================
  /*
    m_xlr_mem_if.rd_wait_until_asserted(MEM0);
    m_xlr_mem_if.clk_negedge_wait(); // wait 1 negedge to send data
    m_xlr_mem_if.pin_wig_rdata(MEM0, req.mem_rdata[MEM0]);
    // wait until wr is enabled signaling the end of operation for DUT
    m_xlr_mem_if.wr_wait_until_asserted(MEM0);
  */
`endif // XLR_MEM_FRONTDOOR_DRIVER_SV

