//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_gpp_coverage.sv
//=============================================================================
// Description: Coverage for agent xlr_gpp
//=============================================================================

`ifndef XLR_GPP_COVERAGE_SV
`define XLR_GPP_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_gpp_pkg::*;

// Declaration for multiple exports
`uvm_analysis_imp_decl(_gpp_cov_in)
`uvm_analysis_imp_decl(_gpp_cov_out)

class xlr_gpp_coverage extends uvm_component;

  `uvm_component_utils(xlr_gpp_coverage)

  uvm_analysis_imp_gpp_cov_in#(xlr_gpp_tx, xlr_gpp_coverage) gpp_cov_in_export;
  uvm_analysis_imp_gpp_cov_out#(xlr_gpp_tx, xlr_gpp_coverage) gpp_cov_out_export;

  xlr_gpp_config m_xlr_gpp_config;
  bit            cg_in_is_covered = 1'b0;
  bit            cg_out_is_covered = 1'b0;
  xlr_gpp_tx     tx_in;
  xlr_gpp_tx     tx_out; // D

  covergroup cg_in;
    option.per_instance = 1;
    option.name         = "[GPP](IN) Coverage";

    cp_start: coverpoint tx_in.host_regsi[START_IDX_REG] {
      bins start_vals   = {32'h00000001, 32'h00000002};
    }
    
    cp_start_valid: coverpoint tx_in.host_regs_valid[START_IDX_REG] {
      bins start_valid_vals = {1'b1};
    }

    start_X_valid: cross cp_start, cp_start_valid {
      bins start_and_valid =
          binsof(cp_start.start_vals) &&
          binsof(cp_start_valid.start_valid_vals);
    }
  endgroup

  covergroup cg_out;
    option.per_instance = 1;
    option.name         = "[GPP](OUT) Coverage";

    cp_busy: coverpoint tx_out.host_regso[BUSY_IDX_REG] {
      bins busy_vals = {32'h1};
    }
    
    cp_busy_valid: coverpoint tx_out.host_regso_valid[BUSY_IDX_REG] {
      bins busy_valid_vals = {1'b1};
    }

    busy_X_valid: cross cp_busy, cp_busy_valid {
      bins busy_and_valid =
          binsof(cp_busy.busy_vals) &&
          binsof(cp_busy_valid.busy_valid_vals);
    }

    cp_done: coverpoint tx_out.host_regso[DONE_IDX_REG] {
      bins done_vals = {32'h1};
    }
    
    cp_done_valid: coverpoint tx_out.host_regso_valid[DONE_IDX_REG] {
      bins done_valid_vals = {1'b1};
    }

    done_X_valid: cross cp_done, cp_done_valid {
      bins done_and_valid =
          binsof(cp_done.done_vals) &&
          binsof(cp_done_valid.done_valid_vals);
    }
  endgroup


  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void write_gpp_cov_in(input xlr_gpp_tx t);
  extern function void write_gpp_cov_out(input xlr_gpp_tx t);
  extern function void report_phase(uvm_phase phase);
endclass : xlr_gpp_coverage 


function xlr_gpp_coverage::new(string name, uvm_component parent);
  super.new(name, parent);
  cg_in  = new();
  cg_out = new();
endfunction // Boilerplate + Embedded CG NEW

function void xlr_gpp_coverage::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if (!uvm_config_db #(xlr_gpp_config)::get(this, "", "config", m_xlr_gpp_config))
    `uvm_error("", "xlr_gpp config not found")
  
  cg_in.option.at_least  = m_xlr_gpp_config.cov_hit_thrshld; // # Of hits = # Of Sequences
  cg_out.option.at_least = m_xlr_gpp_config.cov_hit_thrshld; // Set the Coverage based on Cfg Knob

  tx_in  = xlr_gpp_tx::type_id::create("tx_in");
  tx_out = xlr_gpp_tx::type_id::create("tx_out"); // F

  gpp_cov_in_export  = new("gpp_cov_in_export",  this);
  gpp_cov_out_export = new("gpp_cov_out_export", this);
endfunction // Boilerplate + m_cov constrct.

function void xlr_gpp_coverage::write_gpp_cov_in(input xlr_gpp_tx t);
  tx_in.copy(t); // C
  if (m_xlr_gpp_config.coverage_enable) begin
    cg_in.sample();
    if (cg_in.get_inst_coverage() >= 100) cg_in_is_covered = 1;
  end
endfunction

function void xlr_gpp_coverage::write_gpp_cov_out(input xlr_gpp_tx t);
  tx_out.copy(t); // C
  if (m_xlr_gpp_config.coverage_enable)
  begin
    cg_out.sample();
    if (cg_out.get_inst_coverage() >= 100) cg_out_is_covered = 1;
  end
endfunction


function void xlr_gpp_coverage::report_phase(uvm_phase phase);
  if (m_xlr_gpp_config.coverage_enable) begin
    `honeyb("Coverage", $sformatf("[IN ] Cross start_X_valid = %.1f%%", cg_in.start_X_valid.get_inst_coverage()))
      //`honeyb("Coverage", $sformatf("[IN ] Coverage score      = %3.1f%%", cg_in.get_inst_coverage()))
      //`honeyb("Coverage", $sformatf("cg_in_is_covered = %0d", cg_in_is_covered))
    `honeyb("Coverage", $sformatf("[OUT] Cross busy_X_valid  = %.1f%%", cg_out.busy_X_valid.get_inst_coverage()))
    `honeyb("Coverage", $sformatf("[OUT] Cross done_X_valid  = %.1f%%", cg_out.done_X_valid.get_inst_coverage()))
      //`honeyb("Coverage", $sformatf("[OUT] Coverage score      = %3.1f%%", cg_out.get_inst_coverage()))
      //`honeyb("Coverage", $sformatf("cg_out_is_covered = %0d", cg_out_is_covered))
    $display(); // CLI
  end else
    `honeyb("Coverage", "Coverage disabled for the GPP agent")
endfunction : report_phase

`endif // XLR_GPP_COVERAGE_SV

