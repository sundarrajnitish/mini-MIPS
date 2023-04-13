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
        clk: in STD_LOGIC;
		read_address: in STD_LOGIC_VECTOR (31 downto 0);
		instruction: out STD_LOGIC_VECTOR (31 downto 0)
	);
end instruction_memory;


architecture behavioral of instruction_memory is	

begin

	process (clk, read_address)
	begin
        if rising_edge(clk) then
		case read_address is
			when "00000000000000000000000000000000" => 
				instruction <= "10001100100101000000000000011000";
			when "00000000000000000000000000000100" => 
                instruction <= "00000001101001010011000000100000";
            when "00000000000000000000000000001000" => 
                instruction <= "00000001001000110101100000100111";
			when "00000000000000000000000000001100" => 
                instruction <= "00000000010011000010000101000000";
            when "00000000000000000000000000010100" => 
                instruction <= "00000000111011110001100000100110";
			when "00000000000000000000000000011000" => 
				instruction <= "00110001010000010000000000000010";
			when "00000000000000000000000000011100" => 
				instruction <= "00110000110010110000000000000101";
			when "00000000000000000000000000100000" => 
				instruction <= "00110000010101010000000000001000";
			when "00000000000000000000000000100100" => 
				instruction <= "00000011100111011000100000100000";
			when "00000000000000000000000000101000" => 
				instruction <= "00000010001110111100000000100111";
			when "00000000000000000000000000101100" => 
				instruction <= "00010001100100100000000000000011";
			when "00000000000000000000000000110000" => 
				instruction <= "00000000110001110010100000100000";
			when "00000000000000000000000000110100" => 
				-- your code here
			when "00000000000000000000000000111000" => 
				-- your code here
			when "00000000000000000000000000111100" => 
				-- your code here
			when "00000000000000000000000001000000" => 
				-- your code here
			when "00000000000000000000000001000100" => 
				-- your code here
			when "00000000000000000000000001001000" => 
				-- your code here
			when "00000000000000000000000001001100" => 
				-- your code here
			when "00000000000000000000000001010000" => 
				-- your code here
			when "00000000000000000000000001010100" => 
				-- your code here
			when "00000000000000000000000001011000" => 
				-- your code here
			when "00000000000000000000000001011100" => 
				-- your code here
			when "00000000000000000000000001100000" => 
				-- your code here
			when "00000000000000000000000001100100" => 
				-- your code here
			when "00000000000000000000000001101000" => 
				-- your code here
			when "00000000000000000000000001101100" => 
				-- your code here
			when "00000000000000000000000001110000" => 
				-- your code here
			when "00000000000000000000000001110100" => 
				-- your code here
			when "00000000000000000000000001111000" => 
				-- your code here
			when "00000000000000000000000001111100" => 
				-- your code here
			when others => 
                instruction <= "11111111111111111111111111111111"; --invalid instruction
		end case;
        end if;
	end process;
    

end behavioral;

