// STATUS: OK

`ifndef RW_REG_CONTROL_V
`define RW_REG_CONTROL_V

`include "reg_def.sv"
// `DATA_WIDTH = 8

module rw_reg_control #(
  parameter int ADDR_WIDTH = `ADDR_WIDTH
)(
  // APB INTERFACE SIGNALS
  input  wire                   PCLK,
  input  wire                   PRESETn,
  input  wire                   PSEL,
  input  wire                   PENABLE,
  input  wire                   PWRITE,
  input  wire [ADDR_WIDTH-1:0]  PADDR,
  input  wire [`DATA_WIDTH-1:0] PWDATA,
  
  output wire [`DATA_WIDTH-1:0] PRDATA,
  output wire                   PREADY,
  output wire                   PSLVERR,
  
  input  wire                   TMR_OVF,
  input  wire                   TMR_UDF,
  
  // INTERNAL REGISTER VALUES (to be used by other modules)
  input  wire [`DATA_WIDTH-1:0] TCNT,
  output wire [`DATA_WIDTH-1:0] TDR,
  output wire [`DATA_WIDTH-1:0] TCR,
  output wire [`DATA_WIDTH-1:0] TSR
);
  
  wire [`DATA_WIDTH-1:0] reg_TDR;
  wire [`DATA_WIDTH-1:0] reg_TCR;
  wire [`DATA_WIDTH-1:0] reg_TSR;

  // Internal wires for connecting sub-modules
  wire                   apb_flag;
  wire                   apb_pready;	  
  wire                   apb_pslverr;	  
  wire [`DATA_WIDTH-1:0] read_prdata; // Internal wire to connect read logic output to top-level PRDATA
  
  // ------------------------------------------------------------------
  // Module Instantiations
  // ------------------------------------------------------------------
  
  // APB Transaction FSM
  // This module manages the APB handshake and generates pready/pslverr signals.
  APB_trans #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_apb_trans (
    // input
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .paddr     (PADDR),
    // output
    .flag      (apb_flag),
    .pready    (apb_pready),
    .pslverr   (apb_pslverr)
  );

  // Write Logic Module
  // This module handles writing to TDR, TCR, and TSR registers.
  rw_write_logic #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rw_write_logic (
    // input
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .flag      (apb_flag),
    .pwrite    (PWRITE),
    .paddr     (PADDR),
    .pwdata    (PWDATA),
    .ovf_flag  (TMR_OVF),
    .udf_flag  (TMR_UDF),
    // output
    .TDR       (reg_TDR),
    .TCR       (reg_TCR),
    .TSR       (reg_TSR)
  );

  // Read Logic Module
  // This module handles reading from all registers (TDR, TCR, TSR, TCNT).
  rw_read_logic #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rw_read_logic (
    // input
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .flag      (apb_flag),
    .pwrite    (PWRITE),
    .paddr     (PADDR),
    .TDR       (reg_TDR),
    .TCR       (reg_TCR),
    .TSR       (reg_TSR),
    .TCNT      (TCNT),
    // output
    .prdata    (read_prdata)
  );
  
  // ------------------------------------------------------------------
  // Register reset logic: initialize internal registers on reset
  // ------------------------------------------------------------------
  
  // Assign top-level outputs
  assign PREADY  = apb_pready;
  assign PSLVERR = apb_pslverr;
  assign PRDATA  = read_prdata; 
  assign TDR     = reg_TDR;
  assign TCR     = reg_TCR;
  assign TSR     = reg_TSR;
endmodule

// -----------------------------------------------------------
// Sub-module: rw_read_logic
// Description: Handles all read transactions from APB to the registers.
// -----------------------------------------------------------
module rw_read_logic #(
  parameter ADDR_WIDTH = 8
)(
  input  wire                   pclk,
  input  wire                   preset_n,
  input  wire                   flag,	
  input  wire                   pwrite,
  input  wire [ADDR_WIDTH-1:0]  paddr,
  
  input  wire [`DATA_WIDTH-1:0] TDR,
  input  wire [`DATA_WIDTH-1:0] TCR,
  input  wire [`DATA_WIDTH-1:0] TSR,
  input  wire [`DATA_WIDTH-1:0] TCNT,
  
  output reg  [`DATA_WIDTH-1:0] prdata
);

  wire read_en;
  assign read_en = flag & !pwrite;

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      prdata <= {`DATA_WIDTH{1'b0}};
    end else begin
      if (read_en) begin
        case (paddr)
          `TDR_ADDR  : prdata <= TDR;
          `TCR_ADDR  : prdata <= TCR;
          `TSR_ADDR  : prdata <= TSR;
          `TCNT_ADDR : prdata <= TCNT;
          default    : prdata <= {`DATA_WIDTH{1'b0}};
        endcase
      end else begin
        prdata <= prdata;
      end
    end
  end
endmodule

// -----------------------------------------------------------
// Sub-module: rw_write_logic
// Description: Handles all write transactions from APB to the registers.
// -----------------------------------------------------------
module rw_write_logic #(
  parameter ADDR_WIDTH = 8
)(
  input  wire                   pclk,
  input  wire                   preset_n,
  input  wire                   flag,	
  input  wire                   pwrite,
  input  wire [ADDR_WIDTH-1:0]  paddr,
  input  wire [`DATA_WIDTH-1:0] pwdata,
  
  input  wire                   ovf_flag,
  input  wire                   udf_flag, 
  
  output reg  [`DATA_WIDTH-1:0] TDR,
  output reg  [`DATA_WIDTH-1:0] TCR,
  output reg  [`DATA_WIDTH-1:0] TSR
);
  wire [2:0] w_reg_sel; // Input for write register select
  wire       write_en;
  
  assign w_reg_sel = (paddr == `TDR_ADDR) ? 3'b001 : 
    				 (paddr == `TCR_ADDR) ? 3'b010 : 
    				 (paddr == `TSR_ADDR) ? 3'b100 : 3'b000;
    
  // The `|w_reg_sel` check ensures that there is a selected reg for writing.
  assign write_en = flag & pwrite & |w_reg_sel;

  // Logic to handle reserved bits before writing to registers
  wire [`DATA_WIDTH-1:0] wdata_tdr;
  wire [`DATA_WIDTH-1:0] wdata_tcr;
  wire [`DATA_WIDTH-1:0] wdata_tsr;
  
  assign wdata_tdr = pwdata;
  assign wdata_tcr = pwdata & `TCR_WRITE_MASK; // = {pwdata[7], 1'b0, pwdata[5:4], 2'b00, pwdata[1:0]};
  assign wdata_tsr = pwdata & `TSR_WRITE_MASK; // = {6'b00, pwdata[1:0]};

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      TDR <= `TDR_RST;
      TCR <= `TCR_RST;
      TSR <= `TSR_RST;
    end else begin

      // Hardware set flags - TSR <= {6'b0000_00, udf_flag, ovf_flag};
      if (write_en) begin
        TDR <= (w_reg_sel[0]) ? wdata_tdr : TDR;
        TCR <= (w_reg_sel[1]) ? wdata_tcr : TCR;
        // TSR: clear flags if write '1'
        if (w_reg_sel[2]) begin
          TSR[0] <= (wdata_tsr[0]) ? 1'b0 : TSR[0]; // clear bit OVF if wdata_tsr[0] = 1
          TSR[1] <= (wdata_tsr[1]) ? 1'b0 : TSR[1]; // clear bit UDF if wdata_tsr[0] = 1
        end else begin
          // Hardware set flags
          TSR[0] <= (ovf_flag) ? 1'b1 : TSR[0];
          TSR[1] <= (udf_flag) ? 1'b1 : TSR[1];
        end
      end else begin 
        TDR <= TDR;
        TCR <= TCR;
        TSR <= {6'b0000_00, udf_flag, ovf_flag}; // Continuously update TSR with current flags
      end
    end
  end
endmodule

// -----------------------------------------------------------
// Sub-module: apb_trans (APB Transaction FSM)
// -----------------------------------------------------------
module APB_trans #(
  parameter ADDR_WIDTH = 8
)(
  // SIGNAL FOR APB INTERFACE
  input  logic                  pclk,
  input  logic                  preset_n,
  input  logic                  psel,
  input  logic                  penable,
  input  logic                  pwrite,
  input  logic [ADDR_WIDTH-1:0] paddr,
  
  output logic                  flag,              
  output logic                   pready,
  output logic                   pslverr             
);
  
  // FSM state encoding
  typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_t;
  state_t cur_state, next_state;

  logic       flag_init;
  logic       invalid_addr;

  // FSM: State transition
  always_ff @(posedge pclk or negedge preset_n) begin
    if (!preset_n) 
      cur_state <= IDLE;
    else           
      cur_state <= next_state;
  end

  // FSM: Next state logic
  always_comb begin
    unique case (cur_state)
      IDLE:    next_state = (psel  & !penable) ? SETUP : IDLE;
      SETUP :  next_state = (psel &&  penable) ? ACCESS :
                            (!psel)            ? IDLE   : SETUP;
      ACCESS:  next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end
  
  // ..... CHECK
  assign flag_init = (cur_state == SETUP) && (next_state == ACCESS);
  
  // Invalid address detection logic
  assign invalid_addr = pwrite 
    ? (paddr != `TDR_ADDR && paddr != `TCR_ADDR && paddr != `TSR_ADDR) 
    : (paddr != `TDR_ADDR && paddr != `TCR_ADDR && paddr != `TSR_ADDR && paddr != `TCNT_ADDR);
  
  // Output logic: pready and pslverr
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      pready  <= 1'b0; 
      pslverr <= 1'b0;
    end else begin
      pready  <= flag_init;
      pslverr <= flag_init & invalid_addr;
    end
  end
  
  assign flag = flag_init;
 
endmodule

`endif // RW_REG_CONTROL_V
