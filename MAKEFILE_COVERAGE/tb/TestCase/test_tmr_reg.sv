// ============================================================================
// [TMR_TESTCASE_1.1_to_1.5] - [Register] Tests
//   - TDR, TCR, TSR, TCNT
//   - Null address / Mixed address
// ============================================================================

// --------------------------------------------------------------------------
// TC1.1: TDR (Timer Data Register) Read/Write
// --------------------------------------------------------------------------
task automatic tc_tdr_rw;
  begin
    $display("\n[--- TC1.1: TDR read/write ---]");

    // 1. Check default value
    u_APB_trans_bus.apb_read(`TDR_ADDR, data_read);
    if (data_read == `TDR_RST)
      $display("TC1.1-1 PASS: Default TDR value = 0x%h", data_read);
    else begin
      $display("TC1.1-1 FAIL: Default TDR value incorrect, exp 0x%h got 0x%h",
               `TDR_RST, data_read);
      err_cnt++;
    end

    // 2. N lần write/read ngẫu nhiên
    repeat (`repeat_count) begin
      w_rand_data = $urandom_range(255, 0);
      u_APB_trans_bus.apb_write(`TDR_ADDR, w_rand_data);
      u_APB_trans_bus.apb_read(`TDR_ADDR, data_read);
      if (data_read == w_rand_data)
        $display("TC1.1-2 PASS: Wrote & read 0x%h correctly", w_rand_data);
      else begin
        $display("TC1.1-2 FAIL: TDR mismatch, exp 0x%h got 0x%h",
                 w_rand_data, data_read);
        err_cnt++;
      end
    end
  end
endtask

// --------------------------------------------------------------------------
// TC1.2: TCR Read/Write with mask (chỉ bit writable thay đổi được)
// --------------------------------------------------------------------------
task automatic tc_tcr_rw;
  begin
    $display("\n[--- TC1.2: TCR read/write mask ---]");

    // 1. Check default
    u_APB_trans_bus.apb_read(`TCR_ADDR, data_read);
    if (data_read == `TCR_RST)
      $display("TC1.2-1 PASS: Default TCR value = 0x%h", data_read);
    else begin
      $display("TC1.2-1 FAIL: Default TCR incorrect, exp 0x%h got 0x%h",
               `TCR_RST, data_read);
      err_cnt++;
    end

    // 2. Write/read với mask
    repeat (`repeat_count) begin
      w_rand_data = $urandom_range(255, 0);
      u_APB_trans_bus.apb_write(`TCR_ADDR, w_rand_data);
      u_APB_trans_bus.apb_read(`TCR_ADDR, data_read);

      if (data_read == (w_rand_data & `TCR_WRITE_MASK))
        $display("TC1.2-2 PASS: Wrote 0x%h, read masked 0x%h OK",
                 w_rand_data, data_read);
      else begin
        $display("TC1.2-2 FAIL: TCR mismatch, exp 0x%h got 0x%h",
                 (w_rand_data & `TCR_WRITE_MASK), data_read);
        err_cnt++;
      end
    end
  end
endtask

// --------------------------------------------------------------------------
// TC1.3: TSR Read/Write – chỉ HW được phép set/clear flag
// --------------------------------------------------------------------------
task automatic tc_tsr_rw;
  begin
    $display("\n[--- TC1.3: TSR read/write ---]");

    // 1. Default
    u_APB_trans_bus.apb_read(`TSR_ADDR, data_read);
    if (data_read == `TSR_RST)
      $display("TC1.3-1 PASS: Default TSR value = 0x%h", data_read);
    else begin
      $display("TC1.3-1 FAIL: Default TSR incorrect, exp 0x%h got 0x%h",
               `TSR_RST, data_read);
      err_cnt++;
    end

    // 2. Viết bừa → expect HW bỏ qua (read lại 0)
    repeat (`repeat_count) begin
      w_rand_data = $urandom_range(255, 0);
      u_APB_trans_bus.apb_write(`TSR_ADDR, w_rand_data);
      u_APB_trans_bus.apb_read(`TSR_ADDR, data_read);
      if (data_read == 8'h00)
        $display("TC1.3-2 PASS: TSR ignores SW write (readback = 0)");
      else begin
        $display("TC1.3-2 FAIL: TSR readback not 0 (got 0x%h)", data_read);
        err_cnt++;
      end
    end
  end
endtask

// --------------------------------------------------------------------------
// TC1.4: TCNT Read-Only
//   - Read OK, PSLVERR=0
//   - Write bị reject, PSLVERR=1, TCNT không đổi
// --------------------------------------------------------------------------
task automatic tc_tcnt_ro;
  begin
    $display("\n[--- TC1.4: TCNT read-only ---]");

    // 1. Read hiện tại
    u_APB_trans_bus.apb_read(`TCNT_ADDR, cnt_before_write);
    if (PSLVERR == 1'b0)
      $display("TC1.4-1 PASS: Read TCNT OK, PSLVERR=0");
    else begin
      $display("TC1.4-1 FAIL: Read TCNT PSLVERR=1");
      err_cnt++;
    end

    // 2. Thử write
    w_rand_data = $urandom_range(255, 0);
    $display("=> Try write 0x%h to TCNT ...", w_rand_data);
    u_APB_trans_bus.apb_write(`TCNT_ADDR, w_rand_data);
    if (PSLVERR)
      $display("TC1.4-2 PASS: Write TCNT failed as expected (PSLVERR=1)");
    else begin
      $display("TC1.4-2 FAIL: Write TCNT succeeded unexpectedly");
      err_cnt++;
    end

    // 3. TCNT không đổi
    u_APB_trans_bus.apb_read(`TCNT_ADDR, cnt_after_write);
    if (cnt_after_write == cnt_before_write)
      $display("TC1.4-3 PASS: TCNT unchanged (0x%0h)", cnt_after_write);
    else begin
      $display("TC1.4-3 FAIL: TCNT changed from 0x%0h to 0x%0h",
               cnt_before_write, cnt_after_write);
      err_cnt++;
    end
  end
endtask

// --------------------------------------------------------------------------
// TC1.5: Null Address – truy cập addr không tồn tại → PSLVERR=1
// --------------------------------------------------------------------------
task automatic tc_null_addr;
  begin
    $display("\n[--- TC1.5: Null Address ---]");

    repeat (`repeat_count) begin
      null_addr   = $urandom_range(255, 4);   // tránh 0..3 (TDR/TCR/TSR/TCNT)
      w_rand_data = $urandom_range(255, 0);

      u_APB_trans_bus.apb_write(null_addr, w_rand_data);
      u_APB_trans_bus.apb_read (null_addr, data_read);

      if (PSLVERR)
        $display("TC1.5 PASS: PSLVERR asserted for invalid addr 0x%0h", null_addr);
      else begin
        $display("TC1.5 FAIL: PSLVERR NOT asserted for invalid addr 0x%0h", null_addr);
        err_cnt++;
      end
    end
  end
endtask

// --------------------------------------------------------------------------
// TC1.6: Mixed Address – trộn valid/invalid, check PSLVERR tương ứng
// --------------------------------------------------------------------------
task automatic tc_mixed_addr;
  begin
    $display("\n[--- TC1.6: Mixed Address ---]");

    repeat (`repeat_count) begin
      mixed_addr  = $urandom_range(255, 0);
      w_rand_data = $urandom_range(255, 0);

      u_APB_trans_bus.apb_write(mixed_addr, w_rand_data);

      if ((mixed_addr == `TDR_ADDR) ||
          (mixed_addr == `TCR_ADDR) ||
          (mixed_addr == `TSR_ADDR) ||
          (mixed_addr == `TCNT_ADDR)) begin
        // Valid
        if (!PSLVERR)
          $display("TC1.6 PASS: Valid addr 0x%0h OK (PSLVERR=0)", mixed_addr);
        else begin
          $display("TC1.6 FAIL: Valid addr 0x%0h but PSLVERR=1", mixed_addr);
          err_cnt++;
        end
      end else begin
        // Invalid
        if (PSLVERR)
          $display("TC1.6 PASS: Invalid addr 0x%0h flagged (PSLVERR=1)", mixed_addr);
        else begin
          $display("TC1.6 FAIL: Invalid addr 0x%0h not flagged (PSLVERR=0)", mixed_addr);
          err_cnt++;
        end
      end
    end
  end
endtask

// -------------------------------------------------------------
// Helper task: chạy tất cả test REG
// -------------------------------------------------------------
task automatic run_reg_tests();
  tc_tdr_rw();
  tc_tcr_rw();
  tc_tsr_rw();
  tc_tcnt_ro();
  tc_null_addr();
  tc_mixed_addr();
endtask
