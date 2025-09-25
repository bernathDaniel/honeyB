//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_gpp_reg_block.sv
//=============================================================================
/* Description: Memory Block unit for xlr_gpp
    Create_Map Config:
     Syntax: create_map(NAME, BASE ADDR, TOTAL_BYTEWIDTH_PER_REG, ENDIANNESS);
  
    Default Map:
     Useful when we have a single map, creates cleaner code for access:
     allows using methods like gpr.read() without specifying map name
  
    add_reg for the Map:
     Syntax: add_reg(LINE, OFFSET IN BYTESIZE, ACCESS);
  
    Lock Model:
     Locks the size and content of this register block -
     it's a safety so it can't be changed by accident
    */
//=============================================================================

`ifndef XLR_GPP_REG_BLOCK_SV
`define XLR_GPP_REG_BLOCK_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_gpp_reg_block extends uvm_reg_block;
  `uvm_object_utils(xlr_gpp_reg_block)
  rand xlr_gpp_reg gpr[32]; // 32 GPR Instances
  uvm_reg_map xlr_gpp_map;
  extern function new(string name = "");
  extern virtual function void build();
endclass : xlr_gpp_reg_block

function xlr_gpp_reg_block::new(string name ="");
  super.new(name, UVM_NO_COVERAGE);
endfunction : new

function xlr_gpp_reg_block::build();
  for (int i = 0; i < 32; i++) begin
    gpr[i] = xlr_gpp_reg::type_id::create($sformatf("gpr[%0d]", i));
    gpr[i].configure(this);
    gpr[i].build();
  end
  xlr_gpp_map = create_map("xlr_gpp_map", '0, 4, UVM_LITTLE_ENDIAN);
  default_map = xlr_gpp_map;
  for (int i = 0; i < 32; i++) begin
    xlr_gpp_map.add_reg(gpr[i], i * 4, "RW");
  end
  lock_model();
endfunction : build
`endif // XLR_GPP_REG_BLOCK_SV