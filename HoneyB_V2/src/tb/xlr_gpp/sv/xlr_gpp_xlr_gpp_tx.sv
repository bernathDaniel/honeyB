//=============================================================================
// Project  : HoneyB V2
// File Name: xlr_gpp_seq_item.sv
//=============================================================================
// Description: Sequence item for xlr_gpp_sequencer
//
//              This tx class contains the following special methods:
//              print(), copy(), compare(), record(), unpack(), pack()
//
//              Another cool feature is "mode select" :
//              Mode Select allows you to choose which outputs to
//              apply the method to.
//
//              how to use mode select :
//                             tx.set_mode("<chosen_mode>");
//                             tx.print(); (example for using print method)
//
//              possible modes :
//                            | all || in || out || busy || done |
//=============================================================================

`ifndef XLR_GPP_SEQ_ITEM_SV
`define XLR_GPP_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_gpp_tx extends uvm_sequence_item; 

  `uvm_object_utils(xlr_gpp_tx)

  string mode = "all"; // default mode is all (can be all / in / out / start / busy / done)

  // Transaction variables
  rand logic [31:0][31:0] host_regsi;
  rand logic [31:0] host_regs_valid;
  logic [31:0][31:0] host_regso;
  logic [31:0] host_regso_valid;
  
  constraint c_gpp_data {
    host_regsi[0] == 32'h1;
  }

  constraint c_gpp_nullr { 
    foreach (host_regsi[i])
      if ( i >= 1 && i <= 31 )
        host_regsi[i] == 32'h0;
  }

  constraint c_gpp_valid_data {
    host_regs_valid == 32'h1;
  }

  /*constraint c_gpp_valid_null { // this is unnecessary
    host_regs_valid[31:1] inside 31'd0;
  }
  constraint c_gpp_valid_data_dist { host_regs_valid[0] dist {1'b0 := 1, 1'b1 := 5}; host_regsi[0][0] dist {1'b0 := 1, 1'b1 := 5}; }
  */


  extern function new(string name = "");

  extern function void set_mode(string s);
  extern function void do_copy(uvm_object rhs);
  extern function bit  do_compare(uvm_object rhs, uvm_comparer comparer);
  extern function void do_print(uvm_printer printer);
  extern function void do_record(uvm_recorder recorder);
  extern function void do_pack(uvm_packer packer);
  extern function void do_unpack(uvm_packer packer);
  extern function string convert2string();
  extern function string convert2string_in();
  extern function string convert2string_out();
  extern function string convert2string_start();
  extern function string convert2string_busy();
  extern function string convert2string_done();
endclass : xlr_gpp_tx 


function xlr_gpp_tx::new(string name = "");
  super.new(name);
endfunction : new


function void xlr_gpp_tx::set_mode(string s); // a simple function to set the io mode for printing / copying etc.
  mode = s;
  // `honeyb("GPP TX", $sformatf("Setting mode to: %s...", s)) // Optional || Comment out to reduce log capacity
endfunction : set_mode


function void xlr_gpp_tx::do_copy(uvm_object rhs);
  xlr_gpp_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  super.do_copy(rhs);
  if (mode == "in") begin // inputs only
    host_regsi       = rhs_.host_regsi;      
    host_regs_valid  = rhs_.host_regs_valid; 
  end else if (mode == "out") begin // outputs only
    host_regso       = rhs_.host_regso;      
    host_regso_valid = rhs_.host_regso_valid;
  end else if (mode == "all") begin // both
    host_regsi       = rhs_.host_regsi;      
    host_regs_valid  = rhs_.host_regs_valid; 
    host_regso       = rhs_.host_regso;      
    host_regso_valid = rhs_.host_regso_valid;
  end else if (mode == "busy") begin // busy signal
    host_regso[0]       = rhs_.host_regso[0];      
    host_regso_valid[0] = rhs_.host_regso_valid[0];
  end else if (mode == "done") begin // done signal
    host_regso[1]       = rhs_.host_regso[1];      
    host_regso_valid[1] = rhs_.host_regso_valid[1];
  end
endfunction : do_copy


function bit xlr_gpp_tx::do_compare(uvm_object rhs, uvm_comparer comparer); // Note - Excluding the input signals
  bit result;
  xlr_gpp_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal("", "Cast of rhs object failed")
  result = super.do_compare(rhs, comparer);
    if (mode == "in") begin // inputs only
    result &= comparer.compare_field("host_regsi", host_regsi,             rhs_.host_regsi,       $bits(host_regsi));
    result &= comparer.compare_field("host_regs_valid", host_regs_valid,   rhs_.host_regs_valid,  $bits(host_regs_valid));
  end else if (mode == "out") begin // outputs only
    result &= comparer.compare_field("(busy)host_regso[0]", host_regso[0],             rhs_.host_regso[0],       $bits(host_regso[0]));
    result &= comparer.compare_field("(busy)host_regso_valid[0]", host_regso_valid[0], rhs_.host_regso_valid[0], $bits(host_regso_valid[0]));
    result &= comparer.compare_field("(done)host_regso[1]", host_regso[1],             rhs_.host_regso[1],       $bits(host_regso[1]));
    result &= comparer.compare_field("(done)host_regso_valid[1]", host_regso_valid[1], rhs_.host_regso_valid[1], $bits(host_regso_valid[1]));
  end else if (mode == "all") begin // all
    result &= comparer.compare_field("host_regsi", host_regsi,             rhs_.host_regsi,       $bits(host_regsi));
    result &= comparer.compare_field("host_regs_valid", host_regs_valid,   rhs_.host_regs_valid,  $bits(host_regs_valid));
    result &= comparer.compare_field("host_regso", host_regso,             rhs_.host_regso,       $bits(host_regso));
    result &= comparer.compare_field("host_regso_valid", host_regso_valid, rhs_.host_regso_valid, $bits(host_regso_valid));
  end else if (mode == "start") begin // start signal
    result &= comparer.compare_field("host_regsi", host_regsi[0],             rhs_.host_regsi[0],       $bits(host_regsi[0]));
    result &= comparer.compare_field("host_regs_valid", host_regs_valid[0],   rhs_.host_regs_valid[0],  $bits(host_regs_valid[0]));
  end else if (mode == "busy") begin // busy signal
    result &= comparer.compare_field("(busy)host_regso[0]", host_regso[0],             rhs_.host_regso[0],       $bits(host_regso[0]));
    result &= comparer.compare_field("(busy)host_regso_valid[0]", host_regso_valid[0], rhs_.host_regso_valid[0], $bits(host_regso_valid[0]));
  end else if (mode == "done") begin // done signal
    result &= comparer.compare_field("(done)host_regso[1]", host_regso[1],             rhs_.host_regso[1],       $bits(host_regso[1]));
    result &= comparer.compare_field("(done)host_regso_valid[1]", host_regso_valid[1], rhs_.host_regso_valid[1], $bits(host_regso_valid[1]));
  end
  return result;
endfunction : do_compare


// "io" can be : in (inputs only) || out(outputs only) || all(both)  extern function void do_record(uvm_recorder recorder);
function void xlr_gpp_tx::do_print(uvm_printer printer);
    if (printer.knobs.sprint == 0) begin
    `uvm_info(get_type_name(), convert2string(), UVM_MEDIUM)
  end else begin
    if (mode == "in") begin // inputs only
      printer.m_string = convert2string_in();
    end else if (mode == "out") begin// outputs only
      printer.m_string = convert2string_out();
    end else if (mode == "all") begin // both I/Os
      printer.m_string = convert2string();
    end else if (mode == "start") begin // start signal
      printer.m_string = convert2string_start();
    end else if (mode == "busy") begin // busy signal
      printer.m_string = convert2string_busy();
    end else if (mode == "done") begin // done signal
      printer.m_string = convert2string_done();
    end
  end
endfunction : do_print


function void xlr_gpp_tx::do_record(uvm_recorder recorder);
  super.do_record(recorder);
  // Use the record macros to record the item fields:
  `uvm_record_field("host_regsi",       host_regsi)      
  `uvm_record_field("host_regs_valid",  host_regs_valid) 
  `uvm_record_field("host_regso",       host_regso)      
  `uvm_record_field("host_regso_valid", host_regso_valid)
endfunction : do_record


function void xlr_gpp_tx::do_pack(uvm_packer packer);
  super.do_pack(packer);
  `uvm_pack_int(host_regsi)       
  `uvm_pack_int(host_regs_valid)  
  `uvm_pack_int(host_regso)       
  `uvm_pack_int(host_regso_valid) 
endfunction : do_pack


function void xlr_gpp_tx::do_unpack(uvm_packer packer);
  super.do_unpack(packer);
  `uvm_unpack_int(host_regsi)       
  `uvm_unpack_int(host_regs_valid)  
  `uvm_unpack_int(host_regso)       
  `uvm_unpack_int(host_regso_valid) 
endfunction : do_unpack


function string xlr_gpp_tx::convert2string(); // print all
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {
    "\thost_regsi       = 'h%0h  'd%0d\n", 
    "\thost_regs_valid  = 'h%0h  'd%0d\n", 
    "\thost_regso       = 'h%0h  'd%0d\n", 
    "\thost_regso_valid = 'h%0h  'd%0d\n"},
    host_regsi, host_regsi, host_regs_valid, host_regs_valid, host_regso, host_regso, host_regso_valid, host_regso_valid);
  return s;
endfunction : convert2string


function string xlr_gpp_tx::convert2string_in(); // print inputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {
    "\thost_regsi       = 'h%0h  'd%0d\n", 
    "\thost_regs_valid  = 'h%0h  'd%0d\n"},
    host_regsi, host_regsi, host_regs_valid, host_regs_valid);
  return s;
endfunction : convert2string_in


function string xlr_gpp_tx::convert2string_out(); // print outputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, { 
    "\thost_regso       = 'h%0h  'd%0d\n", 
    "\thost_regso_valid = 'h%0h  'd%0d\n"},
    host_regso, host_regso, host_regso_valid, host_regso_valid);
  return s;
endfunction : convert2string_out


function string xlr_gpp_tx::convert2string_start(); // print start signal
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {
    "\thost_regsi[0]       = 'h%0h  'd%0d\n", 
    "\thost_regs_valid[0]  = 'h%0h  'd%0d\n"},
    host_regsi[0], host_regsi[0], host_regs_valid[0], host_regs_valid[0]);
  return s;
endfunction : convert2string_start


function string xlr_gpp_tx::convert2string_busy(); // print busy signal
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {
    "\t(busy)host_regso[0]       = 'h%0h  'd%0d\n", 
    "\t(busy)host_regso_valid[0] = 'h%0h  'd%0d\n"},
    host_regso[0], host_regso[0], host_regso_valid[0], host_regso_valid[0]);
  return s;
endfunction : convert2string_busy


function string xlr_gpp_tx::convert2string_done(); // print done signal
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, { 
    "\t(done)host_regso[1]       = 'h%0h  'd%0d\n", 
    "\t(done)host_regso_valid[1] = 'h%0h  'd%0d\n"},
    host_regso[1], host_regso[1], host_regso_valid[1], host_regso_valid[1]);
  return s;
endfunction : convert2string_done

`endif // XLR_GPP_SEQ_ITEM_SV

