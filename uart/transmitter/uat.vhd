library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lldevcpu_pack.all;

-- Universal Asynchronous Transmitter
entity uat is
	port(clk: in std_logic; enable: in boolean; data: in data8; bit_out: out std_logic := '1'; ready: buffer boolean := true);
end entity;

architecture uat_arch of uat is
	constant max_cnt: integer := 10;
	
	function get_parity_bit(data_val: std_logic; prev_parity: std_logic) return std_logic is
		variable ret: std_logic := prev_parity;
	begin
		if(data_val = '1') then
			if(prev_parity = '1') then
				ret := '0';
			else
				ret := '1';
			end if;
		end if;
		
		return ret;
	end function;
begin
	process(clk, enable, ready)
		variable ready_v: boolean := true;
		variable clk_cnt: integer range 0 to max_cnt := 0;
		variable parity_bit: std_logic := '0';
		variable data_v: std_logic_vector(7 downto 0) := "00000000";
	begin
		if(rising_edge(clk)) then
			if(enable or not ready) then
				ready_v := false;
				
				case clk_cnt is
					when 0 =>
						bit_out <= '0';					-- pull uart down to signal of transmission start
						data_v := data;
					when (max_cnt - 1) =>
						bit_out <= parity_bit;
					when max_cnt =>
						bit_out <= '1';					-- end of transmission
						ready_v := true;
					when others =>
						parity_bit := get_parity_bit(data_v(clk_cnt - 1), parity_bit);
						bit_out <= data_v(clk_cnt - 1);
				end case;
				
				if(clk_cnt < max_cnt) then
					clk_cnt := clk_cnt + 1;
				else
					clk_cnt := 0;
					parity_bit := '0';
				end if;
			end if;
			
			ready <= ready_v;
		end if;
	end process;
end uat_arch;