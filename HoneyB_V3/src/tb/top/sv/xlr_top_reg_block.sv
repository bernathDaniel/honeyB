//=============================================================================
// Project  : HoneyB V3
// File Name: xlr_top_reg_block.sv
//=============================================================================
// Description: TOP Block of NUM_MEMS SRAMs for xlr_mem & more
//=============================================================================

`ifndef XLR_TOP_REG_BLOCK_SV
`define XLR_TOP_REG_BLOCK_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_top_reg_block extends uvm_reg_block;
  `uvm_object_utils(xlr_top_reg_block)

  rand xlr_mem_reg_block mem_blocks[NUM_MEMS]; // In our case NUM_MEMS = 2 - 2 SRAM Blocks !
  uvm_reg_map xlr_mem_map;

  extern function new(string name = "");
  extern virtual function void build();
endclass : xlr_mem_reg_block


function xlr_top_reg_block::new(string name ="");
  super.new(name, UVM_NO_COVERAGE);
endfunction : new


function xlr_top_reg_block::build();
  for (int i = 0; i < NUM_MEMS; i++) begin
    mem_blocks[i] = xlr_mem_reg_block::type_id::create($sformatf("mem_blocks[%0d]", i));
    mem_blocks[i].configure(this);
    mem_blocks[i].build();
  end

  xlr_mem_map = create_map("xlr_mem_map", '0,  NUM_MEMS * (1 << LOG2_LINES_PER_MEM) * NUM_BYTES * BYTE_WIDTH / 8, UVM_LITTLE_ENDIAN);
  // Useful when we have a single map, it allows using methods like reg.read() without specifying map name
  default_map = xlr_mem_map;
  // Add registers to address map
  for (int i = 0; i < NUM_MEMS; i++) begin
    // (LINE, OFFSET IN BYTESIZE, ACCESS)
    xlr_mem_map.add_submap(mem_blocks[i].xlr_mem_map, i * (1 << LOG2_LINES_PER_MEM) * NUM_BYTES * BYTE_WIDTH / 8);
  end
  lock_model(); // Locks the size and content of this register block - it's a safety so it can't be changed by accident
endfunction : build
`endif // XLR_TOP_REG_BLOCK_SV