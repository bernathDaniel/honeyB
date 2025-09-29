//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_mem_sequencer.sv
//=============================================================================
// Description: Sequencer for xlr_mem
//=============================================================================

`ifndef XLR_MEM_SEQUENCER_SV
`define XLR_MEM_SEQUENCER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


// Sequencer class is specialization of uvm_sequencer
typedef uvm_sequencer #(xlr_mem_tx) xlr_mem_sequencer_t;

`endif // XLR_MEM_SEQUENCER_SV

//***************************************************************************************************************************//
//                                          SEQUENCER EXPLANATION + IMPROVEMENT SUGGESTIONS                                  //
//                                 ------------------------------------------------------------------                        //
// How does this simple code work? basically we just used the most basic uvm_sequencer.                                      //
// This means that we're working with a simple FIFO-like structure where :                                                   //
// xlr_mem_seq_lib is communicating with the sequencer through "start_item(req)"                                             //
// then the sequence will provide all the transactions in FIFO order to the sequencer                                        //
// at this point the sequencer holds a bunch of transactions that the driver can request one by one                          //
// therefore the current control of how the transactions flow to the driver are controlled by the driver.                    //
// later on if needed, we can create a more complex sequencer where we add more complex control functionalities              //
// this will be done if we have a certain order of the transactions that we need etc.                                        //
// but in this simple case, we receive only a "start" command with some random data and order is of no importance.           //
// if later on the order of the command's are crucial, we can define an extended version of the sequencer                    //
// where we can define the correct order of instructions that the DUT must have in order to properly work.                   //
//                                                                                                                           //
//***************************************************************************************************************************//