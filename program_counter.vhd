------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity program_counter is
	port(
		clk: in std_logic;
		address_in: in std_logic_vector(3 downto 0);
		address_out: out std_logic_vector(3 downto 0)
	);
end program_counter;

architecture behavioral of program_counter is
	signal address: std_logic_vector(3 downto 0):= "0000";
	signal test_address: std_logic_vector(3 downto 0):= "0000";

	begin
	process(clk)
		begin
		if address_in = "UUUU" then
			address <= "0000";
		else
			address <= address_in;
			end if;
		if clk='1' then
			test_address <= test_address + 4;
			address_out <= address + 4;
		end if;
	end process;

end behavioral;

