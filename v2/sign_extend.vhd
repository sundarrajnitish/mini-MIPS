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

entity sign_extend is
  port (
    input_data : in std_logic_vector(15 downto 0);
    output_data : out std_logic_vector(31 downto 0)
  );
end entity sign_extend;

architecture behavioral of sign_extend is
begin
  process(input_data)
  begin
    if input_data(15) = '1' then -- check the MSB if it is 1, value is negative according to 2's complement
    output_data <= std_logic_vector(resize(signed(input_data), 32));
    else -- check the MSB if it is 0, value is positive according to 2's complement
    output_data <= std_logic_vector(resize(unsigned(input_data), 32));
    end if;
  end process;
end architecture behavioral;
