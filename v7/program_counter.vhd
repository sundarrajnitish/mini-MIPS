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
        pc_write: in std_logic;
        branch_address: in std_logic_vector(31 downto 0);
		output_address: out std_logic_vector(31 downto 0)
        
	);
end program_counter;

architecture behavioral of program_counter is

	signal next_address: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";

        begin
		process (clk, pc_write, branch_address)
		begin
            if rising_edge(clk) and pc_write = '0' then
			output_address <= next_address;
            next_address <= next_address + 4;
            report "Current Address Forwarded and PC Incremented by 4";
            elsif rising_edge(clk) and pc_write = '1' then
            output_address <= branch_address;
            next_address <= branch_address + 4;
			end if;
		end process;

end behavioral;
