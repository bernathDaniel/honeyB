//=============================================================================
// Project  : HoneyB V3
// File Name: xlr_mem_reg.sv
//=============================================================================
/* Description: Address Line of 256 bits for xlr_mem
   Parameters: NUM_WORDS, DATA_WIDTH can be cfg'd from honeyb pkg
   Configuration:
   Syntax: (SIZE, LSB, ACCESS, VOLATILE, RESET, HASRESET, RAND, ACCESSIBLE)
   Explanation:
        Size - Size of each uvm_reg_field, 32-bit per word
        LSB - where the LSB starts from (i * 32)
        ACCESS - "RW" means we can read and write to those fields
        VOLATILE - '1' means that these fields can be accessed not only by TB
        RESET - If reset is asserted, what is the value ? (32'h0)
        HASRESET - Straightforward
        RAND - Can those fields be randomized ? (Yes, we need them to be)
        ACCESSIBLE - Can those fields be accessed by the TB? yes we need that
      */
//=============================================================================

`ifndef XLR_MEM_REG_SV
`define XLR_MEM_REG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_mem_reg extends uvm_reg;
  `uvm_object_utils(xlr_mem_reg)

  // The uvm_reg_field objects are subfields within the 256-bit register, each subfield has a 32-bit width
  rand uvm_reg_field bytes[NUM_BYTES]; // Array of 32 fields for byte-level granularity

  extern function new(string name = "");
  extern virtual function void build();
endclass : xlr_mem_reg


function xlr_mem_reg::new(string name = "");
  super.new(name, 256, UVM_NO_COVERAGE); // Total Addr width = 256 bits, 32 bytes of 8 bits each !
endfunction : new


/*  the build() method is similar to the build_phase() method but it's not a part of the
    uvm phases, it's just a simple build() method of xlr_mem_reg*/

function void xlr_mem_reg::build();
  for (int i = 0; i < NUM_BYTES; i++) begin
    bytes[i] = uvm_reg_field::type_id::create($sformatf("bytes[%0d]", i)); // Unique name for each field / byte

    // (SIZE, LSB, ACCESS, VOLATILE, RESET, HASRESET, RAND, ACCESSIBLE)
    bytes[i].configure(this, BYTE_WIDTH, i*BYTE_WIDTH, "RW", 1, 8'h0, 1, 1, 1);
  end
endfunction : build

`endif // XLR_MEM_REG_SV