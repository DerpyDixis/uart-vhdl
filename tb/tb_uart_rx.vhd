library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_uart_rx is
end entity;

architecture sim of tb_uart_rx is
    constant CLOCK_PERIOD : time := 10 ns;
    constant CLKS_PER_BIT : positive := 10;
    constant BIT_PERIOD  : time := CLOCK_PERIOD * CLKS_PER_BIT;

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal rx            : std_logic := '1';
    signal data          : std_logic_vector(7 downto 0);
    signal data_valid    : std_logic;
    signal framing_error : std_logic;

    signal expected_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal expect_error   : boolean := false;
    signal received_count : natural := 0;
    signal error_count    : natural := 0;
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
        variable previous_valid : std_logic := '0';
        variable previous_error : std_logic := '0';
    begin
        wait until rising_edge(clk);
        wait for 1 ns;

        if reset = '1' then
            received_count <= 0;
            error_count    <= 0;
            previous_valid := '0';
            previous_error := '0';

            assert data = x"00"
                and data_valid = '0'
                and framing_error = '0'
                report "Incorrect reset outputs"
                severity failure;
        else
            assert not (data_valid = '1' and previous_valid = '1')
                report "data_valid lasted more than one clock cycle"
                severity failure;

            assert not (framing_error = '1' and previous_error = '1')
                report "framing_error lasted more than one clock cycle"
                severity failure;

            if data_valid = '1' then
                assert not expect_error
                    report "Invalid frame was accepted"
                    severity failure;

                assert data = expected_data
                    report "Wrong byte: expected "
                        & to_hstring(expected_data)
                        & ", received " & to_hstring(data)
                    severity failure;

                received_count <= received_count + 1;
            end if;

            if framing_error = '1' then
                assert expect_error
                    report "Unexpected framing error"
                    severity failure;

                error_count <= error_count + 1;
            end if;

            previous_valid := data_valid;
            previous_error := framing_error;
        end if;
    end process;

    stimulus : process
        procedure send_and_check(
            constant payload  : in std_logic_vector(7 downto 0);
            constant bad_stop : in boolean := false
        ) is
            variable received_before : natural;
            variable errors_before   : natural;
            variable data_before     : std_logic_vector(7 downto 0);
        begin
            received_before := received_count;
            errors_before   := error_count;
            data_before     := data;

            expected_data <= payload;
            expect_error  <= bad_stop;

            rx <= '0';
            wait for BIT_PERIOD;

            for bit_number in 0 to 7 loop
                rx <= payload(bit_number);
                wait for BIT_PERIOD;
            end loop;

            if bad_stop then
                rx <= '0';
            else
                rx <= '1';
            end if;
            wait for BIT_PERIOD;

            rx <= '1';
            wait for BIT_PERIOD;

            if bad_stop then
                assert received_count = received_before
                    report "Invalid frame produced a valid byte"
                    severity failure;

                assert error_count = errors_before + 1
                    report "Expected exactly one framing error"
                    severity failure;

                assert data = data_before
                    report "Invalid frame changed the accepted data"
                    severity failure;

                report "Passed invalid stop-bit test" severity note;
            else
                assert received_count = received_before + 1
                    report "Expected exactly one received byte"
                    severity failure;

                assert error_count = errors_before
                    report "Valid frame produced an error"
                    severity failure;

                report "Passed byte " & to_hstring(payload)
                    severity note;
            end if;

            assert data_valid = '0' and framing_error = '0'
                report "Output pulses did not clear"
                severity failure;
        end procedure;

        variable received_before : natural;
        variable errors_before   : natural;
    begin
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        reset <= '0';

        wait for 23 ns;

        send_and_check(x"00");
        send_and_check(x"FF");
        send_and_check(x"55");
        send_and_check(x"AA");
        send_and_check(x"53");

        send_and_check(x"A6", true);

        send_and_check(x"96");

        received_before := received_count;
        errors_before   := error_count;

        rx <= '0';
        wait for 2 * CLOCK_PERIOD;
        rx <= '1';

        wait for 12 * BIT_PERIOD;

        assert received_count = received_before
            and error_count = errors_before
            report "Short false start produced an output event"
            severity failure;

        report "Passed false-start test" severity note;
        report "PASS: RX data, framing errors, recovery, and false start checked"
            severity note;

        stop;
        wait;
    end process;

    watchdog : process
    begin
        wait for 20 us;
        assert false
            report "Testbench timed out"
            severity failure;
        wait;
    end process;
end architecture;