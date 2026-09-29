library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_uart_rx_stream is
    generic (
        CLKS_PER_BIT : positive := 10
    );
end entity;

architecture sim of tb_uart_rx_stream is
    constant CLOCK_PERIOD : time := 10 ns;
    constant BIT_PERIOD   : time := CLOCK_PERIOD * CLKS_PER_BIT;
    constant FRAME_COUNT  : positive := 256;

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal rx            : std_logic := '1';
    signal data          : std_logic_vector(7 downto 0);
    signal data_valid    : std_logic;
    signal framing_error : std_logic;

    signal received_count : natural := 0;
begin
    clk <= not clk after CLOCK_PERIOD / 2;

    dut : entity work.uart_rx
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            clk           => clk,
            reset         => reset,
            rx            => rx,
            data          => data,
            data_valid    => data_valid,
            framing_error => framing_error
        );

    monitor : process
        variable expected_byte : std_logic_vector(7 downto 0);
        variable previous_valid : std_logic := '0';
    begin
        wait until rising_edge(clk);
        wait for 1 ns;

        if reset = '1' then
            received_count <= 0;
            previous_valid := '0';
        else
            assert framing_error = '0'
                report "Framing error during continuous stream"
                severity failure;

            assert not (data_valid = '1' and previous_valid = '1')
                report "data_valid lasted more than one clock cycle"
                severity failure;

            if data_valid = '1' then
                assert received_count < FRAME_COUNT
                    report "Received an unexpected extra byte"
                    severity failure;

                expected_byte :=
                    std_logic_vector(to_unsigned(received_count, 8));

                assert data = expected_byte
                    report "Stream mismatch: expected "
                        & to_hstring(expected_byte)
                        & ", received " & to_hstring(data)
                    severity failure;

                received_count <= received_count + 1;
            end if;

            previous_valid := data_valid;
        end if;
    end process;

    stimulus : process
        variable payload : std_logic_vector(7 downto 0);
    begin
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        reset <= '0';

        wait for 23 ns;

        for byte_value in 0 to FRAME_COUNT - 1 loop
            payload := std_logic_vector(to_unsigned(byte_value, 8));

            rx <= '0';
            wait for BIT_PERIOD;

            for bit_number in 0 to 7 loop
                rx <= payload(bit_number);
                wait for BIT_PERIOD;
            end loop;

            rx <= '1';
            wait for BIT_PERIOD;

        end loop;

        wait for 2 * BIT_PERIOD;

        assert received_count = FRAME_COUNT
            report "Stream incomplete: received "
                & integer'image(received_count)
                & " of " & integer'image(FRAME_COUNT) & " bytes"
            severity failure;

        assert data = x"FF"
            and data_valid = '0'
            and framing_error = '0'
            report "Incorrect outputs after continuous stream"
            severity failure;

        report "PASS: 256 consecutive RX frames with no extra idle gap"
            severity note;

        stop;
        wait;
    end process;

    watchdog : process
    begin
        wait for (FRAME_COUNT + 10) * 10 * BIT_PERIOD;
        assert false
            report "Continuous RX test timed out"
            severity failure;
        wait;
    end process;
end architecture;