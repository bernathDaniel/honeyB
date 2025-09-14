//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_model.sv
//=============================================================================
// Description: Memory Model for xlr_mem
//=============================================================================

`ifndef XLR_MEM_MODEL_SV
`define XLR_MEM_MODEL_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;

class mem_line_randomizer;
  rand logic signed [NUM_WORDS-1:0][WORD_WIDTH-1:0] data;

  constraint valid_range { // Constrain each word to a range
    foreach (data[i]) { data[i] inside {[-20:20]};}
  }
endclass // Utility class for randomization

class xlr_mem_model extends uvm_component;

  `uvm_component_utils(xlr_mem_model)

  uvm_blocking_transport_imp#(
    xlr_mem_tx, // req : Contains info of the driver's request : mem_rd / mem_wr / mem_add / mem_be / mem_idx
    xlr_mem_tx, // rsp : Contains info of the mem model's response : mem_rdata / mem_wdata (and more if needed)
    xlr_mem_model
  ) bt_imp;

  // --- Paramems ---
  //==================
  localparam int BE_WIDTH       = 32;
  localparam int BYTES_PER_WORD = WORD_WIDTH/8; // = 4
  localparam int LINES_PER_MEM  = 1 << LOG2_LINES_PER_MEM;

  // --- Config Handle ---
  //=======================
  xlr_mem_config   m_config;

  // --- Memory Definitions ---
  //=====================================================================================
  typedef logic signed [NUM_WORDS-1:0][WORD_WIDTH-1:0] mem_line;  // 8x32 (from honeyb_pkg)

  mem_line  mem           [NUM_MEMS][int];  // mem[mem_id][addr]
  mem_line  last_mem_rdata[NUM_MEMS];       // per-mem last value
  bit       has_last      [NUM_MEMS];       // per-mem flag for LAST policy
  //=====================================================================================

  extern function       new           (string    name, uvm_component parent       );
  extern function void  build_phase   (uvm_phase phase                            );
  extern virtual  task  transport     (input xlr_mem_tx req, output xlr_mem_tx rsp);

  // Transport Methods
  //===================

  extern function void     do_write(int mem_idx, int addr, mem_line wdata, logic [BE_WIDTH-1:0] be);
  extern function mem_line do_read (int mem_idx, int addr, output bit was_uninit);
  extern function mem_line be_merge(mem_line old_line, mem_line wdata, logic [BE_WIDTH-1:0] be);


  extern function void init_all();
  extern function void init_mem_random(int mem_idx);
  extern function void init_mem_file  (int mem_idx, string path);


  // Policy Handlers
  //=================
  extern function mem_init_policy         get_init_policy    (int mem_idx);
  extern function mem_uninit_read_policy  get_uninit_policy  (int mem_idx);

  // Debugging Helpers: Memory Dump
  //================================
  extern function void dump_mem     (int mem_idx, string filename = "");
  extern function void dump_all_mems(string base_filename = "mem_dump");
endclass


function xlr_mem_model::new(string name, uvm_component parent); // Memory Constructor
  super.new(name, parent);
endfunction : new

function void xlr_mem_model::build_phase (uvm_phase phase);
  super.build_phase(phase);
  bt_imp = new("bt_imp", this);

  if (!uvm_config_db#(xlr_mem_config)::get(this, "", "config", m_config)) begin
    `uvm_error("", "xlr_mem_config not found")
  end

  init_all(); // Memory Initializer
endfunction

task xlr_mem_model::transport(input xlr_mem_tx req, output xlr_mem_tx rsp);
  if (req == null) begin
    `honeyb("[ERROR] MEM Model", "EMPTY REQ !")
    rsp = null;
    return;
  end

  rsp = xlr_mem_tx::type_id::create("rsp");
  rsp.copy(req);


  for (int m = 0; m < NUM_MEMS; m++) begin
    if (req.mem_rd[m] && req.mem_wr[m]) begin
      `honeyb("[FATAL] MEM Model","ILLEGAL RD&WR", $sformatf("mem=%0d addr=0x%0h (single-port)", m, req.mem_addr[m]))
      `uvm_fatal("RDWR_SAME_CALL","Single-port mem cannot read and write in the same call")
    end
  end // SP-SRAM: forbid simultaneous rd & wr on the same mem in one call

  //=============================================================================================
  for (int m = 0; m < NUM_MEMS; m++) begin
    if (req.mem_wr[m])
    begin
                                  do_write(m, req.mem_addr[m], req.mem_wdata[m], req.mem_be[m]);
    end
  end
  //=============================================================================================
  for (int m = 0; m < NUM_MEMS; m++) begin
    if (req.mem_rd[m]) begin
      bit was_uninit;

      mem_line               R = do_read(m, req.mem_addr[m], was_uninit);

      rsp.mem_rdata[m]  = R;
      last_mem_rdata[m] = R;
      has_last[m]       = 1'b1;
    end
  end
  //=============================================================================================
  if (m_config.enable_write_dumps) begin
    for (int m = 0; m < NUM_MEMS; m++) begin
      if (req.mem_wr[m]) begin
        dump_mem(m, $sformatf("mem%0d_after_write_%0t.txt", m, $time));
      end
    end
  end
  //=============================================================================================
endtask


function void xlr_mem_model::do_write(int mem_idx, int addr, mem_line wdata, logic [BE_WIDTH-1:0] be);

  mem_line old_line = mem[mem_idx].exists(addr) ? mem[mem_idx][addr] : '0;

  mem[mem_idx][addr] = be_merge(old_line, wdata, be);
endfunction // WRITE


function mem_line xlr_mem_model::be_merge(mem_line old_line, mem_line wdata, logic [BE_WIDTH-1:0] be);
  mem_line new_line = old_line;
  for (int w = 0; w < NUM_WORDS; w++)
    for (int b = 0; b < BYTES_PER_WORD; b++)
    begin
          int be_idx = w*BYTES_PER_WORD + b;
          if (be[be_idx]) new_line[w][b*8 +: 8] = wdata[w][b*8 +: 8];
    end
  return new_line;
endfunction // BIT ENABLE MERGE


function mem_line xlr_mem_model::do_read (int mem_idx, int addr, output bit was_uninit);
  was_uninit = !mem[mem_idx].exists(addr);
  if (!was_uninit) return mem[mem_idx][addr];

  mem_line R;
  mem_uninit_read_policy pol = get_uninit_policy(mem_idx);
  if (pol == UNINIT_LAST && has_last[mem_idx]) R = last_mem_rdata[mem_idx]; // Default
  else                                         R = '0;

  if (m_config.uninit_is_error)
    `honeyb("[ERROR]   MEM Model","UNINIT READ -> ERROR", $sformatf("mem=%0d addr=0x%0h", mem_idx, addr))
  else
    `honeyb("[WARNING] MEM Model","UNINIT READ -> WARN ",  $sformatf("mem=%0d addr=0x%0h", mem_idx, addr))

  return R;
endfunction

//======================================
//            Memory INIT
//======================================


function void xlr_mem_model::init_all();
  for (int m = 0; m < NUM_MEMS; m++) begin
    has_last[m]       = 1'b0;
    last_mem_rdata[m] = '0;
  end // reset trackers

  for (int m = 0; m < NUM_MEMS; m++) begin
    case (get_init_policy(m))
      INIT_RANDOM: init_mem_random(m);

      INIT_FILE: begin
        if (m_config.init_file_per_mem.exists(m)) init_mem_file(m, m_config.init_file_per_mem[m]);
        else
          `honeyb("[ERROR] MEM Model", "INIT_FILE MISSING", $sformatf("mem=%0d no file path; leaving uninitialized", m))
      end
      default: /* INIT_NONE */ ; // leave uninitialized on purpose
    endcase
  end
endfunction // per-mem policy

function void xlr_mem_model::init_mem_random(int mem_idx);
  mem_line_randomizer randomized = new();
  
  if (m_config.rand_seed != 0) begin
    randomized.srandom(m_config.rand_seed + mem_idx); // Different seed per memory
  end // Reproducible randomization (Debug)

  for (int l = 0; l < LINES_PER_MEM; l++) begin
    if (!randomized.randomize()) begin
      `honeyb("[ERROR] MEM Model", "RANDOMIZE_FAIL!", $sformatf("mem=%0d addr=%0d", mem_idx, l))
    end
    mem[mem_idx][l] = randomized.data;
  end
  `honeyb("MEM Model","INIT_RANDOM Completed ->", $sformatf("mem=%0d, %0d lines", mem_idx, LINES_PER_MEM))
endfunction


function void xlr_mem_model::init_mem_file(int mem_idx, string path);
  int fd = $fopen(path, "r");
  if (fd == 0) begin
    `honeyb("MEM Model","INIT_FILE OPEN_FAIL", $sformatf("mem=%0d file='%s'", mem_idx, path))
    return;
  end

  int addr; mem_line line; int cnt = 0;
  
  while (!$feof(fd)) begin
    if ($fscanf(fd, "%h %h\n", addr, line) == 2) begin
      if (addr < LINES_PER_MEM) begin
        mem[mem_idx][addr] = line;
        cnt++;
      end
    end
  end // expected format per line: "<addr_hex> <line_hex_256bits>"

  $fclose(fd);
  `honeyb("MEM Model","INIT_FILE Completed ->", $sformatf("mem=%0d file='%s' loaded %0d lines", mem_idx, path, cnt))
endfunction



//======================================
//          Policy Handlers
//======================================

function mem_init_policy xlr_mem_model::get_init_policy (int mem_idx);//                      : DEFAULT| Global policy
  return m_config.init_policy_per_mem.exists(mem_idx) ? m_config.init_policy_per_mem[mem_idx] : m_config.init_policy;
endfunction

function mem_uninit_read_policy xlr_mem_model::get_uninit_policy (int mem_idx);//               : DEFAULT| Global policy
  return m_config.uninit_policy_by_mem.exists(mem_idx) ? m_config.uninit_policy_by_mem[mem_idx] : m_config.uninit_policy;
endfunction


//======================================
//          Memory Dump Functions
//======================================

function void xlr_mem_model::dump_mem(int mem_idx, string filename = "");
  string dump_file;
  int fd;
  int addr_count = 0;
  
  // Generate filename if not provided
  if (filename == "") begin
    dump_file = $sformatf("%smem_%0d_dump_%0t.txt", m_config.dump_directory, mem_idx, $time);
  end else begin
    dump_file = $sformatf("%s%s", m_config.dump_directory, filename);
  end
  
  // Validate memory index
  if (mem_idx >= NUM_MEMS) begin
    `honeyb("[ERROR] MEM Model", $sformatf("(DUMP) Invalid memory index %0d (max: %0d)", mem_idx, NUM_MEMS-1))
    return;
  end
  
  fd = $fopen(dump_file, "w");
  if (fd == 0) begin
    `honeyb("[ERROR] MEM Model", $sformatf("(DUMP) Cannot open file '%s' for writing", dump_file))
    return;
  end
  
  // Write header information
  $fwrite(fd, "# Memory Dump for mem[%0d] at time %0t\n", mem_idx, $time);
  $fwrite(fd, "# Format: <addr_hex> <data_256bits_hex>\n");
  $fwrite(fd, "# Memory Config: %0d mems, %0d lines per mem, %0d bits per line\n", 
          NUM_MEMS, LINES_PER_MEM, NUM_WORDS * WORD_WIDTH);
  $fwrite(fd, "#\n");
  
  // Dump all initialized addresses (associative array keys)
  if (mem[mem_idx].size() == 0) begin
    $fwrite(fd, "# Memory is empty (no initialized addresses)\n");
  end else begin
    // Get all addresses and sort them for readability
    int addr_list[$];
    foreach (mem[mem_idx][addr]) begin
      addr_list.push_back(addr);
    end
    addr_list.sort();
    
    // Write each address and its data
    foreach (addr_list[i]) begin
      int addr = addr_list[i];
      $fwrite(fd, "%08h %064h\n", addr, mem[mem_idx][addr]);
      addr_count++;
    end
  end
  
  $fclose(fd);
  `honeyb("MEM Model", "DUMP_Complete", $sformatf("mem=%0d file='%s' dumped %0d addresses", mem_idx, dump_file, addr_count))
endfunction

function void xlr_mem_model::dump_all_mems(string base_filename = "mem_dump");
  for (int m = 0; m < NUM_MEMS; m++) begin
    string filename = $sformatf("%s_mem%0d_%0t.txt", base_filename, m, $time);
    dump_mem(m, filename);
  end
  `honeyb("MEM Model", "DUMP_ALL_COMPLETE", $sformatf("Dumped all %0d memories with base name '%s'", NUM_MEMS, base_filename))
endfunction


//===================
// Extras
//===================
  /*

  function void xlr_mem_model::init_mem_random(int mem_idx);
    for (int i = 0; i < LINES_PER_MEM; i++) begin
      rand mem_line line;
      void'(std::randomize(line));      // reproducible if rand_seed set earlier
      mem[mem_idx][i] = line;
    end
    `honeyb("MEM Model","INIT_RANDOM Completed ->", $sformatf("mem=%0d, %0d lines", mem_idx, LINES_PER_MEM))
  endfunction

  */

`endif // XLR_MEM_MODEL_SV