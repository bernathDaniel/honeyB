//=============================================================================
// Project  : HoneyB V3
// File Name: xlr_reg2mem_adapter.sv
//=============================================================================
// Description: Adapter for xlr_mem used to convert TLM to REG protocol
//=============================================================================

`ifndef XLR_REG2MEM_ADAPTER_SV
`define XLR_REG2MEM_ADAPTER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

class xlr_reg2mem_adapter extends uvm_reg_adapter;
  `uvm_object_utils(xlr_reg2mem_adapter)

  extern function new(string name = "");
  extern function xlr_mem_tx reg2mem(const ref uvm_reg_bus_op rw); // "ref" = call by reference, just like in C
  extern function void mem2reg(uvm_sequence_item t, ref uvm_reg_bus_op rw);
endclass : xlr_reg2mem_adapter

function xlr_reg2mem_adapter::new(string name = "");
  super.new(name);
endfunction : new

function xlr_mem_tx xlr_reg2mem_adapter::reg2mem(const ref uvm_reg_bus_op rw);
  xlr_mem_tx tx;
  int mem_idx;
  bit [31:0] rel_addr; // Relative address to MEM0 or MEM1
  bit [31:0] mem_block_base_addr; // The offset for the addr MEM0 get 0 and MEM1 get 8192

  tx = xlr_mem_tx::type_id::create("tx");

  mem_idx = rw.addr / ((1 << LOG2_LINES_PER_MEM) * NUM_BYTES); // = 0 or 1
  mem_block_base_addr = mem_idx * ((1 << LOG2_LINES_PER_MEM) * NUM_BYTES); // Calc base address for MEM Block
  rel_addr = rw.addr - mem_block_base_addr; // Remove the offset to get the relative address.

  if (rw.kind == UVM_READ) begin
    tx.mem_rd[mem_idx] = 1'b1;
    tx.mem_addr[mem_idx] = rel_addr; // Assign the relative address.
    tx.mem_rdata[mem_idx] = rw.data; // Assign the data read from the memory.
    // tx.mem_be[mem_idx] = rw.byte_en; // Implement later
  end else if (rw.kind == UVM_WRITE) begin
    tx.mem_wr[mem_idx] = 1'b1;
    tx.mem_addr[mem_idx] = rel_addr; // Assign the relative addr
    tx.mem_wdata[mem_idx] = rw.data;
    // tx.mem_be[mem_idx] = rw.btye_en; // Implement later
  end
  
  `honeyb("RAL ADAPTER[reg2mem]", $sformatf("RAL Sending:\nrw.kind=%s\nrw.addr=%h\nmem_idx=%0d\nrel_addr=%h\nrw.data=%h", rw.kind.name(), rw.addr, mem_idx, rel_addr, rw.data))

  return tx;
endfunction : reg2mem

function void xlr_reg2mem_adapter::mem2reg(uvm_sequence_item t, ref uvm_reg_bus_op rw);
  xlr_mem_tx tx;
  if (!$cast(tx, t))
    `uvm_fatal(get_type_name(),"Provided t transaction is not of the correct type")


  if (tx.mem_rd[0] == 1'b1) begin
    rw.kind = UVM_READ;
    rw.addr = tx.mem_addr[0];
    rw.data = tx.mem_rdata[0];
    rw.byte_en = tx.mem_be[0];
    rw.status = UVM_IS_OK;
  end else if (tx.mem_rd[1] == 1'b1) begin
    rw.kind = UVM_READ;
    rw.addr = tx.mem_addr[1] + 8'((1 << LOG2_LINES_PER_MEM) * NUM_BYTES);
    rw.data = tx.mem_rdata[1];
    rw.byte_en = tx.mem_be[1];
    rw.status = UVM_IS_OK;
  end else if (tx.mem_wr[0] == 1'b1) begin
    rw.kind = UVM_WRITE;
    rw.addr = tx.mem_addr[0];
    rw.data = tx.mem_wdata[0];
    rw.byte_en = tx.mem_be[0];
    rw.status = UVM_IS_OK;
  end else if (tx.mem_wr[1] == 1'b1) begin
    rw.kind = UVM_WRITE;
    rw.addr = tx.mem_addr[1] + 8'((1 << LOG2_LINES_PER_MEM) * NUM_BYTES);
    rw.data = tx.mem_wdata[1];
    rw.byte_en = tx.mem_be[1];
    rw.status = UVM_IS_OK;
  end

  `honeyb("RAL ADAPTER[mem2reg]", $sformatf("RAL Received:\nrw.kind=%s\nrw.addr=%h\nrw.data=%h", rw.kind.name(), rw.addr, rw.data))
endfunction : mem2reg

`endif // XLR_REG2MEM_ADAPTER_SV




