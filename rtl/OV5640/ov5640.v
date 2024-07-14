// 优化方向：把两个IIC改为1个
`timescale 1ns / 1ps
`define UD #1
module ov5640 (
    input                               rst_n                 ,
	input                               clk_10M              ,//10Mhz
    //OV5647
    output                              cmos_init_done       ,//OV5640寄存器初始化完成
    //coms1	
    
    inout                               cmos1_scl            ,//cmos1 i2c 
    inout                               cmos1_sda            ,//cmos1 i2c 
    input                               cmos1_vsync          ,//cmos1 vsync
    input                               cmos1_href           ,//cmos1 hsync refrence,data valid
    // output                              cmos1_clk24M         ,//cmos1 24MHz
    input                               cmos1_pclk           ,//cmos1 pxiel clock
    input   [7:0]                       cmos1_data           ,//cmos1 data
    output                              cmos1_reset          ,//cmos1 reset
    output                              cmos1_pwdn           ,//cmos1 power down
    //coms2
    inout                               cmos2_scl            ,//cmos2 i2c 
    inout                               cmos2_sda            ,//cmos2 i2c 
    input                               cmos2_vsync          ,//cmos2 vsync
    input                               cmos2_href           ,//cmos2 hsync refrence,data valid
    // output                              cmos2_clk24M         ,//cmos2 24MHz
    input                               cmos2_pclk           ,//cmos2 pxiel clock
    input   [7:0]                       cmos2_data           ,//cmos2 data
    output                              cmos2_reset          ,//cmos2 reset
    output                              cmos2_pwdn           ,//cmos2 power down
    
    output                              cmos1_vs             ,
    output                              cmos1_de             ,
    output [15:0]                       cmos1_rgb565         ,
    output                              cmos2_vs             ,
    output                              cmos2_de             ,
    output [15:0]                       cmos2_rgb565          
    // output                              cmos3_vs             ,
    // output                              cmos3_de             ,
    // output [15:0]                       cmos3_rgb565          
);
// pix_clk //37.125M 720P30
/////////////////////////////////////////////////////////////////////////////////////
    wire                        initial_en          ;
    wire[15:0]                  cmos1_d_16bit       ;
    wire                        cmos1_href_16bit    ;
    reg [7:0]                   cmos1_d_d0          ;
    reg                         cmos1_href_d0       ;
    reg                         cmos1_vsync_d0      ;
    wire[15:0]                  cmos2_d_16bit       /*synthesis PAP_MARK_DEBUG="1"*/;
    wire                        cmos2_href_16bit    /*synthesis PAP_MARK_DEBUG="1"*/;
    reg [7:0]                   cmos2_d_d0          /*synthesis PAP_MARK_DEBUG="1"*/;
    reg                         cmos2_href_d0       /*synthesis PAP_MARK_DEBUG="1"*/;
    reg                         cmos2_vsync_d0      /*synthesis PAP_MARK_DEBUG="1"*/;
    

//配置CMOS///////////////////////////////////////////////////////////////////////////////////
//OV5640 register configure enable    
    power_on_delay	power_on_delay_inst(
    	.clk_10M                 (clk_10M       ),//input
    	.reset_n                 (rst_n         ),//input
    	.camera1_rstn            (cmos1_reset   ),//output
    	.camera2_rstn            (cmos2_reset   ),//output
    	.camera_pwnd             (camera_pwnd   ),//output
    	.initial_en              (initial_en    ) //output
    );
    
    assign cmos1_pwdn = camera_pwnd;
    assign cmos2_pwdn = camera_pwnd;
    
    reg_config	reg_config(
    	.clk_10M                 (clk_10M            ),//input
    	.camera_rstn             (cmos1_reset        ),//input
    	.initial_en              (initial_en         ),//input
    	.i2c_sclk1               (cmos1_scl          ),//output
    	.i2c_sdat1               (cmos1_sda          ),//inout
        .i2c_sclk2               (cmos2_scl          ),//output
    	.i2c_sdat2               (cmos2_sda          ),//inout
        .reg_conf_done           (cmos_init_done     ),//output config_finished
    	.reg_index               (                   ),//output reg [8:0]
    	.clock_20k               (                   ) //output reg
    );
    
//CMOS 8bit转16bit///////////////////////////////////////////////////////////////////////////////////
//CMOS1
    always@(posedge cmos1_pclk)
        begin
            cmos1_d_d0        <= cmos1_data    ;
            cmos1_href_d0     <= cmos1_href    ;
            cmos1_vsync_d0    <= cmos1_vsync   ;
        end
    
    cmos_8_16bit cmos1_8_16bit(
    	.pclk           (cmos1_pclk       ),//input
    	.rst_n          (cmos_init_done   ),//input
    	.pdata_i        (cmos1_d_d0       ),//input[7:0]
    	.de_i           (cmos1_href_d0    ),//input
    	.vs_i           (cmos1_vsync_d0   ),//input
    	
    	.pdata_o        (cmos1_d_16bit    ),//output[15:0]
    	.de_o           (cmos1_href_16bit ) //output
    );
//CMOS2
    always@(posedge cmos2_pclk)
        begin
            cmos2_d_d0        <= cmos2_data    ;
            cmos2_href_d0     <= cmos2_href    ;
            cmos2_vsync_d0    <= cmos2_vsync   ;
        end
    
    cmos_8_16bit cmos2_8_16bit(
    	.pclk           (cmos2_pclk       ),//input
    	.rst_n          (cmos_init_done   ),//input
    	.pdata_i        (cmos2_d_d0       ),//input[7:0]
    	.de_i           (cmos2_href_d0    ),//input
    	.vs_i           (cmos2_vsync_d0   ),//input
    	
    	.pdata_o        (cmos2_d_16bit    ),//output[15:0]
    	.de_o           (cmos2_href_16bit ) //output
    );
//输入视频源//////////////////////////////////////////////////////////////////////////////////////////

assign     cmos1_vs      =    cmos1_vsync_d0      ;
assign     cmos1_de      =    cmos1_href_16bit    ;
assign     cmos1_rgb565  =    {cmos1_d_16bit[4:0],cmos1_d_16bit[10:5],cmos1_d_16bit[15:11]};//{r,g,b}
assign     cmos2_vs      =    cmos2_vsync_d0      ;
assign     cmos2_de      =    cmos2_href_16bit    ;
assign     cmos2_rgb565  =    {cmos2_d_16bit[4:0],cmos2_d_16bit[10:5],cmos2_d_16bit[15:11]};//{r,g,b}

/* cmos_crop cmos1_crop(
    .clk        (cmos1_pclk  ) ,
    .rst_n      (rst_n       ) ,
    .vs_in      (cmos1_vs    ) ,
    .de_in      (cmos1_de    ) ,
    .rgb565_in  (cmos1_rgb565) ,
    .vs_out     (cmos3_vs    ) ,
    .de_out     (cmos3_de    ) ,
    .rgb565_out (cmos3_rgb565)
); */

endmodule
