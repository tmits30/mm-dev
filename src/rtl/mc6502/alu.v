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

  wire [7:0]   and_ab, shl_a, shr_a;
  wire [8:0]   add_ab, sub_ab;
  wire         in_carry;

  assign and_ab = A & B;
  assign add_ab = A + B;
  assign sub_ab = A - B;
  assign shl_a = A << 1;
  assign shr_a = A >> 1;
  assign in_carry = FLAG_IN & C_FLAG_MASK_C;

  always @(*) begin
    flag_c = FLAG_IN & 1'b1;
    flag_z = (FLAG_IN >> 1) & 1'b1;
    flag_v = (FLAG_IN >> 6) & 1'b1;
    flag_n = (FLAG_IN >> 7) & 1'b1;

    if (CTRL == C_ALU_CTRL_THA) begin
      ret = A;
    end else if (CTRL == C_ALU_CTRL_BIT) begin
      flag_n = (B & 8'h80) >> 7;
      flag_v = (B & 8'h40) >> 6;
      flag_z = (and_ab == 8'h00);
    end else if (CTRL == C_ALU_CTRL_CMP) begin
      flag_n = (sub_ab & 8'h80) >> 7;
      flag_z = (sub_ab[7:0] == 8'h00);
      flag_c = (sub_ab & 9'h100) >> 8;
    end else begin
      case (CTRL)
        C_ALU_CTRL_INC: begin
          ret = A + 8'h01;
        end
        C_ALU_CTRL_DEC: begin
          ret = A - 8'h01;
        end
        C_ALU_CTRL_ASL: begin
          ret = shl_a;
          flag_c = A >> 7;
        end
        C_ALU_CTRL_LSR: begin
          ret = shr_a;
          flag_c = A & 1'b1;
        end
        C_ALU_CTRL_ROL: begin
          ret = shl_a | in_carry;
          flag_c = A >> 7;
        end
        C_ALU_CTRL_ROR: begin
          ret = (in_carry << 7) | shr_a;
          flag_c = A & 1'b1;
        end
        C_ALU_CTRL_AND: begin
          ret = and_ab;
        end
        C_ALU_CTRL_ORA: begin
          ret = A | B;
        end
        C_ALU_CTRL_EOR: begin
          ret = A ^ B;
        end
        C_ALU_CTRL_ADC: begin
          ret = add_ab + in_carry;
          flag_c = (ret & 9'h100) >> 8;
        end
        C_ALU_CTRL_SBC: begin
          ret = sub_ab + in_carry - 1;
          flag_c = (ret & 9'h100) >> 8;
        end
        default: begin
          ret = A;
        end
      endcase
      flag_n = (ret & 8'h80) >> 7;
      flag_z = (ret == 8'h00);
    end
  end

  assign OUT = ret[7:0];
  assign FLAG_OUT = FLAG_IN | (flag_n << 7) | (flag_v << 6)| (flag_z << 2) | flag_c;

endmodule
