------------------------------------------------------------------------------
-- Forwarding Unit (combinational)
--
-- EX-stage forwarding (MUX C -> ALU input A, MUX D -> ALU input B / store data)
--   priority 1: EX/MEM.RegWrite and EX/MEM.dest /= 0 and EX/MEM.dest = src
--   priority 2: MEM/WB.RegWrite and MEM/WB.dest /= 0 and MEM/WB.dest = src
--   (the most recent producer wins)
--
-- ID-stage forwarding (MUX E -> rs, MUX F -> rt ; feeds the BEQ comparator,
-- the JR target and ID/EX)
--   EX/MEM.RegWrite and not EX/MEM.MemRead and EX/MEM.dest /= 0 and match.
--   A load in EX/MEM has no data yet (its alu_result is the address), so it
--   is never forwarded here; the hazard unit stalls instead when needed.
--   MEM/WB -> ID is covered by the register-file write-through bypass.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity forwarding_unit is
  port (
    -- EX stage sources
    ex_rs         : in  reg_addr_t;
    ex_rt         : in  reg_addr_t;
    -- ID stage sources
    id_rs         : in  reg_addr_t;
    id_rt         : in  reg_addr_t;
    -- producers
    mem_reg_write : in  std_logic;
    mem_mem_read  : in  std_logic;
    mem_dest      : in  reg_addr_t;
    wb_reg_write  : in  std_logic;
    wb_dest       : in  reg_addr_t;
    -- selects
    fwd_a         : out fwd_sel_t;   -- MUX C
    fwd_b         : out fwd_sel_t;   -- MUX D
    fwd_e         : out std_logic;   -- MUX E
    fwd_f         : out std_logic    -- MUX F
  );
end entity forwarding_unit;

architecture rtl of forwarding_unit is
  function ex_sel(src : reg_addr_t; m_we : std_logic; m_d : reg_addr_t;
                  w_we : std_logic; w_d : reg_addr_t) return fwd_sel_t is
  begin
    if m_we = '1' and m_d /= REG_ZERO and m_d = src then
      return FWD_EX_MEM;
    elsif w_we = '1' and w_d /= REG_ZERO and w_d = src then
      return FWD_MEM_WB;
    else
      return FWD_NONE;
    end if;
  end function;

  function id_sel(src : reg_addr_t; m_we, m_rd : std_logic; m_d : reg_addr_t)
    return std_logic is
  begin
    if m_we = '1' and m_rd = '0' and m_d /= REG_ZERO and m_d = src then
      return '1';
    else
      return '0';
    end if;
  end function;
begin
  fwd_a <= ex_sel(ex_rs, mem_reg_write, mem_dest, wb_reg_write, wb_dest);
  fwd_b <= ex_sel(ex_rt, mem_reg_write, mem_dest, wb_reg_write, wb_dest);
  fwd_e <= id_sel(id_rs, mem_reg_write, mem_mem_read, mem_dest);
  fwd_f <= id_sel(id_rt, mem_reg_write, mem_mem_read, mem_dest);
end architecture rtl;
