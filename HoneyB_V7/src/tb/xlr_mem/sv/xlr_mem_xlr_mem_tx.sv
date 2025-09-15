//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_xlr_mem_tx.sv
//=============================================================================
// Description: Sequence item for xlr_mem_sequencer
  //
  //              This tx class contains the following special methods:
  //              print(), copy(), compare(), record(), unpack(), pack()
  //
  //              First cool feature is "e_mode select" :
  //              The *Event Mode* Select allows you to choose 
  //              which outputs to apply the method to.
  //
  //              how to use event mode select :
  //                            tx.set_e_mode("<chosen_e_mode>");
  //                            tx.copy(tx2); (example for using copy method)
  //
  //              possible e_modes :
  //                         | def || rst_i || rst_o || rd || wr |
  //
  //              The next cool feature is "mem select" :
  //              Mem Select allows you to choose which memory's signals
  //              to apply the method to.
  //
  //              how to use mem select :
  //                            tx.set_mem("<chosen_mem>");
  //                            tx.copy(tx2); (example for using copy method)
  //
  //              possible mem selects :
  //                         | MEMA(def) || MEM0 || MEM1 | 
  //
  //              Note - It's crucial to use both "set_mem" & "set_e_mode"
  //              It won't work if we use only one of the features !!
//=============================================================================

`ifndef XLR_MEM_SEQ_ITEM_SV
`define XLR_MEM_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*; // for parameters + typedef enum

class xlr_mem_tx extends uvm_sequence_item; 

    `uvm_object_utils(xlr_mem_tx)

    string e_mode = "def";
      // default event mode: "def" | options: def / rst_i / rst_o / rd / wr

    x_mem  mem  = MEMA;
      // default mem select: MEMA | options: MEMA(all) / MEM0 / MEM1

    // Transaction variables
    rand logic [NUM_MEMS-1:0][7:0 ][31:0]                    mem_rdata;

    logic      [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0]        mem_addr;
    logic      [NUM_MEMS-1:0][7:0 ][31:0]                    mem_wdata;
    logic      [NUM_MEMS-1:0][31:0]                          mem_be;
    logic      [NUM_MEMS-1:0]                                mem_rd;
    logic      [NUM_MEMS-1:0]                                mem_wr;

    constraint c_mem_rdata {
      foreach (mem_rdata[mem_idx, word_idx]) {
          if (mem_idx < NUM_MEMS) { 
              mem_rdata[mem_idx][word_idx] inside {[0:20]}; 
          }
      }
    }

    extern function new(string name = "");
    extern function void set_e_mode(string s);
    extern function void set_mem(x_mem m);
    extern function void do_copy(uvm_object rhs);
    extern function void calcopy(x_mem to_mem, x_mem from_mem);
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


function void xlr_mem_tx::set_e_mode(string s);
    assert (s == "def" || s == "rst_i" || s == "rst_o" || s == "rd" || s == "wr")
    else begin
        `uvm_fatal(get_type_name(),
        $sformatf("set_e_mode: invalid e_mode '%s' [ allowed: def / rst_i / rst_o / rd / wr ]", s))
        return;
    end
    // `honeyb("MEM TX", $sformatf("Setting e_mode to: %s...", s)) // Optional || Comment out to reduce log capacity
    e_mode = s;
endfunction // Contains the info for "Which event?"


function void xlr_mem_tx::set_mem(x_mem m);
  // `honeyb("", $sformatf("Setting mem to: MEM[%0d]", mem))
  mem = m;
endfunction // Contains the info for : "Which Mem?"


function void xlr_mem_tx::do_copy(uvm_object rhs);
  xlr_mem_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  super.do_copy(rhs); //| Comminacates:
  mem   = rhs_.mem;   //| Wnich memory?
  e_mode  = rhs_.e_mode;  //| Which Event?
  if (mem == MEMA) begin
    if (e_mode == "def") begin // all signals
      mem_rdata = rhs_.mem_rdata;
      mem_addr  = rhs_.mem_addr; 
      mem_wdata = rhs_.mem_wdata;
      mem_be    = rhs_.mem_be;   
      mem_rd    = rhs_.mem_rd;
      mem_wr    = rhs_.mem_wr; 
    end else if (e_mode == "rst_i") begin // input signal
      mem_rdata = rhs_.mem_rdata;
    end else if (e_mode == "rst_o") begin // outputs signals
      mem_addr  = rhs_.mem_addr; 
      mem_wdata = rhs_.mem_wdata;
      mem_be    = rhs_.mem_be;   
      mem_rd    = rhs_.mem_rd;   
      mem_wr    = rhs_.mem_wr;
    end else if (e_mode == "rd") begin // read signals
      mem_rd    = rhs_.mem_rd;
      mem_addr  = rhs_.mem_addr; 
      mem_rdata = rhs_.mem_rdata;
    end else if (e_mode == "wr") begin // write signals
      mem_wr    = rhs_.mem_wr; 
      mem_addr  = rhs_.mem_addr;
      mem_be    = rhs_.mem_be;
      mem_wdata = rhs_.mem_wdata;
    end
  end else begin
    if (e_mode == "def") begin
      mem_rdata [int'(mem)] = rhs_.mem_rdata [int'(mem)];
      mem_addr  [int'(mem)] = rhs_.mem_addr  [int'(mem)]; 
      mem_wdata [int'(mem)] = rhs_.mem_wdata [int'(mem)];
      mem_be    [int'(mem)] = rhs_.mem_be    [int'(mem)];   
      mem_rd    [int'(mem)] = rhs_.mem_rd    [int'(mem)];
      mem_wr    [int'(mem)] = rhs_.mem_wr    [int'(mem)]; 
    end else if (e_mode == "rst_i") begin
      mem_rdata [int'(mem)] = rhs_.mem_rdata [int'(mem)];
    end else if (e_mode == "rst_o") begin
      mem_addr  [int'(mem)] = rhs_.mem_addr  [int'(mem)]; 
      mem_wdata [int'(mem)] = rhs_.mem_wdata [int'(mem)];
      mem_be    [int'(mem)] = rhs_.mem_be    [int'(mem)];   
      mem_rd    [int'(mem)] = rhs_.mem_rd    [int'(mem)];   
      mem_wr    [int'(mem)] = rhs_.mem_wr    [int'(mem)];
    end else if (e_mode == "rd") begin
      mem_rd    [int'(mem)] = rhs_.mem_rd    [int'(mem)];
      mem_addr  [int'(mem)] = rhs_.mem_addr  [int'(mem)]; 
      mem_rdata [int'(mem)] = rhs_.mem_rdata [int'(mem)];
    end else if (e_mode == "wr") begin
      mem_wr    [int'(mem)] = rhs_.mem_wr    [int'(mem)]; 
      mem_addr  [int'(mem)] = rhs_.mem_addr  [int'(mem)];
      mem_be    [int'(mem)] = rhs_.mem_be    [int'(mem)];
      mem_wdata [int'(mem)] = rhs_.mem_wdata [int'(mem)];
    end
  end
endfunction : do_copy

function void xlr_mem_tx::calcopy(x_mem to_mem, x_mem from_mem);
  if (e_mode == "def") begin
      mem_rdata [int'(to_mem)] = mem_rdata [int'(from_mem)];
      mem_addr  [int'(to_mem)] = mem_addr  [int'(from_mem)]; 
      mem_wdata [int'(to_mem)] = mem_wdata [int'(from_mem)];
      mem_be    [int'(to_mem)] = mem_be    [int'(from_mem)];   
      mem_rd    [int'(to_mem)] = mem_rd    [int'(from_mem)];
      mem_wr    [int'(to_mem)] = mem_wr    [int'(from_mem)];
    end else if (e_mode == "rst_i") begin
      mem_rdata [int'(to_mem)] = mem_rdata [int'(from_mem)];
    end else if (e_mode == "rst_o") begin
      mem_addr  [int'(to_mem)] = mem_addr  [int'(from_mem)]; 
      mem_wdata [int'(to_mem)] = mem_wdata [int'(from_mem)];
      mem_be    [int'(to_mem)] = mem_be    [int'(from_mem)];   
      mem_rd    [int'(to_mem)] = mem_rd    [int'(from_mem)];   
      mem_wr    [int'(to_mem)] = mem_wr    [int'(from_mem)];
    end else if (e_mode == "rd") begin
      mem_rd    [int'(to_mem)] = mem_rd    [int'(from_mem)];
      mem_addr  [int'(to_mem)] = mem_addr  [int'(from_mem)]; 
      mem_rdata [int'(to_mem)] = mem_rdata [int'(from_mem)];
    end else if (e_mode == "wr") begin
      mem_wr    [int'(to_mem)] = mem_wr    [int'(from_mem)]; 
      mem_addr  [int'(to_mem)] = mem_addr  [int'(from_mem)];
      mem_be    [int'(to_mem)] = mem_be    [int'(from_mem)];
      mem_wdata [int'(to_mem)] = mem_wdata [int'(from_mem)];
    end
endfunction // Copy Calculated Data Between Memories

function bit xlr_mem_tx::do_compare(uvm_object rhs, uvm_comparer comparer); // EXCLUDED - Input signals
    bit result;
    xlr_mem_tx rhs_;
    if (!$cast(rhs_, rhs))
        `uvm_fatal("", "Cast of rhs object failed")
    result = super.do_compare(rhs, comparer);
    result &= comparer.compare_field  ("mem" , int'(mem), int'(rhs_.mem),  $bits(x_mem));
    result &= comparer.compare_string ("e_mode", e_mode     , rhs_.e_mode);
    if (mem == MEMA) begin
        if (e_mode == "def") begin // all signals - DEFAULT EVENT
            result &= comparer.compare_field("mem_rdata", mem_rdata , rhs_.mem_rdata  , $bits(mem_rdata ));
            result &= comparer.compare_field("mem_addr" , mem_addr  , rhs_.mem_addr   , $bits(mem_addr  ));
            result &= comparer.compare_field("mem_wdata", mem_wdata , rhs_.mem_wdata  , $bits(mem_wdata ));
            result &= comparer.compare_field("mem_be"   , mem_be    , rhs_.mem_be     , $bits(mem_be    ));
            result &= comparer.compare_field("mem_rd"   , mem_rd    , rhs_.mem_rd     , $bits(mem_rd    ));
            result &= comparer.compare_field("mem_wr"   , mem_wr    , rhs_.mem_wr     , $bits(mem_wr    ));
        end else if (e_mode == "rst_i" ) begin // rst_n for input
            result &= comparer.compare_field("mem_rdata", mem_rdata , rhs_.mem_rdata  , $bits(mem_rdata ));
        end else if (e_mode == "rst_o") begin // rst_n for outputs
            result &= comparer.compare_field("mem_addr" , mem_addr  , rhs_.mem_addr   , $bits(mem_addr  ));
            result &= comparer.compare_field("mem_wdata", mem_wdata , rhs_.mem_wdata  , $bits(mem_wdata ));
            result &= comparer.compare_field("mem_be"   , mem_be    , rhs_.mem_be     , $bits(mem_be    ));
            result &= comparer.compare_field("mem_rd"   , mem_rd    , rhs_.mem_rd     , $bits(mem_rd    ));
            result &= comparer.compare_field("mem_wr"   , mem_wr    , rhs_.mem_wr     , $bits(mem_wr    ));
        end else if (e_mode == "rd") begin // read event
            result &= comparer.compare_field("mem_rd"   , mem_rd    , rhs_.mem_rd     , $bits(mem_rd    )); // rd req
            result &= comparer.compare_field("mem_addr" , mem_addr  , rhs_.mem_addr   , $bits(mem_addr  )); // address
            result &= comparer.compare_field("mem_rdata", mem_rdata , rhs_.mem_rdata  , $bits(mem_rdata )); // rdata
        end else if (e_mode == "wr") begin // write event
            result &= comparer.compare_field("mem_wr"   , mem_wr    , rhs_.mem_wr     , $bits(mem_wr    )); // wr req
            result &= comparer.compare_field("mem_addr" , mem_addr  , rhs_.mem_addr   , $bits(mem_addr  )); // addr
            result &= comparer.compare_field("mem_be"   , mem_be    , rhs_.mem_be     , $bits(mem_be    )); // bit en
            result &= comparer.compare_field("mem_wdata", mem_wdata , rhs_.mem_wdata  , $bits(mem_wdata )); // wdata
        end
    end else begin
        if (e_mode == "def") begin // all signals - DEFAULT EVENT
            result &= comparer.compare_field($sformatf("mem_rdata[%0d]" , int'(mem)), mem_rdata [int'(mem)], rhs_.mem_rdata [int'(mem)], $bits(mem_rdata  [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_addr[%0d]"  , int'(mem)), mem_addr  [int'(mem)], rhs_.mem_addr  [int'(mem)], $bits(mem_addr   [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_wdata[%0d]" , int'(mem)), mem_wdata [int'(mem)], rhs_.mem_wdata [int'(mem)], $bits(mem_wdata  [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_be[%0d]"    , int'(mem)), mem_be    [int'(mem)], rhs_.mem_be    [int'(mem)], $bits(mem_be     [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_rd[%0d]"    , int'(mem)), mem_rd    [int'(mem)], rhs_.mem_rd    [int'(mem)], $bits(mem_rd     [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_wr[%0d]"    , int'(mem)), mem_wr    [int'(mem)], rhs_.mem_wr    [int'(mem)], $bits(mem_wr     [int'(mem)]));
        end else if (e_mode == "rst_i") begin // rst_n for inputs
            result &= comparer.compare_field($sformatf("mem_rdata[%0d]" , int'(mem)), mem_rdata [int'(mem)], rhs_.mem_rdata [int'(mem)], $bits(mem_rdata  [int'(mem)]));
        end else if (e_mode == "rst_o") begin // rst_n for outputs
            result &= comparer.compare_field($sformatf("mem_addr[%0d]"  , int'(mem)), mem_addr  [int'(mem)], rhs_.mem_addr  [int'(mem)], $bits(mem_addr   [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_wdata[%0d]" , int'(mem)), mem_wdata [int'(mem)], rhs_.mem_wdata [int'(mem)], $bits(mem_wdata  [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_be[%0d]"    , int'(mem)), mem_be    [int'(mem)], rhs_.mem_be    [int'(mem)], $bits(mem_be     [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_rd[%0d]"    , int'(mem)), mem_rd    [int'(mem)], rhs_.mem_rd    [int'(mem)], $bits(mem_rd     [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_wr[%0d]"    , int'(mem)), mem_wr    [int'(mem)], rhs_.mem_wr    [int'(mem)], $bits(mem_wr     [int'(mem)]));
        end else if (e_mode == "rd") begin // read event
            result &= comparer.compare_field($sformatf("mem_rd[%0d]"    , int'(mem)), mem_rd    [int'(mem)], rhs_.mem_rd    [int'(mem)], $bits(mem_rd     [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_addr[%0d]"  , int'(mem)), mem_addr  [int'(mem)], rhs_.mem_addr  [int'(mem)], $bits(mem_addr   [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_rdata[%0d]" , int'(mem)), mem_rdata [int'(mem)], rhs_.mem_rdata [int'(mem)], $bits(mem_rdata  [int'(mem)]));
        end else if (e_mode == "wr") begin // write event
            result &= comparer.compare_field($sformatf("mem_wr[%0d]"    , int'(mem)), mem_wr    [int'(mem)], rhs_.mem_wr    [int'(mem)], $bits(mem_wr     [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_addr[%0d]"  , int'(mem)), mem_addr  [int'(mem)], rhs_.mem_addr  [int'(mem)], $bits(mem_addr   [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_be[%0d]"    , int'(mem)), mem_be    [int'(mem)], rhs_.mem_be    [int'(mem)], $bits(mem_be     [int'(mem)]));
            result &= comparer.compare_field($sformatf("mem_wdata[%0d]" , int'(mem)), mem_wdata [int'(mem)], rhs_.mem_wdata [int'(mem)], $bits(mem_wdata  [int'(mem)]));
        end
    end
    return result;
endfunction : do_compare


function void xlr_mem_tx::do_print(uvm_printer printer);
    if (printer.knobs.sprint == 0) begin
        `uvm_info(get_type_name(), convert2string(), UVM_MEDIUM)
    end else begin
        if (e_mode == "def") begin // all signals - DEFAULT EVENT
            printer.m_string = convert2string();
        end else if (e_mode == "rst_i" ) begin // rst_n for inputs
            printer.m_string = convert2string_in();
        end else if (e_mode == "rst_o") begin // rst_n for outputs
            printer.m_string = convert2string_out();
        end else if (e_mode == "rd" ) begin // read event
            printer.m_string = convert2string_rd();
        end else if (e_mode == "wr" ) begin // write event
            printer.m_string = convert2string_wr();
        end
    end
endfunction : do_print


function void xlr_mem_tx::do_record(uvm_recorder recorder);
  super.do_record(recorder);
  // Use the record macros to record the item fields:
  `uvm_record_field ("mem"       , int'(mem) )
  `uvm_record_string("e_mode"      , e_mode  )
  `uvm_record_field ("mem_rdata" , mem_rdata )
  `uvm_record_field ("mem_addr"  , mem_addr  ) 
  `uvm_record_field ("mem_wdata" , mem_wdata )
  `uvm_record_field ("mem_be"    , mem_be    )   
  `uvm_record_field ("mem_rd"    , mem_rd    )   
  `uvm_record_field ("mem_wr"    , mem_wr    )   
endfunction : do_record


function void xlr_mem_tx::do_pack(uvm_packer packer);
  super.do_pack     (packer    );
  `uvm_pack_int     (mem_rdata ) 
  `uvm_pack_int     (mem_addr  )  
  `uvm_pack_int     (mem_wdata ) 
  `uvm_pack_int     (mem_be    )    
  `uvm_pack_int     (mem_rd    )    
  `uvm_pack_int     (mem_wr    )    
endfunction : do_pack


function void xlr_mem_tx::do_unpack(uvm_packer packer);
  super.do_unpack   (packer    );
  `uvm_unpack_int   (mem_rdata ) 
  `uvm_unpack_int   (mem_addr  )  
  `uvm_unpack_int   (mem_wdata ) 
  `uvm_unpack_int   (mem_be    )    
  `uvm_unpack_int   (mem_rd    )    
  `uvm_unpack_int   (mem_wr    )    
endfunction : do_unpack


function string xlr_mem_tx::convert2string(); // DEFAULT - print all
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    $sformat(s, {"%s", "\t[EVENT](DEFAULT):\n", PD}, s);
    for (int mem_idx=0; mem_idx<int'(MEMA); mem_idx++) begin
      // Separator
      $sformat(s, {"%s",
        "=========================================================================\n\n", PD,
        "mem_rdata [%0d] = 'h%0h\n", PD, 
        "mem_addr  [%0d] = 'h%0h\n", PD, 
        "mem_wdata [%0d] = 'h%0h\n", PD,
        "mem_be    [%0d] = 'h%0h\n", PD,
        "mem_rd    [%0d] = 'h%0h\n", PD,
        "mem_wr    [%0d] = 'h%0h\n\n"}, s,
        mem_idx, mem_rdata [mem_idx], 
        mem_idx, mem_addr  [mem_idx],
        mem_idx, mem_wdata [mem_idx],
        mem_idx, mem_be    [mem_idx], 
        mem_idx, mem_rd    [mem_idx], 
        mem_idx, mem_wr    [mem_idx]);
      
      if (mem_idx < int'(MEMA) - 1) $sformat(s, {"%s", PD}, s);
    end
  end else begin
    $sformat(s, {"%s", "\t[EVENT](DEFAULT):\n", PD,
      "=========================================================================\n\n", PD,
      "mem_rdata [%0d] = 'h%0h\n", PD,
      "mem_addr  [%0d] = 'h%0h\n", PD,
      "mem_wdata [%0d] = 'h%0h\n", PD,
      "mem_be    [%0d] = 'h%0h\n", PD,
      "mem_rd    [%0d] = 'h%0h\n", PD,
      "mem_wr    [%0d] = 'h%0h\n\n"}, s,
      int'(mem), mem_rdata [int'(mem)],
      int'(mem), mem_addr  [int'(mem)],
      int'(mem), mem_wdata [int'(mem)],
      int'(mem), mem_be    [int'(mem)],
      int'(mem), mem_rd    [int'(mem)],
      int'(mem), mem_wr    [int'(mem)]);
  end
  return s;
endfunction : convert2string


function string xlr_mem_tx::convert2string_in(); // print inputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    
    $sformat(s, {"%s", "\t[EVENT](INPUT_RESET):\n", PD}, s);
    for (int mem_idx=0; mem_idx<int'(MEMA); mem_idx++) begin
      // Separator
      $sformat(s, {"%s",
        "=========================================================================\n\n", PD,
        "mem_rdata [%0d] = 'h%0h\n\n"}, s,
        mem_idx, mem_rdata [mem_idx]);

      if (mem_idx < int'(MEMA) - 1) $sformat(s, {"%s", PD}, s);
    end
  end else begin
    $sformat(s, {"%s", "\t[EVENT](INPUT_RESET):\n", PD,
      "=========================================================================\n\n", PD,
      "mem_rdata [%0d] = 'h%0h\n\n"}, s,
      int'(mem), mem_rdata[int'(mem)]);
  end
  return s;
endfunction : convert2string_in


function string xlr_mem_tx::convert2string_out(); // print rst_n for outputs event
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    $sformat(s, {"%s", "\t[EVENT](OUTPUT_RESET):\n", PD}, s);
    for (int mem_idx=0; mem_idx<int'(MEMA); mem_idx++) begin
      // Separator
      $sformat(s, {"%s",
        "=========================================================================\n\n", PD, 
        "mem_addr  [%0d] = 'h%0h\n", PD, 
        "mem_wdata [%0d] = 'h%0h\n", PD,
        "mem_be    [%0d] = 'h%0h\n", PD,
        "mem_rd    [%0d] = 'h%0h\n", PD,
        "mem_wr    [%0d] = 'h%0h\n\n"}, s,
        mem_idx, mem_addr  [mem_idx],
        mem_idx, mem_wdata [mem_idx],
        mem_idx, mem_be    [mem_idx], 
        mem_idx, mem_rd    [mem_idx], 
        mem_idx, mem_wr    [mem_idx]);
      
      if (mem_idx < int'(MEMA) - 1) $sformat(s, {"%s", PD}, s);
    end
  end else begin
    $sformat(s, {"%s", "\t[EVENT](OUTPUT_RESET):\n", PD,
      "=========================================================================\n\n", PD,
      "mem_addr  [%0d] = 'h%0h\n", PD,
      "mem_wdata [%0d] = 'h%0h\n", PD,
      "mem_be    [%0d] = 'h%0h\n", PD,
      "mem_rd    [%0d] = 'h%0h\n", PD,
      "mem_wr    [%0d] = 'h%0h\n\n"}, s,
      int'(mem), mem_addr [int'(mem)],
      int'(mem), mem_wdata[int'(mem)],
      int'(mem), mem_be   [int'(mem)],
      int'(mem), mem_rd   [int'(mem)],
      int'(mem), mem_wr   [int'(mem)]);
  end
  return s;
endfunction : convert2string_out

function string xlr_mem_tx::convert2string_rd(); // print read operation
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    $sformat(s, {"%s", "\t[EVENT](DUT_READ):\n", PD}, s);
    for (int mem_idx=0; mem_idx<int'(MEMA); mem_idx++) begin
      // Separator
      $sformat(s, {"%s",
        "=========================================================================\n\n", PD,
        "mem_rdata [%0d] = 'h%0h\n", PD, 
        "mem_addr  [%0d] = 'h%0h\n", PD, 
        "mem_rd    [%0d] = 'h%0h\n\n"}, s,
        mem_idx, mem_rdata [mem_idx], 
        mem_idx, mem_addr  [mem_idx],
        mem_idx, mem_rd    [mem_idx]);
      
      if (mem_idx < int'(MEMA) - 1) $sformat(s, {s, PD});
    end
  end else begin
    $sformat(s, {"%s","\t[EVENT](DUT_READ):\n", PD,
      "=========================================================================\n\n", PD,
      "mem_rd    [%0d] = 'h%0h\n", PD,
      "mem_addr  [%0d] = 'h%0h\n", PD,
      "mem_be    [%0d] = 'h%0h\n", PD,
      "mem_rdata [%0d] = 'h%0h\n\n"}, s,
      int'(mem), mem_rd    [int'(mem)],
      int'(mem), mem_addr  [int'(mem)],
      int'(mem), mem_be    [int'(mem)],
      int'(mem), mem_rdata [int'(mem)]);
  end
  return s;
endfunction : convert2string_rd

function string xlr_mem_tx::convert2string_wr(); // print write operation
  string s;
  $sformat(s, "%s\n", super.convert2string());
  if (mem == MEMA) begin
    $sformat(s, {"%s", "\t[EVENT](DUT_WRITE):\n", PD}, s);
    for (int mem_idx=0; mem_idx<int'(MEMA); mem_idx++) begin
      // Separator
      $sformat(s, {"%s",
        "=========================================================================\n\n", PD,
        "mem_wr    [%0d] = 'h%0h\n", PD,
        "mem_addr  [%0d] = 'h%0h\n", PD,
        "mem_be    [%0d] = 'h%0h\n", PD,
        "mem_wdata [%0d] = 'h%0h\n\n"}, s,
        mem_idx, mem_wr   [mem_idx],
        mem_idx, mem_addr [mem_idx],
        mem_idx, mem_be   [mem_idx],
        mem_idx, mem_wdata[mem_idx]);
      
      if (mem_idx < int'(MEMA) - 1) $sformat(s, {"%s", PD}, s);
    end
  end else begin
    $sformat(s, {"%s","\t[EVENT](DUT_WRITE):\n", PD,
      "=========================================================================\n\n", PD,
      "mem_wr    [%0d] = 'h%0h\n", PD,
      "mem_addr  [%0d] = 'h%0h\n", PD,
      "mem_be    [%0d] = 'h%0h\n", PD,
      "mem_wdata [%0d] = 'h%0h\n\n"}, s,
      int'(mem), mem_wr   [int'(mem)],
      int'(mem), mem_addr [int'(mem)],
      int'(mem), mem_be   [int'(mem)],
      int'(mem), mem_wdata[int'(mem)]);
  end
  return s;
endfunction : convert2string_wr
`endif // XLR_MEM_SEQ_ITEM_SV
