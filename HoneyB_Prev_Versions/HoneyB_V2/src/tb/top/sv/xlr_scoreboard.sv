//=============================================================================
// Project  : HoneyB V2
// File Name: xlr_scoreboard.sv
//=============================================================================
// Description: Scoreboard for top
//=============================================================================

`ifndef TOP_XLR_SCOREBOARD_SV
`define TOP_XLR_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;

// Declaration for multiple exports
`uvm_analysis_imp_decl(_mem_ref) // MEM TX's from REF
`uvm_analysis_imp_decl(_mem_dut) // MEM TX's from DUT
`uvm_analysis_imp_decl(_gpp_ref) // GPP TX's from REF
`uvm_analysis_imp_decl(_gpp_dut) // GPP TX's from DUT

class xlr_scoreboard extends uvm_scoreboard;

    // Register the scoreboard with the factory
    `uvm_component_utils(xlr_scoreboard)

    // TLM ports to receive transactions from both agents
    // xlr_mem agent ports
    uvm_analysis_imp_mem_ref #(xlr_mem_tx, xlr_scoreboard) mem_ref_export;
    uvm_analysis_imp_mem_dut #(xlr_mem_tx, xlr_scoreboard) mem_dut_export;

    // xlr_gpp agent ports
    uvm_analysis_imp_gpp_ref #(xlr_gpp_tx, xlr_scoreboard) gpp_ref_export;
    uvm_analysis_imp_gpp_dut #(xlr_gpp_tx, xlr_scoreboard) gpp_dut_export;

    // Separate queues for each agent and type
    // the [$] indicated that the array dimensions are flexible depending on the TX's size instead of a fixed array size
    xlr_mem_tx mem_ref_queue[$];
    xlr_mem_tx mem_dut_queue[$];
    xlr_gpp_tx gpp_ref_queue[$];
    xlr_gpp_tx gpp_dut_queue[$];

    // Statistics for reporting
    int mem_match_count = 0;
    int mem_mismatch_count = 0;
    int gpp_match_count = 0;
    int gpp_mismatch_count = 0;

    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern virtual function void write_mem_ref(xlr_mem_tx tx);
    extern virtual function void write_gpp_ref(xlr_gpp_tx tx);
    extern virtual function void write_mem_dut(xlr_mem_tx tx);
    extern virtual function void write_gpp_dut(xlr_gpp_tx tx);
    extern function void compare_mem_transactions();
    extern function void compare_gpp_transactions();
    extern virtual function void report_phase(uvm_phase phase);
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
endfunction : build_phase


//*****************************************//
//             Write functions             //
// --------------------------------------- //
// The Write REF funcs get the tx's first  //
// so they only store and don't compare    //
// The Write DUT funcs get the tx's last   //
// so they don't store, only compare       //
//*****************************************//

// Analysis implementation for memory reference transactions
function void xlr_scoreboard::write_mem_ref(xlr_mem_tx tx);

    xlr_mem_tx stored_tx;

    stored_tx = xlr_mem_tx::type_id::create("stored_tx"); // Local var, not a class member !

    // Clone the transaction before storing it
    stored_tx.copy(tx);

    // Simply add to the reference queue - no comparison yet
    mem_ref_queue.push_back(stored_tx);

    // Print what we got here
    `honeyb("MEM REF SCRBD", "Received wr req...")
    tx.set_mem(MEM0);
    tx.set_mode("wr");
    tx.print();
endfunction : write_mem_ref


// Analysis implementation for GPP reference transactions
function void xlr_scoreboard::write_gpp_ref(xlr_gpp_tx tx);
    xlr_gpp_tx stored_tx;

    stored_tx = xlr_gpp_tx::type_id::create("stored_tx"); // Local var, not a class member !

    // Clone the transaction before storing it
    stored_tx.copy(tx);

    // Simply add to the reference queue - no comparison yet
    gpp_ref_queue.push_back(stored_tx);

    // Log Busy Signal
    if (stored_tx.host_regso[0] == 32'h1 && stored_tx.host_regso_valid[0] == 1'b1) begin
        `honeyb("GPP REF SCRBD", "Received BUSY signal...")
        tx.set_mode("busy");
        tx.print();
    end

    // Log Done Signal
    if (stored_tx.host_regso[1] == 32'h1 && stored_tx.host_regso_valid[1] == 1'b1) begin
        `honeyb("GPP REF SCRBD", "Received DONE signal...")
        tx.set_mode("done");
        tx.print();
    end
endfunction : write_gpp_ref


// Analysis implementation for memory DUT transactions
function void xlr_scoreboard::write_mem_dut(xlr_mem_tx tx);
    xlr_mem_tx stored_tx;

    stored_tx = xlr_mem_tx::type_id::create("stored_tx"); // Local var, not a class member !

    // Clone the transaction before storing it
    stored_tx.copy(tx);

    // Add to the DUT queue
    mem_dut_queue.push_back(stored_tx);

    // Print what we got here
    `honeyb("MEM DUT SCRBD", "Received wr req...")
    tx.set_mem(MEM0);
    tx.set_mode("wr");
    tx.print();


    // Now trigger comparison since DUT transaction has arrived
    compare_mem_transactions();
endfunction : write_mem_dut


// Analysis implementation for GPP DUT transactions
function void xlr_scoreboard::write_gpp_dut(xlr_gpp_tx tx);
    xlr_gpp_tx stored_tx;

    stored_tx = xlr_gpp_tx::type_id::create("stored_tx"); // Local var, not a class member !

    // Clone the transaction before storing it
    stored_tx.copy(tx);

    // Add to the DUT queue
    gpp_dut_queue.push_back(stored_tx);

    // Print what we got here
    // Log Busy Signal
    if (stored_tx.host_regso[0] == 32'h1 && stored_tx.host_regso_valid[0] == 1'b1) begin
        `honeyb("GPP DUT SCRBD", "Received BUSY signal...")
        tx.set_mode("busy");
        tx.print();
    end

    // Log Done Signal
    if (stored_tx.host_regso[1] == 32'h1 && stored_tx.host_regso_valid[1] == 1'b1) begin
        `honeyb("GPP DUT SCRBD", "Received DONE signal...")
        tx.set_mode("done");
        tx.print();
    end

    // Now trigger comparison since DUT transaction has arrived
    compare_gpp_transactions();
endfunction : write_gpp_dut


//*******************************************//
//             Compare functions             //
// ---------------------------------------   //
//          COMPARE REF & DUT QUEUES         //
//*******************************************//

function void xlr_scoreboard::compare_mem_transactions();
    xlr_mem_tx ref_tx;
    xlr_mem_tx dut_tx;
    bit result;
    ref_tx = xlr_mem_tx::type_id::create("ref_tx"); // Local var, not a class member !
    dut_tx = xlr_mem_tx::type_id::create("dut_tx"); // Local var, not a class member !
    `honeyb("MEM COMPARE", "Comparing...", $sformatf("Queue Sizes : MEM_REF = %0d MEM_DUT = %0d", mem_ref_queue.size(), mem_dut_queue.size()))
    // Check if both queues have transactions
    if (mem_ref_queue.size() > 0 && mem_dut_queue.size() > 0) begin
        // Get transactions from the front of the queues
        ref_tx = mem_ref_queue.pop_front();
        dut_tx = mem_dut_queue.pop_front();

        // Perform the comparison using our do_compare() override
        ref_tx.set_mem(MEM0);
        ref_tx.set_mode("wr"); // compare wr op
        result = ref_tx.compare(dut_tx);

        if (result) begin
            `honeyb("MEM COMPARE", "MEM WR TXs match!")
            mem_match_count++; // Increment match count
        end else begin
            `uvm_warning("", "MEM WR TXs mismatch!");
            mem_mismatch_count++; // Increment mismatch counthost_regso_valid[0]
            // If there's a mismatch : print the transactions for debugging
            dut_tx.set_mem(MEM0);
            dut_tx.set_mode("wr");
            dut_tx.print();
            ref_tx.print();
        end
    end
endfunction : compare_mem_transactions


function void xlr_scoreboard::compare_gpp_transactions();
    xlr_gpp_tx ref_tx;
    xlr_gpp_tx dut_tx;
    bit result;
    bit rst_deasserted = 1'b0;
    ref_tx = xlr_gpp_tx::type_id::create("ref_tx"); // Local var, not a class member !
    dut_tx = xlr_gpp_tx::type_id::create("dut_tx"); // Local var, not a class member !
    `honeyb("GPP COMPARE", "Comparing...", $sformatf("Queue Sizes : GPP_REF = %0d GPP_DUT = %0d", gpp_ref_queue.size(), gpp_dut_queue.size()))
    // Check if both queues have transactions
    if (gpp_ref_queue.size() > 0 && gpp_dut_queue.size() > 0) begin
        // Get transactions from the front of the queues
        ref_tx = gpp_ref_queue.pop_front();
        dut_tx = gpp_dut_queue.pop_front();

        if (ref_tx.host_regso[0] == '0 && ref_tx.host_regso_valid[0] == 1'b1 && !rst_deasserted) begin // reset
            rst_deasserted = 1'b1;
            ref_tx.set_mode("out");
            result = ref_tx.compare(dut_tx);
            if (result) begin
                `honeyb("GPP COMPARE", "GPP TX rst_n match!")
                gpp_match_count++; // Increment match count
            end else begin
                `uvm_warning("", "GPP TX rst_n mismatch!")
                gpp_mismatch_count++; // Increment mismatch count
                // If there's a mismatch : print the transactions for debugging
                dut_tx.set_mode("out");
                dut_tx.print();
                ref_tx.print();
            end
        end

        if (ref_tx.host_regso[0] == 32'h1 && ref_tx.host_regso_valid[0] == 1'b1) begin // Compare busy signal
            // Perform the comparison using our do_compare() override
            ref_tx.set_mode("busy");
            result = ref_tx.compare(dut_tx);  // Use do_compare()

            if (result) begin
                `honeyb("GPP COMPARE", "GPP BUSY TX match!")
                gpp_match_count++; // Increment match count
            end else begin
                `uvm_warning("", "GPP BUSY TX mismatch!")
                gpp_mismatch_count++; // Increment mismatch count
                // If there's a mismatch : print the transactions for debugging
                dut_tx.set_mode("busy");
                dut_tx.print();
                ref_tx.print();
            end

        end else if (ref_tx.host_regso[1] == 32'h1 && ref_tx.host_regso_valid[1] == 1'b1) begin // compare done signal
            ref_tx.set_mode("done");
            result = ref_tx.compare(dut_tx);

            if (result) begin
                `honeyb("GPP COMPARE", "GPP DONE TX match!")
                gpp_match_count++; // Increment match count
            end else begin
                `uvm_warning("", "GPP DONE TX mismatch!")
                gpp_mismatch_count++; // Increment mismatch count
                // If there's a mismatch : print the transactions for debugging
                dut_tx.set_mode("done");
                dut_tx.print();
                ref_tx.print();
            end
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
    `honeyb("", $sformatf("MEM Matches: %0d", mem_match_count))
    `honeyb("", $sformatf("MEM Mismatches: %0d", mem_mismatch_count))
    `honeyb("", $sformatf("GPP Matches: %0d", gpp_match_count))
    `honeyb("", $sformatf("GPP Mismatches: %0d", gpp_mismatch_count))

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