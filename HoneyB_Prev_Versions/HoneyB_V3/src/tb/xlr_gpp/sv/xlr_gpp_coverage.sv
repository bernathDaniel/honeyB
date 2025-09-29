//=============================================================================
// Project  : HoneyB V2
// File Name: xlr_gpp_coverage.sv
//=============================================================================
// Description: Coverage for agent xlr_gpp
//=============================================================================

`ifndef XLR_GPP_COVERAGE_SV
`define XLR_GPP_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class xlr_gpp_coverage extends uvm_subscriber #(xlr_gpp_tx);

  `uvm_component_utils(xlr_gpp_coverage)

  xlr_gpp_config m_config;    
  bit            m_is_covered;
  xlr_gpp_tx     m_item;

  covergroup m_cov;
    option.per_instance = 1;
    
    // Cover host_regsi[0] bit values (0 or 1)
    cp_host_regsi: coverpoint m_item.host_regsi[0][0] {
      bins regsi_values[] = {1'b0, 1'b1};
    }
    
    // Cover host_regs_valid[0] bit values (0 or 1)
    cp_host_regs_valid: coverpoint m_item.host_regs_valid[0] {
      bins valid_values[] = {1'b0, 1'b1};
    }
    
    // Cover the cross of the two control bits
    cp_cross: cross cp_host_regsi, cp_host_regs_valid {
      // This will create bins for all 4 combinations:
      // (0,0), (0,1), (1,0), (1,1)
    }
  endgroup


  extern function new(string name, uvm_component parent);
  extern function void write(input xlr_gpp_tx t);
  extern function void build_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
endclass : xlr_gpp_coverage 


function xlr_gpp_coverage::new(string name, uvm_component parent);
  super.new(name, parent);
  m_is_covered = 0;
  m_cov = new();
endfunction : new


function void xlr_gpp_coverage::write(input xlr_gpp_tx t);
  m_item = t;
  if (m_config.coverage_enable)
  begin
    m_cov.sample();
    // Check coverage - could use m_cov.option.goal instead of 10 if your simulator supports it
    if (m_cov.get_inst_coverage() >= 10) m_is_covered = 1;
  end
endfunction : write


function void xlr_gpp_coverage::build_phase(uvm_phase phase);
  if (!uvm_config_db #(xlr_gpp_config)::get(this, "", "config", m_config))
    `uvm_error("", "xlr_gpp config not found")
endfunction : build_phase


function void xlr_gpp_coverage::report_phase(uvm_phase phase);
  if (m_config.coverage_enable)
    `uvm_info("", $sformatf("Coverage score = %3.1f%%", m_cov.get_inst_coverage()), UVM_MEDIUM)
  else
    `uvm_info("", "Coverage disabled for this agent", UVM_MEDIUM)
endfunction : report_phase

`endif // XLR_GPP_COVERAGE_SV

