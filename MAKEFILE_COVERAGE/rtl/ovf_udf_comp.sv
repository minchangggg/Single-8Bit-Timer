
`ifndef OVF_UDF_COMP_V
`define OVF_UDF_COMP_V

`include "reg_def.sv"
// `DATA_WIDTH = 8

// -----------------------------------------------------------------------------
// Module: ovf_udf_comp
// Description:
//   This module detects overflow and underflow conditions for an up/down timer.
//   It compares the current TCNT value with the previous one to detect wrap-around,
//   setting corresponding flags (TMR_OVF, TMR_UDF).
//
// Features:
//   - Detects overflow when counting up: 0xFF -> 0x00
//   - Detects underflow when counting down: 0x00 -> 0xFF
//   - Separate clear signals for OVF and UDF flags
//   - Synchronous reset and edge-based detection
//
// Inputs:
//   - pclk          : System clock
//   - preset_n      : Active-low synchronous reset
//   - TCNT          : Current counter value
//   - count_enable  : Enable signal for counting
//   - count_up_down : 0 = count up, 1 = count down
//
// Outputs:
//   - TMR_OVF       : Overflow flag (set when counter wraps from max to 0)
//   - TMR_UDF       : Underflow flag (set when counter wraps from 0 to max)
// -----------------------------------------------------------------------------

module ovf_udf_comp (
  input  wire       		    pclk,            // System clock
  input  wire       		    preset_n,        // Active-low synchronous reset
  
  input  wire [`DATA_WIDTH-1:0] TCNT,            // Current counter value
  input  wire       		    count_enable,    // Count enable signal
  input  wire       		    count_up_down,   // 0: count up, 1: count down
  
  input  wire [`DATA_WIDTH-1:0] TSR,   			 // Timer Control Register
  output reg        		    TMR_OVF,         // Overflow flag
  output reg        		    TMR_UDF          // Underflow flag
);
  
  reg [`DATA_WIDTH-1:0] TCNT_d; // previous TCNT
  reg [`DATA_WIDTH-1:0] TSR_d;  // previous TSR

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      // Reset all flags
      TMR_OVF <= 1'b0;
      TMR_UDF <= 1'b0;
      TCNT_d  <= {`DATA_WIDTH{1'b0}};
      TSR_d   <= {`DATA_WIDTH{1'b0}};
    end else begin
      // detect SW-clear
      if ((TMR_OVF && !TSR[0] && TSR_d[0]) || (TMR_UDF && !TSR[1] && TSR_d[1])) begin
        TMR_OVF <= (TMR_OVF && !TSR[0] && TSR_d[0]) ? 1'b0 : TMR_OVF;
        TMR_UDF <= (TMR_UDF && !TSR[1] && TSR_d[1]) ? 1'b0 : TMR_UDF;
      end else if (count_enable) begin
        // Detect overflow/underflow only if enabled
        // Check counting direction
        if (!count_up_down) begin 
          // clear UDF trong mode up
          TMR_UDF <= 1'b0; 
          // Counting up: TCNT == 8'hFF means the counter is about to overflow.
          // The real overflow would happen on the next count (TCNT wraps to 8'h00).
          if (TCNT_d == {`DATA_WIDTH{1'b1}} && TCNT == {`DATA_WIDTH{1'b0}}) TMR_OVF <= 1'b1;
          else                                                              TMR_OVF <= TMR_OVF;
        end else begin 
          // clear OVF trong mode down
          TMR_OVF <= 1'b0; 
          // Counting down: TCNT == 8'h00 means the counter is about to underflow.
          // The real underflow would happen on the next count (TCNT wraps to 8'hFF).
          if (TCNT_d == {`DATA_WIDTH{1'b0}} && TCNT == {`DATA_WIDTH{1'b1}}) TMR_UDF <= 1'b1;
          else                                                              TMR_UDF <= TMR_UDF;
        end
      end else begin
        // No counting → hold them
        TMR_OVF <= TMR_OVF;
        TMR_UDF <= TMR_UDF;
      end
      
      // Save current value
      TCNT_d <= TCNT;
      // Save current status
      TSR_d  <= TSR;

    end  
  end

endmodule
    
`endif  // OVF_UDF_COMP_V
