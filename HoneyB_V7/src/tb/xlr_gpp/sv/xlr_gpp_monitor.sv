//=========================================================================================
// Project  : HoneyB V7
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

  //        Helper Methods
  //------------------------------
    extern task clk_posedge_wait();
    extern task clk_negedge_wait();
    extern function logic get_rst_n();
    extern task pin_wig_rst();
    extern task rst_n_negedge_wait();
    extern task rst_n_posedge_wait();
endclass : xlr_gpp_monitor // Boilerplate + Helpers


function xlr_gpp_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port_in  = new("analysis_port_in"  , this);
  analysis_port_out = new("analysis_port_out" , this);
endfunction // Boilerplate


function void xlr_gpp_monitor::build_phase(uvm_phase phase);
endfunction : build_phase // Boilerplate


task xlr_gpp_monitor::run_phase(uvm_phase phase);
  `honeyb("GPP Monitor", "run_phase initialized...")
  m_trans_in  = xlr_gpp_tx::type_id::create("m_trans_in");
  m_trans_out = xlr_gpp_tx::type_id::create("m_trans_out");
  do_mon(); // User-Defined Handling
endtask : run_phase // Boilerplate + Report

task xlr_gpp_monitor::do_mon(); // - OK - // - FINAL - //

  // Sampling Enabler Flags
  //========================
    bit busy_sent     = 1'b0;
    bit done_sent     = 1'b0;

  fork
    //=======================================================================
    //                        DUT INPUT MONITOR                            
    //=======================================================================
     // Monitor only when in reg's asserted (indicating valid input)
     // Inputs are testbench related (by driver) and set to be sent on
     // negedge Making sure that no timing violations will occur

    forever begin // - OK - // Input rst_n handling.
      rst_n_negedge_wait();
      if (!get_rst_n()) begin
                              #RACE_CTRL;
        m_trans_in.host_regsi       = vif.host_regsi;
        m_trans_in.host_regs_valid  = vif.host_regs_valid;
        m_trans_in.set_e_mode("rst_i"); // sampling & e_mode set

        `honeyb("GPP Monitor", "RESET(STIMULUS) detected, Broadcasting...")
          m_trans_in.print();
        analysis_port_in.write(m_trans_in);
      end
      rst_n_posedge_wait();
    end
    
    forever begin // - OK - // START_IDX_REG Sampler
      clk_posedge_wait();
                          #RACE_CTRL;
      if (is_start_asserted  (vif.host_regsi[START_IDX_REG] , vif.host_regs_valid[START_IDX_REG]) ||
          is_calcopy_asserted(vif.host_regsi[START_IDX_REG] , vif.host_regs_valid[START_IDX_REG])
      ) begin
        
        m_trans_in.host_regsi     [START_IDX_REG] = vif.host_regsi     [START_IDX_REG];
        m_trans_in.host_regs_valid[START_IDX_REG] = vif.host_regs_valid[START_IDX_REG];
        m_trans_in.set_e_mode("start");
        
        if (vif.host_regsi[START_IDX_REG] == 32'h2) begin
          `honeyb("GPP Monitor", "Start(CALCOPY) ctrl detected, Broadcasting...")
          m_trans_in.set_f_mode(CALCOPY);
        end else `honeyb("GPP Monitor", "Start(MATMUL) ctrl detected, Broadcasting...")

        m_trans_in.print(); // Report
        analysis_port_in.write(m_trans_in);
      end
    end

    //=======================================================================
    //                        DUT OUTPUT MONITOR                           
    //=======================================================================
     // Monitor only when out reg's asserted (indicating valid output)
     // Outputs are DUT related and set to be sent on posedge.
     // This will allow well synchronized timing of the triggerd
     // signals from the DUT.

    forever begin // - OK - // Output rst_n handling.
      rst_n_negedge_wait();
      if (!get_rst_n()) begin
                              #RACE_CTRL;
        m_trans_out.host_regso        = vif.host_regso;
        m_trans_out.host_regso_valid  = vif.host_regso_valid;
        m_trans_out.set_e_mode("rst_o"); // sampling & e_mode set
                              #RACE_CTRL;
        `honeyb("GPP Monitor", "RESET(DUT RSP) detected, Broadcasting...")
          m_trans_out.print();
        analysis_port_out.write(m_trans_out);
      end
      rst_n_posedge_wait();
    end

    
    forever begin // - OK - //BUSY_IDX_REG Sampler
      clk_posedge_wait();
                          #RACE_CTRL;
      if ((busy_sent == 1'b0) && 
        busy_is_asserted(vif.host_regso[BUSY_IDX_REG], vif.host_regso_valid[BUSY_IDX_REG]))
      begin // is asserted
        
        busy_sent = 1'b1; // Set busy flag
        done_sent = 1'b0; // Reset done flag
        
        // sampling & e_mode set
        m_trans_out.host_regso      [BUSY_IDX_REG] = vif.host_regso      [BUSY_IDX_REG];
        m_trans_out.host_regso_valid[BUSY_IDX_REG] = vif.host_regso_valid[BUSY_IDX_REG];
        m_trans_out.set_e_mode("busy");

        `honeyb("GPP Monitor", "BUSY status detected, Broadcasting...")
          m_trans_out.print();// Report

        analysis_port_out.write(m_trans_out);
      end
    end

    forever begin // - OK - // DONE_IDX_REG Sampler
      clk_posedge_wait();
                          #RACE_CTRL;
      if ((done_sent == 1'b0) && 
        done_is_asserted(vif.host_regso[DONE_IDX_REG], vif.host_regso_valid[DONE_IDX_REG]))
      begin // is asserted

        busy_sent = 1'b0; // Reset busy flag
        done_sent = 1'b1; // Set done flag
        
        m_trans_out.host_regso      [DONE_IDX_REG] = vif.host_regso      [DONE_IDX_REG];
        m_trans_out.host_regso_valid[DONE_IDX_REG] = vif.host_regso_valid[DONE_IDX_REG];
        m_trans_out.set_e_mode("done"); // sampling & e_mode set

        `honeyb("GPP Monitor", "DONE status detected, Broadcasting...")
          m_trans_out.print(); // Report
        analysis_port_out.write(m_trans_out);
      end
    end
  join_none
endtask : do_mon

//=========================================================
//                    HELPER METHODS
//=========================================================
  // Clock Methods
  // =============

    task xlr_gpp_monitor::clk_posedge_wait(); @(posedge vif.clk); endtask
    task xlr_gpp_monitor::clk_negedge_wait(); @(negedge vif.clk); endtask

  // Reset Methods
  // =============

    function logic xlr_gpp_monitor::get_rst_n(); return vif.rst_n; endfunction

    task xlr_gpp_monitor::pin_wig_rst();
      vif.host_regsi      <= '0;
      vif.host_regs_valid <= '0;
    endtask

    task xlr_gpp_monitor::rst_n_negedge_wait(); @(negedge vif.rst_n); endtask
    task xlr_gpp_monitor::rst_n_posedge_wait(); @(posedge vif.rst_n); endtask

`endif // XLR_GPP_MONITOR_SV

//===========================
//        EXTRAS
//===========================
  /*
    OPTIONAL - Flags -> Sampler Enablers (Context Revisit)
     bit en_start_sampler  = 1'b0;
     bit en_busy_sampler   = 1'b0;
     bit en_done_sampler   = 1'b0;

    // Optional flag handling - DUT sets busy = 1'b1 & done = 1'b1 when started -> enable the monitor's busy sampler
    // -----------------------
      en_busy_sampler = 1'b1;
      en_done_sampler = 1'b0;

    IDEA - Redefine them for context of purposes, samplers are expected to sample when the DUT is expected to do something
  */

