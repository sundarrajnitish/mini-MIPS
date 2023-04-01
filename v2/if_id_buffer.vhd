------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity if_id_buffer is
    Port (clk, reset, enable : in std_logic;
          pc_in, instruction_in : in std_logic_vector(31 downto 0);
          pc_out, instruction_out : out std_logic_vector(31 downto 0):= (others => '0'));
end if_id_buffer;

architecture behavioral of if_id_buffer is
    
    type if_id_buffer_type is record
    pc : std_logic_vector(31 downto 0);
    instruction : std_logic_vector(31 downto 0);
    end record;

    signal if_id_buffer_reg : if_id_buffer_type := (pc => (others => '0'), instruction => (others => '0'));

    begin
    process (clk, reset)
    begin
        if reset = '1' then
            if_id_buffer_reg.pc <= (others => '0');
            if_id_buffer_reg.instruction <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                if_id_buffer_reg.pc <= pc_in;
                if_id_buffer_reg.instruction <= instruction_in;
            end if;
        end if;
    end process;

pc_out <= if_id_buffer_reg.pc;
instruction_out <= if_id_buffer_reg.instruction;

end architecture behavioral;