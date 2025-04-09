`timescale 1ns/1ps

`include "vitis_net_p4_core_pkg.sv"

import vitis_net_p4_core_pkg::NUM_USER_EXTERNS;
import vitis_net_p4_core_pkg::USER_EXTERN_OUT_WIDTH;
import vitis_net_p4_core_pkg::USER_EXTERN_IN_WIDTH;

module user_externs (
  input  [NUM_USER_EXTERNS-1:0]      user_extern_out_valid,
  input  [USER_EXTERN_OUT_WIDTH-1:0] user_extern_out,

  output [NUM_USER_EXTERNS-1:0]      user_extern_in_valid,
  output [USER_EXTERN_IN_WIDTH-1:0]  user_extern_in,

  input aclk,
  input aresetn
);

  divider_extern divider_extern_inst (
    .user_extern_out_valid (user_extern_out_valid[0]),
    .user_extern_out       (user_extern_out[63:0]),
    .user_extern_in_valid  (user_extern_in_valid[0]),
    .user_extern_in        (user_extern_in[63:0]),
    .aclk    (aclk),
    .aresetn (aresetn)
  );

endmodule: user_externs
