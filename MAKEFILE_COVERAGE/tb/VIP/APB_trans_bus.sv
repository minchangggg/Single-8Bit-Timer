`ifndef __APB_TRANS_BUS_V__
`define __APB_TRANS_BUS_V__

`include "rtl/reg_def.sv"
`include "rtl/apb_if.sv"

// APB master BFM use apb_if.MASTER
module APB_trans_bus #(
  parameter int ADDR_WIDTH = `ADDR_WIDTH,
  parameter int DATA_WIDTH = `DATA_WIDTH
)(
  apb_if.MASTER apb
);

  // ---------------------------------------------------
  // INIT: set for IDLE
  // ---------------------------------------------------
  initial begin
    apb.PSEL    = 1'b0;
    apb.PENABLE = 1'b0;
    apb.PWRITE  = 1'b0;
    apb.PADDR   = '0;
    apb.PWDATA  = '0;
  end

  // ---------------------------------------------------
  // Low-level APB write (no wait-state)
  // ---------------------------------------------------
  task automatic apb_write (
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] data
  );
    begin
      // IDLE -> SETUP
      @(posedge apb.PCLK);
      apb.PADDR   <= addr;
      apb.PWDATA  <= data;
      apb.PWRITE  <= 1'b1;
      apb.PSEL    <= 1'b1;
      apb.PENABLE <= 1'b0;

      // SETUP -> ACCESS
      @(posedge apb.PCLK);
      apb.PENABLE <= 1'b1;

      // ACCESS: wait PREADY (if design always has PREADY=1 => only 1 cycle)
      do @(posedge apb.PCLK); while (!apb.PREADY);

      // Kết thúc: về IDLE
      apb.PSEL    <= 1'b0;
      apb.PENABLE <= 1'b0;
      apb.PWRITE  <= 1'b0;
      apb.PADDR   <= '0;
      apb.PWDATA  <= '0;
    end
  endtask

  // ---------------------------------------------------
  // Low-level APB read
  // ---------------------------------------------------
  task automatic apb_read (
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data
  );
    begin
      // IDLE -> SETUP
      @(posedge apb.PCLK);
      apb.PADDR   <= addr;
      apb.PWRITE  <= 1'b0;
      apb.PSEL    <= 1'b1;
      apb.PENABLE <= 1'b0;

      // SETUP -> ACCESS
      @(posedge apb.PCLK);
      apb.PENABLE <= 1'b1;

      // ACCESS: wait PREADY, get PRDATA
      do @(posedge apb.PCLK); while (!apb.PREADY);
      data = apb.PRDATA;

      // Kết thúc: về IDLE
      apb.PSEL    <= 1'b0;
      apb.PENABLE <= 1'b0;
      apb.PADDR   <= '0;
    end
  endtask

  // ---------------------------------------------------
  // clear_tsr: clear flag OVF/UDF in TSR by writting 1
  // ---------------------------------------------------
  task automatic clear_tsr;
    begin
      apb_write(`TSR_ADDR, {DATA_WIDTH{1'b1}});
    end
  endtask

  // ---------------------------------------------------
  // config_TCR
  // ---------------------------------------------------
  function automatic [DATA_WIDTH-1:0] config_TCR (
    input logic       load,
    input logic       updown,
    input logic       en,
    input logic [1:0] cks
  );
    logic [DATA_WIDTH-1:0] TCR;
    begin
      TCR = '0;
      TCR[`TCR_LOAD_BIT]               = load;
      TCR[`TCR_UPDOWN_BIT]             = updown;
      TCR[`TCR_EN_BIT]                 = en;
      TCR[`TCR_CKS_MSB:`TCR_CKS_LSB]   = cks;
      config_TCR = TCR;
    end
  endfunction

  // ------------------------------------------------------------
  // Helper: cấu hình TCR sao cho timer DISABLE (EN = 0)
  //         + clear TSR, dùng cho fake_overflow / fake_underflow
  // ------------------------------------------------------------
  task configure_timer_disabled (
    input bit       updown, // 0: up, 1: down
    input [1:0]     cks
  );
    reg [`DATA_WIDTH-1:0] tcr_cfg;
    begin
      // clear status register cho sạch flag
      clear_tsr();

      // LOAD = 0, EN = 0, giữ đúng mode up/down & CKS
      tcr_cfg = config_TCR(
                  /*load   =*/ 1'b0,
                  /*updown =*/ updown,
                  /*en     =*/ 1'b0,
                  /*cks    =*/ cks
                );

      apb_write(`TCR_ADDR, tcr_cfg);
    end
  endtask

  // ------------------------------------------------------------
  // Helper: load_once
  //   - Ghi start_val vào TDR
  //   - Kéo LOAD=1 1 lần trong khi EN=0 để nạp TDR -> TCNT
  //   - Sau đó hạ LOAD về 0, timer vẫn disable (không đếm)
  //   => Dùng trong fake_overflow / fake_underflow
  // ------------------------------------------------------------
  task load_once (
    input [`DATA_WIDTH-1:0] start_val,
    input bit               updown,
    input [1:0]             cks
  );
    reg [`DATA_WIDTH-1:0] tcr_cfg;
    begin
      // Ghi giá trị vào TDR
      apb_write(`TDR_ADDR, start_val);

      // 1. LOAD=1, EN=0 để nạp vào TCNT
      tcr_cfg = config_TCR(
                  /*load   =*/ 1'b1,
                  /*updown =*/ updown,
                  /*en     =*/ 1'b0,
                  /*cks    =*/ cks
                );
      apb_write(`TCR_ADDR, tcr_cfg);

      // 2. Hạ LOAD về 0, vẫn EN=0 để giữ nguyên TCNT, không cho chạy
      tcr_cfg = config_TCR(
                  /*load   =*/ 1'b0,
                  /*updown =*/ updown,
                  /*en     =*/ 1'b0,
                  /*cks    =*/ cks
                );
      apb_write(`TCR_ADDR, tcr_cfg);
    end
  endtask

  // ---------------------------------------------------
  // program_and_start:
  //   - clear TSR
  //   - ghi TDR = start_val
  //   - TCR: LOAD=1, EN=1
  //   - sau 1 xung PCLK: LOAD=0, EN=1 => bắt đầu đếm
  // ---------------------------------------------------
  task automatic program_and_start (
    input logic [DATA_WIDTH-1:0] start_val,
    input logic                  updown,   // 0: up, 1: down
    input logic [1:0]            cks
  );
    logic [DATA_WIDTH-1:0] tcr_config;
    begin
      // Clear flag trước
      clear_tsr();

      // Ghi TDR
      apb_write(`TDR_ADDR, start_val);

      // TCR: LOAD=1, EN=1
      tcr_config = config_TCR(1'b1, updown, 1'b1, cks);
      apb_write(`TCR_ADDR, tcr_config);

      // Sau 1 nhịp PCLK, tắt LOAD (0), vẫn EN=1 để counter chạy
      @(posedge apb.PCLK);
      tcr_config = config_TCR(1'b0, updown, 1'b1, cks);
      apb_write(`TCR_ADDR, tcr_config);
    end
  endtask

  // ---------------------------------------------------
  // pause_counter: dừng timer (EN=0)
  // ---------------------------------------------------
  task automatic pause_counter (
    input logic       updown,
    input logic [1:0] cks
  );
    logic [DATA_WIDTH-1:0] tcr_config;
    begin
      tcr_config = config_TCR(1'b0, updown, 1'b0, cks);
      apb_write(`TCR_ADDR, tcr_config);
    end
  endtask

  // ---------------------------------------------------
  // resume_counter: chạy tiếp timer (EN=1)
  // ---------------------------------------------------
  task automatic resume_counter (
    input logic       updown,
    input logic [1:0] cks
  );
    logic [DATA_WIDTH-1:0] tcr_config;
    begin
      tcr_config = config_TCR(1'b0, updown, 1'b1, cks);
      apb_write(`TCR_ADDR, tcr_config);
    end
  endtask

endmodule

`endif // __APB_TRANS_BUS_V__
