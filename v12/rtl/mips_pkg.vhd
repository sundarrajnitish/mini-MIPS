------------------------------------------------------------------------------
-- mini-MIPS v12 : shared types, ISA constants and pipeline-register records
--
-- Original design : Nitish Sundarraj Balaji (COEN 6741, Concordia, W2023)
-- v12 rework      : single-edge synchronous pipeline, branch/jump in ID,
--                   load-use interlock, EX + ID forwarding.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mips_pkg is

  subtype word_t     is std_logic_vector(31 downto 0);
  subtype reg_addr_t is std_logic_vector(4 downto 0);
  subtype opcode_t   is std_logic_vector(5 downto 0);
  subtype funct_t    is std_logic_vector(5 downto 0);
  subtype alu_op_t   is std_logic_vector(2 downto 0);

  constant ZERO_WORD : word_t     := (others => '0');

  -- storage arrays (register file, instruction ROM, data RAM)
  type word_array_t is array (natural range <>) of word_t;
  subtype reg_array_t is word_array_t(0 to 31);
  constant REG_ZERO  : reg_addr_t := (others => '0');

  --------------------------------------------------------------------------
  -- Instruction set (11 instructions, see README / website for encodings)
  --------------------------------------------------------------------------
  constant OP_RTYPE : opcode_t := "000000";  -- ADD, NOR, XOR, SLL, JR
  constant OP_J     : opcode_t := "000010";
  constant OP_BEQ   : opcode_t := "000100";
  constant OP_ANDI  : opcode_t := "001100";
  constant OP_SUBUI : opcode_t := "011001";
  constant OP_LW    : opcode_t := "100011";
  constant OP_SB    : opcode_t := "101000";

  constant FN_SLL   : funct_t := "000000";
  constant FN_JR    : funct_t := "001000";
  constant FN_ADD   : funct_t := "100000";
  constant FN_XOR   : funct_t := "100110";
  constant FN_NOR   : funct_t := "100111";

  -- ALU operation encoding (kept from the original v11 ALU)
  constant ALU_ADD : alu_op_t := "000";
  constant ALU_AND : alu_op_t := "001";
  constant ALU_XOR : alu_op_t := "010";
  constant ALU_NOR : alu_op_t := "011";
  constant ALU_SLL : alu_op_t := "100";
  constant ALU_SUB : alu_op_t := "110";

  --------------------------------------------------------------------------
  -- Control bundle produced by the control unit in ID.
  --   WB group : reg_write, mem_to_reg
  --   M  group : mem_read, mem_write
  --   EX group : reg_dst, alu_src, alu_op
  --   ID-only  : branch, jump, jump_reg, ext_zero, uses_rs, uses_rt
  --------------------------------------------------------------------------
  type ctrl_t is record
    reg_write  : std_logic;
    mem_to_reg : std_logic;
    mem_read   : std_logic;
    mem_write  : std_logic;
    reg_dst    : std_logic;  -- 1: rd, 0: rt
    alu_src    : std_logic;  -- 1: immediate, 0: register
    alu_op     : alu_op_t;
    branch     : std_logic;  -- BEQ
    jump       : std_logic;  -- J
    jump_reg   : std_logic;  -- JR
    ext_zero   : std_logic;  -- 1: zero-extend immediate (ANDI)
    uses_rs    : std_logic;  -- instruction reads rs (hazard detection)
    uses_rt    : std_logic;  -- instruction reads rt (hazard detection)
  end record;

  constant CTRL_NOP : ctrl_t := (
    reg_write => '0', mem_to_reg => '0', mem_read => '0', mem_write => '0',
    reg_dst => '0', alu_src => '0', alu_op => ALU_ADD,
    branch => '0', jump => '0', jump_reg => '0', ext_zero => '0',
    uses_rs => '0', uses_rt => '0');

  --------------------------------------------------------------------------
  -- Pipeline registers. `valid` and `pc` travel with every instruction so
  -- that bubbles are explicit and every stage can be traced back to the
  -- instruction occupying it (pure debug; synthesis prunes unused bits).
  --------------------------------------------------------------------------
  type if_id_t is record
    valid    : std_logic;
    pc       : word_t;
    pc_plus4 : word_t;
    instr    : word_t;
  end record;

  constant IF_ID_RESET : if_id_t := (
    valid => '0', pc => ZERO_WORD, pc_plus4 => ZERO_WORD, instr => ZERO_WORD);

  type id_ex_t is record
    valid     : std_logic;
    pc        : word_t;
    ctrl      : ctrl_t;
    rs_val    : word_t;
    rt_val    : word_t;
    imm       : word_t;
    shamt     : std_logic_vector(4 downto 0);
    rs        : reg_addr_t;
    rt        : reg_addr_t;
    rd        : reg_addr_t;
  end record;

  constant ID_EX_RESET : id_ex_t := (
    valid => '0', pc => ZERO_WORD, ctrl => CTRL_NOP,
    rs_val => ZERO_WORD, rt_val => ZERO_WORD, imm => ZERO_WORD,
    shamt => (others => '0'), rs => REG_ZERO, rt => REG_ZERO, rd => REG_ZERO);

  type ex_mem_t is record
    valid      : std_logic;
    pc         : word_t;
    reg_write  : std_logic;
    mem_to_reg : std_logic;
    mem_read   : std_logic;
    mem_write  : std_logic;
    alu_result : word_t;
    store_data : word_t;
    dest       : reg_addr_t;
  end record;

  constant EX_MEM_RESET : ex_mem_t := (
    valid => '0', pc => ZERO_WORD, reg_write => '0', mem_to_reg => '0',
    mem_read => '0', mem_write => '0', alu_result => ZERO_WORD,
    store_data => ZERO_WORD, dest => REG_ZERO);

  type mem_wb_t is record
    valid      : std_logic;
    pc         : word_t;
    reg_write  : std_logic;
    mem_to_reg : std_logic;
    alu_result : word_t;
    read_data  : word_t;
    dest       : reg_addr_t;
  end record;

  constant MEM_WB_RESET : mem_wb_t := (
    valid => '0', pc => ZERO_WORD, reg_write => '0', mem_to_reg => '0',
    alu_result => ZERO_WORD, read_data => ZERO_WORD, dest => REG_ZERO);

  --------------------------------------------------------------------------
  -- Forwarding select encodings
  --------------------------------------------------------------------------
  subtype fwd_sel_t is std_logic_vector(1 downto 0);
  constant FWD_NONE   : fwd_sel_t := "00";  -- value from ID/EX register
  constant FWD_MEM_WB : fwd_sel_t := "01";  -- value being written back
  constant FWD_EX_MEM : fwd_sel_t := "10";  -- ALU result one stage ahead

  -- Next-PC select (branch mux + jump mux of the datapath diagram)
  subtype pc_sel_t is std_logic_vector(1 downto 0);
  constant PC_PLUS4  : pc_sel_t := "00";
  constant PC_BRANCH : pc_sel_t := "01";
  constant PC_JUMP   : pc_sel_t := "10";
  constant PC_JR     : pc_sel_t := "11";

  --------------------------------------------------------------------------
  -- Debug / trace port (observed by the testbench, ignored by synthesis)
  --------------------------------------------------------------------------
  type debug_t is record
    pc_if      : word_t;
    if_id      : if_id_t;
    id_ex_v    : std_logic;  id_ex_pc  : word_t;
    ex_mem_v   : std_logic;  ex_mem_pc : word_t;
    mem_wb_v   : std_logic;  mem_wb_pc : word_t;
    stall      : std_logic;
    if_flush   : std_logic;
    pc_sel     : pc_sel_t;
    next_pc    : word_t;
    fwd_a      : fwd_sel_t;
    fwd_b      : fwd_sel_t;
    fwd_e      : std_logic;
    fwd_f      : std_logic;
    alu_result : word_t;
    wb_en      : std_logic;
    wb_rd      : reg_addr_t;
    wb_data    : word_t;
    mem_we     : std_logic;
    mem_addr   : word_t;
    mem_wdata  : word_t;
    halted     : std_logic;
  end record;

end package mips_pkg;
