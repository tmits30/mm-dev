module itimer(
  input            CLK,
  input            RES_N,
  input            WE,
  input [1:0]      MODE,
  input [7:0]      IN,
  output reg [7:0] OUT
);

  localparam C_TIM_0001T = 2'b00;
  localparam C_TIM_0008T = 2'b01;
  localparam C_TIM_0064T = 2'b10;
  localparam C_TIM_1024T = 2'b11;

  reg              stop;
  reg [1:0]        mode;
  reg [9:0]        div_cnt;

  always @(posedge CLK) begin
    if (!RES_N)
      mode <= C_TIM_0001T;
    else if (WE)
      mode <= MODE;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      div_cnt <= 10'b0;
    else if (WE)
      div_cnt <= 10'b0;
    else
      div_cnt <= div_cnt + 10'b1;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      stop <= 1'b0;
    else if (WE)
      stop <= 1'b0;
    else if (OUT == 8'b0)
      stop <= 1'b1;
    else
      stop <= stop;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      OUT <= 8'b0;
    else if (WE)
      OUT <= IN;
    else if (stop)
      OUT <= OUT - 8'b1;
    else if (mode == C_TIM_0001T)
      OUT <= OUT - 8'b1;
    else if (mode == C_TIM_0008T && div_cnt[2:0] == 3'b111)
      OUT <= OUT - 8'b1;
    else if (mode == C_TIM_0064T && div_cnt[5:0] == 6'b111111)
      OUT <= OUT - 8'b1;
    else if (mode == C_TIM_1024T && div_cnt[9:0] == 10'b1111111111)
      OUT <= OUT - 8'b1;
    else
      OUT <= OUT;
  end

endmodule