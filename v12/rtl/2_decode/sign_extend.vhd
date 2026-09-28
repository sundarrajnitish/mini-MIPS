------------------------------------------------------------------------------
-- Immediate extender (16 -> 32 bits)
--   zero_ext = '1' : zero-extend  (ANDI, logical immediates as in MIPS)
--   zero_ext = '0' : sign-extend  (SUBUI, LW, SB, BEQ)
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mips_pkg.all;

entity sign_extend is
  port (
    imm16    : in  std_logic_vector(15 downto 0);
    zero_ext : in  std_logic;
    imm32    : out word_t
  );
end entity sign_extend;

architecture rtl of sign_extend is
begin
  imm32 <= std_logic_vector(resize(unsigned(imm16), 32)) when zero_ext = '1'
      else std_logic_vector(resize(signed(imm16), 32));
end architecture rtl;
