//=============================================================================
// Project  : HoneyB V4
// File Name: xlr_mem_coverage.sv
//=============================================================================
// Description: Coverage for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_COVERAGE_SV
`define XLR_MEM_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;


class xlr_mem_coverage extends uvm_subscriber #(xlr_mem_tx);

  `uvm_component_utils(xlr_mem_coverage)

  xlr_mem_config m_config;    
  bit            m_is_covered;
  xlr_mem_tx     m_item;
     
  covergroup m_cov;
    option.per_instance = 1;
    
    // Cover each word of mem_rdata[MEM0][7:0]
    // A[1,1] Value
    cp_word0: coverpoint m_item.mem_rdata[MEM0][0] {
      bins word_value[] = {[0:20]};
    }
    // A[1,2] Value
    cp_word1: coverpoint m_item.mem_rdata[MEM0][1] {
      bins word_value[] = {[0:20]};
    }
    // A[2,1] Value
    cp_word2: coverpoint m_item.mem_rdata[MEM0][2] {
      bins word_value[] = {[0:20]};
    }
    // A[2,2] Value
    cp_word3: coverpoint m_item.mem_rdata[MEM0][3] {
      bins word_value[] = {[0:20]};
    }
    // B[1,1] Value
    cp_word4: coverpoint m_item.mem_rdata[MEM0][4] {
      bins word_value[] = {[0:20]};
    }
    // B[1,2] Value
    cp_word5: coverpoint m_item.mem_rdata[MEM0][5] {
      bins word_value[] = {[0:20]};
    }
    // B[2,1] Value
    cp_word6: coverpoint m_item.mem_rdata[MEM0][6] {
      bins word_value[] = {[0:20]};
    }
    // B[2,2] Value
    cp_word7: coverpoint m_item.mem_rdata[MEM0][7] {
      bins word_value[] = {[0:20]};
    }
  endgroup  

  extern function new(string name, uvm_component parent);
  extern function void write(input xlr_mem_tx t);
  extern function void build_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
endclass : xlr_mem_coverage 


function xlr_mem_coverage::new(string name, uvm_component parent);
  super.new(name, parent);
  m_is_covered = 0;
  m_cov = new();
endfunction : new


function void xlr_mem_coverage::write(input xlr_mem_tx t);
  m_item = t;
  if (m_config.coverage_enable)
  begin
    m_cov.sample();
    // Check coverage - could use m_cov.option.goal instead of 10 if your simulator supports it
    if (m_cov.get_inst_coverage() >= 10) m_is_covered = 1;
  end
endfunction : write


function void xlr_mem_coverage::build_phase(uvm_phase phase);
  if (!uvm_config_db #(xlr_mem_config)::get(this, "", "config", m_config))
    `uvm_error("", "xlr_mem config not found")
endfunction : build_phase


function void xlr_mem_coverage::report_phase(uvm_phase phase);
  if (m_config.coverage_enable)
    `uvm_info("", $sformatf("Coverage score = %3.1f%%", m_cov.get_inst_coverage()), UVM_MEDIUM)
  else
    `uvm_info("", "Coverage disabled for this agent", UVM_MEDIUM)
endfunction : report_phase

`endif // XLR_MEM_COVERAGE_SV

