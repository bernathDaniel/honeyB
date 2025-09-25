//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_gpr_adapter.sv
//=============================================================================
// Description: Adapter for xlr_gpp
//=============================================================================

`ifndef XLR_GPP_ADAPTER_SV
`define XLR_GPP_ADAPTER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_gpp_adapter extends uvm_reg_adapter;
  `uvm_object_utils(xlr_gpp_adapter)

  extern function new(string name = "");
  extern virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
  extern virtual function void bus2reg(uvm_sequence_item bus_item, const ref uvm_reg_bus_op rw);
endclass

function xlr_gpp_adapter::new(string name ="");
  super.new(name);
endfunction

function uvm_sequence_item xlr_gpp_adapter::reg2bus(const ref uvm_reg_bus_op rw);
    xlr_apb_tx bus;
    bus = xlr_apb_tx::type_id::create("bus");
    
    bus.cmd_valid = 1'b1;                            // Valid transaction
    bus.cmd = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;  // Write=1, Read=0  
    bus.addr = rw.addr;
    bus.data = rw.data;
    return bus;
endfunction

function void xlr_gpp_adapter::bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
  xlr_apb_tx bus;
    if (!$cast(bus, bus_item))
        `uvm_fatal(get_type_name(),"Provided bus_item is not of the correct type")
    
    rw.kind = bus.cmd ? UVM_WRITE : UVM_READ;
    rw.addr = bus.addr;
    rw.data = bus.data;
    rw.status = UVM_IS_OK;
endfunction

`endif // XLR_GPP_ADAPTER_SV

//=====================
//      EXTRAS
//=====================
  /*
  gpr_bus_item bus_item = gpr_bus_item::type_id::create("bus_item");
    
    // Map register data
    bus_item.host_regs[rw.addr/4] = rw.data;
    
    // Generate valid pulse for writes
    if (rw.kind == UVM_WRITE) begin
      bus_item.host_regs_valid_pulse[rw.addr/4] = 1'b1;
    end
    
    return bus_item;

  */