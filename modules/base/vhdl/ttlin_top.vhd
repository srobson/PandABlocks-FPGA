--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Interface to external TTL inputs.
--                TTL inputs are registered before assigned to System Bus.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity ttlin_top is
port (
    -- Clocks and Resets
    clk_i               : in  std_logic;
    -- TTL I/O
    pad_i               : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    val_o               : out std_logic_vector(TTLIN_NUM-1 downto 0)
);
end ttlin_top;

architecture rtl of ttlin_top is

signal pad_iob          : std_logic_vector(pad_i'length-1 downto 0);

begin

-- Place into IOB
process(clk_i)
begin
    if rising_edge(clk_i) then
        pad_iob <= pad_i;
    end if;
end process;

-- Syncroniser for each input
SYNC : FOR I IN 0 TO TTLIN_NUM-1 GENERATE

    syncer : entity work.sync_bit
    port map (
        clk_i   => clk_i,
        bit_i   => pad_iob(I),
        bit_o   => val_o(I)
    );

END GENERATE;

end rtl;


