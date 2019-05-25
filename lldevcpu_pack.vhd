library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lldevcpu_pack is
	constant rom_addr_msb_num: integer := 11;

	type opcode is (noop, add, sub);
	subtype rom_data is std_logic_vector(31 downto 0);
	
	subtype reg_addr is integer range 0 to 15;				-- Заменил std_logic_vector(3 downto 0) на integer
	
	subtype rom_addr is std_logic_vector(rom_addr_msb_num downto 0);
	subtype unsigned32 is unsigned(31 downto 0);
end lldevcpu_pack;