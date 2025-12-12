`ifndef IP_TIMER_V
`define IP_TIMER_V

`include "reg_def.sv"
`include "apb_if.sv"
`include "rw_reg_control.sv"
`include "pos_cnt_edge_detect.sv"
`include "logic_control.sv"
`include "cnt_unit.sv"
`include "ovf_udf_comp.sv"

// -----------------------------------------------------------------------------
// Module: ip_TIMER
// Description:
//   Top-level 8-bit timer IP with APB slave interface.
//   - APB register block (TDR, TCR, TSR, TCNT)
//   - Clock select + edge detect
//   - Counter unit (up/down, load, enable)
//   - Overflow / Underflow detection
// -----------------------------------------------------------------------------
module ip_TIMER #(
  parameter int ADDR_WIDTH = `ADDR_WIDTH
)(
  input  wire [3:0]  CLK_IN,   
  apb_if.SLAVE       apb,     
  output wire        TMR_OVF,
  output wire        TMR_UDF
);

  // ===========================================================================
  // Internal wires/regs
  // ===========================================================================

  // Register values (TDR, TCR, TSR, TCNT)
  wire [`DATA_WIDTH-1:0] TDR_reg;
  wire [`DATA_WIDTH-1:0] TCR_reg;
  wire [`DATA_WIDTH-1:0] TSR_reg;
  wire [`DATA_WIDTH-1:0] TCNT_reg;

  // Control signals
  wire [`DATA_WIDTH-1:0] count_start_value;
  wire                   count_load;
  wire                   count_enable;
  wire                   count_up_down;
  wire [1:0]             cks;

  // Clock edge from selected clock source
  wire                   TMR_Edge;

  // Internal OVF/UDF flags from comparator
  wire                   TMR_OVF_int;
  wire                   TMR_UDF_int;

  // ===========================================================================
  // 1. APB READ/WRITE REGISTER CONTROLLER
  //    - Handles APB handshake + read/write to TDR/TCR/TSR
  //    - TCNT is provided as input for readback
  //    - TMR_OVF/TMR_UDF are inputs to be reflected into TSR
  // ===========================================================================
  rw_reg_control #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rw_reg_control (
    .PCLK     (apb.PCLK),
    .PRESETn  (apb.PRESETn),
    .PSEL     (apb.PSEL),
    .PENABLE  (apb.PENABLE),
    .PWRITE   (apb.PWRITE),
    .PADDR    (apb.PADDR),
    .PWDATA   (apb.PWDATA),
    .PRDATA   (apb.PRDATA),
    .PREADY   (apb.PREADY),
    .PSLVERR  (apb.PSLVERR),

    .TMR_OVF  (TMR_OVF_int),
    .TMR_UDF  (TMR_UDF_int),

    .TCNT     (TCNT_reg),
    .TDR      (TDR_reg),
    .TCR      (TCR_reg),
    .TSR      (TSR_reg)
  );

  // ===========================================================================
  // 2. CLOCK SELECT + EDGE DETECTION
  //    - Chọn 1 trong 4 nguồn CLK_IN dựa vào cks[1:0]
  //    - Đồng bộ và tạo xung 1-cycle TMR_Edge
  // ===========================================================================
  pos_cnt_edge_detect u_pos_cnt_edge_detect (
    .pclk     (apb.PCLK),
    .preset_n (apb.PRESETn),
    .CLK_IN   (CLK_IN),
    .cks      (cks),
    .TMR_Edge (TMR_Edge)
  );

  // ===========================================================================
  // 3. LOGIC CONTROL
  //    - Giải mã TDR/TCR để tạo:
  //        + count_start_value (giá trị load)
  //        + count_load
  //        + count_enable
  //        + count_up_down
  //        + cks (chọn clock)
  // ===========================================================================
  logic_control u_logic_control (
    .TDR               (TDR_reg),
    .TCR               (TCR_reg),
    .count_start_value (count_start_value),
    .count_load        (count_load),
    .count_enable      (count_enable),
    .count_up_down     (count_up_down),
    .cks               (cks)
  );

  // ===========================================================================
  // 4. COUNTER UNIT
  //    - Đếm lên/xuống, hỗ trợ load, enable, wrap-around 8-bit
  //    - Dùng TMR_Edge làm clock (pulse)
  // ===========================================================================
  cnt_unit u_cnt_unit (
    .pclk              (apb.PCLK),
    .preset_n          (apb.PRESETn),
    .TMR_Edge          (TMR_Edge),
    .count_start_value (count_start_value),
    .count_load        (count_load),
    .count_enable      (count_enable),
    .count_up_down     (count_up_down),
    .TCNT              (TCNT_reg)
  );

  // ===========================================================================
  // 5. OVERFLOW / UNDERFLOW COMPARATOR
  //    - So sánh TCNT hiện tại với TCNT trước đó để detect wrap:
  //        + Up-count: FF -> 00 ⇒ OVF
  //        + Down-count: 00 -> FF ⇒ UDF
  //    - Dùng TSR để biết khi nào SW clear flag
  // ===========================================================================
  ovf_udf_comp u_ovf_udf_comp (
    .pclk          (apb.PCLK),
    .preset_n      (apb.PRESETn),
    .TCNT          (TCNT_reg),
    .count_enable  (count_enable),
    .count_up_down (count_up_down),
    .TSR           (TSR_reg),
    .TMR_OVF       (TMR_OVF_int),
    .TMR_UDF       (TMR_UDF_int)
  );

  // Map internal flags to the top-level outputs
  assign TMR_OVF = TMR_OVF_int;
  assign TMR_UDF = TMR_UDF_int;

endmodule

`endif // IP_TIMER_V
