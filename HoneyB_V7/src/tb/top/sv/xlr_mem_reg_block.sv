//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_reg_block.sv
//=============================================================================
// Description: Memory Block unit for xlr_mem
//=============================================================================

`ifndef XLR_MEM_REG_BLOCK_SV
`define XLR_MEM_REG_BLOCK_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_mem_reg_block extends uvm_reg_block;
  `uvm_object_utils(xlr_mem_reg_block)

  rand xlr_mem_reg lines[1 << LOG2_LINES_PER_MEM]; // Shifting creates 2^(LOG2_LINES_PER_MEM) rows
  uvm_reg_map xlr_mem_map;

  extern function new(string name = "");
  extern virtual function void build();
endclass : xlr_mem_reg_block


function xlr_mem_reg_block::new(string name ="");
  super.new(name, UVM_NO_COVERAGE);
endfunction : new


function xlr_mem_reg_block::build();
  for (int i = 0; i < (1 << LOG2_LINES_PER_MEM); i++) begin
    lines[i] = xlr_mem_reg::type_id::create($sformatf("lines[%0d]", i));
    lines[i].configure(this);
    lines[i].build();
  end
  // (NAME, BASE ADDR, TOTAL_BYTEWIDTH_PER_SRAM_BLOCK, ENDIANNESS)
  xlr_mem_map = create_map("xlr_mem_map", '0, (1 << LOG2_LINES_PER_MEM) * NUM_BYTES * BYTE_WIDTH / 8, UVM_LITTLE_ENDIAN);
  // Useful when we have a single map, it allows using methods like reg.read() without specifying map name
  default_map = xlr_mem_map;
  // Add registers to address map
  for (int i = 0; i < (1 << LOG2_LINES_PER_MEM); i++) begin
    // (LINE, OFFSET IN BYTESIZE, ACCESS)
    xlr_mem_map.add_reg(lines[i], i * NUM_BYTES * BYTE_WIDTH / 8, "RW");
  end
  lock_model(); // Locks the size and content of this register block - it's a safety so it can't be changed by accident
endfunction : build


`endif // XLR_MEM_REG_BLOCK_SV