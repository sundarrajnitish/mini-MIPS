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

entity address_buffer is
    port ( 
        clk : in std_logic;

        pc_4 : in std_logic_vector(31 downto 0);
        branch_address : in std_logic_vector(31 downto 0);
        load_address : in std_logic_vector(31 downto 0);
        jump_address : in std_logic_vector(31 downto 0);
        jump_reg_address : in std_logic_vector(31 downto 0);
        
        pc_4_out : out std_logic_vector(31 downto 0);
        branch_address_out : out std_logic_vector(31 downto 0);
        load_address_out : out std_logic_vector(31 downto 0);
        jump_address_out : out std_logic_vector(31 downto 0);
        jump_reg_address_out : out std_logic_vector(31 downto 0)
        
        

    );
end address_buffer;

architecture behavioral of address_buffer is
begin
    process(clk, pc_4, branch_address, load_address, jump_address, jump_reg_address)
    begin
        if falling_edge(clk) then
                pc_4_out <= pc_4;
                branch_address_out <= branch_address;
                load_address_out <= load_address;
                jump_address_out <= jump_address;
                jump_reg_address_out <= jump_reg_address;
        end if;
    end process;
end behavioral;

-- Address buffer for the pipeline
