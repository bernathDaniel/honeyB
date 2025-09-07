//=============================================================================
// Project  : HoneyB V2
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
    // if (!vif.rst_n) begin // Old
    if (!m_xlr_mem_if.get_rst()) begin // new

        // vif.mem_rdata <= '0; // old
        m_xlr_mem_if.rd(MEM0, '0); // new

        // @(posedge vif.rst_n); // old
        m_xlr_mem_if.wait4rst_n();// new - DO NOT CHANGE IT'S CRUCIAL TO USE IT HERE
        continue; // go to next interation once rst_n is deasserted.
    end

    seq_item_port.get_next_item(req);// waits for next available tx

    // Debug Statement - Tx logging of the driver
    `honeyb("MEM Driver", "New seq item received. driving...")
    // wait (vif.rst_n == 1'b1); // old || waits for deassertion of rst_n
    wait (m_xlr_mem_if.get_rst() == 1'b1);
    phase.raise_objection(this);// tells the tb that this task is busy
    do_drive(); // User - Specific code for driver

    fork
        begin
            // repeat (10) @(posedge vif.clk); // old
            repeat (10) m_xlr_mem_if.posedge_clk(); // new
            // repeat (10) @(posedge m_xlr_mem_if.get_clk())
            phase.drop_objection(this);
        end
    join_none
    
    /* Explanation for the fork above :
        || Create delay before dropping objection, this is useful to make
        || sure that the test won't be interrupted if new transaction
        || takes time, but we add "fork" to do this in parallel
        || meaning that while drop_objection is delayed, if new
        || transaction is available, the test will proceed to driving it*/
    
    //Notified UVM that the current transaction is done
    seq_item_port.item_done();
  end
endtask : run_phase

task xlr_mem_driver::do_drive(); // User - Specific code for driver

    /*  wait for DUT to send read request (OLD)
        wait (vif.mem_rd == 1'b1 && vif.mem_addr[0] == 0); // old
        // @(negedge vif.clk); // old*/
    m_xlr_mem_if.wait4rd_req(MEM0); // NEW
    m_xlr_mem_if.negedge_clk(); // wait 1 negedge to send data
    /*  assign transaction to DUT interface (OLD)
        vif.mem_rdata <= req.mem_rdata; */
    m_xlr_mem_if.rd(MEM0, req.mem_rdata[MEM0]); // new

    // wait (vif.mem_wr == 1'b1); // old || wait until wr is enabled signaling the end of operation for DUT
    m_xlr_mem_if.wait4wr_req(MEM0); // new ||  wait until wr is enabled signaling the end of operation for DUT
endtask : do_drive

`endif // XLR_MEM_DRIVER_SV

