# Verification

This project implements an 8N1 UART transmitter and receiver in
VHDL-2008 (one start bit, eight data bits transmitted LSB first, no 
parity, one stop bit)

Verification uses self-checking testbenches with NVC. A failing
assertion causes the regression script and GitHub Actions job to fail.

## Running the tests

Install NVC, then run from the repository root:

```bash
bash scripts/test.sh
```

The regression runs the pulse-generator exercise once and four UART
testbenches at each of these CLKS_PER_BIT values:

4, 5, 7, 10, 16, and 868

This produces 25 testbench runs in total

## Test coverage

| Testbench | Checks |
|---|---|
| tb_pulse_every_four | Reset behavior and one pulse every four clock cycles |
| tb_uart_tx | Frame contents, bit duration, busy/done behavior, captured input data, reset during transmission, ignored busy-time requests, and held-high start behavior |
| tb_uart_rx | Valid frames, invalid stop bits, false starts, prolonged-low recovery, reset recovery, and selected baud-rate and start-phase variations |
| tb_uart_loopback | All 256 byte values transmitted through the connected TX and RX |
| tb_uart_rx_stream | All 256 byte values received as consecutive frames with no extra idle interval beyond the stop bit |

The RX timing sweep tests nominal baud rate and sender baud rates
2% faster and 2% slower. Each rate is tested at ten start-phase offsets
using both 0x55 and 0xAA, for 60 timing-sweep frames per clock divider.

These checks establish behavior for the tested combinations; they do
not establish the receiver's maximum baud-mismatch tolerance

## Interface behavior

- Reset is synchronous and active high
- TX captures the input byte when it accepts a start request
- Start requests during transmission are ignored, not queued
- A start signal held high can initiate another transmission when
  the transmitter returns to idle
- TX done and RX data_valid are one-clock-cycle pulses
- RX data remains available until another valid byte is received
  or reset is asserted
- An invalid stop bit produces a framing_error pulse
- After an invalid stop bit, RX waits for the line to return high
  before accepting another frame

## Waveforms

Generate a loopback waveform with:

```bash
bash scripts/waves.sh
```

Open `build/waves/uart_loopback.vcd` in a VCD viewer such as Surfer.

The waveform run uses a 10 ns clock period and CLKS_PER_BIT=10:
100 ns per UART bit and 1 microsecond per 8N1 frame.

Generated waveforms and simulator working files are excluded from Git.

## Limitations

- Results are from RTL simulation
- FPGA synthesis, implementation timing, and physical-board operation
  have not been verified
- Digital simulation does not model analog metastability
- The design does not implement parity, FIFOs, or hardware flow control
- The loopback test shares a clock between TX and RX. Separate RX
  tests exercise selected sender timing differences