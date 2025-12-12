// ============================================================================
// TC: countdw_reset_countup_pclk2
// - Đếm xuống với CKS = PCLK×2
// - Reset giữa chừng, check TDR/TCR/TSR về default
// - Sau reset: đếm lên lại và chờ OVF
// ============================================================================
task automatic tc_countdw_reset_countup_pclk2;
  int  local_err_cnt;
  logic [`DATA_WIDTH-1:0] start_val;
  logic [`DATA_WIDTH-1:0] tdr_val, tcr_val, tsr_val;
  logic [`DATA_WIDTH-1:0] tcnt_before_rst;

  begin
    local_err_cnt = 0;
    $display("\n[TC2.6] countdw_reset_countup_pclk2");

    // 1. Down-count phase
    start_val = $urandom_range(1, 254);
    u_APB_trans_bus.program_and_start(start_val, 1'b1, 2'b00); // down, CKS=pclk×2

    repeat (20) @(posedge u_ip_timer.u_pos_cnt_edge_detect.TMR_Edge);
    u_APB_trans_bus.apb_read(`TCNT_ADDR, tcnt_before_rst);
    $display("  Before reset: TCNT = 0x%0h", tcnt_before_rst);

    // 2. Assert reset
    force PRESETn = 1'b0;
    repeat (3) @(posedge PCLK);
    force PRESETn = 1'b1;
    repeat (3) @(posedge PCLK);
    release PRESETn;

    // 3. Check default regs
    u_APB_trans_bus.apb_read(`TDR_ADDR, tdr_val);
    u_APB_trans_bus.apb_read(`TCR_ADDR, tcr_val);
    u_APB_trans_bus.apb_read(`TSR_ADDR, tsr_val);

    if (tdr_val == `TDR_RST && tcr_val == `TCR_RST && tsr_val == `TSR_RST)
      $display("  Reset part PASS: TDR/TCR/TSR back to default");
    else begin
      $display("  Reset part FAIL: TDR=0x%0h TCR=0x%0h TSR=0x%0h",
               tdr_val, tcr_val, tsr_val);
      local_err_cnt++;
    end

    // 4. Up-count lại từ cùng giá trị
    u_APB_trans_bus.program_and_start(tcnt_before_rst, 1'b0, 2'b00); // up, CKS=pclk×2

    wait (TMR_OVF == 1'b1);
    u_APB_trans_bus.apb_read(`TSR_ADDR, tsr_val);
    if (tsr_val[`TMR_OVF_BIT])
      $display("  Up-count part PASS: OVF flag set (TSR=0x%0h)", tsr_val);
    else begin
      $display("  Up-count part FAIL: TSR=0x%0h (OVF bit chưa set)", tsr_val);
      local_err_cnt++;
    end

    if (local_err_cnt == 0)
      $display("TC2.6 countdw_reset_countup_pclk2: PASS");
    else
      $display("TC2.6 countdw_reset_countup_pclk2: FAIL (%0d errors)", local_err_cnt);

    err_cnt += local_err_cnt;
    repeat (4) @(posedge PCLK);
  end
endtask

// ============================================================================
// TC: countup_reset_countdw_pclk2
// - Đếm lên với CKS = PCLK×2
// - Giữa chừng reset, kiểm tra TDR/TCR/TSR về default
// - Sau reset: set chế độ đếm xuống và chờ UDF
// ============================================================================
task automatic tc_countup_reset_countdw_pclk2;
  int  local_err_cnt;
  logic [`DATA_WIDTH-1:0] start_val;
  logic [`DATA_WIDTH-1:0] tdr_val, tcr_val, tsr_val;
  logic [`DATA_WIDTH-1:0] tcnt_before_rst;

  begin
    local_err_cnt = 0;
    $display("\n[TC2.7] countup_reset_countdw_pclk2");

    // 1. Up-count phase
    start_val = $urandom_range(1, 254);
    u_APB_trans_bus.program_and_start(start_val, 1'b0, 2'b00); // up, CKS = pclk×2

    // Cho chạy một lúc rồi đọc TCNT
    repeat (20) @(posedge u_ip_timer.u_pos_cnt_edge_detect.TMR_Edge);
    u_APB_trans_bus.apb_read(`TCNT_ADDR, tcnt_before_rst);
    $display("  Before reset: TCNT = 0x%0h", tcnt_before_rst);

    // 2. Assert reset
    force PRESETn = 1'b0;
    repeat (3) @(posedge PCLK);
    force PRESETn = 1'b1;
    repeat (3) @(posedge PCLK);
    release PRESETn;

    // 3. Check default register values
    u_APB_trans_bus.apb_read(`TDR_ADDR, tdr_val);
    u_APB_trans_bus.apb_read(`TCR_ADDR, tcr_val);
    u_APB_trans_bus.apb_read(`TSR_ADDR, tsr_val);

    if (tdr_val == `TDR_RST && tcr_val == `TCR_RST && tsr_val == `TSR_RST)
      $display("  Reset part PASS: TDR/TCR/TSR back to default");
    else begin
      $display("  Reset part FAIL: TDR=0x%0h TCR=0x%0h TSR=0x%0h",
               tdr_val, tcr_val, tsr_val);
      local_err_cnt++;
    end

    // 4. Down-count từ cùng giá trị (hoặc random lại cũng ok)
    u_APB_trans_bus.program_and_start(tcnt_before_rst, 1'b1, 2'b00); // down, CKS=pclk×2

    // Chờ underflow
    wait (TMR_UDF == 1'b1);
    u_APB_trans_bus.apb_read(`TSR_ADDR, tsr_val);
    if (tsr_val[`TMR_UDF_BIT])
      $display("  Down-count part PASS: UDF flag set (TSR=0x%0h)", tsr_val);
    else begin
      $display("  Down-count part FAIL: TSR=0x%0h (UDF bit chưa set)", tsr_val);
      local_err_cnt++;
    end

    if (local_err_cnt == 0)
      $display("TC2.7 countup_reset_countdw_pclk2: PASS");
    else
      $display("TC2.7 countup_reset_countdw_pclk2: FAIL (%0d errors)", local_err_cnt);

    err_cnt += local_err_cnt;
    repeat (4) @(posedge PCLK);
  end
endtask

// -------------------------------------------------------------
// Helper task: chạy tất cả test rst
// -------------------------------------------------------------
task automatic run_rst();
    tc_countdw_reset_countup_pclk2();
    tc_countup_reset_countdw_pclk2();
endtask

