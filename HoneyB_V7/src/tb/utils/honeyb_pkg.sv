//=============================================================================
// Project  : HoneyB V7
// File Name: honeyb_pkg.sv
//=============================================================================
// Description: honeyB Utilities package
  //
  // Features: 1) Smart printing system for debugging messages
  //               This custom printing system reduces the amount of information
  //               to exactly what's needed with a neat look for easier review
  //               of the log within the terminal
  //          
  // Syntax   : `honeyb("<component_name>", "<component_status>", "<data>")
  //
  // Important: Package needs to be imported for non-macro items !
  // Example  : `honeyb is defined with "`define" macro - no need to import
  // Example2 : Parameters within package require import
  //
//=============================================================================

`ifndef HONEYB_PKG_SV
`define HONEYB_PKG_SV
`timescale 1ns/1ps

package honeyb_pkg;

	//=====================================================
	// Delay Controls
	//=====================================================
    parameter real RST_CTRL 		= 1.01;
    parameter real RACE_CTRL		= 0.01;
    parameter real DELTA_T_CTRL = 0.001;
	
	//=====================================================
	// HoneyB Debbuger Control
	//=====================================================

    // Debug Modes:
    //---------------
    typedef enum {
      DBG_OFF,			// = OFF Mode
      DBG_ALL,			// = ALL Mode
                    //-------------
      DBG_MEM_MDL,	// = MEM Model									
      DBG_MEM_DRV,	// = MEM Driver
      DBG_MEM_MON,	// = MEM Monitor
                    //--------------
      DBG_GPP_DRV,	// = GPP Driver
      DBG_GPP_MON,	// = GPP Monitor
                    //--------------
      DBG_REF_MDL,	// = REF Model
      DBG_SCR_BRD		// = Scoreboard
    } debug_modes;	//--------------

    localparam DEBUG_MODE = DBG_OFF; // Choose Desired Mode

    // Debug Create Format
    //------------------------
      /*COPY:
              // HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
              if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == ??)) begin
                #PRNT_CTRL;
                `honeyb("| DEBUG       | ", "<Event MSG>")
                `honeyb("| DEBUG PRINT | ", $sformatf("\n\n ?? = %h\n", ??))
              end
      */

    // Simulation Checkpoint
    //--------------------------
      // `uvm_fatal("CHECKPOINT", "Intentional termination at checkpoint X")

	//=====================================================
  // Memory Policies
  //=====================================================

    // Initialization Policies:
    //-----------------------------
      typedef enum {
        INIT_RANDOM, // = DEFAULT
        INIT_FILE,   // *PER-MEM ONLY**
        INIT_NONE    // WRITE FIRST - READ AFTER MODE
      } mem_init_policy;

    // Read Policies -
    // Handles uninitialized addrs:
    //-----------------------------
    typedef enum {
      UNINIT_ZERO, // (OVERRIDE) INIT_NONE     - Returns 0's  
      UNINIT_LAST  // (DEFAULT ) RANDOM / FILE - Returns the last read value
    } mem_uninit_read_policy;

	//=====================================================
	// Parameters & Enumerations
	//=====================================================

    localparam bit [31:0] MATA_BASE_ADDR  = 32'h0000_1000; 	// localparams to avoid them being changed.
    localparam bit [31:0] MATBT_BASE_ADDR = 32'h0000_8000; 	// FIXED VALUES!!
    localparam bit [31:0] OUT_BASE_ADDR   = 32'h0001_0000;

    parameter NUM_MEMS              =   2 ;
    parameter LOG2_LINES_PER_MEM    =   8 ;
    parameter NOF_ITERATIONS        =   10;
    parameter NUM_WORDS             =   8 ;
    parameter WORD_WIDTH            =   32;
    parameter GO_XLR_BIT            =   0 ; // not all of these parameters are used

    typedef enum logic [$clog2(NUM_MEMS+1)-1:0] {
      MEM0, // 1st            MEM
      MEM1, // 2nd            MEM
      MEMA  // Default(ALL)   MEM
    } x_mem;

    typedef enum logic [1:0] {
      START_IDX_REG,   // 0 | Index of the register indicating GO_HONEY
      BUSY_IDX_REG,    // 1 | Index of the register indicating BUSY
      DONE_IDX_REG     // 2 | Index of the register indicating DONE
    } idx_regs;

    typedef enum logic [1:0] {
      MATMUL,
      CALCOPY
    } func_mode; // DUT / REF Functionality Modes

  //=====================================================
  // Special Coverage Parameters
  //=====================================================
    
    // [GPP] Coverage
    localparam logic [31:0] START_MATMUL  = 32'h1;
    localparam logic [31:0] START_CALCOPY = 32'h2;

    // [MEM] Coverage
    localparam logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] MEM_0_ADDR_0 = '0; // mem_addr[0] = 8'h01                                

    localparam logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] MEM_0_ADDR_1 = 8'h01; // mem_addr[0] = 8'h01                                

    localparam logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] MEM_0_1_ADDR_1 = 16'h0101; // mem_addr[0] = mem_addr[1] = 8'h01                                
                                          
    localparam logic [NUM_MEMS-1:0][7:0 ][31:0] MEM_RDATA_0 = '0; // Unused                            

    localparam logic [NUM_MEMS-1:0] MEM_RD_0       = 1'b1;
    
    localparam logic [NUM_MEMS-1:0] MEM_WR_0       = 1'b1;
    localparam logic [NUM_MEMS-1:0] MEM_WR_0_1     = 2'b11;
    
    localparam logic [NUM_MEMS-1:0][31:0] MEM_BE_ALL_0   = 32'hFFFF_FFFF;
    localparam logic [NUM_MEMS-1:0][31:0] MEM_BE_ALL_0_1 = 64'hFFFF_FFFF_FFFF_FFFF;

    localparam logic [NUM_MEMS-1:0][7:0 ][31:0] MEM_WDATA_0   = '0; // Unused
    localparam logic [NUM_MEMS-1:0][7:0 ][31:0] MEM_WDATA_0_1 = '0; // Unused


	//=====================================================
	// HoneyB Messages
	//=====================================================

    // Tab Control for Printing System:
    //----------------------------------
      localparam string PD  = {3{" "}}; // 3 Space Padding
      localparam string PD5 = {5{" "}}; // 5 -" "- 

    class honeyb_cls;
      extern static function string honeyb_filename_extract(string file);
      extern static function void honeyb_printer(string component = "", string status = "", string msg = "", string file, int line);
    endclass : honeyb_cls

    function void honeyb_cls::honeyb_printer(string component = "", string status = "", string msg = "", string file, int line);
      file = honeyb_filename_extract(file);
      $display("HoneyB Message | %s(%0d) @[%0t] {%s} %s%s",file, line, $time, component, status, msg);
    endfunction : honeyb_printer

    function string honeyb_cls::honeyb_filename_extract(string file);
      string filename;

      // If no '/' was found, the entire string is the filename
      if (filename == "") filename = file;

      // Find the last '/' or '\' in the file path
      for (int i = file.len(); i > 0; i--) begin
        if (file[i-1] == "/" || file[i-1] == "\\") begin
          filename = file.substr(i, file.len()-1);
          break;
        end
      end

      for (int i = filename.len(); i > 0; i--) begin
        if (filename[i-1] == ".") begin
          filename = filename.substr(0, i-2);
          break;
        end
      end
      return filename;
    endfunction : honeyb_filename_extract
endpackage

`define honeyb(component = "", status = "", msg = "") honeyb_pkg::honeyb_cls::honeyb_printer(component, status, msg, `__FILE__, `__LINE__);
`endif // HONEYB_PKG_SV

//=================
//     EXTRAS
//=================
  /*
    // SW-HW Register allocation indices
    // =================================
    typedef enum logic [1:0] {
      MAT_A_BASE_ADDR_REG_IDX     ,     // 0 |Index of the register holding the base address
      MAT_BT_BASE_ADDR_REG_IDX    ,     // 1 |Index of the register holding the base address
      OUT_MAT_BASE_ADDR_REG_IDX   ,     // 2 |Index of the register holding the base address
      MAT_A_HEIGHT_H_REG_IDX      ,     // 3 |Index of the register holding the matrix height  - **HORIZONTAL**
      MAT_B_WIDTH_H_REG_IDX       ,     // 4 |Index of the register holding the matrix width   - **HORIZONTAL**
      GO_REG_IDX                  ,     // 5 |Index of the register indicating GO
      BUSY_REG_IDX                ,     // 6 |Index of the register indicating BUSY
      DONE_REG_IDX                ,     // 7 |Index of the register indicating DONE
    } regs_idx;

    // Conversion Mode for later
    //==========================
    typedef enum {
      NO_CONVERT,  // Return unsigned as-is
      TO_SIGD,     // Convert unsigned to signed
      TO_USIGD		 // Convert signed to unsigned
    } convert_mode_t;

    // Debug Verbosity:
    //------------------
    typedef enum { // Currently Unused
      DBG_OFF,
      DBG_ERROR,    // Only critical issues
      DBG_BASIC,    // Key operations  
      DBG_VERBOSE,  // Detailed tracing
      DBG_ALL       // Everything including timing
    } debug_level_e;

    localparam debug_level_e MEM_AGT_LVL = DBG_BASIC;
    localparam debug_level_e MEM_MDL_LVL = DBG_BASIC;
    localparam debug_level_e MEM_DRV_LVL = DBG_BASIC;
    localparam debug_level_e MEM_MON_LVL = DBG_BASIC;
    localparam debug_level_e GPP_DRV_LVL = DBG_BASIC;
    localparam debug_level_e GPP_MON_LVL = DBG_BASIC;
      
    // Debugging Enhancer
    //==========================
    extern static function void honeyb_debugger(debug_modes component, string msg = "");

    function void honeyb_cls::honeyb_debugger(debug_modes component, string msg = "");
      if (DEBUG_MODE == DBG_ALL || DEBUG_MODE == component) begin
          honeyb_printer($sformatf("%s", component.name()), " || DEBUG || ", msg, `__FILE__, `__LINE__);
      end
    endfunction : honeyb_debugger

    `define honeydbg(component, msg = "") honeyb_pkg::honeyb_cls::honeyb_debugger(component, msg);
  */