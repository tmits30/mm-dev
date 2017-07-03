module datapath #(
  parameter P_PCL_INIT = 8'h00,
  parameter P_PCH_INIT = 8'h00,
  parameter P_A_INIT   = 8'h11, //00
  parameter P_X_INIT   = 8'h22, //00
  parameter P_Y_INIT   = 8'h33, //00
  parameter P_S_INIT   = 8'hfe, //ff
  parameter P_P_INIT   = 8'h20, //00
  parameter P_ABL_INIT = 8'h00,
  parameter P_ABH_INIT = 8'h00
)(
  input        CLK,
  input        RES_N,
  input [7:0]  DB_IN,

  // Data Bus (Output) Control
  input [2:0]  DB_OUT_SRC,

  // Data Latch Control
  input        DL_WE,

  // Instruction Register Control
  input        IR_WE,

  // Program Counter Control
  input [1:0]  PCADDER_CTRL,
  input [1:0]  PCL_SRC, // DL / T / PCLAdd
  input [0:0]  PCH_SRC, // DL / PCLAdd
  input        PCL_WE,
  input        PCH_WE,

  // Registers Control
  input [2:0]  REG_SRC, // DL / ALUout
  input        A_WE,
  input        X_WE,
  input        Y_WE,
  input        S_WE,
  input        T_WE,

  // Processor Status Register Control
  input [2:0]  P_SRC,
  input [7:0]  P_MASK,

  // ALU Control
  input [3:0]  ALU_CTRL,
  input [2:0]  ALU_SRC_A,
  input [1:0]  ALU_SRC_B,

  // Address Bus Control
  input [2:0]  ABL_SRC,
  input [2:0]  ABH_SRC,
  input        ABL_WE,
  input        ABH_WE,

  output [7:0] INSTR,
  output [8:0] FLAG,
  output [7:0] ABL,
  output [7:0] ABH,
  output [7:0] DB_OUT
);

`include "params.vh"

  wire [7:0] dl, a, x, y, s, t, p, pcl, pch;
  wire [7:0] pcl_add, pch_add, pcl_wd, pch_wd, reg_wd, p_alu, p_wd, abl_wd, abh_wd;
  wire [7:0] alu_src_a, alu_src_b, alu_out;

  // Instruction Register
  flopenr #(8'h00) ir_reg(.CLK(CLK), .RES_N(RES_N), .WE(IR_WE), .D(DB_IN), .Q(INSTR));

  // Data Latch
  flopenr #(8'h00) dl_reg(.CLK(CLK), .RES_N(RES_N), .WE(DL_WE), .D(DB_IN), .Q(dl));

  // Program Counter
  pcadder pcadder(.RES_N(res_n), .IL(pcl), .IH(pch), .SRC(DB_IN), .CTRL(PCADDER_CTRL), .OL(pcl_add), .OH(pch_add));

  mux4 pcl_mux(.D0(pcl_add), .D1(DB_IN), .D2(t), .S(PCL_SRC), .Y(pcl_wd));
  mux2 pch_mux(.D0(pch_add), .D1(DB_IN), .S(PCH_SRC), .Y(pch_wd));

  flopenr #(P_PCL_INIT) pcl_reg(.CLK(CLK), .RES_N(RES_N), .WE(PCL_WE), .D(pcl_wd), .Q(pcl));
  flopenr #(P_PCH_INIT) pch_reg(.CLK(CLK), .RES_N(RES_N), .WE(PCH_WE), .D(pch_wd), .Q(pch));

  // Registers
  mux8 reg_mux(.D0(a), .D1(x), .D2(y), .D3(s), .D4(t), .D5(p), .D6(DB_IN), .D7(alu_out), .S(REG_SRC), .Y(reg_wd));

  flopenr #(P_A_INIT) a_reg(.CLK(CLK), .RES_N(RES_N), .WE(A_WE), .D(reg_wd), .Q(a));
  flopenr #(P_X_INIT) x_reg(.CLK(CLK), .RES_N(RES_N), .WE(X_WE), .D(reg_wd), .Q(x));
  flopenr #(P_Y_INIT) y_reg(.CLK(CLK), .RES_N(RES_N), .WE(Y_WE), .D(reg_wd), .Q(y));
  flopenr #(P_S_INIT) s_reg(.CLK(CLK), .RES_N(RES_N), .WE(S_WE), .D(reg_wd), .Q(s));
  flopenr #(8'h00) t_reg(.CLK(CLK), .RES_N(RES_N), .WE(T_WE), .D(reg_wd), .Q(t));

  // Processor Status Register
  mux8 p_mux(.D0(t), .D1(DB_IN), .D2(p_alu), .D3(p | P_MASK), .D4(p & ~P_MASK), .D5(p), .S(P_SRC), .Y(p_wd));

  flopenr #(P_P_INIT) p_reg(.CLK(CLK), .RES_N(RES_N), .WE(1'b1), .D(p_wd), .Q(p));

  // ALU
  mux8 alu_src_a_mux(.D0(a), .D1(x), .D2(y), .D3(s), .D4(t), .D5(dl), .S(ALU_SRC_A), .Y(alu_src_a));
  mux4 alu_src_b_mux(.D0(dl), .D1(t), .D2(8'h00), .S(ALU_SRC_B), .Y(alu_src_b));

  alu alu(.A(alu_src_a), .B(alu_src_b), .FLAG_IN(p), .CTRL(ALU_CTRL), .OUT(alu_out), .FLAG_OUT(p_alu));

  // Address Bus
  mux8 abl_mux(.D0(pcl_wd), .D1(pcl), .D2(DB_IN), .D3(alu_out), .D4(s), .D5(t), .D6(8'hfe), .D7(8'hff), .S(ABL_SRC), .Y(abl_wd));
  mux8 abh_mux(.D0(pch_wd), .D1(pch), .D2(DB_IN), .D3(alu_out), .D4(8'h00), .D5(8'h01), .D6(8'hff), .S(ABH_SRC), .Y(abh_wd));

  flopenr #(P_ABL_INIT) abl_reg(.CLK(CLK), .RES_N(RES_N), .WE(ABL_WE), .D(abl_wd), .Q(ABL));
  flopenr #(P_ABH_INIT) abh_reg(.CLK(CLK), .RES_N(RES_N), .WE(ABH_WE), .D(abh_wd), .Q(ABH));

  // Data Bus
  mux8 db_mux(.D0(a), .D1(x), .D2(y), .D3(t), .D4(p), .D5(pcl), .D6(pch), .S(DB_OUT_SRC), .Y(DB_OUT));

  assign FLAG = (pcadder.carry << 8) | p;

endmodule


module flopenr #(
  parameter INIT = 8'h00
)(
  input CLK,
  input RES_N,
  input WE,
  input [7:0] D,
  output reg [7:0] Q
);

  always @(posedge CLK) begin
    if (!RES_N)
      Q <= INIT;
    else if (WE)
      Q <= D;
    else
      Q <= Q;
  end

endmodule


module mux2(
  input [7:0]  D0, D1,
  input        S,
  output [7:0] Y
);

  assign Y = S ? D1 : D0;

endmodule


module mux4(
  input [7:0]  D0, D1, D2, D3,
  input [1:0]  S,
  output [7:0] Y
);

  wire [7:0]   y0, y1;

  mux2 m0(D0, D1, S[0], y0);
  mux2 m1(D2, D3, S[0], y1);
  mux2 m2(y0, y1, S[1], Y);

endmodule


module mux8(
  input [7:0]  D0, D1, D2, D3, D4, D5, D6, D7,
  input [2:0]  S,
  output [7:0] Y
);

  wire [7:0]   y0, y1;

  mux4 m0(D0, D1, D2, D3, S[1:0], y0);
  mux4 m1(D4, D5, D6, D7, S[1:0], y1);
  mux2 m2(y0, y1, S[2], Y);

endmodule


module pcadder(
  input            RES_N,
  input [7:0]      IL,
  input [7:0]      IH,
  input [7:0]      SRC,
  input [1:0]      CTRL,
  output reg [7:0] OL,
  output reg [7:0] OH
);

`include "params.vh"

  reg carry;
  wire [7:0] dst;

  assign dst = IL + 1'b1 + SRC;

  always @* begin
    if (!RES_N)
      carry <= 1'b0;
    if (CTRL == C_PCADDER_CTRL_INC) begin
      if (IL == 8'hff) begin
        OL <= 8'h00;
        if (IH == 8'hff)
          OH <= 8'h00;
        else
          OH <= IH + 1'b1;
      end else begin
        OL <= IL + 1'b1;
        OH <= IH;
      end
      carry <= carry;
    end else if (CTRL == C_PCADDER_CTRL_ADD) begin
      OL <= dst & 8'hff;
      OH <= IH;
      if ((SRC & 8'h80) == 0)
        carry <= dst > 8'hff;
      else
        carry <= carry;
    end else if (CTRL == C_PCADDER_CTRL_CADD) begin
      OL <= IL;
      OH <= carry;
      carry <= 0;
    end else begin
      OL <= IL;
      OH <= IH;
      carry <= carry;
    end
  end

endmodule
