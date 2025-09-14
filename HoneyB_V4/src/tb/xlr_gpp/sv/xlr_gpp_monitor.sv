//=========================================================================================
// Project  : HoneyB V4
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
import honeyb_pkg::*;
import xlr_gpp_pkg::*;

class xlr_gpp_monitor extends uvm_monitor;

  `uvm_component_utils(xlr_gpp_monitor)

  virtual xlr_gpp_if vif;

  uvm_analysis_port #(xlr_gpp_tx) analysis_port_in;   // input signals
  uvm_analysis_port #(xlr_gpp_tx) analysis_port_out;  // output signals

  xlr_gpp_tx m_trans_in;
  xlr_gpp_tx m_trans_out;

  extern function       new         (string name, uvm_component parent);

  extern function void  build_phase (uvm_phase phase);
  extern task           run_phase   (uvm_phase phase);
  extern task           do_mon();
endclass : xlr_gpp_monitor 


function xlr_gpp_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port_in  = new("analysis_port_in"  , this);
  analysis_port_out = new("analysis_port_out" , this);
endfunction : new


function void xlr_gpp_monitor::build_phase(uvm_phase phase);
endfunction : build_phase


task xlr_gpp_monitor::run_phase(uvm_phase phase);
  `honeyb("GPP MON", "run_phase initialized...")

  m_trans_in  = xlr_gpp_tx::type_id::create("m_trans_in");
  m_trans_out = xlr_gpp_tx::type_id::create("m_trans_out");

  do_mon(); // User-Defined Handling

endtask : run_phase

task xlr_gpp_monitor::do_mon();

  bit busy_sent     = 1'b0; // flag for broadcasting busy only once when triggered until done is triggered.
  bit done_sent     = 1'b0; // flag for broadcasting done only once when triggered until busy is triggered.
  bit rst_asserted  = 1'b0;

 /* ~OPTIONAL - Flags -> Sampler Enablers (Context Revisit)
    bit en_start_sampler  = 1'b0;
    bit en_busy_sampler   = 1'b0;
    bit en_done_sampler   = 1'b0;

    IDEA - Redefine them for context of purposes, samplers are expected to sample when the DUT is expected to do something
 */




  fork // in & out monitors work in parallel

    /*************************************************************************/                                                                                       
    //                            DUT INPUT MONITOR                          //
    //-----------------------------------------------------------------------//
    //      Monitor only when in reg's asserted (indicating valid input)     //
    //      Inputs are testbench related (by driver) and set to be sent on   //
    //      negedge Making sure that no timing violations will occur         //
    //                                                                       //
    //***********************************************************************//

    // Input rst_n handling.
    forever begin
      if (!vif.rst_n) begin
        #1; // DO NOT CHANGE

        // flags
        // ---------------------------------------------------------------
        rst_asserted = 1'b1;

        // sampling & e_mode set
        // ---------------------------------------------------------------
        m_trans_in.host_regsi       = vif.host_regsi;
        m_trans_in.host_regs_valid  = vif.host_regs_valid;
        m_trans_in.set_e_mode("rst_i");

        // Report Statement
        `honeyb("GPP MON", "rst_n detected, INPUT transactions are reset")
        m_trans_in.print();

        analysis_port_in.write(m_trans_in);
      end
      @(posedge vif.rst_n); // Wait until rst_n deasserts : 0 -> 1
      rst_asserted = 1'b0;
    end                                                                                                                                                               /*

      START_IDX_REG Sampler
     ===========================================================================================                                                                        */

    forever @(negedge vif.clk) begin
      #1; // small delay so it can capture the driver's NBA assignments.

      if(is_start_asserted(vif.host_regsi[START_IDX_REG], vif.host_regs_valid[START_IDX_REG])) begin
        
        m_trans_in.host_regsi     [START_IDX_REG] = vif.host_regsi     [START_IDX_REG];
        m_trans_in.host_regs_valid[START_IDX_REG] = vif.host_regs_valid[START_IDX_REG];
        
        // Report
        `honeyb("GPP MON", "Detected Start Inst.,:")
        m_trans_in.set_e_mode("start");
        m_trans_in.print();

        // broadcast the transaction through the analysis INPUT port
        analysis_port_in.write(m_trans_in);

       // ~Optional flag handling - DUT sets busy = 1'b1 & done = 1'b1 when started -> enable the monitor's busy sampler
        // -----------------------
        // en_busy_sampler = 1'b1;
        // en_done_sampler = 1'b0;
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
        #1; // DO NOT CHANGE

        // flags
        // ---------------------------------------------------------------
        rst_asserted = 1'b1;

        // sampling & e_mode set
        // ---------------------------------------------------------------
        m_trans_out.host_regso        = vif.host_regso;
        m_trans_out.host_regso_valid  = vif.host_regso_valid;
        m_trans_out.set_e_mode("rst_o");

        // Report
        `honeyb("GPP MON", "rst_n detected, OUTPUT transactions are reset")
        m_trans_out.print();
        analysis_port_out.write(m_trans_out);
      end
      @(posedge vif.rst_n); // Wait until rst_n deasserts : 0 -> 1
    end

    
    forever @(posedge vif.clk) begin
      // NBA vs. BA Deterministic Handling (Active region >> NBA Region)
      #1;                                                                                                                                                               /*

      BUSY_IDX_REG Sampler
     ===========================================================================================                                                                        */


      // If statements to decide if, when & where to broadcast
      if ((busy_sent == 1'b0) && 
        busy_is_asserted(vif.host_regso[BUSY_IDX_REG], vif.host_regso_valid[BUSY_IDX_REG]))
      begin
        
        // flags
        // ---------------------------------------------------------
        busy_sent = 1'b1; // Set busy flag
        done_sent = 1'b0; // Reset done flag
        
        // sampling & e_mode set
        // ---------------------------------------------------------
        m_trans_out.host_regso      [BUSY_IDX_REG] = vif.host_regso      [BUSY_IDX_REG];
        m_trans_out.host_regso_valid[BUSY_IDX_REG] = vif.host_regso_valid[BUSY_IDX_REG];
        m_trans_out.set_e_mode("busy");


        // Report Statement
        `honeyb("GPP MON", "Detected BUSY Inst. : Broadcasting...")
        m_trans_out.print();
        // Broadcast to scoreboard
        analysis_port_out.write(m_trans_out);
      end                                                                                                                                                               /*
     ===========================================================================================
      DONE_IDX_REG Sampler
     ===========================================================================================                                                                        */

      if ((done_sent == 1'b0) && 
        done_is_asserted(vif.host_regso[DONE_IDX_REG], vif.host_regso_valid[DONE_IDX_REG]))
      begin
        
        // flags
        // ---------------------------------------------------------
        busy_sent = 1'b0; // Reset busy flag
        done_sent = 1'b1; // Set done flag
        
        // sampling & e_mode set
        // ---------------------------------------------------------
        m_trans_out.host_regso      [DONE_IDX_REG] = vif.host_regso      [DONE_IDX_REG];
        m_trans_out.host_regso_valid[DONE_IDX_REG] = vif.host_regso_valid[DONE_IDX_REG];
        m_trans_out.set_e_mode("done");


        // Report Statement
        // ----------------------------------------------------------
        `honeyb("GPP MON", "Detected DONE Inst. : Broadcasting...")
        m_trans_out.print();

        // Broadcast the transaction through the analysis OUTPUT port
        // -----------------------------------------------------------
        analysis_port_out.write(m_trans_out);

      end
    end
  join
endtask : do_mon

`endif // XLR_GPP_MONITOR_SV

