//=============================================================================
// Project  : HoneyB V1
// File Name: honeyb_pkg.sv
//=============================================================================
// Description: honeyB Utilities package
//
// Features: 1) Smart printing system for debugging messages
//               This custom printing system reduces the amount of information
//               to exactly what's needed with a neat look for easier review
//               of the log within the terminal
//          
// Syntax: `honeyb("<component_name>", "<component_status>", "<data>")
//=============================================================================

`ifndef HONEYB_PKG_SV
`define HONEYB_PKG_SV

package honeyb_pkg;

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