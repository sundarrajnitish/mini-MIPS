------------------------------------------------------------------------------
-- Branch MUX (first next-PC mux of the datapath diagram)
--   sel = '0' : PC + 4
--   sel = '1' : branch target (BEQ taken, resolved in ID)
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity branch_mux is
  port (
    pc_plus4      : in  word_t;
    branch_target : in  word_t;
    sel           : in  std_logic;
    y             : out word_t
  );
end entity branch_mux;

architecture rtl of branch_mux is
begin
  y <= branch_target when sel = '1' else pc_plus4;
end architecture rtl;
