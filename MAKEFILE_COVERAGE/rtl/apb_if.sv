`ifndef APB_IF_SV
`define APB_IF_SV

`include "reg_def.sv"

// -----------------------------------------------------------------------------
// Simple APB interface
// -----------------------------------------------------------------------------
interface apb_if #(
  parameter int ADDR_WIDTH = `ADDR_WIDTH,
  parameter int DATA_WIDTH = `DATA_WIDTH
)(
  input  logic PCLK,
  input  logic PRESETn
);

  // APB signals
  logic                  PSEL;
  logic                  PENABLE;
  logic                  PWRITE;
  logic [ADDR_WIDTH-1:0] PADDR;
  logic [DATA_WIDTH-1:0] PWDATA;
  logic [DATA_WIDTH-1:0] PRDATA;
  logic                  PREADY;
  logic                  PSLVERR;

  // Master view (CPU / driver)
  modport MASTER (
    input  PCLK, PRESETn,
    input  PREADY, PRDATA, PSLVERR,
    output PSEL, PENABLE, PWRITE, PADDR, PWDATA
  );

  // Slave view (DUT)
  modport SLAVE (
    input  PCLK, PRESETn,
    input  PSEL, PENABLE, PWRITE, PADDR, PWDATA,
    output PREADY, PRDATA, PSLVERR
  );

endinterface

`endif // APB_IF_SV
