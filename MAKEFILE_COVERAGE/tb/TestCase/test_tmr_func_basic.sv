// ============================================================================
// [TMR_TESTCASE_02] - [Functionality Basic] Tests
//   - TC2.1: Up-count, OVF + clear
//   - TC2.2: Down-count, UDF + clear
// ============================================================================

task automatic upcount_check_clr_ovf(input [1:0] cks);
  int  max_poll;
  int  i;
  bit  reached_target;
  begin
    $display("\n[--- TC2.1: Up-Counting + OVF + Clear, CKS=%0d ---]", cks);

    reached_target = 0;
    max_poll       = 2000;

    u_APB_trans_bus.program_and_start(8'hFD, 1'b0, cks);

    // Poll TCNT tới khi = 0x02 hoặc timeout
    for (i = 0; i < max_poll; i++) begin
      u_APB_trans_bus.apb_read(`TCNT_ADDR, data_read);
      if (data_read == 8'h02) begin
        reached_target = 1;
        break;
      end
      @(posedge PCLK);
    end

    if (!reached_target) begin
      $display("TC2.1-0 FAIL: Timeout waiting TCNT=0x02 (last=0x%0h) after %0d polls",
               data_read, max_poll);
      err_cnt++;
      return;
    end

    $display("Start count = 8'hFD | Current count = 0x%0h", data_read);

    // 1. Check TMR_OVF
    if (TMR_OVF) $display("TC2.1-1 PASS: TMR_OVF flag is set exactly");
    else begin
      $display("TC2.1-1 FAIL: TMR_OVF flag is NOT set exactly.");
      err_cnt++;
    end

    // 2. Check TSR[OVF]
    u_APB_trans_bus.apb_read(`TSR_ADDR, data_read);
    if (data_read[`TMR_OVF_BIT]) $display("TC2.1-2 PASS: OVF flag set by HW");
    else begin
      $display("TC2.1-2 FAIL: OVF flag not set");
      err_cnt++;
    end

    // 3. Clear OVF
    u_APB_trans_bus.clear_tsr();
    u_APB_trans_bus.apb_read(`TSR_ADDR, data_read);
    if (!data_read[`TMR_OVF_BIT]) $display("TC2.1-3 PASS: OVF cleared by SW");
    else begin
      $display("TC2.1-3 FAIL: OVF not cleared");
      err_cnt++;
    end

    @(posedge PCLK);
    if (!u_ip_timer.TMR_OVF) $display("TC2.1-3 PASS: OVF flag is cleared exactly");
    else begin
      $display("TC2.1-3 FAIL: OVF flag is not cleared exactly");
      err_cnt++;
    end
  end
endtask


task automatic dwcount_check_clr_udf(input [1:0] cks);
  int  max_poll;
  int  i;
  bit  reached_target;
  begin
    $display("\n[--- TC2.2: Down-Counting + UDF + Clear, CKS=%0d ---]", cks);

    reached_target = 0;
    max_poll       = 2000;

    u_APB_trans_bus.program_and_start(8'h02, 1'b1, cks);

    // Poll TCNT tới khi = 0xFD hoặc timeout
    for (i = 0; i < max_poll; i++) begin
      u_APB_trans_bus.apb_read(`TCNT_ADDR, data_read);
      if (data_read == 8'hFD) begin
        reached_target = 1;
        break;
      end
      @(posedge PCLK);
    end

    if (!reached_target) begin
      $display("TC2.2-0 FAIL: Timeout waiting TCNT=0xFD (last=0x%0h) after %0d polls",
               data_read, max_poll);
      err_cnt++;
      return;
    end

    $display("Start count = 8'h02 | Current count = 0x%0h", data_read);

    // 1. Check TMR_UDF
    if (TMR_UDF) $display("TC2.2-1 PASS: TMR_UDF flag is set exactly");
    else begin
      $display("TC2.2-1 FAIL: TMR_UDF flag is NOT set exactly.");
      err_cnt++;
    end

    // 2. Check TSR[UDF]
    u_APB_trans_bus.apb_read(`TSR_ADDR, data_read);
    if (data_read[`TMR_UDF_BIT]) $display("TC2.2-2 PASS: UDF flag set by HW");
    else begin
      $display("TC2.2-2 FAIL: UDF flag not set");
      err_cnt++;
    end

    // 3. Clear UDF
    u_APB_trans_bus.clear_tsr();
    u_APB_trans_bus.apb_read(`TSR_ADDR, data_read);
    if (!data_read[`TMR_UDF_BIT]) $display("TC2.2-3 PASS: UDF cleared by SW");
    else begin
      $display("TC2.2-3 FAIL: UDF not cleared");
      err_cnt++;
    end

    @(posedge PCLK);
    if (!u_ip_timer.TMR_UDF) $display("TC2.2-3 PASS: UDF flag is cleared exactly");
    else begin
      $display("TC2.2-3 FAIL: UDF flag is not cleared exactly");
      err_cnt++;
    end
  end
endtask


// Runner cho TC2.1 + TC2.2 (CKS = 0..3)
task automatic run_func_basic;
  int cks;
  begin
    for (cks = 0; cks < 4; cks++) begin
      upcount_check_clr_ovf(cks[1:0]);
    end
    for (cks = 0; cks < 4; cks++) begin
      dwcount_check_clr_udf(cks[1:0]);
    end
  end
endtask
