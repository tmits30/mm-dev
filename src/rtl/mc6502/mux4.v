module mux4(
  input [7:0]  D0, D1, D2, D3,
  input [1:0]  S,
  output [7:0] Y
);

  wire [7:0]   y0, y1;

  mux2 m0(D0, D1, S[0], y0);
  mux2 m1(D2, D3, S[0], y1);
  mux2 m2(y0, y1, S[1], Y);

endmodule
