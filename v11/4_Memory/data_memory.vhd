------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_memory is
    port(
        clk: in std_logic;

        mem_address: in std_logic_vector(31 downto 0);
        write_data: in std_logic_vector(31 downto 0);

        
        mem_write: in std_logic;
        mem_read: in std_logic;
       -- mem_reg_write: in std_logic; -- has to be in the write back stage

        read_data: out std_logic_vector(31 downto 0)
    );
end data_memory;

architecture behavioral of data_memory is

    type memory_array is array (0 to 1023) of std_logic_vector(31 downto 0);
    signal memory: memory_array := (others => (others => '0'));

    signal temp_data: std_logic_vector(31 downto 0);

    begin
    process (clk, mem_write, mem_read, mem_address, write_data)
	begin
        if rising_edge(clk) then
            case mem_write is
                when '1' =>
                    temp_data <= memory(to_integer(unsigned(mem_address)));
                    temp_data(7 downto 0) <= write_data(7 downto 0);
                    memory(to_integer(unsigned(mem_address))) <= temp_data;
                    report "Byte stored in the memory";
                when others =>
                    null;
        end case;
        case mem_read is
            when '1' =>
                read_data <= memory(to_integer(unsigned(mem_address)));
                report "Data read from the memory";
            when others =>
                null;
        end case;
        end if;
    end process;

    end behavioral;

            
		