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

        rd_ex_mem : in std_logic_vector(4 downto 0);
        rd_mem_wb : in std_logic_vector(4 downto 0);

        alu_result_ex_mem : in std_logic_vector(31 downto 0);
        alu_result_mem_wb : in std_logic_vector(31 downto 0);
        read_data_mem_wb : in std_logic_vector(31 downto 0);

        mem_to_reg_mem_wb : in std_logic;

        --Decode Stage
        rs_if_id : in std_logic_vector(4 downto 0);
        rt_if_id : in std_logic_vector(4 downto 0);

        forward_signal_rs_if_id : out std_logic;
        forward_data_rs_if_id : out std_logic_vector(31 downto 0);
        forward_signal_rt_if_id : out std_logic;
        forward_data_rt_if_id : out std_logic_vector(31 downto 0);


        --Execute Stage
        rs_id_ex : in std_logic_vector(4 downto 0);
        rt_id_ex : in std_logic_vector(4 downto 0);

        forward_signal_rs_id_ex : out std_logic;
        forward_data_rs_id_ex : out std_logic_vector(31 downto 0);
        forward_signal_rt_id_ex : out std_logic;
        forward_data_rt_id_ex : out std_logic_vector(31 downto 0)
        

    );

end forward_control_unit;

architecture behavioral of forward_control_unit is

    begin 
    process (clk, rd_ex_mem, rd_mem_wb, alu_result_ex_mem, alu_result_mem_wb, read_data_mem_wb, mem_to_reg_mem_wb, rs_if_id, rt_if_id, rs_id_ex, rt_id_ex)
    --if rising_edge(clk) then
        --Decode Stage Forwarding
        --Rs
        begin
        if (rs_if_id = rd_ex_mem) then
            forward_signal_rs_if_id <= '1';
            forward_data_rs_if_id <= alu_result_ex_mem;
        elsif (rs_if_id = rd_mem_wb) then
            forward_signal_rs_if_id <= '1';
            if (mem_to_reg_mem_wb = '1') then
                forward_data_rs_if_id <= read_data_mem_wb;
            else
                forward_data_rs_if_id <= alu_result_mem_wb;
            end if;
        else
            forward_signal_rs_if_id <= '0';
            forward_data_rs_if_id <= (others => '0');
        end if;
        --Rt
        if (rt_if_id = rd_ex_mem) then
            forward_signal_rt_if_id <= '1';
            forward_data_rt_if_id <= alu_result_ex_mem;
        elsif (rt_if_id = rd_mem_wb) then
            forward_signal_rt_if_id <= '1';
            if (mem_to_reg_mem_wb = '1') then
                forward_data_rt_if_id <= read_data_mem_wb;
            else
                forward_data_rt_if_id <= alu_result_mem_wb;
            end if;
        else
            forward_signal_rt_if_id <= '0';
            forward_data_rt_if_id <= (others => '0');
        end if;
        --Execute Stage Forwarding
        --Rs
        if (rs_id_ex = rd_ex_mem) then
            forward_signal_rs_id_ex <= '1';
            forward_data_rs_id_ex <= alu_result_ex_mem;
        elsif (rs_id_ex = rd_mem_wb) then
            forward_signal_rs_id_ex <= '1';
            if (mem_to_reg_mem_wb = '1') then
                forward_data_rs_id_ex <= read_data_mem_wb;
            else
                forward_data_rs_id_ex <= alu_result_mem_wb;
            end if;
        else
            forward_signal_rs_id_ex <= '0';
            forward_data_rs_id_ex <= (others => '0');
        end if;
        --Rt
        if (rt_id_ex = rd_ex_mem) then
            forward_signal_rt_id_ex <= '1';
            forward_data_rt_id_ex <= alu_result_ex_mem;
        elsif (rt_id_ex = rd_mem_wb) then
            forward_signal_rt_id_ex <= '1';
            if (mem_to_reg_mem_wb = '1') then
                forward_data_rt_id_ex <= read_data_mem_wb;
            else
                forward_data_rt_id_ex <= alu_result_mem_wb;
            end if;
        else
            forward_signal_rt_id_ex <= '0';
            forward_data_rt_id_ex <= (others => '0');
        end if;
        end process;
    --end if;
end behavioral;


