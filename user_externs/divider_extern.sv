`timescale 1ns/1ps

module divider_extern (
  input  logic        user_extern_out_valid,
  input  logic [63:0] user_extern_out,

  output logic        user_extern_in_valid,
  output logic [63:0] user_extern_in,

  input aclk,
  input aresetn
);

  typedef enum logic {
    S_IDLE,
    S_DONE
  } state_t;
  state_t state;

  typedef struct packed {
    logic [31:0] divisor;
    logic [31:0] dividend;
  } divider_input_t;

  typedef struct packed {
    logic [31:0] remainder;
    logic [31:0] quotient;
  } divider_output_t;

  divider_input_t  request;
  divider_output_t response;

  assign request = user_extern_out;
  assign user_extern_in = response;

  always_ff @(posedge aclk) begin
    if (~aresetn) begin
      state <= S_IDLE;
      response <= '0;
      user_extern_in_valid <= 1'b0;
    end else begin
      case (state)
        S_IDLE: begin
          if (user_extern_out_valid) begin
            state <= S_DONE;
            user_extern_in_valid <= 1'b1;
            if (request.divisor == 32'h0) begin
              response.quotient <= 32'hFFFFFFFF;
              response.remainder <= request.dividend;
            end else begin
              response.quotient <= request.dividend / request.divisor;
              response.remainder <= request.dividend % request.divisor;
            end
          end
        end

        S_DONE: begin
          state <= S_IDLE;
          response <= '0;
          user_extern_in_valid <= 1'b0;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule: divider_extern
