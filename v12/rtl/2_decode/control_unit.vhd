------------------------------------------------------------------------------
-- Main Control Unit (purely combinational, decodes the instruction in ID)
--
--  Instr  | RegWr MemToReg MemRd MemWr RegDst ALUSrc ALUOp Br J JR Ext0 rs rt
--  -------+----------------------------------------------------------------
--  ADD    |   1      0       0     0     1      0    ADD  0  0  0   -   1  1
--  NOR    |   1      0       0     0     1      0    NOR  0  0  0   -   1  1
--  XOR    |   1      0       0     0     1      0    XOR  0  0  0   -   1  1
--  SLL    |   1      0       0     0     1      0    SLL  0  0  0   -   0  1
--  JR     |   0      0       0     0     -      -     -   0  0  1   -   1  0
--  ANDI   |   1      0       0     0     0      1    AND  0  0  0   1   1  0
--  SUBUI  |   1      0       0     0     0      1    SUB  0  0  0   0   1  0
--  LW     |   1      1       1     0     0      1    ADD  0  0  0   0   1  0
--  SB     |   0      0       0     1     -      1    ADD  0  0  0   0   1  1
--  BEQ    |   0      0       0     0     -      -    SUB  1  0  0   0   1  1
--  J      |   0      0       0     0     -      -     -   0  1  0   -   0  0
--  other  |   all zero  (treated as NOP)
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity control_unit is
  port (
    opcode : in  opcode_t;
    funct  : in  funct_t;
    ctrl   : out ctrl_t
  );
end entity control_unit;

architecture rtl of control_unit is
begin
  process (opcode, funct)
    variable c : ctrl_t;
  begin
    c := CTRL_NOP;
    case opcode is
      when OP_RTYPE =>
        case funct is
          when FN_ADD | FN_NOR | FN_XOR | FN_SLL =>
            c.reg_write := '1';
            c.reg_dst   := '1';
            c.uses_rs   := '1';
            c.uses_rt   := '1';
            case funct is
              when FN_ADD => c.alu_op := ALU_ADD;
              when FN_NOR => c.alu_op := ALU_NOR;
              when FN_XOR => c.alu_op := ALU_XOR;
              when others => c.alu_op := ALU_SLL; c.uses_rs := '0';
            end case;
          when FN_JR =>
            c.jump_reg := '1';
            c.uses_rs  := '1';
          when others =>
            null;  -- unsupported funct: NOP
        end case;

      when OP_ANDI =>
        c.reg_write := '1'; c.alu_src := '1'; c.alu_op := ALU_AND;
        c.ext_zero  := '1'; c.uses_rs := '1';

      when OP_SUBUI =>
        c.reg_write := '1'; c.alu_src := '1'; c.alu_op := ALU_SUB;
        c.uses_rs   := '1';

      when OP_LW =>
        c.reg_write := '1'; c.mem_to_reg := '1'; c.mem_read := '1';
        c.alu_src   := '1'; c.alu_op := ALU_ADD; c.uses_rs := '1';

      when OP_SB =>
        c.mem_write := '1'; c.alu_src := '1'; c.alu_op := ALU_ADD;
        c.uses_rs   := '1'; c.uses_rt := '1';

      when OP_BEQ =>
        c.branch  := '1'; c.alu_op := ALU_SUB;
        c.uses_rs := '1'; c.uses_rt := '1';

      when OP_J =>
        c.jump := '1';

      when others =>
        null;  -- unsupported opcode: NOP
    end case;
    ctrl <= c;
  end process;
end architecture rtl;
