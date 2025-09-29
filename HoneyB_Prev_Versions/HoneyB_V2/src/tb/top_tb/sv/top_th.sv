//=============================================================================
// Project  : HoneyB V2
// File Name: top_th.sv
//=============================================================================
// Description: Test Harness
//=============================================================================

import honeyb_pkg::*;
import xlr_mem_pkg::*;

module top_th;

  timeunit      1ns;
  timeprecision 1ps;

  logic clk;
  logic rst_n;
  parameter hclk_per = 4;

  // Pin-level interfaces connected to DUT

  xlr_mem_if #(
    .NUM_MEMS(2),
    .LOG2_LINES_PER_MEM(4)
  ) _mem_if_24 ( // Naming Convention -  _mem_if_14 = [NUM_MEMS = 1, LOG2_LINES_PER_NUM = 4]
    .clk(clk),
    .rst_n(rst_n)
  );

  /* || The more advanced version - V3 - Coming soon
    | Option 1 - Direct :
    xlr_mem_if #(
      .NUM_MEMS(2),
      .LOG2_LINES_PER_MEM(8)
    ) _mem_if_28 ( // Naming Convention - _mem_if_28 = [NUM_MEMS = 2, LOG2_LINES_PER_NUM = 8]
      .clk(clk),
      .rst_n(rst_n)
    );
    | Option 2 - Parameterizing 100 :
    xlr_mem_if #(
      .NUM_MEMS(NUM_MEMS),
      .LOG2_LINES_PER_MEM(LOG2_LINES_PER_MEM)
    ) _mem_if_hb ( // Naming Convention - _mem_if_hb = check our pkg to see the chosen params
      .clk(clk),
      .rst_n(rst_n)
    );*/

  xlr_gpp_if _gpp_if (
    .clk(clk),
    .rst_n(rst_n)
  );

  /* || IMPORTANT : 
    ||----------------------------------------||
    ||                                        ||
    ||  In order to connect the DUT           ||
    ||  with the agent's virtual IF we        ||
    ||  need to assign into the DUT ports     ||
    ||  the agent IF signals as seen below    ||
    ||  from this moment the setting of the   ||
    ||  virtual IF is done in a reusable way  ||
    ||                                        ||
    ||----------------------------------------||*/

  // Instantiate the dut
  xbox_xlr_dmy1 #(
    .NUM_MEMS(2),
    .LOG2_LINES_PER_MEM(4)
    ) dut (
    .clk(_mem_if_24.clk),
    .rst_n(_mem_if_24.rst_n),
    .xlr_mem_addr(_mem_if_24.mem_addr),
    .xlr_mem_wdata(_mem_if_24.mem_wdata),
    .xlr_mem_be(_mem_if_24.mem_be),
    .xlr_mem_rd(_mem_if_24.mem_rd),
    .xlr_mem_wr(_mem_if_24.mem_wr),
    .xlr_mem_rdata(_mem_if_24.mem_rdata),
    .host_regs(_gpp_if.host_regsi),
    .host_regs_valid_pulse(_gpp_if.host_regs_valid),                                       
    .host_regs_data_out(_gpp_if.host_regso),
    .host_regs_valid_out(_gpp_if.host_regso_valid)
  );

  /* || The More Advanced Version - V3 - Coming Soon
    | Option 1 - Direct :
    xbox_xlr_dmy1 #(
      .NUM_MEMS(2),
      .LOG2_LINES_PER_MEM(8)
      ) dut (
      .clk(_mem_if_28.clk),
      .rst_n(_mem_if_28.rst_n),
      .xlr_mem_addr(_mem_if_28.mem_addr),
      .xlr_mem_wdata(_mem_if_28.mem_wdata),
      .xlr_mem_be(_mem_if_28.mem_be),
      .xlr_mem_rd(_mem_if_28.mem_rd),
      .xlr_mem_wr(_mem_if_28.mem_wr),
      .xlr_mem_rdata(_mem_if_28.mem_rdata),
      .host_regs(_gpp_if.host_regsi),
      .host_regs_valid_pulse(_gpp_if.host_regs_valid),                                       
      .host_regs_data_out(_gpp_if.host_regso),
      .host_regs_valid_out(_gpp_if.host_regso_valid)
    );
    | Option 2 - Parameterizing 100 :
    xbox_xlr_dmy1 #(
      .NUM_MEMS(NUM_MEMS),
      .LOG2_LINES_PER_MEM(LOG2_LINES_PER_MEM)
      ) dut (
      .clk(_mem_if_hb.clk),
      .rst_n(_mem_if_hb.rst_n),
      .xlr_mem_addr(_mem_if_hb.mem_addr),
      .xlr_mem_wdata(_mem_if_hb.mem_wdata),
      .xlr_mem_be(_mem_if_hb.mem_be),
      .xlr_mem_rd(_mem_if_hb.mem_rd),
      .xlr_mem_wr(_mem_if_hb.mem_wr),
      .xlr_mem_rdata(_mem_if_hb.mem_rdata),
      .host_regs(_gpp_if.host_regsi),
      .host_regs_valid_pulse(_gpp_if.host_regs_valid),                                       
      .host_regs_data_out(_gpp_if.host_regso),
      .host_regs_valid_out(_gpp_if.host_regso_valid)
    );*/

  // clk gen
  initial clk = 0;
  always #hclk_per clk = ~clk;

  // rst_n gen - TODO: rst_n = 1 -> rst_n = 0 -> rst_n = 1 !
  initial
  begin
    rst_n = 0;        
    #20
    rst_n = 1; // Desassert reset after 100ns delay
  end
endmodule

