library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_uart_tx is
    generic(
        CLKS_PER_BIT : positive := 10
    );
end entity;

architecture sim of tb_uart_tx is
    constant CLOCK_PERIOD : time := 10 ns;
    constant TEST_BYTE    : std_logic_vector(7 downto 0) := x"53";

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal start : std_logic := '0';
    signal data  : std_logic_vector(7 downto 0) := (others => '0');
    signal tx    : std_logic;
    signal busy  : std_logic;
    signal done  : std_logic;
begin
    clk <= not clk after CLOCK_PERIOD / 2;

    dut : entity work.uart_tx
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            clk   => clk,
            reset => reset,
            start => start,
            data  => data,
            tx    => tx,
            busy  => busy,
            done  => done
        );

        stimulus : process

        procedure tick is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        procedure send_and_check(
            constant payload             : in std_logic_vector(7 downto 0);
            constant inject_busy_request : in boolean := false;
            constant keep_start_high     : in boolean := false
        ) is
            variable expected_bit : std_logic;
        begin
            wait until falling_edge(clk);
            data  <= payload;
            start <= '1';

            tick; 
            
            if not keep_start_high then
                start <= '0';
            end if;
            data  <= not payload;  

            for frame_bit in 0 to 9 loop
                if frame_bit = 0 then
                    expected_bit := '0';
                elsif frame_bit = 9 then
                    expected_bit := '1';
                else
                    expected_bit := payload(frame_bit - 1);
                end if;

                for cycle in 1 to CLKS_PER_BIT loop
                    assert tx = expected_bit
                        report "Wrong tx for byte "
                            & to_hstring(payload)
                            & ", frame bit " & integer'image(frame_bit)
                            & ", cycle " & integer'image(cycle)
                        severity failure;

                    assert busy = '1' and done = '0'
                        report "Incorrect busy/done during transmission"
                        severity failure;
                        if inject_busy_request then
                            if frame_bit = 3 and cycle = 1 then
                                start <= '1';
                            elsif frame_bit = 3 and cycle = 2 then
                                start <= '0';
                            end if;
                        end if;
                    tick;
                end loop;
            end loop;

            assert tx = '1' and busy = '0' and done = '1'
                report "Incorrect completion outputs"
                severity failure;

            report "Passed byte " & to_hstring(payload)
                severity note;
        end procedure;

    begin
        tick;

        assert tx = '1' and busy = '0' and done = '0'
            report "Incorrect reset outputs"
            severity failure;

        wait until falling_edge(clk);
        reset <= '0';

        tick;

        assert tx = '1' and busy = '0' and done = '0'
            report "Incorrect idle outputs"
            severity failure;

        send_and_check(x"00");
        send_and_check(x"FF");
        send_and_check(x"55");
        send_and_check(x"AA");
        send_and_check(x"53");

        tick;

        assert tx = '1' and busy = '0' and done = '0'
            report "done did not clear after completion"
            severity failure;

        wait until falling_edge(clk);
        data  <= x"00";
        start <= '1';

        tick;
        start <= '0';

        for cycle in 1 to CLKS_PER_BIT + 3 loop
            tick;
        end loop;

        assert busy = '1'
            report "Transmitter was not busy before reset test"
            severity failure;

        wait until falling_edge(clk);
        reset <= '1';

        tick;

        assert tx = '1' and busy = '0' and done = '0'
            report "Reset failed to abort transmission"
            severity failure;

        tick;

        assert tx = '1' and busy = '0' and done = '0'
            report "Outputs changed while reset was held"
            severity failure;

        wait until falling_edge(clk);
        reset <= '0';

        send_and_check(x"96");

        tick;

        assert tx = '1' and busy = '0' and done = '0'
            report "Incorrect idle outputs after recovery"
            severity failure;

        report "PASS: multiple TX frames and reset recovery checked"
            severity note;
        
        send_and_check(
            payload             => x"C3",
            inject_busy_request => true
        );

        for cycle in 1 to 10 * CLKS_PER_BIT + 2 loop
            tick;

            assert tx = '1' and busy = '0' and done = '0'
                report "Busy-time request caused an extra transmission"
                severity failure;
        end loop;

        report "Passed ignored busy-time request test" severity note;

        send_and_check(
            payload         => x"12",
            keep_start_high => true
        );


        send_and_check(x"34");

        tick;

        assert tx = '1' and busy = '0' and done = '0'
            report "Incorrect idle outputs after held-start test"
            severity failure;

        report "Passed held-high start test" severity note;

        report "PASS: TX frames, reset recovery, and start-request behavior checked"
            severity note;

        stop;
        wait;
    end process;
    watchdog : process
    begin
        wait for 200 * CLKS_PER_BIT * CLOCK_PERIOD;
        assert false
            report "TX testbench timed out"
            severity failure;
        wait;
    end process;
end architecture;