module dotter(
  input [7:0] PX,
  input [7:0] POS,
  input [7:0] GR,
  input [2:0] SIZ,
  output      DOT
);

  objPixelOn (
    .pixelNum (PX),
    .objPos   (POS),
    .objMask  (GR),
    .objSize  (SIZ),
    .pixelOn  (DOT)
  );  

endmodule
