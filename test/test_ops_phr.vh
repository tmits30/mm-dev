//
// Push Operations
//

task test_phr_PHA;
  localparam T = 8'h11;
  begin
    meminit;
    mem.ram[0] <= 8'h48; // PHA
    mem.ram[1] <= 8'hea; // NOP
    reset_and_run;
    $display("PHA %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h01ff] == T) ? "Success" : "Fail",
             mem.ram[16'h01ff], T);
  end
endtask

task test_phr_PHP;
  localparam T = 8'h00;
  begin
    meminit;
    mem.ram[0] <= 8'h08; // PHA
    mem.ram[1] <= 8'hea; // NOP
    reset_and_run;
    $display("PHP %s: P=0x%02x (0x%02x)",
             (mem.ram[16'h01ff] == T) ? "Success" : "Fail",
             mem.ram[16'h01ff], T);
  end
endtask

task test_phr;
  begin
    test_phr_PHA;
    test_phr_PHP;
  end
endtask
