//=============================================================================
// Project  : HoneyB V7
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

  //=======================================================
  // Declarations (Parameters & Strings)
  //=======================================================
  bit                     mem_is_used;
  int unsigned            rand_seed;                    // INIT_RANDOM - Keep same random values (Easy Debug Mode)

  // Memory Debug:
  bit                     enable_write_dumps;
  int                     sim_dump_limit;               // Limit # of snapshots to avoid overdumping
  string                  dump_directory;

  // globals;
  mem_init_policy         init_policy;             
  mem_uninit_read_policy  uninit_policy;

  // per-mem overrides
  mem_init_policy         init_policy_per_mem [int]; 
  mem_uninit_read_policy  uninit_policy_by_mem[int];
  string                  init_file_per_mem   [int];

  // Used for cfg the if params - IMPORTANT
  string iface_string;

  // Do not register config class with the factory
  uvm_active_passive_enum  is_active = UVM_ACTIVE;
  bit                      coverage_enable;
  int                      cov_hit_thrshld;        
  bit                      checks_enable;


  extern function new(string name = "");
endclass : xlr_mem_config 

function xlr_mem_config::new(string name = "");
  super.new(name);
endfunction : new

`endif // XLR_MEM_CONFIG_SV