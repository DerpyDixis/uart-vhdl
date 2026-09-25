library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_pulse_every_four is
end entity;

architecture sim of tb_pulse_every_four is
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal pulse : std_logic;
begin
    clk <= not clk after 5 ns;

    dut : entity work.pulse_every_four
        port map (
            clk   => clk,
            reset => reset,
            pulse => pulse
        );

    stimulus : process
    begin
        wait for 12 ns;
        reset <= '0';

        for edge_number in 1 to 12 loop
            wait until rising_edge(clk);
            wait for 1 ns; 
            if edge_number mod 4 = 0 then
                assert pulse = '1'
                    report "Missing pulse at edge " & integer'image(edge_number)
                    severity error;
            else
                assert pulse = '0'
                    report "Unexpected pulse at edge " & integer'image(edge_number)
                    severity error;
            end if;
        end loop;

        report "PASS: 12 clock edges checked" severity note;
        stop;
        wait;
    end process;
end architecture;