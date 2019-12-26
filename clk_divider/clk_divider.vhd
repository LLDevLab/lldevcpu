library ieee;					
use ieee.std_logic_1164.all;

entity clk_divider is
	generic (delay_cnt: integer;
			out_s_initial: std_logic := '0');
	port(clk: in std_logic; out_s: out std_logic := out_s_initial);	
end entity clk_divider;

architecture clk_divider_arch of clk_divider is
begin
	clk_divider_proc: process(clk)
		variable clk_cnt: integer range 0 to delay_cnt := 0;
		variable out_v: std_logic := '0';
	begin
		if(rising_edge(clk)) then
			clk_cnt := clk_cnt + 1;					
				
			if(clk_cnt >= delay_cnt) then
				 
				case out_v is
					when '0' => 
						out_v := '1';
					when others =>
						out_v := '0';
				end case;
				
				clk_cnt := 0;
				out_s <= out_v;	
			end if;
		end if;
	end process clk_divider_proc;
end clk_divider_arch;