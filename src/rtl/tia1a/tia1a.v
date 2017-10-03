// Television Interface Adaptor (Model 1A)
module tia1a(
  input        MCLK,   // Machine clock
  input        CCLK,   // Color colck
  input        RES_N,  // For debugging
  input        DEL,    // Color delay input
  input        R_W,    // Read write signal from 6507
  input [3:0]  CS,     // Chip selects
  input [5:0]  A,      // Address bus from 6507
  input [5:0]  I,      // Dumped and latched input ports
  input [7:0]  D_IN,   // Processor input data bus
  output       RDY,    // This output goes to the RDY input of the 6507
  output       HSYNC,  // Composite video horizontal sync
  output       HBLANK, // Horizontal blank
  output       VSYNC,  // Composite video vertical sync
  output       VBLANK, // Vertical blank
  output [2:0] LUM,    // Video luminance outputs
  output [3:0] COL,    // Video color output
  output [1:0] AUD,    // Audio output
  output [7:0] D_OUT   // Processor output data bus
);

`include "params.vh"

  // vertical sync
  reg          vsync;

  // vertical blank
  reg [7:0]    vblank;

  // number-size player missile 0,1
  reg [7:0]    nusiz0, nusiz1;

  // color-lum player 0,1, playfield and background
  reg [7:0]    colup0, colup1, colupf, colubk;

  // control playfield ball size & collisions
  reg [7:0]    ctrlpf;

  // reflect player 0,1
  reg          refp0, refp1;

  // playfield register 20 bit
  reg [7:0]    pf0, pf1, pf2;
  wire [19:0]  pf;

  assign pf = {pf2,
               pf1[0], pf1[1], pf1[2], pf1[3],
               pf1[4], pf1[5], pf1[6], pf1[7],
               pf0[7:4]};

  // audio control
  reg [7:0]    audc0, audc1;

  // audio frequency
  reg [7:0]    audf0, audf1;

  // audio volume
  reg [7:0]    audv0, audv1;

  // graphics player
  reg [7:0]    grp0, grp1;
  reg [7:0]    grp0d, grp1d; // delayed

  // graphics (enable) missile 0,1 and ball
  reg          enam0, enam1, enabl, enabld;

  // horizontal motion player 0,1, missile 0,1 and ball
  reg [7:0]    hmp0, hmp1, hmm0, hmm1, hmbl;

  // strobe positions
  reg [7:0]    posp0, posp1, posm0, posm1, posbl;

  // vertical declay player 0,1 and ball
  reg          vdelp0, vdelp1, vdelbl;

  // reset missile 0,1 to player 0,1
  reg          resmp0, resmp1;

  // read collision
  reg          cxclr;
  reg [14:0]   cxr;

  //
  // Horizontal position counter
  //

  reg [7:0]    hcount;  // Horizontal count

  always @(posedge CCLK) begin
    if (!RES_N)
      hcount <= 8'h0;
    else if (CS[1:0] == 2'b1 && A == C_TIA_WADDR_RSYNC)
      hcount <= 8'h0; // intended for chip testing purpose
    else if (hcount == 8'd227)
      hcount <= 8'h0;
    else
      hcount <= hcount + 8'h1;
  end

  wire [7:0]   pixel;   // Horizontal pixel
  wire [5:0]   pixelpf; // Horizontal playfield pixel

  assign pixel = (hcount >= 8'd68) ? hcount - 8'd68 : 8'd0;
  assign pixelpf = pixel[7:2];

  //
  // Synchronization
  //

  reg          wsync;

  // Wait for sync
  always @(posedge CCLK) begin
    if (!RES_N)
      wsync <= 1'b0;
    else if (CS[1:0] == 2'b1 && A == C_TIA_WADDR_WSYNC)
      wsync <= 1'b1;
    else if (hcount == 8'd0)
      wsync <= 1'b0;
    else
      wsync <= wsync;
  end

  // RDY input of the 6507
  assign RDY = !wsync;

  // Horizontal and Vertical sync and blank
  assign HSYNC = (hcount >= 8'd20) && (hcount < 8'd36);
  assign HBLANK = (hcount < 8'd68);
  assign VSYNC = vsync;
  assign VBLANK = vblank[1];

  //
  // Object Graphics
  //

  wire [7:0] grp0_, grp1_, grm0_, grm1_, grbl_; // temporal graphics

  // Graphics player function
  function [7:0] grpx(input [7:0] gr, input refp);
    begin
      if (refp)
        // reflection graphics
        grpx = {gr[0], gr[1], gr[2], gr[3], gr[4], gr[5], gr[6], gr[7]};
      else
        grpx = gr;
    end
  endfunction

  // Graphics missile and ball function
  function [7:0] grmx(input [1:0] siz);
    begin
      case (siz)
        2'b00: grmx = 8'h01; // 1 pixel width
        2'b01: grmx = 8'h03; // 2 pixels width
        2'b10: grmx = 8'h0f; // 4 pixels width
        2'b11: grmx = 8'hff; // 8 pixels width
      endcase
    end
  endfunction

  assign grp0_ = grpx(vdelp0 ? grp0d : grp0, refp0);
  assign grp1_ = grpx(vdelp1 ? grp1d : grp1, refp1);
  assign grm0_ = grmx(nusiz0[5:4]);
  assign grm1_ = grmx(nusiz1[5:4]);
  assign grbl_ = grmx(ctrlpf[5:4]);

  //
  // Dot object pixels
  //

  /**
   * TODO: [RESMPx] As long as Bit 1 is set, the missile is hidden and its
   * horizontal position is centered on the players position. The centering
   * offset is +3 for normal, +6 for double, and +10 quad sized player
   * (that is giving good centering results with missile widths of 2, 4,
   * and 8 respectively).
   */

  wire       dotm0_, dotm1_, dotbl_; // temporal dot pixels
  wire       dotpf, dotp0, dotp1, dotm0, dotm1, dotbl; // dot pixels

  wire [5:0] pixelpfl, pixelpfr;

  assign pixelpfl = pixelpf;
  assign pixelpfr = ctrlpf[0] ? (6'd39 - pixelpf) : (pixelpf - 6'd20);
  assign dotpf = (pixelpf < 6'd20) ? pf[pixelpfl[4:0]] : pf[pixelpfr[4:0]];

  dotter dotterp0(pixel, posp0, grp0_, nusiz0[2:0], dotp0);
  dotter dotterp1(pixel, posp1, grp1_, nusiz1[2:0], dotp1);
  dotter dotterm0(pixel, posm0, grm0_, nusiz0[2:0], dotm0_);
  dotter dotterm1(pixel, posm1, grm1_, nusiz1[2:0], dotm1_);
  dotter dotterbl(pixel, posbl, grbl_,        3'b0, dotbl_);

  assign dotm0 = dotm0_ & enam0;
  assign dotm1 = dotm1_ & enam1;
  assign dotbl = dotbl_ & (vdelbl ? enabld : enabl);

  //
  // Collision Detection
  //

  always @(posedge CCLK) begin
    if (cxclr)
      cxr <= 15'h00;
    else
      cxr <= cxr | {dotp0 && dotp1, dotm0 && dotm1,  // CXPPMM
                    dotbl && dotpf,                  // CXBLPF
                    dotm1 && dotpf, dotm1 && dotbl,  // CXM1FB
                    dotm0 && dotpf, dotm0 && dotbl,  // CXM0FB
                    dotp1 && dotpf, dotp1 && dotbl,  // CXP1FB
                    dotp0 && dotpf, dotp0 && dotbl,  // CXP0FB
                    dotm1 && dotp0, dotm1 && dotp1,  // CXM1P
                    dotm0 && dotp1, dotm0 && dotp0}; // CXM0P
  end

  //
  // Color Luminance
  //

  reg [7:0]  colupf_; // color luminance for playfield
  reg [7:0]  colupx;  // color luminance for the pixel

  always @(*) begin
    if (ctrlpf[1])
      // score mode
      if (pixelpf < 6'd20)
        colupf_ = colup0;
      else
        colupf_ = colup1;
    else
      // normal mode
      colupf_ = colupf;
  end

  // Mux 4x7
  always @(*) begin
    if (ctrlpf[2]) // Playfield/Ball Priority
      // Above players/missiles
      if (dotp0 || dotm0)
        colupx = colup0;
      else if (dotp1 || dotm1)
        colupx = colup1;
      else if (dotbl)
        colupx = colupf;
      else if (dotpf)
        colupx = colupf_;
      else
        colupx = colubk;
    else
      // Normal
      if (dotbl)
        colupx = colupf;
      else if (dotpf)
        colupx = colupf_;
      else if (dotp0 || dotm0)
        colupx = colup0;
      else if (dotp1 || dotm1)
        colupx = colup1;
      else
        colupx = colubk;
  end

  assign LUM = HBLANK ? 3'b0 : colupx[3:1];
  assign COL = HBLANK ? 4'b0 : colupx[7:4];

  //
  // Input ports
  //

  reg [3:0] inptd; // Dumped input
  reg [1:0] inptl_; // Latched input

  wire [1:0] inptl;

  always @(*) begin
    if (vblank[7])
      // 1=Dumped to ground
      // 4 ports are grounded.
      inptd = 4'b0000;
    else
      // 0=Normal input
      // 4 ports are general purpose high impedance input ports.
      inptd = I[3:0]; // 4'bzzzz;
  end

  /**
   * TODO: understand latched input
   */
  always @(posedge MCLK) begin
    if (!RES_N)
      inptl_ <= 2'b00;
    else if (A == C_TIA_WADDR_VBLANK && D_IN[6])
      inptl_ <= I[5:4];
    else
      inptl_ <= inptl;
  end

  assign inptl = vblank[6] ? inptl_ : I[5:4];

  //
  // Audio Circuits
  //

  /**
   * TODO: audio
   */
  assign AUD = 2'b0;

  //
  // Data and addressing
  //

  // Write Addressing
  always @(posedge MCLK) begin
    if (!RES_N) begin
      vsync <= 1'b0;
      vblank <= 8'b0;
      nusiz0 <= 8'b0;
      nusiz1 <= 8'b0;
      colup0 <= 8'b0;
      colup1 <= 8'b0;
      colupf <= 8'b0;
      colubk <= 8'b0;
      ctrlpf <= 8'b0;
      refp0 <= 1'b0;
      refp1 <= 1'b0;
      pf0 <= 8'b0;
      pf1 <= 8'b0;
      pf2 <= 8'b0;
      audc0 <= 8'b0;
      audc1 <= 8'b0;
      audf0 <= 8'b0;
      audf1 <= 8'b0;
      audv0 <= 8'b0;
      audv1 <= 8'b0;
      grp0 <= 8'b0;
      grp1 <= 8'b0;
      grp0d <= 8'b0;
      grp1d <= 8'b0;
      enam0 <= 1'b0;
      enam1 <= 1'b0;
      enabl <= 1'b0;
      enabld <= 1'b0;
      hmp0 <= 8'b0;
      hmp1 <= 8'b0;
      hmm0 <= 8'b0;
      hmm1 <= 8'b0;
      hmbl <= 8'b0;
      vdelp0 <= 1'b0;
      vdelp1 <= 1'b0;
      vdelbl <= 1'b0;
      resmp0 <= 1'b0;
      resmp1 <= 1'b0;
      posp0 <= 8'b0; // strobe
      posp1 <= 8'b0; // strobe
      posm0 <= 8'b0; // strobe
      posm1 <= 8'b0; // strobe
      posbl <= 8'b0; // strobe
      cxclr <= 1'b0;
    end else if (CS[1:0] == 2'b01) begin // TODO: check CS cond
      if (!R_W)
        case (A)
          C_TIA_WADDR_VSYNC: begin
            // vertical sync set-clear
            vsync <= D_IN[1];
          end
          C_TIA_WADDR_VBLANK: begin
            // vertical blank set-clear
            vblank <= D_IN;
          end
          C_TIA_WADDR_WSYNC: begin
            // wait for leading edge of horizontal blank
          end
          C_TIA_WADDR_RSYNC: begin
            // reset horizontal sync counter
          end
          C_TIA_WADDR_NUSIZ0: begin
            // number-size player-missile 0
            nusiz0 <= D_IN;
          end
          C_TIA_WADDR_NUSIZ1: begin
            // number-size player-missile 1
            nusiz1 <= D_IN;
          end
          C_TIA_WADDR_COLUP0: begin
            // color-lum player 0
            colup0 <= D_IN;
          end
          C_TIA_WADDR_COLUP1: begin
            // color-lum player 1
            colup1 <= D_IN;
          end
          C_TIA_WADDR_COLUPF: begin
            // color-lum playfield
            colupf <= D_IN;
          end
          C_TIA_WADDR_COLUBK: begin
            // color-lum background
            colubk <= D_IN;
          end
          C_TIA_WADDR_CTRLPF: begin
            // control playfield ball size & collisions
            ctrlpf <= D_IN;
          end
          C_TIA_WADDR_REFP0: begin
            // reflect player 0
            refp0 <= D_IN[3];
          end
          C_TIA_WADDR_REFP1: begin
            // reflect player 1
            refp1 <= D_IN[3];
          end
          C_TIA_WADDR_PF0: begin
            // playfield register byte 0
            pf0 <= D_IN;
          end
          C_TIA_WADDR_PF1: begin
            // playfield register byte 1
            pf1 <= D_IN;
          end
          C_TIA_WADDR_PF2: begin
            // playfield register byte 2
            pf2 <= D_IN;
          end
          C_TIA_WADDR_RESP0: begin
            // reset player 0
            if (HBLANK)
              posp0 <= pixel + 8'd3;
            else
              posp0 <= pixel;
          end
          C_TIA_WADDR_RESP1: begin
            // reset player 1
            if (HBLANK)
              posp1 <= pixel + 8'd3;
            else
              posp1 <= pixel;
          end
          C_TIA_WADDR_RESM0: begin
            // reset missile 0
            if (HBLANK)
              posm0 <= pixel + 8'd2;
            else
              posm0 <= pixel;
          end
          C_TIA_WADDR_RESM1: begin
            // reset missile 1
            if (HBLANK)
              posm1 <= pixel + 8'd2;
            else
              posm1 <= pixel;
          end
          C_TIA_WADDR_RESBL: begin
            // reset ball
            if (HBLANK)
              posbl <= pixel + 8'd2;
            else
              posbl <= pixel;
          end
          C_TIA_WADDR_AUDC0: begin
            // audio control 0
            audc0 <= D_IN;
          end
          C_TIA_WADDR_AUDC1: begin
            // audio control 1
            audc1 <= D_IN;
          end
          C_TIA_WADDR_AUDF0: begin
            // audio frequency 0
            audf0 <= D_IN;
          end
          C_TIA_WADDR_AUDF1: begin
            // audio frequency 1
            audf1 <= D_IN;
          end
          C_TIA_WADDR_AUDV0: begin
            // audio volume 0
            audv0 <= D_IN;
          end
          C_TIA_WADDR_AUDV1: begin
            // audio volume 1
            audv1 <= D_IN;
          end
          C_TIA_WADDR_GRP0: begin
            // graphics player 0
            grp0 <= D_IN; // MSB first (from left to right)
            grp0d <= grp0;
          end
          C_TIA_WADDR_GRP1: begin
            // graphics player 1
            grp1 <= D_IN; // MSB first (from left to right)
            grp1d <= grp1;
            enabld <= enabl;
          end
          C_TIA_WADDR_ENAM0: begin
            // graphics (enable) missile 0
            enam0 <= D_IN[1];
          end
          C_TIA_WADDR_ENAM1: begin
            // graphics (enable) missile 1
            enam1 <= D_IN[1];
          end
          C_TIA_WADDR_ENABL: begin
            // graphics (enable) ball
            enabl <= D_IN[1];
          end
          C_TIA_WADDR_HMP0: begin
            // horizontal motion player 0
            hmp0 <= D_IN;
          end
          C_TIA_WADDR_HMP1: begin
            // horizontal motion player 1
            hmp1 <= D_IN;
          end
          C_TIA_WADDR_HMM0: begin
            // horizontal motion missile 0
            hmm0 <= D_IN;
          end
          C_TIA_WADDR_HMM1: begin
            // horizontal motion missile 1
            hmm1 <= D_IN;
          end
          C_TIA_WADDR_HMBL: begin
            // horizontal motion ball
            hmbl <= D_IN;
          end
          C_TIA_WADDR_VDELP0: begin
            // vertical delay player 0
            vdelp0 <= D_IN[0];
          end
          C_TIA_WADDR_VDEL01: begin
            // vertical delay player 1
            vdelp1 <= D_IN[0];
          end
          C_TIA_WADDR_VDELBL: begin
            // vertical delay ball
            vdelbl <= D_IN[0];
          end
          C_TIA_WADDR_RESMP0: begin
            // reset missile 0 to player 0
            resmp0 <= D_IN[1]; // (0=Normal, 1=Hide and Lock on player)
          end
          C_TIA_WADDR_RESMP1: begin
            // reset missile 1 to player 1
            resmp1 <= D_IN[1]; // (0=Normal, 1=Hide and Lock on player)
          end
          C_TIA_WADDR_HMOVE: begin
            // apply horizontal motion
            // HMOVE command should be used only immediately after WSYNC.
            /**
             * TODO: extra motion offsets when HMOVE is executed outside
             * of the horizontal blanking period.
             */
            posp0 <= (posp0 - {{4{hmp0[7]}}, hmp0[7:4]}) % 8'd160;
            posp1 <= (posp1 - {{4{hmp1[7]}}, hmp1[7:4]}) % 8'd160;
            posm0 <= (posm0 - {{4{hmm0[7]}}, hmm0[7:4]}) % 8'd160;
            posm1 <= (posm1 - {{4{hmm1[7]}}, hmm1[7:4]}) % 8'd160;
            posbl <= (posbl - {{4{hmbl[7]}}, hmbl[7:4]}) % 8'd160;
          end
          C_TIA_WADDR_HMCLR: begin
            // clear horizontal motion registers
            hmp0 <= 8'b0;
            hmp1 <= 8'b0;
            hmm0 <= 8'b0;
            hmm1 <= 8'b0;
            hmbl <= 8'b0;
          end
          C_TIA_WADDR_CXCLR: begin
            // clear collision latches
            cxclr <= 1'b1;
          end
          default: begin
          end
        endcase
      else
        ;
    end
  end

  // Read Addressing
  always @(posedge MCLK) begin
    if (!RES_N) begin
      D_OUT <= 8'h00;
    end else if (CS[1:0] == 2'b01) begin // TODO: check CS cond
      if (R_W)
        case (A)
          C_TIA_RADDR_CXM0P: begin
            // read collision M0-P1, M0-P0 (Bit 7,6)
            D_OUT <= {cxr[1:0], 6'b000000};
          end
          C_TIA_RADDR_CXM1P: begin
            // read collision M1-P0, M1-P1
            D_OUT <= {cxr[3:2], 6'b000000};
          end
          C_TIA_RADDR_CXP0FB: begin
            // read collision P0-PF, P0-BL
            D_OUT <= {cxr[5:4], 6'b000000};
          end
          C_TIA_RADDR_CXP1FB: begin
            // read collision P1-PF, P1-BL
            D_OUT <= {cxr[7:6], 6'b000000};
          end
          C_TIA_RADDR_CXM0FB: begin
            // read collision M0-PF, M0-BL
            D_OUT <= {cxr[9:8], 6'b000000};
          end
          C_TIA_RADDR_CXM1FB: begin
            // read collision M1-PF, M1-BL
            D_OUT <= {cxr[11:10], 6'b000000};
          end
          C_TIA_RADDR_CXBLPF: begin
            // read collision BL-PF, unused
            D_OUT <= {cxr[12:12], 7'b0000000};
          end
          C_TIA_RADDR_CXPPMM: begin
            // read collision P0-P1, M0-M1
            D_OUT <= {cxr[14:13], 6'b000000};
          end
          C_TIA_RADDR_INPT0: begin
            // read pot port
            D_OUT <= {inptd[0], 7'b0000000};
          end
          C_TIA_RADDR_INPT1: begin
            // read pot port
            D_OUT <= {inptd[1], 7'b0000000};
          end
          C_TIA_RADDR_INPT2: begin
            // read pot port
            D_OUT <= {inptd[2], 7'b0000000};
          end
          C_TIA_RADDR_INPT3: begin
            // read pot port
            D_OUT <= {inptd[3], 7'b0000000};
          end
          C_TIA_RADDR_INPT4: begin
            // read input
            D_OUT <= {inptl[0], 7'b0000000};
          end
          C_TIA_RADDR_INPT5: begin
            // read input
            D_OUT <= {inptl[1], 7'b0000000};
          end
          default: D_OUT <= 8'h00;
        endcase
      else
        ;
    end
  end

endmodule
