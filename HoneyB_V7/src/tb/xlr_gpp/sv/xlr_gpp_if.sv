//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_gpp_if.sv
//=============================================================================
// Description: Signal interface for agent xlr_gpp
//=============================================================================

`ifndef XLR_GPP_IF_SV
`define XLR_GPP_IF_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_gpp_pkg::*;

interface xlr_gpp_if(
  input logic clk,
  input logic rst_n
);

  timeunit      1ns;
  timeprecision 1ps;

  logic [31:0][31:0]  host_regsi;
  logic [31:0]        host_regs_valid;
  logic [31:0][31:0]  host_regso;
  logic [31:0]        host_regso_valid;
endinterface : xlr_gpp_if

`endif // XLR_GPP_IF_SV

