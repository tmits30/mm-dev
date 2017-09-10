// 6532 RAM-I/O-Timer (RIOT)
// TODO: understand edge-detecting
module mm6532(
  input        CLK,
  input        RES_N,   // Reset
  input        R_W,     // Read 0, Write 1
  input [1:0]  CS,      // Chip select (CS1 and CS2_N)
  input        RS_N,    // RAM select
  input [6:0]  A,       // Address
  input [7:0]  D_IN,    // Data bus buffer (in)
  input [7:0]  PA_IN,   // Peripheral data buffer A (in)
  input [7:0]  PB_IN,   // Peripheral data buffer B (in)
  output       IRQ_N,   // Interrupt control
  output [7:0] D_OUT,   // Data bus buffer (out)
  output [7:0] PA_OUT,  // Peripheral data buffer A (out)
  output [7:0] PB_OUT   // Peripheral data buffer B (out)
);

  //
  // Address decoding
  //

  reg          ram_en, dra_en, ddra_en, drb_en, ddrb_en,
               tim_en, irq_en, edc_en;

  always @(*) begin
    {ram_en, dra_en, ddra_en, drb_en, ddrb_en, tim_en} = 6'b0;
    if (CS == 2'b01 && !RS_N)
      ram_en = 1'b1;    // Write/Read RAM
    else begin
      if (A[2:0] == 3'b000)
        dra_en = 1'b1;  // Write/Read Output Reg A
      else if (A[2:0] == 3'b001)
        ddra_en = 1'b1; // Write/Read DDRA
      else if (A[2:0] == 3'b010)
        drb_en = 1'b1;  // Write/Read Output Reg B
      else if (A[2:0] == 3'b011)
        ddrb_en = 1'b1; // Write/Read DDRB
      else if ((!R_W & A[4]) || (R_W & !A[0] & A[2]))
        tim_en = 1'b1;  // Write/Read Timer
      else if (R_W & A[0] & A[2])
        irq_en = 1'b1;  // Read Interrupt Flag
      else if (!R_W & !A[4] & A[2])
        edc_en = 1'b1;  // Write Edge Detect Control
    end
  end

  //
  // 128 x 8 RAM
  //

  wire [7:0] ramd;

  ram ram(
    .RES_N (RES_N),
    .A     (A),
    .WE    (ram_en & !R_W),
    .WD    (D_IN),
    .RD    (ramd)
  );

  //
  // Data register A/B and DDR A/B
  //

  wire [7:0]   dra, drb;   // Data register
  wire [7:0]   ddra, ddrb; // Data direction register

  flopenr dra_reg(
    .CLK   (CLK),
    .RES_N (RES_N),
    .WE    (dra_en & !R_W),
    .D     (D_IN),
    .Q     (dra)
  );

  flopenr ddra_reg(
    .CLK   (CLK),
    .RES_N (RES_N),
    .WE    (ddra_en & !R_W),
    .D     (D_IN),
    .Q     (ddra)
  );

  flopenr drb_reg(
    .CLK   (CLK),
    .RES_N (RES_N),
    .WE    (drb_en & !R_W),
    .D     (D_IN),
    .Q     (drb)
  );

  flopenr ddrb_reg(
    .CLK   (CLK),
    .RES_N (RES_N),
    .WE    (ddrb_en & !R_W),
    .D     (D_IN),
    .Q     (ddrb)
  );

  //
  // Interval timer
  //

  wire [7:0]   tim;

  itimer itimer(
    .CLK   (CLK),
    .RES_N (RES_N),
    .WE    (tim_en & !R_W),
    .MODE  (A[1:0]),
    .IN    (D_IN),
    .OUT   (tim)
  );

  //
  // Interrupt flag
  //

  wire         pa7;
  reg          pa7_irq_mode; // A0 = 0/1 for negative/positive edge-detect
  reg          pa7_irq, tim_irq;
  reg          pa7_irq_en, tim_irq_en;

  assign pa7 = (PA[7] & ~ddra[7]) | (dra[7] & ddra[7]);

  always @(posedge CLK) begin
    if (!RES_N)
      pa7_irq_mode <= 1'b0;
    else if (edc_en)
      pa7_irq_mode <= A[0];
    else
      pa7_irq_mode <= pa7_irq_mode;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      pa7_irq <= 1'b0;
    else if (irq_en)
      pa7_irq <= 1'b0;
    else
      pa7_irq <= pa7_irq | pa7 == pa7_irq_mode;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      pa7_irq_en <= 1'b0;
    else if (edc_en)
      pa7_irq_en <= A[1];
    else
      pa7_irq_en <= pa7_irq_en;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      tim_irq <= 1'b0;
    else if (tim == 8'f00)
      tim_irq <= 1'b1;
    else if (tim_en)
      tim_irq <= 1'b0;
    else
      tim_irq <= tim_irq;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      tim_irq_en <= 1'b0;
    else if (tim_en)
      tim_irq_en <= A[3];
    else
      tim_irq_en <= tim_irq_en;
  end

  assign IRQ_N = !((tim_irq & tim_irq_en) | (pa7_irq & pa7_irq_en));

  //
  // Output
  //

  function [7:0] data_out();
    begin
      if (ram_en)
        data_out = ramd;
      else if (dra_en)
        data_out = (PA_IN & ~ddra) | (dra & ddra);
      else if (ddra_en)
        data_out = ddra;
      else if (drb_en)
        data_out = (PB_IN & ~ddrb) | (drb & ddrb);
      else if (ddrb_en)
        data_out = ddrb;
      else if (tim_en)
        data_out = tim;
      else if (irq_en)
        data_out = {tim_irq, pa7_irq, 6'b0};
      else
        data_out = 8'h00;
    end
  endfunction

  assign D_OUT = data_out();

endmodule
