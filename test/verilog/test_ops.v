module test_ops();

  localparam STEP = 8;
  localparam MEM_DEPTH = 16;

  reg clk, res_n;
  wire rdy, r_w;
  wire [15:0] ab;
  wire [7:0] db_in, db_out;

  assign rdy = 1'b1;

  memory #(MEM_DEPTH) mem(
    .A  (ab),
    .WE (~r_w),
    .WD (db_out),
    .RD (db_in)
  );

  mpu mpu(
    .CLK    (clk),
    .RES_N  (res_n),
    .RDY    (rdy),
    .DB_IN  (db_in),
    .R_W    (r_w),
    .ABL    (ab[7:0]),
    .ABH    (ab[15:8]),
    .DB_OUT (db_out)
  );

  always begin
    clk = 1; #(STEP/2);
    clk = 0; #(STEP/2);
  end

  task meminit;
    integer i;
    localparam i_max = 2**MEM_DEPTH;
    begin
      for (i = 0; i < i_max; i = i + 1) begin
        mem.ram[i] <= 8'h00;
      end
    end
  endtask

  task reset_and_run;
    begin
      res_n = 1; #(STEP*2);
      res_n = 0; #(STEP*2);
      res_n = 1; #(STEP*8);
    end
  endtask

  localparam SP_INIT = 16'h01fe;

`include "test_ops_sbi.vh"
`include "test_ops_iem.vh"
`include "test_ops_str.vh"
`include "test_ops_rmw.vh"
`include "test_ops_phr.vh"
`include "test_ops_plr.vh"
`include "test_ops_misc.vh"

  initial begin
    test_sbi; // Test for Single Byte Instructions
    test_iem; // Test for Internal Execution on Memory Instructions
    test_str; // Test for Store Operations
    test_rmw; // Test for Store Operations
    test_phr; // Test for Push Operations
    test_plr; // Test for Pull Operations
    test_misc; // Test for Misc
    $finish;
  end

endmodule
