//=============================================================================
// Project  : HoneyB V3
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

    virtual xlr_mem_if vif; // old if
    xlr_mem_pkg::xlr_mem_if_base m_xlr_mem_if; // new if

    extern function new(string name, uvm_component parent);

    extern task run_phase(uvm_phase phase);
    extern task do_drive(); // User - Specific code for driver
endclass : xlr_mem_driver 


function xlr_mem_driver::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction : new


task xlr_mem_driver::run_phase(uvm_phase phase);

  // Declares that run phase starts
  `honeyb("MEM Driver", "run_phase initialized...")

  forever
  begin
    if (!m_xlr_mem_if.get_rst()) begin
        m_xlr_mem_if.rd(MEM0, '0);
        m_xlr_mem_if.wait4rst_n(); // DO NOT CHANGE IT'S CRUCIAL TO USE IT HERE
        continue; // cont. once rst_n is deasserted.
    end

    seq_item_port.get_next_item(req);// pulls next available tx

    `honeyb("MEM Driver", "New seq item received. driving...")
    wait (m_xlr_mem_if.get_rst() == 1'b1);
    phase.raise_objection(this);// tells the tb that it's busy
    do_drive(); // User - Specific code for driver

    fork
        begin
            repeat (10) m_xlr_mem_if.posedge_clk();
            phase.drop_objection(this);
        end
    join_none
    
    seq_item_port.item_done(); // current tx is done
  end
endtask : run_phase

task xlr_mem_driver::do_drive(); // User - Specific code for driver

    m_xlr_mem_if.wait4rd_req(MEM0); // NEW
    m_xlr_mem_if.negedge_clk(); // wait 1 negedge to send data
    m_xlr_mem_if.rd(MEM0, req.mem_rdata[MEM0]); // assign req into DUT's if
    m_xlr_mem_if.wait4wr_req(MEM0); // wait until wr is enabled signaling the end of operation for DUT
endtask : do_drive

`endif // XLR_MEM_DRIVER_SV

