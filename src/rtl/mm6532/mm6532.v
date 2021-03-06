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
    {ram_en, dra_en, ddra_en, drb_en, ddrb_en, tim_en, irq_en, edc_en} = 8'b0;
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

  reg [7:0] dra, drb;   // Data register
  reg [7:0] ddra, ddrb; // Data direction register

  always @(posedge CLK) begin
    if (!RES_N)
      dra <= 8'h00;
    else if (dra_en & !R_W)
      dra <= D_IN;
    else
      dra <= dra;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      ddra <= 8'h00;
    else if (ddra_en & !R_W)
      ddra <= D_IN;
    else
      ddra <= ddra;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      drb <= 8'h00;
    else if (drb_en & !R_W)
      drb <= D_IN;
    else
      drb <= drb;
  end

  always @(posedge CLK) begin
    if (!RES_N)
      ddrb <= 8'h00;
    else if (ddrb_en & !R_W)
      ddrb <= D_IN;
    else
      ddrb <= ddrb;
  end

  //
  // Interval timer
  //

  wire [7:0]   tim;
  wire         tim_irq_;

  itimer itimer(
    .CLK         (CLK),
    .RES_N       (RES_N),
    .WE          (tim_en & !R_W),
    .PRESCALE_IN (A[1:0]),
    .IN          (D_IN),
    .OUT         (tim),
    .INTERRUPT   (tim_irq_)
  );

  // I/O ports

  wire [7:0]   pa, pb;

  assign pa = (PA_IN & ~ddra) | (dra & ddra);
  assign pb = (PB_IN & ~ddrb) | (drb & ddrb);

  //
  // Interrupt flag
  //

  reg          pa7_irq_mode; // A0 = 0/1 for negative/positive edge-detect
  reg          pa7_irq, tim_irq;
  reg          pa7_irq_en, tim_irq_en;

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
      pa7_irq <= pa[7] == pa7_irq_mode;
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
    else if (tim_irq_ && R_W) // TODO: is this correct?
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
        data_out = pa;
      else if (ddra_en)
        data_out = ddra;
      else if (drb_en)
        data_out = pb;
      else if (ddrb_en)
        data_out = ddrb;
      else if (tim_en)
        if (tim_irq)
          data_out = ~tim + 8'b1 - 8'b1;
        else
          data_out = tim;
      else if (irq_en)
        data_out = {tim_irq & tim_irq_en, pa7_irq & pa7_irq_en, 6'b0};
      else
        data_out = 8'h00;
    end
  endfunction

  assign D_OUT = data_out();

  assign PA_OUT = dra & ddra;
  assign PB_OUT = drb & ddrb;

endmodule
