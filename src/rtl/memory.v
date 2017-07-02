module memory #(
  parameter MEM_DEPTH = 16
)(
  input [15:0] A,
  input        WE,
  input [7:0]  WD,
  output [7:0] RD
);

  // reg [7:0]    ram [2**MEM_DEPTH-1:0];
  reg [7:0]    ram [0:2**MEM_DEPTH-1];
  assign RD = ram[A];

  always @(*) begin
    if (WE)
      ram[A] <= WD;
  end

endmodule
