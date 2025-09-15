//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_gpp_seq_lib.sv
//=============================================================================
// Description: Sequence for agent xlr_gpp
//=============================================================================

`ifndef XLR_GPP_SEQ_LIB_SV
`define XLR_GPP_SEQ_LIB_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class xlr_gpp_default_seq extends uvm_sequence #(xlr_gpp_tx);

  `uvm_object_utils(xlr_gpp_default_seq)

  xlr_gpp_config m_xlr_gpp_config;

  extern function new(string name = "");
  extern task body();

`ifndef UVM_POST_VERSION_1_1
  // Functions to support UVM 1.2 objection API in UVM 1.1
  extern function uvm_phase get_starting_phase();
  extern function void set_starting_phase(uvm_phase phase);
`endif
endclass : xlr_gpp_default_seq

function xlr_gpp_default_seq::new(string name = "");
  super.new(name);
endfunction : new



task xlr_gpp_default_seq::body();

  if ( !uvm_config_db#(xlr_gpp_config)::get(get_sequencer(), "", "config", m_xlr_gpp_config) )
      `uvm_error(get_type_name(), "Failed to get config object")

  if (m_xlr_gpp_config.calcopy_enable == 1'b1) begin
    `honeyb("GPP Sequence", "New sequence starting...", " [CALCOPY]")

    req = xlr_gpp_tx::type_id::create("req");
    start_item(req); 
    if ( !req.randomize() )
      `uvm_error("", "Failed to randomize transaction")

    req.host_regsi[START_IDX_REG] = 32'h2;      // CALCOPY
    req.host_regs_valid[START_IDX_REG] = 32'h1; // CALCOPY = VALID

    finish_item(req); 

    `honeyb("GPP Sequence", "Sequence completed! ", " [CALCOPY]")

  end else begin

    `honeyb("GPP Sequence", "New sequence starting...", "[MATMUL]")
      $display(); // CLI
    req = xlr_gpp_tx::type_id::create("req");
    start_item(req); 
    if ( !req.randomize() )
      `uvm_error("", "Failed to randomize transaction")
    finish_item(req);
    `honeyb("GPP Sequence", "Sequence completed! ", "[MATMUL]")
      // Report
  end
endtask : body


`ifndef UVM_POST_VERSION_1_1
function uvm_phase xlr_gpp_default_seq::get_starting_phase();
  return starting_phase;
endfunction // Boilerplate

function void xlr_gpp_default_seq::set_starting_phase(uvm_phase phase);
  starting_phase = phase;
endfunction // Boilerplate
`endif
`endif // XLR_GPP_SEQ_LIB_SV

