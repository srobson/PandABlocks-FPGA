--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Instantiates Control and Status register interface, and
--                core squencer IP
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity sequencer_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    -- Output sequencer
    outa_o              : out std_logic;
    outb_o              : out std_logic;
    outc_o              : out std_logic;
    outd_o              : out std_logic;
    oute_o              : out std_logic;
    outf_o              : out std_logic;
    active_o            : out std_logic
);
end sequencer_block;

architecture rtl of sequencer_block is

signal ENABLE_VAL       : std_logic_vector(31 downto 0);
signal INPA_VAL         : std_logic_vector(31 downto 0);
signal INPB_VAL         : std_logic_vector(31 downto 0);
signal INPC_VAL         : std_logic_vector(31 downto 0);
signal INPD_VAL         : std_logic_vector(31 downto 0);

signal PRESCALE         : std_logic_vector(31 downto 0);
signal TABLE_START      : std_logic;
signal TABLE_DATA       : std_logic_vector(31 downto 0);
signal TABLE_WSTB       : std_logic;
signal TABLE_CYCLE      : std_logic_vector(31 downto 0);
signal TABLE_LENGTH     : std_logic_vector(31 downto 0);
signal TABLE_LENGTH_WSTB: std_logic;
signal CUR_FRAME        : std_logic_vector(31 downto 0);
signal CUR_FCYCLE       : std_logic_vector(31 downto 0);
signal CUR_TCYCLE       : std_logic_vector(31 downto 0);

signal enable           : std_logic;
signal inpa             : std_logic;
signal inpb             : std_logic;
signal inpc             : std_logic;
signal inpd             : std_logic;

begin

--------------------------------------------------------------------------
-- Control System Interface
--------------------------------------------------------------------------
seq_ctrl : entity work.seq_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    enable_o            => enable,
    inpa_o              => inpa,
    inpb_o              => inpb,
    inpc_o              => inpc,
    inpd_o              => inpd,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    PRESCALE            => PRESCALE,
    PRESCALE_WSTB       => open,
    TABLE_CYCLE         => TABLE_CYCLE,
    TABLE_CYCLE_WSTB    => open,
    CUR_FRAME           => CUR_FRAME,
    CUR_FCYCLE          => CUR_FCYCLE,
    CUR_TCYCLE          => CUR_TCYCLE,
    TABLE_START         => open,
    TABLE_START_WSTB    => TABLE_START,
    TABLE_DATA          => TABLE_DATA,
    TABLE_DATA_WSTB     => TABLE_WSTB,
    TABLE_LENGTH        => TABLE_LENGTH,
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB
);

--------------------------------------------------------------------------
-- Sequence Block Core Instantiation
--------------------------------------------------------------------------
sequencer : entity work.sequencer
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    inpa_i              => inpa,
    inpb_i              => inpb,
    inpc_i              => inpc,
    inpd_i              => inpd,
    outa_o              => outa_o,
    outb_o              => outb_o,
    outc_o              => outc_o,
    outd_o              => outd_o,
    oute_o              => oute_o,
    outf_o              => outf_o,
    active_o            => active_o,

    PRESCALE            => PRESCALE,
    TABLE_START         => TABLE_START,
    TABLE_DATA          => TABLE_DATA,
    TABLE_WSTB          => TABLE_WSTB,
    TABLE_CYCLE         => TABLE_CYCLE,
    TABLE_LENGTH        => TABLE_LENGTH(15 downto 0),
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB,

    CUR_FRAME           => CUR_FRAME,
    CUR_FCYCLE          => CUR_FCYCLE,
    CUR_TCYCLE          => CUR_TCYCLE
);

end rtl;

