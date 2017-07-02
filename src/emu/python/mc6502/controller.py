from mc6502 import decoder


class Controller(object):

    def __init__(self):
        self._decoder = decoder.InstructionDecoder()

        self._state = 'T0_fetch_opcode'
        self._instr = 0xea
        self._op_name = 'NOP'
        self._addr_mode = 'impl'

        self.reset()

    def reset(self):
        self.r_w = 'r'

        # Data Bus and Input Data Latch
        self.db_src = 'm'
        self.dl_we = False

        # Instruction Register
        self.ir_we = False

        # Program Counter
        self.pcadder_ctrl = 'nop'
        self.pcl_src = 'm'
        self.pcl_we = False
        self.pch_src = 'm'
        self.pch_we = False

        # Registers
        self.reg_src = 'm'
        self.a_we = False # Accumulator
        self.x_we = False # Index X register
        self.y_we = False # Index Y register
        self.s_we = False # Stack Point Register
        self.t_we = False # Temporary Register

        # Processor Status Register
        self.p_src = 'alu'
        self.p_mask = 0x00

        # ALU
        self.alu_src_a = '-'
        self.alu_src_b = '-'
        self.alu_ctrl = 'tha'

        # Address Bus
        self.abl_src = 'pcl'
        self.abl_we = False
        self.abh_src = 'pch'
        self.abh_we = False

    def __str__(self):
        str_reg = lambda src, we: '({},{})'.format(src, we)
        fmt = [
            'OPCODE={}(0x{:02x}) ADDRMODE={} NextSTATE={}'.format(
                self._op_name, self._instr, self._addr_mode, self._state),
            'RW={} DBSrc={} DLWe={} IRWe={}'.format(
                self.r_w, self.db_src, self.dl_we, self.ir_we),
            'PCL={} PCH={} PCAdderCtrl={}'.format(
                str_reg(self.pcl_src, self.pcl_we),
                str_reg(self.pch_src, self.pch_we), self.pcadder_ctrl),
            'A={} X={} Y={} S={} T={} P={}'.format(
                str_reg(self.reg_src, self.a_we),
                str_reg(self.reg_src, self.x_we),
                str_reg(self.reg_src, self.y_we),
                str_reg(self.reg_src, self.s_we),
                str_reg(self.reg_src, self.t_we),
                self.p_src),
            'ABL={} ABH={}'.format(
                str_reg(self.abl_src, self.abl_we),
                str_reg(self.abh_src, self.abh_we)),
            'ALUSrcA={} ALUSrcB={} ALUControl={}'.format(
                self.alu_src_a, self.alu_src_b, self.alu_ctrl),
        ]
        return '\n\t'.join(fmt)

    def __call__(self, instr, flag, rdy=True,
                 res_n=True, irq_n=True, nmi_n=True):
        self.reset()
        self._state = {
            # Common part
            'T0_fetch_opcode': self._t0_fetch_opcode,
            'T1_fetch_operand': self._t1_fetch_operand,

            # Fetch/Moidify/Write
            'Tx_fetch_data_c0': self._tx_fetch_data_c0,
            'Tx_fetch_data': self._tx_fetch_data,
            'Tx_modify_data': self._tx_modiry_data,
            'Tx_write_data': self._tx_write_data,

            # Absolute Addressing
            'T2_abs_addr_mode': self._t2_abs_addr_mode,
            'T3_jsr_op': self._t3_jsr_op,
            'T4_jsr_op': self._t4_jsr_op,
            'T5_jsr_op': self._t5_jsr_op,

            # Absolute, X or Y Addressing
            'T2_absi_addr_mode': self._t2_absi_addr_mode,

            # Indirect Addressing (JMP Operation)
            'T2_ind_addr_mode': self._t2_ind_addr_mode,
            'T3_ind_addr_mode': self._t3_ind_addr_mode,
            'T4_ind_addr_mode': self._t4_ind_addr_mode,

            # Indirect, X Addressing
            'T2_indx_addr_mode': self._t2_indx_addr_mode,
            'T3_indx_addr_mode': self._t3_indx_addr_mode,
            'T4_indx_addr_mode': self._t4_indx_addr_mode,

            # Indirect, Y Addressing
            'T2_indy_addr_mode': self._t2_indy_addr_mode,
            'T3_indy_addr_mode': self._t3_indy_addr_mode,

            # Relative Addressing (Branch Operations)
            'T2_rel_addr_mode': self._t2_rel_addr_mode,
            'T3_rel_addr_mode': self._t3_rel_addr_mode,

            # Zero Page, X or Y Addressing
            'T2_zpgi_addr_mode': self._t2_zpgi_addr_mode,

            # Implied Addressing
            'T2_brk_op': self._t2_brk_op,
            'T3_brk_op': self._t3_brk_op,
            'T4_brk_op': self._t4_brk_op,
            'T5_brk_op': self._t5_brk_op,
            'T6_brk_op': self._t6_brk_op,

            'T2_plr_op': self._t2_plr_op,
            'T2_phr_op': self._t2_phr_op,

            'T2_rti_op': self._t2_rti_op,
            'T3_rti_op': self._t3_rti_op,
            'T4_rti_op': self._t4_rti_op,
            'T5_rti_op': self._t5_rti_op,

            'T2_rts_op': self._t2_rts_op,
            'T3_rts_op': self._t3_rts_op,
            'T4_rts_op': self._t4_rts_op,
            'T5_rts_op': self._t5_rts_op,
        }[self._state](instr, flag)

    def _execute_control(self):
        a_m = 'a' if self._addr_mode == 'acc' else 'm'
        return {
            # op     A   Out  Control
            'ADC': ('a', 'a', 'adc'),
            'AND': ('a', 'a', 'and'),
            'ASL': (a_m, a_m, 'asl'),
            'BIT': ('a', 'a', 'bit'),
            'CMP': ('a', 'a', 'cmp'),
            'CPX': ('x', 'x', 'cmp'),
            'CPY': ('y', 'y', 'cmp'),
            'DEC': ('t', 't', 'dec'),
            'DEX': ('x', 'x', 'dec'),
            'DEY': ('y', 'y', 'dec'),
            'EOR': ('a', 'a', 'eor'),
            'INC': ('t', 't', 'inc'),
            'INX': ('x', 'x', 'inc'),
            'INY': ('y', 'y', 'inc'),
            'LDA': ('t', 'a', 'tha'),
            'LDX': ('t', 'x', 'tha'),
            'LDY': ('t', 'y', 'tha'),
            'LSR': (a_m, a_m, 'lsr'),
            'ORA': ('a', 'a', 'ora'),
            'PLA': ('t', 'a', 'tha'),
            'PLP': ('t', 'p', 'tha'),
            'ROL': (a_m, a_m, 'rol'),
            'ROR': (a_m, a_m, 'ror'),
            'SBC': ('a', 'a', 'sbc'),
            'TAX': ('a', 'x', 'tha'),
            'TAY': ('a', 'y', 'tha'),
            'TSX': ('s', 'x', 'tha'),
            'TXA': ('x', 'a', 'tha'),
            'TXS': ('x', 's', 'tha'),
            'TYA': ('y', 'a', 'tha'),
        }.get(self._op_name, ('-', '-', 'tha'))

    @property
    def _is_rmw_type(self):
        return self._op_name in ['ASL', 'DEC', 'INC', 'LSR', 'ROL', 'ROR']

    @property
    def _is_str_type(self):
        return self._op_name in ['STA', 'STX', 'STY']

    def _t0_fetch_opcode(self, instr, flag):
        # Instruction Register
        self.ir_we = True

        # Program Counter
        self.pcadder_ctrl = 'inc'
        self.pcl_we = True
        self.pcl_src = 'padr'
        self.pch_we = True
        self.pch_src = 'padr'

        # Execute
        execute = self._execute_control()
        self.alu_src_a = execute[0]
        self.alu_src_b = 't'
        alu_dst = execute[1]
        self.alu_ctrl = execute[2]

        # Store ALUOut
        self.a_we = alu_dst == 'a'
        self.x_we = alu_dst == 'x'
        self.y_we = alu_dst == 'y'
        self.s_we = alu_dst == 's'
        self.reg_src = 'alu'

        # Change Processor Status Register
        flag_op = {
            'CLC': (0x01, 'clr'), 'SEC': (0x01, 'set'),
            'CLI': (0x04, 'clr'), 'SEI': (0x04, 'set'),
            'CLD': (0x08, 'clr'), 'SED': (0x08, 'set'),
            'CLV': (0x40, 'clr'),
        }.get(self._op_name, (0x00, None))
        self.p_mask = flag_op[0]

        if alu_dst == 'p':
            self.p_src = 'm'
        elif flag_op[1] == 'set':
            self.p_src = 'set'
        elif flag_op[1] == 'clr':
            self.p_src = 'clr'

        # Address Bus PC (fetch data from the address at next cycle)
        self.abl_we = True
        self.abh_we = True

        # Next state
        next_state = 'T1_fetch_operand'
        return next_state

    def _t1_fetch_operand(self, instr, flag):
        # Decode instruction
        decoded = self._decoder(instr)
        self._instr = instr
        self._op_name = decoded[0]
        self._addr_mode = decoded[1]

        # Is branch?
        is_branch = {
            'BCC': flag['C'] == 0, 'BCS': flag['C'] == 1,
            'BNE': flag['Z'] == 0, 'BEQ': flag['Z'] == 1,
            'BVC': flag['V'] == 0, 'BVS': flag['V'] == 1,
            'BPL': flag['N'] == 0, 'BMI': flag['N'] == 1,
        }.get(self._op_name, False)

        # Program Counter
        self.pcadder_ctrl = {
            'impl': 'nop',
            'rel': 'add' if is_branch else 'inc',
        }.get(self._addr_mode, 'inc')
        self.pcl_we = True
        self.pcl_src = 'padr'
        self.pch_we = True
        self.pch_src = 'padr'

        # Input Data latch
        self.dl_we = True

        # Temporary Reigister
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        self.abl_we = True
        self.abh_we = True
        if self._addr_mode in ['indx', 'indy', 'zpg', 'zpgx', 'zpgy']:
            self.abl_src = 'm'
            self.abh_src = '0'
        elif self._op_name in ['PHP', 'PHA', 'PLP', 'PLA',
                               'JSR', 'BRK', 'RTI', 'RTS']:
            self.abl_src = 's'
            self.abh_src = '1'
        else:
            self.abl_src = 'pcl'
            self.abh_src = 'pch'

        # Next state
        next_state = {
            'acc': 'T0_fetch_opcode',
            'imm': 'T0_fetch_opcode',
            'abs': 'T2_abs_addr_mode',
            'absx': 'T2_absi_addr_mode',
            'absy': 'T2_absi_addr_mode',
            'ind': 'T2_ind_addr_mode',
            'indx': 'T2_indx_addr_mode',
            'indy': 'T2_indy_addr_mode',
            'zpg': 'Tx_write_data' if self._is_str_type else 'Tx_fetch_data',
            'zpgx': 'T2_zpgi_addr_mode',
            'zpgy': 'T2_zpgi_addr_mode',
            'rel': 'T2_rel_addr_mode' if is_branch else 'T0_fetch_opcode',
            'impl': {
                'BRK': 'T2_brk_op',
                'PLA': 'T2_plr_op', 'PLP': 'T2_plr_op',
                'PHA': 'T2_phr_op', 'PHP': 'T2_phr_op',
                'RTI': 'T2_rti_op', 'RTS': 'T2_rts_op',
            }.get(self._op_name, 'T0_fetch_opcode'),
        }[self._addr_mode]

        return next_state

    def _tx_fetch_data_c0(self, instr, flag):
        # Input Data latch
        self.dl_we = True

        # Execute ADH + C
        self.alu_src_a = 't'
        self.alu_src_b = '1'
        self.alu_ctrl = 'adc'

        # Temporary Register (Data)
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        if flag['C'] or self._is_rmw_type:
            # - ADH + C, ADL
            self.abh_we = True
            self.abh_src = 'alu'
        elif self._op_name in ['STA', 'STX', 'STY']:
            self.abl_we = False
            self.abh_we = False
        else:
            self.abl_we = True
            self.abl_src = 'pcl'
            self.abh_we = True
            self.abh_src = 'pch'

        # Next state
        if flag['C'] or self._is_rmw_type:
            next_state = 'Tx_fetch_data'
        elif self._is_str_type:
            next_state = 'Tx_write_data'
        else:
            next_state = 'T0_fetch_opcode'
        return next_state

    def _tx_fetch_data(self, instr, flag):
        # Input Data latch
        self.dl_we = True

        # Temporary Register
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        if not self._is_rmw_type:
            self.abl_we = True
            self.abl_src = 'pcl'
            self.abh_we = True
            self.abh_src = 'pch'

        # Next state
        next_state = 'Tx_modify_data' if self._is_rmw_type else \
                     'T0_fetch_opcode'
        return next_state

    def _tx_modiry_data(self, instr, flag):
        self.r_w = 'w'

        # Execute
        execute = self._execute_control()
        self.alu_src_a = execute[0]
        self.alu_src_b = 't'
        alu_dst = execute[1]
        self.alu_ctrl = execute[2]
        assert self.alu_src_a == 't' and alu_dst == 't'

        # Temporary Register
        self.t_we = True
        self.reg_src = 'alu'

        # Next state
        next_state = 'Tx_write_data'
        return next_state

    def _tx_write_data(self, instr, flag):
        # Data Bus
        self.r_w = 'w'
        if self._op_name in ['STA', 'STX', 'STY']:
            self.db_src = {'STA': 'a', 'STX': 'x', 'STY': 'y'}[self._op_name]
        else:
            self.db_src = 't'

        # Address Bus (fetch data from the address at next cycle)
        self.abl_we = True
        self.abl_src = 'pcl'
        self.abh_we = True
        self.abh_src = 'pch'

        # Next state
        next_state = 'T0_fetch_opcode'
        return next_state

    def _t2_abs_addr_mode(self, instr, flag):
        # Program Counter
        self.pcadder_ctrl = 'nop' if self._op_name == 'JSR' else 'inc'

        # Input Data Latch (ADH)
        self.dl_we = True

        # Program Counter
        self.pcl_we = True
        self.pch_we = True
        if self._op_name == 'JMP':
            self.pcl_src = 't'
            self.pch_src = 'm'
        else:
            self.pcl_src = 'padr'
            self.pch_src = 'padr'

        # Address Bus (fetch data from the address at next cycle)
        if self._op_name != 'JSR':
            # - ADH, ADL
            self.abl_we = True
            self.abl_src = 't'
            self.abh_we = True
            self.abh_src = 'm'

        # Next state
        if self._op_name == 'JMP':
            next_state = 'T0_fetch_opcode'
        elif self._op_name == 'JSR':
            next_state = 'T3_jsr_op'
        elif self._is_str_type:
            next_state = 'Tx_write_data'
        else:
            next_state = 'Tx_fetch_data'
        return next_state

    def _t3_jsr_op(self, instr, flag):
        # Data Bus
        self.r_w = 'w'
        self.db_src = 'pch'

        # Execute S - 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'dec'

        # Processor Status Register
        self.p_src = 'set' # NOT 'alu'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, S - 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T4_jsr_op'
        return next_state

    def _t4_jsr_op(self, instr, flag):
        # Data Bus
        self.r_w = 'w'
        self.db_src = 'pcl'

        # Execute (S - 1) - 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'dec'

        # Processor Status Register
        self.p_src = 'set' # NOT 'alu'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - PC + 2
        self.abl_we = True
        self.abl_src = 'pcl'
        self.abh_we = True
        self.abh_src = 'pch'

        # Next state
        next_state = 'T5_jsr_op'
        return next_state

    def _t5_jsr_op(self, instr, flag):
        # Input Data Latch (ADH)
        self.dl_we = True

        # Program Counter
        self.pcl_we = True
        self.pcl_src = 't'
        self.pch_we = True
        self.pch_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - ADH, ADL
        self.abl_we = True
        self.abl_src = 't'
        self.abh_we = True
        self.abh_src = 'm'

        # Next state
        next_state = 'T0_fetch_opcode'
        return next_state

    def _t2_absi_addr_mode(self, instr, flag):
        # Program Counter
        self.pcadder_ctrl = 'inc'
        self.pcl_we = True
        self.pcl_src = 'padr'
        self.pch_we = True
        self.pch_src = 'padr'

        # Input Data Latch (BAH)
        self.dl_we = True

        # Execute BAL + index register
        self.alu_src_a = 'x' if self._addr_mode == 'absx' else 'y'
        self.alu_src_b = 't'
        self.alu_ctrl = 'adc'

        # Temporary Register (BAH) for 'Tx_fetch_data_c0'
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - BAH, BAL + index register
        self.abl_we = True
        self.abl_src = 'alu'
        self.abh_we = True
        self.abh_src = 'm'

        # Next state
        next_state = 'Tx_fetch_data_c0'
        return next_state

    def _t2_ind_addr_mode(self, instr, flag):
        # Input Data Latch (IAH)
        self.dl_we = True

        # Program Counter
        self.pcadder_ctrl = 'inc'
        self.pcl_we = True
        self.pcl_src = 'padr'
        self.pch_we = True
        self.pch_src = 'padr'

        # Address Bus (fetch data from the address at next cycle)
        # - IAH, IAL
        self.abl_we = True
        self.abl_src = 't'
        self.abh_we = True
        self.abh_src = 'm'

        # Next state
        next_state = 'T3_ind_addr_mode'
        return next_state

    def _t3_ind_addr_mode(self, instr, flag):
        # Input Data Latch (ADL)
        self.dl_we = True

        # Execute IAL + 1
        self.alu_src_a = 't'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Temporary Reigister (ADL)
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - IAH, IAL + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T4_ind_addr_mode'
        return next_state

    def _t4_ind_addr_mode(self, instr, flag):
        # Input Data Latch (ADH)
        self.dl_we = True

        # Program Counter
        self.pcl_we = True
        self.pcl_src = 't'
        self.pch_we = True
        self.pch_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - ADH, ADL
        self.abl_we = True
        self.abl_src = 't'
        self.abh_we = True
        self.abh_src = 'm'

        # Next state
        next_state = 'T0_fetch_opcode'
        return next_state

    def _t2_indx_addr_mode(self, instr, flag):
        # Execute BAL + X
        self.alu_src_a = 'x'
        self.alu_src_b = 'm'
        self.alu_ctrl = 'adc'

        # Temporary Register (BAL + X)
        self.t_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - 00, BAL + X
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T3_indx_addr_mode'
        return next_state

    def _t3_indx_addr_mode(self, instr, flag):
        # Input Data Latch (ADL)
        self.dl_we = True

        # Execute (BAL + X) + 1
        self.alu_src_a = 't'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Temporary Register (ADL)
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - 00, BAL + X + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T4_indx_addr_mode'
        return next_state

    def _t4_indx_addr_mode(self, instr, flag):
        # Input Data Latch (ADH)
        self.dl_we = True

        # Address Bus (fetch data from the address at next cycle)
        # - ADH, ADL
        self.abl_we = True
        self.abl_src = 't'
        self.abh_we = True
        self.abh_src = 'm'

        # Next state
        next_state = 'Tx_write_data' if self._is_str_type else 'Tx_fetch_data'
        return next_state

    def _t2_indy_addr_mode(self, instr, flag):
        # Input Data Latch (BAL)
        self.dl_we = True

        # Execute IAL + 1
        self.alu_src_a = 't'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Temporary Register (BAL)
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - 00, IAL + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T3_indy_addr_mode'
        return next_state

    def _t3_indy_addr_mode(self, instr, flag):
        # Input Data Latch (BAH)
        self.dl_we = True

        # Execute BAL + Y
        self.alu_src_a = 'y'
        self.alu_src_b = 't'
        self.alu_ctrl = 'adc'

        # Temporary Register (BAH) for 'Tx_fetch_data_c0'
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - BAH, BAL + Y
        self.abl_we = True
        self.abl_src = 'alu'
        self.abh_we = True
        self.abh_src = 'm'

        # Next state
        next_state = 'Tx_fetch_data_c0'
        return next_state

    def _t2_rel_addr_mode(self, instr, flag):
        # Program Counter Adder
        self.pcadder_ctrl = 'cadd'
        self.pcl_we = True
        self.pcl_src = 'padr'
        self.pch_we = True
        self.pch_src = 'padr'

        # Address Bus (fetch data from the address at next cycle)
        # - PCH, (PCL + 2) + offset
        self.abh_we = True
        self.abh_src = 'pch'

        # Next state
        if flag['PCC']:
            next_state = 'T3_rel_addr_mode'
        else:
            next_state = 'T0_fetch_opcode'
        return next_state

    def _t3_rel_addr_mode(self, instr, flag):
        # Next state
        next_state = 'T0_fetch_opcode'
        return next_state

    def _t2_zpgi_addr_mode(self, instr, flag):
        # Execute BAL + index register
        self.alu_src_a = 'x' if self._addr_mode == 'zpgx' else 'y'
        self.alu_src_b = 'm'
        self.alu_ctrl = 'adc'

        # Address Bus (fetch data from the address at next cycle)
        # - ADH, ADL
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'Tx_write_data' if self._is_str_type else 'Tx_fetch_data'
        return next_state

    def _t2_brk_op(self, instr, flag):
        # Data Bus
        self.r_w = 'w'
        self.db_src = 'pch'

        # Execute S - 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'dec'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, S - 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T3_brk_op'
        return next_state

    def _t3_brk_op(self, instr, flag):
        # Data Bus
        self.r_w = 'w'
        self.db_src = 'pcl'

        # Execute (S - 1) - 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'dec'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, (S - 1) - 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T4_brk_op'
        return next_state

    def _t4_brk_op(self, instr, flag):
        # Data Bus
        self.r_w = 'w'
        self.db_src = 'p'

        # Execute ((S - 1) - 1) - 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'dec'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - FF, FE
        self.abl_we = True
        self.abl_src = 'fe'
        self.abh_we = True
        self.abh_src = 'ff'

        # Next state
        next_state = 'T5_brk_op'
        return next_state

    def _t5_brk_op(self, instr, flag):
        # Input Data latch (ADL)
        self.dl_we = True

        # Temporary Register (ADL)
        self.t_we = True
        self.reg_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - FF, FF
        self.abl_we = True
        self.abl_src = 'ff'

        # Next state
        next_state = 'T6_brk_op'
        return next_state

    def _t6_brk_op(self, instr, flag):
        # Input Data latch (ADH)
        self.dl_we = True

        # Program Counter
        self.pcl_we = True
        self.pcl_src = 't'
        self.pch_we = True
        self.pch_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - ADH, ADL
        self.abl_we = True
        self.abl_src = 't'
        self.abh_we = True
        self.abh_src = 'm'

        # Next state
        next_state = 'T0_fetch_opcode'
        return next_state

    def _t2_plr_op(self, instr, flag):
        # Execute S + 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Processor Status Register
        self.p_src = 'set' # NOT 'alu'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, S + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'Tx_fetch_data'
        return next_state

    def _t2_phr_op(self, instr, flag):
        self.r_w = 'w'
        self.db_src = 'a' if self._op_name == 'PHA' else 'p'

        # Input Data latch
        self.dl_we = True

        # Execute S - 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'dec'

        # Processor Status Register
        self.p_src = 'set' # NOT 'alu'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, S + 1
        self.abl_we = True
        self.abl_src = 'pcl'
        self.abh_we = True
        self.abh_src = 'pch'

        # Next state
        next_state = 'T0_fetch_opcode'
        return next_state

    def _t2_rti_op(self, instr, flag):
        # Execute S + 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Processor Status Register
        self.p_src = 'set' # NOT 'alu'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, S + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T3_rti_op'
        return next_state

    def _t3_rti_op(self, instr, flag):
        # Input Data Latch (P)
        self.dl_we = True

        # Execute S + 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Restore Processor Status Register
        self.p_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, (S + 1) + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T4_rti_op'
        return next_state

    def _t4_rti_op(self, instr, flag):
        # Input Data Latch (PCL)
        self.dl_we = True

        # Execute S + 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Processor Status Register
        self.p_src = 'set' # NOT 'alu'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Restore Program Counter
        self.pcl_we = True
        self.pcl_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, ((S + 1) + 1) + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T5_rti_op'
        return next_state

    def _t5_rti_op(self, instr, flag):
        # Input Data Latch (PCH)
        self.dl_we = True

        # Restore Program Counter
        self.pch_we = True
        self.pch_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, (((S + 1) + 1) + 1) + 1
        self.abl_we = True
        self.abl_src = 'pcl'
        self.abh_we = True
        self.abh_src = 'm'

        # Next state
        next_state = 'T0_fetch_opcode'
        return next_state

    def _t2_rts_op(self, instr, flag):
        # Execute S + 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Processor Status Register
        self.p_src = 'set' # NOT 'alu'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, S + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T3_rts_op'
        return next_state

    def _t3_rts_op(self, instr, flag):
        # Input Data Latch (PCL)
        self.dl_we = True

        # Execute (S + 1) + 1
        self.alu_src_a = 's'
        self.alu_src_b = '-'
        self.alu_ctrl = 'inc'

        # Processor Status Register
        self.p_src = 'set' # NOT 'alu'

        # Update Stack Pointer
        self.s_we = True
        self.reg_src = 'alu'

        # Restore Program Counter
        self.pcl_we = True
        self.pcl_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - 0x01, (S + 1) + 1
        self.abl_we = True
        self.abl_src = 'alu'

        # Next state
        next_state = 'T4_rts_op'
        return next_state

    def _t4_rts_op(self, instr, flag):
        # Input Data Latch (PCH)
        self.dl_we = True

        # Restore Program Counter
        self.pch_we = True
        self.pch_src = 'm'

        # Address Bus (fetch data from the address at next cycle)
        # - PCH, PCL
        self.abl_we = True
        self.abl_src = 'pcl'
        self.abh_we = True
        self.abh_src = 'pch'

        # Next state
        next_state = 'T5_rts_op'
        return next_state

    def _t5_rts_op(self, instr, flag):
        # Program Counter
        self.pcadder_ctrl = 'inc'
        self.pcl_we = True
        self.pcl_src = 'padr'
        self.pch_we = True
        self.pch_src = 'padr'

        # Address Bus (fetch data from the address at next cycle)
        # - PCH, PCL + 1
        self.abl_we = True
        self.abl_src = 'pcl'

        # Next state
        next_state = 'T0_fetch_opcode'
        return next_state
