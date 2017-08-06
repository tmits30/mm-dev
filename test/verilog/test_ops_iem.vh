//
// Internal Execution on Memory Instructions
//

// Immdediate Addressing

task test_iem_LDA_imm;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'ha9; // LDA
    mem.ram[1] <= 8'h77; // operand
    mem.ram[2] <= 8'hea; // NOP
    reset_and_run;
    $display("LDA(imm) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Zero Page Addressing

task test_iem_LDA_zpg;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'ha5; // LDA
    mem.ram[1] <= 8'h55; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0055] <= 8'h77; // source
    reset_and_run;
    $display("LDA(zpg) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Zero Page, X Addressing

task test_iem_LDA_zpx;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'hb5; // LDA
    mem.ram[1] <= 8'h33; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0055] <= 8'h77; // source
    reset_and_run;
    $display("LDA(zpx) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Absolute Addressing

task test_iem_LDA_abs;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'had; // LDA
    mem.ram[1] <= 8'h55; // operand
    mem.ram[2] <= 8'h22; // operand
    mem.ram[3] <= 8'hea; // NOP
    mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("LDA(abs) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Absolute, X Addressing

task test_iem_LDA_abx;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'hbd; // LDA
    mem.ram[1] <= 8'h33; // operand
    mem.ram[2] <= 8'h22; // operand
    mem.ram[3] <= 8'hea; // NOP
    mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("LDA(abx) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Absolute, Y Addressing

task test_iem_LDA_aby;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'hb9; // LDA
    mem.ram[1] <= 8'h22; // operand
    mem.ram[2] <= 8'h22; // operand
    mem.ram[3] <= 8'hea; // NOP
    mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("LDA(aby) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Absolute, Y Addressing when the page boundary is crossed

task test_iem_LDA_abyc;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'hb9; // LDA
    mem.ram[1] <= 8'hf0; // operand
    mem.ram[2] <= 8'h21; // operand
    mem.ram[3] <= 8'hea; // NOP
    mem.ram[16'h2223] <= 8'h77; // source
    reset_and_run;
    $display("LDA(aby*) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Indirect, X Addressing

task test_iem_LDA_inx;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'ha1; // LDA
    mem.ram[1] <= 8'h45; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0067] <= 8'h55; // ADL
    mem.ram[16'h0068] <= 8'h22; // ADH
    mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("LDA(inx) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Indirect, Y Addressing

task test_iem_LDA_iny;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'hb1; // LDA
    mem.ram[1] <= 8'h67; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0067] <= 8'h22; // ADL
    mem.ram[16'h0068] <= 8'h22; // ADH
    mem.ram[16'h2255] <= 8'h77; // source
    reset_and_run;
    $display("LDA(iny) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

// Indirect, Y Addressing when the page boundary is crossed

task test_iem_LDA_inyc;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'hb1; // LDA
    mem.ram[1] <= 8'h67; // operand
    mem.ram[2] <= 8'hea; // NOP
    mem.ram[16'h0067] <= 8'hf0; // ADL
    mem.ram[16'h0068] <= 8'h21; // ADH
    mem.ram[16'h2223] <= 8'h77; // source
    reset_and_run;
    $display("LDA(iny*) %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

task test_iem_LDA;
  begin
    test_iem_LDA_imm;
    test_iem_LDA_zpg;
    test_iem_LDA_zpx;
    test_iem_LDA_abs;
    test_iem_LDA_abx;
    test_iem_LDA_aby;
    test_iem_LDA_abyc;
    test_iem_LDA_inx;
    test_iem_LDA_iny;
    test_iem_LDA_inyc;
  end
endtask

task test_iem;
  begin
    test_iem_LDA;
  end
endtask
