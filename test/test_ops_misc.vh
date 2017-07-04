//
// Test for Misc
//

task test_misc_JSR;
  localparam T_S = (SP_INIT[7:0] - 2);
  localparam T_SP0 = 8'h44;
  localparam T_SP1 = 8'h68;
  localparam T_PCL = 8'h55;
  localparam T_PCH = 8'h22;
  begin
    meminit;
    mem.ram[16'h2255] <= 8'hea;
    mem.ram[16'h4466] <= 8'h20; // JSR
    mem.ram[16'h4467] <= T_PCL; // 1st operand ADL
    mem.ram[16'h4468] <= T_PCH; // 2nd operand ADH
    mem.ram[16'h4469] <= 8'hea; // NOP
    reset_and_run;
    $display("JSR %s: 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mem.ram[SP_INIT-0] == T_SP0 &&
              mem.ram[SP_INIT-1] == T_SP1 &&
              mpu.datapath.s == T_S &&
             mpu.datapath.pcl == T_PCL+1 &&
             mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mem.ram[SP_INIT-0], T_SP0,
             mem.ram[SP_INIT-1], T_SP1,
             mpu.datapath.s, T_S,
             mpu.datapath.pcl, T_PCL+1,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc_BRK;
  localparam T_S = (SP_INIT[7:0] - 3);
  localparam T_SP0 = 8'h44;
  localparam T_SP1 = 8'h67;
  localparam T_SP2 = 8'h20;
  localparam T_PCL = 8'h55;
  localparam T_PCH = 8'h22;
  begin
    meminit;
    mem.ram[16'h0000] <= 8'hea;
    mem.ram[16'h2255] <= 8'hea; // NOP
    mem.ram[16'h4466] <= 8'h00; // BRK
    mem.ram[16'h4467] <= 8'hea; // NOP
    mem.ram[16'hfffe] <= T_PCL; // 1st operand ADL
    mem.ram[16'hffff] <= T_PCH; // 2nd operand ADH
    reset_and_run;
    $display("BRK %s: 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mem.ram[SP_INIT-0] == T_SP0 &&
              mem.ram[SP_INIT-1] == T_SP1 &&
              mem.ram[SP_INIT-2] == T_SP2 &&
              mpu.datapath.s == T_S &&
              mpu.datapath.pcl == T_PCL+1 &&
              mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mem.ram[SP_INIT-0], T_SP0,
             mem.ram[SP_INIT-1], T_SP1,
             mem.ram[SP_INIT-2], T_SP2,
             mpu.datapath.s, T_S,
             mpu.datapath.pcl, T_PCL+1,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc_RTI;
  // P_S_INIT=8'hfb;
  localparam T_S = 8'hfa + 3;
  localparam T_P = 8'h20;
  localparam T_PCL = 8'h55;
  localparam T_PCH = 8'h22;
  begin
    meminit;
    mem.ram[16'h0000] <= 8'h40;
    mem.ram[16'h01fb] <= T_P;
    mem.ram[16'h01fc] <= T_PCL;
    mem.ram[16'h01fd] <= T_PCH;
    reset_and_run;
    $display("RTI %s: 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mpu.datapath.s == T_S &&
              mpu.datapath.p == T_P &&
              mpu.datapath.pcl == T_PCL+1 &&
              mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mpu.datapath.s, T_S,
             mpu.datapath.p, T_P,
             mpu.datapath.pcl, T_PCL+1,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc_RTS;
  localparam T_S = 8'hfa + 2;
  localparam T_PCL = 8'h55;
  localparam T_PCH = 8'h22;
  begin
    meminit;
    mem.ram[16'h0000] <= 8'h60;
    mem.ram[16'h01fb] <= T_PCL;
    mem.ram[16'h01fc] <= T_PCH;
    mem.ram[16'h2256] <= 8'hea;
    reset_and_run;
    $display("RTS %s: 0x%02x (0x%02x) 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mpu.datapath.s == T_S &&
              mpu.datapath.pcl == T_PCL+2 &&
              mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mpu.datapath.s, T_S,
             mpu.datapath.pcl, T_PCL+2,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc_JMP_abs;
  localparam T_PCL = 8'h55;
  localparam T_PCH = 8'h22;
  begin
    meminit;
    mem.ram[16'h0000] <= 8'h4c;
    mem.ram[16'h0001] <= T_PCL;
    mem.ram[16'h0002] <= T_PCH;
    mem.ram[16'h2255] <= 8'hea;
    reset_and_run;
    $display("JMP(abs) %s: 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mpu.datapath.pcl == T_PCL+2 &&
              mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mpu.datapath.pcl, T_PCL+2,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc_JMP_ind;
  localparam T_PCL = 8'h55;
  localparam T_PCH = 8'h22;
  begin
    meminit;
    mem.ram[16'h0000] <= 8'h6c;
    mem.ram[16'h0001] <= 8'h66;
    mem.ram[16'h0002] <= 8'h44;
    mem.ram[16'h4466] <= 8'h55;
    mem.ram[16'h4467] <= 8'h22;
    mem.ram[16'h2255] <= 8'hea;
    reset_and_run;
    $display("JMP(ind) %s: 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mpu.datapath.pcl == T_PCL+2 &&
              mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mpu.datapath.pcl, T_PCL+2,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc_BCC_t1;
  localparam T_PCL = 8'h02;
  localparam T_PCH = 8'h00;
  begin
    meminit;
    mem.ram[16'h0000] <= 8'h90;
    mem.ram[16'h0001] <= 8'h53;
    mem.ram[16'h0002] <= 8'hea;
    mem.ram[16'h0055] <= 8'hea;
    reset_and_run;
    $display("BCC(T1) %s: 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mpu.datapath.pcl == T_PCL+2 &&
              mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mpu.datapath.pcl, T_PCL+2,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc_BCC_t2;
  localparam T_PCL = 8'h55;
  localparam T_PCH = 8'h00;
  begin
    meminit;
    mem.ram[16'h0000] <= 8'h90;
    mem.ram[16'h0001] <= 8'h53;
    mem.ram[16'h0055] <= 8'hea;
    reset_and_run;
    $display("BCC(T2) %s: 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mpu.datapath.pcl == T_PCL+2 &&
              mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mpu.datapath.pcl, T_PCL+2,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc_BCC_t3;
  localparam T_PCL = 8'h22;
  localparam T_PCH = 8'h01;
  begin
    meminit;
    mem.ram[16'h0040] <= 8'h90;
    mem.ram[16'h0041] <= 8'he0;
    mem.ram[16'h0122] <= 8'hea;
    reset_and_run;
    $display("BCC(T2) %s: 0x%02x (0x%02x) 0x%02x (0x%02x)",
             (mpu.datapath.pcl == T_PCL+2 &&
              mpu.datapath.pch == T_PCH) ? "Success" : "Fail",
             mpu.datapath.pcl, T_PCL+2,
             mpu.datapath.pch, T_PCH);
  end
endtask

task test_misc;
  begin
    test_misc_JSR;
    test_misc_BRK;
    test_misc_RTI;
    test_misc_RTS;
    test_misc_JMP_abs;
    test_misc_JMP_ind;
    test_misc_BCC_t1;
    test_misc_BCC_t2;
    test_misc_BCC_t3;
  end
endtask
