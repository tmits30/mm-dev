module itimer(
  input        CLK,
  input        RES_N,
  input        WE,
  input [1:0]  MODE,
  input [7:0]  IN,
  output [7:0] OUT
);

  localparam C_TIM_0001T = 2'b00;
  localparam C_TIM_0008T = 2'b01;
  localparam C_TIM_0064T = 2'b10;
  localparam C_TIM_1024T = 2'b11;

  reg [1:0]        mode;
  reg [9:0]        div_cnt;
  reg [8:0]        tim_cnt;
  reg              stop;

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
    else if (tim_cnt == 9'b0)
      stop <= 1'b1;
    else
      stop <= stop;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      tim_cnt <= 9'b0;
    else if (WE)
      tim_cnt <= {1'b0, IN};
    else if (stop)
      tim_cnt <= tim_cnt - 9'b1;
    else if (mode == C_TIM_0001T)
      tim_cnt <= tim_cnt - 9'b1;
    else if (mode == C_TIM_0008T && div_cnt[2:0] == 3'b111)
      tim_cnt <= tim_cnt - 9'b1;
    else if (mode == C_TIM_0064T && div_cnt[5:0] == 6'b111111)
      tim_cnt <= tim_cnt - 9'b1;
    else if (mode == C_TIM_1024T && div_cnt[9:0] == 10'b1111111111)
      tim_cnt <= tim_cnt - 9'b1;
    else
      tim_cnt <= tim_cnt;
  end

  assign OUT = tim_cnt[8] ? ~tim_cnt[7:0] + 1 : tim_cnt[7:0];

endmodule
