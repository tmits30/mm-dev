module mux8(
  input [7:0]  D0, D1, D2, D3, D4, D5, D6, D7,
  input [2:0]  S,
  output [7:0] Y
);

  wire [7:0]   y0, y1;

  mux4 m0(D0, D1, D2, D3, S[1:0], y0);
  mux4 m1(D4, D5, D6, D7, S[1:0], y1);
  mux2 m2(y0, y1, S[2], Y);

endmodule
