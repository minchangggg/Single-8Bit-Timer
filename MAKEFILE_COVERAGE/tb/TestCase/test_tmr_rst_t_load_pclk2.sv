// ============================================================================
// TC: countup_reset_load_countdw_pclk2
// - Đếm lên với giá trị random
// - Reset giữa chừng, check default
// - Sau reset: load 1 giá trị random mới và đếm xuống, chờ UDF
// ============================================================================
task automatic tc_countup_reset_load_countdw_pclk2;
  int  local_err_cnt;
  logic [`DATA_WIDTH-1:0] start_val;
  logic [`DATA_WIDTH-1:0] new_val;
  logic [`DATA_WIDTH-1:0] tdr_val, tcr_val, tsr_val;

  begin
    local_err_cnt = 0;
    $display("\n[TC2.8] countup_reset_load_countdw_pclk2");

    // 1. Up-count phase
    start_val = $urandom_range(1, 254);
    u_APB_trans_bus.program_and_start(start_val, 1'b0, 2'b00);

    repeat (20) @(posedge u_ip_timer.u_pos_cnt_edge_detect.TMR_Edge);

    // 2. Reset
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

    // 4. Load giá trị mới và đếm xuống
    new_val = $urandom_range(1, 254);
    u_APB_trans_bus.program_and_start(new_val, 1'b1, 2'b00); // down

    wait (TMR_UDF == 1'b1);
    u_APB_trans_bus.apb_read(`TSR_ADDR, tsr_val);
    if (tsr_val[`TMR_UDF_BIT])
      $display("  Load+Down part PASS: UDF flag set (TSR=0x%0h)", tsr_val);
    else begin
      $display("  Load+Down part FAIL: TSR=0x%0h (UDF bit chưa set)", tsr_val);
      local_err_cnt++;
    end

    if (local_err_cnt == 0)
      $display("TC2.8 countup_reset_load_countdw_pclk2: PASS");
    else
      $display("TC2.8 countup_reset_load_countdw_pclk2: FAIL (%0d errors)", local_err_cnt);

    err_cnt += local_err_cnt;
    repeat (4) @(posedge PCLK);
  end
endtask

// ============================================================================
// TC: countdw_reset_load_countdw_pclk2
// - Đếm xuống với giá trị random
// - Reset giữa chừng, check default
// - Sau reset: load random mới và tiếp tục đếm xuống, chờ UDF
// ============================================================================
task automatic tc_countdw_reset_load_countdw_pclk2;
  int  local_err_cnt;
  logic [`DATA_WIDTH-1:0] start_val;
  logic [`DATA_WIDTH-1:0] new_val;
  logic [`DATA_WIDTH-1:0] tdr_val, tcr_val, tsr_val;

  begin
    local_err_cnt = 0;
    $display("\n[TC2.9] countdw_reset_load_countdw_pclk2");

    // 1. Down-count phase
    start_val = $urandom_range(1, 254);
    u_APB_trans_bus.program_and_start(start_val, 1'b1, 2'b00);

    repeat (20) @(posedge u_ip_timer.u_pos_cnt_edge_detect.TMR_Edge);

    // 2. Reset
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

    // 4. Load random mới, vẫn đếm xuống
    new_val = $urandom_range(1, 254);
    u_APB_trans_bus.program_and_start(new_val, 1'b1, 2'b00);

    wait (TMR_UDF == 1'b1);
    u_APB_trans_bus.apb_read(`TSR_ADDR, tsr_val);
    if (tsr_val[`TMR_UDF_BIT])
      $display("  Load+Down part PASS: UDF flag set (TSR=0x%0h)", tsr_val);
    else begin
      $display("  Load+Down part FAIL: TSR=0x%0h (UDF bit chưa set)", tsr_val);
      local_err_cnt++;
    end

    if (local_err_cnt == 0)
      $display("TC2.9 countdw_reset_load_countdw_pclk2: PASS");
    else
      $display("TC2.9 countdw_reset_load_countdw_pclk2: FAIL (%0d errors)", local_err_cnt);

    err_cnt += local_err_cnt;
    repeat (4) @(posedge PCLK);
  end
endtask

// -------------------------------------------------------------
// Helper task: chạy tất cả test rst_t_load
// -------------------------------------------------------------
task automatic run_rst_t_load_tests();
    tc_countup_reset_load_countdw_pclk2();
    tc_countdw_reset_load_countdw_pclk2();
endtask
