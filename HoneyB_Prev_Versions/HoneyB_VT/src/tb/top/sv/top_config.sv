//=============================================================================
// Project  : HoneyB V1
// File Name: top_config.sv
//=============================================================================
// Description: Configuration for top
//=============================================================================

`ifndef TOP_CONFIG_SV
`define TOP_CONFIG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class top_config extends uvm_object;

  // Do not register config class with the factory

  rand xlr_mem_config  m_xlr_mem_config; // these variables are created as rand but the agent_cfgs don't have rand so no randomization
  // rand xlr_mem_28_config m_xlr_mem_config; // V3
  rand xlr_gpp_config  m_xlr_gpp_config;

  extern function new(string name = "");
endclass : top_config 

function top_config::new(string name = ""); // This constructor makes top_config contain the 2 agent config's.
  super.new(name);

  m_xlr_mem_config                 = new("m_xlr_mem_config"); // here we config the agents to be active, with check and cov en.
  m_xlr_mem_config.is_active       = UVM_ACTIVE;             
  m_xlr_mem_config.checks_enable   = 1;                      
  m_xlr_mem_config.coverage_enable = 0;   // disable the coverage for now               

  m_xlr_gpp_config                 = new("m_xlr_gpp_config");
  m_xlr_gpp_config.is_active       = UVM_ACTIVE;             
  m_xlr_gpp_config.checks_enable   = 1;                      
  m_xlr_gpp_config.coverage_enable = 0;   // disable the coverage for now               
endfunction : new

`endif // TOP_CONFIG_SV

