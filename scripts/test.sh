#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p build/nvc
nvc --std=2008 --work=work:build/nvc -a \
    rtl/pulse_every_four.vhd \
    rtl/uart_tx.vhd \
    rtl/uart_rx.vhd \
    rtl/uart_loopback.vhd \
    tb/tb_pulse_every_four.vhd \
    tb/tb_uart_tx.vhd \
    tb/tb_uart_rx.vhd \
    tb/tb_uart_loopback.vhd \
    tb/tb_uart_rx_stream.vhd

echo "Running tb_pulse_every_four"

nvc --std=2008 --work=work:build/nvc -e tb_pulse_every_four
nvc --std=2008 --work=work:build/nvc -r tb_pulse_every_four \
    --exit-severity=error

for clocks_per_bit in 4 5 7 10 16 868
do
    for testbench in tb_uart_tx tb_uart_rx tb_uart_loopback tb_uart_rx_stream
    do
        echo "Running ${testbench}, CLKS_PER_BIT=${clocks_per_bit}"

        nvc --std=2008 --work=work:build/nvc \
            -e "$testbench" -g CLKS_PER_BIT="$clocks_per_bit"

        nvc --std=2008 --work=work:build/nvc \
            -r "$testbench" --exit-severity=error
    done
done

echo "PASS: pulse exercise and 24 UART test runs completed"

echo "PASS: all four testbenches completed"