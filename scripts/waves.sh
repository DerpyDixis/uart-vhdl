#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

mkdir -p build/waves

nvc --std=2008 --work=work:build/waves-work -a \
    rtl/uart_tx.vhd \
    rtl/uart_rx.vhd \
    rtl/uart_loopback.vhd \
    tb/tb_uart_loopback.vhd

nvc --std=2008 --work=work:build/waves-work \
    -e tb_uart_loopback \
    -g CLKS_PER_BIT=10 \
    --no-collapse

nvc --std=2008 --work=work:build/waves-work \
    -r tb_uart_loopback \
    --format=vcd \
    --wave=build/waves/uart_loopback.vcd \
    --exit-severity=error

echo "Waveform saved to build/waves/uart_loopback.vcd"