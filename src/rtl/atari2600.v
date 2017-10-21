// Atari2600
// - memory map: www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-05.html
module atari2600(
  input         MCLK,   // Machine clock
  input         CCLK,   // Color clock
  input         RES_N,  // Reset
  input [4:0]   CTRL_A, // Input Joystick controller A
  input [4:0]   CTRL_B, // Input Joystick controller A
  input [1:0]   C_DIF,  // Input console difficulty switches
  input         C_COL,  // Input console color switches
  input         C_SEL,  // Input console select switches
  input         C_STA,  // Input console start switches
  input [7:0]   D_IN,   // Input data from ROM
  output        CS,     // ROM chip selects
  output [11:0] ADDR,   // ROM address
  output        HSYNC,  // Horizontal sync
  output        HBLANK, // Horizontal blank
  output        VSYNC,  // Vertical sync
  output        VBLANK, // Vertical blank
  output [3:0]  COL,    // Video color output
  output [1:0]  LUM     // Video luminance output
);

  //
  // MM6502
  //

  wire          mpu_rdy;
  wire          mpu_r_w;
  wire [15:0]   mpu_addr;
  wire [7:0]    mpu_d_in, mpu_d_out;

  assign mpu_rdy = tia_rdy;

  // Address range | Function
  // $0000-$007f   | TIA registers
  // $0080-$00ff   | RAM
  // $0200-$02ff   | RIOT registers
  // $1000-$1fff   | ROM
  always @(*) begin
    if (mpu_addr[12])
      mpu_d_in = D_IN;       // from ROM
    else if (mpu_addr[9])
      mpu_d_in = riot_d_out; // from RIOT registers
    else if (mpu_addr[7])
      mpu_d_in = riot_d_out; // from RAM
    else
      mpu_d_in = tia_d_out;  // from TIA registers
  end

  mm6502 mpu(
    .CLK    (MCLK),           // Machine clock
    .RES_N  (RES_N),          // Reset
    .RDY    (mpu_rdy),        // Ready
    .DB_IN  (mpu_d_in),       // Data in
    .R_W    (mpu_r_w),        // Read(1)/Write(0)
    .ABL    (mpu_addr[15:8]), // Address bus low
    .ABH    (mpu_addr[7:0]),  // Address bus high
    .DB_OUT (mpu_d_out)       // Data out
  );

  //
  // MM6532 RIOT
  //

  wire         riot_r_w;
  wire [6:0]   riot_addr;
  wire [7:0]   riot_d_in, riot_d_out;
  wire [1:0]   riot_cs;
  wire         riot_rs_n;
  wire         riot_irq_n;
  wire [7:0]   riot_pa_in, riot_pa_out;
  wire [7:0]   riot_pb_in, riot_pb_out;

  assign riot_r_w = mpu_r_w;
  assign riot_cs = {mpu_addr[12], mpu_addr[7]};
  assign riot_rs_n = mpu_addr[9];
  assign riot_addr = mpu_addr[6:0];
  assign riot_d_in = mpu_d_out;
  assign riot_pa_in = {CTRL_A[3:0], CTRL_B[3:0]};
  assign riot_pb_in = {C_DIF, 2'b00, C_COL, 1'b0, C_SEL, C_STA};

  mm6532 riot(
    .CLK    (MCLK),        // Machine clock
    .RES_N  (RES_N),       // Reset
    .R_W    (riot_r_w),    // Read(1)/Write(0)
    .CS     (riot_cs),     // Chip select (CS1 and CS2_N)
    .RS_N   (riot_rs_n),   // RAM select
    .A      (riot_addr),   // Address
    .D_IN   (riot_d_in),   // Data bus buffer (in)
    .PA_IN  (riot_pa_in),  // Peripheral data buffer A (in)
    .PB_IN  (riot_pb_in),  // Peripheral data buffer B (in)
    .IRQ_N  (riot_irq_n),  // Interrupt control
    .D_OUT  (riot_d_out),  // Data bus buffer (out)
    .PA_OUT (riot_pa_out), // Peripheral data buffer A (out)
    .PB_OUT (riot_pb_out)  // Peripheral data buffer B (out)
  );

  //
  // TIA-1A
  //

  wire         tia_r_w;
  wire [3:0]   tia_cs;
  wire [5:0]   tia_addr;
  wire [5:0]   tia_inpt;
  wire [7:0]   tia_d_in, tia_d_out;

  assign tia_r_w = mpu_r_w;
  assign tia_cs = {2'b01, mpu_addr[12], mpu_addr[7]};
  assign tia_addr = mpu_addr[5:0];
  assign tia_inpt = {CTRL_B[4], CTRL_A[4], 4'b0};
  assign tia_d_in = mpu_d_out;

  tia1a tia(
    .MCLK   (MCLK),       // Machine clock
    .CCLK   (CCLK),       // Color colck
    .RES_N  (1'b1),       // For debugging
    .DEL    (1'b0),       // Color delay input (TODO)
    .R_W    (tia_r_w),    // Read write signal from 6507
    .CS     (tia_cs),     // Chip selects
    .A      (tia_addr),   // Address bus from 6507
    .I      (tia_inpt),   // Dumped and latched input ports
    .D_IN   (tia_d_in),   // Processor input data bus
    .RDY    (tia_rdy),    // This output goes to the RDY input of the 6507
    .HSYNC  (HSYNC),      // Composite video horizontal sync
    .HBLANK (HBLANK),     // Horizontal blank
    .VSYNC  (VSYNC),      // Composite video vertical sync
    .VBLANK (VBLANK),     // Vertical blank
    .LUM    (LUM),        // Video luminance outputs
    .COL    (COL),        // Video color output
    .AUD    (2'b0),       // Audio output (TODO)
    .D_OUT  (tia_d_out)   // Processor output data bus
  );

  //
  // Output
  //

  assign CS = mpu_addr[12];
  assign ADDR = mpu_addr[11:0];
   
endmodule
