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

entity branch_address_calc is
  port (
    pc_4 : in std_logic_vector(31 downto 0);
    immediate_32 : in std_logic_vector(31 downto 0);
    branch_address : out std_logic_vector(31 downto 0)
  );
end branch_address_calc;

architecture behavioral of branch_address_calc is

    begin
    process (pc_4, immediate_32)
        
    begin
        branch_address <= std_logic_vector(unsigned(pc_4) + unsigned(immediate_32));
    end process;
    end behavioral;
