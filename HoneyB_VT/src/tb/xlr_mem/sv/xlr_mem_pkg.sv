//=============================================================================
// Project  : HoneyB V2
// File Name: xlr_mem_pkg.sv
//=============================================================================
// Description: Package for agent xlr_mem
//=============================================================================

package xlr_mem_pkg;

	`include "uvm_macros.svh"
	import uvm_pkg::*;
	import honeyb_pkg::*;

  class xlr_mem_if_base extends uvm_component;
    `uvm_component_utils(xlr_mem_if_base)
    
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Methods to be called from the UVM verification env :
    // If I got it right, these tasks aren't supposed to be actually called,
    // we'll call the tasks within xlr_mem_class located in "xlr_mem_if.sv"
    // The sole purpose of this whole class is for the parameterization trick
    //--------------------------------------------------------------------------

    //virtual task get_clk(output logic o_clk); // Optional Implementation, less preferred for Non-Timing Operations
    //  `uvm_error(get_type_name(),"get_clk not implemented")
    //endtask : get_clk

    //virtual task get_rst_n(output logic o_rst_n); // Optional Implementation, less preferred for Non-Timing Operations
    //  `uvm_error(get_type_name(),"get_rst_n not implemented")
    //endtask : get_rst_n

    virtual function logic get_clk();
      `uvm_error(get_type_name(), "get_clk not implemented")
      return '0;
    endfunction

    virtual function logic get_rst_n();
      `uvm_error(get_type_name(), "get_rst_n not implemented")
      return '0;
    endfunction

    virtual function logic [NUM_MEMS-1:0][7:0][31:0] get_rdata_all();
      `uvm_error(get_type_name(), "get_rdata_all not implemented")
      return '0;
    endfunction

    virtual function logic [7:0][31:0] get_rdata(int i);
      `uvm_error(get_type_name(), "get_rdata not implemented")
      return '0;
    endfunction
    
    virtual function logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] get_addr_all(); // Needed for rst_n assertion handling in Monitor
      `uvm_error(get_type_name(), "get_addr_all not implemented")
      return '0;
    endfunction

    virtual function logic [LOG2_LINES_PER_MEM-1:0] get_addr(int i);
      `uvm_error(get_type_name(), "get_addr not implemented")
      return '0;
    endfunction

    virtual function logic [NUM_MEMS-1:0][7:0][31:0] get_wdata_all();
      `uvm_error(get_type_name(), "get_wdata_all not implemented")
      return '0;
    endfunction

    virtual function logic [7:0][31:0] get_wdata(int i);
      `uvm_error(get_type_name(), "get_wdata not implemented")
      return '0;
    endfunction

    virtual function logic [NUM_MEMS-1:0] get_rd_all();
      `uvm_error(get_type_name(), "get_rd_all not implemented")
      return '0;
    endfunction

    virtual function logic get_rd(int i);
      `uvm_error(get_type_name(), "get_rd not implemented")
      return '0;
    endfunction

    virtual function logic [NUM_MEMS-1:0] get_wr_all();
      `uvm_error(get_type_name(), "get_wr_all not implemented")
      return '0;
    endfunction

    virtual function logic get_wr(int i);
      `uvm_error(get_type_name(), "get_wr not implemented")
      return '0;
    endfunction

    virtual function logic [NUM_MEMS-1:0][31:0] get_be_all();
      `uvm_error(get_type_name(), "get_be_all not implemented")
      return '0;
    endfunction

    virtual function logic [31:0] get_be(int i);
      `uvm_error(get_type_name(), "get_be not implemented")
      return '0;
    endfunction

    virtual task clk_wait_posedge();
      `uvm_error(get_type_name(),"clk_wait_posedge not implemented")
    endtask : clk_wait_posedge

    virtual task clk_wait_negedge();
      `uvm_error(get_type_name(),"clk_wait_negedge not implemented")
    endtask : clk_wait_negedge

    virtual task rst_n_wait_posedge();
      `uvm_error(get_type_name(),"rst_n_wait_posedge not implemented")
    endtask : rst_n_wait_posedge

    virtual task rst_n_wait_until_deassert();
      `uvm_error(get_type_name(),"rst_n_wait_until_deassert not implemented")
    endtask : rst_n_wait_until_deassert

    virtual task rd_wait_until_asserted(input int mem_idx);
      `uvm_error(get_type_name(),"rd_wait_until_asserted not implemented")
    endtask : rd_wait_until_asserted

    virtual task wr_wait_until_asserted(input int mem_idx);
      `uvm_error(get_type_name(),"wr_wait_until_asserted not implemented")
    endtask : wr_wait_until_asserted

    virtual task pin_wig(
      input logic [7:0][31:0] m_rdata,
      input int mem_idx
    );
      `uvm_error(get_type_name(), "pin_wig not implemented")
    endtask : pin_wig

    virtual task rst_pin_wig();
      `uvm_error(get_type_name(), "rst_pin_wig not implemented")
    endtask


    //--------------------------------------------------------------------------
    // the I/Os of this task needs to be changed according to the changes
    // I'll do later on for wr func !!!
    //--------------------------------------------------------------------------

    /*virtual task wr(
      input logic [NUM_MEMS-1:0]                          m_wr,
      input logic [NUM_MEMS-1:0] [LOG2_LINES_PER_MEM-1:0] m_addr,
      input logic [NUM_MEMS-1:0] [31:0]                   m_be,
      input logic [NUM_MEMS-1:0] [7:0][31:0]              m_wdata
    );
      `uvm_error(get_type_name(), "write not implemented")
    endtask : wr*/
  endclass
endpackage : xlr_mem_pkg
