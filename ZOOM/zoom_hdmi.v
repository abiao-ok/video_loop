/*==============================================
在图片头加复位
加对接ddr3的fifo和地址发生器
clk_hdmi Fmax = 245Mhz
clk_100M Fmax = 159Mhz
==============================================*/
module zoom_hdmi (
    error_empty,
    rst_n           ,   // input        
    clk_hdmi        ,   // input        HDMI 像素时钟
    vga_vs          ,   // input        在图片头复位 注意 vs==1 会复位
    din_vld         ,   // input        数据有效信号
    din             ,   // input [23:0] 数据
    clk_100M        ,   // input        ddr3的工作时钟
    wrhdmi_frame    ,   // output[ 1:0] 写入ddr3的帧编号 1, 2, 3
    wrhdmi_req      ,   // output       有 16*240bit 个数据了 申请写入ddr3
    wrhdmi_vld      ,   // output       数据有效信号
    wrhdmi_data     ,   // output[239:0]240bit数据
    wrhdmi_addr     ,   // output[15:0] 需要写入的地址
    wrhdmi_rden         // input        指示发送16个240bit数据
);
    
    input        rst_n       ;
    input        clk_hdmi    ;
    input        vga_vs      ;   // 需要在图片头复位 注意 vs 的高低
    input        din_vld     ;
    input [23:0] din         ;
    input        clk_100M   ;
    output[ 1:0] wrhdmi_frame ;
    output       wrhdmi_req   ;
    output       wrhdmi_vld   ;
    output[239:0]wrhdmi_data  ;
    output[15:0] wrhdmi_addr  ;
    input        wrhdmi_rden  ;
    output  error_empty;
    parameter begin_addr = 16'd1;
    
    reg         pout_vld    ;
    wire [23:0] pout        ;
    wire data_vld, data_X, data_Y;
    wire [23:0] dout1_1    ;
    wire [23:0] dout1_2    ;
    wire [23:0] dout2_1    ;
    wire [23:0] dout2_2    ;
    wire [ 7:0] pout_r, pout_g, pout_b;
    wire         rstn       ;
    
    // 在帧头复位  vga_vs==1 复位
    assign rstn = rst_n && (~vga_vs);
    
    matrix_hdmi matrix_hdmi(  // 为了时序最大化，舍弃了 matrix_busy 指示信号，务必保证，完成一张图片后才能进行第二张图片
        .clk      (clk_hdmi)   ,   // input        
        .rst_n    (rstn    )   ,   // input         传输完一张图片，本模块最好要复位
        .din_vld  (din_vld )   ,   // input         输入像素数据 有效信号
        .din      (din     )   ,   // input  [23:0] 输入像素数据
        .data_vld (data_vld)   ,   // output        矩阵数据 有效信号
        .dout1_1  (dout1_1 )   ,   // output [23:0] 矩阵的(1,1)位
        .dout1_2  (dout1_2 )   ,   // output [23:0]       (1,2)
        .dout2_1  (dout2_1 )   ,   // output [23:0]       (2,1)
        .dout2_2  (dout2_2 )   ,   // output [23:0]       (2,2)
        .data_X   (data_X  )   ,   // output        像素 x 坐标的低两位
        .data_Y   (data_Y  )       // output        像素 y 坐标的低两位
    );
    
    always @(posedge clk_hdmi or negedge rstn)begin	// 
        if(!rstn)begin
            pout_vld <= 1'b0;
        end
        else begin
            pout_vld <= data_X && data_Y;
        end
    end
    
    AvgPooling hdmi_r(
        .clk      (clk_hdmi         )    ,   // input
        .pixel_1  (dout1_1[23:16]   )    ,   // input [ 7:0] (1,1)位置像素
        .pixel_2  (dout1_2[23:16]   )    ,   // input [ 7:0] (1,2)位置像素
        .pixel_3  (dout2_1[23:16]   )    ,   // input [ 7:0] (2,1)位置像素
        .pixel_4  (dout2_2[23:16]   )    ,   // input [ 7:0] (2,2)位置像素
        .pout     (pout_r           )        // output[ 7:0] 结果在下一拍加载
    );
    
    AvgPooling hdmi_g(
        .clk      (clk_hdmi         )    ,   // input
        .pixel_1  (dout1_1[15:8]    )    ,   // input [ 7:0] (1,1)位置像素
        .pixel_2  (dout1_2[15:8]    )    ,   // input [ 7:0] (1,2)位置像素
        .pixel_3  (dout2_1[15:8]    )    ,   // input [ 7:0] (2,1)位置像素
        .pixel_4  (dout2_2[15:8]    )    ,   // input [ 7:0] (2,2)位置像素
        .pout     (pout_g           )        // output[ 7:0] 结果在下一拍加载
    );
    
    AvgPooling hdmi_b(
        .clk      (clk_hdmi         )    ,   // input
        .pixel_1  (dout1_1[7:0]     )    ,   // input [ 7:0] (1,1)位置像素
        .pixel_2  (dout1_2[7:0]     )    ,   // input [ 7:0] (1,2)位置像素
        .pixel_3  (dout2_1[7:0]     )    ,   // input [ 7:0] (2,1)位置像素
        .pixel_4  (dout2_2[7:0]     )    ,   // input [ 7:0] (2,2)位置像素
        .pout     (pout_b           )        // output[ 7:0] 结果在下一拍加载
    );
    
    assign pout = {pout_r, pout_g, pout_b};
    
    zoom_addr #(.begin_addr(begin_addr))
    zoom_hdmi_addr(
        .error_empty(error_empty),
        .rst_n      (rst_n        ) ,   // input        
        .clk_zoom   (clk_hdmi     ) ,   // input        
        .vga_vs     (vga_vs       ) ,   // input        在头复位, vga_vs==1为头
        .pout_vld   (pout_vld     ) ,   // input        有效信号缩放后的数据
        .pout       (pout         ) ,   // input [23:0] 缩放后的数据
        .clk_100M   (clk_100M     ) ,   // input        ddr3使用的时钟
        .frame      (wrhdmi_frame ) ,   // output[ 1:0] HDMI 正在写的帧 1,2,3
        .data_req   (wrhdmi_req   ) ,   // output       HDMI 的传输请求
        .data_vld   (wrhdmi_vld   ) ,   // output       HDMI 的数据有效信号
        .data_data  (wrhdmi_data  ) ,   // output[239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .data_addr  (wrhdmi_addr  ) ,   // output[15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .data_rden  (wrhdmi_rden  )     // input        一个周期 指示 HDMI 可以传输一组数据了
    );
    
endmodule
