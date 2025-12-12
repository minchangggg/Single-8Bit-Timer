// ============================================================================
// [TMR_TEST_02] - Fork-Join Tests
//   - TC2.3: upcount_forkjoin 
//   - TC2.4: dwcount_forkjoin
// ============================================================================

task automatic upcount_forkjoin(input [1:0] cks);
  begin
    $display("\n[TC2.3] upcount_forkjoin, CKS=%0d", cks);

    fork
      begin : th1
        // Re-use TC2.1 core
        upcount_check_clr_ovf(cks);
      end

      begin : th2
        repeat (200) @(posedge PCLK);
        $display("  [TC2.3] Thread2 INFO: running in parallel, CKS=%0d", cks);
      end
    join

    $display("TC2.3 (CKS=%0d) DONE (dựa trên TC2.1)", cks);
  end
endtask


task automatic dwcount_forkjoin(input [1:0] cks);
  begin
    $display("\n[TC2.4] dwcount_forkjoin, CKS=%0d", cks);

    fork
      begin : th1
        // Re-use TC2.2 core
        dwcount_check_clr_udf(cks);
      end

      begin : th2
        repeat (200) @(posedge PCLK);
        $display("  [TC2.4] Thread2 INFO: running in parallel, CKS=%0d", cks);
      end
    join

    $display("TC2.4 (CKS=%0d) DONE (dựa trên TC2.2)", cks);
  end
endtask


// Runner cho TC2.3 + TC2.4 (tương ứng testplan:
//   countup_forkjoin_pclk2/4/8/16 & countdw_forkjoin_pclk2/4/8/16)
task automatic run_func_forkjoin;
  int cks;
  begin
    for (cks = 0; cks < 4; cks++) begin
      upcount_forkjoin(cks[1:0]);
    end
    for (cks = 0; cks < 4; cks++) begin
      dwcount_forkjoin(cks[1:0]);
    end
  end
endtask
