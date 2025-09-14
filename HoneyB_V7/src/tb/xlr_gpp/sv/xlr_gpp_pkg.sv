//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_gpp_pkg.sv
//=============================================================================
// Description: Package for agent xlr_gpp
//=============================================================================
`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
package xlr_gpp_pkg;

  // START ASSERTION CHECK
  // =====================
  function logic is_start_asserted(logic [31:0] reg_val, logic valid);
    return (reg_val == 32'h1) && valid;
  endfunction

  function logic is_calcopy_asserted(logic [31:0] reg_val, logic valid);
    return (reg_val == 32'h2) && valid;
  endfunction

  // BUSY ASSERTION CHECK
  // ====================
  function logic busy_is_asserted(logic [31:0] reg_val, logic valid);
    return (reg_val == 32'h1) && valid;
  endfunction
  function logic busy_is_deasserted (logic [31:0] reg_val, logic valid); // host_valid[BUSY_IDX_REX] == 1'b1 ALWAYS
    return (reg_val == 32'h0) && valid;
  endfunction

  // DONE ASSERTION CHECK
  // ====================
  function logic done_is_asserted(logic [31:0] reg_val, logic valid);
    return (reg_val == 32'h1) && valid;
  endfunction
  function logic done_is_deasserted (logic [31:0] reg_val, logic valid);
    return (reg_val == 32'h0) && !valid;
  endfunction

  // UNUSED
  // ======
  /*
    function logic [31:0] busy_reg_format(logic busy_state);
      return busy_state ? 32'h1 : 32'h0;
    endfunction
    
    function logic [31:0] done_reg_format(logic done_state);
      return done_state ? 32'h1 : 32'h0;
    endfunction
    function logic [31:0] get_reg_value(logic [31:0][31:0] host_regs, regs_idx idx);
    return host_regs[int'(idx)];
    endfunction
    function logic get_reg_valid(logic [31:0] host_regs_valid, regs_idx idx);
      return host_regs_valid[int'(idx)];
    endfunction
    function logic is_start_asserted(logic [31:0] reg_val, logic valid);
      return (reg_val == 32'h1) && valid;
    endfunction
    function logic [31:0] format_busy_reg(logic busy_state);
      return busy_state ? 32'h1 : 32'h0;
    endfunction
    function logic [31:0] format_done_reg(logic done_state);
      return done_state ? 32'h1 : 32'h0;
    endfunction
  */
endpackage : xlr_gpp_pkg