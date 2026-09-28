------------------------------------------------------------------------------
-- Jump MUX (second next-PC mux of the datapath diagram)
--   sel = "00" : output of the branch mux
--   sel = "01" : J  target  = {PC+4[31:28], target26, "00"}
--   sel = "10" : JR target  = forwarded value of rs
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity jump_mux is
  port (
    from_branch : in  word_t;
    jump_target : in  word_t;
    jr_target   : in  word_t;
    sel         : in  std_logic_vector(1 downto 0);
    y           : out word_t
  );
end entity jump_mux;

architecture rtl of jump_mux is
begin
  with sel select
    y <= jump_target when "01",
         jr_target   when "10",
         from_branch when others;
end architecture rtl;
