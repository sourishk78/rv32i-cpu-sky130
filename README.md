# RV32I-Subset CPU: Design, Verification, and Sky130 Physical Design

A compact multicycle CPU in SystemVerilog that executes a 9-instruction subset of the RISC-V RV32I ISA, verified with 21 self-checking tests and taken through a full RTL-to-GDS flow on the open-source SkyWater Sky130 process.

Built as part of the SiliconJackets (Georgia Tech IC design club) onboarding. Club-provided starter files are not included in this repository.

## Results

| Metric | Result |
|---|---|
| Clock frequency | 205.4 MHz (200 MHz clock constraint, +0.132 ns worst slack) |
| Total negative slack (TNS) | Improved by 327 ns through cell swapping |
| Core area | 1000.642 x 500.321 um = 500,642 um^2 |
| Instance count (post-route) | 6,457 |
| Total cell area (post-route) | 353,035.77 um^2 |
| DRC / LVS | 0 violations |
| Verification | 21 self-checking test cases, target code coverage reached |

<img width="970" height="500" alt="image" src="https://github.com/user-attachments/assets/0a7fe188-8656-4d3b-87bb-3b0eb97a6671" />


## Architecture

**ISA subset (9 instructions, R/I/S/B formats):** `addi`, `add`, `sub`, `lw`, `sw`, `beq`, `sll`, `srl`, `ebreak`

- **Decoder:** decodes all 9 instructions and generates immediates with sign extension for I-, S-, and B-type formats.
- **ALU:** shared between arithmetic and address calculation.
- **Control FSM:** two states (`NORMAL`, `MEM_WAIT`) to handle memory latency.
- **Memory interface:** the SRAMs are word-addressed, so computed byte addresses are shifted right by 2 bits before driving the data SRAM ports and the branch target.

<img width="908" height="500" alt="image" src="https://github.com/user-attachments/assets/9a142775-9619-4bc7-bf65-604585b82efe" />


## Verification

- Wrote a verification test plan covering all 9 instructions.
- 21 self-checking test cases: each test compares results against expected register and memory state and reports pass or fail automatically.
- Expanded the test suite iteratively until the target code coverage was reached.

## Physical Design (Sky130)

- Sized the core for about 50% utilization at a 2:1 aspect ratio, placed the SRAM macros abutted and fixed, and added power rings around them
- Enabled clock gating in synthesis
- Switched to the high-speed cell libraries in synthesis and place and route across SS, TT, and FF corners (TNS improved by 327 ns), reaching 205.4 MHz against a 200 MHz clock constraint
- Wrote a Tcl procedure using `get_db` to compute the design's total negative slack
- Cleared all DRC and LVS violations
- Edited the Tcl flow scripts for each stage

## Tools

SystemVerilog, Synopsys Design Compiler (synthesis), Cadence Innovus (place and route), Cadence Pegasus and Virtuoso (DRC/LVS), Tcl, Python, SkyWater Sky130 PDK

## Repository Layout

[Fill in once your folder is organized, for example:]

```
rtl/        SystemVerilog source
tb/         self-checking testbenches
docs/       test plan, diagrams, screenshots
scripts/    Tcl flow scripts
reports/    timing and area reports
```

## What I Learned

- [One or two sentences, in your own words, such as: timing closure means finding the worst paths first, and verification keeps catching what a passing test misses.]

## Author

Sourish Kanakala, Georgia Tech Computer Engineering
[LinkedIn](https://www.linkedin.com/in/sourish-kanakala)
