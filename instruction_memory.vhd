------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_memory is
	port (
		read_address: in STD_LOGIC_VECTOR (31 downto 0);
		instruction: out STD_LOGIC_VECTOR (31 downto 0)
	);
end instruction_memory;


architecture behavioral of instruction_memory is	

--signal next_address: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";

begin

	process (read_address)
	begin
		case read_address is
			when "00000000000000000000000000000000" => 
				instruction <= "00100000000010000000000000000111";
                --next_address <= read_address;
			when "00000000000000000000000000000100" => 
                instruction <= "00100000000010010000000000000110";
                --next_address <= read_address;
			when "00000000000000000000000000001100" => 
                instruction <= "00010101000010010000000000000010";
                --next_address <= read_address;
            when "00000000000000000000000000001000" => 
                instruction <= "00100000000010000000000000001000";
                --next_address <= read_address;
            when "00000000000000000000000000010100" => 
                instruction <= "00100000000010010000000000001000";
                --next_address <= read_address;
			when others => 
                instruction <= "11111111111111111111111111111111";
                --next_address <= read_address;
		end case;

	end process;
    

end behavioral;