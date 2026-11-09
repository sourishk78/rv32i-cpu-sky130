/*
 * Converts sequences from the sequencer into signals that drive the external
 * port of the DUT. This is the only class that drives the DUT. It uses the
 * clocking block to avoid races with the monitor.
 *
 * Check memory_controller to see how it arbitrates memory ownership between
 * the CPU and the external port, and acts as a crossbar (xbar) to route external
 * access to ISRAM, DSRAM, and registers.
 */
class cpu_driver #(int DataSize=32, int AddrSize=14);

    virtual interface cpu_if #(.DataSize(DataSize), .AddrSize(AddrSize)) cpuVif; //reference to a cpu_if

    mailbox #(cpu_xbar_item #(DataSize, AddrSize)) xbar_box; //sequencer puts cpuxbar transactions into this mailbox and the driver will pull one by one and act

    // Maximum cycles to wait for an external read to finish
    int xbar_timeout = 32;

    // Maximum cycles to wait for the CPU to halt
    int run_timeout = 20000;

    int timeouts;                // Counts timeout failures
    bit last_run_completed;      // High when the CPU reports a clean halt

    // Constructor //makes specific objects using the blueprints
    function new(virtual interface cpu_if #(DataSize, AddrSize) cpuVif,
                 mailbox #(cpu_xbar_item #(DataSize, AddrSize)) xbar_box);
      this.cpuVif   = cpuVif; //.this references this class' instance
      this.xbar_box = xbar_box;
      this.timeouts = 0;
      this.last_run_completed = 1'b0;
    endfunction: new

    // Put the DUT into a known reset state
    task reset_task();
        // TODO: Drive all requests inactive, hold reset for several clock
        // cycles, then release it and give the interface time to settle
        cpuVif.cb.reset <= 1; //<= because it comes from a clocking block (clocking cb)
        cpuVif.cb.en_cpu <= 0;
        cpuVif.cb.halt_cpu <= 0;
        cpuVif.cb.addr <= 0;
        cpuVif.cb.wdata <= 0;
        cpuVif.cb.w_en <= 0;
        cpuVif.cb.r_en <= 0;
        //$fatal(1, "implement cpu_driver.reset_task");
        repeat (5) @(cpuVif.cb); // no clk in this file, cpuVif itself is a clocking block with a defined posedge (defined in cpu_if)
        cpuVif.cb.reset <= 0;
        repeat (2) @(cpuVif.cb);
    endtask: reset_task

    // Send one write through the DUT's external memory port
    task xbar_write(input logic [AddrSize-1:0] addr, input logic [DataSize-1:0] data);
        if (addr[1:0] != 2'b00) begin
            $error($stime, " Drv: external write address 0x%0x is not word aligned\n", addr);
        end

        // TODO: Drive one external write through the clocking block for one request, 
        // then return the port to idle
        cpuVif.cb.addr <= addr;
        cpuVif.cb.wdata <= data;
        cpuVif.cb.w_en <= 1;
        cpuVif.cb.r_en <= 0;
        //$fatal(1, "implement cpu_driver.xbar_write");
        @(cpuVif.cb);
        cpuVif.cb.addr <= 0; //stops from repeating everey cycle
        cpuVif.cb.wdata <= 0;
        cpuVif.cb.w_en <= 0;
    endtask: xbar_write

    // Send one read through the external memory port and wait for its data
    task xbar_read(input logic [AddrSize-1:0] addr);
        bit timed_out;
        int count;

        if (addr[1:0] != 2'b00) begin
            $error($stime, " Drv: external read address 0x%0x is not word aligned\n", addr);
        end

        // TODO: Keep the request stable until rready, capture the returned
        // data, and set a timeout for the response
        cpuVif.cb.addr <= addr;
        cpuVif.cb.r_en <= 1;
        cpuVif.cb.w_en <= 0;
        timed_out = 1'b0;
        count     = 0;
        while (!cpuVif.cb.rready) begin
            @(cpuVif.cb);
            count ++;
            if (count > xbar_timeout) begin
                timed_out = 1'b1;
                break;
            end
        end
        if (timed_out) begin
            $error($stime, "Drv: external read at 0x%0x timed out waiting for rready\n", addr);
            timeouts++;
        end
        cpuVif.cb.r_en <= 1'b0;
        cpuVif.cb.addr <= '0;
        //$fatal(1, "implement cpu_driver.xbar_read");
    endtask: xbar_read

    // Drive a start request for one CPU run
    task start_cpu();
        // TODO: Pulse en_cpu
        cpuVif.cb.en_cpu <= 1;
        @(cpuVif.cb);
        cpuVif.cb.en_cpu <= 0;
        //$fatal(1, "implement cpu_driver.start_cpu");
    endtask: start_cpu

    // Wait for the CPU to halt, or fail after the allowed number of cycles
    task wait_for_halt(output int cycles, input int max_cycles=0);
        int limit;
        bit halted;
        // TODO: Check cpu_halted on each cycle and report how many cycles
        // ran. Set last_run_completed only after a real halt. On a timeout, increment
        // timeouts and leave the flag low so the testbench can recover.

        limit  = (max_cycles == 0) ? run_timeout : max_cycles;
        cycles = 0;
        halted = 1'b0;
        last_run_completed = 1'b0;

        while (cycles < limit) begin
            @(cpuVif.cb);
            cycles ++;
            if (cpuVif.cb.cpu_halted) begin
                halted = 1'b1;
                break;
            end
        end
        if (halted) begin
            last_run_completed = 1'b1;
        end
        else begin
            $error($stime, " Drv: CPU did not halt within %0d cycles\n", limit);
            timeouts++;
            last_run_completed = 1'b0;
        end
        //$fatal(1, "implement cpu_driver.wait_for_halt");
    endtask: wait_for_halt

    // Start CPU and wait for it to halt
    task run_program(input int max_cycles=0);
        int cycles;

        last_run_completed = 1'b0;
        start_cpu();
        wait_for_halt(cycles, max_cycles);
    endtask: run_program

    // Stop a program through an external halt and wait for memory ownership
    // to return to the external port
    task halt_cpu_now();
        // TODO: Assert an external halt request and wait, with a bound,
        // until ownership returns to the external port
        int count;
        bit timed_out;

        cpuVif.cb.halt_cpu <= 1'b1;
        @(cpuVif.cb);
        cpuVif.cb.halt_cpu <= 1'b0;
        count = 0;
        timed_out = 1'b0;
        while (cpuVif.cb.cpu_active) begin
            count++;
            if (count > xbar_timeout) begin
                timed_out = 1'b1;
                break;
            end
            @(cpuVif.cb);
        end
        if (timed_out) begin
            $error($stime, " Drv: external halt did not return memory ownership within %0d cycles\n", xbar_timeout);
            timeouts++;
        end
        //$fatal(1, "TODO: implement cpu_driver.halt_cpu_now");
    endtask: halt_cpu_now

    // Main driver loop. Keeps taking transactions from the mailbox and
    // driving them through the DUT
    task run();
        cpu_xbar_item #(DataSize, AddrSize) trans;

        forever begin
            xbar_box.get(trans);
            if (trans.is_write) begin
                xbar_write(trans.addr, trans.data);
            end else begin
                xbar_read(trans.addr);
            end
        end
    endtask: run

endclass: cpu_driver