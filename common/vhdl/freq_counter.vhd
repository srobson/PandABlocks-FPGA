-----------------------------------------------------------------------------
--  Project      : Diamond SPEC FA Sniffer
--  Filename     : freq_counter.vhd
--  Purpose      : FOFB Fast Acquisition PciE sniffer
--  Author       : Dr. Isa S. Uzun
-----------------------------------------------------------------------------
--  Description  : Frequency counter for 4 clocks against reference clock 
--                 input
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity freq_counter is
port (
    reset           : in  std_logic;
    refclk          : in  std_logic;
    test_clocks     : in  std_logic_vector(3 downto 0);
    freq_out        : out std32_array(3 downto 0)
);
end freq_counter;

architecture rtl of freq_counter is

subtype uint32_t is unsigned(31 downto 0);
type uint32_array is array(natural range <>) of uint32_t;

signal ref_cntr        : integer range 2**13-1 downto 0;
signal ref_trigger     : std_logic;
signal trigger         : std_logic_vector(3 downto 0);
signal clk_cntr        : uint32_array(3 downto 0);
signal clk_cnt_reg     : uint32_array(3 downto 0);

begin

--------------------------------------------------------------------------
-- Reference Counter and Trigger
--------------------------------------------------------------------------
process(refclk)
begin
    if rising_edge(refclk) then
        if (reset = '1') then
            ref_cntr    <= 0;
            ref_trigger <= '1';
        else
            if (ref_cntr = 2**13-1) then
                ref_cntr    <= 0;
                ref_trigger <= '1';
            else
                ref_cntr    <= ref_cntr + 1;
                ref_trigger <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Clock counters
-- Counts number of ticks between reference trigger
--------------------------------------------------------------------------
CNTR_GEN : FOR I IN 0 TO 3 GENERATE

p2p_trigger_inst : entity work.pulse2pulse
port map (
    in_clk      => refclk,
    out_clk     => test_clocks(I),
    rst         => reset,
    pulsein     => ref_trigger,
    inbusy      => open,
    pulseout    => trigger(I)
);

process(test_clocks(I))
begin
    if rising_edge(test_clocks(I)) then
        if (reset = '1') then
            clk_cntr(I)    <= (others=>'0');
            clk_cnt_reg(I) <= (others=>'0');
        else
            if (trigger(I) = '1') then
                clk_cntr(I)    <= (others=>'0');
                clk_cnt_reg(I) <= clk_cntr(I);
            else
                clk_cntr(I)    <= clk_cntr(I) + 1;
                clk_cnt_reg(I) <= clk_cnt_reg(I);
            end if;
        end if;
    end if;
end process;

freq_out(I) <= std_logic_vector(clk_cnt_reg(I));

END GENERATE;

end rtl;
