//=============================================================================
// Project : HoneyB V7
// File Name: xlr_sram_mem.sv
//=============================================================================
// Description: UVM Memory Model for SRAM Blocks
//=============================================================================

`ifndef XLR_SRAM_MEM_SV
`define XLR_SRAM_MEM_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_sram_mem extends uvm_mem;
  `uvm_object_utils(xlr_sram_mem)  
  extern function new(string name = "", 
                      longint unsigned size = 0,
                      int unsigned n_bits = 0,
                      string access = "RW",
                      int has_coverage = UVM_NO_COVERAGE);
endclass : xlr_sram_mem

function xlr_sram_mem::new(string name = "",
                           longint unsigned size = 0,
                           int unsigned n_bits = 0,
                           string access = "RW",
                           int has_coverage = UVM_NO_COVERAGE
);  super.new(name, size, n_bits, access, has_coverage);
endfunction : new

//=============================================================================
// SRAM Memory Block - Contains multiple SRAM instances
//=============================================================================
class xlr_sram_mem_block extends uvm_reg_block;
    `uvm_object_utils(xlr_sram_mem_block)
    
    rand xlr_sram_mem sram_instances[NUM_MEMS];  // Array of SRAM memory objects
    uvm_reg_map xlr_sram_map;
    
    extern function new(string name = "");
    extern virtual function void build();
endclass : xlr_sram_mem_block

function xlr_sram_mem_block::new(string name = "");
    super.new(name, UVM_NO_COVERAGE);
endfunction : new

function void xlr_sram_mem_block::build();
  // Calculate memory parameters
  longint unsigned mem_size_lines = 1 << LOG2_LINES_PER_MEM;  // Number of lines per memory
  int unsigned mem_width_bits = 256;  // 256-bit wide memory lines
  
  // Create SRAM memory instances
  for (int i = 0; i < NUM_MEMS; i++) begin
    sram_instances[i] = xlr_sram_mem::type_id::create($sformatf("sram_instances[%0d]", i));
    sram_instances[i].configure(this, mem_size_lines, mem_width_bits, "RW", UVM_NO_COVERAGE);
    sram_instances[i].build();
  end
  
  xlr_sram_map = create_map("xlr_sram_map", 0, 32, UVM_LITTLE_ENDIAN);  // 32-byte aligned for 256-bit lines
  
  for (int i = 0; i < NUM_MEMS; i++) begin
    // Each SRAM gets 32KB address space (32*1024 bytes)
    longint unsigned base_offset = i * 32 * 1024;
    xlr_sram_map.add_submap(sram_instances[i].get_default_map(), base_offset);
  end
  default_map = xlr_sram_map;
  lock_model();
endfunction : build

`endif // XLR_SRAM_MEM_SV