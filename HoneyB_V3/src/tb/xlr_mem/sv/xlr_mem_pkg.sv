//=============================================================================
// Project  : HoneyB V3
// File Name: xlr_mem_pkg.sv
//=============================================================================
/* Description: Package for agent xlr_mem
    Abstract Base Class: The idea is to replace the virtual interface
    with a trick of creating this abstract class within SV env and
    instantiating it within UVM.
    This trick allows us to use all of UVM's features like Factory cfg
    and overriding and most importantly allowing us to implement
    multiple interfaces with different parameters at once with simple
    changes only.

    Methods: Since we're abandoning virtual interfaces, we're unable to
    directly access the interfaces signals like we used to.
    This forces us to fully implement the OOP methodologies like "get"
    functions allowing full encapsulation of the signals and creating
    meaningful method names to understand what we're trying to achieve.

    Virtual Methods: The base class has virtual methods as declarations,
    All of those are implemented within the extending class located in
    xlr_mem_if.sv file with the concrete class method that's doing
    all the parameterization tricks, more info in the WORD DOC...
    */ 
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

    virtual function logic get_clk();
      `uvm_error(get_type_name(), "get_clk not implemented")
    endfunction

    virtual function logic get_rst();
      `uvm_error(get_type_name(), "get_rst not implemented")
    endfunction

    virtual function logic [7:0][31:0] get_mem_rdata(input x_mem m);
      `uvm_error(get_type_name(), "get_mem_rdata not implemented")
    endfunction

    virtual function logic [LOG2_LINES_PER_MEM-1:0] get_mem_addr(input x_mem m);
      `uvm_error(get_type_name(), "get_mem_addr not implemented")
    endfunction

    virtual function logic [7:0][31:0] get_mem_wdata(input x_mem m);
      `uvm_error(get_type_name(), "get_mem_wdata not implemented")
    endfunction

    virtual function logic [31:0] get_mem_be(input x_mem m);
      `uvm_error(get_type_name(), "get_mem_be not implemented")
    endfunction

    virtual function logic get_mem_rd(input x_mem m);
      `uvm_error(get_type_name(), "get_mem_rd not implemented")
    endfunction

    virtual function logic get_mem_wr(input x_mem m);
      `uvm_error(get_type_name(), "get_mem_wr not implemented")
    endfunction

    virtual task wait4rd_req(input x_mem m);
      `uvm_error(get_type_name(), "wait4rd not implemented")
    endtask

    virtual task wait4wr_req(input x_mem m);
      `uvm_error(get_type_name(), "wait4wr not implemented")
    endtask

    virtual task posedge_clk(); // posedge clk delay
      `uvm_error(get_type_name(), "posedge_clk not implemented")
    endtask

    virtual task negedge_clk(); // negedge clk delay
      `uvm_error(get_type_name(), "negedge_clk not implemented")
    endtask

    virtual task wait4rst_n(); // wait for rst_n deassertion
      `uvm_error(get_type_name(), "wait4rst_n not implemented")
    endtask

    virtual task rd(
      input x_mem m,
      input logic [7:0][31:0] m_rdata
    );
      `uvm_error(get_type_name(), "read not implemented")
    endtask

    //--------------------------------------------------------------------------
    // the I/Os of this task needs to be changed according to the changes
    // I'll do later on for wr func !!!
    //--------------------------------------------------------------------------

  /*  virtual task wr(
      input logic [NUM_MEMS-1:0]                          m_wr,
      input logic [NUM_MEMS-1:0] [LOG2_LINES_PER_MEM-1:0] m_addr,
      input logic [NUM_MEMS-1:0] [31:0]                   m_be,
      input logic [NUM_MEMS-1:0] [7:0][31:0]              m_wdata
    );
      `uvm_error(get_type_name(), "write not implemented")
    endtask*/
  endclass : xlr_mem_if_base
endpackage : xlr_mem_pkg
