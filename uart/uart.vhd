library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lldevcpu_pack.all;

entity uart is
	port(clk: in std_logic; 
			tx_data: in data8;								-- outgoint data
			control_bits: in unsigned16;
			bit_out: out std_logic;							-- outgoing data bit
			tx_started: out boolean;
			tx_ready: buffer boolean := true);
end entity;
	
architecture uart_arch of uart is
	component uart_clk_divider is 
		port(enable: in boolean; clk: in std_logic; delay_cnt: in baud_rate; out_s: out std_logic := '0');
	end component;

	component uat is		-- universal asynchronous transmitter
		port(clk: in std_logic; enable: in boolean; data: in std_logic_vector(0 to 7); bit_out: out std_logic; ready: buffer boolean);
	end component;
	
	signal tx_enable_s: boolean;
	signal tx_clk_enable_s: boolean;
	signal uart_baud_rate_s: baud_rate := 2_604;
	signal uart_clk_s: std_logic := '0';
	signal tx_ready_s: boolean := true;
	signal uat_ready_s: boolean := true;
	
	alias tx_enable_a: std_ulogic is control_bits(uart_tx_enable_bit);
	alias rx_enable_a: std_ulogic is control_bits(14);
	alias baud_rate_a: unsigned(2 downto 0) is control_bits(13 downto 11);
	alias tx_started_a: std_ulogic is control_bits(uart_tx_started_bit);
	
	function get_baud_rate(baud_rate_in: unsigned(2 downto 0)) return baud_rate is
	begin
		case baud_rate_in is
			when "110" => return 217;		-- baud rate 115200
			when others => return 2_604; 	-- baud rate 9600
		end case;
	end function;
begin
	tx_clk_enable_s <= true when tx_enable_a = '1' else false;
	tx_ready <= tx_ready_s;
	uart_tx_delay: uart_clk_divider port map(tx_clk_enable_s, clk, uart_baud_rate_s, uart_clk_s);

	uat1: uat port map(uart_clk_s, tx_enable_s, tx_data, bit_out, uat_ready_s);
	
	transmit_proc: process(clk, tx_enable_a, tx_started_a, uat_ready_s)
		variable tx_started_v: boolean;
		variable tx_enable_v: boolean;
		variable prev_tx_started_a_v: std_logic := '0';
	begin
		if(tx_enable_a = '1' and falling_edge(clk)) then
			if(tx_started_a = '1') then
				if(uat_ready_s and not tx_started_v) then
					tx_enable_v := true;				
					tx_started_v := true;
					tx_ready_s <= false;
				elsif(not uat_ready_s) then
					tx_enable_v := false;
				elsif(not tx_enable_v and uat_ready_s and tx_started_v) then
					tx_started_v := not (prev_tx_started_a_v = '0' and tx_started_a = '1');
					tx_ready_s <= true;
				end if;
			end if;
			
			prev_tx_started_a_v := tx_started_a;
			tx_enable_s <= tx_enable_v;
			tx_started <= tx_started_v;
		end if;
	end process transmit_proc;
	
	set_tx_baud_rate_proc: process(clk, tx_enable_a, rx_enable_a, baud_rate_a)
	begin
		-- when uart receiver and transmitter are disabled
		if(falling_edge(clk) and (tx_enable_a = '0' and rx_enable_a = '0')) then
			uart_baud_rate_s <= get_baud_rate(baud_rate_a);
		end if;
	end process set_tx_baud_rate_proc;
end uart_arch;