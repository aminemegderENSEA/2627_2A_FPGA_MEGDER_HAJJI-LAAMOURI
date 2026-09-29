library ieee;
use ieee.std_logic_1164.all;

entity tb_chenillard is
end entity;

architecture sim of tb_chenillard is
    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal leds  : std_logic_vector(9 downto 0);
begin
    clk <= not clk after 10 ns;  -- 50 MHz

    uut : entity work.chenillard
        generic map (G_DIV => 4, G_N => 10)
        port map (i_clk => clk, i_rst_n => rst_n, o_leds => leds);

    process
    begin
        rst_n <= '0';
        wait for 50 ns;
        rst_n <= '1';
        wait for 2 us;
        wait;
    end process;
end architecture;
