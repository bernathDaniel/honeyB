//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_mem_seq_item.sv
//=============================================================================
// Description: Sequence item for xlr_mem_sequencer
//
//              This tx class contains the following special methods:
//              print(), copy(), compare(), record(), unpack(), pack()
//
//              Another cool feature is "mode select" :
//              Mode Select allows you to choose which outputs to
//              apply the method to.
//
//              how to use mode select :
//                            tx.set_mode("<chosen_mode>");
//                            tx.copy(tx2); (example for using copy method)
//
//              possible modes :
//                         | all || in || out || rd || wr |
//=============================================================================

`ifndef XLR_MEM_SEQ_ITEM_SV
`define XLR_MEM_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class xlr_mem_tx extends uvm_sequence_item; 

  `uvm_object_utils(xlr_mem_tx)

  string mode = "all"; // default io mode all - options : all / in / out / rd / wr

  // Transaction variables
  rand logic [0:0][7:0][31:0] mem_rdata;
  logic [0:0][3:0] mem_addr;
  logic [0:0][7:0][31:0] mem_wdata;
  logic [0:0][31:0] mem_be;
  logic [0:0] mem_rd;
  logic [0:0] mem_wr;

  constraint c_mem_rdata {
    foreach (mem_rdata[0][i])
      mem_rdata[0][i] inside {[0:20]};
  }

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
  extern function string convert2string_rd();
  extern function string convert2string_wr();
endclass : xlr_mem_tx 


function xlr_mem_tx::new(string name = "");
  super.new(name);
endfunction : new


function void xlr_mem_tx::set_mode(string s); // a simple function to set the io mode for printing / copying etc.
  mode = s;
  `uvm_info("", $sformatf("Setting mode to: %s", s), UVM_MEDIUM)
endfunction


function void xlr_mem_tx::do_copy(uvm_object rhs);
  xlr_mem_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  super.do_copy(rhs);
  if (mode == "in") begin // inputs only
    mem_rdata = rhs_.mem_rdata;
  end else if (mode == "out") begin // outputs only
    mem_addr  = rhs_.mem_addr; 
    mem_wdata = rhs_.mem_wdata;
    mem_be    = rhs_.mem_be;   
    mem_rd    = rhs_.mem_rd;   
    mem_wr    = rhs_.mem_wr; 
  end else if (mode == "all") begin // both
    mem_rdata = rhs_.mem_rdata;
    mem_addr  = rhs_.mem_addr; 
    mem_wdata = rhs_.mem_wdata;
    mem_be    = rhs_.mem_be;   
    mem_rd    = rhs_.mem_rd;
    mem_wr    = rhs_.mem_wr; 
  end else if (mode == "rd") begin // read related signals
    mem_rd    = rhs_.mem_rd;
    mem_addr  = rhs_.mem_addr; 
    mem_be    = rhs_.mem_be;
    mem_rdata = rhs_.mem_rdata;
  end else if (mode == "wr") begin // write related signals
    mem_wr    = rhs_.mem_wr; 
    mem_addr  = rhs_.mem_addr;
    mem_be    = rhs_.mem_be;
    mem_wdata = rhs_.mem_wdata;
  end
endfunction : do_copy


function bit xlr_mem_tx::do_compare(uvm_object rhs, uvm_comparer comparer); // Note - Excluding the input signals
  bit result;
  xlr_mem_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal("", "Cast of rhs object failed")
  result = super.do_compare(rhs, comparer);
  if (mode == "in") begin // inputs only
    result &= comparer.compare_field("mem_rdata", mem_rdata, rhs_.mem_rdata, $bits(mem_rdata));
  end else if (mode == "out") begin // outputs only
    result &= comparer.compare_field("mem_addr", mem_addr,   rhs_.mem_addr,  $bits(mem_addr));
    result &= comparer.compare_field("mem_wdata", mem_wdata, rhs_.mem_wdata, $bits(mem_wdata));
    result &= comparer.compare_field("mem_be", mem_be,       rhs_.mem_be,    $bits(mem_be));
    result &= comparer.compare_field("mem_rd", mem_rd,       rhs_.mem_rd,    $bits(mem_rd));
    result &= comparer.compare_field("mem_wr", mem_wr,       rhs_.mem_wr,    $bits(mem_wr));
  end else if (mode == "all") begin // all signals
    result &= comparer.compare_field("mem_rdata", mem_rdata, rhs_.mem_rdata, $bits(mem_rdata));
    result &= comparer.compare_field("mem_addr", mem_addr,   rhs_.mem_addr,  $bits(mem_addr));
    result &= comparer.compare_field("mem_wdata", mem_wdata, rhs_.mem_wdata, $bits(mem_wdata));
    result &= comparer.compare_field("mem_be", mem_be,       rhs_.mem_be,    $bits(mem_be));
    result &= comparer.compare_field("mem_rd", mem_rd,       rhs_.mem_rd,    $bits(mem_rd));
    result &= comparer.compare_field("mem_wr", mem_wr,       rhs_.mem_wr,    $bits(mem_wr));
  end else if (mode == "rd") begin // read related signals
    result &= comparer.compare_field("mem_rd", mem_rd,       rhs_.mem_rd,    $bits(mem_rd)); // rd req
    result &= comparer.compare_field("mem_addr", mem_addr,   rhs_.mem_addr,  $bits(mem_addr)); // address
    result &= comparer.compare_field("mem_be", mem_be,       rhs_.mem_be,    $bits(mem_be)); // bit en
    result &= comparer.compare_field("mem_rdata", mem_rdata, rhs_.mem_rdata, $bits(mem_rdata)); // rdata
  end else if (mode == "wr") begin // write related signals
    result &= comparer.compare_field("mem_wr", mem_wr,       rhs_.mem_wr,    $bits(mem_wr)); // wr req
    result &= comparer.compare_field("mem_addr", mem_addr,   rhs_.mem_addr,  $bits(mem_addr)); // addr
    result &= comparer.compare_field("mem_be", mem_be,       rhs_.mem_be,    $bits(mem_be)); // bit en
    result &= comparer.compare_field("mem_wdata", mem_wdata, rhs_.mem_wdata, $bits(mem_wdata)); // wdata
  end
  return result;
endfunction : do_compare


// "mode" can be : in (inputs only) || out(outputs only) || all(both)
function void xlr_mem_tx::do_print(uvm_printer printer);
  if (printer.knobs.sprint == 0) begin
    `uvm_info(get_type_name(), convert2string(), UVM_MEDIUM)
  end else begin
    if (mode == "in") begin // inputs only
      printer.m_string = convert2string_in();
    end else if (mode == "out") begin// outputs only
      printer.m_string = convert2string_out();
    end else if (mode == "all") begin // both I/Os
      printer.m_string = convert2string();
    end else if (mode == "rd") begin // read related signals
      printer.m_string = convert2string_rd();
    end else if (mode == "wr") begin // write related signals
      printer.m_string = convert2string_wr();
    end
  end
endfunction : do_print


function void xlr_mem_tx::do_record(uvm_recorder recorder);
  super.do_record(recorder);
  // Use the record macros to record the item fields:
  `uvm_record_field("mem_rdata", mem_rdata)
  `uvm_record_field("mem_addr",  mem_addr) 
  `uvm_record_field("mem_wdata", mem_wdata)
  `uvm_record_field("mem_be",    mem_be)   
  `uvm_record_field("mem_rd",    mem_rd)   
  `uvm_record_field("mem_wr",    mem_wr)   
endfunction : do_record


function void xlr_mem_tx::do_pack(uvm_packer packer);
  super.do_pack(packer);
  `uvm_pack_int(mem_rdata) 
  `uvm_pack_int(mem_addr)  
  `uvm_pack_int(mem_wdata) 
  `uvm_pack_int(mem_be)    
  `uvm_pack_int(mem_rd)    
  `uvm_pack_int(mem_wr)    
endfunction : do_pack


function void xlr_mem_tx::do_unpack(uvm_packer packer);
  super.do_unpack(packer);
  `uvm_unpack_int(mem_rdata) 
  `uvm_unpack_int(mem_addr)  
  `uvm_unpack_int(mem_wdata) 
  `uvm_unpack_int(mem_be)    
  `uvm_unpack_int(mem_rd)    
  `uvm_unpack_int(mem_wr)    
endfunction : do_unpack


function string xlr_mem_tx::convert2string(); // print all
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {"%s\n",
    "mem_rdata = 'h%0h  'd%0d\n", 
    "mem_addr  = 'h%0h  'd%0d\n", 
    "mem_wdata = 'h%0h  'd%0d\n", 
    "mem_be    = 'h%0h  'd%0d\n", 
    "mem_rd    = 'h%0h  'd%0d\n", 
    "mem_wr    = 'h%0h  'd%0d\n"},
    get_full_name(), mem_rdata, mem_rdata, mem_addr, mem_addr, mem_wdata, mem_wdata, mem_be, mem_be, mem_rd, mem_rd, mem_wr, mem_wr);
  return s;
endfunction : convert2string


function string xlr_mem_tx::convert2string_in(); // print inputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {"%s\n",
    "mem_rdata = 'h%0h  'd%0d\n"},
    get_full_name(), mem_rdata, mem_rdata);
  return s;
endfunction : convert2string_in


function string xlr_mem_tx::convert2string_out(); // print outputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {"%s\n", 
    "mem_addr  = 'h%0h  'd%0d\n", 
    "mem_wdata = 'h%0h  'd%0d\n", 
    "mem_be    = 'h%0h  'd%0d\n", 
    "mem_rd    = 'h%0h  'd%0d\n", 
    "mem_wr    = 'h%0h  'd%0d\n"},
    get_full_name(), mem_addr, mem_addr, mem_wdata, mem_wdata, mem_be, mem_be, mem_rd, mem_rd, mem_wr, mem_wr);
  return s;
endfunction : convert2string_out


function string xlr_mem_tx::convert2string_rd(); // print read operation
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {"%s\n",
    "mem_rd    = 'h%0h  'd%0d\n", 
    "mem_addr  = 'h%0h  'd%0d\n", 
    "mem_be    = 'h%0h  'd%0d\n", 
    "mem_rdata = 'h%0h  'd%0d\n"},
    get_full_name(), mem_rd, mem_rd, mem_addr, mem_addr, mem_be, mem_be, mem_rdata, mem_rdata);
  return s;
endfunction : convert2string_rd


function string xlr_mem_tx::convert2string_wr(); // print write operation
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, {"%s\n", 
    "mem_wr    = 'h%0h  'd%0d\n",
    "mem_addr  = 'h%0h  'd%0d\n",  
    "mem_be    = 'h%0h  'd%0d\n", 
    "mem_wdata = 'h%0h  'd%0d\n"},
    get_full_name(), mem_wr, mem_wr, mem_addr, mem_addr, mem_be, mem_be, mem_wdata, mem_wdata);
  return s;
endfunction : convert2string_wr

`endif // XLR_MEM_SEQ_ITEM_SV

