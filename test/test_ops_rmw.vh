//
// Read-Modify-Write Operations
//

// Zero Page Addressing

task test_rmw_DEC_zpg;
  localparam T = 8'h76;
  begin
    meminit;
    mem.ram[0] <= 8'hc6; // DEC
    mem.ram[1] <= 8'h55; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0055] <= 8'h77; // source
    reset_and_run;
    $display("DEC(zpg) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h0055] == T) ? "Success" : "Fail",
             mem.ram[16'h0055], T);
  end
endtask

// Zero Page, X Addressing

task test_rmw_DEC_zpx;
  localparam T = 8'h76;
  begin
    meminit;
    mem.ram[0] <= 8'hd6; // DEC
    mem.ram[1] <= 8'h33; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0055] <= 8'h77; // source
    reset_and_run;
    $display("DEC(zpx) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h0055] == T) ? "Success" : "Fail",
             mem.ram[16'h0055], T);
  end
endtask

// Absolute Addressing

task test_rmw_DEC_abs;
  localparam T = 8'h76;
  begin
    meminit;
    mem.ram[0] <= 8'hce; // DEC
    mem.ram[1] <= 8'h55; // operand
    mem.ram[2] <= 8'h22; // operand
    mem.ram[3] <= 8'hea; // NOP
    mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("DEC(abs) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h2255] == T) ? "Success" : "Fail",
             mem.ram[16'h2255], T);
  end
endtask

// Absolute, X Addressing

task test_rmw_DEC_abx;
  localparam T = 8'h76;
  begin
    meminit;
    mem.ram[0] <= 8'hde; // DEC
    mem.ram[1] <= 8'h33; // operand
    mem.ram[2] <= 8'h22; // operand
    mem.ram[3] <= 8'hea; // NOP
    mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("DEC(abx) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h2255] == T) ? "Success" : "Fail",
             mem.ram[16'h2255], T);
  end
endtask

task test_rmw_DEC;
  begin
    test_rmw_DEC_zpg;
    test_rmw_DEC_zpx;
    test_rmw_DEC_abs;
    test_rmw_DEC_abx;
  end
endtask

task test_rmw;
  begin
    test_rmw_DEC;
  end
endtask
