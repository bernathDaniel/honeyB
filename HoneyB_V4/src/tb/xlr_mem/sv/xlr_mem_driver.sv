//=============================================================================
// Project  : HoneyB V4
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

  extern function new(string name, uvm_component parent);

  extern task run_phase(uvm_phase phase);
  extern task do_drive(); // User - Specific code for driver
endclass : xlr_mem_driver 


function xlr_mem_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task xlr_mem_driver::run_phase(uvm_phase phase);

  // Report Statement
  `honeyb("MEM Driver", "run_phase initialized...")

  forever begin
    if (!m_xlr_mem_if.get_rst_n()) begin
      m_xlr_mem_if.pin_wig_rst();
      m_xlr_mem_if.rst_n_posedge_wait(); // DO NOT CHANGE
      continue;
    end

    seq_item_port.get_next_item(req);

    // Report Statement
    `honeyb("MEM Driver", "New seq item received. driving...")
    m_xlr_mem_if.rst_n_wait_until_deassert();
    phase.raise_objection(this);
    do_drive();

    fork // drop delay - avoiding accidental early terminate
      begin
        repeat (10) m_xlr_mem_if.clk_posedge_wait();
        phase.drop_objection(this);
      end
    join_none
    
    seq_item_port.item_done();
  end
endtask : run_phase

task xlr_mem_driver::do_drive(); // User - Specific code for driver

  m_xlr_mem_if.rd_wait_until_asserted(MEM0);

  m_xlr_mem_if.clk_negedge_wait(); // wait 1 negedge to send data

  m_xlr_mem_if.pin_wig_rdata(MEM0, req.mem_rdata[MEM0]);
  
  // wait until wr is enabled signaling the end of operation for DUT
  m_xlr_mem_if.wr_wait_until_asserted(MEM0);

endtask : do_drive

`endif // XLR_MEM_DRIVER_SV

