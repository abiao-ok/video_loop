// Created by IP Generator (Version 2022.1 build 99559)
// Instantiation Template
//
// Insert the following codes into your Verilog file.
//   * Change the_instance_name to your own instance name.
//   * Change the signal names in the port associations


matrix_ram24_zoom_hdmi the_instance_name (
  .wr_data(wr_data),    // input [23:0]
  .addr(addr),          // input [10:0]
  .wr_en(wr_en),        // input
  .clk(clk),            // input
  .rst(rst),            // input
  .rd_data(rd_data)     // output [23:0]
);
