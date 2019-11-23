library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lldevcpu_pack.all;

entity uart is
	port(clk: in std_logic; 
			data_out: in std_logic_vector(7 downto 0);		-- outgoint data
			settings: in unsigned16;
			tx_start_s: in boolean;
			bit_out: out std_logic;							-- outgoing data bit
			uart_clk: buffer std_logic := '0';
			tx_ready: buffer boolean := true);
end entity;
	
architecture uart_arch of uart is
	component uart_clk_divider is 
		port(clk: in std_logic; delay_cnt: in baud_rate; out_s: out std_logic := '0');
	end component;

	component uat is		-- universal asynchronous transmitter
		port(clk: in std_logic; enable: in boolean; data: in std_logic_vector(0 to 7); bit_out: out std_logic; ready: buffer boolean);
	end component;
	
	alias tx_enable_a: std_ulogic is settings(15);
	alias rx_enable_a: std_ulogic is settings(14);
	alias baud_rate_a: unsigned(2 downto 0) is settings(13 downto 11);
	
	signal tx_enable_s: boolean;
	signal uart_baud_rate_s: baud_rate := 2_604;
	
	function get_baud_rate(baud_rate_in: unsigned(2 downto 0)) return baud_rate is
	begin
		case baud_rate_in is
			when "110" => return 217;		-- baud rate 115200
			when others => return 2_604; 	-- baud rate 9600
		end case;
	end function;
begin
	uart_delay: uart_clk_divider port map(clk, uart_baud_rate_s, uart_clk);

	uat1: uat port map(uart_clk, tx_enable_s, data_out, bit_out, tx_ready);
	
	tx_enable_s <= tx_enable_a = '1' and tx_start_s;
	
	set_tx_baud_rate_proc: process(clk, tx_enable_a, baud_rate_a)
	begin
		-- when uart receiver and transmitter are disabled
		if(falling_edge(clk) and (tx_enable_a = '0' and rx_enable_a = '0')) then
			uart_baud_rate_s <= get_baud_rate(baud_rate_a);
		end if;
	end process set_tx_baud_rate_proc;
end uart_arch;