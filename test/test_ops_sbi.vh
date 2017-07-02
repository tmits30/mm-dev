//
// Test for Single Byte Instructions
//

task test_sbi_NOP;
  begin
    meminit;
    mem.ram[0] <= 8'hea;
    mem.ram[1] <= 8'hea; // NOP
    reset_and_run;
  end
endtask

task test_sbi_SEC;
  localparam T = 8'h01;
  begin
    meminit;
    mem.ram[0] <= 8'h38;
    mem.ram[1] <= 8'hea; // NOP
    reset_and_run;
    $display("SEC %s: P=0x%02x (0x%02x)",
             (mpu.datapath.p == T) ? "Success" : "Fail",
             mpu.datapath.p, T);
  end
endtask

task test_sbi_SED;
  localparam T = 8'h08;
  begin
    meminit;
    mem.ram[0] <= 8'hf8;
    mem.ram[1] <= 8'hea; // NOP
    reset_and_run;
    $display("SED %s: P=0x%02x (0x%02x)",
             (mpu.datapath.p == T) ? "Success" : "Fail",
             mpu.datapath.p, T);
  end
endtask

task test_sbi_SEI;
  localparam T = 8'h04;
  begin
    meminit;
    mem.ram[0] <= 8'h78;
    mem.ram[1] <= 8'hea; // NOP
    reset_and_run;
    $display("SEI %s: P=0x%02x (0x%02x)",
             (mpu.datapath.p == T) ? "Success" : "Fail",
             mpu.datapath.p, T);
  end
endtask

task test_sbi_CLC;
  localparam T = 8'h00;
  begin
    meminit;
    mem.ram[0] <= 8'h18;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h01;
    reset_and_run;
    $display("CLC %s: P=0x%02x (0x%02x)",
             (mpu.datapath.p == T) ? "Success" : "Fail",
             mpu.datapath.p, T);
  end
endtask

task test_sbi_CLD;
  localparam T = 8'h00;
  begin
    meminit;
    mem.ram[0] <= 8'hd8;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h08;
    reset_and_run;
    $display("CLD %s: P=0x%02x (0x%02x)",
             (mpu.datapath.p == T) ? "Success" : "Fail",
             mpu.datapath.p, T);
  end
endtask

task test_sbi_CLI;
  localparam T = 8'h00;
  begin
    meminit;
    mem.ram[0] <= 8'h58;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h04;
    reset_and_run;
    $display("CLI %s: P=0x%02x (0x%02x)",
             (mpu.datapath.p == T) ? "Success" : "Fail",
             mpu.datapath.p, T);
  end
endtask

task test_sbi_CLV;
  localparam T = 8'h00;
  begin
    meminit;
    mem.ram[0] <= 8'hb8;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("CLV %s: P=0x%02x (0x%02x)",
             (mpu.datapath.p == T) ? "Success" : "Fail",
             mpu.datapath.p, T);
  end
endtask

task test_sbi_TAX;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'haa;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("TAX %s: P=0x%02x (0x%02x)",
             (mpu.datapath.x == T) ? "Success" : "Fail",
             mpu.datapath.x, T);
  end
endtask

task test_sbi_TAY;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'ha8;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("TAY %s: P=0x%02x (0x%02x)",
             (mpu.datapath.y == T) ? "Success" : "Fail",
             mpu.datapath.y, T);
  end
endtask

task test_sbi_TSX;
  localparam T = 8'hff;
  begin
    meminit;
    mem.ram[0] <= 8'hba;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("TSX %s: P=0x%02x (0x%02x)",
             (mpu.datapath.x == T) ? "Success" : "Fail",
             mpu.datapath.x, T);
  end
endtask

task test_sbi_TXA;
  localparam T = 8'h22;
  begin
    meminit;
    mem.ram[0] <= 8'h8a;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("TXA %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

task test_sbi_TXS;
  localparam T = 8'h22;
  begin
    meminit;
    mem.ram[0] <= 8'h9a;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("TXS %s: P=0x%02x (0x%02x)",
             (mpu.datapath.s == T) ? "Success" : "Fail",
             mpu.datapath.s, T);
  end
endtask

task test_sbi_TYA;
  localparam T = 8'h33;
  begin
    meminit;
    mem.ram[0] <= 8'h98;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("TYA %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

task test_sbi_DEX;
  localparam T = 8'h21;
  begin
    meminit;
    mem.ram[0] <= 8'hca;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("DEX %s: P=0x%02x (0x%02x)",
             (mpu.datapath.x == T) ? "Success" : "Fail",
             mpu.datapath.x, T);
  end
endtask

task test_sbi_DEY;
  localparam T = 8'h32;
  begin
    meminit;
    mem.ram[0] <= 8'h88;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("DEY %s: P=0x%02x (0x%02x)",
             (mpu.datapath.y == T) ? "Success" : "Fail",
             mpu.datapath.y, T);
  end
endtask

task test_sbi_INX;
  localparam T = 8'h23;
  begin
    meminit;
    mem.ram[0] <= 8'he8;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("INX %s: P=0x%02x (0x%02x)",
             (mpu.datapath.x == T) ? "Success" : "Fail",
             mpu.datapath.x, T);
  end
endtask

task test_sbi_INY;
  localparam T = 8'h34;
  begin
    meminit;
    mem.ram[0] <= 8'hc8;
    mem.ram[1] <= 8'hea; // NOP
    mpu.datapath.p_reg.Q <= 8'h40;
    reset_and_run;
    $display("INY %s: P=0x%02x (0x%02x)",
             (mpu.datapath.y == T) ? "Success" : "Fail",
             mpu.datapath.y, T);
  end
endtask

task test_sbi;
  begin
    test_sbi_NOP;
    test_sbi_SEC;
    test_sbi_SED;
    test_sbi_SEI;
    test_sbi_CLC;
    test_sbi_CLD;
    test_sbi_CLI;
    test_sbi_CLV;
    test_sbi_TAX;
    test_sbi_TAY;
    test_sbi_TSX;
    test_sbi_TXA;
    test_sbi_TXS;
    test_sbi_TYA;
    test_sbi_DEX;
    test_sbi_DEY;
    test_sbi_INX;
    test_sbi_INY;
  end
endtask
