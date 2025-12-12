`timescale 1ns/1ps

`include "rtl/reg_def.sv"
`include "rtl/apb_if.sv"
`include "VIP/cnt_sys_signal.sv"
`include "VIP/APB_trans_bus.sv"
`include "rtl/IP_TIMER.sv"

`define repeat_count 20

module tb_ip_TIMER;
  localparam ADDR_WIDTH = 8;

  // -------------------------------------------------------------
  // Clock / Reset / CLK_IN
  // -------------------------------------------------------------
  logic       PCLK;
  logic       PRESETn;
  logic [3:0] CLK_IN;

  // DUT flags
  logic TMR_OVF;
  logic TMR_UDF;

  // var used in test
  integer                 err_cnt;
  logic [`DATA_WIDTH-1:0] w_rand_data;
  logic [`DATA_WIDTH-1:0] data_write;
  logic [`DATA_WIDTH-1:0] data_read;
  logic [`DATA_WIDTH-1:0] cnt_before_write;
  logic [`DATA_WIDTH-1:0] cnt_after_write;
  logic [ADDR_WIDTH-1:0]  null_addr;
  logic [ADDR_WIDTH-1:0]  mixed_addr;

  // -------------------------------------------------------------
  // 1. create sys_clk, sys_rst, CLK_IN
  // -------------------------------------------------------------
  cnt_sys_signal #(
    .sys_clk_period (10)
  ) u_cnt_sys_signal (
    .sys_clk_w   (PCLK),
    .sys_rst_n_w (PRESETn),
    .clk_in_w    (CLK_IN)
  );

  // -------------------------------------------------------------
  // 2. APB interface
  // -------------------------------------------------------------
  apb_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`DATA_WIDTH)
  ) apb (
    .PCLK   (PCLK),
    .PRESETn(PRESETn)
  );

  // Aliases for easier use in tests
  wire                   PREADY  = apb.PREADY;
  wire                   PSLVERR = apb.PSLVERR;
  wire [`DATA_WIDTH-1:0] PRDATA  = apb.PRDATA;

  // -------------------------------------------------------------
  // 3. DUT: modport SLAVE
  // -------------------------------------------------------------
  ip_TIMER #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_ip_timer (
    .CLK_IN  (CLK_IN),
    .apb     (apb),
    .TMR_OVF (TMR_OVF),
    .TMR_UDF (TMR_UDF)
  );

  // -------------------------------------------------------------
  // 4. APB BFM: modport MASTER
  // -------------------------------------------------------------
  APB_trans_bus #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_APB_trans_bus (
    .apb(apb)
  );

  // -------------------------------------------------------------
  // 5. Include all testcase 
  // -------------------------------------------------------------
  // Register tests
  `include "TestCase/test_tmr_reg.sv"

  // Functionality tests (up/down, fork-join, pause/resume)
  // `include "TestCase/tc_timer_func.sv"
  `include "TestCase/test_tmr_func_basic.sv"   
  `include "TestCase/test_tmr_func_forkjoin.sv"
  `include "TestCase/test_tmr_func_pause.sv"   
  // Reset sequence tests
  `include "TestCase/test_tmr_rst_plck2.sv"
  // Reset to Load sequence tests
  `include "TestCase/test_tmr_rst_t_load_pclk2.sv"
  // Fake underflow / overflow tests
  `include "TestCase/test_tmr_fake_udf_ovf.sv"

  // -------------------------------------------------------------
  // 6. Test controller – choose TEST=REG / FUNC / ALL
  // -------------------------------------------------------------
  string TESTNAME;

  initial begin
    err_cnt = 0;
    $display("===== START tb_ip_TIMER =====");

    // Đợi reset nhả
    @(negedge PRESETn);
    @(posedge PRESETn);
    repeat (5) @(posedge PCLK);

    // Lấy TEST từ command line (vd: +TEST=FUNC)
    if (!$value$plusargs("TEST=%s", TESTNAME))
      TESTNAME = "ALL";

    $display("[TB] Selected TEST = %s", TESTNAME);

    case (TESTNAME)
      "REG": begin
        run_reg_tests();
      end

      "FUNC_BASIC": begin
        run_func_basic();
      end

      "FUNC_FORKJOIN": begin
        run_func_forkjoin();
      end

      "FUNC_PAUSE": begin
        run_func_pause();
      end

      "FUNC_RESET": begin
        run_rst();
      end

      "FUNC_LOAD": begin
        run_rst_t_load_tests();
      end

      "FUNC_FAKE": begin
        tc_fake_underflow();
        tc_fake_overflow();
      end      

      "FUNC": begin
        // ----------- FUNC_BASIC ------------
        run_func_basic();

        // -------- FUNC_FORKJOIN ---------
        run_func_forkjoin();

        // ---------- FUNC_PAUSE -----------
        run_func_pause();

        // --------- Reset ----------
        run_rst();

        // --------- Reset+Load ----------
        run_rst_t_load_tests();

        // --------- Fake Underflow / Overflow ----------
        run_fake_tests();

      end

      "ALL": begin
        // REG
        run_reg_tests();

        // FUNC
        run_func_basic();
        run_func_forkjoin();
        run_func_pause();

        run_rst();
        run_rst_t_load_tests();

        run_fake_tests();
      end

      default: begin
        $error("[TB] Unknown TEST=%s", TESTNAME);
        err_cnt++;
      end
    endcase

    $display("===== END tb_ip_TIMER, err_cnt = %0d =====", err_cnt);
    #100;
    $finish;
  end

endmodule
