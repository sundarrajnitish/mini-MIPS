------------------------------------------------------------------------------
-- ALU (combinational)
--   ADD : a + b          AND : a and b       XOR : a xor b
--   NOR : a nor b        SLL : b << shamt    SUB : a - b
-- All arithmetic is modulo 2^32 (no overflow traps, like ADDU/SUBU).
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mips_pkg.all;

entity alu is
  port (
    op     : in  alu_op_t;
    a      : in  word_t;
    b      : in  word_t;
    shamt  : in  std_logic_vector(4 downto 0);
    result : out word_t;
    zero   : out std_logic
  );
end entity alu;

architecture rtl of alu is
  signal r : word_t;
begin
  process (op, a, b, shamt)
  begin
    case op is
      when ALU_ADD => r <= std_logic_vector(unsigned(a) + unsigned(b));
      when ALU_AND => r <= a and b;
      when ALU_XOR => r <= a xor b;
      when ALU_NOR => r <= a nor b;
      when ALU_SLL => r <= std_logic_vector(shift_left(unsigned(b), to_integer(unsigned(shamt))));
      when ALU_SUB => r <= std_logic_vector(unsigned(a) - unsigned(b));
      when others  => r <= ZERO_WORD;
    end case;
  end process;
  result <= r;
  zero   <= '1' when r = ZERO_WORD else '0';
end architecture rtl;
