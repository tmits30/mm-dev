module pcadder(
  input            RES_N,
  input [7:0]      IL,
  input [7:0]      IH,
  input [7:0]      SRC,
  input [1:0]      CTRL,
  output reg [7:0] OL,
  output reg [7:0] OH,
  output reg       CARRY
);

`include "params.vh"

  wire [8:0] dst;

  assign dst = IL + 1'b1 + SRC;

  always @(*) begin
    if (CTRL == C_PCADDER_CTRL_INC) begin
      if (IL == 8'hff) begin
        OL = 8'h00;
        if (IH == 8'hff)
          OH = 8'h00;
        else
          OH = IH + 1'b1;
      end else begin
        OL = IL + 1'b1;
        OH = IH;
      end
    end else if (CTRL == C_PCADDER_CTRL_ADD) begin
      OL = dst[7:0];
      OH = IH;
    end else if (CTRL == C_PCADDER_CTRL_CADD) begin
      OL = IL;
      OH = IH + {7'b0, CARRY};
    end else begin
      OL = IL;
      OH = IH;
    end
  end

  always @(*) begin
    if (!RES_N)
      CARRY = 1'b0;
    else if (CTRL == C_PCADDER_CTRL_ADD)
      CARRY = dst[8];
    else
      CARRY = CARRY;
  end

endmodule
