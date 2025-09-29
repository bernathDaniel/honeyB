//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_mem_seq_lib.sv
//=============================================================================
// Description: Sequence for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_SEQ_LIB_SV
`define XLR_MEM_SEQ_LIB_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class xlr_mem_default_seq extends uvm_sequence #(xlr_mem_tx);

  `uvm_object_utils(xlr_mem_default_seq)

  extern function new(string name = "");
  extern task body();

`ifndef UVM_POST_VERSION_1_1
  // Functions to support UVM 1.2 objection API in UVM 1.1
  extern function uvm_phase get_starting_phase();
  extern function void set_starting_phase(uvm_phase phase);
`endif

endclass : xlr_mem_default_seq


function xlr_mem_default_seq::new(string name = "");
  super.new(name);
endfunction : new


task xlr_mem_default_seq::body();
  //`honeyb("MEM SEQ", "New sequence starting...")

  req = xlr_mem_tx::type_id::create("req");
  start_item(req); 
  if ( !req.randomize() )
    `uvm_error("", "Failed to randomize transaction")
  finish_item(req); 

  //`honeyb("MEM SEQ", "Sequence completed...")
endtask : body


`ifndef UVM_POST_VERSION_1_1
function uvm_phase xlr_mem_default_seq::get_starting_phase();
  return starting_phase;
endfunction: get_starting_phase


function void xlr_mem_default_seq::set_starting_phase(uvm_phase phase);
  starting_phase = phase;
endfunction: set_starting_phase
`endif

`endif // XLR_MEM_SEQ_LIB_SV

