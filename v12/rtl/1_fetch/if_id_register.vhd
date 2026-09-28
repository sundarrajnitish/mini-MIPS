------------------------------------------------------------------------------
-- IF/ID pipeline register
--   write = '0' : hold (stall)            -- has priority over flush
--   flush = '1' : insert a bubble (taken branch / J / JR squashes the
--                 wrong-path instruction that was just fetched)
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity if_id_register is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    write : in  std_logic;
    flush : in  std_logic;
    d     : in  if_id_t;
    q     : out if_id_t
  );
end entity if_id_register;

architecture rtl of if_id_register is
  signal r : if_id_t := IF_ID_RESET;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r <= IF_ID_RESET;
      elsif write = '1' then
        if flush = '1' then
          r <= IF_ID_RESET;
        else
          r <= d;
        end if;
      end if;
    end if;
  end process;
  q <= r;
end architecture rtl;
