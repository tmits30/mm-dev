//------------------------------------------------------------------------------
// Processor Status Flag
//------------------------------------------------------------------------------

localparam C_FLAG_SHFT_C = 0;
localparam C_FLAG_SHFT_Z = 1;
localparam C_FLAG_SHFT_I = 2;
localparam C_FLAG_SHFT_D = 3;
localparam C_FLAG_SHFT_B = 4;
localparam C_FLAG_SHFT__ = 5;
localparam C_FLAG_SHFT_V = 6;
localparam C_FLAG_SHFT_N = 7;
localparam C_FLAG_SHFT_PCC = 8;

localparam C_FLAG_MASK_C = 8'h01; // Carry
localparam C_FLAG_MASK_Z = 8'h02; // Zero
localparam C_FLAG_MASK_I = 8'h04; // Interrupt (IRQ disable)
localparam C_FLAG_MASK_D = 8'h08; // Decimal (use BCD for arithmetics)
localparam C_FLAG_MASK_B = 8'h10; // Break
localparam C_FLAG_MASK__ = 8'h20; // ignored
localparam C_FLAG_MASK_V = 8'h40; // Overflow
localparam C_FLAG_MASK_N = 8'h80; // Negative
localparam C_FLAG_MASK_PCC = 9'h100;

//------------------------------------------------------------------------------
// Operations
//------------------------------------------------------------------------------

localparam C_OP_ADC = 6'h00;
localparam C_OP_AND = 6'h01;
localparam C_OP_ASL = 6'h02;
localparam C_OP_BCC = 6'h03;
localparam C_OP_BCS = 6'h04;
localparam C_OP_BEQ = 6'h05;
localparam C_OP_BIM = 6'h06;
localparam C_OP_BIT = 6'h07;
localparam C_OP_BMI = 6'h08;
localparam C_OP_BNE = 6'h09;
localparam C_OP_BPL = 6'h0a;
localparam C_OP_BRK = 6'h0b;
localparam C_OP_BVC = 6'h0c;
localparam C_OP_BVS = 6'h0d;
localparam C_OP_CLC = 6'h0e;
localparam C_OP_CLD = 6'h0f;
localparam C_OP_CLI = 6'h10;
localparam C_OP_CLV = 6'h11;
localparam C_OP_CMP = 6'h12;
localparam C_OP_CPX = 6'h13;
localparam C_OP_CPY = 6'h14;
localparam C_OP_DEA = 6'h15;
localparam C_OP_DEC = 6'h16;
localparam C_OP_DEX = 6'h17;
localparam C_OP_DEY = 6'h18;
localparam C_OP_EOR = 6'h19;
localparam C_OP_INA = 6'h1a;
localparam C_OP_INC = 6'h1b;
localparam C_OP_INX = 6'h1c;
localparam C_OP_INY = 6'h1d;
localparam C_OP_JMP = 6'h1e;
localparam C_OP_JSR = 6'h1f;
localparam C_OP_LDA = 6'h20;
localparam C_OP_LDX = 6'h21;
localparam C_OP_LDY = 6'h22;
localparam C_OP_LSR = 6'h23;
localparam C_OP_NOP = 6'h24;
localparam C_OP_ORA = 6'h25;
localparam C_OP_PHA = 6'h26;
localparam C_OP_PHP = 6'h27;
localparam C_OP_PLA = 6'h28;
localparam C_OP_PLP = 6'h29;
localparam C_OP_ROL = 6'h2a;
localparam C_OP_ROR = 6'h2b;
localparam C_OP_RTI = 6'h2c;
localparam C_OP_RTS = 6'h2d;
localparam C_OP_SBC = 6'h2e;
localparam C_OP_SEC = 6'h2f;
localparam C_OP_SED = 6'h30;
localparam C_OP_SEI = 6'h31;
localparam C_OP_STA = 6'h32;
localparam C_OP_STX = 6'h33;
localparam C_OP_STY = 6'h34;
localparam C_OP_TAX = 6'h35;
localparam C_OP_TAY = 6'h36;
localparam C_OP_TSX = 6'h37;
localparam C_OP_TXA = 6'h38;
localparam C_OP_TXS = 6'h39;
localparam C_OP_TYA = 6'h3a;

//------------------------------------------------------------------------------
// Address Mode
//------------------------------------------------------------------------------

localparam C_ADDR_MODE_ACC = 4'h0; // Accumulator Mode
localparam C_ADDR_MODE_ABS = 4'h1; // Absolute Addressing Mode
localparam C_ADDR_MODE_ABX = 4'h2; // Absolute, X Addressing Mode
localparam C_ADDR_MODE_ABY = 4'h3; // Absolute, Y Addressing Mode
localparam C_ADDR_MODE_IMM = 4'h4; // Immediate Addressing Mode
localparam C_ADDR_MODE_IMP = 4'h5; // Implied Mode
localparam C_ADDR_MODE_IND = 4'h6; // Indirect Addressing Mode (for branch ops)
localparam C_ADDR_MODE_INX = 4'h7; // Indirect, X Addressing Mode
localparam C_ADDR_MODE_INY = 4'h8; // Indirect, Y Addressing Mode
localparam C_ADDR_MODE_REL = 4'h9; // Relative Addressing Mode
localparam C_ADDR_MODE_ZPG = 4'ha; // Zero Page Addressing Mode
localparam C_ADDR_MODE_ZPX = 4'hb; // Zero Page, X Addressing Mode
localparam C_ADDR_MODE_ZPY = 4'hc; // Zero Page, Y Addressing Mode

//------------------------------------------------------------------------------
// ALU Contorl
//------------------------------------------------------------------------------

localparam C_ALU_CTRL_THA = 4'h0;
localparam C_ALU_CTRL_INC = 4'h1;
localparam C_ALU_CTRL_DEC = 4'h2;
localparam C_ALU_CTRL_AND = 4'h3;
localparam C_ALU_CTRL_ORA = 4'h4;
localparam C_ALU_CTRL_EOR = 4'h5;
localparam C_ALU_CTRL_ASL = 4'h6;
localparam C_ALU_CTRL_LSR = 4'h7;
localparam C_ALU_CTRL_ROL = 4'h8;
localparam C_ALU_CTRL_ROR = 4'h9;
localparam C_ALU_CTRL_ADC = 4'ha;
localparam C_ALU_CTRL_SBC = 4'hb; 
localparam C_ALU_CTRL_BIT = 4'hc;
localparam C_ALU_CTRL_CMP = 4'hd;

//------------------------------------------------------------------------------
// PC Adder Control
//------------------------------------------------------------------------------

localparam C_PCADDER_CTRL_NOP  = 2'h0;
localparam C_PCADDER_CTRL_INC  = 2'h1;
localparam C_PCADDER_CTRL_ADD  = 2'h2;
localparam C_PCADDER_CTRL_CADD = 2'h3;

//------------------------------------------------------------------------------
// Control Signal
//------------------------------------------------------------------------------

localparam C_RW_R = 1'b1;
localparam C_RW_W = 1'b0;

localparam C_DB_OUT_SRC_A   = 3'h0;
localparam C_DB_OUT_SRC_X   = 3'h1;
localparam C_DB_OUT_SRC_Y   = 3'h2;
localparam C_DB_OUT_SRC_T   = 3'h3;
localparam C_DB_OUT_SRC_P   = 3'h4;
localparam C_DB_OUT_SRC_PCL = 3'h5;
localparam C_DB_OUT_SRC_PCH = 3'h6;

localparam C_PCL_SRC_ADD = 2'h0;
localparam C_PCL_SRC_MEM = 2'h1;
localparam C_PCL_SRC_T   = 2'h2;

localparam C_PCH_SRC_ADD = 1'b0;
localparam C_PCH_SRC_MEM = 1'b1;

localparam C_REG_SRC_A   = 3'h0;
localparam C_REG_SRC_X   = 3'h1;
localparam C_REG_SRC_Y   = 3'h2;
localparam C_REG_SRC_S   = 3'h3;
localparam C_REG_SRC_T   = 3'h4;
localparam C_REG_SRC_P   = 3'h5;
localparam C_REG_SRC_MEM = 3'h6;
localparam C_REG_SRC_ALU = 3'h7;

localparam C_REG_DST_A   = 3'h0;
localparam C_REG_DST_X   = 3'h1;
localparam C_REG_DST_Y   = 3'h2;
localparam C_REG_DST_S   = 3'h3;
localparam C_REG_DST_T   = 3'h4;
localparam C_REG_DST_P   = 3'h5;

localparam C_P_SRC_T   = 3'h0;
localparam C_P_SRC_MEM = 3'h1;
localparam C_P_SRC_ALU = 3'h2;
localparam C_P_SRC_SET = 3'h3;
localparam C_P_SRC_CLR = 3'h4;

localparam C_ALU_SRC_A_A   = 3'h0;
localparam C_ALU_SRC_A_X   = 3'h1;
localparam C_ALU_SRC_A_Y   = 3'h2;
localparam C_ALU_SRC_A_S   = 3'h3;
localparam C_ALU_SRC_A_T   = 3'h4;

localparam C_ALU_SRC_B_T   = 1'h0;
localparam C_ALU_SRC_B_H00 = 1'h1;

localparam C_ABL_SRC_PCN = 3'h0; // Next Program Counter Low
localparam C_ABL_SRC_PCC = 3'h1; // Current Program Counter Low
localparam C_ABL_SRC_MEM = 3'h2;
localparam C_ABL_SRC_ALU = 3'h3;
localparam C_ABL_SRC_S   = 3'h4;
localparam C_ABL_SRC_T   = 3'h5;
localparam C_ABL_SRC_HFE = 3'h6;
localparam C_ABL_SRC_HFF = 3'h7;

localparam C_ABH_SRC_PCN = 3'h0; // Next Program Counter High
localparam C_ABH_SRC_PCC = 3'h1; // Current Program Counter High
localparam C_ABH_SRC_MEM = 3'h2;
localparam C_ABH_SRC_ALU = 3'h3;
localparam C_ABH_SRC_H00 = 3'h4;
localparam C_ABH_SRC_H01 = 3'h5;
localparam C_ABH_SRC_HFF = 3'h6;

//------------------------------------------------------------------------------
// State
//------------------------------------------------------------------------------

// Common part
localparam C_STATE_T0_R_OPCO = 6'h00; // Read Opcode
localparam C_STATE_T1_R_OPER = 6'h01; // Read 1st Operand
localparam C_STATE_TX_R_DATB = 6'h02; // Read Data at crossing page boundary
localparam C_STATE_TX_R_DATA = 6'h03; // Read Data
localparam C_STATE_TX_M_DATA = 6'h04; // Modify Data
localparam C_STATE_TX_W_DATA = 6'h05; // Write Data

// Absolute Addressing Mode
localparam C_STATE_T2_ABS_AM = 6'h06;
localparam C_STATE_T3_JSR_OP = 6'h07;
localparam C_STATE_T4_JSR_OP = 6'h08;
localparam C_STATE_T5_JSR_OP = 6'h09;

// Absolute, X or Y Addressing Mode
localparam C_STATE_T2_ABR_AM = 6'h0a;

// Indirect Addressing Mode (JMP Operation)
localparam C_STATE_T2_IND_AM = 6'h0b;
localparam C_STATE_T3_IND_AM = 6'h0c;
localparam C_STATE_T4_IND_AM = 6'h0d;

// Indirect, X Addressing Mode
localparam C_STATE_T2_INX_AM = 6'h0e;
localparam C_STATE_T3_INX_AM = 6'h0f;
localparam C_STATE_T4_INX_AM = 6'h10;

// Indirect, Y Addressing Mode
localparam C_STATE_T2_INY_AM = 6'h11;
localparam C_STATE_T3_INY_AM = 6'h12;

// Relative Addressing Mode (Branch Operations)
localparam C_STATE_T2_REL_AM = 6'h13;
localparam C_STATE_T3_REL_AM = 6'h14;

// Zero Page, X or Y Addressing Mode
localparam C_STATE_T2_ZPR_AM = 6'h15;

// Implied Addressing Mode
localparam C_STATE_T2_BRK_OP = 6'h16;
localparam C_STATE_T3_BRK_OP = 6'h17;
localparam C_STATE_T4_BRK_OP = 6'h18;
localparam C_STATE_T5_BRK_OP = 6'h19;
localparam C_STATE_T6_BRK_OP = 6'h1a;

localparam C_STATE_T2_PLR_OP = 6'h1b;
localparam C_STATE_T2_PHR_OP = 6'h1c;

localparam C_STATE_T2_RTI_OP = 6'h1d;
localparam C_STATE_T3_RTI_OP = 6'h1e;
localparam C_STATE_T4_RTI_OP = 6'h1f;
localparam C_STATE_T5_RTI_OP = 6'h20;

localparam C_STATE_T2_RTS_OP = 6'h21;
localparam C_STATE_T3_RTS_OP = 6'h22;
localparam C_STATE_T4_RTS_OP = 6'h23;
localparam C_STATE_T5_RTS_OP = 6'h24;
