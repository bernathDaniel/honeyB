//=============================================================================
// Project  : HoneyB V7
// File Name: top_config.sv
//=============================================================================
// Description: Configuration for top
//=============================================================================

`ifndef TOP_CONFIG_SV
`define TOP_CONFIG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;


class top_config extends uvm_object;

  // Do not register config class with the factory

  rand xlr_mem_config  m_xlr_mem_config;
  rand xlr_gpp_config  m_xlr_gpp_config;
  int m_seq_count;

  extern function new(string name = "");
endclass : top_config 
                                            //==========================
function top_config::new(string name = ""); // DEFAULTS: DO NOT CHANGE!
  super.new(name);                          //==========================

  m_xlr_mem_config                    = new("m_xlr_mem_config");
  m_xlr_mem_config.mem_is_used        = 1;
  m_xlr_mem_config.rand_seed          = 0;
  m_xlr_mem_config.uninit_is_error    = 0;
  m_xlr_mem_config.enable_write_dumps = 0;
  m_xlr_mem_config.dump_directory     = "./mem_dumps/";
  m_xlr_mem_config.init_policy        = INIT_RANDOM;
  m_xlr_mem_config.uninit_policy      = UNINIT_LAST;
  m_xlr_mem_config.is_active          = UVM_ACTIVE;             
  m_xlr_mem_config.checks_enable      = 1;                      
  m_xlr_mem_config.coverage_enable    = 1;
  m_xlr_mem_config.cov_hit_thrshld    = 1;                   

  m_xlr_gpp_config                    = new("m_xlr_gpp_config");
  m_xlr_gpp_config.is_active          = UVM_ACTIVE;             
  m_xlr_gpp_config.checks_enable      = 1;                      
  m_xlr_gpp_config.coverage_enable    = 1;
  m_xlr_gpp_config.cov_hit_thrshld    = 1;
endfunction : new

`endif // TOP_CONFIG_SV