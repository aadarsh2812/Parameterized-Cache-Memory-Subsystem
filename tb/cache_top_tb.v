`timescale 1ns / 1ps
`include "cache_config.vh"

//============================================================
// Module Name : tb_cache_top
// Project     : Parameterized Cache Memory Subsystem
// Description :
//   Top-level functional testbench for the cache.
//
//   Tests:
//     1. Reset
//     2. Read miss + refill
//     3. Read hits
//     4. Write miss + write allocate
//     5. Write hits
//     6. Clean eviction
//     7. Dirty eviction
//     8. Boundary/conflict cases
//     9. Randomized stress testing
//    10. CPU response data/opaque/length checking
//============================================================

module tb_cache_top;

    //---------------------------------------------------------
    // Clock and Reset
    //---------------------------------------------------------

    reg clk;
    reg reset;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    //---------------------------------------------------------
    // DUT Interface Signals
    //---------------------------------------------------------

    // CPU Request
    reg                            cpu_req_valid;
    wire                           cpu_req_ready;

    reg  [`CACHE_ADDR_WIDTH-1:0]   cachereq_addr;
    reg  [`CACHE_DATA_WIDTH-1:0]   cachereq_data;
    reg  [`CACHE_OPAQUE_WIDTH-1:0] cachereq_opaque;
    reg  [`CACHE_TYPE_WIDTH-1:0]   cachereq_type;
    reg  [`CACHE_LEN_WIDTH-1:0]    cachereq_len;

    // CPU Response
    wire                           cpu_resp_valid;
    reg                            cpu_resp_ready;

    wire [`CACHE_DATA_WIDTH-1:0]   cpu_resp_data;
    wire [`CACHE_OPAQUE_WIDTH-1:0] cpu_resp_opaque;
    wire [`CACHE_LEN_WIDTH-1:0]    cpu_resp_len;

    // Memory Request
    wire                           mem_req_valid;
    reg                            mem_req_ready;
    wire                           mem_req_write;

    wire [`CACHE_ADDR_WIDTH-1:0]   mem_req_addr;
    wire [`CACHE_LINE_BITS-1:0]    mem_req_wdata;

    // Memory Response
    reg                            mem_resp_valid;
    reg  [`CACHE_LINE_BITS-1:0]    mem_resp_rdata;


    //---------------------------------------------------------
    // Performance & Coverage Counters
    //---------------------------------------------------------

    integer total_transactions;
    integer passed_tests;
    integer failed_tests;

    integer cpu_reads;
    integer cpu_writes;

    integer mem_reads;
    integer mem_writes;

    integer dirty_evictions;
    integer sim_timeouts;
    integer cache_refills;


    //---------------------------------------------------------
    // Manual Coverage Trackers
    //---------------------------------------------------------

    integer cov_read_miss;
    integer cov_read_hit;

    integer cov_write_miss;
    integer cov_write_hit;

    integer cov_clean_evict;
    integer cov_dirty_evict;


    //---------------------------------------------------------
    // Reference Models
    //---------------------------------------------------------

    // Architectural reference memory:
    // 64 KB / 4 bytes = 16384 words
    reg [31:0] ref_mem [0:16383];

    // Behavioral backing memory:
    // 64 KB / cache-line size
    reg [`CACHE_LINE_BITS-1:0]
        main_mem [0:(65536/`CACHE_LINE_SIZE)-1];


    //---------------------------------------------------------
    // DUT Instantiation
    //---------------------------------------------------------

    cache_top dut (
        .clk             (clk),
        .reset           (reset),

        // CPU request
        .cpu_req_valid   (cpu_req_valid),
        .cpu_req_ready   (cpu_req_ready),
        .cachereq_addr   (cachereq_addr),
        .cachereq_data   (cachereq_data),
        .cachereq_opaque (cachereq_opaque),
        .cachereq_type   (cachereq_type),
        .cachereq_len    (cachereq_len),

        // CPU response
        .cpu_resp_valid  (cpu_resp_valid),
        .cpu_resp_ready  (cpu_resp_ready),
        .cpu_resp_data   (cpu_resp_data),
        .cpu_resp_opaque (cpu_resp_opaque),
        .cpu_resp_len    (cpu_resp_len),

        // Memory request
        .mem_req_valid   (mem_req_valid),
        .mem_req_ready   (mem_req_ready),
        .mem_req_write   (mem_req_write),
        .mem_req_addr    (mem_req_addr),
        .mem_req_wdata   (mem_req_wdata),

        // Memory response
        .mem_resp_valid  (mem_resp_valid),
        .mem_resp_rdata  (mem_resp_rdata)
    );


    //---------------------------------------------------------
    // Initialization of Memory Models
    //---------------------------------------------------------

    integer init_idx;
    integer j;

    initial begin

        // Initialize reference memory
        for (init_idx = 0;
             init_idx < 16384;
             init_idx = init_idx + 1) begin

            // Deterministic pattern
            ref_mem[init_idx] =
                {init_idx[15:0], ~init_idx[15:0]};

        end


        // Build line-addressable backing memory
        for (init_idx = 0;
             init_idx < (65536/`CACHE_LINE_SIZE);
             init_idx = init_idx + 1) begin

            for (j = 0;
                 j < (`CACHE_LINE_SIZE/4);
                 j = j + 1) begin

                main_mem[init_idx][j*32 +: 32] =
                    ref_mem[
                        init_idx * (`CACHE_LINE_SIZE/4) + j
                    ];

            end
        end

    end


    //---------------------------------------------------------
    // Behavioral Main Memory Engine
    //---------------------------------------------------------

    integer mem_timeout;

    reg [31:0] line_idx;

    always @(posedge clk) begin

        if (reset) begin

            mem_req_ready  <= 1'b0;
            mem_resp_valid <= 1'b0;
            mem_resp_rdata <= {`CACHE_LINE_BITS{1'b0}};

        end
        else begin

            // Default
            mem_req_ready  <= 1'b1;
            mem_resp_valid <= 1'b0;


            //-------------------------------------------------
            // Accept memory request
            //-------------------------------------------------

            if (mem_req_valid && mem_req_ready) begin

                mem_req_ready <= 1'b0;

                // Convert byte address to cache-line index
                line_idx =
                    (mem_req_addr >> `CACHE_OFFSET_BITS)
                    & ((65536/`CACHE_LINE_SIZE)-1);


                //-------------------------------------------------
                // WRITE-BACK / EVICTION
                //-------------------------------------------------

                if (mem_req_write) begin

                    mem_writes      = mem_writes + 1;
                    dirty_evictions = dirty_evictions + 1;
                    cov_dirty_evict = 1;


                    //-------------------------------------------------
                    // Check line alignment
                    //-------------------------------------------------

                    if (mem_req_addr[`CACHE_OFFSET_BITS-1:0] != 0) begin

                        $display(
                            "[FAIL] MEMORY: Unaligned write-back address %h",
                            mem_req_addr
                        );

                        failed_tests = failed_tests + 1;

                    end


                    //-------------------------------------------------
                    // Verify write-back data
                    //-------------------------------------------------

                    begin : verify_wb

                        integer w_idx;

                        reg [`CACHE_LINE_BITS-1:0]
                            expected_line;


                        for (w_idx = 0;
                             w_idx < (`CACHE_LINE_SIZE/4);
                             w_idx = w_idx + 1) begin

                            expected_line[w_idx*32 +: 32] =
                                ref_mem[
                                    line_idx * (`CACHE_LINE_SIZE/4)
                                    + w_idx
                                ];

                        end


                        if (mem_req_wdata !== expected_line) begin

                            $display(
                                "[FAIL] MEMORY: Dirty Write-Back Data Mismatch"
                            );

                            $display(
                                "       Address : %h",
                                mem_req_addr
                            );

                            $display(
                                "       Expected: %h",
                                expected_line
                            );

                            $display(
                                "       Actual  : %h",
                                mem_req_wdata
                            );

                            failed_tests = failed_tests + 1;

                        end
                        else begin

                            $display(
                                "[PASS] MEMORY: Dirty Write-Back Verified at Addr %h",
                                mem_req_addr
                            );

                        end

                    end


                    //-------------------------------------------------
                    // Update backing memory
                    //-------------------------------------------------

                    main_mem[line_idx] = mem_req_wdata;


                    //-------------------------------------------------
                    // Simulate memory latency
                    //-------------------------------------------------

                    repeat(2) @(posedge clk);

                    mem_resp_valid <= 1'b1;

                end


                //-------------------------------------------------
                // READ / REFILL
                //-------------------------------------------------

                else begin

                    mem_reads     = mem_reads + 1;
                    cache_refills = cache_refills + 1;


                    // Simulate memory latency
                    repeat(2) @(posedge clk);

                    mem_resp_rdata <= main_mem[line_idx];

                    mem_resp_valid <= 1'b1;

                end

            end

        end

    end


    //---------------------------------------------------------
    // Reset Task
    //---------------------------------------------------------

    task reset_dut;

        begin

            reset = 1'b1;

            cpu_req_valid  = 1'b0;
            cpu_resp_ready = 1'b0;

            cachereq_addr   = 0;
            cachereq_data   = 0;
            cachereq_opaque = 0;
            cachereq_type   = 0;
            cachereq_len    = 0;

            repeat(5) @(posedge clk);

            reset = 1'b0;

            repeat(2) @(posedge clk);

        end

    endtask


    //---------------------------------------------------------
    // CPU READ Task
    //---------------------------------------------------------

    task do_cpu_read;

        input [31:0] addr;
        input [7:0]  opaque;

        integer timeout;
        integer pre_mem_reads;

        reg [31:0] expected_data;
        reg [31:0] word_idx;

        reg read_ok;

        begin

            read_ok = 1'b1;

            //-------------------------------------------------
            // Reference value
            //-------------------------------------------------

            pre_mem_reads = mem_reads;

            word_idx =
                (addr >> 2) & 14'h3FFF;

            expected_data =
                ref_mem[word_idx];


            //-------------------------------------------------
            // Drive CPU request
            //-------------------------------------------------

            @(posedge clk);

            cpu_req_valid  = 1'b1;

            cachereq_type  = 2'b00;       // READ
            cachereq_addr  = addr;
            cachereq_data  = 32'b0;
            cachereq_opaque = opaque;
            cachereq_len   = 2'b10;       // 4 bytes / word


            //-------------------------------------------------
            // Wait for request ready
            //-------------------------------------------------

            timeout = 0;

            while (!cpu_req_ready && timeout < 100) begin

                @(posedge clk);

                timeout = timeout + 1;

            end


            if (timeout >= 100) begin

                $display(
                    "[TIMEOUT] CPU Read Request stalled at Addr: %h",
                    addr
                );

                sim_timeouts = sim_timeouts + 1;
                failed_tests = failed_tests + 1;

                read_ok = 1'b0;

            end


            //-------------------------------------------------
            // Complete request handshake
            //-------------------------------------------------

            @(posedge clk);

            cpu_req_valid = 1'b0;

            cpu_resp_ready = 1'b1;


            //-------------------------------------------------
            // Wait for response
            //-------------------------------------------------

            timeout = 0;

            while (!cpu_resp_valid && timeout < 100) begin

                @(posedge clk);

                timeout = timeout + 1;

            end


            if (timeout >= 100) begin

                $display(
                    "[TIMEOUT] CPU Read Response stalled at Addr: %h",
                    addr
                );

                sim_timeouts = sim_timeouts + 1;
                failed_tests = failed_tests + 1;

                read_ok = 1'b0;

            end


            //-------------------------------------------------
            // Check response DATA
            //-------------------------------------------------

            if (cpu_resp_data !== expected_data) begin

                $display(
                    "[FAIL] READ : Addr=%h Expected=%h Actual=%h",
                    addr,
                    expected_data,
                    cpu_resp_data
                );

                failed_tests = failed_tests + 1;

                read_ok = 1'b0;

            end
            else begin

                $display(
                    "[PASS] READ : Addr=%h Expected=%h Actual=%h",
                    addr,
                    expected_data,
                    cpu_resp_data
                );

            end


            //-------------------------------------------------
            // Check OPAQUE
            //-------------------------------------------------

            if (cpu_resp_opaque !== opaque) begin

                $display(
                    "[FAIL] READ : Opaque mismatch. Expected=%h Actual=%h",
                    opaque,
                    cpu_resp_opaque
                );

                failed_tests = failed_tests + 1;

                read_ok = 1'b0;

            end


            //-------------------------------------------------
            // Check LENGTH
            //-------------------------------------------------

            if (cpu_resp_len !== 2'b10) begin

                $display(
                    "[FAIL] READ : Length mismatch. Expected=2'b10 Actual=%b",
                    cpu_resp_len
                );

                failed_tests = failed_tests + 1;

                read_ok = 1'b0;

            end


            //-------------------------------------------------
            // Count successful transaction
            //-------------------------------------------------

            if (read_ok) begin

                passed_tests = passed_tests + 1;

            end


            //-------------------------------------------------
            // Hit / Miss coverage
            //-------------------------------------------------

            if (mem_reads > pre_mem_reads)
                cov_read_miss = 1;
            else
                cov_read_hit = 1;


            //-------------------------------------------------
            // Finish response handshake
            //-------------------------------------------------

            @(posedge clk);

            cpu_resp_ready = 1'b0;

            cpu_reads = cpu_reads + 1;

            total_transactions =
                total_transactions + 1;

        end

    endtask


    //---------------------------------------------------------
    // CPU WRITE Task
    //---------------------------------------------------------

    task do_cpu_write;

        input [31:0] addr;
        input [31:0] data;
        input [7:0]  opaque;

        integer timeout;
        integer pre_mem_reads;

        reg [31:0] word_idx;

        reg write_ok;

        begin

            write_ok = 1'b1;

            //-------------------------------------------------
            // Reference address
            //-------------------------------------------------

            pre_mem_reads = mem_reads;

            word_idx =
                (addr >> 2) & 14'h3FFF;


            //-------------------------------------------------
            // Drive CPU request
            //-------------------------------------------------

            @(posedge clk);

            cpu_req_valid  = 1'b1;

            cachereq_type  = 2'b01;       // WRITE
            cachereq_addr  = addr;
            cachereq_data  = data;
            cachereq_opaque = opaque;
            cachereq_len   = 2'b10;       // 4 bytes / word


            //-------------------------------------------------
            // Wait for request ready
            //-------------------------------------------------

            timeout = 0;

            while (!cpu_req_ready && timeout < 100) begin

                @(posedge clk);

                timeout = timeout + 1;

            end


            if (timeout >= 100) begin

                $display(
                    "[TIMEOUT] CPU Write Request stalled at Addr: %h",
                    addr
                );

                sim_timeouts = sim_timeouts + 1;
                failed_tests = failed_tests + 1;

                write_ok = 1'b0;

            end


            //-------------------------------------------------
            // Complete request handshake
            //-------------------------------------------------

            @(posedge clk);

            cpu_req_valid = 1'b0;

            cpu_resp_ready = 1'b1;


            //-------------------------------------------------
            // Wait for response
            //-------------------------------------------------

            timeout = 0;

            while (!cpu_resp_valid && timeout < 100) begin

                @(posedge clk);

                timeout = timeout + 1;

            end


            if (timeout >= 100) begin

                $display(
                    "[TIMEOUT] CPU Write Response stalled at Addr: %h",
                    addr
                );

                sim_timeouts = sim_timeouts + 1;
                failed_tests = failed_tests + 1;

                write_ok = 1'b0;

            end


            //-------------------------------------------------
            // Check OPAQUE
            //-------------------------------------------------

            if (cpu_resp_opaque !== opaque) begin

                $display(
                    "[FAIL] WRITE : Opaque mismatch. Expected=%h Actual=%h",
                    opaque,
                    cpu_resp_opaque
                );

                failed_tests = failed_tests + 1;

                write_ok = 1'b0;

            end


            //-------------------------------------------------
            // Check LENGTH
            //-------------------------------------------------

            if (cpu_resp_len !== 2'b10) begin

                $display(
                    "[FAIL] WRITE : Length mismatch. Expected=2'b10 Actual=%b",
                    cpu_resp_len
                );

                failed_tests = failed_tests + 1;

                write_ok = 1'b0;

            end


            //-------------------------------------------------
            // Update reference memory
            //
            // IMPORTANT:
            // The reference memory represents architectural
            // memory contents. For a write-back cache, the
            // physical backing memory may remain old until
            // dirty eviction. Therefore the reference model
            // is updated here so that future write-back data
            // can be checked against the expected value.
            //-------------------------------------------------

            if (timeout < 100) begin

                ref_mem[word_idx] = data;

                $display(
                    "[PASS] WRITE : Addr=%h Data=%h",
                    addr,
                    data
                );

            end


            //-------------------------------------------------
            // Count successful transaction
            //-------------------------------------------------

            if (write_ok) begin

                passed_tests = passed_tests + 1;

            end


            //-------------------------------------------------
            // Hit / Miss coverage
            //-------------------------------------------------

            if (mem_reads > pre_mem_reads)
                cov_write_miss = 1;
            else
                cov_write_hit = 1;


            //-------------------------------------------------
            // Finish response handshake
            //-------------------------------------------------

            @(posedge clk);

            cpu_resp_ready = 1'b0;

            cpu_writes = cpu_writes + 1;

            total_transactions =
                total_transactions + 1;

        end

    endtask


    //---------------------------------------------------------
    // Main Test Stimulus
    //---------------------------------------------------------

    integer i;

    integer rand_addr;
    integer rand_data;
    integer rand_op;

    integer pre_clean_mem_writes;


    initial begin

        //-----------------------------------------------------
        // Initialize counters
        //-----------------------------------------------------

        total_transactions = 0;
        passed_tests       = 0;
        failed_tests       = 0;

        cpu_reads          = 0;
        cpu_writes         = 0;

        mem_reads          = 0;
        mem_writes         = 0;

        dirty_evictions    = 0;
        sim_timeouts       = 0;
        cache_refills      = 0;

        cov_read_miss      = 0;
        cov_read_hit       = 0;

        cov_write_miss     = 0;
        cov_write_hit      = 0;

        cov_clean_evict    = 0;
        cov_dirty_evict    = 0;


        //-----------------------------------------------------
        // Waveform
        //-----------------------------------------------------

        $dumpfile("sim_cache.fsdb");
        $dumpvars(0, tb_cache_top);


        //-----------------------------------------------------
        // Start
        //-----------------------------------------------------

        $display("==================================================");
        $display("   STARTING CACHE MEMORY SUBSYSTEM TESTBENCH");
        $display("==================================================");

        $display("");
        $display("CACHE CONFIGURATION");
        $display("  CACHE_SIZE       = %0d bytes", `CACHE_SIZE);
        $display("  CACHE_LINE_SIZE  = %0d bytes", `CACHE_LINE_SIZE);
        $display("  CACHE_NUM_LINES  = %0d", `CACHE_NUM_LINES);
        $display("  CACHE_LINE_BITS  = %0d", `CACHE_LINE_BITS);
        $display("  CACHE_TAG_BITS   = %0d", `CACHE_TAG_BITS);
        $display("  CACHE_INDEX_BITS = %0d", `CACHE_INDEX_BITS);
        $display("  CACHE_OFFSET_BITS= %0d", `CACHE_OFFSET_BITS);
        $display("==================================================");


        //-----------------------------------------------------
        // 1. Reset
        //-----------------------------------------------------

        $display("\n--- RESET TEST ---");

        reset_dut();


        //-----------------------------------------------------
        // 2. First read after reset
        //    Compulsory miss + refill
        //-----------------------------------------------------

        $display("\n--- READ MISS + REFILL TEST ---");

        do_cpu_read(
            32'h0000_1000,
            8'h01
        );


        //-----------------------------------------------------
        // 3. Read hits
        //    Same 32-byte cache line
        //-----------------------------------------------------

        $display("\n--- READ HIT TEST ---");

        do_cpu_read(
            32'h0000_1004,
            8'h02
        );

        do_cpu_read(
            32'h0000_1008,
            8'h03
        );

        do_cpu_read(
            32'h0000_100C,
            8'h04
        );


        //-----------------------------------------------------
        // 4. CLEAN EVICTION TEST
        //
        // 0x1000 and 0x3000:
        //
        // Both map to the same cache index:
        //
        //   0x1000 >> 5 = 0x80
        //   0x3000 >> 5 = 0x180
        //
        // Same index, different tag.
        //
        // The 0x1000 line has NOT been written, therefore
        // it is clean.
        //-----------------------------------------------------

        $display("\n--- CLEAN EVICTION TEST ---");

        pre_clean_mem_writes = mem_writes;

        do_cpu_read(
            32'h0000_3000,
            8'h09
        );


        if (mem_writes == pre_clean_mem_writes) begin

            $display(
                "[PASS] CLEAN EVICTION: No write-back generated"
            );

            cov_clean_evict = 1;

        end
        else begin

            $display(
                "[FAIL] CLEAN EVICTION: Unexpected memory write-back"
            );

            failed_tests = failed_tests + 1;

        end


        //-----------------------------------------------------
        // 5. WRITE MISS / WRITE ALLOCATE
        //-----------------------------------------------------

        $display("\n--- WRITE MISS + WRITE ALLOCATE TEST ---");

        do_cpu_write(
            32'h0000_2000,
            32'hDEADBEEF,
            8'h05
        );


        //-----------------------------------------------------
        // 6. READ AFTER WRITE ALLOCATE
        //-----------------------------------------------------

        $display("\n--- READ AFTER WRITE-ALLOCATE TEST ---");

        do_cpu_read(
            32'h0000_2000,
            8'h06
        );


        //-----------------------------------------------------
        // 7. WRITE HITS
        //-----------------------------------------------------

        $display("\n--- WRITE HIT TEST ---");

        do_cpu_write(
            32'h0000_2004,
            32'hCAFEF00D,
            8'h07
        );

        do_cpu_write(
            32'h0000_2008,
            32'hBADD00D5,
            8'h08
        );


        //-----------------------------------------------------
        // 8. READ BACK MULTIPLE WORDS
        //-----------------------------------------------------

        $display("\n--- MULTIPLE WORD READ-BACK TEST ---");

        do_cpu_read(
            32'h0000_2000,
            8'h15
        );

        do_cpu_read(
            32'h0000_2004,
            8'h16
        );

        do_cpu_read(
            32'h0000_2008,
            8'h17
        );


        //-----------------------------------------------------
        // 9. EXPLICIT DIRTY EVICTION TEST
        //-----------------------------------------------------

        $display("\n--- EXPLICIT DIRTY EVICTION TEST ---");


        //-----------------------------------------------------
        // A: Read A
        // Address = 0x000A0050
        //-----------------------------------------------------

        do_cpu_read(
            32'h000A_0050,
            8'h10
        );


        //-----------------------------------------------------
        // B: Write A
        // Makes cache line dirty
        //-----------------------------------------------------

        do_cpu_write(
            32'h000A_0050,
            32'h11112222,
            8'h11
        );


        //-----------------------------------------------------
        // C: Read A
        // Verify new data
        //-----------------------------------------------------

        do_cpu_read(
            32'h000A_0050,
            8'h12
        );


        //-----------------------------------------------------
        // D: Read B
        //
        // Same index as A but different tag:
        //
        // A = 0x000A0050
        // B = 0x000B0050
        //
        // This should cause dirty eviction of A.
        //-----------------------------------------------------

        do_cpu_read(
            32'h000B_0050,
            8'h13
        );


        //-----------------------------------------------------
        // E: Read A again
        //
        // A should have been written back to memory and
        // subsequently refilled.
        //-----------------------------------------------------

        do_cpu_read(
            32'h000A_0050,
            8'h14
        );


        //-----------------------------------------------------
        // 10. Boundary Tests
        //-----------------------------------------------------

        $display("\n--- BOUNDARY TESTS ---");


        // Lowest address
        do_cpu_write(
            32'h0000_0000,
            32'h12345678,
            8'hA1
        );

        do_cpu_read(
            32'h0000_0000,
            8'hA2
        );


        // Highest word-aligned address in 64-KB memory
        do_cpu_write(
            32'h0000_FFFC,
            32'h87654321,
            8'hA3
        );

        do_cpu_read(
            32'h0000_FFFC,
            8'hA4
        );


        //-----------------------------------------------------
        // 11. Conflict / Thrashing Tests
        //-----------------------------------------------------

        $display("\n--- CONFLICT / THRASHING TESTS ---");


        do_cpu_write(
            32'h0001_0040,
            32'hAAAAAAAA,
            8'hB1
        );

        do_cpu_write(
            32'h0002_0040,
            32'hBBBBBBBB,
            8'hB2
        );

        do_cpu_write(
            32'h0003_0040,
            32'hCCCCCCCC,
            8'hB3
        );

        do_cpu_read(
            32'h0001_0040,
            8'hB4
        );

        do_cpu_read(
            32'h0002_0040,
            8'hB5
        );


        //-----------------------------------------------------
        // 12. Randomized Stress Test
        //
        // Full 64-KB address range.
        // Word aligned.
        //-----------------------------------------------------

        $display("\n--- RANDOMIZED STRESS TEST ---");

        for (i = 0; i < 1000; i = i + 1) begin

            // 64-KB range, word aligned
            rand_addr =
                ($random & 32'h0000_FFFC);

            rand_data =
                $random;

            rand_op =
                $random & 1;


            if (rand_op == 1) begin

                do_cpu_write(
                    rand_addr,
                    rand_data,
                    i[7:0]
                );

            end
            else begin

                do_cpu_read(
                    rand_addr,
                    i[7:0]
                );

            end

        end


        //-----------------------------------------------------
        // 13. Allow final transactions to settle
        //-----------------------------------------------------

        repeat(20) @(posedge clk);


        //-----------------------------------------------------
        // Final Summary
        //-----------------------------------------------------

        $display("");
        $display("==================================================");
        $display("CACHE TESTBENCH SUMMARY");
        $display("==================================================");

        $display(
            "Total Transactions      : %0d",
            total_transactions
        );

        $display(
            "Passed Tests            : %0d",
            passed_tests
        );

        $display(
            "Failed Tests            : %0d",
            failed_tests
        );

        $display(
            "CPU Reads               : %0d",
            cpu_reads
        );

        $display(
            "CPU Writes              : %0d",
            cpu_writes
        );

        $display(
            "Memory Reads            : %0d",
            mem_reads
        );

        $display(
            "Memory Writes           : %0d",
            mem_writes
        );

        $display(
            "Cache-Line Refills      : %0d",
            cache_refills
        );

        $display(
            "Write-Backs             : %0d",
            mem_writes
        );

        $display(
            "Dirty Evictions         : %0d",
            dirty_evictions
        );

        $display(
            "Timeouts                : %0d",
            sim_timeouts
        );

        $display("==================================================");


        //-----------------------------------------------------
        // Coverage
        //-----------------------------------------------------

        $display(
            "Read Path               : %s",
            (cov_read_hit || cov_read_miss)
            ? "COVERED"
            : "NOT COVERED"
        );

        $display(
            "Write Path              : %s",
            (cov_write_hit || cov_write_miss)
            ? "COVERED"
            : "NOT COVERED"
        );

        $display(
            "Read Miss + Refill      : %s",
            cov_read_miss
            ? "COVERED"
            : "NOT COVERED"
        );

        $display(
            "Read Hit                : %s",
            cov_read_hit
            ? "COVERED"
            : "NOT COVERED"
        );

        $display(
            "Write Hit               : %s",
            cov_write_hit
            ? "COVERED"
            : "NOT COVERED"
        );

        $display(
            "Write Miss              : %s",
            cov_write_miss
            ? "COVERED"
            : "NOT COVERED"
        );

        $display(
            "Clean Eviction          : %s",
            cov_clean_evict
            ? "COVERED"
            : "NOT COVERED"
        );

        $display(
            "Dirty Eviction          : %s",
            cov_dirty_evict
            ? "COVERED"
            : "NOT COVERED"
        );

        $display(
            "Write-Back              : %s",
            cov_dirty_evict
            ? "COVERED"
            : "NOT COVERED"
        );

        $display("==================================================");


        //-----------------------------------------------------
        // Final Result
        //-----------------------------------------------------

        if ((failed_tests == 0) &&
            (sim_timeouts == 0)) begin

            $display(
                "[RESULT] ALL CACHE TESTS PASSED"
            );

        end
        else begin

            $display(
                "[RESULT] CACHE TEST FAILED"
            );

        end


        //-----------------------------------------------------
        // End simulation
        //-----------------------------------------------------

        $finish;

    end

endmodule