##MIPS PWM Motor Controller
##computer architecture
##robotics engineering
##2022028404 최제헌 Jeheon Choi
## 1. Introduction

This project combines a 5-stage pipelined MIPS processor, memory-mapped I/O
(MMIO), and an 8-bit PWM peripheral into one software-controlled motor system.
The design matters because it demonstrates the complete path from an assembly
instruction to a physical-style digital output: software reads an external
input, the CPU executes the control loop, an MMIO write updates a hardware
register, and the PWM circuit converts that register value into pulse width.

## 2. System Architecture

```text
                       +-------------------------------+
 switches[7:0] ------->| data_memory: MMIO read 0x90  |
                       +---------------+---------------+
                                       |
 +---------+   +---------+   +---------v-+   +---------+   +---------+
 |   IF    |-->|   ID    |-->|    EX     |-->|   MEM   |-->|   WB    |
 | PC/IMEM |   | decode  |   | ALU/fwd   |   | MMIO/RAM|   | regfile |
 +---------+   +---------+   +-----------+   +----+----+   +---------+
                                                  |
                                      duty 0x98 / enable 0x9c
                                                  |
                                           +------v------+
                                           | 8-bit PWM   |
                                           | counter/cmp |
                                           +------+------+
                                                  |
                                               pwm_out
```

The instruction-fetch stage supplies instructions and advances the PC. Decode
reads the register file, generates control signals, and resolves branches early.
Execute performs ALU operations with forwarding from later stages. Memory
contains ordinary RAM and the MMIO address decoder. Writeback returns load or ALU
results to the register file. The hazard unit inserts stalls for unavailable
load results and forwards values whenever possible.

## 3. MMIO Design

| Address | Device | Direction | Notes |
| --- | --- | --- | --- |
| `0x0000`-`0x008f` | RAM | Read/write | Word-addressed internal storage |
| `0x0090` | Switches | Read-only | `{24'b0, switches}` |
| `0x0098` | PWM duty | CPU write | Low 8 bits are stored |
| `0x009c` | PWM enable | CPU write | Low bit is stored |

`data_memory.v` decodes the full 32-bit ALU address with `case` statements.
Special addresses select the switch input or PWM registers; all other addresses
select RAM. Writes are synchronous so peripheral state changes only on a clock
edge, matching normal sequential hardware. Reads are combinational so a load's
memory-stage result is available without adding another cycle.

The MMIO registers use the active-low reset. Reset clears duty and enable,
guaranteeing that the motor output starts disabled.

## 4. PWM Controller Design

The PWM peripheral contains an 8-bit free-running counter and a comparator:

```text
counter <= counter + 1
pwm_out = enable && (counter < duty)
```

For duty `N`, the output is high for `N` counts in each 256-count period. Thus
the ideal duty ratio is `N / 256`; `0` is always low and `255` is high for 255
of 256 clocks. If the clock period is `T_clk`, then:

```text
T_pwm = 256 * T_clk
f_pwm = f_clk / 256
```

The testbench clock period is 10 ns, so the simulated PWM period is 2.56 us and
the PWM frequency is approximately 390.625 kHz.

## 5. Software Algorithm

Profile B was selected because it demonstrates both input and output MMIO while
allowing direct interactive speed control.

```text
enable PWM
forever:
    target = read switches at 0x90
    write target to PWM duty at 0x98
```

The program uses `$t0` as the switch address, `$t2` as the duty address, and
`$t1` as the transferred value. The loop is intentionally short: the processor
samples switches frequently, while the PWM register holds the most recent value
for the independent hardware counter. A `nop` occupies the jump delay slot.
Pipeline load-use handling stalls the dependent store until the loaded switch
value can be forwarded correctly.

Unlike ramp profiles, profile B does not need a software delay loop. Its update
rate is determined by the load/store/jump loop and pipeline hazard timing. The
testbench holds each input for longer than one complete PWM period so pulse width
can be measured reliably.

## 6. Reflection

The most difficult part was not the PWM controller itself, but checking whether the value loaded from the switch MMIO address was really reaching the PWM duty register. The PWM module was simple because it only used an 8-bit counter and a comparator. However, the full system could fail at several points: the top-level switch port, the MMIO address decoder, the store-data path, the load-use hazard handling, or the encoded machine instructions in memfile.dat.

To make the verification clearer, I used a self-checking testbench with four switch values: 0, 64, 128, and 255. This made it easier to confirm that pwm_duty followed switches and that pwm_out changed its pulse width accordingly.

If I had more time, I would add an FPGA wrapper with clock division and switch debouncing so that the design could be tested on a real board, not only in simulation.
Thank you for reading!
