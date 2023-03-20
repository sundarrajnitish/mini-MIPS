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
		pc_clk: in std_logic;
		pc_address_in: in std_logic_vector(31 downto 0);
		pc_address_out: out std_logic_vector(31 downto 0)
	);
end program_counter;

architecture behavioral of program_counter is
	signal pc_address: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";
	signal pc_test_address: std_logic_vector(31 downto 0):= "00000000000000000000000000000000"; -- for testing

	begin
	process(pc_clk)
		begin
		if pc_address_in = "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" then
			pc_address <= "00000000000000000000000000000000";
		else
			pc_address <= pc_address_in;
			end if;
		if pc_clk = '1' then
			pc_test_address <= pc_test_address + 4;
			pc_address_out <= pc_address + 4;
		end if;
	end process;

end behavioral;

