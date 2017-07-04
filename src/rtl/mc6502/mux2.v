module mux2(
  input [7:0]  D0, D1,
  input        S,
  output [7:0] Y
);

  assign Y = S ? D1 : D0;

endmodule
