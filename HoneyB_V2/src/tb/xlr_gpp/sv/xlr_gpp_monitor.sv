//=========================================================================================
// Project  : HoneyB V2
// File Name: xlr_gpp_monitor.sv
//=========================================================================================
// Description: Monitor for xlr_gpp
// Important: The monitor takes care both of the inputs and the outputs
//            therefore it has 2 analysis ports, 1 for the inputs and 1 for outputs
//            since we have a single tx class for both input & output
//            this means that the transaction being broadcasted includes all tx's
//            thus, through the input analysis ports the output signals will be
//            propagated with 'x' values and vice versa for the output analysis port.
//=========================================================================================

`ifndef XLR_GPP_MONITOR_SV
`define XLR_GPP_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class xlr_gpp_monitor extends uvm_monitor;

  `uvm_component_utils(xlr_gpp_monitor)

  virtual xlr_gpp_if vif;

  uvm_analysis_port #(xlr_gpp_tx) analysis_port_in; // input signals
  uvm_analysis_port #(xlr_gpp_tx) analysis_port_out; // output signals

  xlr_gpp_tx m_trans_in;
  xlr_gpp_tx m_trans_out;

  extern function new(string name, uvm_component parent);

  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern task do_mon();
endclass : xlr_gpp_monitor 


function xlr_gpp_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port_in = new("analysis_port_in", this);
  analysis_port_out = new("analysis_port_out", this);
endfunction : new


function void xlr_gpp_monitor::build_phase(uvm_phase phase);
endfunction : build_phase


task xlr_gpp_monitor::run_phase(uvm_phase phase);
  `honeyb("GPP MON", "run_phase initialized...")

  m_trans_in = xlr_gpp_tx::type_id::create("m_trans_in");
  m_trans_out = xlr_gpp_tx::type_id::create("m_trans_out");
  do_mon();
endtask : run_phase

task xlr_gpp_monitor::do_mon();

  bit busy_sent = 1'b0; // flag for broadcasting busy only once when triggered until done is triggered.
  bit done_sent = 1'b0; // flag for broadcasting done only once when triggered until busy is triggered.
  bit rst_asserted = 1'b0;

  fork // in & out monitors work in parallel

    //*********************************************************************//
    //                           DUT INPUT MONITOR                         //
    //---------------------------------------------------------------------//
    //     Monitor only when in reg's asserted (indicating valid input)    //
    //     Inputs are testbench related (by driver) and set to be sent on  //
    //     negedge Making sure that no timing violations will occur        //
    //                                                                     //
    //*********************************************************************//

    // Input rst_n handling.
    forever begin
      if (!vif.rst_n) begin
        rst_asserted = 1'b1;
        #1;
        m_trans_in.host_regsi = vif.host_regsi;
        m_trans_in.host_regs_valid = vif.host_regs_valid;
        `honeyb("GPP MON", "rst_n detected, INPUT transactions are reset")
        analysis_port_in.write(m_trans_in);
      end
      @(vif.rst_n); // Wait until rst_n changes.
      rst_asserted = 1'b0;
    end

    forever @(negedge vif.clk) begin
      #1; // small delay so it can capture the driver's NBA assignments.
      // Always Capture the input values
      m_trans_in.host_regsi = vif.host_regsi;
      m_trans_in.host_regs_valid = vif.host_regs_valid;

      // If statements to decide when to broadcast and where
      // Currently I broadcast only to the REF and Scoreboard
      // But I could add coverage and another analyis port and broadcast
      // different things based on what I'm trying to accomplish through if statements.

      if(vif.host_regsi[0] == 32'h1 && vif.host_regs_valid[0] == 1'b1) begin // start signal
        // Log the captured data
        `honeyb("GPP MON", "Detected Start Inst. :")
        m_trans_in.set_mode("start");
        m_trans_in.print();
        // broadcast the transaction through the analysis INPUT port
        analysis_port_in.write(m_trans_in);
      end else if (!rst_asserted) begin
        //`uvm_info("GPP MON", "\nDetected No Start Inst., No Broadcasting..", UVM_MEDIUM)
      end
    end

    //*********************************************************************//
    //                           DUT OUTPUT MONITOR                        //
    //---------------------------------------------------------------------//
    //     Monitor only when out reg's asserted (indicating valid output)  //
    //     Outputs are DUT related and set to be sent on posedge.          //
    //     This will allow well synchronized timing of the triggerd        //
    //     signals from the DUT.                                           //
    //                                                                     //
    //*********************************************************************//

    //output rst_n handling.
    forever begin
      if (!vif.rst_n) begin
        #1;
        m_trans_out.host_regso = vif.host_regso;
        m_trans_out.host_regso_valid = vif.host_regso_valid;
        `honeyb("GPP MON", "rst_n detected, OUTPUT transactions are reset")
        analysis_port_out.write(m_trans_out);
      end
      @(vif.rst_n); // Wait until rst_n changes.
    end

    forever @(posedge vif.clk) begin
      #1;
      // Always capture the output values
      m_trans_out.host_regso = vif.host_regso;
      m_trans_out.host_regso_valid = vif.host_regso_valid;
      // If statements to decide if, when & where to broadcast
      if (vif.host_regso[0] == 32'h1 && vif.host_regso_valid[0] == 1'b1 && busy_sent == 1'b0) begin // busy signal
        busy_sent = 1'b1; // Set busy_sent when busy is asserted.
        done_sent = 1'b0; // Reset done_sent when busy is asserted.
        // Log the captured data
        `honeyb("GPP MON", "Detected BUSY Inst. : Broadcasting...")
        // Broadcast to scoreboard
        analysis_port_out.write(m_trans_out);
      end

      if (vif.host_regso[1] == 32'h1 && vif.host_regso_valid[1] == 1'b1) begin // done signal
        done_sent = 1'b1; // Set done_sent when done is asserted.
        busy_sent = 1'b0; // Reset busy_sent when done is asserted.
        // Log the captured data
        `honeyb("GPP MON", "Detected DONE Inst. : Broadcasting...")
        // Broadcast the transaction through the analysis OUTPUT port
        analysis_port_out.write(m_trans_out);
      end
    end
  join
endtask : do_mon

`endif // XLR_GPP_MONITOR_SV

