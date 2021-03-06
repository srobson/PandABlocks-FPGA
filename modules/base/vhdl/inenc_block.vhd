--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Control register interface for INENC block.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.addr_defines.all;
use work.top_defines.all;
use work.addr_defines.all;

entity inenc_block is
port (
    -- Clock and Reset.
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
    -- Encoder I/O Pads.
    A_IN                : in  std_logic;
    B_IN                : in  std_logic;
    Z_IN                : in  std_logic;
    CLK_OUT             : out std_logic;
    DATA_IN             : in  std_logic;
    CLK_IN              : in  std_logic;
    CONN_OUT            : out std_logic;
    -- Block Outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    DCARD_MODE          : in  std_logic_vector(31 downto 0);
    PROTOCOL            : out std_logic_vector(2 downto 0);
    posn_o              : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of inenc_block is

signal clk_ext          : std_logic;
-- Block Configuration Registers
signal PROTOCOL_i       : std_logic_vector(31 downto 0);
signal PROTOCOL_WSTB    : std_logic;
signal BYPASS           : std_logic_vector(31 downto 0);
signal CLK_PERIOD       : std_logic_vector(31 downto 0);
signal CLK_PERIOD_WSTB  : std_logic;
signal FRAME_PERIOD     : std_logic_vector(31 downto 0);
signal FRAME_PERIOD_WSTB: std_logic;
signal BITS             : std_logic_vector(31 downto 0);
signal BITS_WSTB        : std_logic;
signal SETP             : std_logic_vector(31 downto 0);
signal SETP_WSTB        : std_logic;
signal RST_ON_Z         : std_logic_vector(31 downto 0);
signal STATUS           : std_logic_vector(31 downto 0);
signal STATUS_RSTB      : std_logic;
signal read_ack         : std_logic;

signal reset            : std_logic;
signal slow             : slow_packet;

signal read_addr        : natural range 0 to (2**read_address_i'length - 1);

begin

-- Assign outputs
PROTOCOL <= PROTOCOL_i(2 downto 0);

-- Input encoder connection status comes from either
--  * Dcard pin [12] for incremental, or
--  * link_up status for absolute in loopback mode
CONN_OUT <= STATUS(0);

-- Certain parameter changes must initiate a block reset.
reset <= PROTOCOL_WSTB or CLK_PERIOD_WSTB or
            FRAME_PERIOD_WSTB or BITS_WSTB;

--------------------------------------------------------------------------
-- Control System Interface
--------------------------------------------------------------------------
inenc_ctrl : entity work.inenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    clk_o               => clk_ext,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    PROTOCOL            => PROTOCOL_i,
    PROTOCOL_WSTB       => PROTOCOL_WSTB,
    BYPASS              => BYPASS,
    CLK_PERIOD          => CLK_PERIOD,
    CLK_PERIOD_WSTB     => CLK_PERIOD_WSTB,
    FRAME_PERIOD        => FRAME_PERIOD,
    FRAME_PERIOD_WSTB   => FRAME_PERIOD_WSTB,
    BITS                => BITS,
    BITS_WSTB           => BITS_WSTB,
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    RST_ON_Z_WSTB       => open,
    STATUS              => STATUS,
    DCARD_ID            => '0' & DCARD_MODE(31 downto 1)
);

-- Generate read strobe to clear STATUS register on readback
read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack,
    DELAY       => RD_ADDR2ACK
);

read_addr <= to_integer(unsigned(read_address_i));

STATUS_RSTB <= '1' when (read_ack = '1' and read_addr = INENC_STATUS)
                    else '0';

--------------------------------------------------------------------------
-- INENC block instantiation
--------------------------------------------------------------------------
inenc_inst : entity work.inenc
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset,
    --
    A_IN                => A_IN,
    B_IN                => B_IN,
    Z_IN                => Z_IN,
    CLK_OUT             => CLK_OUT,
    DATA_IN             => DATA_IN,
    CLK_IN              => CLK_IN,
    --
    clk_out_ext_i       => clk_ext,
    --
    DCARD_MODE          => DCARD_MODE,
    PROTOCOL            => PROTOCOL_i(2 downto 0),
    BYPASS              => BYPASS(0),
    CLK_PERIOD          => CLK_PERIOD,
    FRAME_PERIOD        => FRAME_PERIOD,
    BITS                => BITS(7 downto 0),
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z(0),
    STATUS              => STATUS,
    STATUS_RSTB         => STATUS_RSTB,

    posn_o              => posn_o
);

end rtl;
