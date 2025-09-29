//=============================================================================
// Project  : HoneyB V2
// File Name: xlr_mem_config.sv
//=============================================================================
// Description: Configuration for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_CONFIG_SV
`define XLR_MEM_CONFIG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;

class xlr_mem_config extends uvm_object;

    // Do not register config class with the factory

    virtual xlr_mem_if       vif;
                    
    uvm_active_passive_enum  is_active = UVM_ACTIVE;
    bit                      coverage_enable;       
    bit                      checks_enable;     

    // # of sequences for the parameterized IF - may be unnecessary.
    /*  Further explanation for using "count" :
        This can be used within xlr_mem_seq_lib by getting the cfg db
        and the idea is to be able to configure how many times we want to LIMIT
        the child sequences based on a certain need. in our case, we probably don't
        want to limit it, since we're interested in using the sequence as many times
        as our xlr requires it, therefore it should be commencted out.*/
    int unsigned count; 

    // This string is used for cfg the params of the if - IMPORTANT !!
    string iface_string;    

    extern function new(string name = "");
endclass : xlr_mem_config 

function xlr_mem_config::new(string name = "");
    super.new(name);
endfunction : new

`endif // XLR_MEM_CONFIG_SV

