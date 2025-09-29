//=============================================================================
// Project  : HoneyB V4
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

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
    //                   Get Methods                  //
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

    /*############################################################################################################################*/

    virtual function logic get_clk();
      `uvm_error(get_type_name(), "get_clk not implemented")
      return '0;
    endfunction

    virtual task clk_posedge_wait();
      `uvm_error(get_type_name(), "clk_posedge_wait not implemented")
    endtask

    virtual task clk_negedge_wait();
      `uvm_error(get_type_name(), "clk_negedge_wait not implemented")
    endtask

    /*############################################################################################################################*/

    virtual function logic get_rst_n();
      `uvm_error(get_type_name(), "get_rst not implemented")
      return '0;
    endfunction

    virtual task rst_n_posedge_wait();
      `uvm_error(get_type_name(),"rst_n_posedge_wait not implemented")
    endtask

    virtual task rst_n_wait_until_deassert();
      `uvm_error(get_type_name(),"rst_n_wait_until_deassert not implemented")
    endtask

    /*############################################################################################################################*/

    virtual function logic [NUM_MEMS-1:0][7:0][31:0] get_rdata_all();
      `uvm_error(get_type_name(), "get_rdata_all not implemented")
      return '0;
    endfunction

    virtual function logic [7:0][31:0] get_rdata(input x_mem m);
      `uvm_error(get_type_name(), "get_rdata not implemented")
      return '0;
    endfunction

    /*############################################################################################################################*/

    virtual function logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] get_addr_all(); // Needed for rst_n assertion handling in Monitor
      `uvm_error(get_type_name(), "get_addr_all not implemented")
      return '0;
    endfunction

    virtual function logic [LOG2_LINES_PER_MEM-1:0] get_addr(input x_mem m);
      `uvm_error(get_type_name(), "get_addr not implemented")
      return '0;
    endfunction

    /*############################################################################################################################*/

    virtual function logic [NUM_MEMS-1:0][7:0][31:0] get_wdata_all();
      `uvm_error(get_type_name(), "get_wdata_all not implemented")
      return '0;
    endfunction

    virtual function logic [7:0][31:0] get_wdata(input x_mem m);
      `uvm_error(get_type_name(), "get_wdata not implemented")
      return '0;
    endfunction

    /*############################################################################################################################*/

    virtual function logic [NUM_MEMS-1:0][31:0] get_be_all();
      `uvm_error(get_type_name(), "get_be_all not implemented")
      return '0;
    endfunction

    virtual function logic [31:0] get_be(input x_mem m);
      `uvm_error(get_type_name(), "get_be not implemented")
      return '0;
    endfunction

    /*############################################################################################################################*/

    virtual function logic [NUM_MEMS-1:0] get_rd_all();
      `uvm_error(get_type_name(), "get_rd_all not implemented")
      return '0;
    endfunction

    virtual function logic get_rd(input x_mem m);
      `uvm_error(get_type_name(), "get_rd not implemented")
      return '0;
    endfunction

    virtual task rd_wait_until_asserted(input x_mem m);
      `uvm_error(get_type_name(), "rd_wait_until_asserted not implemented")
    endtask

    /*############################################################################################################################*/

    virtual function logic [NUM_MEMS-1:0] get_wr_all();
      `uvm_error(get_type_name(), "get_wr_all not implemented")
      return '0;
    endfunction

    virtual function logic get_wr(input x_mem m);
      `uvm_error(get_type_name(), "get_wr not implemented")
      return '0;
    endfunction

    virtual task wr_wait_until_asserted(input x_mem m);
      `uvm_error(get_type_name(), "wr_wait_until_asserted not implemented")
    endtask

    /*############################################################################################################################*/

    virtual task pin_wig_rst();
      `uvm_error(get_type_name(), "pin_wig_rdata not implemented")
    endtask
    
    virtual task pin_wig_rdata(
      input x_mem m,
      input logic [7:0][31:0] m_rdata
    );
      `uvm_error(get_type_name(), "pin_wig_rdata not implemented")
    endtask
    
    /*############################################################################################################################*/
  endclass : xlr_mem_if_base
endpackage : xlr_mem_pkg
