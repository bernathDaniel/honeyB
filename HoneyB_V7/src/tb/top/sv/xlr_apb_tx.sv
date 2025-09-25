//=============================================================================
// Project    : HoneyB V7
// File Name  : xlr_apb_tx.sv
//=============================================================================
// Description: Sequence item for CPU-XBOX Communication Protocol
//=============================================================================

`ifndef XLR_APB_TX_SV
`define XLR_APB_TX_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_apb_tx extends uvm_sequence_item; 

  `uvm_object_utils(xlr_apb_tx)

  // APB PROTOCOL:
  rand bit cmd;           // 0 - READ  | 1 - WRITE
  rand bit cmd_valid;     // 1 - VALID | 0 - IDLE
  rand logic [31:0] addr; // CPU always provides this
  rand logic [31:0] data; // bidirectional data

  constraint c_apb_cmd_valid {
    cmd_valid == 1'b1;
  }

  extern function new(string name = "");
  extern function void    do_copy   (uvm_object rhs);
  extern function bit     do_compare(uvm_object rhs, uvm_comparer comparer);
  extern function void    do_print  (uvm_printer printer);
  extern function void    do_record (uvm_recorder recorder);
  extern function void    do_pack   (uvm_packer packer);
  extern function void    do_unpack (uvm_packer packer);
  extern function string  convert2string();
endclass : xlr_apb_tx

function xlr_apb_tx::new(string name = "");
  super.new(name);
endfunction : new


function void xlr_apb_tx::do_copy(uvm_object rhs);
  xlr_apb_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  super.do_copy(rhs);
  cmd  = rhs_.cmd; 
  addr = rhs_.addr;
  data = rhs_.data;
endfunction : do_copy


function bit xlr_apb_tx::do_compare(uvm_object rhs, uvm_comparer comparer);
  bit result;
  xlr_apb_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  result = super.do_compare(rhs, comparer);
  result &= comparer.compare_field("cmd", cmd,   rhs_.cmd,  $bits(cmd));
  result &= comparer.compare_field("addr", addr, rhs_.addr, $bits(addr));
  result &= comparer.compare_field("data", data, rhs_.data, $bits(data));
  return result;
endfunction : do_compare


function void xlr_apb_tx::do_print(uvm_printer printer);
  if (printer.knobs.sprint == 0)
    `uvm_info(get_type_name(), convert2string(), UVM_MEDIUM)
  else
    printer.m_string = convert2string();
endfunction : do_print


function void xlr_apb_tx::do_record(uvm_recorder recorder);
  super.do_record(recorder);
  `uvm_record_field("cmd",  cmd) 
  `uvm_record_field("addr", addr)
  `uvm_record_field("data", data)
endfunction : do_record


function void xlr_apb_tx::do_pack(uvm_packer packer);
  super.do_pack(packer);
  `uvm_pack_int(cmd)  
  `uvm_pack_int(addr) 
  `uvm_pack_int(data) 
endfunction : do_pack


function void xlr_apb_tx::do_unpack(uvm_packer packer);
  super.do_unpack(packer);
  `uvm_unpack_int(cmd)  
  `uvm_unpack_int(addr) 
  `uvm_unpack_int(data) 
endfunction : do_unpack


function string xlr_apb_tx::convert2string();
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {"%s\n",
    "cmd  = 'h%0h  'd%0d\n", 
    "addr = 'h%0h  'd%0d\n", 
    "data = 'h%0h  'd%0d\n"},
    get_full_name(), cmd, cmd, addr, addr, data, data);
  return s;
endfunction : convert2string