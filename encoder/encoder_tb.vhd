library ieee;
use ieee.std_logic_1164.all;

entity encoder_tb is
end entity encoder_tb;

architecture sim of encoder_tb is
    constant CLK_PERIOD : time := 20 ns;
    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal ch_a  : std_logic := '0';
    signal ch_b  : std_logic := '0';
    signal pb    : std_logic := '1';
    signal count : natural range 0 to 7 := 0;

    procedure wait_clocks(signal c : in std_logic; constant n : in positive) is
    begin
        for k in 1 to n loop
            wait until rising_edge(c);
        end loop;
    end procedure;

    -- Sens qui incremente selon les conditions de fronts du sujet.
    -- Un cycle complet compte deux fronts d'incrementation.
    procedure forward_cycle(signal a, b : inout std_logic; signal c : in std_logic) is
    begin
        -- 00 -> 10 : A monte, B=0 : +1
        a <= '1'; wait_clocks(c, 4);
        -- 10 -> 11 : B monte, A=1 : pas de decrement
        b <= '1'; wait_clocks(c, 4);
        -- 11 -> 01 : A descend, B=1 : +1
        a <= '0'; wait_clocks(c, 4);
        -- 01 -> 00 : B descend, A=0 : pas de decrement
        b <= '0'; wait_clocks(c, 4);
    end procedure;

    -- Sens qui decremente selon les conditions de fronts du sujet.
    procedure reverse_cycle(signal a, b : inout std_logic; signal c : in std_logic) is
    begin
        -- 00 -> 01 : B monte, A=0 : -1
        b <= '1'; wait_clocks(c, 4);
        -- 01 -> 11 : A monte, B=1 : pas d'increment
        a <= '1'; wait_clocks(c, 4);
        -- 11 -> 10 : B descend, A=1 : -1
        b <= '0'; wait_clocks(c, 4);
        -- 10 -> 00 : A descend, B=0 : pas d'increment
        a <= '0'; wait_clocks(c, 4);
    end procedure;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.encoder
        generic map (max_count => 8)
        port map (
            i_clk => clk,
            i_rst_n => rst_n,
            i_ch_a => ch_a,
            i_ch_b => ch_b,
            i_pb => pb,
            o_count => count
        );

    stimulus : process
    begin
        -- Reset general actif bas.
        rst_n <= '0';
        wait_clocks(clk, 3);
        rst_n <= '1';
        wait_clocks(clk, 6);

        forward_cycle(ch_a, ch_b, clk);
        wait_clocks(clk, 3);
        assert count = 2
            report "ECHEC : un cycle positif doit incrementer deux fois" severity error;

        forward_cycle(ch_a, ch_b, clk);
        wait_clocks(clk, 3);
        assert count = 4
            report "ECHEC : deux cycles positifs doivent donner 4" severity error;

        reverse_cycle(ch_a, ch_b, clk);
        wait_clocks(clk, 3);
        assert count = 2
            report "ECHEC : un cycle negatif doit decrementer deux fois" severity error;

        -- Remise a zero par le bouton-poussoir actif bas.
        pb <= '0';
        wait_clocks(clk, 4);
        pb <= '1';
        wait_clocks(clk, 3);
        assert count = 0
            report "ECHEC : le bouton doit remettre le compteur a zero" severity error;

        -- Saturation haute : le compteur ne doit pas depasser max_count-1 (=7).
        for k in 1 to 5 loop
            forward_cycle(ch_a, ch_b, clk);
        end loop;
        wait_clocks(clk, 3);
        assert count = 7
            report "ECHEC : le compteur doit rester borne a 7" severity error;

        -- Un cycle de plus ne doit pas provoquer de debordement.
        forward_cycle(ch_a, ch_b, clk);
        wait_clocks(clk, 3);
        assert count = 7
            report "ECHEC : le compteur ne doit pas deborder" severity error;

        report "SUCCES : tests encodeur termines sans assertion en echec" severity note;
        wait;
    end process;
end architecture sim;
