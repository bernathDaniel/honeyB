//=============================================================================
// Project  : HoneyB V4
// File Name: xlr_mem_config.sv
//=============================================================================
// Description: Configuration for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_CONFIG_SV
`define XLR_MEM_CONFIG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;

class xlr_mem_config extends uvm_object;

  // Do not register config class with the factory

  uvm_active_passive_enum  is_active = UVM_ACTIVE;
  bit                      coverage_enable;       
  bit                      checks_enable;     

  // # of sequences for the parameterized IF
  int unsigned count; 

  // This string is used for cfg the params of the if - IMPORTANT !!
  string iface_string;    

  extern function new(string name = "");
endclass : xlr_mem_config 

function xlr_mem_config::new(string name = "");
  super.new(name);
endfunction : new

`endif // XLR_MEM_CONFIG_SV