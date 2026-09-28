------------------------------------------------------------------------------
-- Branch / Jump resolution in ID (the "Shift left 2" + adder + comparator)
--   branch_target = PC+4 + (sign_ext(imm16) << 2)
--   jump_target   = {PC+4[31:28], target26, "00"}
--   equal         = (rs_val = rt_val)   -- operands come from MUX E / MUX F
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mips_pkg.all;

entity branch_unit is
  port (
    pc_plus4      : in  word_t;
    imm16         : in  std_logic_vector(15 downto 0);
    target26      : in  std_logic_vector(25 downto 0);
    rs_val        : in  word_t;
    rt_val        : in  word_t;
    branch_target : out word_t;
    jump_target   : out word_t;
    equal         : out std_logic
  );
end entity branch_unit;

architecture rtl of branch_unit is
  signal offset : signed(31 downto 0);
begin
  offset        <= shift_left(resize(signed(imm16), 32), 2);
  branch_target <= std_logic_vector(signed(pc_plus4) + offset);
  jump_target   <= pc_plus4(31 downto 28) & target26 & "00";
  equal         <= '1' when rs_val = rt_val else '0';
end architecture rtl;
