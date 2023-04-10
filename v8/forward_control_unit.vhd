------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forward_control_unit is
    port(
        clk : in std_logic;

        rs : in std_logic_vector(4 downto 0);
        rt : in std_logic_vector(4 downto 0);

        opcode_exmem : in std_logic_vector(5 downto 0);
        alu_result_exmem : in std_logic_vector(31 downto 0);
        rd_exmem : in std_logic_vector(4 downto 0);
        alu_result_memwb : in std_logic_vector(31 downto 0);
        rd_memwb : in std_logic_vector(4 downto 0);
        read_data_reg : in std_logic_vector(31 downto 0);

        forward_signal_rs : out std_logic;
        forward_data_rs : out std_logic_vector(31 downto 0);
        forward_signal_rt : out std_logic;
        forward_data_rt : out std_logic_vector(31 downto 0)

    );

end forward_control_unit;

architecture behavioral of forward_control_unit is

    begin 
    process (clk, rs, rt, opcode_exmem, alu_result_exmem, rd_exmem, alu_result_memwb, rd_memwb, read_data_reg)
    begin 
        if rising_edge(clk) then
            case opcode_exmem is
                when "100011" => 
                    case rd_exmem is
                        when rs =>
                            forward_signal_rs <= '1';
                            forward_data_rs <= read_data_reg;
                        when rt =>
                            forward_signal_rt <= '1';
                            forward_data_rt <= read_data_reg;
                        when others =>
                            forward_signal_rs <= '0';
                            forward_data_rs <= (others => '0');
                            forward_signal_rt <= '0';
                            forward_data_rt <= (others => '0');
                    end case;
                when others =>
            case rd_exmem is
                when rs => 
                    forward_signal_rs <= '1';
                    forward_data_rs <= alu_result_exmem;
                when rt =>
                    forward_signal_rt <= '1';
                    forward_data_rt <= alu_result_exmem;
                when others =>
                    forward_signal_rs <= '0';
                    forward_data_rs <= (others => '0');
                    forward_signal_rt <= '0';
                    forward_data_rt <= (others => '0');
            end case;

            case rd_memwb is
                when rs => 
                    forward_signal_rs <= '1';
                    forward_data_rs <= alu_result_memwb;
                when rt =>
                    forward_signal_rt <= '1';
                    forward_data_rt <= alu_result_memwb;
                when others =>
                    forward_signal_rs <= '0';
                    forward_data_rs <= (others => '0');
                    forward_signal_rt <= '0';
                    forward_data_rt <= (others => '0');
            end case;


