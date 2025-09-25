//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_top_reg_block.sv
//=============================================================================
// Description: TOP Block of UVM RAL
//=============================================================================

`ifndef XLR_TOP_REG_BLOCK_SV
`define XLR_TOP_REG_BLOCK_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_top_reg_block extends uvm_reg_block;
  `uvm_object_utils(xlr_top_reg_block)
  uvm_reg_map xlr_xbox_root_map;
  rand xlr_gpp_reg_block gpr_block;
  rand xlr_sram_mem_block sram_block;
  extern function new(string name = "");
  extern virtual function void build();
endclass : xlr_top_reg_block

function xlr_top_reg_block::new(string name ="");
  super.new(name, UVM_NO_COVERAGE);
endfunction : new

function xlr_top_reg_block::build();  
 //=============================================================== Root map to hold all submaps
  xlr_xbox_root_map = create_map("xlr_xbox_root_map", 0 , 4, UVM_LITTLE_ENDIAN);
  default_map = xlr_xbox_root_map;
 //=============================================================== GPR Block
  gpr_block = xlr_gpp_reg_block::type_id::create("gpr_block");
  gpr_block.configure(this);
  gpr_block.build(); //                  GPR MAP,     BASE_ADDR
  xlr_xbox_root_map.add_submap(gpr_block.xlr_gpp_map, 'h1A400000);
 //=============================================================== MEM Block Farm (Up to 8)
  sram_block = xlr_sram_mem_block::type_id::create("sram_block");
  sram_block.configure(this);
  sram_block.build();
  xlr_xbox_root_map.add_submap(sram_block.xlr_sram_map, 'h1A480000);
 //===============================================================
  lock_model(); // Locks the size and content of this register block - it's a safety so it can't be changed by accident
endfunction : build
`endif // XLR_TOP_REG_BLOCK_SV