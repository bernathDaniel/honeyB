//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_gpp_config.sv
//=============================================================================
// Description: Configuration for agent xlr_gpp
//=============================================================================

`ifndef XLR_GPP_CONFIG_SV
`define XLR_GPP_CONFIG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_gpp_pkg::*;

class xlr_gpp_config extends uvm_object;

  // Do not register config class with the factory

  virtual xlr_gpp_if       vif;
                  
  uvm_active_passive_enum  is_active = UVM_ACTIVE;
  bit                      coverage_enable;
  int                      cov_hit_thrshld;       
  bit                      checks_enable;
  bit                      calcopy_enable;

  extern function new(string name = "");
endclass : xlr_gpp_config 

function xlr_gpp_config::new(string name = "");
  super.new(name);
endfunction : new

`endif // XLR_GPP_CONFIG_SV

