------------------------------------------------------------------------------
-- Write-back MUX: MemtoReg = '1' selects the loaded word, else the ALU result
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity wb_mux is
  port (
    read_data  : in  word_t;
    alu_result : in  word_t;
    mem_to_reg : in  std_logic;
    y          : out word_t
  );
end entity wb_mux;

architecture rtl of wb_mux is
begin
  y <= read_data when mem_to_reg = '1' else alu_result;
end architecture rtl;
