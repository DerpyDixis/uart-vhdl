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
    tb/tb_uart_loopback.vhd

for testbench in \
    tb_pulse_every_four \
    tb_uart_tx \
    tb_uart_rx \
    tb_uart_loopback
do
    echo "Running ${testbench}"

    nvc --std=2008 --work=work:build/nvc -e "$testbench"
    nvc --std=2008 --work=work:build/nvc -r "$testbench" \
        --exit-severity=error
done

echo "PASS: all four testbenches completed"