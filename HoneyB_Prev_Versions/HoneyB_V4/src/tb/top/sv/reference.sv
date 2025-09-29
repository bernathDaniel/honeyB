//=============================================================================
// Project  : HoneyB V4
// File Name: reference.sv
//=============================================================================
// Description: Reference model for use with xlr_scoreboard
//=============================================================================

`ifndef REFERENCE_SV
`define REFERENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

`uvm_analysis_imp_decl(_reference_mem)
`uvm_analysis_imp_decl(_reference_gpp)

class reference extends uvm_component;
  `uvm_component_utils(reference)

  uvm_analysis_imp_reference_mem #(xlr_mem_tx, reference) analysis_export_mem; // m_xlr_mem_agent
  uvm_analysis_imp_reference_gpp #(xlr_gpp_tx, reference) analysis_export_gpp; // m_xlr_gpp_agent

  uvm_analysis_port #(xlr_mem_tx) analysis_port_mem; // m_xlr_mem_agent
  uvm_analysis_port #(xlr_gpp_tx) analysis_port_gpp; // m_xlr_gpp_agent

  int mem_iters = 0;

  extern function new(string name, uvm_component parent);

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export_mem = new("analysis_export_mem", this);
    analysis_export_gpp = new("analysis_export_gpp", this);
    analysis_port_mem   = new("analysis_port_mem",   this);
    analysis_port_gpp   = new("analysis_port_gpp",   this);
  endfunction : build_phase

  extern function void write_reference_mem(input xlr_mem_tx t);
  extern function void write_reference_gpp(input xlr_gpp_tx t);

  extern function void send_xlr_mem_input(xlr_mem_tx t);
  extern function void send_xlr_gpp_input(xlr_gpp_tx t);
endclass : reference


function reference::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


function void reference::write_reference_mem(xlr_mem_tx t);
  send_xlr_mem_input(t);
endfunction : write_reference_mem
  
function void reference::write_reference_gpp(xlr_gpp_tx t);
  send_xlr_gpp_input(t);
endfunction : write_reference_gpp

function void reference::send_xlr_mem_input(xlr_mem_tx t);
  
   /* The DFC Rule: Declare it, Factorize it, Copy it:
 -------------------------------------------------------                                                                                                  */ 
  xlr_mem_tx tx;                                      // Declare
  tx = xlr_mem_tx::type_id::create("tx");             // Factorize
  tx.copy(t);                                         /* Copy                                                                                        /*
 -------------------------------------------------------                                                                                                  */

  // Update Statement
  `honeyb("MEM REF", "TX Received...")
  tx.print();                                                                                                                                             /*
  ------------------------------------------------------                                                                                                  */
  if (tx.mem_rd[tx.mem] == 1'b1) begin // Read Event

    tx.set_e_mode("wr");
    // Update Statement
    `honeyb("MEM REF", "READ Request Received...", $sformatf("Iteration #%0d", mem_iters++))
    // the expected signals for writing back
    tx.mem_be   [tx.mem] = 32'hFFFFFFFF; // En all bits for writing.
    tx.mem_wr   [tx.mem] = 1'b1;
    tx.mem_addr [tx.mem] = 8'h01; // Write res into addr[1]

  /* Calculation of 2x2 MatMul
 -----------------------------------------------------------------
  [tx.mem] = This is the mechanism for generalizing the REF Model
  to handle any selected memory, enabling flexibility & reuse!

  Without it - We're forced to implement things hardcoded, but now
  We can choose to operate on data coming from any memory!
 -----------------------------------------------------------------                                                                                                                          */
    
    tx.mem_wdata[tx.mem][0] = tx,mem_rdata[tx.mem][0]*tx,mem_rdata[tx.mem][4] + tx,mem_rdata[tx.mem][1]*tx,mem_rdata[tx.mem][6];
    tx.mem_wdata[tx.mem][1] = tx,mem_rdata[tx.mem][0]*tx,mem_rdata[tx.mem][5] + tx,mem_rdata[tx.mem][1]*tx,mem_rdata[tx.mem][7];
    tx.mem_wdata[tx.mem][2] = tx,mem_rdata[tx.mem][2]*tx,mem_rdata[tx.mem][4] + tx,mem_rdata[tx.mem][3]*tx,mem_rdata[tx.mem][6];
    tx.mem_wdata[tx.mem][3] = tx,mem_rdata[tx.mem][2]*tx,mem_rdata[tx.mem][5] + tx,mem_rdata[tx.mem][3]*tx,mem_rdata[tx.mem][7];
    
    for ( int i = 4; i < 8; i++ )
      tx.mem_wdata[tx.mem][i] = '0; // last 4 words expected as 0.
    
    analysis_port_mem.write(tx); // broadcast it.
  end else begin
    if (tx.mode = "rst_i") begin // this mode is reserved for rst_n occurences.
      // No Read Req ! Set everything to 0 just like in DUT
      `honeyb("MEM REF Model", "NO READ OR RST_N ASSERTED")
      tx.mem_wdata  = '0;
      tx.mem_be     = '0;
      tx.mem_rd     = '0;
      tx.mem_wr     = '0;
      tx.mem_addr   = '0;
      tx.set_e_mode("rst_o"); // Change to rst_o for comparison with DUT's response while carrying the read data !
      analysis_port_mem.write(tx); // broadcast the rst_n result
    end
  end
endfunction : send_xlr_mem_input

function void reference::send_xlr_gpp_input(xlr_gpp_tx t);
  
  /* The DFC Rule: Declare it, Factorize it, Copy it:
 -------------------------------------------------------                                                                                                  */ 
  xlr_gpp_tx tx;
  tx = xlr_gpp_tx::type_id::create("tx");
  tx.copy(t);                                                                                                                                                                           /*
  ------------------------------------------------------                                                                                                                                  */

  if (tx.host_regsi     [START_IDX_REG] == 32'h1 &&
      tx.host_regs_valid[START_IDX_REG] ==  1'b1      )
  begin

    // Update Statement
    `honeyb("GPP REF Model", "START Received...", "BUSY & DONE TX GEN...")
    tx.host_regso       [BUSY_IDX_REG] = 32'h1;
    tx.host_regso_valid [BUSY_IDX_REG] =  1'b1;

    // "start" -> "busy" conversion:
    //---------------------------------
    tx.set_e_mode("busy");

    // Report Statement
    `honeyb("GPP REF Model", "Sent busy...")
    analysis_port_gpp.write(tx);

  //===========================================================================//

    tx.host_regso       [DONE_IDX_REG] = 32'h1; // done signal
    tx.host_regso_valid [DONE_IDX_REG] =  1'b1; // Valid done.

    tx.host_regso       [BUSY_IDX_REG] = 32'h0; // Flush Busy signal
    tx.host_regso_valid [BUSY_IDX_REG] =  1'b1; // Optionally Redundant, but it's a safeguard

    // "busy" -> "done" conversion:
    //---------------------------------
    tx.set_e_mode("done");

    // Report Statement
    `honeyb("GPP REF Model", "Sent done...")
    analysis_port_gpp.write(tx);

  end else begin // [EVENT](INPUT_RESET) Handling

    tx.host_regso_valid               =   '0;
    tx.host_regso                     =   '0;
    tx.host_regso_valid[BUSY_IDX_REG] = 1'b1; // busy's valid signal always 1'b1 !

    // "rst_i" -> "rst_o" conversion:
    //----------------------------------
    tx.set_e_mode("rst_o"); // [EVENT](OUTPUT_RESET) 

    // Report Statement
    `honeyb("GPP REF Model", "GOT NO START (OR RST_N ASSERTED")
    analysis_port_gpp.write(tx);
  end
endfunction : send_xlr_gpp_input 

`endif // REFERENCE_SV




/************************************************************************************************************************************************************/
//     Extras:
//
//      These messages are redundant and used for UVM Debugging solely, in the future, remove and log inputs only through input monitor!
//     `uvm_info("", $sformatf("A11 = %0d, A12 = %0d, A21 = %0d, A22 = %0d", tx,mem_rdata[0][0], tx,mem_rdata[0][1], tx,mem_rdata[0][2], tx,mem_rdata[0][3]), UVM_MEDIUM);
//     `uvm_info("", $sformatf("B11 = %0d, B12 = %0d, B21 = %0d, B22 = %0d", tx,mem_rdata[0][4], tx,mem_rdata[0][5], tx,mem_rdata[0][6], tx,mem_rdata[0][7]), UVM_MEDIUM);
//     `uvm_info("", $sformatf("Reading from Address: %0d", tx,mem_addr[0]), UVM_MEDIUM);
//
//
//
//