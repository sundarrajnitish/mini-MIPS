------------------------------------------------------------------------------
-- ID/EX pipeline register
--   bubble = '1' : load a NOP (valid = 0, all control = 0). Used on a stall;
--                  this is the "0" input of the control MUX in the diagram.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity id_ex_register is
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    bubble : in  std_logic;
    d      : in  id_ex_t;
    q      : out id_ex_t
  );
end entity id_ex_register;

architecture rtl of id_ex_register is
  signal r : id_ex_t := ID_EX_RESET;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or bubble = '1' then
        r <= ID_EX_RESET;
      else
        r <= d;
      end if;
    end if;
  end process;
  q <= r;
end architecture rtl;
