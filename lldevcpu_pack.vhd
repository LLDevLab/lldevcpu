library ieee;
use ieee.std_logic_1164.all;

package lldevcpu_pack is
	type opcode is (noop, add, sub);
	subtype rom_data is std_logic_vector(31 downto 0);
	subtype reg_addr is std_logic_vector(3 downto 0);
end lldevcpu_pack;