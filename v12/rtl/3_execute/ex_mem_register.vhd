------------------------------------------------------------------------------
-- EX/MEM pipeline register (no flush needed: control hazards are resolved
-- in ID, so a wrong-path instruction never reaches EX)
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity ex_mem_register is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    d   : in  ex_mem_t;
    q   : out ex_mem_t
  );
end entity ex_mem_register;

architecture rtl of ex_mem_register is
  signal r : ex_mem_t := EX_MEM_RESET;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r <= EX_MEM_RESET;
      else
        r <= d;
      end if;
    end if;
  end process;
  q <= r;
end architecture rtl;
