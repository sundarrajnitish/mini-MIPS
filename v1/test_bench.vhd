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

entity test_bench is
    port(
        clk : in std_logic
    );
end test_bench;

architecture behavioral of test_bench is

    signal pc_op: std_logic_vector(1 downto 0);
    signal address_in: std_logic_vector(31 downto 0);
    signal target_address: std_logic_vector(31 downto 0);
    signal address_out: std_logic_vector(31 downto 0);

    signal input_address : std_logic_vector(31 downto 0);
    signal output_address : std_logic_vector(31 downto 0);

    signal read_address: std_logic_vector(31 downto 0);
    signal instruction: std_logic_vector(31 downto 0);

    -- The clock for the other components; starts when the state is ready
	signal en: std_logic:= '0';


    component program_counter
		port (
			clk: in std_logic;
		    pc_op: in std_logic_vector(1 downto 0);
		    address_in: in std_logic_vector(31 downto 0);
		    target_address: in std_logic_vector(31 downto 0);
		    address_out: out std_logic_vector(31 downto 0)
		);
	end component;

    component fetch_incrementer
        port (
            clk : in std_logic;
            address_out : in std_logic_vector(31 downto 0);
            output_address : out std_logic_vector(31 downto 0)
        );
    end component;

	component instruction_memory
		port (
			address_out: in STD_LOGIC_VECTOR (31 downto 0);
		    instruction: out STD_LOGIC_VECTOR (31 downto 0)
		);
	end component;

    begin

	en <= '1' when clk'event and clk = '1' else '0';

    PC: program_counter port map (en, pc_op, address_in, target_address, address_out); 

    FI: fetch_incrementer port map (en, address_out, output_address);

	IM: instruction_memory port map (address_out, instruction => instruction);

    end behavioral;