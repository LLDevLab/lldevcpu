library ieee;
use ieee.std_logic_1164.all;

library lldevcpu;
use lldevcpu.lldevcpu_pack.all;

entity alu_tb is end;

architecture alu_tb of alu_tb is
	component alu is
		port(enable: in boolean; 
				clk: in std_logic; 
				op_code: in opcode; 
				dest_data, src_data: in unsigned32; 
				result: out unsigned32);
	end component;
	
	signal clk: std_logic := '0';
	signal opcode_s: opcode;
	signal src_data_s: unsigned32;
	signal dest_data_s: unsigned32;
	signal result_s: unsigned32;
	signal enable_s: boolean;
begin
	clk <= not clk after 10 ns;
	
	opcode_s <= sub after 30 ns, noop after 60 ns, add after 110 ns;
	
	enable_s <= true after 20 ns, false after 50 ns, true after 100 ns;
	
	src_data_s <= X"00000001", X"00000002" after 60 ns, X"00000009" after 100 ns;
	dest_data_s <= X"00000010", X"00000005" after 100 ns;
	
	alu1: alu port map(enable_s, clk, opcode_s, dest_data_s, src_data_s, result_s);
end alu_tb;