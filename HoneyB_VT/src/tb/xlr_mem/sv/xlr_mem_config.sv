//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_mem_config.sv
//=============================================================================
// Description: Configuration for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_CONFIG_SV
`define XLR_MEM_CONFIG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import xlr_mem_pkg::*;
import honeyb_pkg::*;

class xlr_mem_config extends uvm_object;

  // Do not register config class with the factory

  virtual xlr_mem_if       vif;
                  
  uvm_active_passive_enum  is_active = UVM_ACTIVE;
  bit                      coverage_enable;       
  bit                      checks_enable;         

  int unsigned count; // # of sequences for the parameterized IF
  string iface_string; // This string is used for cfg the params of the if

  extern function new(string name = "");
endclass : xlr_mem_config 

function xlr_mem_config::new(string name = "");
  super.new(name);
endfunction : new

`endif // XLR_MEM_CONFIG_SV

