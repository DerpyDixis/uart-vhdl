# VHDL-2008 UART (8N1)

[![VHDL tests](https://github.com/rishiram-eng/uart-vhdl/actions/workflows/test.yml/badge.svg)](https://github.com/rishiram-eng/uart-vhdl/actions/workflows/test.yml)

A configurable UART transmitter and receiver implemented in VHDL-2008,
with self-checking testbenches, an internal loopback wrapper, and
automated regression testing through GitHub Actions.

The project demonstrates RTL state machines, serial communication,
input synchronization, and simulation-based verification.

## Design

- **Format:** One start bit, eight data bits transmitted LSB first, 
no parity, and one stop bit
- **Timing:** A `CLKS_PER_BIT` generic sets the bit duration:
  `baud = clock_frequency / CLKS_PER_BIT`
- **Receiver:** A two-stage input synchronizer followed by start-bit
  confirmation and one sample per data/stop bit near its center.
  Sampling timing includes synchronization delay and clock quantization
- **Framing errors:** A low stop-bit sample raises `framing_error`
  The receiver then waits for the synchronized input to return high
- **Reset:** Synchronous and active high
- **TX requests:** Input data is captured when a request is accepted.
  Requests while busy are ignored. Holding start high can initiate
  another frame when TX returns to idle

The receiver requires `CLKS_PER_BIT >= 4`. When the desired clock-to-baud
ratio is not an integer, the selected divider introduces baud-rate error.

## Repository Structure

- `rtl/uart_tx.vhd` — UART transmitter
- `rtl/uart_rx.vhd` — UART receiver
- `rtl/uart_loopback.vhd` — Internal TX-to-RX connection
- `rtl/pulse_every_four.vhd` — Introductory counter/pulse exercise
- `tb/` — Self-checking testbenches
- `scripts/test.sh` — Full regression
- `scripts/waves.sh` — Loopback waveform generation
- `docs/verification.md` — Verification details and limitations
- `.github/workflows/test.yml` — GitHub Actions workflow

## Run the Tests

Requires [NVC](https://github.com/nickg/nvc) and Bash.
Run from the repository root:

```bash
bash scripts/test.sh
```

The regression runs four UART testbenches at each of six
`CLKS_PER_BIT` values: 4, 5, 7, 10, 16, and 868.

Together with the introductory pulse test, this produces 25 testbench
runs. All testbenches use a 10 ns clock period.

Coverage includes:

- TX bit values, bit durations, data capture, and request behavior
- Reset during transmission and reception
- Selected false-start, framing-error, and prolonged-low scenarios
- All 256 byte values through internal loopback
- All 256 byte values in consecutive RX frames
- Nominal and ±2% sender baud rates at ten start-phase offsets,
  using 0x55 and 0xAA

GitHub Actions runs the same regression on pushes and pull requests.
Assertion failures cause the job to fail.

See [Verification](docs/verification.md) for detailed coverage,
interface behavior, and limitations.

## Inspect Waveforms

```bash
bash scripts/waves.sh
```

Open `build/waves/uart_loopback.vcd` in a waveform viewer such as Surfer.

This waveform run uses `CLKS_PER_BIT=10`: 100 ns per bit and
1 microsecond per 8N1 frame.

Generated simulation files are stored under `build/` and excluded
from Git.

## Verification Status and Scope

The design has been verified in RTL simulation using NVC, including
automated runs on GitHub Actions.

FPGA synthesis, implementation timing, and physical-board operation
have not been verified. The simulated 100 MHz clock is a testbench
setting, not a demonstrated hardware operating frequency.

The design does not include parity, FIFOs, hardware flow control, or
majority-vote sampling. Digital simulation does not model analog
metastability, and the timing sweep does not establish maximum
baud-mismatch tolerance.