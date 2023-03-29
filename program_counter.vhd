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
		pc_op: in std_logic_vector(1 downto 0);
		address_in: in std_logic_vector(31 downto 0);
		target_address: in std_logic_vector(31 downto 0);
		address_out: out std_logic_vector(31 downto 0)
	);
end program_counter;

architecture behavioral of program_counter is

	begin
		process (clk)
		begin
			if (clk'event and clk = '1') then
			case pc_op is
				when "00" => --indicates pc value should be an incremented value of the previous pc value
					address_out <= address_in;
				when "01" => --indicates that pc should be updated to target or branch address
					address_out <= target_address;
				when others =>
					null;
			end case;
			end if;
				
		end process;

end behavioral;

