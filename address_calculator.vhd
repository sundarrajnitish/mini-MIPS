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

entity address_calc is
  port (
    base_address : in std_logic_vector(31 downto 0);
    shift_address : in std_logic_vector(31 downto 0);
    output_address : out std_logic_vector(31 downto 0)
  );
end entity address_calc;

architecture behavioral of address_calc is
begin
  process(base_address, shift_address)
  variable temp_address : unsigned(63 downto 0);
  begin
    temp_address := unsigned(base_address) + (unsigned(shift_address) * 4);
    output_address <= std_logic_vector(temp_address(31 downto 0));
    --std_logic_vector(temp_address(31 downto 0));
  end process;
end architecture behavioral;