//=============================================================================
// Project  : HoneyB V7
// File Name: top_test.sv
//=============================================================================
// Description: Test class for top, cfg db control center
//=============================================================================

`ifndef TOP_TEST_SV
`define TOP_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;


class top_test extends uvm_test;

  `uvm_component_utils(top_test)

  top_env m_env;

  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
endclass : top_test

function top_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

function void top_test::build_phase(uvm_phase phase);
  top_config m_config;
  if (!uvm_config_db #(top_config)::get(this, "", "config", m_config))
    `uvm_error(get_type_name(), "Unable to get top_config")

  
  // Strings to uniquely identify instances of parameterized interface. Used by factory overrides.
  m_config.m_xlr_mem_config.iface_string = "xlr_mem_if_2_8";
  xlr_mem_default_seq::type_id::set_type_override(xlr_mem_seq::get_type()); // Overriding the default seq with a custom one.
  
  // === Optional per-mem overrides (uncomment as needed) =======================

  // UNCOMMENT IF MEM IS NOT USED
  xlr_mem_driver::type_id::set_inst_override(xlr_mem_frontdoor_driver::get_type(),
  "m_env.m_xlr_mem_agent.m_driver", this);

  // m_config.m_xlr_mem_config.mem_is_used              = 1; // Turn off with 0
  // m_config.m_xlr_mem_config.rand_seed                = 1; // Debugger: Enable Reproducible Randomization
  // m_config.m_xlr_mem_config.enable_write_dumps       = 1; // Debugger: Enable Write Dumps

  // MEM 0: preload from file
  // m_config.m_xlr_mem_config.init_policy_per_mem[0]   = INIT_FILE;
  // m_config.m_xlr_mem_config.init_file_per_mem[0]     = "mem0.hex";

  // MEM 1: start empty; treat uninit reads as zeros
  // m_config.m_xlr_mem_config.init_policy_per_mem[1]   = INIT_NONE;
  // m_config.m_xlr_mem_config.uninit_policy_by_mem[1]  = UNINIT_ZERO;

  // MEM 2: force random init (even if global isn?t random)
  // m_config.m_xlr_mem_config.init_policy_per_mem[2]   = INIT_RANDOM;


  // Optional: escalate uninit reads to ERROR instead of WARN
  // m_config.m_xlr_mem_config.uninit_is_error          = 1;
  
  
  m_env = top_env::type_id::create("m_env", this);
endfunction : build_phase

`endif // TOP_TEST_SV

