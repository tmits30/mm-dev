// References
// - http://www.6502.org/tutorials/compare_instructions.html
// - http://www.6502.org/tutorials/decimal_mode.html
// - http://www.6502.org/tutorials/vflag.html

module alu(
  input [7:0]  A,
  input [7:0]  B,
  input [7:0]  FLAG_IN,
  input [3:0]  CTRL,
  output [7:0] OUT,
  output [7:0] FLAG_OUT
);

`include "params.vh"

  reg [8:0]    ret;
  reg          flag_c, flag_z, flag_v, flag_n;

  wire [7:0]   and_ab;
  wire [8:0]   add_ab, sub_ab;
  wire         in_carry;

  assign and_ab = A & B;
  assign add_ab = A + B;
  assign sub_ab = A - B;
  assign in_carry = FLAG_IN[C_FLAG_SHFT_C];

  always @(*) begin
    flag_c = FLAG_IN[C_FLAG_SHFT_C];
    flag_z = FLAG_IN[C_FLAG_SHFT_Z];
    flag_v = FLAG_IN[C_FLAG_SHFT_V];
    flag_n = FLAG_IN[C_FLAG_SHFT_N];

    if (CTRL == C_ALU_CTRL_THA) begin
      ret[7:0] = A;
    end else if (CTRL == C_ALU_CTRL_BIT) begin
      ret[7:0] = A;
      flag_n = B[7];
      flag_v = B[6];
      flag_z = and_ab == 8'h00;
    end else if (CTRL == C_ALU_CTRL_CMP) begin
      ret[7:0] = A;
      flag_n = sub_ab[7];
      flag_z = sub_ab[7:0] == 8'h00;
      flag_c = sub_ab[8] || sub_ab[7:0] == 8'h00;
    end else begin
      case (CTRL)
        C_ALU_CTRL_INC: begin
          ret = A + 8'h01;
        end
        C_ALU_CTRL_DEC: begin
          ret = A - 8'h01;
        end
        C_ALU_CTRL_ASL: begin
          ret[7:0] = {A[6:0], 1'b0};
          flag_c = A[7];
        end
        C_ALU_CTRL_LSR: begin
          ret[7:0] = {1'b0, A[7:1]};
          flag_c = A[0];
        end
        C_ALU_CTRL_ROL: begin
          ret = {A, in_carry};
          flag_c = A[7];
        end
        C_ALU_CTRL_ROR: begin
          ret = {A[0], in_carry, A[7:1]};
          flag_c = A[0];
        end
        C_ALU_CTRL_AND: begin
          ret[7:0] = and_ab;
        end
        C_ALU_CTRL_ORA: begin
          ret[7:0] = A | B;
        end
        C_ALU_CTRL_EOR: begin
          ret[7:0] = A ^ B;
        end
        C_ALU_CTRL_ADC: begin
          if (FLAG_IN[C_FLAG_SHFT_D]) begin
            // TODO: not implemented
          end else begin
            ret = add_ab + {7'b0, in_carry};
            flag_c = ret[8];
            flag_v = ((A[7] == 0 && B[7] == 0) ||
                      (A[7] == 1 && B[7] == 1)) && (ret[7] == 1);
          end
        end
        C_ALU_CTRL_SBC: begin
          if (FLAG_IN[C_FLAG_SHFT_D]) begin
            // TODO: not implemented
          end else begin
            ret = sub_ab - {7'b0, in_carry};
            flag_c = ret[8];
            flag_v = ((A[7] == 0 && B[7] == 1) ||
                      (A[7] == 1 && B[7] == 0)) && (ret[7] == 1);
          end
        end
        default: begin
          ret[7:0] = A;
        end
      endcase
      flag_n = ret[7];
      flag_z = ret[7:0] == 8'h00;
    end
  end

  assign OUT = ret[7:0];
  assign FLAG_OUT = {flag_n, flag_v,
                     FLAG_IN[C_FLAG_SHFT__], FLAG_IN[C_FLAG_SHFT_B],
                     FLAG_IN[C_FLAG_SHFT_D], FLAG_IN[C_FLAG_SHFT_I],
                     flag_z, flag_c};

endmodule
