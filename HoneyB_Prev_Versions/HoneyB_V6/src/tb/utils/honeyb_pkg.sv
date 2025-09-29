//=============================================================================
// Project  : HoneyB V4
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

package honeyb_pkg;

	// Parameters to be used for the test bench
	// not all of these parameters are used
	// ========================================
	localparam bit [31:0] MATA_BASE_ADDR  = 32'h0000_1000; 	// localparams to avoid them being changed.
	localparam bit [31:0] MATBT_BASE_ADDR = 32'h0000_8000; 	// FIXED VALUES!!
	localparam bit [31:0] OUT_BASE_ADDR   = 32'h0001_0000;

	localparam string PD            =  {3{" "}}; // 3 Space Padding, used for TX Printing System

	parameter NUM_MEMS              =   2 ;
	parameter LOG2_LINES_PER_MEM    =   8 ;
	parameter NOF_ITERATIONS        =   10;
	parameter NUM_WORDS             =   8 ;
	parameter DATA_WIDTH            =   32;
	parameter ADDR_WIDTH            =   8 ;
	parameter GO_XLR_BIT            =   0 ;

	// Enumerations
	// ============
	typedef enum logic [$clog2(NUM_MEMS+1)-1:0] {
		MEM0, // 1st            MEM
		MEM1, // 2nd            MEM
		MEMA  // Default(ALL)   MEM
	} x_mem;

	// SW-HW Register allocation indices
	// =================================
	/*typedef enum logic [1:0] {
		MAT_A_BASE_ADDR_REG_IDX     ,     // 0 |Index of the register holding the base address
		MAT_BT_BASE_ADDR_REG_IDX    ,     // 1 |Index of the register holding the base address
		OUT_MAT_BASE_ADDR_REG_IDX   ,     // 2 |Index of the register holding the base address
		MAT_A_HEIGHT_H_REG_IDX      ,     // 3 |Index of the register holding the matrix height  - **HORIZONTAL**
		MAT_B_WIDTH_H_REG_IDX       ,     // 4 |Index of the register holding the matrix width   - **HORIZONTAL**
		GO_REG_IDX                  ,     // 5 |Index of the register indicating GO
		BUSY_REG_IDX                ,     // 6 |Index of the register indicating BUSY
		DONE_REG_IDX                ,     // 7 |Index of the register indicating DONE
	} regs_idx;*/

	typedef enum logic [1:0] {
		START_IDX_REG,// 0 |Index of the register indicating GO_HONEY
		BUSY_IDX_REG, // 1 |Index of the register indicating BUSY
		DONE_IDX_REG // 2 |Index of the register indicating DONE
	} idx_regs;

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