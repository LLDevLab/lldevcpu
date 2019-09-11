library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lldevcpu_pack.all;

entity alu is
	port(enable: in boolean; 
			clk: in std_logic; 
			op_code: in opcode; 
			dest_data, src_data: in unsigned32; 
			result: out unsigned32 := X"00000000";
			sreg: out unsigned32 := X"00000000");
end entity;

architecture alu of alu is
	alias carry_flag_a: std_ulogic is sreg(carry_flag_pos);
	alias zero_flag_a: std_ulogic is sreg(zero_flag_pos);
	alias negative_flag_a: std_ulogic is sreg(negative_flag_pos);
	
	function get_zero_flag(result_param: unsigned(32 downto 0)) return std_ulogic is
	begin
		if(result_param(31 downto 0) = X"00000000") then
			return '1';
		else
			return '0';
		end if;
	end function;
begin	
	process(clk, enable)
		variable zero_flag_v: std_ulogic := '0';
		variable result_v: unsigned(32 downto 0) := (others => '0');
	begin	
		if(rising_edge(clk) and enable) then		
			case op_code is
				when add =>
					result_v := ('0' & dest_data) + ('0' & src_data);
					zero_flag_v := get_zero_flag(result_v);
				when sub | cmp =>
					result_v := ('0' & dest_data) - ('0' & src_data);	
					zero_flag_v := get_zero_flag(result_v);
				when clr =>
					result_v := (others => '0');
					zero_flag_v := '0';
				when or_op =>
					result_v := ('0' & dest_data) or ('0' & src_data);
					zero_flag_v := get_zero_flag(result_v);
				when others =>
					result_v := (others => '0');
					zero_flag_v := '0';
			end case;
			
			carry_flag_a <= result_v(32);			-- bit 32 of result_v is a carry bit (carry bit can be used as overflow bit)
			zero_flag_a <= zero_flag_v;
			negative_flag_a <= result_v(31);		-- Set negative flag if MSB of the result is set
			result <= result_v(31 downto 0);
		end if;
	end process;
end alu;