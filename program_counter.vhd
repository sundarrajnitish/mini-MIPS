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

entity pc is
	port(
		ck: in std_logic;
		current_address: out std_logic_vector(31 downto 0)
	);
end pc;

architecture beh of pc is

	signal next_address: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";

	begin
		process (ck)
		begin
			if (ck'event and ck = '1') then
			case next_address is
				when "00000000000000000000000000000000" => 
					current_address <= "00000000000000000000000000000000";
					next_address <= next_address + 4;

				when others =>
					current_address <= next_address;
					next_address <= next_address + 4; 
					
			end case;
			end if;
				
		end process;

end beh;

