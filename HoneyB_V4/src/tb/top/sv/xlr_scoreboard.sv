//=============================================================================
// Project        : HoneyB V4
// File Name      : xlr_scoreboard.sv
//=============================================================================
// Description    : Scoreboard for top
/* DFC ThumbRule  : Declare it, Factorize it, Copy it.                                                                                                        
                    --------------------------------------|
                    This original catchy hook is meant to | 
                    EMPHASIZE the importance of order in  |
                    the Scrbd to ensure the Best practice | 
                    of Storage in TLM to avoid issues.    |
                    --------------------------------------|                                                                                                                                              */
//=============================================================================

`ifndef TOP_XLR_SCOREBOARD_SV
`define TOP_XLR_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_gpp_pkg::*;

// Declaration for multiple exports
`uvm_analysis_imp_decl(_mem_ref) // MEM TX's from REF
`uvm_analysis_imp_decl(_mem_dut) // MEM TX's from DUT
`uvm_analysis_imp_decl(_gpp_ref) // GPP TX's from REF
`uvm_analysis_imp_decl(_gpp_dut) // GPP TX's from DUT

class xlr_scoreboard extends uvm_scoreboard;

  // Register the scoreboard with the factory
  `uvm_component_utils(xlr_scoreboard)

  // TLM ports to receive transactions from both agents
  // xlr_mem agent ports - DUT | REF
  uvm_analysis_imp_mem_ref #(xlr_mem_tx, xlr_scoreboard) mem_ref_export;
  uvm_analysis_imp_mem_dut #(xlr_mem_tx, xlr_scoreboard) mem_dut_export;

  // xlr_gpp agent ports - DUT | REF
  uvm_analysis_imp_gpp_ref #(xlr_gpp_tx, xlr_scoreboard) gpp_ref_export;
  uvm_analysis_imp_gpp_dut #(xlr_gpp_tx, xlr_scoreboard) gpp_dut_export;

  // Separate queues for each agent and type, "$" = flexible sizing
  xlr_mem_tx mem_ref_queue[$];
  xlr_mem_tx mem_dut_queue[$];
  xlr_gpp_tx gpp_ref_queue[$];
  xlr_gpp_tx gpp_dut_queue[$];

  // Statistics for reporting
  int mem_match_count     = 0;
  int mem_mismatch_count  = 0;
  int gpp_match_count     = 0;
  int gpp_mismatch_count  = 0;

  extern          function      new           (string     name, uvm_component parent);
  extern          function void build_phase   (uvm_phase  phase);

  extern virtual  function void write_mem_ref (xlr_mem_tx tx);
  extern virtual  function void write_gpp_ref (xlr_gpp_tx tx);
  extern virtual  function void write_mem_dut (xlr_mem_tx tx);
  extern virtual  function void write_gpp_dut (xlr_gpp_tx tx);

  extern          function void compare_mem_transactions();
  extern          function void compare_gpp_transactions();

  extern virtual  function void report_phase  (uvm_phase phase);
endclass : xlr_scoreboard

// Constructor
function xlr_scoreboard::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


// Build Phase
function void xlr_scoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);
  mem_ref_export = new("mem_ref_export", this);
  mem_dut_export = new("mem_dut_export", this);
  gpp_ref_export = new("gpp_ref_export", this);
  gpp_dut_export = new("gpp_dut_export", this);
endfunction : build_phase                                                                                                                                                               /*


|===================================================================|
|/             ---------------------------------------             \|
||             |           Storage functions         |             ||
||             ---------------------------------------             ||
||             |         STORE REF & DUT QUEUES      |             ||
|\             ---------------------------------------             /|
|===================================================================|


 STORAGE [MEM] || Reference Model
===============================================================                                                                                             */

function void xlr_scoreboard::write_mem_ref(xlr_mem_tx tx);

 /* The DFC Rule: Declare it, Factorize it, Copy it:
 -------------------------------------------------------                                                                                                  */ 
  xlr_mem_tx stored_tx;
  stored_tx = xlr_mem_tx::type_id::create("stored_tx");
  stored_tx.copy(tx);                                                                                                                                     /*
 -------------------------------------------------------                                                                                                  */

  // Queue it up:
  mem_ref_queue.push_back(stored_tx); // End-Of-Queue Insertion

  // Report
  `honeyb("MEM REF SCRBD", "Write Request Received! ")
  stored_tx.print();
endfunction : write_mem_ref                                                                                                                                                               /*
===============================================================

 STORAGE [GPP]|| Reference Model
===============================================================                                                                                                   */

function void xlr_scoreboard::write_gpp_ref(xlr_gpp_tx tx);
  
  /* The DFC Rule: Declare it, Factorize it, Copy it:
 -------------------------------------------------------                                                                                                  */ 
  xlr_gpp_tx stored_tx;
  stored_tx = xlr_gpp_tx::type_id::create("stored_tx");
  stored_tx.copy(tx);                                                                                                                                     /*
 -------------------------------------------------------                                                                                                  */

  // Queue it up:
  gpp_ref_queue.push_back(stored_tx); // End-Of-Queue Insertion


  // Log Busy Signal
  if (busy_is_asserted( stored_tx.host_regso      [BUSY_IDX_REG],
                        stored_tx.host_regso_valid[BUSY_IDX_REG]))
  begin
    `honeyb("GPP REF SCRBD", "Received BUSY signal...")
    stored_tx.print();
  end

  // Log Done Signal
  if (done_is_asserted( stored_tx.host_regso      [DONE_IDX_REG],
                        stored_tx.host_regso_valid[DONE_IDX_REG]))
  begin
    `honeyb("GPP REF SCRBD", "Received DONE signal...")
    stored_tx.print();
  end
endfunction : write_gpp_ref                                                                                                                                                               /*
===============================================================

 STORAGE [MEM] || Design Under Test
===============================================================                                                                                                                 */

function void xlr_scoreboard::write_mem_dut(xlr_mem_tx tx);

 /* The DFC Rule: Declare it, Factorize it, Copy it:
 -------------------------------------------------------                                                                                                  */ 
  xlr_mem_tx stored_tx;
  stored_tx = xlr_mem_tx::type_id::create("stored_tx");
  stored_tx.copy(tx);                                                                                                                                     /*
 -------------------------------------------------------                                                                                                  */

  // Queue it up:
  mem_dut_queue.push_back(stored_tx); // End-Of-Queue Insertion

  // Report
  `honeyb("MEM DUT SCRBD", "Write Request Received! ")
  stored_tx.print();  

  /*  COMPARISON [MEM]:
  -------------------------------------------------------                                                                                                      */
  compare_mem_transactions();                                                                                                                                 /*
  -------------------------------------------------------                                                                                                        */
endfunction : write_mem_dut                                                                                                                                                               /*
===============================================================

 STORAGE [GPP] || Design Under Test
===============================================================                                                                                                */

function void xlr_scoreboard::write_gpp_dut(xlr_gpp_tx tx);
  
  
  /* The DFC Rule: Declare it, Factorize it, Copy it:
 -------------------------------------------------------                                                                                                  */ 
  xlr_gpp_tx stored_tx;
  stored_tx = xlr_gpp_tx::type_id::create("stored_tx");
  stored_tx.copy(tx);                                                                                                                                     /*
 -------------------------------------------------------                                                                                                  */

  // Queue it up:
  gpp_dut_queue.push_back(stored_tx); // End-Of-Queue Insertion


  // Log Busy Signal
  if (busy_is_asserted( stored_tx.host_regso      [BUSY_IDX_REG],
                        stored_tx.host_regso_valid[BUSY_IDX_REG]))
  begin
    `honeyb("GPP DUT SCRBD", "Received BUSY signal...")
    stored_tx.print();
  end

  // Log Done Signal
  if (done_is_asserted( stored_tx.host_regso      [DONE_IDX_REG],
                        stored_tx.host_regso_valid[DONE_IDX_REG]))
  begin
    `honeyb("GPP DUT SCRBD", "Received DONE signal...")
    stored_tx.print();
  end

    /*  COMPARISON [GPP]:
  -------------------------------------------------------                                                                                                      */
  compare_gpp_transactions();                                                                                                                                 /*
  -------------------------------------------------------                                                                                                        */
endfunction : write_gpp_dut                                                                                                                                               /*

|===================================================================|
|/             ---------------------------------------             \|
||             |           Compare functions         |             ||
||             ---------------------------------------             ||
||             |        COMPARE REF & DUT QUEUES     |             ||
|\             ---------------------------------------             /|
|===================================================================|


 COMPARE [MEM] || Reference Model & Design Under Test
===============================================================                                                                                                                         */

function void xlr_scoreboard::compare_mem_transactions();                                                                                                     /*
  
  Declare & Factorize
  -------------------------------------------------------                                                                                                     */
  xlr_mem_tx ref_tx;
  ref_tx = xlr_mem_tx::type_id::create("ref_tx");                                                                                                             /*
  -------------------------------------------------------                                                                                                     */
  xlr_mem_tx dut_tx;
  dut_tx = xlr_mem_tx::type_id::create("dut_tx");                                                                                                             /*
  -------------------------------------------------------                                                                                                     */
  bit result;                                                                                                                                                                       /*
  -------------------------------------------------------                                                                                                     */

  `honeyb("MEM COMPARE", "Comparing...", $sformatf("Queue Sizes : MEM_REF = %0d MEM_DUT = %0d", mem_ref_queue.size(), mem_dut_queue.size()))
  
  // Check if both queues have transactions
  if (mem_ref_queue.size() > 0 && mem_dut_queue.size() > 0) begin
    
    /* Get transactions from the front of the queues
    -----------------------------------------------------                                                                                                      */
    ref_tx = mem_ref_queue.pop_front();
    dut_tx = mem_dut_queue.pop_front();                                                                                                                                                                       /*
    -----------------------------------------------------                                                                                                     */
    result = ref_tx.compare(dut_tx);                                                                                                                                                                       /*
    -----------------------------------------------------                                                                                                     */

    if (result) begin /* Event-specific success reporting
    -----------------------------------------------------
      /* WR         Report: */  if      (ref_tx.e_mode == "wr")    `honeyb("MEM COMPARE", "MEM WR TXs match!")
      /* RST_O      Report: */  else if (ref_tx.e_mode == "rst_o") `honeyb("MEM COMPARE", "MEM RST_O TX match!")
      /* Unexpected Report: */  else    `uvm_warning("MEM COMPARE", $sformatf("Unexpected e_mode '%s' in MEM comparison", ref_tx.e_mode))
      /* Incr. match count: */  mem_match_count++;
    end else begin /* Event-specific failure reporting                                                                                                        /*     
    --------------------------------------------------
      /* WR         Report: */  if      (ref_tx.e_mode == "wr")    `uvm_warning("MEM COMPARE", "MEM WR TXs mismatch!")
      /* RST_O      Report: */  else if (ref_tx.e_mode == "rst_o") `uvm_warning("MEM COMPARE", "MEM RST_O TX mismatch!")
      /* Unexpected Report: */  else    `uvm_warning("MEM COMPARE", $sformatf("Unexpected e_mode '%s' in MEM comparison", ref_tx.e_mode))
      /* Incr. match count: */  mem_mismatch_count++;
      /* Prnt DUT Mismatch: */  dut_tx.print();
      /* Prnt REF Mismatch: */  ref_tx.print();
    end
  end
endfunction : compare_mem_transactions                                                                                                                                                               /*
===============================================================

 COMPARE [GPP] || Reference Model & Design Under Test
===============================================================                                                                                                                 */

function void xlr_scoreboard::compare_gpp_transactions();                                                                                                     /*
  
  Declare & Factorize
  -------------------------------------------------------                                                                                                     */
  xlr_gpp_tx ref_tx;
  ref_tx = xlr_gpp_tx::type_id::create("ref_tx");                                                                                                             /*
  -------------------------------------------------------                                                                                                     */
  xlr_gpp_tx dut_tx;
  dut_tx = xlr_gpp_tx::type_id::create("dut_tx");                                                                                                             /*
  -------------------------------------------------------                                                                                                     */
  bit result;                                                                                                                                                                       /*
  -------------------------------------------------------                                                                                                     */

  `honeyb("GPP COMPARE", "Comparing...", $sformatf("Queue Sizes : GPP_REF = %0d GPP_DUT = %0d", gpp_ref_queue.size(), gpp_dut_queue.size()))
  // Check if both queues have transactions
  if (gpp_ref_queue.size() > 0 && gpp_dut_queue.size() > 0) begin

    /* Get transactions from the front of the queues
    -----------------------------------------------------                                                                                                      */
    ref_tx = gpp_ref_queue.pop_front();
    dut_tx = gpp_dut_queue.pop_front();                                                                                                                                                                       /*
    -----------------------------------------------------                                                                                                     */
    result = ref_tx.compare(dut_tx);                                                                                                                                                                       /*
    -----------------------------------------------------                                                                                                     */


    if (result) begin /* Event-specific success reporting
    -----------------------------------------------------
      /* RST_O      Report: */ if      (ref_tx.e_mode == "rst_o") `honeyb("GPP COMPARE", "GPP RST_O TX match!")
      /* BUSY       Report: */ else if (ref_tx.e_mode == "busy" ) `honeyb("GPP COMPARE", "GPP BUSY  TX match!")
      /* DONE       Report: */ else if (ref_tx.e_mode == "done" ) `honeyb("GPP COMPARE", "GPP DONE  TX match!")
      /* Unexpected Report: */ else    `uvm_warning("GPP COMPARE", $sformatf("Unexpected e_mode '%s' in GPP comparison", ref_tx.e_mode))
      /* Incr. match count: */ gpp_match_count++;
    end else begin /* Event-specific failure reporting                                                                                                        /*     
    --------------------------------------------------
      /* RST_O      Report: */ if      (ref_tx.e_mode == "rst_o") `uvm_warning("GPP COMPARE", "GPP RST_O TX mismatch!")
      /* BUSY       Report: */ else if (ref_tx.e_mode == "busy" ) `uvm_warning("GPP COMPARE", "GPP BUSY  TX mismatch!")
      /* DONE       Report: */ else if (ref_tx.e_mode == "done" ) `uvm_warning("GPP COMPARE", "GPP DONE  TX mismatch!")
      /* Unexpected Report: */ else    `uvm_warning("GPP COMPARE", $sformatf("Unexpected e_mode '%s' in GPP comparison", ref_tx.e_mode))
      /* Incr. match count: */ gpp_mismatch_count++;
      /* Prnt DUT Mismatch: */ dut_tx.print();
      /* Prnt REF Mismatch: */ ref_tx.print();
    end
  end
endfunction : compare_gpp_transactions


//*******************************************//
//                Report Phase               //
// ---------------------------------------   //
//               Display Results             //
//*******************************************//

function void xlr_scoreboard::report_phase(uvm_phase phase);
  `honeyb("", "Scoreboard Report:")
  `honeyb("", "--------------------------")
  `honeyb("", $sformatf("MEM Matches    : %0d", mem_match_count))
  `honeyb("", $sformatf("MEM Mismatches : %0d", mem_mismatch_count))
  `honeyb("", $sformatf("GPP Matches    : %0d", gpp_match_count))
  `honeyb("", $sformatf("GPP Mismatches : %0d", gpp_mismatch_count))

  // Check for pending transactions
  if (mem_ref_queue.size() > 0) begin
    `honeyb("WARNING", $sformatf("%0d MEM REF TXs not compared", mem_ref_queue.size()))
    `uvm_warning("", "")
  end
  
  if (mem_dut_queue.size() > 0) begin
    `honeyb("WARNING", $sformatf("%0d MEM DUT TXs not compared", mem_dut_queue.size()))
    `uvm_warning("", "")
  end
  
  if (gpp_ref_queue.size() > 0) begin
    `honeyb("WARNING", $sformatf("%0d GPP REF TXs not compared", gpp_ref_queue.size()))
    `uvm_warning("", "")
  end
  
  if (gpp_dut_queue.size() > 0) begin
    `honeyb("WARNING", $sformatf("%0d GPP DUT TXs not compared", gpp_dut_queue.size()))
    `uvm_warning("", "")
  end
endfunction : report_phase

`endif // TOP_XLR_SCOREBOARD_SV




                                                                                                                                                                                                      /*
  %%%%%%%%%%%%%%%%%%%%%%%%%
  %         EXTRAS        %
  %%%%%%%%%%%%%%%%%%%%%%%%%

   /*Event Case Handling + Comparison - Based on e_mode
    //-----------------------------------------------------                                                                                                      
    if (ref_tx.e_mode == "rst_o") begin
      // Reset output event comparison  
      result = ref_tx.compare(dut_tx);
      if (result) begin
        `honeyb("GPP COMPARE", "GPP RST_O TX match!")
        gpp_match_count++;
      end else begin
        `uvm_warning("GPP COMPARE", "GPP RST_O TX mismatch!")
        gpp_mismatch_count++;
        dut_tx.print();
        ref_tx.print();
      end
    end else if (ref_tx.e_mode == "busy") begin
      // Busy signal event comparison
      result = ref_tx.compare(dut_tx);
      if (result) begin
        `honeyb("GPP COMPARE", "GPP BUSY TX match!")
        gpp_match_count++;
      end else begin
        `uvm_warning("GPP COMPARE", "GPP BUSY TX mismatch!")
        gpp_mismatch_count++;
        dut_tx.print();
        ref_tx.print();
      end
    end else if (ref_tx.e_mode == "done") begin
      // Done signal event comparison
      result = ref_tx.compare(dut_tx);
      if (result) begin
        `honeyb("GPP COMPARE", "GPP DONE TX match!")
        gpp_match_count++;
      end else begin
        `uvm_warning("GPP COMPARE", "GPP DONE TX mismatch!")
        gpp_mismatch_count++;
        dut_tx.print();
        ref_tx.print();
      end
    end else begin
      // Handle unexpected e_mode values
      `uvm_warning("GPP COMPARE", $sformatf("Unexpected e_mode: %s", ref_tx.e_mode))
    end

  if (ref_tx.e_mode == "rst_i") begin
    // Reset input event comparison
    result = ref_tx.compare(dut_tx);
    if (result) begin
      `honeyb("GPP COMPARE", "GPP RST_I TX match!")
      gpp_match_count++;
    end else begin
      `uvm_warning("GPP COMPARE", "GPP RST_I TX mismatch!")
      gpp_mismatch_count++;
      dut_tx.print();
      ref_tx.print();
    end
  end else

  // Edge Case Handling + Comparison
      -----------------------------------------------------                                                                                                      */
      /* rst_n = 1'b1 : 
      if (!rst_n_deasserted && busy_is_deasserted ( ref_tx.host_regso       [BUSY_IDX_REG],
                                                    ref_tx.host_regso_valid [BUSY_IDX_REG]))
      begin
        rst_n_deasserted = 1'b1;
        result = ref_tx.compare(dut_tx);

        if (result)
        begin
          `honeyb("GPP COMPARE", "GPP TX rst_n match!")
          gpp_match_count++;
        end
        else
        begin
          gpp_mismatch_count++;

          // Debug Report
          `uvm_warning("GPP COMPARE", "GPP TX rst_n mismatch!")
          dut_tx.print();
          ref_tx.print();
        end
      end

      if (busy_is_asserted (ref_tx.host_regso       [BUSY_IDX_REG],
                            ref_tx.host_regso_valid [BUSY_IDX_REG]))
      if (ref_tx.host_regso[0] == 32'h1 && ref_tx.host_regso_valid[0] == 1'b1) begin // Compare busy signal
        // Perform the comparison using our do_compare() override
        ref_tx.set_e_mode("busy");
        result = ref_tx.compare(dut_tx);  // Use do_compare()

        if (result) begin
          `honeyb("GPP COMPARE", "GPP BUSY TX match!")
          gpp_match_count++; // Increment match count
        end else begin
          `uvm_warning("", "GPP BUSY TX mismatch!")
          gpp_mismatch_count++; // Increment mismatch count
          // If there's a mismatch : print the transactions for debugging
          dut_tx.set_e_mode("busy");
          dut_tx.print();
          ref_tx.print();
        end

      end else if (ref_tx.host_regso[1] == 32'h1 && ref_tx.host_regso_valid[1] == 1'b1) begin // compare done signal
        ref_tx.set_e_mode("done");
        result = ref_tx.compare(dut_tx);

        if (result) begin
          `honeyb("GPP COMPARE", "GPP DONE TX match!")
          gpp_match_count++; // Increment match count
        end else begin
          `uvm_warning("", "GPP DONE TX mismatch!")
          gpp_mismatch_count++; // Increment mismatch count
          // If there's a mismatch : print the transactions for debugging
          dut_tx.set_e_mode("done");
          dut_tx.print();
          ref_tx.print();
        end
      end
  .
                                                                                                                                                                                                          */