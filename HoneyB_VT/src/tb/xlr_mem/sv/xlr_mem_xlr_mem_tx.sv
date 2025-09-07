//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_mem_seq_item.sv
//=============================================================================
// Description: Sequence item for xlr_mem_sequencer
//
//              This tx class contains the following special methods:
//              print(), copy(), compare(), record(), unpack(), pack()
//
//              First cool feature is "mode select" :
//              Mode Select allows you to choose which outputs to
//              apply the method to.
//
//              how to use mode select :
//                            tx.set_mode("<chosen_mode>");
//                            tx.copy(tx2); (example for using copy method)
//
//              possible modes :
//                         | all || in || out || rd || wr |
//
//              The next cool feature is "mem select" :
//              Mem Select allows you to choose which memory's signals
//              to apply the method to.
//
//              how to use mem select :
//                            tx.set_mem("<chosen_mem>");
//                            tx.set_mode("<chose_mode");
//                            tx.copy(tx2); (example for using copy method)
//
//              possible mem selects :
//                         | MEMA(all) || MEM0 || MEM1 | 
//
//              Note - It's crucial to use both "set_mem" & "set_mode"
//              It won't work if we use only one of the features !!
//=============================================================================

`ifndef XLR_MEM_SEQ_ITEM_SV
`define XLR_MEM_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*; // for parameters + typedef enum

class xlr_mem_tx extends uvm_sequence_item; 

  `uvm_object_utils(xlr_mem_tx)

  string mode = "all"; // default io mode all - options : all / in / out / rd / wr
  x_mem mem = MEMA; // default mem select MEMA - options : MEMA(all) / MEM0 / MEM1

  // Transaction variables
  int                                                      mem_idx;

  rand logic [NUM_MEMS-1:0][7:0][31:0]                     mem_rdata;

  logic      [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0]        mem_addr;
  logic      [NUM_MEMS-1:0][7:0][31:0]                     mem_wdata;
  logic      [NUM_MEMS-1:0][31:0]                          mem_be;
  logic      [NUM_MEMS-1:0]                                mem_rd;
  logic      [NUM_MEMS-1:0]                                mem_wr;

  constraint c_mem_rdata {
    foreach (mem_rdata[0][i])
      mem_rdata[0][i] inside {[0:20]};
  }

  extern function new(string name = "");
  extern function void set_mode(string s);
  extern function void set_mem(x_mem m);
  extern function void set_mem_idx(int m_idx);
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
  assert (s == "all" || s == "in" || s == "out" || s == "rd" || s == "wr")
  else begin
    `uvm_fatal(get_type_name(),
      $sformatf("set_mode: invalid mode '%s' (allowed: all/in/out/rd/wr)", s))
    return;
  end
  mode = s;
  //`honeyb("[MEM] Tx Object", $sformatf("Setting mode to: %s", s))
endfunction


function void xlr_mem_tx::set_mem(x_mem m); // a simple function to set the mem for printing / copying etc.
  assert (m == MEMA || (int'(m) >= 0 && int'(m) < NUM_MEMS))
  else begin
    `uvm_fatal(get_type_name(),
      $sformatf("set_mem: invalid enum value MEM[%0d] (allowed: MEM[A] or MEM[0]..MEM[%0d])", m, NUM_MEMS-1))
    return;
  end
  mem = m;
  //`honeyb("[MEM] TX Object", $sformatf("Setting mem to: MEM[%0d]", mem))
endfunction

function void xlr_mem_tx::set_mem_idx(int m_idx);
  assert ((m_idx >= 0) && (m_idx < NUM_MEMS))
  else begin
    `uvm_fatal(get_type_name(),
      $sformatf("set_mem_idx: invalid index value %0d (allowed: 0 <= mem_idx <= %0d)", m_idx, NUM_MEMS-1))
    return;
  end
  mem_idx = m_idx;
  //`honeyb("[MEM] TX Object", $sformatf("Setting mem_idx to: %0d", mem_idx))
endfunction


function void xlr_mem_tx::do_copy(uvm_object rhs);
  xlr_mem_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  super.do_copy(rhs);
  mem   = rhs_.mem;   // Copy now so Branching will be according to the TX being copied
  mode  = rhs_.mode;
  if (mem == MEMA) begin
    if (mode == "all") begin // both
      mem_idx   = rhs_.mem_idx;
      mem_rdata = rhs_.mem_rdata;
      mem_addr  = rhs_.mem_addr; 
      mem_wdata = rhs_.mem_wdata;
      mem_be    = rhs_.mem_be;   
      mem_rd    = rhs_.mem_rd;
      mem_wr    = rhs_.mem_wr; 
    end else if (mode == "in") begin // inputs only
      mem_idx   = rhs_.mem_idx;
      mem_rdata = rhs_.mem_rdata;
    end else if (mode == "out") begin // outputs only
      mem_idx   = rhs_.mem_idx;
      mem_addr  = rhs_.mem_addr; 
      mem_wdata = rhs_.mem_wdata;
      mem_be    = rhs_.mem_be;   
      mem_rd    = rhs_.mem_rd;   
      mem_wr    = rhs_.mem_wr;
    end else if (mode == "rd") begin // read related signals
      mem_idx   = rhs_.mem_idx;
      mem_rd    = rhs_.mem_rd;
      mem_addr  = rhs_.mem_addr; 
      mem_be    = rhs_.mem_be;
      mem_rdata = rhs_.mem_rdata;
    end else if (mode == "wr") begin // write related signals
      mem_idx   = rhs_.mem_idx;
      mem_wr    = rhs_.mem_wr; 
      mem_addr  = rhs_.mem_addr;
      mem_be    = rhs_.mem_be;
      mem_wdata = rhs_.mem_wdata;
    end
  end else if (mem == MEM0) begin
    if (mode == "all") begin // both
      mem_idx          = rhs_.mem_idx;
      mem_rdata [MEM0] = rhs_.mem_rdata [MEM0];
      mem_addr  [MEM0] = rhs_.mem_addr  [MEM0]; 
      mem_wdata [MEM0] = rhs_.mem_wdata [MEM0];
      mem_be    [MEM0] = rhs_.mem_be    [MEM0];   
      mem_rd    [MEM0] = rhs_.mem_rd    [MEM0];
      mem_wr    [MEM0] = rhs_.mem_wr    [MEM0]; 
    end else if (mode == "in") begin // inputs only
      mem_idx          = rhs_.mem_idx;
      mem_rdata [MEM0] = rhs_.mem_rdata [MEM0];
    end else if (mode == "out") begin // outputs only
      mem_idx          = rhs_.mem_idx;
      mem_addr  [MEM0] = rhs_.mem_addr  [MEM0]; 
      mem_wdata [MEM0] = rhs_.mem_wdata [MEM0];
      mem_be    [MEM0] = rhs_.mem_be    [MEM0];   
      mem_rd    [MEM0] = rhs_.mem_rd    [MEM0];   
      mem_wr    [MEM0] = rhs_.mem_wr    [MEM0];
    end else if (mode == "rd") begin // read related signals
      mem_idx          = rhs_.mem_idx;
      mem_rd    [MEM0] = rhs_.mem_rd    [MEM0];
      mem_addr  [MEM0] = rhs_.mem_addr  [MEM0]; 
      mem_be    [MEM0] = rhs_.mem_be    [MEM0];
      mem_rdata [MEM0] = rhs_.mem_rdata [MEM0];
    end else if (mode == "wr") begin // write related signals
      mem_idx          = rhs_.mem_idx;
      mem_wr    [MEM0] = rhs_.mem_wr    [MEM0]; 
      mem_addr  [MEM0] = rhs_.mem_addr  [MEM0];
      mem_be    [MEM0] = rhs_.mem_be    [MEM0];
      mem_wdata [MEM0] = rhs_.mem_wdata [MEM0];
    end
  end else if (mem == MEM1) begin
    if (mode == "all") begin // both
      mem_idx          = rhs_.mem_idx;
      mem_rdata [MEM1] = rhs_.mem_rdata [MEM1];
      mem_addr  [MEM1] = rhs_.mem_addr  [MEM1]; 
      mem_wdata [MEM1] = rhs_.mem_wdata [MEM1];
      mem_be    [MEM1] = rhs_.mem_be    [MEM1];   
      mem_rd    [MEM1] = rhs_.mem_rd    [MEM1];
      mem_wr    [MEM1] = rhs_.mem_wr    [MEM1]; 
    end else if (mode == "in") begin // inputs only
      mem_idx          = rhs_.mem_idx;
      mem_rdata [MEM1] = rhs_.mem_rdata [MEM1];
    end else if (mode == "out") begin // outputs only
      mem_idx          = rhs_.mem_idx;
      mem_addr  [MEM1] = rhs_.mem_addr  [MEM1]; 
      mem_wdata [MEM1] = rhs_.mem_wdata [MEM1];
      mem_be    [MEM1] = rhs_.mem_be    [MEM1];   
      mem_rd    [MEM1] = rhs_.mem_rd    [MEM1];   
      mem_wr    [MEM1] = rhs_.mem_wr    [MEM1];
    end else if (mode == "rd") begin // read related signals
      mem_idx          = rhs_.mem_idx;
      mem_rd    [MEM1] = rhs_.mem_rd    [MEM1];
      mem_addr  [MEM1] = rhs_.mem_addr  [MEM1]; 
      mem_be    [MEM1] = rhs_.mem_be    [MEM1];
      mem_rdata [MEM1] = rhs_.mem_rdata [MEM1];
    end else if (mode == "wr") begin // write related signals
      mem_idx          = rhs_.mem_idx;
      mem_wr    [MEM1] = rhs_.mem_wr    [MEM1]; 
      mem_addr  [MEM1] = rhs_.mem_addr  [MEM1];
      mem_be    [MEM1] = rhs_.mem_be    [MEM1];
      mem_wdata [MEM1] = rhs_.mem_wdata [MEM1];
    end
  end
endfunction : do_copy


function bit xlr_mem_tx::do_compare(uvm_object rhs, uvm_comparer comparer); // Note - Excluding the input signals
  bit result;
  xlr_mem_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal("", "Cast of rhs object failed")
  result = super.do_compare(rhs, comparer);
  result &= comparer.compare_field("mem_idx", mem_idx, rhs_.mem_idx, $bits(mem_idx));
  if (mem == MEMA) begin
    if (mode == "all") begin // all signals
      result &= comparer.compare_field("mem_rdata", mem_rdata, rhs_.mem_rdata, $bits(mem_rdata));
      result &= comparer.compare_field("mem_addr", mem_addr,   rhs_.mem_addr,  $bits(mem_addr));
      result &= comparer.compare_field("mem_wdata", mem_wdata, rhs_.mem_wdata, $bits(mem_wdata));
      result &= comparer.compare_field("mem_be", mem_be,       rhs_.mem_be,    $bits(mem_be));
      result &= comparer.compare_field("mem_rd", mem_rd,       rhs_.mem_rd,    $bits(mem_rd));
      result &= comparer.compare_field("mem_wr", mem_wr,       rhs_.mem_wr,    $bits(mem_wr));
    end else if (mode == "in") begin // inputs only
      result &= comparer.compare_field("mem_rdata", mem_rdata, rhs_.mem_rdata, $bits(mem_rdata));
    end else if (mode == "out") begin // outputs only
      result &= comparer.compare_field("mem_addr", mem_addr,   rhs_.mem_addr,  $bits(mem_addr));
      result &= comparer.compare_field("mem_wdata", mem_wdata, rhs_.mem_wdata, $bits(mem_wdata));
      result &= comparer.compare_field("mem_be", mem_be,       rhs_.mem_be,    $bits(mem_be));
      result &= comparer.compare_field("mem_rd", mem_rd,       rhs_.mem_rd,    $bits(mem_rd));
      result &= comparer.compare_field("mem_wr", mem_wr,       rhs_.mem_wr,    $bits(mem_wr));
    end else if (mode == "rd") begin // read only
      result &= comparer.compare_field("mem_rd", mem_rd,       rhs_.mem_rd,    $bits(mem_rd)); // rd req
      result &= comparer.compare_field("mem_addr", mem_addr,   rhs_.mem_addr,  $bits(mem_addr)); // address
      result &= comparer.compare_field("mem_be", mem_be,       rhs_.mem_be,    $bits(mem_be)); // bit en
      result &= comparer.compare_field("mem_rdata", mem_rdata, rhs_.mem_rdata, $bits(mem_rdata)); // rdata
    end else if (mode == "wr") begin // write only
      result &= comparer.compare_field("mem_wr", mem_wr,       rhs_.mem_wr,    $bits(mem_wr)); // wr req
      result &= comparer.compare_field("mem_addr", mem_addr,   rhs_.mem_addr,  $bits(mem_addr)); // addr
      result &= comparer.compare_field("mem_be", mem_be,       rhs_.mem_be,    $bits(mem_be)); // bit en
      result &= comparer.compare_field("mem_wdata", mem_wdata, rhs_.mem_wdata, $bits(mem_wdata)); // wdata
    end
  end else if (mem == MEM0) begin
    if (mode == "all") begin // all signals
      result &= comparer.compare_field("mem_rdata[0]", mem_rdata[MEM0], rhs_.mem_rdata[MEM0], $bits(mem_rdata[MEM0]));
      result &= comparer.compare_field("mem_addr[0]", mem_addr[MEM0],   rhs_.mem_addr[MEM0],  $bits(mem_addr[MEM0]));
      result &= comparer.compare_field("mem_wdata[0]", mem_wdata[MEM0], rhs_.mem_wdata[MEM0], $bits(mem_wdata[MEM0]));
      result &= comparer.compare_field("mem_be[0]", mem_be[MEM0],       rhs_.mem_be[MEM0],    $bits(mem_be[MEM0]));
      result &= comparer.compare_field("mem_rd[0]", mem_rd[MEM0],       rhs_.mem_rd[MEM0],    $bits(mem_rd[MEM0]));
      result &= comparer.compare_field("mem_wr[0]", mem_wr[MEM0],       rhs_.mem_wr[MEM0],    $bits(mem_wr[MEM0]));
    end else if (mode == "in") begin // inputs only
      result &= comparer.compare_field("mem_rdata[0]", mem_rdata[MEM0], rhs_.mem_rdata[MEM0], $bits(mem_rdata[MEM0]));
    end else if (mode == "out") begin // outputs only
      result &= comparer.compare_field("mem_addr[0]", mem_addr[MEM0],   rhs_.mem_addr[MEM0],  $bits(mem_addr[MEM0]));
      result &= comparer.compare_field("mem_wdata[0]", mem_wdata[MEM0], rhs_.mem_wdata[MEM0], $bits(mem_wdata[MEM0]));
      result &= comparer.compare_field("mem_be[0]", mem_be[MEM0],       rhs_.mem_be[MEM0],    $bits(mem_be[MEM0]));
      result &= comparer.compare_field("mem_rd[0]", mem_rd[MEM0],       rhs_.mem_rd[MEM0],    $bits(mem_rd[MEM0]));
      result &= comparer.compare_field("mem_wr[0]", mem_wr[MEM0],       rhs_.mem_wr[MEM0],    $bits(mem_wr[MEM0]));
    end else if (mode == "rd") begin // read only
      result &= comparer.compare_field("mem_rd[0]", mem_rd[MEM0],       rhs_.mem_rd[MEM0],    $bits(mem_rd[MEM0])); // rd req
      result &= comparer.compare_field("mem_addr[0]", mem_addr[MEM0],   rhs_.mem_addr[MEM0],  $bits(mem_addr[MEM0])); // address
      result &= comparer.compare_field("mem_be[0]", mem_be[MEM0],       rhs_.mem_be[MEM0],    $bits(mem_be[MEM0])); // bit en
      result &= comparer.compare_field("mem_rdata[0]", mem_rdata[MEM0], rhs_.mem_rdata[MEM0], $bits(mem_rdata[MEM0])); // rdata
    end else if (mode == "wr") begin // write only
      result &= comparer.compare_field("mem_wr[0]", mem_wr[MEM0],       rhs_.mem_wr[MEM0],    $bits(mem_wr[MEM0])); // wr req
      result &= comparer.compare_field("mem_addr[0]", mem_addr[MEM0],   rhs_.mem_addr[MEM0],  $bits(mem_addr[MEM0])); // addr
      result &= comparer.compare_field("mem_be[0]", mem_be[MEM0],       rhs_.mem_be[MEM0],    $bits(mem_be[MEM0])); // bit en
      result &= comparer.compare_field("mem_wdata[0]", mem_wdata[MEM0], rhs_.mem_wdata[MEM0], $bits(mem_wdata[MEM0])); // wdata
    end
  end else if (mem == MEM1) begin
    if (mode == "all") begin // all signals
      result &= comparer.compare_field("mem_rdata[0]", mem_rdata[MEM1], rhs_.mem_rdata[MEM1], $bits(mem_rdata[MEM1]));
      result &= comparer.compare_field("mem_addr[0]", mem_addr[MEM1],   rhs_.mem_addr[MEM1],  $bits(mem_addr[MEM1]));
      result &= comparer.compare_field("mem_wdata[0]", mem_wdata[MEM1], rhs_.mem_wdata[MEM1], $bits(mem_wdata[MEM1]));
      result &= comparer.compare_field("mem_be[0]", mem_be[MEM1],       rhs_.mem_be[MEM1],    $bits(mem_be[MEM1]));
      result &= comparer.compare_field("mem_rd[0]", mem_rd[MEM1],       rhs_.mem_rd[MEM1],    $bits(mem_rd[MEM1]));
      result &= comparer.compare_field("mem_wr[0]", mem_wr[MEM1],       rhs_.mem_wr[MEM1],    $bits(mem_wr[MEM1]));
    end else if (mode == "in") begin // inputs only
      result &= comparer.compare_field("mem_rdata[0]", mem_rdata[MEM1], rhs_.mem_rdata[MEM1], $bits(mem_rdata[MEM1]));
    end else if (mode == "out") begin // outputs only
      result &= comparer.compare_field("mem_addr[0]", mem_addr[MEM1],   rhs_.mem_addr[MEM1],  $bits(mem_addr[MEM1]));
      result &= comparer.compare_field("mem_wdata[0]", mem_wdata[MEM1], rhs_.mem_wdata[MEM1], $bits(mem_wdata[MEM1]));
      result &= comparer.compare_field("mem_be[0]", mem_be[MEM1],       rhs_.mem_be[MEM1],    $bits(mem_be[MEM1]));
      result &= comparer.compare_field("mem_rd[0]", mem_rd[MEM1],       rhs_.mem_rd[MEM1],    $bits(mem_rd[MEM1]));
      result &= comparer.compare_field("mem_wr[0]", mem_wr[MEM1],       rhs_.mem_wr[MEM1],    $bits(mem_wr[MEM1]));
    end else if (mode == "rd") begin // read only
      result &= comparer.compare_field("mem_rd[0]", mem_rd[MEM1],       rhs_.mem_rd[MEM1],    $bits(mem_rd[MEM1])); // rd req
      result &= comparer.compare_field("mem_addr[0]", mem_addr[MEM1],   rhs_.mem_addr[MEM1],  $bits(mem_addr[MEM1])); // address
      result &= comparer.compare_field("mem_be[0]", mem_be[MEM1],       rhs_.mem_be[MEM1],    $bits(mem_be[MEM1])); // bit en
      result &= comparer.compare_field("mem_rdata[0]", mem_rdata[MEM1], rhs_.mem_rdata[MEM1], $bits(mem_rdata[MEM1])); // rdata
    end else if (mode == "wr") begin // write only
      result &= comparer.compare_field("mem_wr[0]", mem_wr[MEM1],       rhs_.mem_wr[MEM1],    $bits(mem_wr[MEM1])); // wr req
      result &= comparer.compare_field("mem_addr[0]", mem_addr[MEM1],   rhs_.mem_addr[MEM1],  $bits(mem_addr[MEM1])); // addr
      result &= comparer.compare_field("mem_be[0]", mem_be[MEM1],       rhs_.mem_be[MEM1],    $bits(mem_be[MEM1])); // bit en
      result &= comparer.compare_field("mem_wdata[0]", mem_wdata[MEM1], rhs_.mem_wdata[MEM1], $bits(mem_wdata[MEM1])); // wdata
    end
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
  if (mem == MEMA) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "=========================================================================\n\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n", PD, 
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD, 
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n\n", PD,
      "=========================================================================\n\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_rdata [MEM0], mem_rdata [MEM0], 
      MEM0, mem_addr  [MEM0], mem_addr  [MEM0], 
      MEM0, mem_wdata [MEM0], mem_wdata [MEM0], 
      MEM0, mem_be    [MEM0], mem_be    [MEM0], 
      MEM0, mem_rd    [MEM0], mem_rd    [MEM0], 
      MEM0, mem_wr    [MEM0], mem_wr    [MEM0],
      MEM1, mem_rdata [MEM1], mem_rdata [MEM1],
      MEM1, mem_addr  [MEM1], mem_addr  [MEM1],
      MEM1, mem_wdata [MEM1], mem_wdata [MEM1],
      MEM1, mem_be    [MEM1], mem_be    [MEM1],
      MEM1, mem_rd    [MEM1], mem_rd    [MEM1],
      MEM1, mem_wr    [MEM1], mem_wr    [MEM1]);
  end else if (mem == MEM0) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_rdata [MEM0], mem_rdata [MEM0],
      MEM0, mem_addr  [MEM0], mem_addr  [MEM0],
      MEM0, mem_wdata [MEM0], mem_wdata [MEM0],
      MEM0, mem_be    [MEM0], mem_be    [MEM0],
      MEM0, mem_rd    [MEM0], mem_rd    [MEM0],
      MEM0, mem_wr    [MEM0], mem_wr    [MEM0]);
  end else if (mem == MEM1) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM1, mem_rdata [MEM1], mem_rdata [MEM1],
      MEM1, mem_addr  [MEM1], mem_addr  [MEM1],
      MEM1, mem_wdata [MEM1], mem_wdata [MEM1],
      MEM1, mem_be    [MEM1], mem_be    [MEM1],
      MEM1, mem_rd    [MEM1], mem_rd    [MEM1],
      MEM1, mem_wr    [MEM1], mem_wr    [MEM1]);
  end
  return s;
endfunction : convert2string

function string xlr_mem_tx::convert2string_in(); // print inputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n\n", PD, 
      "=========================================================================\n\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_rdata [MEM0], mem_rdata [MEM0], 
      MEM1, mem_rdata [MEM1], mem_rdata [MEM1]);
  end else if (mem == MEM0) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_rdata[MEM0], mem_rdata[MEM0]);
  end else if (mem == MEM1) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM1, mem_rdata[MEM1], mem_rdata[MEM1]);
  end
  return s;
endfunction : convert2string_in

function string xlr_mem_tx::convert2string_out(); // print outputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD, 
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n\n", PD,
      "=========================================================================\n\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_addr  [MEM0], mem_addr  [MEM0], 
      MEM0, mem_wdata [MEM0], mem_wdata [MEM0], 
      MEM0, mem_be    [MEM0], mem_be    [MEM0], 
      MEM0, mem_rd    [MEM0], mem_rd    [MEM0], 
      MEM0, mem_wr    [MEM0], mem_wr    [MEM0],
      MEM1, mem_addr  [MEM1], mem_addr  [MEM1],
      MEM1, mem_wdata [MEM1], mem_wdata [MEM1],
      MEM1, mem_be    [MEM1], mem_be    [MEM1],
      MEM1, mem_rd    [MEM1], mem_rd    [MEM1],
      MEM1, mem_wr    [MEM1], mem_wr    [MEM1]);
  end else if (mem == MEM0) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_addr [MEM0], mem_addr [MEM0],
      MEM0, mem_wdata[MEM0], mem_wdata[MEM0],
      MEM0, mem_be   [MEM0], mem_be   [MEM0],
      MEM0, mem_rd   [MEM0], mem_rd   [MEM0],
      MEM0, mem_wr   [MEM0], mem_wr   [MEM0]);
  end else if (mem == MEM1) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM1, mem_addr [MEM1], mem_addr [MEM1],
      MEM1, mem_wdata[MEM1], mem_wdata[MEM1],
      MEM1, mem_be   [MEM1], mem_be   [MEM1],
      MEM1, mem_rd   [MEM1], mem_rd   [MEM1],
      MEM1, mem_wr   [MEM1], mem_wr   [MEM1]);
  end
  return s;
endfunction : convert2string_out

function string xlr_mem_tx::convert2string_rd(); // print read operation
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD, 
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD, 
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n\n", PD,
      "=========================================================================\n\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_rd    [MEM0], mem_rd    [MEM0],
      MEM0, mem_addr  [MEM0], mem_addr  [MEM0], 
      MEM0, mem_be    [MEM0], mem_be    [MEM0], 
      MEM0, mem_rdata [MEM0], mem_rdata [MEM0], 
      MEM1, mem_rd    [MEM1], mem_rd    [MEM1],
      MEM1, mem_addr  [MEM1], mem_addr  [MEM1],
      MEM1, mem_be    [MEM1], mem_be    [MEM1],
      MEM1, mem_rdata [MEM1], mem_rdata [MEM1]);
  end else if (mem == MEM0) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_rd    [MEM0], mem_rd    [MEM0],
      MEM0, mem_addr  [MEM0], mem_addr  [MEM0],
      MEM0, mem_be    [MEM0], mem_be    [MEM0],
      MEM0, mem_rdata [MEM0], mem_rdata [MEM0]);
  end else if (mem == MEM1) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_rd    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_rdata [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM1, mem_rd    [MEM1], mem_rd    [MEM1],
      MEM1, mem_addr  [MEM1], mem_addr  [MEM1],
      MEM1, mem_be    [MEM1], mem_be    [MEM1],
      MEM1, mem_rdata [MEM1], mem_rdata [MEM1]);
  end
  return s;
endfunction : convert2string_rd

function string xlr_mem_tx::convert2string_wr(); // print write operation
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n\n", PD,
      "=========================================================================\n\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_wr    [MEM0], mem_wr    [MEM0],
      MEM0, mem_addr  [MEM0], mem_addr  [MEM0], 
      MEM0, mem_be    [MEM0], mem_be    [MEM0],
      MEM0, mem_wdata [MEM0], mem_wdata [MEM0],
      MEM1, mem_wr    [MEM1], mem_wr    [MEM1],
      MEM1, mem_addr  [MEM1], mem_addr  [MEM1],
      MEM1, mem_be    [MEM1], mem_be    [MEM1],
      MEM1, mem_wdata [MEM1], mem_wdata [MEM1]);
  end else if (mem == MEM0) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM0, mem_wr   [MEM0], mem_wr   [MEM0],
      MEM0, mem_addr [MEM0], mem_addr [MEM0],
      MEM0, mem_be   [MEM0], mem_be   [MEM0],
      MEM0, mem_wdata[MEM0], mem_wdata[MEM0]);
  end else if (mem == MEM1) begin
    $sformat(s, {"\n", PD, "mem_idx = %0d\n", PD,
      "mem_wr    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_addr  [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_be    [MEM%0d] = 'h%0h  'd%0d\n", PD,
      "mem_wdata [MEM%0d] = 'h%0h  'd%0d\n\n"},
      mem_idx,
      MEM1, mem_wr    [MEM1], mem_wr    [MEM1],
      MEM1, mem_addr  [MEM1], mem_addr  [MEM1],
      MEM1, mem_be    [MEM1], mem_be    [MEM1],
      MEM1, mem_wdata [MEM1], mem_wdata [MEM1]);
  end
  return s;
endfunction : convert2string_wr

`endif // XLR_MEM_SEQ_ITEM_SV

