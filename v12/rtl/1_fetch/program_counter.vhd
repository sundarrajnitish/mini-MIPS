------------------------------------------------------------------------------
-- Program Counter: 32-bit register with synchronous reset and write enable.
-- pc_write = '0' freezes the PC during a load-use / branch-operand stall.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity program_counter is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    pc_write : in  std_logic;
    next_pc  : in  word_t;
    pc       : out word_t
  );
end entity program_counter;

architecture rtl of program_counter is
  signal pc_q : word_t := ZERO_WORD;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        pc_q <= ZERO_WORD;
      elsif pc_write = '1' then
        pc_q <= next_pc;
      end if;
    end if;
  end process;
  pc <= pc_q;
end architecture rtl;
