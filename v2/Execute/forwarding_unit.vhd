library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity forwarding_unit is
    port (
        -- Inputs
        rs_id          : in  std_logic_vector(4 downto 0); -- ID stage register-1 source register address
        rt_id          : in  std_logic_vector(4 downto 0); -- ID stage register-2 source register address
        ex_rd         : in  std_logic_vector(4 downto 0); -- EX stage destination register address
        mem_rd      : in  std_logic_vector(4 downto 0); -- MEM stage destination register address
        ex_mem_reg : in  std_logic_vector(1 downto 0); -- MUX selector for EX/MEM or MEM/WB forwarding
        mem_wb_reg : in  std_logic_vector(1 downto 0); -- MUX selector for MEM/WB forwarding
        -- Outputs
        ex_mem_fwd : out std_logic_vector(1 downto 0); -- MUX selector for EX/MEM forwarding
        mem_wb_fwd : out std_logic_vector(1 downto 0)  -- MUX selector for MEM/WB forwarding
    );
end forwarding_unit;

architecture Behavioral of forwarding_unit is
begin

    -- By default, the MUX selectors are set to 0, indicating no forwarding.
    ex_mem_fwd <= "00";
    mem_wb_fwd <= "00";

    -- Determine if the first input should be forwarded from EX/MEM or MEM/WB
    -- If ex_rd matches rs_id, then set ex_mem_fwd to 2'b10 (forward from EX/MEM)
    with ex_mem_reg select
        ex_mem_fwd <= "00" when "00", -- no forwarding
                             "10" when "01" and (ex_rd = rs_id) else "00"; -- forward from EX/MEM

    -- Determine if the second input should be forwarded from EX/MEM or MEM/WB
    -- If ex_rd matches rt_id, then set ex_mem_fwd to 2'b10 (forward from EX/MEM)
    with ex_mem_reg select
        ex_mem_fwd <= "00" when "00", -- no forwarding
                             "10" when "01" and (ex_rd = rt_id) else ex_mem_fwd; -- forward from EX/MEM

    -- Determine if the first input should be forwarded from MEM/WB
    -- If mem_rd matches rs_id and there is no forwarding from EX/MEM, then set mem_wb_fwd to 2'b10 (forward from MEM/WB)
    with mem_wb_reg select
        mem_wb_fwd <= "00" when "00", -- no forwarding
                             "10" when "01" and (mem_rd = rs_id) and (ex_mem_fwd(1) = '0') else "00"; -- forward from MEM/WB

    -- Determine if the second input should be forwarded from MEM/WB
    -- If mem_rd matches rt_id and there is no forwarding from EX/MEM or MEM/WB, then set mem_wb_fwd to 2'b10 (forward from MEM/WB)
    with mem_wb_reg select
        mem_wb_fwd <= "00" when "00", -- no forwarding
                             "10" when "01" and (mem_rd = rt_id) and (ex_mem_fwd(1) = '0') and (mem_wb_fwd(1) = '0') else mem_wb_fwd; -- forward from MEM/WB
