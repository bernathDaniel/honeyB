//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_mem_if.sv
//=============================================================================
// Description: Signal interface for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_IF_SV
`define XLR_MEM_IF_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
//import xlr_mem_pkg::*;

interface xlr_mem_if(
  input logic clk,
  input logic rst_n
);

  timeunit      1ns;
  timeprecision 1ps;

  // Inputs
  logic [0:0][7:0][31:0] mem_rdata;

  // Outputs
  logic [0:0][3:0] mem_addr;
  logic [0:0][7:0][31:0] mem_wdata;
  logic [0:0][31:0] mem_be;
  logic [0:0] mem_rd;
  logic [0:0] mem_wr;
endinterface : xlr_mem_if

// Extras :

/* clocking mem_cb @(posedge clk);
  default input #1step output #1step;
  input  xlr_mem_addr;
  input  xlr_mem_wdata;
  input  xlr_mem_be;
  input  xlr_mem_rd;
  input  xlr_mem_wr;
  output xlr_mem_rdata;
endclocking */

`endif // XLR_MEM_IF_SV