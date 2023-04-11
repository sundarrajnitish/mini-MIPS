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
        address_in: in std_logic_vector(31 downto 0);

        current_address: out std_logic_vector(31 downto 0);
		next_address: out std_logic_vector(31 downto 0)
        
	);
end program_counter;

architecture behavioral of program_counter is

        signal temp_address: std_logic_vector(31 downto 0) := (others => '0');

        begin
        --next_address <= (others => '0');
		process (clk, address_in)
		begin
            if rising_edge(clk) then
                case address_in is
                    when "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" | "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" => 
                    current_address <= temp_address;
                    next_address <= temp_address + 4;
                when others =>
                    current_address <= address_in;
                    next_address <= address_in + 4;
                end case;
            end if;

		end process;

end behavioral;
