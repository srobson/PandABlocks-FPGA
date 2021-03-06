--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : This module handles Framing and Capture pulse generation along
--                with ADC/Encoder position processing.
--
--                Output from this block is fed to Buffer block for capture.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity pcap_frame is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block register
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MASK        : in  std_logic_vector(31 downto 0);
    FRAMING_MODE        : in  std_logic_vector(31 downto 0);
    -- Block input and outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    frame_i             : in  std_logic;
    capture_i           : in  std_logic;
    timestamp_i         : in  std_logic_vector(63 downto 0);

    capture_o           : out std_logic;
    posn_o              : out std32_array(63 downto 0);
    error_o             : out std_logic
);
end pcap_frame;

architecture rtl of pcap_frame is

signal frame_prev       : std_logic;
signal capture_prev     : std_logic;
signal ongoing_capture  : std_logic;

signal frame_rise       : std_logic;
signal capture_rise     : std_logic;
signal first_frame      : std_logic;
signal capture          : std_logic;

signal timestamp        : unsigned(63 downto 0);
signal capture_ts       : unsigned(63 downto 0) := (others => '0');
signal frame_ts         : unsigned(63 downto 0) := (others => '0');
signal frame_length     : unsigned(63 downto 0) := (others => '0');
signal capture_offset   : unsigned(63 downto 0) := (others => '0');

signal posbus           : std32_array(31 downto 0);
signal extbus           : std32_array(31 downto 0);

begin

--------------------------------------------------------------------------
-- Input registers, and
-- Detect rise/falling edge of internal signals.
--------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        frame_prev <= frame_i;
        capture_prev <= capture_i;
    end if;
end process;

frame_rise <= frame_i and not frame_prev;
capture_rise <= capture_i and not capture_prev;

--------------------------------------------------------------------------
-- Capture and Frame managements:
--
-- A capture between two Frame inputs indicates a live frame
-- where data is captured at the end when in FRAMING mode.
--
-- When FRAMING_ENABLE = 1:
--
-- FRAME:    |     |     |     |      |      |      |      |
-- CAPTURE:     x           x            x             x
-- Output          |           |             |             |
--
--------------------------------------------------------------------------
capture <= capture_rise when (FRAMING_ENABLE = '0') else
                frame_rise and ongoing_capture;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ongoing_capture <= '0';
            capture_o <= '0';
            first_frame <= '0';
            error_o <= '0';
        else
            -- Data processing in capture module has a latency of 1 tick so
            -- capture signal must be aligned
            capture_o <= capture;

            -- First frame arrived flag which is used to detect 'capture
            -- before frame pulse' error condition
            -- Resets on arming.
            if (frame_rise = '1') then
                first_frame <= '1';
            end if;

            -- If happens on the same clock, capture belongs the
            -- immediate frame.
            if (frame_rise = '1' and capture_rise = '1') then
                ongoing_capture <= '1';
            -- Otherwise start a clear frame.
            elsif (frame_rise = '1') then
                ongoing_capture <= '0';
            -- Flag that capture pulse received.
            elsif (capture_rise = '1') then
                ongoing_capture <= '1';
            end if;

            -- When Framing is enabled, there are two error conditions
            -- (1) Capture pulse arrives before frame, and
            -- (2) More than 1 capture pulses in a frame
            -- Error is latched until next pcap start (via reset port)

            -- Make sure that frame and capture are not on the same clock
            if (first_frame = '0' and frame_rise = '0') then
                error_o <= FRAMING_ENABLE and capture_rise;
            elsif (ongoing_capture = '1' and frame_rise = '0') then
                error_o <= FRAMING_ENABLE and capture_rise;
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- There are three timestamp information captured as: Start of Frame,
-- Frame Length and Capture Offset.
--------------------------------------------------------------------------
timestamp <= unsigned(timestamp_i);

process(clk_i) begin
    if rising_edge(clk_i) then
        -- Start of Frame timestamp and Frame Length in ticks
        if (frame_rise = '1') then
            frame_ts <= timestamp;
            frame_length <= timestamp - frame_ts;
        end if;

        -- Capture timestamps and capture offset from frame start
        if (capture_rise = '1') then
            capture_ts <= timestamp;
            capture_offset <= timestamp - frame_ts;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Instantiate Position Processing Blocks
--------------------------------------------------------------------------
PROC_OTHERS : FOR I IN 1 TO 31 GENERATE

pcap_capture_inst : entity work.pcap_capture
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    posn_i              => posbus_i(I),
    frame_i             => frame_rise,
    capture_i           => capture_rise,
    posn_o              => posbus(I),
    extn_o              => extbus(I),

    FRAMING_ENABLE      => FRAMING_ENABLE,
    FRAMING_MASK        => FRAMING_MASK(I),
    FRAMING_MODE        => FRAMING_MODE(I)
);
END GENERATE;

--------------------------------------------------------------------------
-- Assign 64x32-bits position fields for data capture
--------------------------------------------------------------------------
posn_o(0)  <= posbus_i(0);
posn_o(31 downto 1)  <= posbus(31 downto 1);

posn_o(32) <= (others => '0');
posn_o(36 downto 33) <= extbus(4 downto 1);
posn_o(37) <= std_logic_vector(capture_ts(31 downto  0));
posn_o(38) <= std_logic_vector(capture_ts(63 downto 32));
posn_o(39) <= std_logic_vector(frame_length(31 downto 0));
posn_o(40) <= std_logic_vector(capture_offset(31 downto 0));
posn_o(41) <= (others => '0');
posn_o(42) <= sysbus_i(31 downto 0);
posn_o(43) <= sysbus_i(63 downto 32);
posn_o(44) <= sysbus_i(95 downto 64);
posn_o(45) <= sysbus_i(127 downto 96);
posn_o(49 downto 46) <= extbus(24 downto 21);
posn_o(63 downto 50) <= (others => (others => '0'));

end rtl;

