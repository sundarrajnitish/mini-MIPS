------------------------------------------------------------------------------
-- MEM/WB pipeline register
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity mem_wb_register is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    d   : in  mem_wb_t;
    q   : out mem_wb_t
  );
end entity mem_wb_register;

architecture rtl of mem_wb_register is
  signal r : mem_wb_t := MEM_WB_RESET;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r <= MEM_WB_RESET;
      else
        r <= d;
      end if;
    end if;
  end process;
  q <= r;
end architecture rtl;
