--------------------------------------------------------------------------------
--  File:       panda_counter.vhd
--  Desc:       Programmable Pulse Generator.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity panda_counter is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    enable_i            : in  std_logic;
    trigger_i           : in  std_logic;
    carry_o             : out std_logic;
    -- Block Parameters
    DIR                 : in  std_logic;
    START               : in  std_logic_vector(31 downto 0);
    START_LOAD          : in  std_logic;
    STEP                : in  std_logic_vector(31 downto 0);
    -- Block Status
    COUNT               : out std_logic_vector(31 downto 0)
);
end panda_counter;

architecture rtl of panda_counter is

signal trigger_prev     : std_logic;
signal trigger_rise     : std_logic;
signal enable_prev      : std_logic;
signal enable_fall      : std_logic;
signal counter          : unsigned(32 downto 0);

begin

-- Input registering
process(clk_i)
begin
    if rising_edge(clk_i) then
        trigger_prev <= trigger_i;
        enable_prev <= enable_i;
    end if;
end process;

trigger_rise <= trigger_i and not trigger_prev;
enable_fall <= not enable_i and enable_prev;

--
-- Up/Down Counter
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            counter <= (others => '0');
        else
            if (START_LOAD = '1') then
                counter <= unsigned('0' & START);
            elsif (enable_fall = '1') then
                counter <= unsigned('0' & START);
            elsif (trigger_rise = '1') then
                if (DIR = '0') then
                    counter <= counter + unsigned(STEP);
                else
                    counter <= counter - unsigned(STEP);
                end if;
            end if;
        end if;
    end if;
end process;

COUNT <= std_logic_vector(counter(31 downto 0));
carry_o <= counter(32);

end rtl;
