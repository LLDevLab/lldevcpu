library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lldevcpu_pack.all;

entity alu is
	port(enable: in boolean; 
			clk: in std_logic; 
			op_code: in opcode; 
			dest_data, src_data: in unsigned32; 
			result: out unsigned32 := X"00000000");
end entity;

architecture alu of alu is
begin	
	process(clk, enable)
	begin	
		if(rising_edge(clk) and enable) then
			case op_code is
				when add =>
					result <= dest_data + src_data;
				when sub =>
					result <= dest_data - src_data;					
				when others =>
					result <= (others => '0');
			end case;
		end if;
	end process;
end alu;