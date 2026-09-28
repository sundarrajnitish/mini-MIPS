------------------------------------------------------------------------------
-- Hazard Detection Unit (combinational, lives in ID)
--
-- 1. Load-use hazard
--      ID/EX is a load (MemRead) whose destination is a source of the
--      instruction in ID  -> stall 1 cycle. The loaded value is then
--      forwarded from MEM/WB into EX.
--
-- 2. Branch / JR operand hazard (operands are needed already in ID)
--      a) ID/EX will write a source register (any RegWrite)  -> stall
--         (the ALU result only exists at the end of EX)
--      b) EX/MEM is a load writing a source register         -> stall
--         (the loaded value only exists at the end of MEM)
--      An ALU result sitting in EX/MEM is forwarded through MUX E / F,
--      a value in MEM/WB comes through the register-file bypass.
--      => BEQ/JR after an ALU op: 1 stall; right after a load: 2 stalls.
--
-- Stall  : PC and IF/ID hold, a bubble (all-zero control) enters ID/EX.
--
-- 3. Control hazards (only acted upon when not stalling)
--      BEQ taken / J / JR are resolved in ID: next PC is redirected and the
--      single wrong-path instruction in IF/ID is flushed (1-cycle penalty).
--      Branches are statically predicted not-taken.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity hazard_unit is
  port (
    -- instruction in ID
    id_valid       : in  std_logic;
    id_ctrl        : in  ctrl_t;
    id_rs          : in  reg_addr_t;
    id_rt          : in  reg_addr_t;
    id_equal       : in  std_logic;
    -- instruction in EX
    ex_reg_write   : in  std_logic;
    ex_mem_read    : in  std_logic;
    ex_dest        : in  reg_addr_t;
    -- instruction in MEM
    mem_mem_read   : in  std_logic;
    mem_dest       : in  reg_addr_t;
    -- outputs
    stall          : out std_logic;   -- PCWrite = IF/IDWrite = not stall
    if_flush       : out std_logic;
    pc_sel         : out pc_sel_t
  );
end entity hazard_unit;

architecture rtl of hazard_unit is
  function reads(ctrl : ctrl_t; rs, rt, r : reg_addr_t) return boolean is
  begin
    return r /= REG_ZERO and
           ((ctrl.uses_rs = '1' and rs = r) or (ctrl.uses_rt = '1' and rt = r));
  end function;
begin
  process (all)
    variable load_use, branch_haz, s : boolean;
  begin
    load_use   := ex_mem_read = '1' and reads(id_ctrl, id_rs, id_rt, ex_dest);

    branch_haz := (id_ctrl.branch = '1' or id_ctrl.jump_reg = '1') and
                  ((ex_reg_write = '1' and reads(id_ctrl, id_rs, id_rt, ex_dest)) or
                   (mem_mem_read = '1' and reads(id_ctrl, id_rs, id_rt, mem_dest)));

    s := id_valid = '1' and (load_use or branch_haz);

    stall    <= '0';
    if_flush <= '0';
    pc_sel   <= PC_PLUS4;

    if s then
      stall <= '1';
    elsif id_valid = '1' then
      if id_ctrl.branch = '1' and id_equal = '1' then
        pc_sel <= PC_BRANCH; if_flush <= '1';
      elsif id_ctrl.jump = '1' then
        pc_sel <= PC_JUMP;   if_flush <= '1';
      elsif id_ctrl.jump_reg = '1' then
        pc_sel <= PC_JR;     if_flush <= '1';
      end if;
    end if;
  end process;
end architecture rtl;
