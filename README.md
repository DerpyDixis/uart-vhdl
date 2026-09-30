# VHDL-2008 UART (8N1)

A basic 8N1 UART core (transmitter, receiver, and internal loopback) written in VHDL-2008 to practice RTL state machines, clock divider timing, and writing self-checking testbenches

## Implementation Details

- **Format:** 8 data bits, no parity, 1 stop bit (LSB first)
- **Timing:** Configured via a `CLKS_PER_BIT` generic (`baud = f_clk / CLKS_PER_BIT`)
- **RX Synchronization & Sampling:** RX input passes through a 2-stage synchronizer to mitigate metastability. A start bit is confirmed halfway through bit 0 (`CLKS_PER_BIT / 2`); subsequent data and stop bits are sampled at their midpoints
- **Error Handling:** RX flags framing errors if the stop bit isn't high, then returns to `IDLE` on the next detected rising edge/idle period
- **Resets:** Fully synchronous, active-high throughout

> **Note on baud divider:** `CLKS_PER_BIT` must be ≥ 4 for the mid-bit sampler to resolve cleanly. Non-integer ratios will introduce slight baud frequency error

## Repo Structure

```text
├── rtl/
│   ├── uart_tx.vhd           # Serializer / FSM
│   ├── uart_rx.vhd           # Deserializer, 2FF sync, center-sampling
│   ├── uart_loopback.vhd     # TX-to-RX top-level wrapper
│   └── pulse_every_four.vhd  # Initial clock divider test module
├── tb/                       # Self-checking testbenches
└── scripts/
    └── test.sh               # Runs NVC simulation flow
```

## Running Simulations

Requires [NVC](https://github.com/nickg/nvc) and Bash

```sh
./scripts/test.sh
```

Simulation artifacts build into `build/nvc/`. The test suite covers:
- Mid-bit TX/RX timing and pulse widths
- Mid-frame synchronous reset behavior
- False-start rejection on glitches < 0.5 bit periods
- Framing error detection and re-sync on missing stop bits
- 256-byte exhaustive loopback (`0x00` to `0xFF`)

*Simulations currently run at `CLKS_PER_BIT = 10` on a 100 MHz clock (10 ns period) for fast iteration (10 Mbaud equivalent)*

## To-Do / Known Scope Limits

- [ ] Synthesis run and timing closure on hardware
- [ ] 3-sample majority voting on RX data bits (currently single center-sample)
- [ ] TX/RX FIFOs to decouple transmission from byte-by-byte polling
- [ ] Test bench for clock phase offsets and small ±% baud mismatches

See [Verification](docs/verification.md) for test coverage, interface
behavior, waveform instructions, and limitations.