//=============================================================================
// Project  : HoneyB V2
// File Name: xlr_mem_seq_lib.sv
//=============================================================================
// Description: Sequence for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_SEQ_LIB_SV
`define XLR_MEM_SEQ_LIB_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;


class xlr_mem_default_seq extends uvm_sequence #(xlr_mem_tx);

    `uvm_object_utils(xlr_mem_default_seq)

    extern function new(string name = "");
    extern task body();

    `ifndef UVM_POST_VERSION_1_1
        // Functions to support UVM 1.2 objection API in UVM 1.1
        extern function uvm_phase get_starting_phase();
        extern function void set_starting_phase(uvm_phase phase);
    `endif
endclass : xlr_mem_default_seq


function xlr_mem_default_seq::new(string name = "");
    super.new(name);
endfunction : new


task xlr_mem_default_seq::body();
    `honeyb("MEM SEQ", "New sequence starting...")

    req = xlr_mem_tx::type_id::create("req");
    start_item(req); 
    if ( !req.randomize() )
        `uvm_error("", "Failed to randomize transaction")
    finish_item(req); 

    `honeyb("MEM SEQ", "Sequence completed...")
endtask : body


`ifndef UVM_POST_VERSION_1_1
    function uvm_phase xlr_mem_default_seq::get_starting_phase();
        return starting_phase;
    endfunction: get_starting_phase

    function void xlr_mem_default_seq::set_starting_phase(uvm_phase phase);
        starting_phase = phase;
    endfunction: set_starting_phase
`endif


`ifndef XLR_MEM_1_4_SEQ_SV
`define XLR_MEM_1_4_SEQ_SV

class xlr_mem_seq extends xlr_mem_default_seq;
    `uvm_object_utils(xlr_mem_seq)

    // rand byte data; // TODO : Figure out what's it used for

    xlr_mem_config m_xlr_mem_config; // currently unused

    // constructor
    function new(string name = "");
        super.new(name);
    endfunction : new

    task body();

        `honeyb("MEM SEQ", "New sequence starting...")

        req = xlr_mem_tx::type_id::create("req");
        start_item(req); 
        if ( !req.randomize() )
            `uvm_error("", "Failed to randomize transaction")
        finish_item(req); 

        `honeyb("MEM SEQ", "Sequence completed...")
    endtask : body

    /* New Body for later use, currently use the default seq.
        task body();
            `honeyb("MEM SEQ", "xlr_mem_seq SEQ starting..")            
            if ( !uvm_config_db#(xlr_mem_config)::get(get_sequencer(), "", "config", m_xlr_mem_config) )
                `uvm_error(get_type_name(), "Failed to get config object")
            
            for (int i = 0; i < xlr_mem_config.count; i++) begin
                req = data_tx::type_id::create("req");
                start_item(req); 
                if ( !req.randomize() with { data == i; })
                    `uvm_warning(get_type_name(), "randomization failed!")
                finish_item(req); 
            end

            #40ns; // Allow some extra time
            
            `honeyb("MEM SEQ", "xlr_mem_seq SEQ completed..")  
        endtask : body*/
endclass : xlr_mem_seq
`endif // XLR_MEM_1)4_SEQ_SV

/*`ifndef XLR_MEM_2_8_SEQ_SV - Coming soon V3..
    `define XLR_MEM_2_8_SEQ_SV

    class xlr_mem_2_8_seq extends xlr_mem_default_seq;
        `uvm_object_utils(xlr_mem_2_8_seq)

        // rand byte data; // TODO : Figure out what's it used for

        xlr_mem_config m_xlr_mem_config;

        // constructor
        function new(string name = "");
            super.new(name);
        endfunction : new

        task body();
            `uvm_info(get_type_name(), "xlr_mem_2_8_seq sequence starting", UVM_MEDIUM)
            
            if ( !uvm_config_db#(xlr_mem_config)::get(get_sequencer(), "", "config", m_xlr_mem_config) )
                `uvm_error(get_type_name(), "Failed to get config object")
            
            for (int i = 0; i < xlr_mem_config.count; i++) begin
                req = data_tx::type_id::create("req");
                start_item(req); 
                if ( !req.randomize() with { data == i; })
                    `uvm_warning(get_type_name(), "randomization failed!")
                finish_item(req); 
            end

            #40ns; // Allow some extra time
            
            `uvm_info(get_type_name(), "xlr_mem_2_8_seq sequence completed", UVM_MEDIUM)
        endtask : body
    endclass : xlr_mem_2_8_seq
`endif // XLR_MEM_2_8_SEQ_SV*/

`endif // XLR_MEM_SEQ_LIB_SV

