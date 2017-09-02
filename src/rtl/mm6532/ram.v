module ram(
  input        RES_N,
  input [6:0]  A,
  input        WE,
  input [7:0]  WD,
  output [7:0] RD
);

  reg [7:0]    mem[127:0];

  integer      i;

  always @(*) begin
    if (!RES_N)
      for (i = 0; i < 128; i = i + 1)
        mem[i] = 8'b0;
    else if (WE)
      mem[A] <= WD;
  end

  assign RD = mem[A];

endmodule
