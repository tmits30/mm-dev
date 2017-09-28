module itimer(
  input            CLK,
  input            RES_N,
  input            WE,
  input [1:0]      PRESCALE_IN,
  input [7:0]      IN,
  output reg [7:0] OUT,
  output reg       INTERRUPT
);

  localparam C_PRESCALE_0001T = 2'b00;
  localparam C_PRESCALE_0008T = 2'b01;
  localparam C_PRESCALE_0064T = 2'b10;
  localparam C_PRESCALE_1024T = 2'b11;

  reg [9:0]        count;

  always @(posedge CLK) begin
    if (!RES_N)
      count <= 10'b0;
    else if (WE)
      count <= 10'b1;
    else
      count <= count + 10'b1;
  end

  reg [1:0]        prescale;
  wire             prescale_out;

  always @(posedge CLK) begin
    if (!RES_N)
      prescale <= C_PRESCALE_0001T;
    else if (WE)
      prescale <= PRESCALE_IN;
    else if (OUT == 8'b0 && prescale_out)
      prescale <= C_PRESCALE_0001T;
    else
      prescale <= prescale;
  end

  assign prescale_out = (prescale == C_PRESCALE_0001T) ||
                        (prescale == C_PRESCALE_0008T && count[2:0] == 3'b0) ||
                        (prescale == C_PRESCALE_0064T && count[5:0] == 6'b0) ||
                        (prescale == C_PRESCALE_1024T && count[9:0] == 10'b0);

  always @(posedge CLK) begin
    if (!RES_N)
      OUT <= 8'b0;
    else if (WE)
      OUT <= IN - 8'b1;
    else if (prescale_out)
      OUT <= OUT - 8'b1;
    else
      OUT <= OUT;
  end

  always @(*) begin
    if (!RES_N)
      INTERRUPT = 1'b0;
    else if (OUT == 8'b0 && prescale_out)
      INTERRUPT = 1'b1;
    else
      INTERRUPT = 1'b0;
  end

endmodule
