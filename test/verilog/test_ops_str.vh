//
// Store Operations
//

// Zero Page Addressing

task test_str_STA_zpg;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'h85; // STA
    mem.ram[1] <= 8'h55; // operand
    mem.ram[2] <= 8'hea; // NOP
    // mem.ram[16'h0055] <= 8'h77; // source
    reset_and_run;
    $display("STA(zpg) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h0055] == T) ? "Success" : "Fail",
             mem.ram[16'h0055], T);
  end
endtask

// Zero Page, X Addressing

task test_str_STA_zpx;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'h95; // STA
    mem.ram[1] <= 8'h33; // operand
    mem.ram[2] <= 8'hea; // NOP
    // mem.ram[16'h0055] <= 8'h77; // source
    reset_and_run;
    $display("STA(zpx) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h0055] == T) ? "Success" : "Fail",
             mem.ram[16'h0055], T);
  end
endtask

// Absolute Addressing

task test_str_STA_abs;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'h8d; // STA
    mem.ram[1] <= 8'h55; // operand
    mem.ram[2] <= 8'h22; // operand
    mem.ram[3] <= 8'hea; // NOP
    // mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("STA(abs) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h2255] == T) ? "Success" : "Fail",
             mem.ram[16'h2255], T);
  end
endtask

// Absolute, X Addressing

task test_str_STA_abx;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'h9d; // STA
    mem.ram[1] <= 8'h33; // operand
    mem.ram[2] <= 8'h22; // operand
    mem.ram[3] <= 8'hea; // NOP
    // mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("STA(abx) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h2255] == T) ? "Success" : "Fail",
             mem.ram[16'h2255], T);
  end
endtask

// Absolute, Y Addressing

task test_str_STA_aby;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'h99; // STA
    mem.ram[1] <= 8'h22; // operand
    mem.ram[2] <= 8'h22; // operand
    mem.ram[3] <= 8'hea; // NOP
    // mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("STA(aby) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h2255] == T) ? "Success" : "Fail",
             mem.ram[16'h2255], T);
  end
endtask

// Indirect, X Addressing

task test_str_STA_inx;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'h81; // STA
    mem.ram[1] <= 8'h45; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0067] <= 8'h55; // ADL
    mem.ram[16'h0068] <= 8'h22; // ADH
    // mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("STA(inx) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h2255] == T) ? "Success" : "Fail",
             mem.ram[16'h2255], T);
  end
endtask

// Indirect, Y Addressing

task test_str_STA_iny;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'h91; // STA
    mem.ram[1] <= 8'h67; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0067] <= 8'h22; // ADL
    mem.ram[16'h0068] <= 8'h22; // ADH
    // mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("STA(iny) %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h2255] == T) ? "Success" : "Fail",
             mem.ram[16'h2255], T);
  end
endtask

task test_str_STA;
  begin
    test_str_STA_zpg;
    test_str_STA_zpx;
    test_str_STA_abs;
    test_str_STA_abx;
    test_str_STA_aby;
    test_str_STA_inx;
    test_str_STA_iny;
  end
endtask

task test_str;
  begin
    test_str_STA;
  end
endtask
