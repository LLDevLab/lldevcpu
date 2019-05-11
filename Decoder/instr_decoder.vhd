library ieee;
use ieee.std_logic_1164.all;

-- lldevcpu — название библиотеки, созданной мной в ModelSim
library lldevcpu;
use lldevcpu.lldevcpu_pack.all;

entity instr_decoder is
	port(clk: in std_logic; 
			instruction: in rom_data; 
			instr_opcode: out opcode; 
			dest_reg_addr: out reg_addr := X"0";
			src_reg_addr: out reg_addr := X"0");
end entity instr_decoder;

architecture instr_decoder_arch of instr_decoder is
	alias opcode_bin_s: std_logic_vector(5 downto 0) is instruction(31 downto 26);
	alias dest_reg_addr_s: reg_addr is instruction(25 downto 22);
	alias src_reg_addr_s: reg_addr is instruction(21 downto 18);
begin
	process(clk)
	begin
		if(rising_edge(clk)) then
			case opcode_bin_s is
				when "000001" =>
					instr_opcode <= add;
					src_reg_addr <= src_reg_addr_s;
					dest_reg_addr <= dest_reg_addr_s;
				when "000010" =>
					instr_opcode <= sub;
					src_reg_addr <= src_reg_addr_s;
					dest_reg_addr <= dest_reg_addr_s;
				when others =>
					instr_opcode <= noop;
					src_reg_addr <= X"0";
					dest_reg_addr <= X"0";
			end case;
		end if;
	end process;
end instr_decoder_arch;