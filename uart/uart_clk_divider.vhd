library ieee;					
use ieee.std_logic_1164.all;
use work.lldevcpu_pack.all;

entity uart_clk_divider is						
	port(enable: in boolean; clk: in std_logic; delay_cnt: in baud_rate := uart_max_baud_rate_divider; out_s: out std_logic := '0');	
end entity uart_clk_divider;

architecture uart_clk_divider_arch of uart_clk_divider is
	subtype baud_rate_from_zero is integer range 0 to uart_max_baud_rate_divider;
begin
	clk_divider_proc: process(clk, enable)
		variable clk_cnt_v: baud_rate_from_zero := 0;
		variable out_v: std_logic := '0';
	begin
		if(enable and rising_edge(clk)) then		
			if(clk_cnt_v = 0) then
				case out_v is
					when '0' => 
						out_v := '1';
					when others =>
						out_v := '0';
				end case;
				
				clk_cnt_v := delay_cnt;
				out_s <= out_v;	
			end if;
			
			clk_cnt_v := clk_cnt_v - 1;
		end if;
	end process clk_divider_proc;
end uart_clk_divider_arch;