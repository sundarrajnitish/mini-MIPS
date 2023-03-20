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
        im_clk: in STD_LOGIC;
		im_address_in: in STD_LOGIC_VECTOR (31 downto 0);
        im_write_data: in STD_LOGIC_VECTOR (31 downto 0);
		im_instruction_out_1, im_instruction_out_2: out STD_LOGIC_VECTOR (31 downto 0)
	);
end instruction_memory;

architecture Behavioral of instruction_memory is
    type instruction_array is array(0 to 31) of STD_LOGIC_VECTOR (31 downto 0);
    signal instruction_memory: instruction_array := (
        "10001110001010100000000000001000", -- lw r10, 8(r1)
        "00000000010000110101100000100010", -- sub r11, r2, r3
        "00000000100001010110000000100100", -- add r12, r4, r5
        "00000000110001110110100000100101", -- or r13, r6, r7
        "00000001000010010111000000100000", -- add r14, r8, r9
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000", -- no operation
        "00000000000000000000000000000000" -- 32 instructions
    );

    begin
        im_instruction_out_1 = instruction_memory(to_integer(unsigned(im_address_in)));
        im_instruction_out_2 = instruction_memory(to_integer(unsigned(im_address_in)));

    process(im_clk)
    begin
        if im_clk = '1' then
            instruction_memory(to_integer(unsigned(im_address_in))) <= im_write_data;
        end if;
    end process;


end Behavioral;