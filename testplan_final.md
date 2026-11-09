## 1. Functional tests

This test plan will test three categories for possible bugs for each instruction type.
1. Value boundaries
  The largest/smallest possible values a field can hold.
2. Structural verification
  Behavior that should hold by construction, like reading the same register through two different ports
3. History independence
  Whether or not the accuracy of a process depends on where/when the instruction appears.
Many tests listed below ar not expected to fail but are still being tested because they make sure an encrypted implementation still uphold the same guarantee.

### Functional-test summary

| Test ID | Test name | Functionality being tested | Expected result | Status |
| --- | --- | --- | --- | --- |
| 1.1 | `ADDI_MIN` | addi with immediate -2048, most negative 12-bit value | x1 = -2048 | Executed |
| 1.2 | `ADDI_ZERO` | addi with immediate 0 | x1 = 0 | Executed |
| 1.3 | `ADDI_MAX` | addi with immediate 2047, larget positive 12-bit value  | x1 = 2047 | Executed |
| 1.4 | `SLL_ZERO` | sll shift amount 0 | result unchanged | Executed |
| 1.5 | `SLL_MAX` | sll shift amount 31 | old bit 0 shifted to new bit 31, new bits 0-30 hold 0s | Executed |
| 1.6 | `SRL_ZERO` | srl shift amount 0 | result unchanged | Executed |
| 1.7 | `SRL_MAX` | srl shift amount 31 | old bit 31 shifted to new bit 0, new bits 1-31 hold 0s | Executed |
| 1.8 | `BEQ_SAME_REG` | beq with rs1 == rs2 | branch always taken | Executed |
| 1.9 | `ADD_POS_WRAP` | add with 4294967295 (max positive 32-bit value) and 1 | result wraps to 0 | Executed |
| 1.10 | `SUB_NEG_WRAP` | sub with -2147483648 (min negative 32-bit value) and -1 | result wraps to 0 | Executed |
| 1.11 | `LW_SW_ADDR_ZERO` | store word, load word at word address 0 | value read back matches value written, processes properly | Executed |
| 1.12 | `LW_SW_ADDR_MAX` | store word, load word at word address 0 | value read back matches value written, processes properly | Executed |
| 1.13 | `LW_ADDR_WRAP` | lw with byte address 4096, one past valid range | doesn't read 1 at bit-12, only reads 0s | Executed |
| 1.14 | `SW_LW_DEPEND` | sw then lw immediately after to the same address | lw returns the value stored, processes properly | Executed |
| 1.15 | `EBREAK_FIRST` | ebreak as the first instr in a program | cpu halts immediately, all registers stay at reset value | Plannned |
| 1.16 | `ADD_BASIC` | add with two small values | 	x3 = 7 | Executed
| 1.17 | `SUB_BASIC` | sub with two small values | 	x3 = 7 | Executed
| 1.18 | `RESET_MID` | reset while the cpu is running, then rerun | all registers and PC reset | Executed
| 1.19 | `EXT_HALT` | halt_cpu stops the cpu mid-program | 	cpu goes inactive | Executed
| 1.20 | `PC_HIGH_ADDR` | 250 instruction program | PC reachers high address| Executed
| 1.21 | `ISRAM_HIGH_ADDR` | write and read word 1023 | value matches | Executed



### Functional-test details

### 1.1 — `ADDI_MIN`

**Functionality:**
addi with the most negative possible 12-bit immediate (-2048), verifying correct sign extension in decode.

**Initial state:**

- Registers: all at reset value 0
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(-2048)),
  EBREAK_WORD
};  
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x1` | `32'hFFFFF800` | x0 (0) + (-2048); -2048 = 12'h800, sign extended to 32 bits|

**Pass criteria:**
CPU halts by ebreak within timeout. x1 holds the sign extended value, all other registers remain 0

**Final result:** PASS (TEST PASSED from make xrun)

### 1.2 — `ADDI_ZERO`

**Functionality:**
addi with the immediate 0, confirming the sign bit 0 path produces no unexpected sign extension errors

**Initial state:**

- Registers: all at reset value 0
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(0)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x1` | `32'h00000000` | x0 (0) + (0) = 0|

**Pass criteria:**
CPU halts by ebreak within timeout. x1 = 0.

**Final result:** PASS (TEST PASSED from make xrun)

### 1.3 — `ADDI_MAX`

**Functionality:**
addi with the most positive 12-bit immediate (2047), verifying the 0 sign-bit boundary

**Initial state:**

- Registers: all at reset value 0
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(2047)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x1` | `32'h000007FF` | x0 (0) + 2047 = 2047. 2047 = 12'h7FF, 0s fill to 32|

**Pass criteria:**
CPU halts by ebreak within timeout. x1 holds correct value.

**Final result:** PASS (TEST PASSED from make xrun)

### 1.4 — `SLL_ZERO`

**Functionality:**
sll with a shift amount of 0, identity case.

**Initial state:**

- Registers: x1 = some known non-zero value built from addi. x0 = shift amount 0, always 0.
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1234)),
  asm_instr(.op(OP_SLL), .rd(3), .rs1(1), .rs2(0)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'h000004D2` equal to x1 | shift by 0 leaves the value the same |

**Pass criteria:**
CPU halts by ebreak within timeout. x3 == x1

**Final result:** PASS (TEST PASSED from make xrun)

### 1.5 — `SLL_MAX`

**Functionality:**
sll with a shift amount of 31, maximum shift amount with 5 bits and confirms only rs2[4:0] is used.

**Initial state:**

- Registers: x1 = 32'h00000001. x2 = 32'h0000001F shift amount 31.
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)),
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(31)),
  asm_instr(.op(OP_SLL), .rd(3), .rs1(1), .rs2(2)),
  EBREAK_WORD
};
```
//makking sure ignores upper 27 bits
```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)),
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)),
  asm_instr(.op(OP_SLL), .rd(3), .rs1(1), .rs2(2)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'h80000000` | 1 shifted by 31 moves old bit 0 to new bit 31 |

**Pass criteria:**
CPU halts by ebreak within timeout. x3 = 32'h80000000.

**Final result:** PASS (TEST PASSED from make xrun)

### 1.6 — `SRL_ZERO`

**Functionality:**
srl with a shift amount of 0, identity case.

**Initial state:**

- Registers: x1 = some known non-zero value built from addi. x0 = shift amount 0, always 0.
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1234)),
  asm_instr(.op(OP_SRL), .rd(3), .rs1(1), .rs2(0)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'h000004D2`equal to x1| shift by 0 leaves the value the same |

**Pass criteria:**
CPU halts by ebreak within timeout.  x3 == x1.

**Final result:** PASS (TEST PASSED from make xrun)

### 1.7 — `SRL_MAX`

**Functionality:**
srl with a shift amount of 31, maximum shift amount with 5 bits and confirms only rs2[4:0] is used.

**Initial state:**

- Registers: x1 = 32'h00000001. x2 = 32'h0000001F shift amount 31.
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(31)), // dest. register 4 holds 31
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)), // dest. register 1 holds 1
  asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)), // dest. register 1 shifts src. register 1's value (x1) by src. register 4's value (x4)
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(31)),
  asm_instr(.op(OP_SRL), .rd(3), .rs1(1), .rs2(2)),
  EBREAK_WORD
};
```
//making sure ignores upper 27 bits
```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(31)),
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)), 
  asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)), 
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)), // -1 is 32'hFFFFFFFF, bottom 5 bits still 31
  asm_instr(.op(OP_SRL), .rd(3), .rs1(1), .rs2(2)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'h00000001` | 32'h80000000 moves old bit 31 to new bit 0 |

**Pass criteria:**
CPU halts by ebreak within timeout.  x3 = 1 (32'h00000001).

**Final result:** PASS (TEST PASSED from make xrun)

### 1.8 — `BEQ_SAME_REG`

**Functionality:**
beq comparing a register against itself. rs1 and rs2 are seperate address that happen to be equal. this verifies double read of the same register produces consistent values and the branch is correctly taken.

**Initial state:**

- Registers: x3 = any known value
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_BEQ), .rs1(3), .rs2(3), .imm(8)), 
  asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(999)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| control flow | branch taken | rs1 == rs2 |

**Pass criteria:**
CPU halts by ebreak at the branch target.  x3 = 1 (32'h00000001).

**Final result:** PASS (TEST PASSED from make xrun)

### 1.9 — `ADD_POS_WRAP`

**Functionality:**
add where the true sum goes beyond what can be represented in 32 bits. confiriming wraparound

**Initial state:**

- Registers: x1 = 32'hFFFFFFFF; x2 = 32'h00000001
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(-1)), 
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(1)),
  asm_instr(.op(OP_ADD), .rd(3), .rs1(1), .rs2(2)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | 32'h00000000 | 32'hFFFFFFFF + 1 wraps to 0 in binary math |

**Pass criteria:**
CPU halts by ebreak within timeout.  x3 = 0.

**Final result:** PASS (TEST PASSED from make xrun)

### 1.10 — `SUB_NEG_WRAP`

**Functionality:**
sub with biggest negative number and -1 so the true sum(or difference) exceeds whats represtentable in 32 bits.

**Initial state:**

- Registers: x1 = 32'h80000000
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(31)), 
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)),
  asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)),
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(1)),
  asm_instr(.op(OP_SUB), .rd(3), .rs1(1), .rs2(2)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'h7FFFFFFF` | 32'h80000000 - 1 wraps to 32'h7FFFFFFF |

**Pass criteria:**
CPU halts by ebreak within timeout.  x3 = 32'7FFFFFFF.

**Final result:** PASS (TEST PASSED from make xrun)

### 1.11 — `LW_SW_ADDR_ZERO`

**Functionality:**
sw then lw at word address 0

**Initial state:**

- Registers: base address held in x0, used as rs1. x2 = known value to store (32'hFFFFFFFF)
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)),
  asm_instr(.op(OP_SW), .rs1(0), .rs2(2), .imm(0)),
  asm_instr(.op(OP_LW), .rd(3), .rs1(0), .imm(0)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'hFFFFFFFF` | value stored by sw |
| `dmem[0]` | `32'hFFFFFFFF` | value loaded by lw |

**Pass criteria:**
CPU halts by ebreak within timeout.  x3 = stored value (32'hFFFFFFFF) and dmem[0] matches.

**Final result:** PASS (TEST PASSED from make xrun)

### 1.12 — `LW_SW_ADDR_MAX`

**Functionality:**
sw then lw at word address 1023, last valid dmem word

**Initial state:**

- Registers: x1 = 4092. x2 = known value (32'hFFFFFFFF)
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(2)),
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1023)),
  asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)),
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)),
  asm_instr(.op(OP_SW), .rs1(1), .rs2(2), .imm(0)),
  asm_instr(.op(OP_LW), .rd(3), .rs1(1), .imm(0)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'hFFFFFFFF` | value loaded back |
| `dmem[1023]` | `32'hFFFFFFFF` | last valid word address |

**Pass criteria:**
CPU halts by ebreak within timeout.  x3 = stored value (32'hFFFFFFFF) and dmem[1023] matches.

**Final result:** PASS (TEST PASSED from make xrun)

### 1.13 — `LW_SW_ADDR_WRAP`

**Functionality:**
lw with an effective byte address of 4096, one word past the valid range.

**Initial state:**

- Registers: x1 = 4080. x2 = known value (32'hFFFFFFFF)
- Data memory: word 0 preloaded
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(2)),
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1020)),
  asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)),
  asm_instr(.op(OP_LW), .rd(3), .rs1(1), .imm(16)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'hDEADBEEF` | dsram_addr_o = alu_mem_addr[11:2] drops bit 12. 4096's only set bit is bit 12, resolving to word address 0 |
| `dmem[0]` | `32'hDEADBEEF` | preloaded |

**Pass criteria:**
CPU halts by ebreak within timeout.  x3 = word 0 value. 

**Final result:** PASS (TEST PASSED from make xrun)

### 1.14 — `SW_LW_DEPEND`

**Functionality:**
sq immediately followed by lw to the same address, verifying fsm

**Initial state:**

- Registers: base address held in x0, x2 = known value, 32'hFFFFFFFF
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)),
  asm_instr(.op(OP_ADDI), .rd(0), .rs1(2), .imm(0)),
  asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)),
  asm_instr(.op(OP_LW), .rd(3), .rs1(0), .imm(0)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x3` | `32'hFFFFFFFF` | lw should see the value that sw just wrote |

**Pass criteria:**
CPU halts by ebreak within timeout.  x3 matches the stored valued on every run

**Final result:** PASS (TEST PASSED from make xrun)

### 1.15 — `EBREAK_FIRST`

**Functionality:**
ebreak as teh very first instr executed in a program. verifies fsm's transitions are not history dependent

**Initial state:**

- Registers: all at reset value (0)
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| all registers | `32'h00000000` | no other instr executed, everything stay at reset values |
| `dmem` all words | unchanged | no memory store ops executed |

**Pass criteria:**
CPU halts by ebreak within timeout. cpu is halted for the rest of the cycles

**Final result:** PASS (TEST PASSED from make xrun)

### 1.16 — `ADD_BASIC`

**Functionality:**
Basic register math with small, easy, positive values

**Initial state:**

- Registers: all at reset value (0)
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(5)),
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(3)),
  asm_instr(.op(OP_ADDI), .rd(3), .rs1(1), .imm(2)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x1` | `32'h00000005` | 0 + 5 |
| `x2` | `32'h00000003` | 0 + 3 |
| `x3` | `32'h00000007` | 5 + 2 = 7 |
| `dmem` all words | unchanged | no memory store ops executed |

**Pass criteria:**
CPU halts by ebreak within timeout. registers equal expected values

**Final result:** PASS (TEST PASSED from make xrun)

### 1.17 — `SUB_BASIC`

**Functionality:**
Basic register subtraction with small, easy, positive values

**Initial state:**

- Registers: all at reset value (0)
- Data memory: none
- Other setup: standard reset, default program timeout

**Program:**

```systemverilog
prog = '{
  asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(10)),
  asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(3)),
  asm_instr(.op(OP_SUB), .rd(3), .rs1(1), .rs2(2)),
  EBREAK_WORD
};
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x1` | `32'h0000000A` | 0 + 10 |
| `x2` | `32'h00000003` | 0 + 3 |
| `x3` | `32'h00000007` | 10 - 3 = 7 |
| `dmem` all words | unchanged | no memory store ops executed |

**Pass criteria:**
CPU halts by ebreak within timeout. registers equal expected values

**Final result:** PASS (TEST PASSED from make xrun)

### 1.18 — `RESET_MID`

**Functionality:**
Reset while cpu is running a program, checks if the cpu will restart from reset state

**Initial state:**

- Registers: all at reset value (0)
- Data memory: init_memories()
- Other setup: cpu starts, runs 3 cycles, reset

**Program:**

```systemverilog
prog = '{
    asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(5)),
    asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(5)),
    asm_instr(.op(OP_ADDI), .rd(3), .rs1(0), .imm(5)),
    EBREAK_WORD
};
drv.reset_task();
seqr.load_program(prog);
seqr.wait_for_empty();
repeat (2) @(cpu_if.cb);
drv.start_cpu();
repeat (3) @(cpu_if.cb);
drv.reset_task();
init_memories();
run_directed("RESET_MID", prog);
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x1` | `32'h00000005` | 0 + 5 |
| `x2` | `32'h00000005` | 0 + 5 |
| `x3` | `32'h00000005` | 0 + 5 |
| `dmem` all words | unchanged | no memory store ops executed |

**Pass criteria:**
CPU halts by ebreak within timeout on the second run. registers equal expected values, all others stay 0

**Final result:** PASS (TEST PASSED from make xrun)

### 1.19 — `EXT_HALT`

**Functionality:**
halt_cpu stops the CPU in the middle of a prog. the cpu should deactivate and return memories

**Initial state:**

- Registers: all at reset value (0)
- Data memory: init_memories()
- Other setup: standard reset, program loaded, cpu runs 5 cycles, halt is assereted, cpu reset

**Program:**

```systemverilog
begin
    logic [31:0] halt_prog [$];
    for (int i = 0; i  < 10; i++) begin
        halt_prog.push_back(asm_instr(.op(OP_ADDI), .rd(1), .rs1(1), .imm(1)));
    end
    halt_prog.push_back(EBREAK_WORD);
    sb.set_test("EXT_HALT");
    drv.reset_task();
    seqr.load_program(halt_prog);
    seqr.wait_for_empty();
    repeat (2) @(cpu_if.cb);
    drv.start_cpu();
    repeat (5) @(cpu_if.cb);
    drv.halt_cpu_now();
    drv.reset_task();
end
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x1` | not checked | program stopped mid way, no readback |
| `dmem` all words | unchanged | no memory store ops executed |

**Pass criteria:**
CPU stops after halt_cpu_now(), cpu_active drops within 1 cycle of cpu_halted

**Final result:** PASS (TEST PASSED from make xrun)

### 1.20 — `PC_HIGH_ADDR`

**Functionality:**
A long straight-line program that drives the program counter through the upper part of instruction memory. This checks that PC increment and instruction fetch work at high addresses and that the CPU still reaches `ebreak` at the end. Added for code coverage of the high PC bits.

**Initial state:**

- Registers: all at reset value 0
- Data memory: initialized by `init_memories()`, none specific to this test
- Other setup: standard reset, timeout raised to 3000 cycles, 16 data words read back

**Program:**

```systemverilog
begin
  logic [31:0] long_prog [$];
  for (int i = 0; i < 250; i++) begin
    long_prog.push_back(asm_instr(.op(OP_ADDI), .rd(1), .rs1(1), .imm(1)));
  end
  long_prog.push_back(EBREAK_WORD);
  run_directed("PC_HIGH_ADDR", long_prog, 3000, 16);
end
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `x1` | `32'h000000FA` | 250 `addi x1, x1, 1` instructions, each adds 1 to x1 starting from 0 |
| all other registers | `32'h00000000` | never written |
| `dmem` words 0-15 | unchanged | no stores executed |

**Pass criteria:**
CPU halts by `ebreak` within the 3000-cycle timeout. x1 = 250, all other registers remain 0, no scoreboard mismatch.

**Final result:**

### 1.21 — `ISRAM_HIGH_ADDR`

**Functionality:**
An external-port write and read of the last instruction-memory word (word 1023). This checks that the top word of instruction memory is reachable through the external port and returns the written value. Added for code coverage of the high instruction-memory address bits. No CPU program runs in this test.

**Initial state:**

- Registers: all at reset value 0, CPU not started
- Data memory: initialized by `init_memories()`, none specific to this test
- Other setup: standard reset, instruction memory initialized to `EBREAK_WORD`

**Program:**

```systemverilog
drv.reset_task();
init_memories();
sb.set_test("COVERAGE_ISRAM_HIGH_ADDR");
seqr.send_write_trans(word_addr(ISRAM_BASE, 1023), 32'hFFFFFFFF);
seqr.send_read_trans(word_addr(ISRAM_BASE, 1023));
seqr.wait_for_empty();
repeat (4) @(cpu_if.cb);
```

**Expected result:**

| Register or memory word | Expected value | Calculation or explanation |
| --- | --- | --- |
| `imem[1023]` read | `32'hFFFFFFFF` | value written to the last instruction-memory word |
| all registers | `32'h00000000` | CPU never started |
| `dmem` all words | unchanged | no stores executed |

**Pass criteria:**
The external read returns 32'hFFFFFFFF, the scoreboard logs "Matches Actual" for `imem[0x3ff]`, and no mismatch, assertion, or monitor error is reported.

**Final result:**

## 2. Constrained-random tests

### Instruction constraints

| Constraint | Provided, partial, or open | Behavior and purpose | Final implementation summary |
| --- | --- | --- | --- |
| `c_opcode` | Provided | membership constraint restricting op to the 8 supported non-halt opcodes. Excludes OP_EBREAK and anything outside the cpu's 9-instruction set | No member change |
| `c_reg_bias` | Provided | weighted distribution biasing register selection toward x0 and x1-x7, leaving x8-x31 a smaller share. | No member change |
| `c_imm_range` | Partial | added the missing upper bound, imm <= 2047, to match the immediate range | imm inside {[-2048:2047]} added |
| `c_mem_align` | Open | Forces lw/sw offsets to be word-aligned (imm%4 == 0) | (op inside {OP_LW, OP_SW}) -> (imm%4 == 0) added |
| `c_imm_unused` | Provided | Forces imm to 0 for add/sub/sll/srl since those instructions don't use it | No member change |
| `c_branch_target` | Partial | Added an upper bound so beq can't jump past the end of the program, only forward branches allowed | (op == OP_BEQ) -> (imm%4 == 0) && (imm >= 4) && (imm <= (prog_len - idx) *4) |
| `c_no_branch_at_end` | Provided | Stops beq from being generated as the last instr, since it wouldnt have anything to do | No member change |
| `c_branch_taken_bias` | Open | Forces rs1 = rs2 about half the time so beq actually gets taken sometimes, not just random misses | (op == OP_BEQ) -> (rs1 == rs2) dist {1:/50, 0:/50} added |

### External-port constraints

| Constraint | Provided, partial, or open | Behavior and purpose | Final implementation summary |
| --- | --- | --- | --- |
| `c_align` | Provided | Forces external addresses to be word-aligned | No member change |
| `c_valid_window` | Partial | Added bounds so the address stays inside real memory withing each window, not just valid window selector | line 660 |
| `c_reg_read_only` | Provided | Forces writes to be blocked if the address is in the register-file window, since it's read only | No member change |
| `c_data_corners` | Open | Biases data toward 0, 32'hFFFFFFFF, 32'h80000000, and 32'h7FFFFFFF, same edge values from add/sub tests | data dist {32'h0:/10,32'hFFFFFFFF:/10, 32'h80000000:/10, 32'h7FFFFFFF:/10, [32'h1:32'hFFFFFFFE]:/60} added |
constraint c_valid_window {
  addr[13:12] inside {2'b00, 2'b01, 2'b10};
  (addr[13:12] == 2'b00) -> addr[11:2] <= 10'd1023;
  (addr[13:12] == 2'b01) -> addr[11:2] <= 10'd1023;
  (addr[13:12] == 2'b10) -> addr[6:2] <= 5'd31;
  (addr[13:12] == 2'b10) -> addr[11:7] <= 5'd0;

}
### Random-program test

| Item | Plan |
| --- | --- |
| Number of programs per seed | 10-20 |
| Program-length range | 3-15 lines, not counting ebreak |
| Information logged for reproduction | Numeric `SVSEED`, iteration, and complete generated program |

**Implementation outline:**

```systemverilog
for (int i = 0; i < NUM_RANDOM_PROGRAMS; i++) begin
int len;
drv.reset_task();
len = $urandom_range(15,3);
seqr.gen_program(len);
seqr.wait_for_empty();
repeat (2) @(cpu_if.cb);
drv.run_program(max_cycles);
if (drv.last_run_completed) begin
readback(2, REG_COUNT);
readback(1, dmem_words);
end
else begin
$display($stime, " TB: random program %0d timed out/n", i);
drv.reset_task();
end
end
```

## 3. Assertions

### Assertion summary

| Assertion ID/name | Behavior checked | When it is sampled/disabled | Activating test |
| --- | --- | --- | --- |
| 4.1 / `NO_XBAR_RESPONSE_WHILE_CPU_ACTIVE` | external port never responds while the cpu owns memories | every cycle, disable iff (rst) | any directed test where the cpu is running |
| 4.2 / `CPU_STOPS_AFTER_HALT` | CPU deactivates within a bounded window after cpu_halted pulses | every cycle, disable iff (rst), checks 0-1 cycles after the pulse | run_smoke_test/run_external_halt_smoke |

### 4.1 — `NO_XBAR_RESPONSE_WHILE_CPU_ACTIVE`

**Timing requirement in words:**
The external port is services only while the cpu is disabled, so on any cycle cpu_active is high, rready must not be asserted - instantaneous
```systemverilog
NO_XBAR_RESPONSE_WHILE_CPU_ACTIVE:
  assert property (@(posedge clk) disable iff (rst)
    cpu_if.cpu_active |-> !cpu_if.rready)
  else assertion_fail("external port rready asserted while CPU is active");
```

**Evidence that it detects a violation:**
[assert1_fail.log](logs/assert1_fail.log)


### 4.2 — `CPU_STOPS_AFTER_HALT`

**Timing requirement in words:**
cpu_halted is a one-cycle pulse when ebreak retires, and halt_cpu_i (the halt path) is supposed to return the memories to the external port. Once that pulse goes, cpu_active must drop within at most 1 cycle afterward - bounded window response
```systemverilog
CPU_STOPS_AFTER_HALT:
  assert property (@(posedge clk) disable iff (rst)
    cpu_if.cpu_halted |=> ##[0:1] !cpu_if.cpu_active)
  else assertion_fail("CPU remained active more than 1 cycle after cpu_halted pulsed");
```

**Evidence that it detects a violation:**
[assert2_fail.log](logs/assert2_fail.log)
