library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_uart_loopback is
end entity;

architecture sim of tb_uart_loopback is
    constant CLOCK_PERIOD : time := 10 ns;
    constant CLKS_PER_BIT : positive := 10;

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal tx_start      : std_logic := '0';
    signal tx_data       : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy       : std_logic;
    signal tx_done       : std_logic;
    signal rx_data       : std_logic_vector(7 downto 0);
    signal rx_valid      : std_logic;
    signal framing_error : std_logic;

    signal expected_data : std_logic_vector(7 downto 0) := (others => '0');
    signal received_count : natural := 0;
begin
    clk <= not clk after CLOCK_PERIOD / 2;

    dut : entity work.uart_loopback
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            clk           => clk,
            reset         => reset,
            tx_start      => tx_start,
            tx_data       => tx_data,
            tx_busy       => tx_busy,
            tx_done       => tx_done,
            rx_data       => rx_data,
            rx_valid      => rx_valid,
            framing_error => framing_error
        );

    monitor : process
        variable previous_valid : std_logic := '0';
    begin
        wait until rising_edge(clk);
        wait for 1 ns;

        if reset = '1' then
            received_count <= 0;
            previous_valid := '0';
        else
            assert framing_error = '0'
                report "Unexpected framing error in loopback"
                severity failure;

            assert not (rx_valid = '1' and previous_valid = '1')
                report "rx_valid lasted more than one clock cycle"
                severity failure;

            if rx_valid = '1' then
                assert rx_data = expected_data
                    report "Expected " & to_hstring(expected_data)
                        & ", received " & to_hstring(rx_data)
                    severity failure;

                received_count <= received_count + 1;
            end if;

            previous_valid := rx_valid;
        end if;
    end process;

    stimulus : process
        variable payload : std_logic_vector(7 downto 0);

        procedure tick is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;
    begin
        tick;
        tick;

        wait until falling_edge(clk);
        reset <= '0';

        for byte_value in 0 to 255 loop
            payload := std_logic_vector(to_unsigned(byte_value, 8));

            wait until falling_edge(clk);
            expected_data <= payload;
            tx_data       <= payload;
            tx_start      <= '1';

            tick;
            tx_start <= '0';

            assert tx_busy = '1'
                report "Transmitter did not accept request"
                severity failure;

            tx_data <= not payload;

            for cycle in 1 to 10 * CLKS_PER_BIT + 2 loop
                tick;
                exit when tx_done = '1';
            end loop;

            assert tx_done = '1'
                report "Transmitter did not finish"
                severity failure;

            for cycle in 1 to 5 loop
                tick;
            end loop;

            assert received_count = byte_value + 1
                report "Missing or duplicate byte after sending "
                    & to_hstring(payload)
                severity failure;

            assert tx_busy = '0' and tx_done = '0'
                report "Transmitter did not return to idle"
                severity failure;
        end loop;

        report "PASS: all 256 byte values transmitted and received"
            severity note;

        stop;
        wait;
    end process;

    watchdog : process
    begin
        wait for 1 ms;
        assert false
            report "Loopback test timed out"
            severity failure;
        wait;
    end process;
end architecture;