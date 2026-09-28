------------------------------------------------------------------------------
-- Register File: 32 x 32-bit, 2 asynchronous read ports, 1 synchronous
-- write port.
--   * $0 is hard-wired to zero (writes to $0 are ignored).
--   * Internal write-through bypass: if WB writes the register that ID is
--     reading in the same cycle, the new value is returned. This is the RTL
--     equivalent of the textbook "write in the first half of the cycle, read
--     in the second half" and removes the need for a separate WB buffer.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mips_pkg.all;

entity register_file is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    ra1       : in  reg_addr_t;
    ra2       : in  reg_addr_t;
    rd1       : out word_t;
    rd2       : out word_t;
    we        : in  std_logic;
    wa        : in  reg_addr_t;
    wd        : in  word_t
  );
end entity register_file;

architecture rtl of register_file is
  signal regs : reg_array_t := (others => ZERO_WORD);

  function read_port(signal r : reg_array_t; ra : reg_addr_t;
                     we_i : std_logic; wa_i : reg_addr_t; wd_i : word_t)
    return word_t is
  begin
    if ra = REG_ZERO then
      return ZERO_WORD;
    elsif we_i = '1' and wa_i = ra then
      return wd_i;                       -- write-through bypass
    else
      return r(to_integer(unsigned(ra)));
    end if;
  end function;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        regs <= (others => ZERO_WORD);
      elsif we = '1' and wa /= REG_ZERO then
        regs(to_integer(unsigned(wa))) <= wd;
      end if;
    end if;
  end process;

  rd1 <= read_port(regs, ra1, we, wa, wd);
  rd2 <= read_port(regs, ra2, we, wa, wd);
end architecture rtl;
