`ifndef XLR_MEM_IF_SV
`define XLR_MEM_IF_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*; // for parameters
import xlr_mem_pkg::*; // for parameterized _if

interface xlr_mem_if #(parameter NUM_MEMS = 2, LOG2_LINES_PER_MEM = 8) (
  input logic clk,
  input logic rst_n
);

  timeunit      1ns;
  timeprecision 1ps;

  // Inputs
  logic [NUM_MEMS-1:0] [7:0][31:0] mem_rdata;

  // Outputs
  logic [NUM_MEMS-1:0] [LOG2_LINES_PER_MEM-1:0] mem_addr;
  logic [NUM_MEMS-1:0] [7:0][31:0]              mem_wdata;
  logic [NUM_MEMS-1:0] [31:0]                   mem_be;
  logic [NUM_MEMS-1:0]                          mem_rd;
  logic [NUM_MEMS-1:0]                          mem_wr;

  // Setting the class parameters to 0 - Default values to emphasize that we're factory overriding them later

  class xlr_mem_class #(int NUM_MEMS = 0, int LOG2_LINES_PER_MEM = 0) extends xlr_mem_if_base;
    `uvm_component_param_utils(xlr_mem_class#(NUM_MEMS,LOG2_LINES_PER_MEM))

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    /* -> Optional (Less Preferred) Implementations for "get_clk() & get_rst_n()" using Task methods
      //task get_clk(output logic o_clk);
      //  o_clk = clk;
      //endtask : get_clk

      //task get_rst_n(output logic o_rst_n);
      //  o_rst_n = rst_n;
      //endtask : get_rst_n
    */

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
    //                   Get Methods                  //
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

    /*############################################################################################################################*/

    function logic  get_clk();          return clk;         endfunction

    task clk_wait_posedge();          @(posedge clk);       endtask

    task clk_wait_negedge();          @(negedge clk);       endtask

    /*############################################################################################################################*/

    function logic  get_rst_n();  return rst_n; endfunction

    task rst_n_wait_posedge();        @(posedge rst_n);     endtask

    task rst_n_wait_until_deassert(); wait(rst_n == 1'b1);  endtask

    /*############################################################################################################################*/

    function logic [NUM_MEMS-1:0][7:0][31:0] get_rdata_all();
      return mem_rdata;
    endfunction

    function logic [7:0][31:0] get_rdata(int i);
      assert (i >= 0 && i < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(), $sformatf("get_rdata: i = %0d OOR, 0 <= i <= %0d Only!", i, NUM_MEMS-1))
        return '0; // Placate Compiler
      end
      return mem_rdata[i];
    endfunction

    /*############################################################################################################################*/
    
    function logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] get_addr_all(); // Needed for rst_n assertion handling in Monitor
      return mem_addr;
    endfunction

    function logic [LOG2_LINES_PER_MEM-1:0] get_addr(int i);
      assert (i >= 0 && i < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(), $sformatf("get_addr: i = %0d OOR, 0 <= i <= %0d Only!", i, NUM_MEMS-1))
        return '0; // Placate Compiler
      end
      return mem_addr[i];
    endfunction

    /*############################################################################################################################*/

    function logic [NUM_MEMS-1:0][7:0][31:0] get_wdata_all();
      return mem_wdata;
    endfunction

    function logic [7:0][31:0] get_wdata(int i);
      assert (i >= 0 && i < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(), $sformatf("get_wdata: i = %0d OOR, 0 <= i <= %0d Only!", i, NUM_MEMS-1))
        return '0; // Placate Compiler
      end
      return mem_wdata[i];
    endfunction

    /*############################################################################################################################*/

    function logic [NUM_MEMS-1:0] get_rd_all();
      return mem_rd;
    endfunction

    function logic get_rd(int i);
      assert (i >= 0 && i < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(), $sformatf("get_rd: i = %0d OOR, 0 <= i <= %0d Only!", i, NUM_MEMS-1))
        return '0; // Placate Compiler
      end
      return mem_rd[i];
    endfunction

    /*############################################################################################################################*/

    function logic [NUM_MEMS-1:0] get_wr_all();
      return mem_wr;
    endfunction

    function logic get_wr(int i); // OOR = Out Of Order
      assert (i >= 0 && i < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(), $sformatf("get_wr: i = %0d OOR, 0 <= i <= %0d Only!", i, NUM_MEMS-1))
        return '0; // Placate Compiler
      end
      return mem_wr[i];
    endfunction

    /*############################################################################################################################*/

    function logic [NUM_MEMS-1:0][31:0] get_be_all();
      return mem_be;
    endfunction

    function logic [31:0] get_be(int i);
      assert (i >= 0 && i < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(), $sformatf("get_be: i = %0d OOR, 0 <= i <= %0d Only!", i, NUM_MEMS-1))
        return '0; // Placate Compiler
      end
      return mem_be[i];
    endfunction

    /*############################################################################################################################*/

    task rd_wait_until_asserted(input int mem_idx);
      assert (mem_idx >= 0 && mem_idx < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(),
            $sformatf("rd_wait_until_asserted: mem_idx = %0d OOR, 0 <= mem_idx <= %0d Only!", mem_idx, NUM_MEMS-1))
        return; // Placate Compiler
      end
      wait(mem_rd[mem_idx] == 1'b1);
    endtask : rd_wait_until_asserted

    task wr_wait_until_asserted(input int mem_idx);
      assert (mem_idx >= 0 && mem_idx < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(),
            $sformatf("wr_wait_until_asserted: mem_idx=%0d OOR, 0 <= mem_idx <= %0d Only!", mem_idx, NUM_MEMS-1))
        return; // placate compiler if fatal behavior is customized
      end
      wait (mem_wr[mem_idx] == 1'b1);
    endtask : wr_wait_until_asserted

    task pin_wig( // A pin wiggling method designed for the Driver - the only pins it can wiggle is mem_rdata.
      input logic [7:0][31:0] m_rdata,
      input int mem_idx
    );
      assert (mem_idx >= 0 && mem_idx < NUM_MEMS) else begin
        `uvm_fatal(get_type_name(), $sformatf("pin_wig: mem_idx = %0d OOR, 0 <= mem_idx <= %0d Only!", mem_idx, NUM_MEMS-1))
        return; // Placate Compiler
      end
      mem_rdata[mem_idx] <= m_rdata;
    endtask : pin_wig

    task rst_pin_wig();
      mem_rdata <= '0;
    endtask
    
  endclass : xlr_mem_class
  
  // Function to override abstract base class with concrete implementation of class
  // called from tb_prepend_to_initial.sv
  // The path_name is key to overriding the correct parameterized instantiation

  function void use_concrete_class();
    string path_name;
    path_name = $sformatf("*.xlr_mem_if_%0d_%0d", NUM_MEMS, LOG2_LINES_PER_MEM);
    xlr_mem_if_base::type_id::set_inst_override( xlr_mem_class#(NUM_MEMS,LOG2_LINES_PER_MEM)::get_type(), path_name, null);
  endfunction : use_concrete_class
endinterface : xlr_mem_if

`endif // XLR_MEM_IF_SV