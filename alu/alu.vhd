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
		variable is_opcode_processed_v: std_ulogic;
		variable result_v: unsigned(32 downto 0) := (others => '0');
	begin	
		if(rising_edge(clk) and enable) then
			is_opcode_processed_v := '1';
		
			case op_code is
				when add =>
					result_v := ('0' & dest_data) + ('0' & src_data);
				when sub | cmp =>
					result_v := ('0' & dest_data) - ('0' & src_data);	
				when clr =>
					result_v := (others => '0');
				when or_op =>
					result_v := ('0' & dest_data) or ('0' & src_data);
				when and_op =>
					result_v := ('0' & dest_data) and ('0' & src_data);
				when xor_op =>
					result_v := ('0' & dest_data) xor ('0' & src_data);
				when not_op =>
					result_v := '0' & (not dest_data);
				when lsh =>
					result_v := '0' & shift_left(dest_data, to_integer(src_data));
				when rsh =>
					result_v := '0' & shift_right(dest_data, to_integer(src_data));
				when others =>
					result_v := (others => '0');
					is_opcode_processed_v := '0';
			end case;
			
			carry_flag_a <= result_v(32);			-- bit 32 of result_v is a carry bit (carry bit can be used as overflow bit)
			
			-- setting zero flag if opcode is processed by ALU 
			zero_flag_a <= is_opcode_processed_v and get_zero_flag(result_v); 
			
			negative_flag_a <= result_v(31);		-- Set negative flag if MSB of the result is set
			result <= result_v(31 downto 0);
		end if;
	end process;
end alu;