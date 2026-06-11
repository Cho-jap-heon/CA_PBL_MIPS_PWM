# MIPS PWM Motor Controller

A 5-stage pipelined MIPS processor that reads an 8-bit switch value through
memory-mapped I/O and converts it into a PWM motor-control signal.

## System Block Diagram

```text
 switches[7:0] -> MMIO 0x90 -> MIPS CPU -> MMIO 0x98 -> PWM controller -> pwm_out
                                    |
                                    +------ MMIO 0x9c (enable)
```

The implementation uses motor profile **B**: software continuously reads the
switches and writes the same value to the PWM duty register.

## MMIO Address Map

| Address | Device | Direction | Notes |
| --- | --- | --- | --- |
| `0x0000`-`0x008f` | RAM | Read/write | Normal data memory |
| `0x0090` | Switches | Read-only | Zero-extended 8-bit input |
| `0x0098` | PWM duty | Write/read for debug | `0`-`255` maps to `0`-near `100%` |
| `0x009c` | PWM enable | Write/read for debug | Bit 0 enables PWM |

## Build and Run

Requirements: Icarus Verilog, GNU Make, and GTKWave.

```sh
cd class_13
make
gtkwave mips.vcd
```

`make` compiles with warnings enabled, runs the self-checking testbench, and
creates `mips.vcd`. A successful run prints four switch-to-duty checks followed
by `PASS: Profile B MMIO and PWM simulation completed`.

## Expected Waveform

The testbench drives `switches` through `0`, `64`, `128`, and `255`. The internal
`pwm_duty` register follows each value after the software loop reads `0x90` and
writes `0x98`. The high portion of `pwm_out` grows from no pulses, to about 25%,
to 50%, and finally to nearly 100% of each 256-clock PWM period.

## File Layout

```text
class_13/
|-- README.md
|-- Makefile
|-- motor_control.asm
|-- memfile.dat
|-- mips.v
|-- mips_tb.v
|-- datapath.v
|-- data_memory.v
|-- pwm_controller.v
|-- hazard_unit.v
|-- other CPU modules
`-- docs/
    |-- design_report.md
    |-- test_report.md
    `-- waveform_profile.png
```

See [docs/design_report.md](docs/design_report.md) for architecture details and
[docs/test_report.md](docs/test_report.md) for verification results.
