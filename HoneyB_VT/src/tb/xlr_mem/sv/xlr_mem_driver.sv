//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_mem_driver.sv
//=============================================================================
// Description: Driver for xlr_mem
//=============================================================================

`ifndef XLR_MEM_DRIVER_SV
`define XLR_MEM_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
//import xlr_mem_pkg::*;
import honeyb_pkg::*;

class xlr_mem_driver extends uvm_driver #(xlr_mem_tx);

  `uvm_component_utils(xlr_mem_driver)

  // virtual xlr_mem_if vif; // old if
  xlr_mem_pkg::xlr_mem_if_base m_xlr_mem_if; // new if

  //logic rst_now; // used as an output signal for the ABC methods, 
                   // needed for if-else statements if get_rst_n() is implemented as a "task" :
                   // i.e. " task get_rst_n(output logic o_rst_n); o_rst_n = rst_n; endtask "

  extern function new(string name, uvm_component parent);

  extern task run_phase(uvm_phase phase);
  extern task do_drive(); // User - Specific code for driver
endclass : xlr_mem_driver 


function xlr_mem_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task xlr_mem_driver::run_phase(uvm_phase phase);

  // Declares that run phase starts
  `honeyb("[MEM] Driver", "Starting Run Phase...")

  forever
  begin
    // if (!vif.rst_n) begin // Old
    if (m_xlr_mem_if.get_rst_n() == 1'b0) begin // New

      // vif.mem_rdata <= '0; // old
      m_xlr_mem_if.rst_pin_wig(); // new - Note that "*.pin_wig([7:0][31:0] mem_rdata, mem_idx)" are the args.

      // @(posedge vif.rst_n); // old
      m_xlr_mem_if.rst_n_wait_posedge(); // new
      continue; // go to next interation once rst_n is deasserted.
    end

    seq_item_port.get_next_item(req);// waits for next available tx

    // Debug Statement - Tx logging of the driver
    `honeyb("MEM Driver", "New seq item received, Driving...")

    // wait (vif.rst_n == 1'b1); // old || waits for deassertion of rst_n
    m_xlr_mem_if.rst_n_wait_until_deassert(); // new || waits for rst_n == 1'b1 || DIFFERENT THAN @(posedge rst_n)!!!
    phase.raise_objection(this);// tells the tb that this task is busy
  
    do_drive(); // User - Specific code for driver

    fork
      begin
        // repeat (10) @(posedge vif.clk); // old
        repeat (10) m_xlr_mem_if.clk_wait_posedge(); // new
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

  /* adds small delay before driving the data
    // repeat ($urandom_range(0, 1)) @(posedge vif.clk);*/

  // wait for DUT to send read request
  // wait (vif.mem_rd == 1'b1 && vif.mem_addr[0] == 0); // old
  m_xlr_mem_if.rd_wait_until_asserted(0); // mem_idx = 0

  // @(negedge vif.clk); // old
  m_xlr_mem_if.clk_wait_negedge();// new

  // assign transaction to DUT interface
  // vif.mem_rdata <= req.mem_rdata; // old
  m_xlr_mem_if.pin_wig(req.mem_rdata[0], 0); // new, currently we're assuming that only mem_rdata[0] is being used.

  // wait (vif.mem_wr == 1'b1); // old || wait until wr is enabled signaling the end of operation for DUT
  m_xlr_mem_if.wr_wait_until_asserted(0); // new || mem_idx = 0
  // @(posedge vif.clk); might need to delete idk..
endtask : do_drive

`endif // XLR_MEM_DRIVER_SV

