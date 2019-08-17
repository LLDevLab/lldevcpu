library ieee;
use ieee.std_logic_1164.all;

entity uat_tb is end;

architecture uat_tb of uat_tb is
	
	component uat is
		port(clk: in std_logic; enable: in boolean; data: in std_logic_vector(0 to 7); bit_out: out std_logic; ready: buffer boolean);
	end component;

	signal clk: std_logic := '0';
	signal enable_s: boolean;
	signal ready_s: boolean;
	signal data_s: std_logic_vector(0 to 7) := "00110011";
	signal bit_out_s: std_logic := '1';
begin
	clk <= not clk after 5 ns;
	enable_s <= ready_s;
	
	uat1: uat
		port map(clk, enable_s, data_s, bit_out_s, ready_s);
end uat_tb;