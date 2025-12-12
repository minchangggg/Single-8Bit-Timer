`ifndef __SYS_TMR_SIGNAL_V__
`define __SYS_TMR_SIGNAL_V__

// =============================================================================
// Module: sys_signal
// Description: Generates the main system clock and active-low reset signal.
// Parameters:
//   - sys_clk_period: The period of the generated clock in ns.
// Outputs:
//   - sys_clk: The system clock.
//   - sys_rst_n: The active-low reset signal.
// =============================================================================
module sys_signal #(
  parameter int sys_clk_period = 10   // ns
)(
  output logic sys_clk,
  output logic sys_rst_n
);

  // Clock generation
  initial begin
    sys_clk = 1'b0;
    forever #(sys_clk_period/2) sys_clk = ~sys_clk;
  end

  // Reset generation: hold reset low for a few cycles, then release it
  initial begin
    sys_rst_n = 1'b0;
    #(sys_clk_period * 5);
    sys_rst_n = 1'b1;
  end

endmodule


// =====================================================================================
// Module: cnt_clk_in_gen
// Description:
//   - Generates 4 divided clocks from sys_clk:
//     clk_div2, clk_div4, clk_div8, clk_div16.
//   - These serve as the 4 CLK_IN sources for IP_TIMER.
// =====================================================================================
module cnt_clk_in_gen (
  input  logic       sys_clk,
  output logic [3:0] clk_in
);

  logic clk_div2, clk_div4, clk_div8, clk_div16;

  // Initialize internal divided clocks
  initial begin
    clk_div2  = 1'b0;
    clk_div4  = 1'b0;
    clk_div8  = 1'b0;
    clk_div16 = 1'b0;
  end

  // Generate divided clocks (testbench -> use always, not always_ff)
  always @(posedge sys_clk)   clk_div2  <= ~clk_div2;
  always @(posedge clk_div2)  clk_div4  <= ~clk_div4;
  always @(posedge clk_div4)  clk_div8  <= ~clk_div8;
  always @(posedge clk_div8)  clk_div16 <= ~clk_div16;

  // Map divided clocks to the output bus
  assign clk_in = {clk_div16, clk_div8, clk_div4, clk_div2};

endmodule


// =============================================================================
// Module: cnt_sys_signal
// Description:
//   - Wrapper for the testbench: generates sys_clk, sys_rst_n,
//     and the 4 clk_in signals.
// =============================================================================
module cnt_sys_signal #(
  parameter int sys_clk_period = 10   // ns
)(
  output logic       sys_clk_w,
  output logic       sys_rst_n_w,
  output logic [3:0] clk_in_w
);

  logic sys_clk_int;
  logic sys_rst_n_int;

  // Main clock + reset
  sys_signal #(
    .sys_clk_period(sys_clk_period)
  ) u_sys_signal (
    .sys_clk   (sys_clk_int),
    .sys_rst_n (sys_rst_n_int)
  );

  // Divided clocks
  cnt_clk_in_gen u_cnt_clk_in_gen (
    .sys_clk (sys_clk_int),
    .clk_in  (clk_in_w)
  );

  // Drive testbench-visible signals
  assign sys_clk_w   = sys_clk_int;
  assign sys_rst_n_w = sys_rst_n_int;

endmodule

`endif // __SYS_TMR_SIGNAL_V__
