//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_sequencer.sv
//=============================================================================
// Description: Sequencer for xlr_mem_seq
//=============================================================================

`ifndef XLR_MEM_SEQUENCER_SV
`define XLR_MEM_SEQUENCER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

// Sequencer
typedef uvm_sequencer #(xlr_mem_tx) xlr_mem_sequencer_t;

`endif // XLR_MEM_SEQUENCER_SV