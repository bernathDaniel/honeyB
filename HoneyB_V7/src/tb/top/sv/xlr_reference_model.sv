//=============================================================================
// Project  : HoneyB V7
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

  uvm_analysis_imp_reference_mem#(xlr_mem_tx, reference) analysis_export_mem; // m_xlr_mem_agent
  uvm_analysis_imp_reference_gpp#(xlr_gpp_tx, reference) analysis_export_gpp; // m_xlr_gpp_agent

  uvm_analysis_port #(xlr_mem_tx) analysis_port_mem; // m_xlr_mem_agent
  uvm_analysis_port #(xlr_gpp_tx) analysis_port_gpp; // m_xlr_gpp_agent

  func_mode f_mode = MATMUL; // DEFAULT | MATMUL

  extern function new(string name, uvm_component parent);  
  extern function void build_phase(uvm_phase phase);

  extern function void write_reference_mem(input xlr_mem_tx t);
  extern function void write_reference_gpp(input xlr_gpp_tx t);

  extern function void send_xlr_mem_input(xlr_mem_tx t);
  extern function void send_xlr_gpp_input(xlr_gpp_tx t);
endclass // Boilerplate


function reference::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction // Boilerplate

function void reference::build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export_mem = new("analysis_export_mem", this);
    analysis_export_gpp = new("analysis_export_gpp", this);
    analysis_port_mem   = new("analysis_port_mem",   this);
    analysis_port_gpp   = new("analysis_port_gpp",   this);
endfunction // Boilerplate

function void reference::write_reference_mem(xlr_mem_tx t);
  send_xlr_mem_input(t);
endfunction // Boilerplate
  
function void reference::write_reference_gpp(xlr_gpp_tx t);
  send_xlr_gpp_input(t);
endfunction // Boilerplate

function void reference::send_xlr_mem_input(xlr_mem_tx t);

// The DFC Rule: Declare it, Factorize it, Copy it:
// -------------------------------------------------------
    xlr_mem_tx tx;                                      // Declare
    tx = xlr_mem_tx::type_id::create("tx");             // Factorize
    tx.copy(t);                                         // Copy
// ------------------------------------------------------
  if (tx.e_mode == "rd") begin
    tx.set_e_mode("wr");
    // the expected signals for writing back
    tx.mem_be   [MEM0] = 32'hFFFFFFFF; // Write Gating En
    tx.mem_wr   [MEM0] = 1'b1;
    tx.mem_addr [MEM0] = 8'h01; // Write res into addr[1]
    //-----------------
    tx.mem_be   [MEM1] = '0;
    tx.mem_wr   [MEM1] = '0;
    tx.mem_addr [MEM1] = '0;
    tx.mem_wdata[MEM1] = '0;
    //-----------------
    tx.mem_wdata[MEM0][0] = tx.mem_rdata[MEM0][0]*tx.mem_rdata[MEM0][4] + tx.mem_rdata[MEM0][1]*tx.mem_rdata[MEM0][6];
    tx.mem_wdata[MEM0][1] = tx.mem_rdata[MEM0][0]*tx.mem_rdata[MEM0][5] + tx.mem_rdata[MEM0][1]*tx.mem_rdata[MEM0][7];
    tx.mem_wdata[MEM0][2] = tx.mem_rdata[MEM0][2]*tx.mem_rdata[MEM0][4] + tx.mem_rdata[MEM0][3]*tx.mem_rdata[MEM0][6];
    tx.mem_wdata[MEM0][3] = tx.mem_rdata[MEM0][2]*tx.mem_rdata[MEM0][5] + tx.mem_rdata[MEM0][3]*tx.mem_rdata[MEM0][7];
    //-----------------
    for (int i=4; i<8; i++) tx.mem_wdata[MEM0][i] = '0; // last 4 words expected as 0.
    if  (f_mode == CALCOPY) tx.calcopy(MEM1, MEM0);     // Copying result into MEM1

    `honeyb("REF Model", "READ Request Received: ", "Generating Prediction...")
      //tx.print(); // Report
    analysis_port_mem.write(tx);
  end else if (tx.e_mode == "rst_i") begin
    `honeyb("REF Model", "RESET(MEM) Received: ", "Generating Prediction...")
    tx.set_e_mode("rst_o");
    tx.op_flush();
    analysis_port_mem.write(tx);
  end else `honeyb("REF Model", "Event Mismatch, Check me out!") 
endfunction // Chain of Events: rd -> *FLUSH* -> wr & rst_i -> rst_o

function void reference::send_xlr_gpp_input(xlr_gpp_tx t);

  // The DFC Rule: Declare it, Factorize it, Copy it:
  // -------------------------------------------------------
    xlr_gpp_tx tx;
    tx = xlr_gpp_tx::type_id::create("tx");
    tx.copy(t);
  // -------------------------------------------------------
    if (tx.e_mode == "start")
    begin
      if (tx.f_mode == CALCOPY) begin
        `honeyb("REF Model", "START(CALCOPY) Received: ", "Generating Prediction...")
          $display(); // CLI
        f_mode = tx.f_mode; // Inform REF Model about the Functionality
      end else begin
        `honeyb("REF Model", "START(MATMUL) Received: ", "Generating Prediction...")
          $display(); // CLI
      end
    //=====================//  "start" -> "busy"
      tx.set_e_mode("busy"); // set e_mode
      tx.host_regso       [BUSY_IDX_REG] = 32'h1;
      tx.host_regso_valid [BUSY_IDX_REG] =  1'b1;
      //------------------
      `honeyb("REF Model", "Sent busy...")
      analysis_port_gpp.write(tx);
    //=====================// "busy"-> *FLUSH* -> "done"
      tx.op_flush();
      tx.set_e_mode("done"); //set e_mode
      tx.host_regso       [DONE_IDX_REG] = 32'h1; // done signal
      tx.host_regso_valid [DONE_IDX_REG] =  1'b1; // Valid done.
      //------------------
      `honeyb("REF Model", "Sent done...")
      analysis_port_gpp.write(tx);
    end else if (tx.e_mode == "rst_i") begin // "rst_i" -> "rst_o"
      tx.set_e_mode("rst_o"); // [EVENT](OUTPUT_RESET) 
      tx.op_flush();
      `honeyb("REF Model", "RESET(GPP) Received: ", "Generating Prediction...")
        //tx.print();// Report
      analysis_port_gpp.write(tx);
    end else `honeyb("REF Model", "Event Mismatch, Check me out!")
endfunction // Chain of Events: start -> busy -> done & "rst_i" -> "rst_o"
`endif // REFERENCE_SV

//==================================
//            EXTRAS
//==================================
  // These messages are redundant and used for UVM Debugging solely, in the future,
  // remove and log inputs only through input monitor!
  // `uvm_info("", $sformatf("A11 = %0d, A12 = %0d, A21 = %0d, A22 = %0d", tx.mem_rdata[0][0], tx.mem_rdata[0][1], tx.mem_rdata[0][2], tx.mem_rdata[0][3]), UVM_MEDIUM);
  // `uvm_info("", $sformatf("B11 = %0d, B12 = %0d, B21 = %0d, B22 = %0d", tx.mem_rdata[0][4], tx.mem_rdata[0][5], tx.mem_rdata[0][6], tx.mem_rdata[0][7]), UVM_MEDIUM);
  // `uvm_info("", $sformatf("Reading from Address: %0d", tx.mem_addr[0]), UVM_MEDIUM);

