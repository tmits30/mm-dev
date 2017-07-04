module flopenr #(
  parameter P_INIT = 8'h00
)(
  input            CLK,
  input            RES_N,
  input            WE,
  input [7:0]      D,
  output reg [7:0] Q
);

  always @(posedge CLK) begin
    if (!RES_N)
      Q <= P_INIT;
    else if (WE)
      Q <= D;
    else
      Q <= Q;
  end

endmodule
