library ieee;
use ieee.std_logic_1164.all;

entity chenillard is
    generic (
        G_DIV : natural := 5000000;  -- ~100 ms à 50 MHz
        G_N   : natural := 10        -- nombre de LED
    );
    port (
        i_clk   : in  std_logic;
        i_rst_n : in  std_logic;
        o_leds  : out std_logic_vector(G_N-1 downto 0)
    );
end entity chenillard;

architecture rtl of chenillard is
    signal r_enable : std_logic := '0';
    signal r_leds   : std_logic_vector(G_N-1 downto 0);
begin
    -- Diviseur de fréquence
    process(i_clk, i_rst_n)
        variable counter : natural range 0 to G_DIV := 0;
    begin
        if (i_rst_n = '0') then
            counter := 0;
            r_enable <= '0';
        elsif (rising_edge(i_clk)) then
            if (counter = G_DIV) then
                counter := 0;
                r_enable <= '1';
            else
                counter := counter + 1;
                r_enable <= '0';
            end if;
        end if;
    end process;

    -- Registre à décalage circulaire
    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_leds <= (0 => '1', others => '0');
        elsif (rising_edge(i_clk)) then
            if (r_enable = '1') then
                r_leds <= r_leds(G_N-2 downto 0) & r_leds(G_N-1);
            end if;
        end if;
    end process;

    o_leds <= r_leds;
end architecture rtl;
