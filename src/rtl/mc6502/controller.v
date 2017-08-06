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

  // Instruction Register Control
  output reg       IR_WE,

  // Program Counter Control
  output reg [1:0] PCADDER_CTRL,
  output reg [1:0] PCL_SRC,
  output reg [0:0] PCH_SRC,
  output reg       PCL_WE,
  output reg       PCH_WE,

  // Registers Control
  output reg [2:0] REG_SRC,
  output reg       A_WE,
  output reg       X_WE,
  output reg       Y_WE,
  output reg       S_WE,
  output reg       T_WE,

  // Processor Status Register Control
  output reg [2:0] P_SRC,
  output reg [7:0] P_MASK,
  output reg       P_WE,

  // ALU Control
  output reg [3:0] ALU_CTRL,
  output reg [2:0] ALU_SRC_A,
  output reg [0:0] ALU_SRC_B,

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
  wire is_ldr_op, is_str_op, is_plr_op, is_txr_op, is_rmw_op;
  wire is_set_op, is_clr_op; // flag set/clear

  // Load Operations
  assign is_ldr_op = (op == C_OP_LDA) | (op == C_OP_LDX) | (op == C_OP_LDY);

  // Store Operations
  assign is_str_op = (op == C_OP_STA) | (op == C_OP_STX) | (op == C_OP_STY);

  // Pull Operations
  assign is_plr_op = (op == C_OP_PLA) | (op == C_OP_PLP);

  // Transfer register-register Operations
  assign is_txr_op = (op == C_OP_TAX) | (op == C_OP_TAY) | (op == C_OP_TSX) |
                     (op == C_OP_TXA) | (op == C_OP_TXS) | (op == C_OP_TYA);

  // Read-Modify-Write Operations
  assign is_rmw_op = (op == C_OP_ASL) | (op == C_OP_DEC) | (op == C_OP_INC) |
                     (op == C_OP_LSR) | (op == C_OP_ROL) | (op == C_OP_ROR);

  // Set Flag Operations
  assign is_set_op = (op == C_OP_SEC) | (op == C_OP_SED) | (op == C_OP_SEI);

  // Clear Flag Operations
  assign is_clr_op = (op == C_OP_CLC) | (op == C_OP_CLD) | (op == C_OP_CLI) |
                     (op == C_OP_CLV);

  //
  // Target for Flag Operations
  //
  wire [7:0] flag_mask;

  assign flag_mask = flag_signal(op);

  function [7:0] flag_signal(input [5:0] OP);
    begin
      case (OP)
        C_OP_CLC: flag_signal = C_FLAG_MASK_C;
        C_OP_SEC: flag_signal = C_FLAG_MASK_C;
        C_OP_CLD: flag_signal = C_FLAG_MASK_D;
        C_OP_SED: flag_signal = C_FLAG_MASK_D;
        C_OP_CLI: flag_signal = C_FLAG_MASK_I;
        C_OP_SEI: flag_signal = C_FLAG_MASK_I;
        C_OP_CLV: flag_signal = C_FLAG_MASK_V;
        default:  flag_signal = 8'h00;
      endcase
    end
  endfunction

  //
  // Is branch?
  //
  wire is_branch;

  assign is_branch = ((op == C_OP_BCC) && !FLAG[C_FLAG_SHFT_C]) ||
                     ((op == C_OP_BCS) &&  FLAG[C_FLAG_SHFT_C]) ||
                     ((op == C_OP_BNE) && !FLAG[C_FLAG_SHFT_Z]) ||
                     ((op == C_OP_BEQ) &&  FLAG[C_FLAG_SHFT_Z]) ||
                     ((op == C_OP_BVC) && !FLAG[C_FLAG_SHFT_V]) ||
                     ((op == C_OP_BVS) &&  FLAG[C_FLAG_SHFT_V]) ||
                     ((op == C_OP_BPL) && !FLAG[C_FLAG_SHFT_N]) ||
                     ((op == C_OP_BMI) &&  FLAG[C_FLAG_SHFT_N]);

  //
  // Move Src-Dst Register
  //
  wire [2:0] mov_src, mov_dst;

  assign {mov_src, mov_dst} = mov_signal(op);

  function [5:0] mov_signal(input [5:0] OP);
    begin
      case (OP)
        C_OP_LDA: mov_signal = {C_REG_SRC_T, C_REG_DST_A};
        C_OP_LDX: mov_signal = {C_REG_SRC_T, C_REG_DST_X};
        C_OP_LDY: mov_signal = {C_REG_SRC_T, C_REG_DST_Y};
        C_OP_PLA: mov_signal = {C_REG_SRC_T, C_REG_DST_A};
        C_OP_PLP: mov_signal = {C_REG_SRC_T, C_REG_DST_P};
        C_OP_TAX: mov_signal = {C_REG_SRC_A, C_REG_DST_X};
        C_OP_TAY: mov_signal = {C_REG_SRC_A, C_REG_DST_Y};
        C_OP_TSX: mov_signal = {C_REG_SRC_S, C_REG_DST_X};
        C_OP_TXA: mov_signal = {C_REG_SRC_X, C_REG_DST_A};
        C_OP_TXS: mov_signal = {C_REG_SRC_X, C_REG_DST_S};
        C_OP_TYA: mov_signal = {C_REG_SRC_Y, C_REG_DST_A};
        default:  mov_signal = {C_REG_SRC_T, C_REG_DST_T};
      endcase
    end
  endfunction

  //
  // ALU Execution
  //
  wire [3:0] exe_ctrl;
  wire [2:0] exe_src_a;

  assign {exe_ctrl, exe_src_a} = exe_signal(op, addr_mode);

  function [6:0] exe_signal(input [5:0] OP, input [3:0] ADDR_MODE);
    begin
      if (ADDR_MODE == C_ADDR_MODE_ACC)
        case (OP)
          C_OP_ASL: exe_signal = {C_ALU_CTRL_ASL, C_ALU_SRC_A_A};
          C_OP_LSR: exe_signal = {C_ALU_CTRL_LSR, C_ALU_SRC_A_A};
          C_OP_ROL: exe_signal = {C_ALU_CTRL_ROL, C_ALU_SRC_A_A};
          C_OP_ROR: exe_signal = {C_ALU_CTRL_ROR, C_ALU_SRC_A_A};
          default:  exe_signal = {C_ALU_CTRL_THA, C_ALU_SRC_A_T};
        endcase
      else
        case (OP)
          C_OP_ADC: exe_signal = {C_ALU_CTRL_ADC, C_ALU_SRC_A_A};
          C_OP_AND: exe_signal = {C_ALU_CTRL_AND, C_ALU_SRC_A_A};
          C_OP_BIT: exe_signal = {C_ALU_CTRL_BIT, C_ALU_SRC_A_A};
          C_OP_CMP: exe_signal = {C_ALU_CTRL_CMP, C_ALU_SRC_A_A};
          C_OP_CPX: exe_signal = {C_ALU_CTRL_CMP, C_ALU_SRC_A_X};
          C_OP_CPY: exe_signal = {C_ALU_CTRL_CMP, C_ALU_SRC_A_Y};
          C_OP_DEX: exe_signal = {C_ALU_CTRL_DEC, C_ALU_SRC_A_X};
          C_OP_DEY: exe_signal = {C_ALU_CTRL_DEC, C_ALU_SRC_A_Y};
          C_OP_EOR: exe_signal = {C_ALU_CTRL_EOR, C_ALU_SRC_A_A};
          C_OP_INX: exe_signal = {C_ALU_CTRL_INC, C_ALU_SRC_A_X};
          C_OP_INY: exe_signal = {C_ALU_CTRL_INC, C_ALU_SRC_A_Y};
          C_OP_ORA: exe_signal = {C_ALU_CTRL_ORA, C_ALU_SRC_A_A};
          C_OP_SBC: exe_signal = {C_ALU_CTRL_SBC, C_ALU_SRC_A_A};
          C_OP_DEC: exe_signal = {C_ALU_CTRL_DEC, C_ALU_SRC_A_T};
          C_OP_INC: exe_signal = {C_ALU_CTRL_INC, C_ALU_SRC_A_T};
          C_OP_ASL: exe_signal = {C_ALU_CTRL_ASL, C_ALU_SRC_A_T};
          C_OP_LSR: exe_signal = {C_ALU_CTRL_LSR, C_ALU_SRC_A_T};
          C_OP_ROL: exe_signal = {C_ALU_CTRL_ROL, C_ALU_SRC_A_T};
          C_OP_ROR: exe_signal = {C_ALU_CTRL_ROR, C_ALU_SRC_A_T};
          default:  exe_signal = {C_ALU_CTRL_THA, C_ALU_SRC_A_T};
        endcase
    end
  endfunction

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
        if (is_rmw_op || FLAG[C_FLAG_SHFT_C])
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
        if (FLAG[C_FLAG_SHFT_PCC])
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
    // Data Bus
    R_W = C_RW_R;
    DB_OUT_SRC = C_DB_OUT_SRC_A;

    // Instruction Register
    IR_WE = 1'b0;

    // Execute
    ALU_CTRL = C_ALU_CTRL_THA;
    ALU_SRC_A = C_ALU_SRC_A_A;
    ALU_SRC_B = C_ALU_SRC_B_T;

    // Registers
    REG_SRC = C_REG_SRC_MEM;
    A_WE = 1'b0;
    X_WE = 1'b0;
    Y_WE = 1'b0;
    S_WE = 1'b0;
    T_WE = 1'b0;

    // Processor Status Register
    P_SRC = C_P_SRC_ALU;
    P_MASK = 8'h00;
    P_WE = 1'b1;

    // Program Counter
    PCADDER_CTRL = C_PCADDER_CTRL_NOP;
    PCL_SRC = C_PCL_SRC_MEM;
    PCH_SRC = C_PCH_SRC_MEM;
    PCL_WE = 1'b0;
    PCH_WE = 1'b0;

    // Address Bus
    ABL_SRC = C_ABL_SRC_PCN;
    ABH_SRC = C_ABH_SRC_PCN;
    ABL_WE = 1'b0;
    ABH_WE = 1'b0;

    case (cur_state)
      C_STATE_T0_R_OPCO: begin
        // Instruction Register
        IR_WE = 1'b1;

        // Execute
        ALU_CTRL = exe_ctrl;
        ALU_SRC_A = exe_src_a;

        if (is_txr_op | is_ldr_op | is_plr_op) begin
          REG_SRC = mov_src;
          A_WE = mov_dst == C_REG_DST_A;
          X_WE = mov_dst == C_REG_DST_X;
          Y_WE = mov_dst == C_REG_DST_Y;
          S_WE = mov_dst == C_REG_DST_S;
        end else begin
          REG_SRC = C_REG_SRC_ALU;
          A_WE = exe_src_a == C_ALU_SRC_A_A;
          X_WE = exe_src_a == C_ALU_SRC_A_X;
          Y_WE = exe_src_a == C_ALU_SRC_A_Y;
          S_WE = exe_src_a == C_ALU_SRC_A_S;
        end

        // Change Processor Status Register
        P_MASK = flag_mask;
        if (mov_dst == C_REG_DST_P)
          P_SRC = C_P_SRC_T; // PLP only
        else if (is_set_op)
          P_SRC = C_P_SRC_SET;
        else if (is_clr_op)
          P_SRC = C_P_SRC_CLR;
        else if (is_rmw_op)
          P_WE = 1'b0;
        else if (exe_ctrl != C_ALU_CTRL_THA)
          P_SRC = C_P_SRC_ALU;
        else
          P_WE = 1'b0;

        // Program Counter
        PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (PC)
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T1_R_OPER: begin
        // Temporary Reigister
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Program Counter
        if (addr_mode == C_ADDR_MODE_IMP)
          PCADDER_CTRL = C_PCADDER_CTRL_NOP;
        else if (addr_mode == C_ADDR_MODE_REL && is_branch)
          PCADDER_CTRL = C_PCADDER_CTRL_ADD;
        else
          PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        if (addr_mode != C_ADDR_MODE_ACC) begin
          PCL_WE = 1'b1;
          PCH_WE = 1'b1;
        end

        // Address Bus
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
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_TX_R_DATB: begin
        // Execute ADH + C
        ALU_CTRL = C_ALU_CTRL_ADC;
        ALU_SRC_A = C_ALU_SRC_A_T;
        ALU_SRC_B = C_ALU_SRC_B_H00;

        // Temporary Register (Data)
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Address Bus
        if (FLAG[C_FLAG_SHFT_C] || is_rmw_op) begin
          // ADH + C, ADL
          ABH_SRC = C_ABH_SRC_ALU;
          ABH_WE = 1'b1;
        end else if (is_str_op) begin
          ABL_WE = 1'b0;
          ABH_WE = 1'b0;
        end else begin
          // PC
          ABL_SRC = C_ABL_SRC_PCC;
          ABH_SRC = C_ABH_SRC_PCC;
          ABL_WE = 1'b1;
          ABH_WE = 1'b1;
        end
      end
      C_STATE_TX_R_DATA: begin
        // Temporary Register
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Address Bus
        if (!is_rmw_op) begin
          ABL_SRC = C_ABL_SRC_PCC;
          ABH_SRC = C_ABH_SRC_PCC;
          ABL_WE = 1'b1;
          ABH_WE = 1'b1;
        end
      end
      C_STATE_TX_M_DATA: begin
        // Data Bus
        R_W = C_RW_W;

        // Execute
        ALU_CTRL = exe_ctrl;
        ALU_SRC_A = exe_src_a;

        // Temporary Register
        REG_SRC = C_REG_SRC_ALU;
        T_WE = 1'b1;
      end
      C_STATE_TX_W_DATA: begin
        // Data Bus
        R_W = C_RW_W;
        if (op == C_OP_STA)
          DB_OUT_SRC = C_DB_OUT_SRC_A;
        else if (op == C_OP_STX)
          DB_OUT_SRC = C_DB_OUT_SRC_X;
        else if (op == C_OP_STY)
          DB_OUT_SRC = C_DB_OUT_SRC_Y;
        else
          DB_OUT_SRC = C_DB_OUT_SRC_T;

        // Address Bus
        ABL_SRC = C_ABL_SRC_PCC;
        ABH_SRC = C_ABH_SRC_PCC;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_ABS_AM: begin
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

        // Address Bus (ADH, ADL)
        if (op != C_OP_JSR) begin
          ABL_SRC = C_ABL_SRC_T;
          ABH_SRC = C_ABH_SRC_MEM;
          ABL_WE = 1'b1;
          ABH_WE = 1'b1;
        end
      end
      C_STATE_T3_JSR_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_PCH;

        // Execute S - 1
        ALU_CTRL = C_ALU_CTRL_DEC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Processor Status Register
        P_WE = 1'b0;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Address Bus (0x01, S - 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T4_JSR_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_PCL;

        // Execute (S - 1) - 1
        ALU_CTRL = C_ALU_CTRL_DEC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Processor Status Register
        P_WE = 1'b0;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Address Bus (PC + 2)
        ABL_SRC = C_ABL_SRC_PCC;
        ABH_SRC = C_ABH_SRC_PCC;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T5_JSR_OP: begin
        // Program Counter
        PCL_SRC = C_PCL_SRC_T;
        PCH_SRC = C_PCH_SRC_MEM;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (ADH, ADL)
        ABL_SRC = C_ABL_SRC_T;
        ABH_SRC = C_ABH_SRC_MEM;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_ABR_AM: begin
        // Execute BAL + index register
        ALU_CTRL = C_ALU_CTRL_ADC;
        if (addr_mode == C_ADDR_MODE_ABX)
          ALU_SRC_A = C_ALU_SRC_A_X;
        else
          ALU_SRC_A = C_ALU_SRC_A_Y;

        // Temporary Register (BAH) for C_STATE_TX_R_DATB
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Program Counter
        PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (BAH, BAL + index register)
        ABL_SRC = C_ABL_SRC_ALU;
        ABH_SRC = C_ABH_SRC_MEM;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_IND_AM: begin
        // Program Counter
        PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (IAH, IAL)
        ABL_SRC = C_ABL_SRC_T;
        ABH_SRC = C_ABH_SRC_MEM;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T3_IND_AM: begin
        // Execute IAL + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_T;

        // Temporary Reigister (ADL)
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Address Bus (IAH, IAL + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T4_IND_AM: begin
        // Program Counter
        PCL_SRC = C_PCL_SRC_T;
        PCH_SRC = C_PCH_SRC_MEM;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (ADH, ADL)
        ABL_SRC = C_ABL_SRC_T;
        ABH_SRC = C_ABH_SRC_MEM;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_INX_AM: begin
        // Execute BAL + X
        ALU_CTRL = C_ALU_CTRL_ADC;
        ALU_SRC_A = C_ALU_SRC_A_X;

        // Temporary Register (BAL + X)
        REG_SRC = C_REG_SRC_ALU;
        T_WE = 1'b1;

        // Address Bus (00, BAL + X)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T3_INX_AM: begin
        // Execute (BAL + X) + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_T;

        // Temporary Register (ADL)
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Address Bus (00, BAL + X + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T4_INX_AM: begin
        // Address Bus (ADH, ADL)
        ABL_SRC = C_ABL_SRC_T;
        ABH_SRC = C_ABH_SRC_MEM;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_INY_AM: begin
        // Execute IAL + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_T;

        // Temporary Register (BAL)
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Address Bus (00, IAL + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T3_INY_AM: begin
        // Execute BAL + Y
        ALU_CTRL = C_ALU_CTRL_ADC;
        ALU_SRC_A = C_ALU_SRC_A_Y;

        // Temporary Register (BAH) for C_STATE_TX_F_DATB
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Address Bus (BAH, BAL + Y)
        ABL_SRC = C_ABL_SRC_ALU;
        ABH_SRC = C_ABH_SRC_MEM;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_REL_AM: begin
        // Program Counter Adder
        PCADDER_CTRL = C_PCADDER_CTRL_CADD;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (PCH, (PCL + 2) + offset)
        ABL_SRC = C_ABL_SRC_PCN;
        ABH_SRC = C_ABH_SRC_PCN;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T3_REL_AM: begin
      end
      C_STATE_T2_ZPR_AM: begin
        // Execute BAL + index register
        ALU_CTRL = C_ALU_CTRL_ADC;
        if (addr_mode == C_ADDR_MODE_ZPX)
          ALU_SRC_A = C_ALU_SRC_A_X;
        else
          ALU_SRC_A = C_ALU_SRC_A_Y;

        // Address Bus (ADH, ADL)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T2_BRK_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_PCH;

        // Execute S - 1
        ALU_CTRL = C_ALU_CTRL_DEC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Address Bus (0x01, S - 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABH_SRC = C_ABH_SRC_H01;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T3_BRK_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_PCL;

        // Execute (S - 1) - 1
        ALU_CTRL = C_ALU_CTRL_DEC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Address Bus (0x01, (S - 1) - 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABH_SRC = C_ABH_SRC_H01;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T4_BRK_OP: begin
        // Data Bus
        R_W = C_RW_W;
        DB_OUT_SRC = C_DB_OUT_SRC_P;

        // Execute ((S - 1) - 1) - 1
        ALU_CTRL = C_ALU_CTRL_DEC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Address Bus (FF, FE)
        ABL_SRC = C_ABL_SRC_HFE;
        ABH_SRC = C_ABH_SRC_HFF;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T5_BRK_OP: begin
        // Temporary Register (ADL)
        REG_SRC = C_REG_SRC_MEM;
        T_WE = 1'b1;

        // Address Bus (FF, FF)
        ABL_SRC = C_ABL_SRC_HFF;
        ABH_SRC = C_ABH_SRC_HFF;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T6_BRK_OP: begin
        // Program Counter
        PCL_SRC = C_PCL_SRC_T;
        PCH_SRC = C_PCH_SRC_MEM;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (ADH, ADL)
        ABL_SRC = C_ABL_SRC_T;
        ABH_SRC = C_ABH_SRC_MEM;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_PLR_OP: begin
        // Execute S + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Address Bus (0x01, S + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T2_PHR_OP: begin
        // Data Bus
        R_W = C_RW_W;
        if (op == C_OP_PHA)
          DB_OUT_SRC = C_DB_OUT_SRC_A;
        else
          DB_OUT_SRC = C_DB_OUT_SRC_P;

        // Execute S - 1
        ALU_CTRL = C_ALU_CTRL_DEC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Address Bus (0x01, S + 1)
        ABL_SRC = C_ABL_SRC_PCC;
        ABH_SRC = C_ABH_SRC_PCC;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_RTI_OP: begin
        // Execute S + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Address Bus (0x01, S + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T3_RTI_OP: begin
        // Execute S + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_SRC = C_P_SRC_MEM;

        // Address Bus (0x01, (S + 1) + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T4_RTI_OP: begin
        // Execute S + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Restore Program Counter
        PCL_SRC = C_PCL_SRC_MEM;
        PCL_WE = 1'b1;

        // Address Bus (0x01, ((S + 1) + 1) + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T5_RTI_OP: begin
        // Restore Program Counter
        PCH_SRC = C_PCH_SRC_MEM;
        PCH_WE = 1'b1;

        // Address Bus (0x01, (((S + 1) + 1) + 1) + 1)
        ABL_SRC = C_ABL_SRC_PCC;
        ABH_SRC = C_ABH_SRC_MEM;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T2_RTS_OP: begin
        // Execute S + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Address Bus (0x01, S + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T3_RTS_OP: begin
        // Execute (S + 1) + 1
        ALU_CTRL = C_ALU_CTRL_INC;
        ALU_SRC_A = C_ALU_SRC_A_S;

        // Update Stack Pointer
        REG_SRC = C_REG_SRC_ALU;
        S_WE = 1'b1;

        // Processor Status Register
        P_WE = 1'b0;

        // Restore Program Counter
        PCL_SRC = C_PCL_SRC_MEM;
        PCL_WE = 1'b1;

        // Address Bus (0x01, (S + 1) + 1)
        ABL_SRC = C_ABL_SRC_ALU;
        ABL_WE = 1'b1;
      end
      C_STATE_T4_RTS_OP: begin
        // Restore Program Counter
        PCH_SRC = C_PCH_SRC_MEM;
        PCH_WE = 1'b1;

        // Address Bus (PCH, PCL)
        ABL_SRC = C_ABL_SRC_PCN;
        ABH_SRC = C_ABH_SRC_PCN;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      C_STATE_T5_RTS_OP: begin
        // Program Counter
        PCADDER_CTRL = C_PCADDER_CTRL_INC;
        PCL_SRC = C_PCL_SRC_ADD;
        PCH_SRC = C_PCH_SRC_ADD;
        PCL_WE = 1'b1;
        PCH_WE = 1'b1;

        // Address Bus (PCH, PCL + 1)
        ABL_SRC = C_ABL_SRC_PCN;
        ABH_SRC = C_ABH_SRC_PCN;
        ABL_WE = 1'b1;
        ABH_WE = 1'b1;
      end
      default: begin
      end
    endcase
  end

endmodule
