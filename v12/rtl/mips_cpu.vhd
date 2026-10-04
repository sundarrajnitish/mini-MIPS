------------------------------------------------------------------------------
-- mini-MIPS : 5-stage pipelined processor (top level)
--
--   IF  : PC, instruction memory, PC+4 adder, branch MUX, jump MUX
--   ID  : control unit, register file, extender, hazard unit,
--         ID forwarding (MUX E / MUX F), branch comparator, target adders
--   EX  : EX forwarding (MUX C / MUX D), ALUSrc (MUX A), RegDst (MUX B), ALU
--   MEM : data memory (LW / SB)
--   WB  : write-back MUX -> register file
--
-- Single clock edge (rising), synchronous active-high reset. All stage logic
-- is combinational; only the PC, the four pipeline registers, the register
-- file and the data memory hold state.
--
-- Hazard summary
--   * RAW on ALU results       : forwarded (EX/MEM or MEM/WB -> EX), 0 stalls
--   * load-use                 : 1 stall, then MEM/WB -> EX forwarding
--   * BEQ/JR operand in EX     : 1 stall, then EX/MEM -> ID forwarding
--   * BEQ/JR operand from a LW : 2 stalls, then register-file bypass
--   * taken BEQ / J / JR       : 1 flushed slot (predict not-taken)
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mips_pkg.all;

entity mips_cpu is
  generic (
    IMEM_DEPTH : positive := 256;
    DMEM_DEPTH : positive := 1024;
    IMEM_FILE  : string   := "program.hex";
    DMEM_FILE  : string   := ""
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    dbg   : out debug_t
  );
end entity mips_cpu;

architecture rtl of mips_cpu is

  -- pipeline registers
  signal if_id  : if_id_t;
  signal id_ex  : id_ex_t;
  signal ex_mem : ex_mem_t;
  signal mem_wb : mem_wb_t;

  -- IF
  signal pc, pc_plus4, instr, branch_mux_out, next_pc : word_t;
  signal if_id_d : if_id_t;

  -- ID
  signal id_opcode : opcode_t;
  signal id_funct  : funct_t;
  signal id_rs, id_rt, id_rd : reg_addr_t;
  signal id_ctrl   : ctrl_t;
  signal rf_rd1, rf_rd2, id_rs_val, id_rt_val, id_imm : word_t;
  signal branch_target, jump_target : word_t;
  signal id_equal  : std_logic;
  signal stall, if_flush : std_logic;
  signal pc_sel    : pc_sel_t;
  signal fwd_e, fwd_f : std_logic;
  signal id_ex_d   : id_ex_t;
  signal jump_sel  : std_logic_vector(1 downto 0);
  signal branch_sel, pc_write : std_logic;

  -- EX
  signal fwd_a, fwd_b : fwd_sel_t;
  signal alu_a, rt_fwd, alu_b, alu_result : word_t;
  signal alu_zero : std_logic;
  signal ex_dest  : reg_addr_t;
  signal ex_mem_d : ex_mem_t;

  -- MEM
  signal dmem_rdata : word_t;
  signal mem_wb_d   : mem_wb_t;

  -- WB
  signal wb_data : word_t;

begin

  ---------------------------------------------------------------------------
  -- IF : instruction fetch
  ---------------------------------------------------------------------------
  u_pc : entity work.program_counter
    port map (clk => clk, rst => rst, pc_write => pc_write,
              next_pc => next_pc, pc => pc);

  u_imem : entity work.instruction_memory
    generic map (DEPTH => IMEM_DEPTH, INIT_FILE => IMEM_FILE)
    port map (addr => pc, instr => instr);

  pc_write <= not stall;
  pc_plus4 <= std_logic_vector(unsigned(pc) + 4);

  u_branch_mux : entity work.branch_mux
    port map (pc_plus4 => pc_plus4, branch_target => branch_target,
              sel => branch_sel, y => branch_mux_out);

  branch_sel <= '1' when pc_sel = PC_BRANCH else '0';

  jump_sel <= "01" when pc_sel = PC_JUMP else
              "10" when pc_sel = PC_JR   else
              "00";

  u_jump_mux : entity work.jump_mux
    port map (from_branch => branch_mux_out, jump_target => jump_target,
              jr_target => id_rs_val, sel => jump_sel, y => next_pc);

  if_id_d <= (valid => '1', pc => pc, pc_plus4 => pc_plus4, instr => instr);

  u_if_id : entity work.if_id_register
    port map (clk => clk, rst => rst, write => pc_write, flush => if_flush,
              d => if_id_d, q => if_id);

  ---------------------------------------------------------------------------
  -- ID : decode, register read, hazard detection, branch/jump resolution
  ---------------------------------------------------------------------------
  id_opcode <= if_id.instr(31 downto 26);
  id_rs     <= if_id.instr(25 downto 21);
  id_rt     <= if_id.instr(20 downto 16);
  id_rd     <= if_id.instr(15 downto 11);
  id_funct  <= if_id.instr(5 downto 0);

  u_ctrl : entity work.control_unit
    port map (opcode => id_opcode, funct => id_funct, ctrl => id_ctrl);

  u_rf : entity work.register_file
    port map (clk => clk, rst => rst,
              ra1 => id_rs, ra2 => id_rt, rd1 => rf_rd1, rd2 => rf_rd2,
              we => mem_wb.reg_write, wa => mem_wb.dest, wd => wb_data);

  -- MUX E / MUX F : ID-stage forwarding from EX/MEM
  id_rs_val <= ex_mem.alu_result when fwd_e = '1' else rf_rd1;
  id_rt_val <= ex_mem.alu_result when fwd_f = '1' else rf_rd2;

  u_ext : entity work.sign_extend
    port map (imm16 => if_id.instr(15 downto 0), zero_ext => id_ctrl.ext_zero,
              imm32 => id_imm);

  u_branch : entity work.branch_unit
    port map (pc_plus4 => if_id.pc_plus4, imm16 => if_id.instr(15 downto 0),
              target26 => if_id.instr(25 downto 0),
              rs_val => id_rs_val, rt_val => id_rt_val,
              branch_target => branch_target, jump_target => jump_target,
              equal => id_equal);

  u_hazard : entity work.hazard_unit
    port map (id_valid => if_id.valid, id_ctrl => id_ctrl,
              id_rs => id_rs, id_rt => id_rt, id_equal => id_equal,
              ex_reg_write => id_ex.ctrl.reg_write,
              ex_mem_read  => id_ex.ctrl.mem_read, ex_dest => ex_dest,
              mem_mem_read => ex_mem.mem_read, mem_dest => ex_mem.dest,
              stall => stall, if_flush => if_flush, pc_sel => pc_sel);

  id_ex_d <= (valid  => if_id.valid, pc => if_id.pc, ctrl => id_ctrl,
              rs_val => id_rs_val, rt_val => id_rt_val, imm => id_imm,
              shamt  => if_id.instr(10 downto 6),
              rs => id_rs, rt => id_rt, rd => id_rd);

  -- control MUX of the diagram: a stall turns the ID/EX input into a bubble
  u_id_ex : entity work.id_ex_register
    port map (clk => clk, rst => rst, bubble => stall, d => id_ex_d, q => id_ex);

  ---------------------------------------------------------------------------
  -- EX : forwarding muxes, ALU
  ---------------------------------------------------------------------------
  u_fwd : entity work.forwarding_unit
    port map (ex_rs => id_ex.rs, ex_rt => id_ex.rt,
              id_rs => id_rs, id_rt => id_rt,
              mem_reg_write => ex_mem.reg_write, mem_mem_read => ex_mem.mem_read,
              mem_dest => ex_mem.dest,
              wb_reg_write => mem_wb.reg_write, wb_dest => mem_wb.dest,
              fwd_a => fwd_a, fwd_b => fwd_b, fwd_e => fwd_e, fwd_f => fwd_f);

  -- MUX C : ALU operand A
  with fwd_a select
    alu_a <= ex_mem.alu_result when FWD_EX_MEM,
             wb_data           when FWD_MEM_WB,
             id_ex.rs_val      when others;

  -- MUX D : rt value (ALU operand B candidate and SB store data)
  with fwd_b select
    rt_fwd <= ex_mem.alu_result when FWD_EX_MEM,
              wb_data           when FWD_MEM_WB,
              id_ex.rt_val      when others;

  -- MUX A : ALUSrc (after forwarding, so an immediate is never overridden)
  alu_b <= id_ex.imm when id_ex.ctrl.alu_src = '1' else rt_fwd;

  -- MUX B : RegDst
  ex_dest <= id_ex.rd when id_ex.ctrl.reg_dst = '1' else id_ex.rt;

  u_alu : entity work.alu
    port map (op => id_ex.ctrl.alu_op, a => alu_a, b => alu_b,
              shamt => id_ex.shamt, result => alu_result, zero => alu_zero);

  ex_mem_d <= (valid => id_ex.valid, pc => id_ex.pc,
               reg_write => id_ex.ctrl.reg_write, mem_to_reg => id_ex.ctrl.mem_to_reg,
               mem_read => id_ex.ctrl.mem_read, mem_write => id_ex.ctrl.mem_write,
               alu_result => alu_result, store_data => rt_fwd, dest => ex_dest);

  u_ex_mem : entity work.ex_mem_register
    port map (clk => clk, rst => rst, d => ex_mem_d, q => ex_mem);

  ---------------------------------------------------------------------------
  -- MEM : data memory
  ---------------------------------------------------------------------------
  u_dmem : entity work.data_memory
    generic map (DEPTH => DMEM_DEPTH, INIT_FILE => DMEM_FILE)
    port map (clk => clk, mem_write => ex_mem.mem_write,
              addr => ex_mem.alu_result, wdata => ex_mem.store_data,
              read_data => dmem_rdata);

  mem_wb_d <= (valid => ex_mem.valid, pc => ex_mem.pc,
               reg_write => ex_mem.reg_write, mem_to_reg => ex_mem.mem_to_reg,
               alu_result => ex_mem.alu_result, read_data => dmem_rdata,
               dest => ex_mem.dest);

  u_mem_wb : entity work.mem_wb_register
    port map (clk => clk, rst => rst, d => mem_wb_d, q => mem_wb);

  ---------------------------------------------------------------------------
  -- WB : write-back mux (register file write port is driven above)
  ---------------------------------------------------------------------------
  u_wb_mux : entity work.wb_mux
    port map (read_data => mem_wb.read_data, alu_result => mem_wb.alu_result,
              mem_to_reg => mem_wb.mem_to_reg, y => wb_data);

  ---------------------------------------------------------------------------
  -- Debug / trace
  ---------------------------------------------------------------------------
  dbg.pc_if      <= pc;
  dbg.if_id      <= if_id;
  dbg.id_ex_v    <= id_ex.valid;   dbg.id_ex_pc  <= id_ex.pc;
  dbg.ex_mem_v   <= ex_mem.valid;  dbg.ex_mem_pc <= ex_mem.pc;
  dbg.mem_wb_v   <= mem_wb.valid;  dbg.mem_wb_pc <= mem_wb.pc;
  dbg.stall      <= stall;
  dbg.if_flush   <= if_flush;
  dbg.pc_sel     <= pc_sel;
  dbg.next_pc    <= next_pc;
  dbg.fwd_a      <= fwd_a;
  dbg.fwd_b      <= fwd_b;
  dbg.fwd_e      <= fwd_e;
  dbg.fwd_f      <= fwd_f;
  dbg.alu_result <= alu_result;
  dbg.wb_en      <= mem_wb.reg_write when mem_wb.dest /= REG_ZERO else '0';
  dbg.wb_rd      <= mem_wb.dest;
  dbg.wb_data    <= wb_data;
  dbg.mem_we     <= ex_mem.mem_write;
  dbg.mem_addr   <= ex_mem.alu_result;
  dbg.mem_wdata  <= ex_mem.store_data;
  -- "halt" convention: a J in ID whose target is its own address (j .)
  dbg.halted     <= '1' when if_id.valid = '1' and id_ctrl.jump = '1'
                             and jump_target = if_id.pc else '0';

end architecture rtl;
