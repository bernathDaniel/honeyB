module xbox_xlr_dmy1 #(parameter NUM_MEMS=1,LOG2_LINES_PER_MEM=4)  (

  // XBOX memories interface
   // System Clock and Reset
   input clk,
   input rst_n, // asserted when 0

   // Accelerator XBOX mastered memories interface

   output logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] xlr_mem_addr,  //  address per memory instance
   output logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_wdata, // 32 bytes write data interface per memory instance
   output logic [NUM_MEMS-1:0]      [31:0] xlr_mem_be,    // 32 byte-enable mask per data byte per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_rd,    // read signal per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_wr,    // write signal per instance.
   input        [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_rdata, // 32 bytes read data interface per memory instance

   // Command Status Register Interface
   input  [31:0][31:0] host_regs,                   // regs accelerator write data, reflecting registers content as most recently written by SW over APB
   input        [31:0] host_regs_valid_pulse,       // reg written by host (APB) (one per register)
                                                    
   output logic [31:0][31:0] host_regs_data_out,          // regs accelerator write data,  this is what SW will read when accessing the register
                                                    // provided that the register specific host_regs_valid_out is asserted
   output logic      [31:0] host_regs_valid_out,         // reg accelerator (one per register)

   input [18:0]        trig_soc_xmem_wr_addr,       // optional trigger, XBOX memory address accessed by SOC (processor/apb)
   input               trig_soc_xmem_wr             // optional trigger, validate actual SOC xmem wr access   
) ;


// ILAAD: Inference-Driven Low-latency Autonomous AI Devices

// A system verilog macro to calculate the relative memory address (in hardware terms) of an agreed location with the software
`define SPACE_SIZE_PER_MEM 1024 // Reserved space per memory , regardless of actual available size
`define XBOX_TCM_OFFSET_ADDR(mem_idx,line_idx,word_idx) ((mem_idx*`SPACE_SIZE_PER_MEM*32)+(line_idx*32)+(word_idx*4))

enum {MEM0=0,MEM1=1} mem_idx ; // xbox memories reference indexing

// The accelerator sense the command address access by the software as a trigger to start acting. 
assign trig_detected = trig_soc_xmem_wr && (trig_soc_xmem_wr_addr==`XBOX_TCM_OFFSET_ADDR(1,255,0)) ; // SW Writing to CMD word in TCM

// parameters
parameter N = 16;          // Vector size
parameter WIDTH = 8;     // Bit width of each element in the vector
parameter NUM_MACS = 2;

wire sw_go_alu;

assign sw_go_alu = (host_regs[0][GO_XLR_BIT]) & host_regs_valid_pulse[0];

// =================== test code =========================

typedef enum {IDLE_ST, CALC_ST} state_t;

state_t state, nxt_state;

// host regs
reg [31:0] row_a           ; 
reg [31:0] column_b        ; 
reg [31:0] input_addr_a    ; 
reg [31:0] input_addr_b    ; 
reg [31:0] output_addr_res ;

// control signals
reg start_dp;
reg valid_in;
wire dp_valid_out;
wire finish_calc;
wire col_counter_ovfl;

// memory accesses
reg nxt_rd;
reg nxt_be;

// counters
reg [31:0] row_counter;
reg [31:0] col_counter;
wire [31:0] nxt_col_counter;
wire [31:0] nxt_row_counter;
wire [31:0] row_inc;

// masking
wire [31:0] mask_bits;

// mac data
logic signed [8-1:0] xlr_mem_rdata_upckd [NUM_MEMS-1:0][0:32-1];
logic signed [32-1:0] xlr_mem_wr_vrf [0:32-1];
logic signed [32-1:0] xlr_mem_rd_vrf [0:32-1];
wire [7:0] en_valu;
wire [31:0] en_reg;

reg sel_valu;
wire sync_rst_valu;

// phantom
assign dp_valid_out = 1'b1;
/*
TODO README: each row is aligned to 32 bytes
*/

assign row_inc = (column_b > 32'd16) ? 32'd1 : 
    (column_b > 32'd8) ? 32'd2 :
    (column_b > 32'd4) ? 32'd4 :
    32'd8;
    
assign col_counter_ovfl = ((col_counter + 32'd32) >= column_b) && (column_b != 32'd0);
assign row_counter_ovfl = ((row_counter + row_inc)  >= row_a) && (row_a != 32'd0);

assign nxt_col_counter = (dp_valid_out == 1'b1) ? 
    (~col_counter_ovfl) ? col_counter + 32'd32 : 32'd0  
    : col_counter;

assign nxt_row_counter = (col_counter_ovfl) ? 
    (~row_counter_ovfl) ? row_counter + row_inc : 32'd0
    : row_counter;

assign finish_calc = row_counter_ovfl & col_counter_ovfl;

assign mask_bits = (col_counter_ovfl) ? column_b - col_counter : 32'd32;

assign xlr_mem_addr[MEM0] = (sw_go_alu) ? host_regs[4] : input_addr_a + 32'd1; // TODO in vec mac operation increase only the matrix (MAT1/MEM1)
assign xlr_mem_addr[MEM1] = (sw_go_alu) ? host_regs[5] : input_addr_b + 32'd1; 

assign xlr_mem_rd[MEM0] = (sw_go_alu) ? 1'b1 : nxt_rd ;
assign xlr_mem_rd[MEM1] = (sw_go_alu) ? 1'b1 : nxt_rd ;

assign xlr_mem_be[MEM0] = (sw_go_alu) ? 32'hffff_ffff : nxt_be;
assign xlr_mem_be[MEM1] = (sw_go_alu) ? 32'hffff_ffff : nxt_be;

assign en_valu = (~sel_valu) ? 8'h00 : (mask_bits > 32'd28) ? 8'hff:
    (mask_bits > 32'd24) ? 8'b0111_1111 :
    (mask_bits > 32'd20) ? 8'b0011_1111 :
    (mask_bits > 32'd16) ? 8'b0001_1111 :
    (mask_bits > 32'd12) ? 8'b0000_1111 :
    (mask_bits > 32'd8) ? 8'b0000_0111 :
    (mask_bits > 32'd4) ? 8'b0000_0011 :
    (mask_bits != 32'd0) ? 8'b0000_0001 :
    0;
assign sync_rst_valu = sw_go_alu;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        row_a            <=  32'd0;
        column_b         <=  32'd0;
        input_addr_a     <=  32'd0;
        input_addr_b     <=  32'd0;
        output_addr_res  <=  32'd0;
        state            <= IDLE_ST;
        col_counter      <=  32'd0;
        row_counter      <=  32'd0;
        start_dp         <=  1'd0;
        host_regs_data_out[0]  <= 32'd0;
        host_regs_valid_out[0] <= 1'b0;
        nxt_rd <= 1'b0;
        nxt_be <= 1'b0;
        sel_valu <= 1'b0;
    end else begin
        case (state)
            IDLE_ST: begin
                col_counter      <=  32'd0;
                row_counter      <=  32'd0;
                nxt_rd <= 1'b0;
                nxt_be <= 1'b0;
                sel_valu <= 1'b0;
                if (sw_go_alu) begin
                    row_a            <= host_regs[2];
                    column_b         <= host_regs[3];
                    input_addr_a     <= host_regs[4];
                    input_addr_b     <= host_regs[5];
                    output_addr_res  <= host_regs[6];                    
                    state            <= CALC_ST;
                    start_dp         <= 1'b1;
                    host_regs_data_out[0]  <= 32'd0;
                    host_regs_valid_out[0] <= 1'b0;
                    nxt_rd <= 1'b1;
                    nxt_be <= 1'b1;
                    sel_valu <= 1'b1;
                end
            end
            CALC_ST: begin
                input_addr_a <= xlr_mem_addr[MEM0];
                input_addr_b <= xlr_mem_addr[MEM1];
                start_dp     <= 1'b0;
                col_counter  <= nxt_col_counter;
                row_counter  <= nxt_row_counter;
                nxt_rd <= 1'b1;
                nxt_be <= 1'b1;        
                sel_valu <= 1'b1;

                if (finish_calc) begin
                    state <= IDLE_ST;
                    host_regs_data_out[0][GO_XLR_BIT]  <= 1'b1;
                    host_regs_valid_out[0]             <= 1'b1;
                    row_a                              <= 32'd0;
                    column_b                           <= 32'd0;
                    nxt_rd <= 1'b0;
                    nxt_be <= 1'b0;
                    sel_valu <= 1'b0;
                end
            end
            default: begin
                
            end
        endcase
    end
end

always_comb begin
    for (int i=0; i<8; i++) begin
        for (int j=0; j<4; j++) begin
            xlr_mem_rdata_upckd[MEM0][i*4+j] = (i*4+j < mask_bits) ? xlr_mem_rdata[MEM0][i][8*j +:8] : 8'd0;
            xlr_mem_rdata_upckd[MEM1][i*4+j] = (i*4+j < mask_bits) ? xlr_mem_rdata[MEM1][i][8*j +:8] : 8'd0;
        end
    end
end

genvar dp_num;      

generate
    for (dp_num = 0; dp_num < 8; dp_num++) begin
        wire signed [31:0] dp_result;  // Intermediate wire
        _4x4DotProduct dprod[dp_num] (
            .clk(clk),
            .rst_n(rst_n),
            // .sync_rst(sync_rst_valu),
            .d_in1(xlr_mem_rdata_upckd[MEM0][dp_num*4:(dp_num+1)*4-1]),
            .d_in2(xlr_mem_rdata_upckd[MEM1][dp_num*4:(dp_num+1)*4-1]),
            .r_in(xlr_mem_rd_vrf[dp_num]),
            .d_out(dp_result)    
        );
        assign xlr_mem_wr_vrf[dp_num] = dp_result;
    end

endgenerate

// TODO add gather add register unit
// TODO add add scalar unit
// TODO add hadamard product unit
genvar reg_file_size;

generate
    for (reg_file_size=0 ; reg_file_size<32; reg_file_size++) begin
        
        assign en_reg[reg_file_size] = (reg_file_size < 5'd8) ? en_valu[reg_file_size] : 1'd0; 
    
        wire signed [31:0] dp_write;  // Intermediate wire
    
        _vecRegFile vreg_file[reg_file_size] (
            .clk(clk),
            .rst_n(rst_n), // asserted when 0
            .sync_rst(sync_rst_valu), // asserted when 0
            .addr(1'b0), /*Currently always zero*/
            .wr(en_reg[reg_file_size]),
            .d_in(xlr_mem_wr_vrf[reg_file_size]),
            .d_out(dp_write)    
        );
        assign xlr_mem_rd_vrf[reg_file_size] = dp_write; 
    end
endgenerate
endmodule
