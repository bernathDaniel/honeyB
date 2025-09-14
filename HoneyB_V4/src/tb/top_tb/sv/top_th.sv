//=============================================================================
// Project  : HoneyB V4
// File Name: top_th.sv
//=============================================================================
// Description: Test Harness
//=============================================================================

import honeyb_pkg::*;
import xlr_mem_pkg::*;

module top_th;

  timeunit      1ns;
  timeprecision 1ps;

  logic     clk;
  logic     rst_n;
  parameter hclk_per = 4;

  /********************************************************/
  /*       Pin-level interfaces connected to DUT          */
  /********************************************************/

  xlr_mem_if #(
    .NUM_MEMS             (2      ),
    .LOG2_LINES_PER_MEM   (8      )
  ) _mem_if_28 ( // Naming Convention -  _mem_if_14 = [NUM_MEMS = 1, LOG2_LINES_PER_NUM = 4]
    .clk                  (clk    ),
    .rst_n                (rst_n  )
  );

  xlr_gpp_if _gpp_if (
    .clk                  (clk    ),
    .rst_n                (rst_n  )
  );

  /********************************************************/
  /*                  Instantiate the DUT                 */
  /********************************************************/

  xbox_xlr_dmy1 #(
    .NUM_MEMS               (2                        ),
    .LOG2_LINES_PER_MEM     (8                        )
    ) dut (
    .clk                    (_mem_if_28.clk           ),
    .rst_n                  (_mem_if_28.rst_n         ),
    .xlr_mem_addr           (_mem_if_28.mem_addr      ),
    .xlr_mem_wdata          (_mem_if_28.mem_wdata     ),
    .xlr_mem_be             (_mem_if_28.mem_be        ),
    .xlr_mem_rd             (_mem_if_28.mem_rd        ),
    .xlr_mem_wr             (_mem_if_28.mem_wr        ),
    .xlr_mem_rdata          (_mem_if_28.mem_rdata     ),
    .host_regs              (_gpp_if.host_regsi       ),
    .host_regs_valid_pulse  (_gpp_if.host_regs_valid  ),                                       
    .host_regs_data_out     (_gpp_if.host_regso       ),
    .host_regs_valid_out    (_gpp_if.host_regso_valid )
  );

  /********************************************************/
  /*                    clk & rst_n gen                   */
  /********************************************************/

  // clk gen
  //--------------------------
  initial clk = 0;
  always #hclk_per clk = ~clk;

  // rst_n gen 
  //--------------------------
  // TODO - If there's enough time, try exercising with an added delay of ~ #10 before assertion

  initial begin
    rst_n = 1'b1;
    rst_n = 1'b0;        
    #20
    rst_n = 1'b1; // Desassert reset after 20ns
  end
endmodule

