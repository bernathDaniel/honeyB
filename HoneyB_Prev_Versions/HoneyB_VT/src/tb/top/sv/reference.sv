//=============================================================================
// Project  : HoneyB V1
// File Name: reference.sv
//=============================================================================
// Description: Reference model for use with xlr_scoreboard
//=============================================================================

`ifndef REFERENCE_SV
`define REFERENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_ref_mem)
`uvm_analysis_imp_decl(_ref_gpp)

class reference extends uvm_component;
  `uvm_component_utils(reference)

  uvm_analysis_imp_ref_mem #(xlr_mem_tx, reference) analysis_export_ref_mem; // m_xlr_mem_agent
  uvm_analysis_imp_ref_gpp #(xlr_gpp_tx, reference) analysis_export_ref_gpp; // m_xlr_gpp_agent

  uvm_analysis_port #(xlr_mem_tx) analysis_port_ref_mem; // m_xlr_mem_agent
  uvm_analysis_port #(xlr_gpp_tx) analysis_port_ref_gpp; // m_xlr_gpp_agent

  extern function new(string name, uvm_component parent);

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export_ref_mem = new("analysis_export_ref_mem", this);
    analysis_export_ref_gpp = new("analysis_export_ref_gpp", this);
    analysis_port_ref_mem   = new("analysis_port_ref_mem",   this);
    analysis_port_ref_gpp   = new("analysis_port_ref_gpp",   this);
  endfunction : build_phase

  extern function void write_ref_mem(input xlr_mem_tx t);
  extern function void write_ref_gpp(input xlr_gpp_tx t);

  extern function void send_xlr_mem_input(xlr_mem_tx t);
  extern function void send_xlr_gpp_input(xlr_gpp_tx t);
endclass : reference


function reference::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


function void reference::write_ref_mem(xlr_mem_tx t);
  `honeyb("[MEM](mem & mode Checker) REF Model", ":\n", $sformatf("\n\tt.mem = MEM[%0d], t.mode = %s\n", t.mem, t.mode))
  `honeyb("[MEM] REF Model", "Received the following TX:")
  t.print();
  send_xlr_mem_input(t);
endfunction : write_ref_mem
  
function void reference::write_ref_gpp(xlr_gpp_tx t);
  `honeyb("[GPP] REF Model", "Received the following TX:")
  t.print();
  send_xlr_gpp_input(t);
endfunction : write_ref_gpp

function void reference::send_xlr_mem_input(xlr_mem_tx t);
  xlr_mem_tx tx;
  int t_mem_idx = t.mem_idx;
  tx = xlr_mem_tx::type_id::create("tx");

  

  if (t.mem_rd == 1'b1) begin // Read Req

    // the expected signals for writing back
    tx.mem_idx   = 0;
    tx.mem_be[0] = 32'hFFFFFFFF; // En all bits
    tx.mem_wr[0] = 1'b1;
    tx.mem_addr[0] = 4'h1; // Write res into addr[1]
    tx.set_mode("wr");
    tx.set_mem(MEM0);

    // calculation of 2x2 MatMul
    tx.mem_wdata[0][0] = t.mem_rdata[t_mem_idx][0]*t.mem_rdata[t_mem_idx][4] + t.mem_rdata[t_mem_idx][1]*t.mem_rdata[t_mem_idx][6];
    tx.mem_wdata[0][1] = t.mem_rdata[t_mem_idx][0]*t.mem_rdata[t_mem_idx][5] + t.mem_rdata[t_mem_idx][1]*t.mem_rdata[t_mem_idx][7];
    tx.mem_wdata[0][2] = t.mem_rdata[t_mem_idx][2]*t.mem_rdata[t_mem_idx][4] + t.mem_rdata[t_mem_idx][3]*t.mem_rdata[t_mem_idx][6];
    tx.mem_wdata[0][3] = t.mem_rdata[t_mem_idx][2]*t.mem_rdata[t_mem_idx][5] + t.mem_rdata[t_mem_idx][3]*t.mem_rdata[t_mem_idx][7];
    
    for ( int i = 4; i < 8; i++ )
      tx.mem_wdata[0][i] = '0; // last 4 words expected as 0.
    
    analysis_port_ref_mem.write(tx); // broadcast it.
  end else begin
    // No Read Req ! Do nothing
    `honeyb("[MEM] REF Model", "NO READ OR RST_N ASSERTED, Broadcasting...")
    tx.copy(t);
    analysis_port_ref_mem.write(tx); // broadcast the rst_n result
  end
endfunction : send_xlr_mem_input

function void reference::send_xlr_gpp_input(xlr_gpp_tx t);
  xlr_gpp_tx tx;
  tx = xlr_gpp_tx::type_id::create("tx");

  if (t.host_regsi[0] == 32'h1 && t.host_regs_valid[0] == 1'b1) begin // start signal

    tx.host_regso       [0] = 32'h1; // busy signal
    tx.host_regso_valid [0] = 1'b1;
    `honeyb("[GPP] REF", "SENT TX ('DUT BUSY')")
    analysis_port_ref_gpp.write(tx);

    tx.host_regso       [1] = 32'h1; // done signal
    tx.host_regso_valid [1] = 1'b1; // Valid done.
    tx.host_regso       [0] = 32'h0; // reset busy signal so the scoreboard won't catch it twice !
    tx.host_regso_valid [0] = 1'b0;
    `honeyb("[GPP] REF", "SENT TX ('DUT DONE')")
    analysis_port_ref_gpp.write(tx);
  end else begin

    tx.host_regso       [0] = 32'h0; // assert zeros only to the relevant registers ! the others must remain 'x' just like for the DUT.
    tx.host_regso_valid [0] = 1'b1;
    tx.host_regso       [1] = 32'h0;
    tx.host_regso_valid [1] = 1'b0;
    `honeyb("[GPP] REF", "NO START RECEIVED (OR RST_N ASSERTED)")
    analysis_port_ref_gpp.write(tx);
  end
endfunction : send_xlr_gpp_input 

`endif // REFERENCE_SV




/************************************************************************************************************************************************************/
//     Extras:
//
//      These messages are redundant and used for UVM Debugging solely, in the future, remove and log inputs only through input monitor!
//     `uvm_info("", $sformatf("A11 = %0d, A12 = %0d, A21 = %0d, A22 = %0d", t.mem_rdata[0][0], t.mem_rdata[0][1], t.mem_rdata[0][2], t.mem_rdata[0][3]), UVM_MEDIUM);
//     `uvm_info("", $sformatf("B11 = %0d, B12 = %0d, B21 = %0d, B22 = %0d", t.mem_rdata[0][4], t.mem_rdata[0][5], t.mem_rdata[0][6], t.mem_rdata[0][7]), UVM_MEDIUM);
//     `uvm_info("", $sformatf("Reading from Address: %0d", t.mem_addr[0]), UVM_MEDIUM);
//
//
//
//