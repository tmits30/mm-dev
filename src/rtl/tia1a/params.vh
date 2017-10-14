//------------------------------------------------------------------------------
// Write Address
//------------------------------------------------------------------------------

localparam C_TIA_WADDR_VSYNC  = 6'h00; // vertical sync set-clear
localparam C_TIA_WADDR_VBLANK = 6'h01; // vertical blank set-clear
localparam C_TIA_WADDR_WSYNC  = 6'h02; // wait for leading edge of horizontal blank
localparam C_TIA_WADDR_RSYNC  = 6'h03; // reset horizontal sync counter
localparam C_TIA_WADDR_NUSIZ0 = 6'h04; // number-size player-missile 0
localparam C_TIA_WADDR_NUSIZ1 = 6'h05; // number-size player-missile 1
localparam C_TIA_WADDR_COLUP0 = 6'h06; // color-lum player 0
localparam C_TIA_WADDR_COLUP1 = 6'h07; // color-lum player 1
localparam C_TIA_WADDR_COLUPF = 6'h08; // color-lum playfield
localparam C_TIA_WADDR_COLUBK = 6'h09; // color-lum background
localparam C_TIA_WADDR_CTRLPF = 6'h0a; // control playfield ball size & collisions
localparam C_TIA_WADDR_REFP0  = 6'h0b; // reflect player 0
localparam C_TIA_WADDR_REFP1  = 6'h0c; // reflect player 1
localparam C_TIA_WADDR_PF0    = 6'h0d; // playfield register byte 0
localparam C_TIA_WADDR_PF1    = 6'h0e; // playfield register byte 1
localparam C_TIA_WADDR_PF2    = 6'h0f; // playfield register byte 2
localparam C_TIA_WADDR_RESP0  = 6'h10; // reset player 0
localparam C_TIA_WADDR_RESP1  = 6'h11; // reset player 1
localparam C_TIA_WADDR_RESM0  = 6'h12; // reset missile 0
localparam C_TIA_WADDR_RESM1  = 6'h13; // reset missile 1
localparam C_TIA_WADDR_RESBL  = 6'h14; // reset ball
localparam C_TIA_WADDR_AUDC0  = 6'h15; // audio control 0
localparam C_TIA_WADDR_AUDC1  = 6'h16; // audio control 1
localparam C_TIA_WADDR_AUDF0  = 6'h17; // audio frequency 0
localparam C_TIA_WADDR_AUDF1  = 6'h18; // audio frequency 1
localparam C_TIA_WADDR_AUDV0  = 6'h19; // audio volume 0
localparam C_TIA_WADDR_AUDV1  = 6'h1a; // audio volume 1
localparam C_TIA_WADDR_GRP0   = 6'h1b; // graphics player 0
localparam C_TIA_WADDR_GRP1   = 6'h1c; // graphics player 1
localparam C_TIA_WADDR_ENAM0  = 6'h1d; // graphics (enable) missile 0
localparam C_TIA_WADDR_ENAM1  = 6'h1e; // graphics (enable) missile 1
localparam C_TIA_WADDR_ENABL  = 6'h1f; // graphics (enable) ball
localparam C_TIA_WADDR_HMP0   = 6'h20; // horizontal motion player 0
localparam C_TIA_WADDR_HMP1   = 6'h21; // horizontal motion player 1
localparam C_TIA_WADDR_HMM0   = 6'h22; // horizontal motion missile 0
localparam C_TIA_WADDR_HMM1   = 6'h23; // horizontal motion missile 1
localparam C_TIA_WADDR_HMBL   = 6'h24; // horizontal motion ball
localparam C_TIA_WADDR_VDELP0 = 6'h25; // vertical delay player 0
localparam C_TIA_WADDR_VDELP1 = 6'h26; // vertical delay player 1
localparam C_TIA_WADDR_VDELBL = 6'h27; // vertical delay ball
localparam C_TIA_WADDR_RESMP0 = 6'h28; // reset missile 0 to player 0
localparam C_TIA_WADDR_RESMP1 = 6'h29; // reset missile 1 to player 1
localparam C_TIA_WADDR_HMOVE  = 6'h2a; // apply horizontal motion
localparam C_TIA_WADDR_HMCLR  = 6'h2b; // clear horizontal motion registers
localparam C_TIA_WADDR_CXCLR  = 6'h2c; // clear collision latches

//------------------------------------------------------------------------------
// Read Address
//------------------------------------------------------------------------------

localparam C_TIA_RADDR_CXM0P  = 6'h00; // read collision M0-P1, M0-P0 (Bit 7,6)
localparam C_TIA_RADDR_CXM1P  = 6'h01; // read collision M1-P0, M1-P1
localparam C_TIA_RADDR_CXP0FB = 6'h02; // read collision P0-PF, P0-BL
localparam C_TIA_RADDR_CXP1FB = 6'h03; // read collision P1-PF, P1-BL
localparam C_TIA_RADDR_CXM0FB = 6'h04; // read collision M0-PF, M0-BL
localparam C_TIA_RADDR_CXM1FB = 6'h05; // read collision M1-PF, M1-BL
localparam C_TIA_RADDR_CXBLPF = 6'h06; // read collision BL-PF, unused
localparam C_TIA_RADDR_CXPPMM = 6'h07; // read collision P0-P1, M0-M1
localparam C_TIA_RADDR_INPT0  = 6'h08; // read pot port
localparam C_TIA_RADDR_INPT1  = 6'h09; // read pot port
localparam C_TIA_RADDR_INPT2  = 6'h0a; // read pot port
localparam C_TIA_RADDR_INPT3  = 6'h0b; // read pot port
localparam C_TIA_RADDR_INPT4  = 6'h0c; // read input
localparam C_TIA_RADDR_INPT5  = 6'h0d; // read input

//------------------------------------------------------------------------------
// Common function
//------------------------------------------------------------------------------

function [3:0] reverse4(input [3:0] in);
  begin
    reverse4 = {in[0], in[1], in[2], in[3]};
  end
endfunction

function [7:0] reverse8(input [7:0] in);
  begin
    reverse8 = {in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]};
  end
endfunction
