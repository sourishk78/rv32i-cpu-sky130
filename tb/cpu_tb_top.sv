/*
 * Top-level testbench
 */
module cpu_tb_top;

    import cpu_tb_pkg::*;

    parameter int DataSize = DATA_W;
    parameter int AddrSize = XBAR_AW;

    string requested_seed = "default";

    int assertion_errors = 0;

    logic clk = 0;
    always #5 clk = ~clk;

    // IF instantiation
    cpu_if #(.DataSize(DataSize), .AddrSize(AddrSize)) cpu_if(.clk(clk));

    // DUT instantiation
    chip_top dut (
        .clk_i(clk),
        .rst_i(cpu_if.cpu.reset),
        .en_cpu_i(cpu_if.cpu.en_cpu),
        .halt_cpu_i(cpu_if.cpu.halt_cpu),
        .cpu_halted_o(cpu_if.cpu.cpu_halted),
        .addr_i(cpu_if.cpu.addr),
        .wdata_i(cpu_if.cpu.wdata),
        .w_en_i(cpu_if.cpu.w_en),
        .r_en_i(cpu_if.cpu.r_en),
        .rdata_o(cpu_if.cpu.rdata),
        .rready_o(cpu_if.cpu.rready)
    );

    // Observation signals from the DUT memory path
    assign cpu_if.cpu_active     = dut.cpu_enable_q;
    assign cpu_if.dsram_en       = dut.dsram_en;
    assign cpu_if.dsram_write_en = dut.dsram_write_en;
    assign cpu_if.dsram_addr     = dut.dsram_addr;
    assign cpu_if.dsram_wdata    = dut.dsram_wdata;
    assign cpu_if.dsram_rdata    = dut.dsram_rdata;

    cpu_tb_pkg::cpu_sequencer #(.DataSize(DataSize), .AddrSize(AddrSize)) seqr;
    cpu_tb_pkg::cpu_driver #(.DataSize(DataSize), .AddrSize(AddrSize))    drv;
    cpu_tb_pkg::cpu_monitor #(.DataSize(DataSize), .AddrSize(AddrSize))   mon;
    cpu_tb_pkg::cpu_sb #(.DataSize(DataSize), .AddrSize(AddrSize))        sb;

    // Record failed assertion
    function void assertion_fail(input string message);
        assertion_errors++;
        $error($stime, " ASSERT: %s\n", message);
    endfunction: assertion_fail

    // Initialize both memories through the DUT's external memory port
    task automatic init_memories();
        $display($stime, " TB: Initializing instruction and data memories\n");
        mon.log_transactions = 1'b0;
        sb.log_transactions = 1'b0;
        for (int i = 0; i < ISRAM_WORDS; i++) begin
            seqr.send_write_trans(word_addr(ISRAM_BASE, i), EBREAK_WORD);
        end
        for (int i = 0; i < DSRAM_WORDS; i++) begin
            seqr.send_write_trans(word_addr(DSRAM_BASE, i), $urandom());
        end
        seqr.wait_for_empty();
        repeat (2) @(cpu_if.cb);
        mon.log_transactions = 1'b1;
        sb.log_transactions = 1'b1;
        $display($stime, " TB: Memory initialization complete\n");
    endtask: init_memories

    // Queue external reads on a memory window
    task automatic readback(input int window, input int num_words, input int start_word=0);
        logic [AddrSize-1:0] base;

        case (window)
            0: base = ISRAM_BASE;
            1: base = DSRAM_BASE;
            2: base = REG_BASE;
            default: base = REG_BASE;
        endcase

        for (int i = 0; i < num_words; i++) begin
            seqr.send_read_trans(word_addr(base, start_word + i));
        end
        seqr.wait_for_empty();
        repeat (4) @(cpu_if.cb);
    endtask: readback

    task automatic preload_dmem(input logic [31:0] values [$], input int start_word=0);
        foreach (values[i]) begin
            seqr.send_write_trans(word_addr(DSRAM_BASE, start_word + i), values[i]);
        end
        seqr.wait_for_empty();
        repeat (2) @(cpu_if.cb);
    endtask: preload_dmem

    // Run a directed test
    task automatic run_directed(input string name, const ref logic [31:0] program_words [$],
            input int max_cycles=2000, input int dmem_words=16);
        $display("");
        $display("=================================================================");
        $display(" TEST: %s", name);
        $display("=================================================================");
        sb.set_test(name);

        drv.reset_task();
        seqr.load_program(program_words);
        seqr.wait_for_empty();
        repeat (2) @(cpu_if.cb);
        drv.run_program(max_cycles);

        if (drv.last_run_completed) begin
            readback(2, REG_COUNT);
            readback(1, dmem_words);
        end else begin
            $display($stime, " TB: Skipping %s readback after CPU timeout\n", name);
            drv.reset_task();
        end
    endtask: run_directed

    // Basic smoke test for loading, running, and observing a program that halts
    task automatic run_smoke_test();
        logic [31:0] smoke_prog [$];
        smoke_prog = '{ EBREAK_WORD };
        run_directed("smoke_ebreak", smoke_prog, 100, 1);
    endtask: run_smoke_test

    // Smoke test for stopping the CPU from outside the program
    // Readback is skipped because the CPU stops before the program completes
    task automatic run_external_halt_smoke();
        logic [31:0] long_prog [$];

        for (int i = 0; i < 32; i++) begin
            long_prog.push_back(asm_instr(.op(OP_ADDI), .rd(1), .rs1(1), .imm(1)));
        end
        long_prog.push_back(EBREAK_WORD);

        $display("");
        $display("=================================================================");
        $display(" TEST: smoke_external_halt");
        $display("=================================================================");
        sb.set_test("smoke_external_halt");

        drv.reset_task();
        seqr.load_program(long_prog);
        seqr.wait_for_empty();
        repeat (2) @(cpu_if.cb);
        drv.start_cpu();
        repeat (12) @(cpu_if.cb);
        drv.halt_cpu_now();
        drv.reset_task();
    endtask: run_external_halt_smoke

    

    // TEST PROGRAM
    logic [31:0] prog [$];
    logic [31:0] data [$];

    int NUM_RANDOM_PROGRAMS = 20;
    int NUM_RANDOM_XBAR = 300;

    initial begin
        int total_errors;

        mon = new(cpu_if);
        sb = new(mon.mon_box);
        seqr = new();
        drv = new(cpu_if, seqr.xbar_box);

        void'($value$plusargs("NUM_RANDOM_PROGRAMS=%d", NUM_RANDOM_PROGRAMS));
        void'($value$plusargs("NUM_RANDOM_XBAR=%d", NUM_RANDOM_XBAR));
        if ($test$plusargs("REF_TRACE")) begin
            sb.ref_model.trace = 1'b1;
        end

        fork
            mon.run();
            sb.run();
            drv.run();
        join_none

        drv.reset_task();
        init_memories();

        run_smoke_test();
        run_external_halt_smoke();


        // DIRECTED TESTS
        drv.reset_task();
        init_memories();

        // TODO: Add directed test cases from the test plan (initial)
        // Use the existing helpers
        
        // Example Test: addi with a positive immediate
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(5)),
            asm_instr(.op(OP_ADDI), .rd(2), .rs1(1), .imm(100)),
            EBREAK_WORD
        };
        run_directed("addi_positive", prog);

        //1.1 ADDI_MIN
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(-2048)),
            EBREAK_WORD
        };
        run_directed("ADDI_MIN", prog);

        //1.2 ADDI_ZERO
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(0)),
        EBREAK_WORD
        };
        run_directed("ADDI_ZERO", prog);

        //1.3 ADDI_MIN
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(2047)),
        EBREAK_WORD
        };
        run_directed("ADDI_MIN", prog);

        //1.4 SLL_ZERO
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1234)),
        asm_instr(.op(OP_SLL), .rd(3), .rs1(1), .rs2(0)),
        EBREAK_WORD
        };
        run_directed("SLL_ZERO", prog);   

        //1.5 SLL_MAX
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)),
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(31)),
        asm_instr(.op(OP_SLL), .rd(3), .rs1(1), .rs2(2)),
        EBREAK_WORD
        };
        run_directed("SLL_MAX", prog);

        //1.5b SLL_MAX_MASK
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)),
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)),
        asm_instr(.op(OP_SLL), .rd(3), .rs1(1), .rs2(2)),
        EBREAK_WORD
        };
        run_directed("SLL_MAX_MASK", prog);

        //1.6 SRL_ZERO 
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1234)),
        asm_instr(.op(OP_SRL), .rd(3), .rs1(1), .rs2(0)),
        EBREAK_WORD
        };
        run_directed("SRL_ZERO", prog);

        //1.7 SRL_MAX
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(31)), // dest. register 4 holds 31
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)), // dest. register 1 holds 1
        asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)), // dest. register 1 shifts src. register 1's value (x1) by src. register 4's value (x4)
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(31)),
        asm_instr(.op(OP_SRL), .rd(3), .rs1(1), .rs2(2)),
        EBREAK_WORD
        }; 
        run_directed("SRL_MAX", prog);

        //1.7b SRL_MAX_MASK
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(31)),
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)), 
        asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)), 
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)), // -1 is 32'hFFFFFFFF, bottom 5 bits still 31
        asm_instr(.op(OP_SRL), .rd(3), .rs1(1), .rs2(2)),
        EBREAK_WORD
        };
        run_directed("SRL_MAX_MASK", prog);

        //1.8 BEQ_SAME_REG
        prog = '{
        asm_instr(.op(OP_BEQ), .rs1(3), .rs2(3), .imm(8)), 
        asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(999)),
        EBREAK_WORD
        };
        run_directed("BEQ_SAME_REG", prog); 

        //1.9 ADD_POS_WRAP
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(-1)), 
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(1)),
        asm_instr(.op(OP_ADD), .rd(3), .rs1(1), .rs2(2)),
        EBREAK_WORD
        };
        run_directed("ADD_POS_WRAP", prog);

        //1.10 SUB_NEG_WRAP
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(31)), 
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1)),
        asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)),
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(1)),
        asm_instr(.op(OP_SUB), .rd(3), .rs1(1), .rs2(2)),
        EBREAK_WORD
        };
        run_directed("SUB_NEG_WRAP", prog);   

        //1.11 LW_SW_ADDR_ZERO
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)),
        asm_instr(.op(OP_SW), .rs1(0), .rs2(2), .imm(0)),
        asm_instr(.op(OP_LW), .rd(3), .rs1(0), .imm(0)),
        EBREAK_WORD
        };
        run_directed("LW_SW_ADDR_ZERO", prog);

        //1.12 LW_SW_ADDR_MAX
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(2)),
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1023)),
        asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)),
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)),
        asm_instr(.op(OP_SW), .rs1(1), .rs2(2), .imm(0)),
        asm_instr(.op(OP_LW), .rd(3), .rs1(1), .imm(0)),
        EBREAK_WORD
        };
        run_directed("LW_SW_ADDR_MAX", prog);

        //1.13 LW_SW_ADDR_WRAP
        begin
            logic [31:0] preload_vals [$];
            preload_vals = '{32'hDEADBEEF};
            preload_dmem(preload_vals, 0);
        end
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(4), .rs1(0), .imm(2)),
        asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(1020)),
        asm_instr(.op(OP_SLL), .rd(1), .rs1(1), .rs2(4)),
        asm_instr(.op(OP_LW), .rd(3), .rs1(1), .imm(16)),
        EBREAK_WORD
        };
        run_directed("LW_SW_ADDR_WRAP", prog);

        //1.14 SW_LW_DEPEND
        prog = '{
        asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(-1)),
        asm_instr(.op(OP_SW), .rd(0), .rs1(2), .imm(0)),
        asm_instr(.op(OP_LW), .rd(3), .rs1(0), .rs2(0)),
        EBREAK_WORD
        };
        run_directed("SW_LW_DEPEND", prog);

        //1.15 EBREAK_FIRST
        prog = '{
            EBREAK_WORD
        };
        run_directed("EBREAK_FIRST", prog);

        //1.16 ADD BASIC
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(5)),
            asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(3)),
            asm_instr(.op(OP_ADDI), .rd(3), .rs1(1), .imm(2)),
            EBREAK_WORD
        };
        run_directed("ADD_BASIC", prog);

        //1.17 SUB_BASIC
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(1), .rs1(0), .imm(10)),
            asm_instr(.op(OP_ADDI), .rd(2), .rs1(0), .imm(3)),
            asm_instr(.op(OP_SUB), .rd(3), .rs1(1), .rs2(2)),
            EBREAK_WORD
        };
        run_directed("SUB_BASIC", prog);

        //1.18 RESET_MID
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

        //1.19 EXT_HALT
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

        // PC_HIGH_ADDR (Had to add for code coverage)
        begin
            logic [31:0] long_prog [$];
            for (int i = 0; i < 250; i++) begin
                long_prog.push_back(asm_instr(.op(OP_ADDI), .rd(1), .rs1(1), .imm(1)));
            end
            long_prog.push_back(EBREAK_WORD);
            run_directed("PC_HIGH_ADDR", long_prog, 3000, 16);
        end

        // ISRAM_HIGH_ADDR (Had to add for code coverage)
        drv.reset_task();
        init_memories();
        sb.set_test("COVERAGE_ISRAM_HIGH_ADDR");
        seqr.send_write_trans(word_addr(ISRAM_BASE, 1023), 32'hFFFFFFFF);
        seqr.send_read_trans(word_addr(ISRAM_BASE, 1023));
        seqr.wait_for_empty();
        repeat(4) @(cpu_if.cb);
        
        //BUG HUNT
        prog = '{
            asm_instr(.op(OP_SW), .rs1(7),  .rs2(6),  .imm(44)),
            asm_instr(.op(OP_SW), .rs1(28), .rs2(21), .imm(2004)),
            EBREAK_WORD
        };
        run_directed("BUG1_MINIMAL_REPRO", prog, 2000, 512);
        // E1 baseline (also pass 2000, 512 on BUG1_MINIMAL_REPRO)
        // E2 first store alone
        prog = '{ asm_instr(.op(OP_SW), .rs1(7), .rs2(6), .imm(44)), EBREAK_WORD };
        run_directed("BUG1_E2_FIRST_ALONE", prog, 2000, 512);

        // E3 second store alone
        prog = '{ asm_instr(.op(OP_SW), .rs1(28), .rs2(21), .imm(2004)), EBREAK_WORD };
        run_directed("BUG1_E3_SECOND_ALONE", prog, 2000, 512);

        // E4 nop between stores
        prog = '{
            asm_instr(.op(OP_SW),   .rs1(7),  .rs2(6),  .imm(44)),
            asm_instr(.op(OP_ADDI), .rd(0),   .rs1(0),  .imm(0)),
            asm_instr(.op(OP_SW),   .rs1(28), .rs2(21), .imm(2004)),
            EBREAK_WORD };
        run_directed("BUG1_E4_NOP_BETWEEN", prog, 2000, 512);

        // E5 swapped order
        prog = '{
            asm_instr(.op(OP_SW), .rs1(28), .rs2(21), .imm(2004)),
            asm_instr(.op(OP_SW), .rs1(7),  .rs2(6),  .imm(44)),
            EBREAK_WORD };
        run_directed("BUG1_E5_SWAPPED", prog, 2000, 512);

        // E6 second offset 2004 -> 44
        prog = '{
            asm_instr(.op(OP_SW), .rs1(7),  .rs2(6),  .imm(44)),
            asm_instr(.op(OP_SW), .rs1(28), .rs2(21), .imm(44)),
            EBREAK_WORD };
        run_directed("BUG1_E6_SMALL_OFFSET", prog, 2000, 512);

        // E7 stores start at instruction 3 (two nops first)
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(0), .rs1(0), .imm(0)),
            asm_instr(.op(OP_ADDI), .rd(0), .rs1(0), .imm(0)),
            asm_instr(.op(OP_SW),   .rs1(7),  .rs2(6),  .imm(44)),
            asm_instr(.op(OP_SW),   .rs1(28), .rs2(21), .imm(2004)),
            EBREAK_WORD };
        run_directed("BUG1_E7_NOT_FIRST", prog, 2000, 512);

        // E8 add the beq from the random program
        prog = '{
            asm_instr(.op(OP_SW),  .rs1(7),  .rs2(6),  .imm(44)),
            asm_instr(.op(OP_SW),  .rs1(28), .rs2(21), .imm(2004)),
            asm_instr(.op(OP_BEQ), .rs1(7),  .rs2(2),  .imm(8)),
            EBREAK_WORD };
        run_directed("BUG1_E8_WITH_BEQ", prog, 2000, 512);

        


        // CONSTRAINED-RANDOM TESTS
        // TODO: Add constrained-randomized testing for cpu_seq_item and cpu_xbar_item
        // For every random CPU program:
        //   1. print an iteration label so the seed and failure are reproducible,
        //   2. reset the CPU and call init_memories() before gen_program(),
        //   3. wait for program writes, run with the supplied bounded helper,
        //   4. queue the register and relevant memory reads needed by the scoreboard.
        // Keep randomized external-port traffic in a phase where the CPU is stopped.
        // The README explains why memory must be reinitialized every iteration.
        for (int iter = 0; iter < NUM_RANDOM_PROGRAMS; iter++) begin
            int len;
            $display("");
            $display("=============================================================");
            $display("RANDOM PROGRAM ITERATION %0d (SVSEED=%0s)", iter, requested_seed);
            $display("=============================================================");
            sb.set_test($sformatf("random_program_%0d", iter));
            drv.reset_task();
            init_memories();
            len = $urandom_range(15, 3);
            seqr.gen_program(len);
            seqr.wait_for_empty();
            repeat (2) @(cpu_if.cb);
            drv.run_program();
            if (drv.last_run_completed) begin
                readback(2, REG_COUNT);
                readback(1, 16);
            end
            else begin
                $display($stime, "TB: random program %0d timed out\n", iter);
                drv.reset_task();
            end
        end
        drv.reset_task();
        init_memories();
        sb.set_test("random_xbar");
        for (int i = 0; i < NUM_RANDOM_XBAR; i++) begin
            seqr.gen_xbar(1);
            seqr.wait_for_empty();
            repeat (2) @(cpu_if.cb);
        end

        // BUG 2 experiments
        prog = '{
            asm_instr(.op(OP_SW), .rs1(4), .rs2(8), .imm(256)),
            asm_instr(.op(OP_LW), .rd(4),  .rs1(1), .imm(1568)),
            EBREAK_WORD };
        run_directed("B2_E1_SW_LW", prog, 2000, 512);

        prog = '{ asm_instr(.op(OP_LW), .rd(4), .rs1(1), .imm(1568)), EBREAK_WORD };
        run_directed("B2_E2_LW_ALONE", prog, 2000, 512);

        prog = '{
            asm_instr(.op(OP_SW),   .rs1(4), .rs2(8), .imm(256)),
            asm_instr(.op(OP_ADDI), .rd(0),  .rs1(0), .imm(0)),
            asm_instr(.op(OP_LW),   .rd(4),  .rs1(1), .imm(1568)),
            EBREAK_WORD };
        run_directed("B2_E3_NOP_BETWEEN", prog, 2000, 512);

        prog = '{
            asm_instr(.op(OP_SW), .rs1(4), .rs2(8), .imm(256)),
            asm_instr(.op(OP_LW), .rd(4),  .rs1(1), .imm(44)),
            EBREAK_WORD };
        run_directed("B2_E4_SMALL_LW_OFFSET", prog, 2000, 512);

        prog = '{
            asm_instr(.op(OP_ADDI), .rd(0), .rs1(0), .imm(0)),
            asm_instr(.op(OP_SW),   .rs1(4), .rs2(8), .imm(256)),
            asm_instr(.op(OP_LW),   .rd(4),  .rs1(1), .imm(1568)),
            EBREAK_WORD };
        run_directed("B2_E5_NOT_FIRST", prog, 2000, 512);

        prog = '{
            asm_instr(.op(OP_LW), .rd(4),  .rs1(1), .imm(1568)),
            asm_instr(.op(OP_SW), .rs1(4), .rs2(8), .imm(256)),
            EBREAK_WORD };
        run_directed("B2_E6_LW_SW", prog, 2000, 512);

        prog = '{
            asm_instr(.op(OP_SW), .rs1(4), .rs2(8), .imm(256)),
            asm_instr(.op(OP_LW), .rd(4),  .rs1(4), .imm(256)),
            EBREAK_WORD };
        run_directed("B2_E7_SAME_ADDR", prog, 2000, 512);

        // F1 lw, sw independent of x4
        prog = '{
            asm_instr(.op(OP_LW), .rd(4),  .rs1(1), .imm(1568)),
            asm_instr(.op(OP_SW), .rs1(5), .rs2(8), .imm(256)),
            EBREAK_WORD };
        run_directed("B2_F1_INDEP_SW", prog, 2000, 512);

        // F2 lw, nop, dependent sw
        prog = '{
            asm_instr(.op(OP_LW),   .rd(4),  .rs1(1), .imm(1568)),
            asm_instr(.op(OP_ADDI), .rd(0),  .rs1(0), .imm(0)),
            asm_instr(.op(OP_SW),   .rs1(4), .rs2(8), .imm(256)),
            EBREAK_WORD };
        run_directed("B2_F2_NOP_BETWEEN", prog, 2000, 512);

        // F3 lw, addi (not a store)
        prog = '{
            asm_instr(.op(OP_LW),   .rd(4), .rs1(1), .imm(1568)),
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(7)),
            EBREAK_WORD };
        run_directed("B2_F3_LW_ADDI", prog, 2000, 512);

        // F4 lw, lw
        prog = '{
            asm_instr(.op(OP_LW), .rd(4), .rs1(1), .imm(1568)),
            asm_instr(.op(OP_LW), .rd(2), .rs1(5), .imm(1272)),
            EBREAK_WORD };
        run_directed("B2_F4_LW_LW", prog, 2000, 512);

        // F5 sw, lw, sw (iteration 2 core)
        prog = '{
            asm_instr(.op(OP_SW), .rs1(4),  .rs2(8), .imm(256)),
            asm_instr(.op(OP_LW), .rd(4),   .rs1(1), .imm(1568)),
            asm_instr(.op(OP_SW), .rs1(17), .rs2(2), .imm(1060)),
            EBREAK_WORD };
        run_directed("B2_F5_SW_LW_SW", prog, 2000, 512);
        // F6 sw, lw, nop, sw
        prog = '{
            asm_instr(.op(OP_SW),   .rs1(4),  .rs2(8), .imm(256)),
            asm_instr(.op(OP_LW),   .rd(4),   .rs1(1), .imm(1568)),
            asm_instr(.op(OP_ADDI), .rd(0),   .rs1(0), .imm(0)),
            asm_instr(.op(OP_SW),   .rs1(17), .rs2(2), .imm(1060)),
            EBREAK_WORD };
        run_directed("B2_F6_NOP_AFTER_LW", prog, 2000, 512);

        // F7 sw, nop, lw, sw
        prog = '{
            asm_instr(.op(OP_SW),   .rs1(4),  .rs2(8), .imm(256)),
            asm_instr(.op(OP_ADDI), .rd(0),   .rs1(0), .imm(0)),
            asm_instr(.op(OP_LW),   .rd(4),   .rs1(1), .imm(1568)),
            asm_instr(.op(OP_SW),   .rs1(17), .rs2(2), .imm(1060)),
            EBREAK_WORD };
        run_directed("B2_F7_NOP_BEFORE_LW", prog, 2000, 512);

        // F8 lw, sw, sw
        prog = '{
            asm_instr(.op(OP_LW), .rd(4),   .rs1(1), .imm(1568)),
            asm_instr(.op(OP_SW), .rs1(5),  .rs2(8), .imm(256)),
            asm_instr(.op(OP_SW), .rs1(17), .rs2(2), .imm(1060)),
            EBREAK_WORD };
        run_directed("B2_F8_LW_SW_SW", prog, 2000, 512);

        // B2_I1: lw then sw
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(8), .rs1(0), .imm(291)),
            asm_instr(.op(OP_LW),   .rd(4), .rs1(1), .imm(1568)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(8), .imm(256)),
            EBREAK_WORD };
        run_directed("B2_I1_LW_SW_DATA", prog, 2000, 512);

        // B3_J1: base 616, offset 220
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(616)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(220)),
            EBREAK_WORD };
        run_directed("B3_J1_BASE616_OFF220", prog, 2000, 512);

        // B3_J2: base 616, offset 0
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(616)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(0)),
            EBREAK_WORD };
        run_directed("B3_J2_BASE616_OFF0", prog, 2000, 512);

        // B3_J3: base 100, offset 220
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(100)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(220)),
            EBREAK_WORD };
        run_directed("B3_J3_BASE100_OFF220", prog, 2000, 512);

        // B3_J4: x0 base, offset 836
        prog = '{
            asm_instr(.op(OP_SW), .rs1(0), .rs2(0), .imm(836)),
            EBREAK_WORD };
        run_directed("B3_J4_X0_BASE", prog, 2000, 512);

        // B3_K1: x0 base, offset 220
        prog = '{ asm_instr(.op(OP_SW), .rs1(0), .rs2(0), .imm(220)), EBREAK_WORD };
        run_directed("B3_K1_X0_OFF220", prog, 2000, 512);

        // B3_K2: base 100, offset 64
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(100)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(64)),
            EBREAK_WORD };
        run_directed("B3_K2_BASE100_OFF64", prog, 2000, 512);

        // B3_K3: base 100, offset 128
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(100)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(128)),
            EBREAK_WORD };
        run_directed("B3_K3_BASE100_OFF128", prog, 2000, 512);

        // B3_K4: base 100, offset 192
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(100)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(192)),
            EBREAK_WORD };
        run_directed("B3_K4_BASE100_OFF192", prog, 2000, 512);

        // B3_K5: base 100, offset 12
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(100)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(12)),
            EBREAK_WORD };
        run_directed("B3_K5_BASE100_OFF12", prog, 2000, 512);

        // B3_K6: lw, base 100, offset 220
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(100)),
            asm_instr(.op(OP_LW),   .rd(4), .rs1(5), .imm(220)),
            EBREAK_WORD };
        run_directed("B3_K6_LW_BASE100_OFF220", prog, 2000, 512);

        // B3_L1: base 128, offset 128
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(128)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(128)),
            EBREAK_WORD };
        run_directed("B3_L1_CARRY_128_128", prog, 2000, 512);

        // B3_L2: base 200, offset 100
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(200)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(100)),
            EBREAK_WORD };
        run_directed("B3_L2_CARRY_200_100", prog, 2000, 512);

        // B3_L3: base 200, offset 40
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(200)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(40)),
            EBREAK_WORD };
        run_directed("B3_L3_NOCARRY_200_40", prog, 2000, 512);

        // B3_L4: base 256, offset 256
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(256)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(256)),
            EBREAK_WORD };
        run_directed("B3_L4_BIT8_CARRY", prog, 2000, 512);

        // B3_L5: base 252, offset 4
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(252)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(4)),
            EBREAK_WORD };
        run_directed("B3_L5_CARRY_252_4", prog, 2000, 512);

        // B3_N1: base 256, offset 200
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(256)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(200)),
            EBREAK_WORD };
        run_directed("B3_N1_BIT8_NOCARRY", prog, 2000, 512);

        // B3_N2: base 456, offset 100
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(456)),
            asm_instr(.op(OP_SW),   .rs1(5), .rs2(0), .imm(100)),
            EBREAK_WORD };
        run_directed("B3_N2_CARRY_BIT8CLEAR", prog, 2000, 512);

        // B3_N3: lw, base 252, offset 4
        prog = '{
            asm_instr(.op(OP_ADDI), .rd(5), .rs1(0), .imm(252)),
            asm_instr(.op(OP_LW),   .rd(4), .rs1(5), .imm(4)),
            EBREAK_WORD };
        run_directed("B3_N3_LW_CARRY", prog, 2000, 512);



        // TEST FINISH
        repeat (20) @(cpu_if.cb);
        total_errors = sb.errors + drv.timeouts + mon.errors + assertion_errors;
        if (sb.checks == 0) begin
            $error("Testbench performed zero checks; no results were verified");
        end

        $display("=================================================================");
        $display("  Scoreboard mismatches : %0d", sb.errors);
        $display("  Driver timeouts       : %0d", drv.timeouts);
        $display("  Monitor protocol errs : %0d", mon.errors);
        $display("  Assertion failures    : %0d", assertion_errors);
        $display("=================================================================");
        $display();

        if (total_errors == 0) begin
            $display("=================================================================");
            $display(" TEST PASSED!");
            $display("=================================================================");
        end else begin
            $display("=================================================================");
            $display(" TEST FAILED: %0d error(s)", total_errors);
            $display("=================================================================");
        end
        $finish;
    end

    // Stop a broken DUT or testbench instead of letting the simulation run forever
    initial begin
        #10ms;
        $display(" TEST FAILED - global timeout");
        $fatal(1, "global timeout");
    end

    initial begin
        void'($value$plusargs("SEED_LABEL=%s", requested_seed));
        if ($test$plusargs("BUG_HUNT_WAVES")) begin
            $shm_open("bug_hunt_waves.shm");
        end else begin
            $shm_open("waves.shm");
        end
        $shm_probe("AC");
    end

    wire rst = cpu_if.reset;
    // TODO: Add the required protocol or control assertions from the testplan

    // Example assertion
    // It checks one interface rule and sends failures through the testbench counter
    NO_SIMULTANEOUS_READ_WRITE:
        assert property (@(posedge clk) disable iff (rst)
            !(cpu_if.w_en && cpu_if.r_en))
        else assertion_fail("w_en_i and r_en_i were asserted together");

    NO_XBAR_RESPONSE_WHILE_CPU_ACTIVE:
        assert property (@(posedge clk) disable iff (rst)
            cpu_if.cpu_active |-> !cpu_if.rready)
        else assertion_fail("external port rready asserted while CPU is active");   

    CPU_STOPS_AFTER_HALT:
        assert property (@(posedge clk) disable iff (rst)
            cpu_if.cpu_halted |=> ##[0:1] !cpu_if.cpu_active)
        else assertion_fail("CPU remained active more than 1 cycle after cpu_halted pulsed");         

endmodule: cpu_tb_top
