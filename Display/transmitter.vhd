library ieee;
use ieee.std_logic_1164.all;

entity transmitter is
	port(enable: in boolean; clk: in std_logic; digit_pos: in std_logic_vector(7 downto 0) := X"00"; digit: in std_logic_vector(7 downto 0) := X"00"; sclk, dio: out std_logic := '0'; ready: buffer boolean := true);
end entity transmitter;

architecture transmitter_arch of transmitter is
	constant max_int: integer := 16;
begin
	sclk <= clk when not ready else '0';		

	send_proc: process(clk, enable, ready)
		variable dio_cnt_v: integer range 0 to max_int := 0;
		variable data_v: std_logic_vector((max_int - 1) downto 0);		
	begin		
		if(falling_edge(clk) and (enable or not ready)) then
			if(dio_cnt_v = 0) then			
				data_v := digit_pos & digit;
				ready <= false;
			end if;			
			
			if(dio_cnt_v = max_int) then				
				dio_cnt_v := 0;
				ready <= true;
				dio <= '0';
			else	
				dio <= data_v(dio_cnt_v);
				dio_cnt_v := dio_cnt_v + 1;
			end if;
		end if;
	end process send_proc;
end transmitter_arch;