------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jump_address_calc is
  port (
    input_address : in std_logic_vector(25 downto 0);
    pc_concat : in std_logic_vector(3 downto 0);
    jump_address : out std_logic_vector(31 downto 0)
  );
end jump_address_calc;

architecture behavioral of jump_address_calc is

    signal shift_lefted : std_logic_vector(27 downto 0) := (others => '0');

    begin
    process (input_address, pc_concat)
    begin
        shift_lefted <= input_address & "00";
        jump_address <= pc_concat & shift_lefted; 
    end process;
    end behavioral;
