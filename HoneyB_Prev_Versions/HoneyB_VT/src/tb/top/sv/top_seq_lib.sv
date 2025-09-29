//=============================================================================
// Project  : HoneyB V1
// File Name: top_seq_lib.sv
//=============================================================================
// Description: Sequence for top
//=============================================================================

`ifndef TOP_SEQ_LIB_SV
`define TOP_SEQ_LIB_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class top_default_seq extends uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(top_default_seq)

  xlr_mem_agent  m_xlr_mem_agent;
  xlr_gpp_agent  m_xlr_gpp_agent;

  // Sequence #
  int m_seq_count = 2;

  // Sequence iteration counter
  int iteration_count = 0;

  extern function new(string name = "");
  extern task body();
  extern task pre_start();
  extern task post_start();

`ifndef UVM_POST_VERSION_1_1
  // Functions to support UVM 1.2 objection API in UVM 1.1
  extern function uvm_phase get_starting_phase();
  extern function void set_starting_phase(uvm_phase phase);
`endif

endclass : top_default_seq


function top_default_seq::new(string name = "");
  super.new(name);
endfunction : new


task top_default_seq::body();
  `honeyb("Top Sequence", "Default Sequence starting...")

  repeat (m_seq_count)
  begin
    // Debug Statement : Check if Seq Started & Iteration #
    `honeyb("Top Sequence", $sformatf("[TOP] Sequence stating new iteration %0d...", iteration_count))
    fork
      if (m_xlr_mem_agent.m_config.is_active == UVM_ACTIVE)
      begin
        xlr_mem_default_seq seq;
        seq = xlr_mem_default_seq::type_id::create("seq");
        seq.set_item_context(this, m_xlr_mem_agent.m_sequencer);
        if ( !seq.randomize() )
          `uvm_error("", "Failed to randomize sequence")
        seq.set_starting_phase( get_starting_phase() );
        seq.start(m_xlr_mem_agent.m_sequencer, this);

        // Debug Statement : Check MEM sequence completion & iteration #
        `honeyb("Top Sequence", $sformatf("[MEM] Sequence completed, iteration count: %0d...", iteration_count))
      end
      if (m_xlr_gpp_agent.m_config.is_active == UVM_ACTIVE)
      begin
        xlr_gpp_default_seq seq;
        seq = xlr_gpp_default_seq::type_id::create("seq");
        seq.set_item_context(this, m_xlr_gpp_agent.m_sequencer);
        if ( !seq.randomize() )
          `uvm_error("", "Failed to randomize sequence")
        seq.set_starting_phase( get_starting_phase() );
        seq.start(m_xlr_gpp_agent.m_sequencer, this);

        // Debug Statement : Check GPP sequence completion & iteration #
        `honeyb("Top Sequence", $sformatf("[GPP] Sequence completed, iteration count: %0d...", iteration_count))
      end
    join

    // Debug Statement : Check that a full iteration was completed
    `honeyb("Top Sequence", $sformatf("[TOP] Sequence completed, iteration count: %0d...", iteration_count))
  end
  `honeyb("Top Sequence", "Default Sequence completed...")
endtask : body


task top_default_seq::pre_start();
  uvm_phase phase = get_starting_phase();
  if (phase != null)
    phase.raise_objection(this);
endtask: pre_start


task top_default_seq::post_start();
  uvm_phase phase = get_starting_phase();
  if (phase != null) 
    phase.drop_objection(this);
endtask: post_start


`ifndef UVM_POST_VERSION_1_1
  function uvm_phase top_default_seq::get_starting_phase();
    return starting_phase;
  endfunction: get_starting_phase


  function void top_default_seq::set_starting_phase(uvm_phase phase);
    starting_phase = phase;
  endfunction: set_starting_phase
`endif

`endif // TOP_SEQ_LIB_SV