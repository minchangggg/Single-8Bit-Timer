// ======================================================================
// TC20: fake_underflow
// - Timer disable, mode count-down, pclk×2
// - Dùng LOAD nạp 0 -> 255 vào TCNT mà không cho chạy
// - Expect: UDF flag KHÔNG được set
// ======================================================================
task automatic tc_fake_underflow();
  int local_err_cnt = 0;
  reg [`DATA_WIDTH-1:0] tsr_val;

  $display("\n[--- TC2.10: fake_underflow ---]");

  // 1. Đảm bảo timer đang disable & mode down (EN=0, updown=1, cks=00)
  u_APB_trans_bus.configure_timer_disabled(/*updown=*/1'b1, /*cks=*/2'b00);

  // 2. Nạp 0 vào TCNT thông qua LOAD từ TDR
  u_APB_trans_bus.load_once(8'h00, /*updown=*/1'b1, /*cks=*/2'b00);

  // 3. Nạp 255 vào TCNT, vẫn timer disable
  u_APB_trans_bus.load_once(8'hFF, /*updown=*/1'b1, /*cks=*/2'b00);

  // 4. Đọc TSR xem UDF có bị set hay không
  u_APB_trans_bus.apb_read(`TSR_ADDR, tsr_val);
  if (tsr_val[`TMR_UDF_BIT]) begin
    $display("TC20 FAIL: UDF flag set in fake_underflow scenario (TSR=0x%0h)", tsr_val);
    local_err_cnt++;
  end else begin
    $display("TC2.10 PASS: UDF flag NOT set in fake_underflow (TSR=0x%0h)", tsr_val);
  end

  err_cnt += local_err_cnt;
endtask

// ======================================================================
// TC21: fake_overflow
// - Timer disable, mode count-up, pclk×2
// - Dùng LOAD nạp 255 -> 0, nhưng timer không chạy
// - Expect: OVF flag KHÔNG được set
// ======================================================================
task automatic tc_fake_overflow();
  int local_err_cnt = 0;
  reg [`DATA_WIDTH-1:0] tsr_val;

  $display("\n[--- TC2.11: fake_overflow ---]");

  // 1. Timer disable, mode up-count
  u_APB_trans_bus.configure_timer_disabled(/*updown=*/1'b0, /*cks=*/2'b00);

  // 2. Nạp 255 rồi 0 bằng LOAD
  u_APB_trans_bus.load_once(8'hFF, /*updown=*/1'b0, /*cks=*/2'b00);
  u_APB_trans_bus.load_once(8'h00, /*updown=*/1'b0, /*cks=*/2'b00);

  // 3. Check TSR[OVF]
  u_APB_trans_bus.apb_read(`TSR_ADDR, tsr_val);
  if (tsr_val[`TMR_OVF_BIT]) begin
    $display("TC2.11 FAIL: OVF flag set in fake_overflow (TSR=0x%0h)", tsr_val);
    local_err_cnt++;
  end else begin
    $display("TC2.11 PASS: OVF flag NOT set in fake_overflow (TSR=0x%0h)", tsr_val);
  end

  err_cnt += local_err_cnt;
endtask

// -------------------------------------------------------------
// Helper task: chạy tất cả test
// -------------------------------------------------------------
task automatic run_fake_tests();
  tc_fake_underflow();
  tc_fake_overflow();
endtask