module mpu(
  input        CLK,
  input        RES_N,
  input        RDY,
  input [7:0]  DB_IN,
  output       R_W,
  output [7:0] ABL,
  output [7:0] ABH,
  output [7:0] DB_OUT
);

  // Data Bus (Output) Control
  wire [2:0] db_out_src;

  // Instruction Register Control
  wire       ir_we;

  // Program Counter Control
  wire [1:0] pcadder_ctrl;
  wire [1:0] pcl_src;
  wire [0:0] pch_src;
  wire       pcl_we;
  wire       pch_we;

  // Registers Control
  wire [2:0] reg_src;
  wire       a_we;
  wire       x_we;
  wire       y_we;
  wire       s_we;
  wire       t_we;

  // Processor Status Register Control
  wire [2:0] p_src;
  wire [7:0] p_mask;

  // ALU Control
  wire [3:0] alu_ctrl;
  wire [2:0] alu_src_a;
  wire [0:0] alu_src_b;

  // Address Bus Control
  wire [2:0] abl_src;
  wire [2:0] abh_src;
  wire       abl_we;
  wire       abh_we;

  wire [7:0] instr;
  wire [8:0] flag;

  controller controller(
    .CLK          (CLK),
    .RES_N        (RES_N),
    .RDY          (RDY),
    .INSTR        (instr),
    .FLAG         (flag),
    .R_W          (R_W),
    .DB_OUT_SRC   (db_out_src),
    .IR_WE        (ir_we),
    .PCADDER_CTRL (pcadder_ctrl),
    .PCL_SRC      (pcl_src),
    .PCH_SRC      (pch_src),
    .PCL_WE       (pcl_we),
    .PCH_WE       (pch_we),
    .REG_SRC      (reg_src),
    .A_WE         (a_we),
    .X_WE         (x_we),
    .Y_WE         (y_we),
    .S_WE         (s_we),
    .T_WE         (t_we),
    .P_SRC        (p_src),
    .P_MASK       (p_mask),
    .ALU_CTRL     (alu_ctrl),
    .ALU_SRC_A    (alu_src_a),
    .ALU_SRC_B    (alu_src_b),
    .ABL_SRC      (abl_src),
    .ABH_SRC      (abh_src),
    .ABL_WE       (abl_we),
    .ABH_WE       (abh_we)
  );

  datapath datapath(
    .CLK          (CLK),
    .RES_N        (RES_N),
    .DB_IN        (DB_IN),
    .DB_OUT_SRC   (db_out_src),
    .IR_WE        (ir_we),
    .PCADDER_CTRL (pcadder_ctrl),
    .PCL_SRC      (pcl_src),
    .PCH_SRC      (pch_src),
    .PCL_WE       (pcl_we),
    .PCH_WE       (pch_we),
    .REG_SRC      (reg_src),
    .A_WE         (a_we),
    .X_WE         (x_we),
    .Y_WE         (y_we),
    .S_WE         (s_we),
    .T_WE         (t_we),
    .P_SRC        (p_src),
    .P_MASK       (p_mask),
    .ALU_CTRL     (alu_ctrl),
    .ALU_SRC_A    (alu_src_a),
    .ALU_SRC_B    (alu_src_b),
    .ABL_SRC      (abl_src),
    .ABH_SRC      (abh_src),
    .ABL_WE       (abl_we),
    .ABH_WE       (abh_we),
    .INSTR        (instr),
    .FLAG         (flag),
    .ABL          (ABL),
    .ABH          (ABH),
    .DB_OUT       (DB_OUT)
  );

endmodule
