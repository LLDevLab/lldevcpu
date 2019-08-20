library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lldevcpu_br;
use lldevcpu.lldevcpu_pack.all;

entity instr_decoder is
	port(clk: in std_logic; 
			instruction: in rom_data; 
			instr_opcode: out opcode; 
			dest_reg_addr: out reg_addr := 0;
			src_reg_addr: out reg_addr := 0);
end entity instr_decoder;

architecture instr_decoder_arch of instr_decoder is
	alias opcode_bin_s: std_logic_vector(5 downto 0) is instruction(31 downto 26);
	alias dest_reg_addr_s: std_logic_vector(3 downto 0) is instruction(25 downto 22);
	alias src_reg_addr_s: std_logic_vector(3 downto 0) is instruction(21 downto 18);
	alias br_reg_addr_s: std_logic_vector(3 downto 0) is instruction(25 downto 22);
begin
	process(clk)
		variable src_reg_addr_v: reg_addr := 0;
		variable dest_reg_addr_v: reg_addr := 0;
	begin
		if(rising_edge(clk)) then
			src_reg_addr_v := 0;
			dest_reg_addr_v := 0;
					
			case opcode_bin_s is
				when "000001" =>
					instr_opcode <= add;
					src_reg_addr_v := to_integer(unsigned(src_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "000010" =>
					instr_opcode <= sub;
					src_reg_addr_v := to_integer(unsigned(src_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "000011" =>
					instr_opcode <= br;
					dest_reg_addr_v := pc_reg_addr;
					src_reg_addr_v := to_integer(unsigned(br_reg_addr_s));
				when others =>
					instr_opcode <= noop;
			end case;
			
			src_reg_addr <= src_reg_addr_v;
			dest_reg_addr <= dest_reg_addr_v;
		end if;
	end process;
end instr_decoder_arch;