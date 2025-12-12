// ============================================================================
// [TMR_TESTCASE_2.5] - Pause / Resume Tests
// ============================================================================

task automatic updwcount_timer_pause_resume (
  input       updown, // 0: up, 1: down
  input [1:0] cks
);
  reg [`DATA_WIDTH-1:0] start_val;
  reg [`DATA_WIDTH-1:0] tcnt_before_pause;
  reg [`DATA_WIDTH-1:0] tcnt_after_pause_1;
  reg [`DATA_WIDTH-1:0] tcnt_after_pause_2;
  reg [`DATA_WIDTH-1:0] tcnt_after_resume;
  int local_err_cnt;
  int diff;

  begin
    local_err_cnt = 0;

    if (updown == 1'b0)
      $display("\n[--- TC2.5: UP Pause/Resume, CKS=%0d ---]", cks);
    else
      $display("\n[--- TC2.5: DOWN Pause/Resume, CKS=%0d ---]", cks);

    // 1. Program and start
    start_val = $urandom_range(1, 254);
    u_APB_trans_bus.program_and_start(start_val, updown, cks);

    // Let the timer run for a few cycles
    repeat (10) @(posedge u_ip_timer.u_pos_cnt_edge_detect.TMR_Edge);
    u_APB_trans_bus.apb_read(`TCNT_ADDR, tcnt_before_pause);
    $display("  TCNT before pause = 0x%0h", tcnt_before_pause);

    // 2. Pause
    u_APB_trans_bus.pause_counter(updown, cks);
    @(posedge PCLK);

    // First sample right after pause
    u_APB_trans_bus.apb_read(`TCNT_ADDR, tcnt_after_pause_1);

    // Wait longer while the timer is paused
    repeat (20) @(posedge PCLK);
    u_APB_trans_bus.apb_read(`TCNT_ADDR, tcnt_after_pause_2);

    diff = (tcnt_after_pause_2 > tcnt_after_pause_1) ?
            (tcnt_after_pause_2 - tcnt_after_pause_1) :
            (tcnt_after_pause_1 - tcnt_after_pause_2);

    if (diff <= 1) begin
      $display("TC2.5-1 PASS: TCNT is almost stable while paused (0x%0h -> 0x%0h, diff=%0d)",
               tcnt_after_pause_1, tcnt_after_pause_2, diff);
    end else begin
      $display("TC2.5-1 FAIL: TCNT changes too much while paused (0x%0h -> 0x%0h, diff=%0d)",
               tcnt_after_pause_1, tcnt_after_pause_2, diff);
      local_err_cnt++;
    end

    // 3. Resume
    u_APB_trans_bus.resume_counter(updown, cks);
    repeat (10) @(posedge u_ip_timer.u_pos_cnt_edge_detect.TMR_Edge);
    u_APB_trans_bus.apb_read(`TCNT_ADDR, tcnt_after_resume);

    if (tcnt_after_resume != tcnt_after_pause_2) begin
      $display("TC2.5-2 PASS: TCNT changes after resume (0x%0h -> 0x%0h)",
               tcnt_after_pause_2, tcnt_after_resume);
    end else begin
      $display("TC2.5-2 FAIL: TCNT does not change after resume (still 0x%0h)",
               tcnt_after_resume);
      local_err_cnt++;
    end

    if (local_err_cnt == 0)
      $display("TC2.5: PASS");
    else
      $display("TC2.5: FAIL with %0d errors", local_err_cnt);

    err_cnt += local_err_cnt;
    repeat (4) @(posedge PCLK);
  end
endtask


// Runner: group all pause/resume tests (UP & DOWN, CKS=0..3)
task automatic run_func_pause;
  int cks;
  begin
    // UP
    for (cks = 0; cks < 4; cks++) begin
      updwcount_timer_pause_resume(1'b0, cks[1:0]);
    end
    // DOWN
    for (cks = 0; cks < 4; cks++) begin
      updwcount_timer_pause_resume(1'b1, cks[1:0]);
    end
  end
endtask
