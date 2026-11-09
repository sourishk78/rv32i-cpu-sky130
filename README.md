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
rtl/
├── cpu/                          CPU core (alu, cpu_pkg, cpu_top, fetch, reg_file, risc_decode)
├── CF_SRAM_1024x32.tt_180V_25C.v SRAM macro model
├── chip_top.sv                   top level connecting the CPU and memories
├── memory_controller.sv          arbitrates CPU and external access to the SRAMs
└── sram_wrapper.sv               wrapper around the SRAM macro
tb/                               self-checking testbench
docs/                             test plan, diagrams, screenshots
logs/                             simulation and assertion logs
scripts/                          Tcl flow scripts
reports/                          timing and area reports
```

## What I Learned

- **RTL design:** writing synthesizable SystemVerilog for a decoder, ALU, register file, and control FSM, and thinking in terms of hardware and clock cycles instead of sequential code.
- **Verification:** planning tests by failure mode (value boundaries, structural checks, history independence), writing self-checking tests, reading simulation logs, and using coverage and assertions to find what my tests were missing.
- **Physical design:** running synthesis and place and route, working through timing closure across SS, TT, and FF corners, and using Virtuoso and Pegasus to clear DRC and LVS violations.
- **The big picture:** how a design moves from RTL to GDS, and how a decision made at one stage, like how I wrote the RTL or constrained the clock, shows up later in timing and area.

## Author

Sourish Kanakala, Georgia Tech Computer Engineering
[LinkedIn](https://www.linkedin.com/in/sourish-kanakala)
