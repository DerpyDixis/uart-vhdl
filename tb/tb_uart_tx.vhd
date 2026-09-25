library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_uart_tx is
end entity;

architecture sim of tb_uart_tx is
    constant CLOCK_PERIOD : time := 10 ns;
    constant CLKS_PER_BIT : positive := 10;
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
        variable expected_bit : std_logic;
    begin
        wait until rising_edge(clk);
        wait for 1 ns;

        assert tx = '1' and busy = '0' and done = '0'
            report "Incorrect reset outputs"
            severity failure;

        wait until falling_edge(clk);
        reset <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert tx = '1' and busy = '0' and done = '0'
            report "Incorrect idle outputs"
            severity failure;

        -- 0x53 test
        wait until falling_edge(clk);
        data  <= TEST_BYTE;
        start <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        start <= '0';
        data  <= x"FF";

        for frame_bit in 0 to 9 loop
            if frame_bit = 0 then
                expected_bit := '0';             -- Start bit
            elsif frame_bit = 9 then
                expected_bit := '1';             -- Stop bit
            else
                expected_bit := TEST_BYTE(frame_bit - 1);
            end if;

            for cycle in 1 to CLKS_PER_BIT loop
                assert tx = expected_bit
                    report "Wrong tx value at frame bit "
                        & integer'image(frame_bit)
                        & ", cycle " & integer'image(cycle)
                    severity failure;

                assert busy = '1' and done = '0'
                    report "Incorrect busy/done during transmission"
                    severity failure;

                wait until rising_edge(clk);
                wait for 1 ns;
            end loop;
        end loop;

        assert tx = '1' and busy = '0' and done = '1'
            report "Incorrect completion outputs"
            severity failure;

        wait until rising_edge(clk);
        wait for 1 ns;

        assert tx = '1' and busy = '0' and done = '0'
            report "done did not clear or transmitter did not return idle"
            severity failure;

        report "PASS: TX frame, timing, data capture, and completion checked"
            severity note;
        stop;
        wait;
    end process;
end architecture;