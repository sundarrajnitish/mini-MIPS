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
        pc_flush: in std_logic;

        input_address: in std_logic_vector(31 downto 0);
        next_address: out std_logic_vector(31 downto 0) := (others => '0');
		output_address: out std_logic_vector(31 downto 0)
        
	);
end program_counter;

architecture behavioral of program_counter is

	--signal temp_next_address: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";
        begin
		process (clk, pc_flush)
		begin
            if pc_flush = '1' and clk = '1' then
                next_address <= "11111111111111111111111111111111";
                output_address <= "11111111111111111111111111111111";
                report "PC FLUSHED / STALLED";
            end if; 
            if clk = '1' and pc_flush = '0' then
			output_address <= input_address;
            next_address <= input_address + 4;
            report "Current Address Forwarded and PC Incremented by 4";
			end if;
		end process;

end behavioral;
