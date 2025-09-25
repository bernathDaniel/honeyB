//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_gpp_reg.sv
//=============================================================================
/* Description: Address lines of 32-bits for xlr_gpp
   Configuration:
   Syntax: configure(SIZE, LSB, ACCESS, VOLATILE, RESET, HASRESET, RAND, ACCESSIBLE)
   Explanation:
        Parent - this
        Size - Size of each uvm_reg_field
        LSB - where the LSB starts from (i * 32)
        ACCESS - "RW" means we can read and write to those fields
        VOLATILE - '1' means that these fields can be accessed not only by TB
        RESET - If reset is asserted, what is the value ? (32'h0)
        HASRESET - Straightforward
        RAND - Can those fields be randomized ? (Yes, we need them to be)
        ACCESSIBLE - Can those fields be accessed by the TB? yes we need that
      */
//=============================================================================

`ifndef XLR_GPP_REG_SV
`define XLR_GPP_REG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_gpp_reg extends uvm_reg;
  `uvm_object_utils(xlr_gpp_reg)
  rand uvm_reg_field value;// a 32-bit register field
  extern function new(string name = "");
  extern virtual function void build();
endclass : xlr_gpp_reg

function xlr_gpp_reg::new(string name = "");
  super.new(name, 32, UVM_NO_COVERAGE); // Value width = 32-bits as an atomic value
endfunction : new

/*  the build() method is similar to the build_phase() method but it's not a part of the
    uvm phases, it's just a simple build() method of xlr_gpp_reg*/
function void xlr_gpp_reg::build();
    value = uvm_reg_field::type_id::create("value");
    value.configure(this, 32, 0, "RW", 1, 32'h0, 1, 1, 1);
endfunction : build
`endif // XLR_GPP_REG_SV