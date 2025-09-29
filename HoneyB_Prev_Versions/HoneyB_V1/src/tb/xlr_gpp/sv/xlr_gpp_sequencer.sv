//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_gpp_sequencer.sv
//=============================================================================
// Description: Sequencer for xlr_gpp
//=============================================================================

`ifndef XLR_GPP_SEQUENCER_SV
`define XLR_GPP_SEQUENCER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


// Sequencer class is specialization of uvm_sequencer
typedef uvm_sequencer #(xlr_gpp_tx) xlr_gpp_sequencer_t;

`endif // XLR_GPP_SEQUENCER_SV

