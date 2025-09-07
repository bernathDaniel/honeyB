//=============================================================================
// Project  : HoneyB V3
// File Name: honeyb_pkg.sv
//=============================================================================
/* Description: honeyB Utilities package

    Features: 1) Smart printing system for debugging messages
                 This custom printing system reduces the amount of information
                 to exactly what's needed with a neat look for easier review
                 of the log within the terminal
        
    Syntax: `honeyb("<component_name>", "<component_status>", "<data>")

    Important: Package needs to be important for non-macro items !
    Example: `honeyb is defined with "`define" macro - no need to import
    Example2: parameters within package require import
    */
//=============================================================================

`ifndef HONEYB_PKG_SV
`define HONEYB_PKG_SV

package honeyb_pkg;

    /* Parameters to be used for the test bench
        not all of these parameters are used*/
    parameter NUM_MEMS = 2;
    parameter LOG2_LINES_PER_MEM = 8;
    parameter NUM_WORDS = 8;
    parameter DATA_WIDTH = 32;
    parameter NUM_BYTES = 32;
    parameter BYTE_WIDTH = 8;
    parameter MEM_SIZE = (1 << LOG2_LINES_PER_MEM) * NUM_WORDS * DATA_WIDTH / 8; // In bytes: 256*8*32/8 = 256*32 = 8192 BYTE
    parameter MEM_SIZE_B = (1 << LOG2_LINES_PER_MEM) * NUM_BYTES * BYTE_WIDTH / 8; // In bytes: 256*32*8/8 = 256*32 = 8192 BYTE
    parameter NOF_ITERATIONS = 10;
    parameter ADDR_WIDTH = 8;
    parameter GO_XLR_BIT = 0;

    typedef enum logic [NUM_MEMS-1:0] {
        MEM0, // 1st MEM
        MEM1, // 2nd MEM
        MEMA // Default mode for ALL
    } x_mem;

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