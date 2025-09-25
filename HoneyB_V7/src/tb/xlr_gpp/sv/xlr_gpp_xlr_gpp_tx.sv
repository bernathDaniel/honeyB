//=============================================================================
// Project    : HoneyB V7
// File Name  : xlr_gpp_xlr_gpp_tx.sv
//=============================================================================
// Description: Sequence item for xlr_gpp_sequencer
  //
  //              This tx class contains the following special methods:
  //              print(), copy(), compare(), record(), unpack(), pack()
  //
  //              Special *context* feature "e_mode select" :
  //              The **Event** mode select allows you to
  //              choose context of triggered event for improved
  //              communication across the ecosystem:
  //
  //              how to use e_mode select :
  //                             tx.set_e_mode("<chosen_e_mode>");
  //                             tx.print(); (example for using print method)
  //
  //              possible e_modes :
  //                            | def || rst_i || rst_o || start || busy || done |
//=============================================================================

`ifndef XLR_GPP_XLR_GPP_TX_SV
`define XLR_GPP_XLR_GPP_TX_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_gpp_tx extends uvm_sequence_item; 

  `uvm_object_utils(xlr_gpp_tx)

  string e_mode = "def"; // default e_mode is def (can be def / rst_i / rst_o / start / busy / done)

  func_mode f_mode = MATMUL; // default f_mode is MATMUL (can be CALCOPY) 

  // Transaction variables
  rand logic  [31:0][31:0] host_regsi;
  rand logic  [31:0]       host_regs_valid; // In

  logic       [31:0][31:0] host_regso;
  logic       [31:0]       host_regso_valid; // Out
  
  constraint c_gpp_data {
    host_regsi[START_IDX_REG] == 32'h1;
  }

  constraint c_gpp_nullr { 
    foreach (host_regsi[i])
      if ( i >= 1 && i <= 31 )
        host_regsi[i] == 32'h0;
  }

  constraint c_gpp_valid_data {
    host_regs_valid[START_IDX_REG] == 1'b1;
  }

  extern function new(string name = "");

  extern function void    set_e_mode(string s);
  extern function void    set_f_mode(func_mode f);
  extern function void    op_flush();
  extern function void    do_copy   (uvm_object rhs);
  extern function bit     do_compare(uvm_object rhs, uvm_comparer comparer);
  extern function void    do_print  (uvm_printer printer);
  extern function void    do_record (uvm_recorder recorder);
  extern function void    do_pack   (uvm_packer packer);
  extern function void    do_unpack (uvm_packer packer);
  extern function string  convert2string();
  extern function string  convert2string_rst_i();
  extern function string  convert2string_rst_o();
  extern function string  convert2string_start();
  extern function string  convert2string_busy();
  extern function string  convert2string_done();
endclass : xlr_gpp_tx 


function xlr_gpp_tx::new(string name = "");
  super.new(name);
endfunction // Boilerplate


function void xlr_gpp_tx::set_e_mode(string s); // can be -> def / rst_i / rst_o / start / busy / done)
  assert (s == "def" || s == "rst_i" || s == "rst_o" || s == "start" || s == "busy" || s == "done")
    else begin
      `uvm_fatal(get_type_name(),
      $sformatf("set_e_mode: invalid e_mode '%s'! [ allowed: def / rst_i / rst_o / start / busy / done ]", s))
      return;
    end
  // `honeyb("GPP TX", $sformatf("Setting e_mode to: %s...", s)) // Optional || Comment out to reduce log capacity
  e_mode = s;
endfunction : set_e_mode


function void xlr_gpp_tx::set_f_mode(func_mode f); // can be -> MATMUL / CALCOPY
  // `honeyb("", $sformatf("Setting f_mode to: MEM[%0d]", f_mode))
  f_mode = f;
endfunction


function void xlr_gpp_tx::op_flush();
  assert(e_mode == "rst_o" || e_mode == "busy")
  else begin
    `uvm_fatal(get_type_name(),
      $sformatf("op_flush: invalid e_mode '%s' [allowed: rst_o/busy]", e_mode))
      return;
  end
  host_regso       = '0;
  host_regso_valid = '0;
                    // Busy Always Valid
  host_regso_valid[BUSY_IDX_REG] = 1'b1;
endfunction


function void xlr_gpp_tx::do_copy(uvm_object rhs);
  xlr_gpp_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal(get_type_name(), "Cast of rhs object failed")
  super.do_copy(rhs);
  e_mode = rhs_.e_mode;
  f_mode = rhs_.f_mode;
  // Event-specific field copying
  if (e_mode == "rst_i") begin                      // inputs only
    host_regsi                      = rhs_.host_regsi;
    host_regs_valid                 = rhs_.host_regs_valid;
  end else if (e_mode == "rst_o"  ) begin           // outputs only
    host_regso                      = rhs_.host_regso;
    host_regso_valid                = rhs_.host_regso_valid;
  end else if (e_mode == "def"    ) begin           // both
    host_regsi                      = rhs_.host_regsi;
    host_regs_valid                 = rhs_.host_regs_valid;
    host_regso                      = rhs_.host_regso;
    host_regso_valid                = rhs_.host_regso_valid;
  end else if (e_mode == "start"  ) begin           // start signal
    host_regsi      [START_IDX_REG] = rhs_.host_regsi       [START_IDX_REG];
    host_regs_valid [START_IDX_REG] = rhs_.host_regs_valid  [START_IDX_REG];
  end else if (e_mode == "busy"   ) begin           // busy signal
    host_regso      [BUSY_IDX_REG ] = rhs_.host_regso       [BUSY_IDX_REG ];
    host_regso_valid[BUSY_IDX_REG ] = rhs_.host_regso_valid [BUSY_IDX_REG ];
  end else if (e_mode == "done"   ) begin           // done signal
    host_regso      [DONE_IDX_REG ] = rhs_.host_regso       [DONE_IDX_REG ];
    host_regso_valid[DONE_IDX_REG ] = rhs_.host_regso_valid [DONE_IDX_REG ];
  end
endfunction : do_copy


function bit xlr_gpp_tx::do_compare(uvm_object rhs, uvm_comparer comparer); // Note - Excluding the input signals
  bit result;
  xlr_gpp_tx rhs_;
  if (!$cast(rhs_, rhs))
    `uvm_fatal("", "Cast of rhs object failed")
  result = super.do_compare(rhs, comparer);
    if (e_mode == "rst_i") begin        // inputs only
    result &= comparer.compare_field("host_regsi"     , host_regsi      ,   rhs_.host_regsi     ,  $bits(host_regsi     ));
    result &= comparer.compare_field("host_regs_valid", host_regs_valid ,   rhs_.host_regs_valid,  $bits(host_regs_valid));
  end else if (e_mode == "rst_o") begin // outputs only
    result &= comparer.compare_field("host_regso      [BUSY_IDX_REG]" , host_regso      [BUSY_IDX_REG], rhs_.host_regso      [BUSY_IDX_REG], $bits(host_regso      [BUSY_IDX_REG]));
    result &= comparer.compare_field("host_regso_valid[BUSY_IDX_REG]" , host_regso_valid[BUSY_IDX_REG], rhs_.host_regso_valid[BUSY_IDX_REG], $bits(host_regso_valid[BUSY_IDX_REG]));
    result &= comparer.compare_field("host_regso      [DONE_IDX_REG]" , host_regso      [DONE_IDX_REG], rhs_.host_regso      [DONE_IDX_REG], $bits(host_regso      [DONE_IDX_REG]));
    result &= comparer.compare_field("host_regso_valid[DONE_IDX_REG]" , host_regso_valid[DONE_IDX_REG], rhs_.host_regso_valid[DONE_IDX_REG], $bits(host_regso_valid[DONE_IDX_REG]));
  end else if (e_mode == "def") begin   // all
    result &= comparer.compare_field("host_regsi"     , host_regsi     ,   rhs_.host_regsi     ,  $bits(host_regsi     ));
    result &= comparer.compare_field("host_regs_valid", host_regs_valid,   rhs_.host_regs_valid,  $bits(host_regs_valid));
    result &= comparer.compare_field("host_regso"      , host_regso      , rhs_.host_regso      , $bits(host_regso      ));
    result &= comparer.compare_field("host_regso_valid", host_regso_valid, rhs_.host_regso_valid, $bits(host_regso_valid));
  end else if (e_mode == "start") begin   // start signal
    result &= comparer.compare_field("host_regsi"     , host_regsi      [START_IDX_REG],   rhs_.host_regsi      [START_IDX_REG],  $bits(host_regsi      [START_IDX_REG]));
    result &= comparer.compare_field("host_regs_valid", host_regs_valid [START_IDX_REG],   rhs_.host_regs_valid [START_IDX_REG],  $bits(host_regs_valid [START_IDX_REG]));
  end else if (e_mode == "busy") begin    // busy signal
    result &= comparer.compare_field("host_regso      [BUSY_IDX_REG]", host_regso      [BUSY_IDX_REG], rhs_.host_regso      [BUSY_IDX_REG], $bits(host_regso      [BUSY_IDX_REG]));
    result &= comparer.compare_field("host_regso_valid[BUSY_IDX_REG]", host_regso_valid[BUSY_IDX_REG], rhs_.host_regso_valid[BUSY_IDX_REG], $bits(host_regso_valid[BUSY_IDX_REG]));
  end else if (e_mode == "done") begin    // done signal
    result &= comparer.compare_field("host_regso      [DONE_IDX_REG]", host_regso      [DONE_IDX_REG], rhs_.host_regso      [DONE_IDX_REG], $bits(host_regso      [DONE_IDX_REG]));
    result &= comparer.compare_field("host_regso_valid[DONE_IDX_REG]", host_regso_valid[DONE_IDX_REG], rhs_.host_regso_valid[DONE_IDX_REG], $bits(host_regso_valid[DONE_IDX_REG]));
  end
  return result;
endfunction : do_compare


function void xlr_gpp_tx::do_print(uvm_printer printer);
    if (printer.knobs.sprint == 0) begin
    `uvm_info(get_type_name(), convert2string(), UVM_MEDIUM)
  end else begin
    if (e_mode == "rst_i") begin                  // inputs only
      printer.m_string = convert2string_rst_i();
    end else if (e_mode == "rst_o") begin         // outputs only
      printer.m_string = convert2string_rst_o();
    end else if (e_mode == "def") begin           // both I/Os
      printer.m_string = convert2string();
    end else if (e_mode == "start") begin         // start signal
      printer.m_string = convert2string_start();
    end else if (e_mode == "busy") begin          // busy signal
      printer.m_string = convert2string_busy();
    end else if (e_mode == "done") begin          // done signal
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
  $sformat(s, { "%s", "[EVENT](DEFAULT):\n",
    "\thost_regsi       = 'h%0h\n", 
    "\thost_regs_valid  = 'h%0h\n", 
    "\thost_regso       = 'h%0h\n", 
    "\thost_regso_valid = 'h%0h\n\n"}, s,
    host_regsi, host_regs_valid, host_regso, host_regso_valid);
  return s;
endfunction : convert2string


function string xlr_gpp_tx::convert2string_rst_i(); // print inputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, { "%s", "[EVENT](INPUT_RESET):\n",
    "\thost_regsi       = 'h%0h\n", 
    "\thost_regs_valid  = 'h%0h\n\n"}, s,
    host_regsi, host_regs_valid);
  return s;
endfunction : convert2string_rst_i


function string xlr_gpp_tx::convert2string_rst_o(); // print outputs
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, { "%s", "[EVENT](OUTPUT_RESET):\n",
    "\thost_regso       = 'h%0h\n", 
    "\thost_regso_valid = 'h%0h\n\n"}, s,
    host_regso, host_regso_valid);
  return s;
endfunction : convert2string_rst_o


function string xlr_gpp_tx::convert2string_start(); // print start signal
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, { "%s", "[EVENT](START):\n",
    "\thost_regsi     [START_IDX_REG]  = 'h%0h\n", 
    "\thost_regs_valid[START_IDX_REG]  = 'h%0h\n\n"}, s,
    host_regsi[START_IDX_REG], host_regs_valid[START_IDX_REG]);
  return s;
endfunction : convert2string_start


function string xlr_gpp_tx::convert2string_busy(); // print busy signal
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, { "%s", "[EVENT](BUSY):\n",
    "\thost_regso      [BUSY_IDX_REG] = 'h%0h\n", 
    "\thost_regso_valid[BUSY_IDX_REG] = 'h%0h\n\n"}, s,
    host_regso[BUSY_IDX_REG], host_regso_valid[BUSY_IDX_REG]);
  return s;
endfunction : convert2string_busy


function string xlr_gpp_tx::convert2string_done(); // print done signal
  string s;
  $sformat(s, "%s\n", super.convert2string());
  $sformat(s, { "%s", "[EVENT](DONE):\n",
    "\thost_regso      [DONE_IDX_REG] = 'h%0h\n", 
    "\thost_regso_valid[DONE_IDX_REG] = 'h%0h\n\n"}, s,
    host_regso[DONE_IDX_REG], host_regso_valid[DONE_IDX_REG]);
  return s;
endfunction : convert2string_done

`endif // XLR_GPP_XLR_GPP_TX_SV


//===============
//    EXTRAS
//===============
  /*

  constraint c_gpp_valid_null { // this is unnecessary
    host_regs_valid[31:1] inside 31'd0;
  }
  
  constraint c_gpp_valid_data_dist {
    host_regs_valid[START_IDX_REG] dist {1'b0 := 1, 1'b1 := 5};
    host_regsi[START_IDX_REG][0] dist {1'b0 := 1, 1'b1 := 5};
  }

  */