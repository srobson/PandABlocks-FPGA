library ieee;
use ieee.std_logic_1164.all;
package panda_version is
constant FPGA_VERSION: std_logic_vector(31 downto 0)   := X"00000102";
constant FPGA_BUILD: std_logic_vector(31 downto 0)   := X"9a0f164a";
end panda_version;
