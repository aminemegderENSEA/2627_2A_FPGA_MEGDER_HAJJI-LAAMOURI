library ieee;
use ieee.std_logic_1164.all;

entity chenillard is
    port (
        i_clk   : in  std_logic;
        i_rst_n : in  std_logic;
        o_leds   : out std_logic_vector(9 downto 0)
    );
end entity chenillard;

architecture rtl of chenillard is
    signal r_leds       : std_logic_vector(9 downto 0) := "0000000001";
    signal r_led_enable : std_logic := '0';
begin

    process(i_clk, i_rst_n)
        variable counter : natural range 0 to 5000000 := 0;
    begin
        if (i_rst_n = '0') then
            counter := 0;
            r_led_enable <= '0';

        elsif rising_edge(i_clk) then
            if counter = 5000000 then
                counter := 0;
                r_led_enable <= '1';
            else
                counter := counter + 1;
                r_led_enable <= '0';
            end if;
        end if;
    end process;


    process(i_clk, i_rst_n)
        variable count : natural range 0 to 9 := 0;
    begin
        if (i_rst_n = '0') then
            r_leds <= "0000000000";
            count := 0;

        elsif rising_edge(i_clk) then
            if r_led_enable = '1' then

                if count = 9 then
                    count := 0;
                else
                    count := count + 1;
                end if;

                r_leds <= (others => '0');
                r_leds(count) <= '1';

            end if;
        end if;
    end process;

    o_leds <= r_leds;

end architecture rtl;
