//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_coverage.sv
//=============================================================================
// Description: Coverage for agent xlr_mem
  //
  // IMPORTANT : MIGHT NEED TO CHANGE FOR MATCHING SIGNED VALUES
//=============================================================================

`ifndef XLR_MEM_COVERAGE_SV
`define XLR_MEM_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

// Declaration for multiple exports
`uvm_analysis_imp_decl(_mem_cov_in)
`uvm_analysis_imp_decl(_mem_cov_out)

class xlr_mem_coverage extends uvm_component;

  `uvm_component_utils(xlr_mem_coverage)

  uvm_analysis_imp_mem_cov_in#(xlr_mem_tx, xlr_mem_coverage)  mem_cov_in_export;
  uvm_analysis_imp_mem_cov_out#(xlr_mem_tx, xlr_mem_coverage) mem_cov_out_export;

  xlr_mem_config m_xlr_mem_config;    
  bit            cg_in_is_covered = 1'b0;
  bit            cg_out_is_covered = 1'b0;
  xlr_mem_tx     tx_in;
  xlr_mem_tx     tx_out;
     
  covergroup cg_in;
    option.per_instance = 1;
    option.name         = "[MEM](IN) Coverage";
    option.comment      = "mem_rdata Responses to DUT";
    //option.at_least = m_xlr_mem_config.cov_hit_thrshld;

    cp_mem_rdata: coverpoint tx_in.mem_rdata[0] {
      bins mem_rdata_vals[] = {[0:$]} with (item != 0);
    }
  endgroup 

  covergroup cg_out;
    option.per_instance = 1;
    option.name         = "[MEM](OUT) Coverage";
    option.comment      = "Read / Write Requests by DUT";
    //option.at_least = m_xlr_mem_config.cov_hit_thrshld;

    cp_mem_addr: coverpoint tx_out.mem_addr {
      bins mem_addr_0 = {32'h00000000};  // MEM0 address 0
      bins mem_addr_1 = {32'h00000001};  // MEM0 and MEM1 address 1
    }

    cp_mem_wdata: coverpoint tx_out.mem_wdata[1:0] {
      bins mem_wdata_vals[] = {[0:$]} with (item != 0);
    }

    cp_mem_wr: coverpoint tx_out.mem_wr {
      bins mem_wr_vals = {1'b1};
    }

    cp_mem_be: coverpoint tx_out.mem_be {
      bins mem_be_vals = {32'hFFFFFFFF};
    }

    cp_mem_rd: coverpoint tx_out.mem_rd {
      bins mem_rd_vals = {1'b1};
    }

    rd_X_addr: cross cp_mem_rd, cp_mem_addr {
      bins complete_read =
          binsof(cp_mem_rd.mem_rd_vals) &&
          binsof(cp_mem_addr.mem_addr_0);  // Only reading from addr 0
    }

    wr_X_addr_X_be_wdata: cross cp_mem_wr, cp_mem_addr, cp_mem_be, cp_mem_wdata {
      bins complete_write =
          binsof(cp_mem_wr.mem_wr_vals) &&
          binsof(cp_mem_addr.mem_addr_1) &&  // Writing to addr 1 (both MEM0 and MEM1)
          binsof(cp_mem_be.mem_be_vals) &&
          binsof(cp_mem_wdata.mem_wdata_vals);
    }
  endgroup
  
  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void write_mem_cov_in(input xlr_mem_tx t);
  extern function void write_mem_cov_out(input xlr_mem_tx t);
  extern function void report_phase(uvm_phase phase);
endclass : xlr_mem_coverage 


function xlr_mem_coverage::new(string name, uvm_component parent);
  super.new(name, parent);
  cg_in  = new();
  cg_out = new();
endfunction // Boilerplate + CG New


function void xlr_mem_coverage::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if (!uvm_config_db #(xlr_mem_config)::get(this, "", "config", m_xlr_mem_config))
    `uvm_error("", "xlr_mem config not found")

  tx_in = xlr_mem_tx::type_id::create("tx_in");
  tx_out = xlr_mem_tx::type_id::create("tx_out"); // F

  mem_cov_in_export = new("mem_cov_in_export", this);
  mem_cov_out_export = new("mem_cov_out_export", this);
endfunction // Boilerplate + m_cov constrct.


function void xlr_mem_coverage::write_mem_cov_in(input xlr_mem_tx t);
  tx_in.copy(t); // C
    if (m_xlr_mem_config.coverage_enable)
    begin
      `honeyb("Hello", "Mem Coverage In")
      if (cg_in == null) `uvm_error("", "cg_in is null!")
      cg_in.sample();
      if (cg_in.get_inst_coverage() >= 5) cg_in_is_covered = 1;
    end
endfunction


function void xlr_mem_coverage::write_mem_cov_out(input xlr_mem_tx t);
  tx_out.copy(t); // C
  
    if (m_xlr_mem_config.coverage_enable)
    begin
      `honeyb("Hello", "Mem Coverage Out")
      cg_out.sample();
      if (cg_out.get_inst_coverage() >= 5) cg_out_is_covered = 1;
    end
endfunction


function void xlr_mem_coverage::report_phase(uvm_phase phase);
  if (m_xlr_mem_config.coverage_enable) begin
    `uvm_info("", $sformatf("[MEM IN]  Coverage score = %3.1f%%", cg_in.get_inst_coverage()), UVM_MEDIUM)
    `uvm_info("", $sformatf("[MEM OUT] Coverage score = %3.1f%%", cg_out.get_inst_coverage()), UVM_MEDIUM)
    `honeyb("DEBUG", $sformatf("cg_in_is_covered = %0d", cg_in_is_covered))
    `honeyb("DEBUG", $sformatf("cg_out_is_covered = %0d", cg_out_is_covered))
  end else
    `uvm_info("", "Coverage disabled for this agent", UVM_MEDIUM)
endfunction : report_phase

`endif // XLR_MEM_COVERAGE_SV

