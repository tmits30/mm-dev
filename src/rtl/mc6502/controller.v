module controller(
  input            CLK,
  input            RES_N,
  input            RDY,

  input [7:0]      INSTR,
  input [8:0]      FLAG, // MSB is Program Counter Carray Flag

  // Read/Write
  output reg       R_W,

  // Data Bus (Output Reg) Control
  output reg [2:0] DB_OUT_SRC,

  // Data Latch Control
  output reg       DL_WE,

  // Instruction Register Control
  output reg       IR_WE,

  // Program Counter Control
  output reg [1:0] PCADDER_CTRL,
  output reg [1:0] PCL_SRC, // DL / T / PCLAdd
  output reg [0:0] PCH_SRC, // DL / PCLAdd
  output reg       PCL_WE,
  output reg       PCH_WE,

  // Registers Control
  output reg [1:0] REG_SRC, // DL / ALUout
  output reg       A_WE,
  output reg       X_WE,
  output reg       Y_WE,
  output reg       S_WE,
  output reg       T_WE,

  // Processor Status Register Control
  output reg [2:0] P_SRC,
  output reg [7:0] P_MASK,

  // ALU Control
  output reg [3:0] ALU_CTRL,
  output reg [2:0] ALU_SRC_A,
  output reg [1:0] ALU_SRC_B,

  // Address Bus Control
  output reg [2:0] ABL_SRC,
  output reg [2:0] ABH_SRC,
  output reg       ABL_WE,
  output reg       ABH_WE
);

`include "params.vh"

  //
  // Decode instruction
  //
  wire [5:0] op;
  wire [3:0] addr_mode;

  decorder decoder(.INSTR(INSTR), .OP(op), .ADDR_MODE(addr_mode));

  //
  // Special Operation
  //
  wire is_ldr_op, is_str_op, is_plr_op, is_tsd_op, is_rmw_op, is_set_op, is_clr_op, is_branch;
  wire [7:0] flag_mask;

  // Load Operations
  assign is_ldr_op = (op == C_OP_LDA) | (op == C_OP_LDX) | (op == C_OP_LDY);

  // Store Operations
  assign is_str_op = (op == C_OP_STA) | (op == C_OP_STX) | (op == C_OP_STY);

  // Pull Operations
  assign is_plr_op = (op == C_OP_PLA) | (op == C_OP_PLP);

  // Transfer Operations
  assign is_tsd_op = (op == C_OP_TAX) | (op == C_OP_TAY) | (op == C_OP_TSX) |
                     (op == C_OP_TXA) | (op == C_OP_TXS) | (op == C_OP_TYA);

  // Read-Modify-Write Operations
  assign is_rmw_op = (op == C_OP_ASL) | (op == C_OP_DEC) | (op == C_OP_INC) |
                     (op == C_OP_LSR) | (op == C_OP_ROL) | (op == C_OP_ROR);

  // Set Flag Operations
  assign is_set_op = (op == C_OP_SEC) | (op == C_OP_SED) | (op == C_OP_SEI);

  // Clear Flag Operations
  assign is_clr_op = (op == C_OP_CLC) | (op == C_OP_CLD) | (op == C_OP_CLI) | (op == C_OP_CLV);

  // Target for Flag Operations
  assign flag_mask = ((op == C_OP_CLC) || (op == C_OP_SEC)) ? C_FLAG_MASK_C :
                     ((op == C_OP_CLD) || (op == C_OP_SED)) ? C_FLAG_MASK_D :
                     ((op == C_OP_CLI) || (op == C_OP_SEI)) ? C_FLAG_MASK_I :
                     ((op == C_OP_CLI)) ? C_FLAG_MASK_V : 8'h00;

  // Is branch?
  assign is_branch = ((op == C_OP_BCC) && !(FLAG & C_FLAG_MASK_C)) ||
                     ((op == C_OP_BCS) &&  (FLAG & C_FLAG_MASK_C)) ||
                     ((op == C_OP_BNE) && !(FLAG & C_FLAG_MASK_Z)) ||
                     ((op == C_OP_BEQ) &&  (FLAG & C_FLAG_MASK_Z)) ||
                     ((op == C_OP_BVC) && !(FLAG & C_FLAG_MASK_V)) ||
                     ((op == C_OP_BVS) &&  (FLAG & C_FLAG_MASK_V)) ||
                     ((op == C_OP_BPL) && !(FLAG & C_FLAG_MASK_N)) ||
                     ((op == C_OP_BMI) &&  (FLAG & C_FLAG_MASK_N));

  //
  // ALU Execution
  //
  wire [7:0] exe_src_a_mem;
  wire [3:0] exe_dst_a_mem;

  assign exe_src_a_mem = (addr_mode == C_ADDR_MODE_ACC) ? C_ALU_SRC_A_A : C_ALU_SRC_A_MEM;
  assign exe_dst_a_mem = (addr_mode == C_ADDR_MODE_ACC) ? C_ALU_DST_A : C_ALU_DST_MEM;

  wire [3:0] exe_ctrl;
  wire [2:0] exe_src_a;
  wire [1:0] exe_src_b;
  wire [2:0] exe_dst;

  assign exe_src_b = C_ALU_SRC_B_T;
  assign {exe_ctrl, exe_src_a, exe_dst} =
      (op == C_OP_LDA) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_T, C_ALU_DST_A} :
      (op == C_OP_LDX) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_T, C_ALU_DST_X} :
      (op == C_OP_LDY) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_T, C_ALU_DST_Y} :
      (op == C_OP_PLA) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_T, C_ALU_DST_A} :
      (op == C_OP_PLP) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_T, C_ALU_DST_P} :
      (op == C_OP_TAX) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_A, C_ALU_DST_X} :
      (op == C_OP_TAY) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_A, C_ALU_DST_Y} :
      (op == C_OP_TSX) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_S, C_ALU_DST_X} :
      (op == C_OP_TXA) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_X, C_ALU_DST_A} :
      (op == C_OP_TXS) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_X, C_ALU_DST_S} :
      (op == C_OP_TYA) ? {C_ALU_CTRL_THA, C_ALU_SRC_A_Y, C_ALU_DST_A} :
      (op == C_OP_ADC) ? {C_ALU_CTRL_ADC, C_ALU_SRC_A_A, C_ALU_DST_A} :
      (op == C_OP_AND) ? {C_ALU_CTRL_AND, C_ALU_SRC_A_A, C_ALU_DST_A} :
      (op == C_OP_ASL) ? {C_ALU_CTRL_ASL, exe_src_a_mem, exe_dst_a_mem} :
      (op == C_OP_BIT) ? {C_ALU_CTRL_BIT, C_ALU_SRC_A_A, C_ALU_DST_A} :
      (op == C_OP_CMP) ? {C_ALU_CTRL_CMP, C_ALU_SRC_A_A, C_ALU_DST_A} :
      (op == C_OP_CPX) ? {C_ALU_CTRL_CMP, C_ALU_SRC_A_X, C_ALU_DST_X} :
      (op == C_OP_CPY) ? {C_ALU_CTRL_CMP, C_ALU_SRC_A_Y, C_ALU_DST_Y} :
      (op == C_OP_DEC) ? {C_ALU_CTRL_DEC, C_ALU_SRC_A_T, C_ALU_DST_T} :
      (op == C_OP_DEX) ? {C_ALU_CTRL_DEC, C_ALU_SRC_A_X, C_ALU_DST_X} :
      (op == C_OP_DEY) ? {C_ALU_CTRL_DEC, C_ALU_SRC_A_Y, C_ALU_DST_Y} :
      (op == C_OP_EOR) ? {C_ALU_CTRL_EOR, C_ALU_SRC_A_A, C_ALU_DST_A} :
      (op == C_OP_INC) ? {C_ALU_CTRL_INC, C_ALU_SRC_A_T, C_ALU_DST_T} :
      (op == C_OP_INX) ? {C_ALU_CTRL_INC, C_ALU_SRC_A_X, C_ALU_DST_X} :
      (op == C_OP_INY) ? {C_ALU_CTRL_INC, C_ALU_SRC_A_Y, C_ALU_DST_Y} :
      (op == C_OP_LSR) ? {C_ALU_CTRL_LSR, exe_src_a_mem, exe_dst_a_mem} :
      (op == C_OP_ORA) ? {C_ALU_CTRL_ORA, C_ALU_SRC_A_A, C_ALU_DST_A} :
      (op == C_OP_ROL) ? {C_ALU_CTRL_ROL, exe_src_a_mem, exe_dst_a_mem} :
      (op == C_OP_ROR) ? {C_ALU_CTRL_ROR, exe_src_a_mem, exe_dst_a_mem} :
      (op == C_OP_SBC) ? {C_ALU_CTRL_SBC, C_ALU_SRC_A_A, C_ALU_DST_A} : 10'b0;

  //
  // Current/Next State
  //
  reg [5:0] cur_state, nxt_state;

  always @(posedge CLK) begin
    if (!RES_N)
      cur_state <= C_STATE_T0_R_OPCO;
    else if (RDY)
      cur_state <= nxt_state;
    else
      cur_state <= cur_state;
  end

  always @(*) begin
    case (cur_state)
      C_STATE_T0_R_OPCO: nxt_state = C_STATE_T1_R_OPER;
      C_STATE_T1_R_OPER:
        case (addr_mode)
          C_ADDR_MODE_ACC: nxt_state = C_STATE_T0_R_OPCO;
          C_ADDR_MODE_IMM: nxt_state = C_STATE_T0_R_OPCO;
          C_ADDR_MODE_ABS: nxt_state = C_STATE_T2_ABS_AM;
          C_ADDR_MODE_ABX: nxt_state = C_STATE_T2_ABR_AM;
          C_ADDR_MODE_ABY: nxt_state = C_STATE_T2_ABR_AM;
          C_ADDR_MODE_IND: nxt_state = C_STATE_T2_IND_AM;
          C_ADDR_MODE_INX: nxt_state = C_STATE_T2_INX_AM;
          C_ADDR_MODE_INY: nxt_state = C_STATE_T2_INY_AM;
          C_ADDR_MODE_ZPG:
            if (is_str_op)
              nxt_state = C_STATE_TX_W_DATA;
            else
              nxt_state = C_STATE_TX_R_DATA;
          C_ADDR_MODE_ZPX: nxt_state = C_STATE_T2_ZPR_AM;
          C_ADDR_MODE_ZPY: nxt_state = C_STATE_T2_ZPR_AM;
          C_ADDR_MODE_REL:
            if (is_branch)
              nxt_state = C_STATE_T2_REL_AM;
            else
              nxt_state = C_STATE_TX_R_DATA;
          C_ADDR_MODE_IMP:
            case (op)
              C_OP_BRK: nxt_state = C_STATE_T2_BRK_OP;
              C_OP_PLA: nxt_state = C_STATE_T2_PLR_OP;
              C_OP_PLP: nxt_state = C_STATE_T2_PLR_OP;
              C_OP_PHA: nxt_state = C_STATE_T2_PHR_OP;
              C_OP_PHP: nxt_state = C_STATE_T2_PHR_OP;
              C_OP_RTI: nxt_state = C_STATE_T2_RTI_OP;
              C_OP_RTS: nxt_state = C_STATE_T2_RTS_OP;
              default:  nxt_state = C_STATE_T0_R_OPCO;
            endcase
          default: nxt_state = C_STATE_T0_R_OPCO;
        endcase
      C_STATE_TX_R_DATB:
        if (is_rmw_op || FLAG & C_FLAG_MASK_C)
          nxt_state = C_STATE_TX_R_DATA;
        else if (is_str_op)
          nxt_state = C_STATE_TX_W_DATA;
        else
          nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_TX_R_DATA:
        if (is_rmw_op)
          nxt_state = C_STATE_TX_M_DATA;
        else
          nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_TX_M_DATA: nxt_state = C_STATE_TX_W_DATA;
      C_STATE_TX_W_DATA: nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_T2_ABS_AM:
        if (op == C_OP_JMP)
          nxt_state = C_STATE_T0_R_OPCO;
        else if (op == C_OP_JSR)
          nxt_state = C_STATE_T3_JSR_OP;
        else if (is_str_op)
          nxt_state = C_STATE_TX_W_DATA;
        else
          nxt_state = C_STATE_TX_R_DATA;
      C_STATE_T3_JSR_OP: nxt_state = C_STATE_T4_JSR_OP;
      C_STATE_T4_JSR_OP: nxt_state = C_STATE_T5_JSR_OP;
      C_STATE_T5_JSR_OP: nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_T2_ABR_AM: nxt_state = C_STATE_TX_R_DATB;
      C_STATE_T2_IND_AM: nxt_state = C_STATE_T3_IND_AM;
      C_STATE_T3_IND_AM: nxt_state = C_STATE_T4_IND_AM;
      C_STATE_T4_IND_AM: nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_T2_INX_AM: nxt_state = C_STATE_T3_INX_AM;
      C_STATE_T3_INX_AM: nxt_state = C_STATE_T4_INX_AM;
      C_STATE_T4_INX_AM:
        if (is_str_op)
          nxt_state = C_STATE_TX_W_DATA;
        else
          nxt_state = C_STATE_TX_R_DATA;
      C_STATE_T2_INY_AM: nxt_state = C_STATE_T3_INY_AM;
      C_STATE_T3_INY_AM: nxt_state = C_STATE_TX_R_DATB;
      C_STATE_T2_REL_AM:
        if (FLAG & C_FLAG_MASK_PCC)
          nxt_state = C_STATE_T3_REL_AM;
        else
          nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_T3_REL_AM: nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_T2_ZPR_AM:
        if (is_str_op)
          nxt_state = C_STATE_TX_W_DATA;
        else
          nxt_state = C_STATE_TX_R_DATA;
      C_STATE_T2_BRK_OP: nxt_state = C_STATE_T3_BRK_OP;
      C_STATE_T3_BRK_OP: nxt_state = C_STATE_T4_BRK_OP;
      C_STATE_T4_BRK_OP: nxt_state = C_STATE_T5_BRK_OP;
      C_STATE_T5_BRK_OP: nxt_state = C_STATE_T6_BRK_OP;
      C_STATE_T6_BRK_OP: nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_T2_PLR_OP: nxt_state = C_STATE_TX_R_DATA;
      C_STATE_T2_PHR_OP: nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_T2_RTI_OP: nxt_state = C_STATE_T3_RTI_OP;
      C_STATE_T3_RTI_OP: nxt_state = C_STATE_T4_RTI_OP;
      C_STATE_T4_RTI_OP: nxt_state = C_STATE_T5_RTI_OP;
      C_STATE_T5_RTI_OP: nxt_state = C_STATE_T0_R_OPCO;
      C_STATE_T2_RTS_OP: nxt_state = C_STATE_T3_RTS_OP;
      C_STATE_T3_RTS_OP: nxt_state = C_STATE_T4_RTS_OP;
      C_STATE_T4_RTS_OP: nxt_state = C_STATE_T5_RTS_OP;
      C_STATE_T5_RTS_OP: nxt_state = C_STATE_T0_R_OPCO;
      default: nxt_state = 6'hxx; // unknown state
    endcase
  end

  //
  // Output Controll Signals
  //
  always @(*) begin
    R_W = C_RW_R;
    DB_OUT_SRC = C_DB_OUT_SRC_A;

    DL_WE = 1'b0;
    IR_WE = 1'b0;

    PCADDER_CTRL = C_PCADDER_CTRL_NOP;
    PCL_SRC = C_PCL_SRC_MEM;
    PCH_SRC = C_PCH_SRC_MEM;
    PCL_WE = 1'b0;
    PCH_WE = 1'b0;

    REG_SRC = C_REG_SRC_MEM;
    A_WE = 1'b0;
    X_WE = 1'b0;
    Y_WE = 1'b0;
    S_WE = 1'b0;
    T_WE = 1'b0;

    P_SRC = C_P_SRC_ALU;
    P_MASK = 8'h00;

    ALU_CTRL = C_ALU_CTRL_THA;
    ALU_SRC_A = C_ALU_SRC_A_A; // default: A
    ALU_SRC_B = C_ALU_SRC_B_T; // default: t

    ABL_SRC = C_ABL_SRC_PCN;
    ABH_SRC = C_ABH_SRC_PCN;
    ABL_WE = 1'b0;
    ABH_WE = 1'b0;

    case (cur_state)
      C_STATE_T0_R_OPCO: begin
        // Instruction Register
        IR_WE = 1'b1;

        // Program Counter
        PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Execute
        ALU_SRC_A = exe_src_a;
        ALU_SRC_B = exe_src_b;
        ALU_CTRL = exe_ctrl;

        // Store ALUOut
        A_WE = exe_dst == C_ALU_DST_A;
        X_WE = exe_dst == C_ALU_DST_X;
        Y_WE = exe_dst == C_ALU_DST_Y;
        S_WE = exe_dst == C_ALU_DST_S;
        REG_SRC = C_REG_SRC_ALU;

        // Change Processor Status Register
        P_MASK = flag_mask;
        if (exe_dst == C_ALU_DST_P)
          P_SRC = C_P_SRC_ALU;
        else if (is_set_op)
          P_SRC = C_P_SRC_SET;
        else if (is_clr_op)
          P_SRC = C_P_SRC_CLR;
        else
          P_SRC = C_P_SRC_NON;

        // Address Bus PC (fetch data from the address at next cycle)
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T1_R_OPER: begin
        // Program Counter
        if (addr_mode == C_ADDR_MODE_IMP)
          PCADDER_CTRL = C_PCADDER_CTRL_NOP;
        else if (addr_mode == C_ADDR_MODE_REL && is_branch)
          PCADDER_CTRL = C_PCADDER_CTRL_ADD;
        else
          PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Input Data latch
        DL_WE = 1'b1;

        // Temporary Reigister
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
        if (addr_mode == C_ADDR_MODE_INX ||
            addr_mode == C_ADDR_MODE_INY ||
            addr_mode == C_ADDR_MODE_ZPG ||
            addr_mode == C_ADDR_MODE_ZPX ||
            addr_mode == C_ADDR_MODE_ZPY) begin
          ABL_SRC = C_ABL_SRC_MEM;
          ABH_SRC = C_ABH_SRC_H00;
        end else if (op == C_OP_PHA || op == C_OP_PHP ||
                     op == C_OP_PLA || op == C_OP_PLP ||
                     op == C_OP_JSR || op == C_OP_BRK ||
                     op == C_OP_RTI || op == C_OP_RTS) begin
          ABL_SRC = C_ABL_SRC_S;
          ABH_SRC = C_ABH_SRC_H01;
        end else begin
          ABL_SRC = C_ABL_SRC_PCN;
          ABH_SRC = C_ABH_SRC_PCN;
        end
      end
      C_STATE_TX_R_DATB: begin
        // Input Data latch
        DL_WE = 1'b1;

        // Execute ADH + C
        ALU_SRC_A = C_ALU_SRC_A_T;
        ALU_SRC_B = C_ALU_SRC_B_H00;
        ALU_CTRL = C_ALU_CTRL_ADC;

        // Temporary Register (Data)
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        if (FLAG & C_FLAG_MASK_C || is_rmw_op) begin
          // - ADH + C, ADL
          ABH_WE = 1'b1;
          ABH_SRC = C_ABH_SRC_ALU;
        end else if (is_str_op) begin
          ABL_WE = 1'b0;
          ABH_WE = 1'b0;
        end else begin
          ABL_WE = 1'b1;
          ABL_SRC = C_ABL_SRC_PCC;
          ABH_WE = 1'b1;
          ABH_SRC = C_ABH_SRC_PCC;
        end
      end
      C_STATE_TX_R_DATA: begin
        // Input Data latch
        DL_WE = 1'b1;

        // Temporary Register
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        if (!is_rmw_op) begin
          ABL_WE = 1'b1;
          ABL_SRC = C_ABL_SRC_PCC;
          ABH_WE = 1'b1;
          ABH_SRC = C_ABH_SRC_PCC;
        end
      end
      C_STATE_TX_M_DATA: begin
        R_W = C_RW_W;

        // Execute
        ALU_SRC_A = exe_src_a;
        ALU_SRC_B = exe_src_b;
        ALU_CTRL = exe_ctrl;

        // Temporary Register
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;
      end
      C_STATE_TX_W_DATA: begin
        // Data Bus
        R_W = C_RW_W;;
        if (op == C_OP_STA)
          DB_OUT_SRC = C_DB_OUT_SRC_A;
        else if (op == C_OP_STX)
          DB_OUT_SRC = C_DB_OUT_SRC_X;
        else if (op == C_OP_STY)
          DB_OUT_SRC = C_DB_OUT_SRC_Y;
        else
          DB_OUT_SRC = C_DB_OUT_SRC_T;

        // Address Bus (fetch data from the address at next cycle)
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_PCC;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_PCC;
      end
      C_STATE_T2_ABS_AM: begin
        // Input Data Latch (ADH)
        DL_WE = 1'b1;

        // Program Counter
        if (op == C_OP_JSR)
          PCADDER_CTRL = C_PCADDER_CTRL_NOP;
        else
          PCADDER_CTRL = C_PCADDER_CTRL_INC;
        if (op == C_OP_JMP) begin
          PCL_SRC = C_PCL_SRC_T;
          PCH_SRC = C_PCH_SRC_MEM;
        end else begin
          PCL_SRC = C_PCL_SRC_ADD;
          PCH_SRC = C_PCH_SRC_ADD;
        end
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (fetch data from the address at next cycle)
        if (op != C_OP_JSR) begin
          // - ADH, ADL
          ABL_WE = 1'b1;
          ABL_SRC = C_ABL_SRC_T;
          ABH_WE = 1'b1;
          ABH_SRC = C_ABH_SRC_MEM;
        end
      end
      C_STATE_T3_JSR_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_PCH;

        // Execute S - 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_DEC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, S - 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T4_JSR_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_PCL;

        // Execute (S - 1) - 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_DEC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - PC + 2
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_PCC;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_PCC;
      end
      C_STATE_T5_JSR_OP: begin
        // Input Data Latch (ADH)
        DL_WE = 1'b1;

        // Program Counter
        PCL_WE = 1'b1;
        PCL_SRC = C_PCL_SRC_T;
        PCH_WE = 1'b1;
        PCH_SRC = C_PCH_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - ADH, ADL
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_T;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_MEM;
      end
      C_STATE_T2_ABR_AM: begin
        // Program Counter
        PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Input Data Latch (BAH)
        DL_WE = 1'b1;

        // Execute BAL + index register
        if (addr_mode == C_ADDR_MODE_ABX)
          ALU_SRC_A = C_ALU_SRC_A_X;
        else
          ALU_SRC_A = C_ALU_SRC_A_Y;
        ALU_SRC_B = C_ALU_SRC_B_T;
        ALU_CTRL = C_ALU_CTRL_ADC;

        // Temporary Register (BAH) for 'Tx_fetch_data_c0'
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - BAH, BAL + index register
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_MEM;
      end
      C_STATE_T2_IND_AM: begin
        // Input Data Latch (IAH)
        DL_WE = 1'b1;

        // Program Counter
        PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (fetch data from the address at next cycle)
        // - IAH, IAL
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_T;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_MEM;
      end
      C_STATE_T3_IND_AM: begin
        // Input Data Latch (ADL)
        DL_WE = 1'b1;

        // Execute IAL + 1
        ALU_SRC_A = C_ALU_SRC_A_T;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Temporary Reigister (ADL)
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - IAH, IAL + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T4_IND_AM: begin
        // Input Data Latch (ADH)
        DL_WE = 1'b1;

        // Program Counter
        PCL_WE = 1'b1;
        PCL_SRC = C_PCL_SRC_T;
        PCH_WE = 1'b1;
        PCH_SRC = C_PCH_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - ADH, ADL
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_T;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_MEM;
      end
      C_STATE_T2_INX_AM: begin
        // Execute BAL + X
        ALU_SRC_A = C_ALU_SRC_A_X;
        ALU_SRC_B = C_ALU_SRC_B_MEM;
        ALU_CTRL = C_ALU_CTRL_ADC;

        // Temporary Register (BAL + X)
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 00, BAL + X
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T3_INX_AM: begin
        // Input Data Latch (ADL)
        DL_WE = 1'b1;

        // Execute (BAL + X) + 1
        ALU_SRC_A = C_ALU_SRC_A_T;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Temporary Register (ADL)
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - 00, BAL + X + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T4_INX_AM: begin
        // Input Data Latch (ADH)
        DL_WE = 1'b1;

        // Address Bus (fetch data from the address at next cycle)
        // - ADH, ADL
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_T;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_MEM;
      end
      C_STATE_T2_INY_AM: begin
        // Input Data Latch (BAL)
        DL_WE = 1'b1;

        // Execute IAL + 1
        ALU_SRC_A = C_ALU_SRC_A_T;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Temporary Register (BAL)
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - 00, IAL + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T3_INY_AM: begin
        // Input Data Latch (BAH)
        DL_WE = 1'b1;

        // Execute BAL + Y
        ALU_SRC_A = C_ALU_SRC_A_Y;
        ALU_SRC_B = C_ALU_SRC_B_T;
        ALU_CTRL = C_ALU_CTRL_ADC;

        // Temporary Register (BAH) for 'Tx_fetch_data_c0'
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - BAH, BAL + Y
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_MEM;
      end
      C_STATE_T2_REL_AM: begin
        // Program Counter Adder
        PCADDER_CTRL = C_PCADDER_CTRL_CADD;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (fetch data from the address at next cycle)
        // - PCH, (PCL + 2) + offset
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_PCN;
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_PCN;
      end
      C_STATE_T3_REL_AM: begin
      end
      C_STATE_T2_ZPR_AM: begin
        // Execute BAL + index register
        if (addr_mode == C_ADDR_MODE_ZPX)
          ALU_SRC_A = C_ALU_SRC_A_X;
        else
          ALU_SRC_A = C_ALU_SRC_A_Y;
        ALU_SRC_B = C_ALU_SRC_B_MEM;
        ALU_CTRL = C_ALU_CTRL_ADC;

        // Address Bus (fetch data from the address at next cycle)
        // - ADH, ADL
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T2_BRK_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_PCH;

        // Execute S - 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_DEC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, S - 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_H01;
      end
      C_STATE_T3_BRK_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_PCL;

        // Execute (S - 1) - 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_DEC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, (S - 1) - 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_H01;
      end
      C_STATE_T4_BRK_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_P;

        // Execute ((S - 1) - 1) - 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_DEC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - FF, FE
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_HFE;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_HFF;
      end
      C_STATE_T5_BRK_OP: begin
        // Input Data latch (ADL)
        DL_WE = 1'b1;

        // Temporary Register (ADL)
        T_WE = 1'b1;
        REG_SRC = C_REG_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - FF, FF
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_HFF;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_HFF;
      end
      C_STATE_T6_BRK_OP: begin
        // Input Data latch (ADH)
        DL_WE = 1'b1;

        // Program Counter
        PCL_WE = 1'b1;
        PCL_SRC = C_PCL_SRC_T;
        PCH_WE = 1'b1;
        PCH_SRC = C_PCH_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - ADH, ADL
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_T;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_MEM;
      end
      C_STATE_T2_PLR_OP: begin
        // Execute S + 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, S + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T2_PHR_OP: begin
        R_W = C_RW_W;
        if (op == C_OP_PHA)
          DB_OUT_SRC = C_DB_OUT_SRC_A;
        else
          DB_OUT_SRC = C_DB_OUT_SRC_P;

        // Input Data latch
        DL_WE = 1'b1;

        // Execute S - 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_DEC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, S + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_PCC;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_PCC;
      end
      C_STATE_T2_RTI_OP: begin
        // Execute S + 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, S + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T3_RTI_OP: begin
        // Input Data Latch (P)
        DL_WE = 1'b1;

        // Execute S + 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Processor Status Register
        P_SRC = C_P_SRC_MEM;

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, (S + 1) + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T4_RTI_OP: begin
        // Input Data Latch (PCL)
        DL_WE = 1'b1;

        // Execute S + 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Restore Program Counter
        PCL_WE = 1'b1;
        PCL_SRC = C_PCL_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, ((S + 1) + 1) + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T5_RTI_OP: begin
        // Input Data Latch (PCH)
        DL_WE = 1'b1;

        // Restore Program Counter
        PCH_WE = 1'b1;
        PCH_SRC = C_PCH_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, (((S + 1) + 1) + 1) + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_PCC; // MEM?
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_MEM;
      end
      C_STATE_T2_RTS_OP: begin
        // Execute S + 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, S + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T3_RTS_OP: begin
        // Input Data Latch (PCL)
        DL_WE = 1'b1;

        // Execute (S + 1) + 1
        ALU_SRC_A = C_ALU_SRC_A_S;
        ALU_CTRL = C_ALU_CTRL_INC;

        // Processor Status Register
        P_SRC = C_P_SRC_NON; // NOT from ALU

        // Update Stack Pointer
        S_WE = 1'b1;
        REG_SRC = C_REG_SRC_ALU;

        // Restore Program Counter
        PCL_WE = 1'b1;
        PCL_SRC = C_PCL_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - 0x01, (S + 1) + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_ALU;
      end
      C_STATE_T4_RTS_OP: begin
        // Input Data Latch (PCH)
        DL_WE = 1'b1;

        // Restore Program Counter
        PCH_WE = 1'b1;
        PCH_SRC = C_PCH_SRC_MEM;

        // Address Bus (fetch data from the address at next cycle)
        // - PCH, PCL
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_PCN;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_PCN;
      end
      C_STATE_T5_RTS_OP: begin
        // Program Counter
        PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (fetch data from the address at next cycle)
        // - PCH, PCL + 1
        ABL_WE = 1'b1;
        ABL_SRC = C_ABL_SRC_PCN;
        ABH_WE = 1'b1;
        ABH_SRC = C_ABH_SRC_PCN;
      end
    endcase
  end

endmodule
