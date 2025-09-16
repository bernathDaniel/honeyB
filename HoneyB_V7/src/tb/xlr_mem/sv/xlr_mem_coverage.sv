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
  bit            cg_in_is_covered  = 1'b0;
  bit            cg_out_is_covered = 1'b0;
  xlr_mem_tx     tx_in;
  xlr_mem_tx     tx_out; // D
     
  covergroup cg_in;
    option.per_instance = 1;
    option.name         = "[MEM](IN) Coverage";

    cp_mem_rd: coverpoint tx_in.mem_rd {
      bins mem_rd_vals = {MEM_RD_0};
    }

    cp_mem_rd_addr: coverpoint tx_in.mem_addr {
      bins mem_rd_addr_vals = {MEM_0_ADDR_0};  // MEM0 address 0
    }

    rd_X_addr: cross cp_mem_rd, cp_mem_rd_addr {
      bins complete_read =
          binsof(cp_mem_rd.mem_rd_vals) &&
          binsof(cp_mem_rd_addr.mem_rd_addr_vals);
    }
  endgroup 

  covergroup cg_out;
    option.per_instance = 1;
    option.name         = "[MEM](OUT) Coverage";

    cp_mem_wr_addr: coverpoint tx_out.mem_addr {
      bins mem_wr_addr_vals = {MEM_0_ADDR_1, MEM_0_1_ADDR_1};  // MEM_0 || MEM_0_1 -> ADDR 1
    }

    cp_mem_wr: coverpoint tx_out.mem_wr {
      bins mem_wr_vals = {MEM_WR_0, MEM_WR_0_1}; // 8'h03 -> Calcopy{mem_wr[0]=mem_wr[1]=1}
    }

    cp_mem_be: coverpoint tx_out.mem_be {
      bins mem_be_vals = {MEM_BE_ALL_0, MEM_BE_ALL_0_1};
    }

    wr_X_addr_X_be: cross cp_mem_wr, cp_mem_wr_addr, cp_mem_be {
      bins complete_write =
          binsof(cp_mem_wr.mem_wr_vals) &&
          binsof(cp_mem_wr_addr.mem_wr_addr_vals) &&  // Writing to addr 1 (both MEM0 and MEM1)
          binsof(cp_mem_be.mem_be_vals);
    }
  endgroup
  
  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void write_mem_cov_in(input xlr_mem_tx t);
  extern function void write_mem_cov_out(input xlr_mem_tx t);
  extern function void final_phase(uvm_phase phase);

  //===================
  //  Helper Methods
  //===================
  extern function automatic bit words_in_0_k(logic [7:0][31:0] tx, int unsigned k);
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

  cg_in.option.at_least  = m_xlr_mem_config.cov_hit_thrshld; // # Of hits = # Of Sequences
  cg_out.option.at_least = m_xlr_mem_config.cov_hit_thrshld; // Set the Coverage based on Cfg Knob

  tx_in  = xlr_mem_tx::type_id::create("tx_in");
  tx_out = xlr_mem_tx::type_id::create("tx_out"); // F

  mem_cov_in_export  = new("mem_cov_in_export",  this);
  mem_cov_out_export = new("mem_cov_out_export", this);
endfunction // Boilerplate + m_cov constrct.


function void xlr_mem_coverage::write_mem_cov_in(input xlr_mem_tx t);
  tx_in.copy(t);
  if (m_xlr_mem_config.coverage_enable)
  begin
    `honeyb("Hello", "Mem Coverage In | ", $sformatf("coverage_enable = %0d", m_xlr_mem_config.coverage_enable))
    cg_in.sample();
    if (cg_in.get_inst_coverage() >= 100) cg_in_is_covered = 1;
  end
endfunction


function void xlr_mem_coverage::write_mem_cov_out(input xlr_mem_tx t); 
  tx_out.copy(t);
    if (m_xlr_mem_config.coverage_enable)
    begin
      `honeyb("Hello", "Mem Coverage Out")
      cg_out.sample();
      if (cg_out.get_inst_coverage() >= 100) cg_out_is_covered = 1;
    end
endfunction


function void xlr_mem_coverage::final_phase(uvm_phase phase);
  if (m_xlr_mem_config.coverage_enable) begin
    `honeyb("Coverage", $sformatf("[IN ] Coverage score      = %.1f%%", cg_in.get_inst_coverage()))
      //`honeyb("DEBUG", $sformatf("cg_in_is_covered = %0d", cg_in_is_covered))
    `honeyb("Coverage", $sformatf("[OUT] Coverage score      = %.1f%%", cg_out.get_inst_coverage()))
      //`honeyb("DEBUG", $sformatf("cg_out_is_covered = %0d", cg_out_is_covered))
      $display(); // CLI
  end else begin
    `honeyb("Coverage", "Coverage disabled for the MEM agent")
      $display(); // CLI
  end
endfunction : final_phase


//=============================================
//            Coverage Helper Methods
//=============================================

function automatic bit xlr_mem_coverage::words_in_0_k(logic [7:0][31:0] tx, int unsigned k);
  //logic [31:0] k32 = logic [31:0]'(k);   // pure cast, no $func
  foreach (tx[i]) begin
    if ((^tx[i]) === 1'bx)    return 1'b0;
    if (tx[i] > k) return 1'b0;
  end
  return 1'b1;
endfunction

`endif // XLR_MEM_COVERAGE_SV


//===================
//      Extras
//===================
  /*
    int unsigned   rdata_uppr_rng = 20;
    int unsigned wdata_uppr_rng   = 400;

    cp_mem_rdata: coverpoint tx_in.mem_rdata[0] {
      bins mem_rdata_vals = {[0:$]} with (item != 0);
    }

    cp_mem_wdata: coverpoint tx_out.mem_wdata[1] {
      bins mem_wdata_vals = {[0:$]} with (item != 0);
    }

    cp_mem_rdata: coverpoint tx_in.mem_rdata iff (all_small) {
      bins rdata_all_small_rng = { ['0:'1] }; // fires when all_small==1
    }

    cp_mem_wdata: coverpoint tx_out.mem_wdata iff (w_all_small) {
      bins wdata_all_small_rng = { ['0:'1] }; // fires only when all 8 words ≤ 400
    }

    function xlr_mem_coverage::new(string name, uvm_component parent);
      super.new(name, parent);
      cg_in  = new;
      cg_out = new;
    endfunction // Boilerplate + CG New

    function void xlr_mem_coverage::write_mem_cov_in(input xlr_mem_tx t);
      tx_in.copy(t);
      if (m_xlr_mem_config.coverage_enable)
      begin
        bit all_small = 1'b1;
        int cnt_zero_wrds = 0;
        foreach (tx_in.mem_rdata[i]) begin
          if ((^tx_in.mem_rdata[i]) === 1'bx) all_small = 1'b0;         // X/Z check
          else begin 
            if (tx_in.mem_rdata[i] > rdata_uppr_rng) all_small = 1'b0; // 0..k
            if (tx_in.mem_rdata[i] == '0) cnt_zero_wrds++;
          end
        end
        if (cnt_zero_wrds == 8) all_small = 1'b0;
        `honeyb("Hello", "Mem Coverage In | ", $sformatf("coverage_enable = %0d", m_xlr_mem_config.coverage_enable))
        cg_in.sample(tx_in, all_small);
        if (cg_in.get_inst_coverage() >= 100) cg_in_is_covered = 1;
      end
    endfunction


    function void xlr_mem_coverage::write_mem_cov_out(input xlr_mem_tx t); 
      tx_out.copy(t);
        if (m_xlr_mem_config.coverage_enable)
        begin
          bit w_all_small = 1'b1;
          int cnt_zero_wrds = 0;
          foreach (tx_out.mem_wdata[i]) begin
            if ((^tx_out.mem_wdata[i]) === 1'bx) w_all_small = 1'b0;  // X/Z check
            else begin 
              if (tx_out.mem_wdata[i] > wdata_uppr_rng) w_all_small = 1'b0; // 0..400
              if (tx_out.mem_wdata[i] == '0) cnt_zero_wrds++; // != 0
            end
          end
          if (cnt_zero_wrds == 8) w_all_small = 1'b0;
          `honeyb("Hello", "Mem Coverage Out")
          cg_out.sample(tx_out, w_all_small);
          if (cg_out.get_inst_coverage() >= 100) cg_out_is_covered = 1;
        end
    endfunction
  */
