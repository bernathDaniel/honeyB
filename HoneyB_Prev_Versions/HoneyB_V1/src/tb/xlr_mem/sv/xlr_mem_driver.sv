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


class xlr_mem_driver extends uvm_driver #(xlr_mem_tx);

  `uvm_component_utils(xlr_mem_driver)

  virtual xlr_mem_if vif;

  extern function new(string name, uvm_component parent);

  extern task run_phase(uvm_phase phase);
  extern task do_drive(); // User - Specific code for driver
endclass : xlr_mem_driver 


function xlr_mem_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


task xlr_mem_driver::run_phase(uvm_phase phase);

  // Declares that run phase starts
  `uvm_info("", "run_phase", UVM_MEDIUM)

  forever
  begin
    if (!vif.rst_n) begin
      vif.mem_rdata <= '0;
      @(posedge vif.rst_n);
      continue; // go to next interation once rst_n is deasserted.
    end

    seq_item_port.get_next_item(req);// waits for next available tx

    // Debug Statement - Tx logging of the driver
    `uvm_info("", "New seq item received in MEM Driver !", UVM_MEDIUM)

    wait (vif.rst_n == 1'b1);// waits for deassertion of rst_n
    phase.raise_objection(this);// tells the tb that this task is busy
  
    do_drive(); // User - Specific code for driver

    fork
      begin
        repeat (10) @(posedge vif.clk);
        phase.drop_objection(this);
      end
    join_none
    // Explanation for the fork above :
    // Create delay before dropping objection, this is useful to make
    // sure that the test won't be interrupted if new transaction
    // takes time, but we add "fork" to do this in parallel
    // meaning that while drop_objection is delayed, if new
    // transaction is available, the test will proceed to driving it
    
    //Notified UVM that the current transaction is done
    seq_item_port.item_done();
  end
endtask : run_phase

task xlr_mem_driver::do_drive(); // User - Specific code for driver

  // adds small delay before driving the data
  //repeat ($urandom_range(0, 1)) @(posedge vif.clk);

  // wait for DUT to send read request
  wait (vif.mem_rd == 1'b1 && vif.mem_addr[0] == 0);

  @(negedge vif.clk);
  // assign transaction to DUT interface
  vif.mem_rdata <= req.mem_rdata;

  wait (vif.mem_wr == 1'b1); // wait until wr is enabled signaling the end of operation for DUT
  // @(posedge vif.clk);
endtask : do_drive

`endif // XLR_MEM_DRIVER_SV

