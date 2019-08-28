library ieee;
use ieee.std_logic_1164.all;

use work.lldevcpu_pack.all;

entity alu_tb is end;

architecture alu_tb of alu_tb is
	component alu is
		port(enable: in boolean; 
			clk: in std_logic; 
			op_code: in opcode; 
			dest_data, src_data: in unsigned32; 
			result: out unsigned32;
			sreg: out unsigned32);
	end component;
	
	signal clk: std_logic := '0';
	signal opcode_s: opcode;
	signal src_data_s: unsigned32 := X"00000000";
	signal dest_data_s: unsigned32 := X"00000000";
	signal result_s: unsigned32 := X"00000000";
	signal enable_s: boolean;
	signal sreg_s: unsigned32 := X"00000000";
begin
	clk <= not clk after 5 ns;
	
	--opcode_s <= add;
	opcode_s <= sub;
	
	enable_s <= true;
	
	--src_data_s <= X"FFFFFFF9" after 10 ns, X"FFFFFFFF" after 20 ns, X"FFFFFFF8" after 30 ns;
	src_data_s <= X"00000010" after 10 ns, X"00000001" after 20 ns, X"00000001" after 30 ns;
	
	--dest_data_s <= X"00000010" after 10 ns, X"00000001" after 20 ns, X"00000001" after 30 ns;
	dest_data_s <= X"00000001" after 10 ns, X"00000001" after 20 ns, X"FFFFFFF8" after 30 ns;
	
	alu1: alu port map(enable_s, clk, opcode_s, dest_data_s, src_data_s, result_s, sreg_s);
end alu_tb;