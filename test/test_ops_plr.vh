//
// Pull Operations
//

task test_plr_PLA;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'h68; // PLA
    mem.ram[1] <= 8'hea; // NOP
    mem.ram[16'h01ff] <= 8'h77;
    reset_and_run;
    $display("PLA %s: P=0x%02x (0x%02x)",
             (mpu.datapath.a == T && mpu.datapath.s == 8'hff) ? "Success" : "Fail",
             mpu.datapath.a, T);
  end
endtask

task test_plr_PLP;
  localparam T = 8'h77;
  begin
    meminit;
    mem.ram[0] <= 8'h28; // PLP
    mem.ram[1] <= 8'hea; // NOP
    mem.ram[16'h01ff] <= 8'h77;
    reset_and_run;
    $display("PLP %s: P=0x%02x (0x%02x)",
             (mpu.datapath.p == T && mpu.datapath.s == 8'hff) ? "Success" : "Fail",
             mpu.datapath.p, T);
  end
endtask

task test_plr;
  begin
    test_plr_PLA;
    test_plr_PLP;
  end
endtask
