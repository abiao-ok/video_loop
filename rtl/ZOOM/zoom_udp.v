/*==============================================

==============================================*/
module zoom_udp (
    error_empty ,
    rst_n       ,   // input        
    clk_udp     ,   // input        摄像头像素时钟
    din_vs      ,   // input        在图片头复位 注意 vs==1 会复位
    din_vld     ,   // input        输入像素数据 有效信号
    din         ,   // input [15:0] 输入像素数据
    clk_100M    ,   // input        ddr3使用的时钟
    udp_frame   ,   // output[ 1:0] udp 正在写的帧 1,2,3
    udp_req     ,   // output       udp 的传输请求
    udp_vld     ,   // output       udp 的数据有效信号
    udp_data    ,   // output[255:0]udp 的数据 wdata1_rden 拉高的两拍后 输出有效数据
    udp_addr    ,   // output[15:0] udp 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
    udp_rden        // input        udp一个周期 指示 udp 可以传输一组数据了
);
    
    input        rst_n      ;   // 需要在图片头复位 注意 vs 的高低
    input        clk_udp    ;   // 
    input        din_vs     ;   // 需要在图片头复位 注意 vs 的高低
    input        din_vld    ;   // 输入像素数据 有效信号
    input [15:0] din        ;   // 输入像素数据
    input        clk_100M   ;
    output[ 1:0] udp_frame  ;
    output       udp_req    ;
    output       udp_vld    ;
    output[239:0]udp_data   ;
    output[15:0] udp_addr   ;
    input        udp_rden   ;
    output  error_empty;
    
    parameter   begin_addr = 16'd9_722;
    
    wire[23:0] pout       ;   // 图像缩放后的输出数据
    reg   pout_vld   ;   // 输出数据有效指示信号
    
    wire         data_vld   ;
    wire [15:0]  dout1_1    ;
    wire [15:0]  dout1_2    ;
    wire [15:0]  dout2_1    ;
    wire [15:0]  dout2_2    ;
    wire         hs_end     ;
    wire         XY_vld     ;
    
    matrix_udp matrix_udp( // 为了时序最大化，舍弃了 matrix_busy 指示信号，务必保证，完成一张图片后才能进行第二张图片
        .clk      (clk_udp )  ,   // input        
        .rst_n    (rst_n   )  ,   // input         传输完一张图片，本模块最好要复位
        .vga_vs   (din_vs  )  ,   // input        每过三张图片，在头复位, vga_vs==1为头
        .din_vld  (din_vld )  ,   // input         输入像素数据 有效信号
        .din      (din     )  ,   // input  [15:0] 输入像素数据
        .data_vld (data_vld)  ,   // output        矩阵数据 有效信号
        .dout1_1  (dout1_1 )  ,   // output [15:0] 矩阵的(1,1)位
        .dout1_2  (dout1_2 )  ,   // output [15:0]       (1,2)
        .dout2_1  (dout2_1 )  ,   // output [15:0]       (2,1)
        .dout2_2  (dout2_2 )  ,   // output [15:0]       (2,2)
        .hs_end   (hs_end  )      // output 
        
    );
    
    wire [ 3:0] udp_dx, udp_dy;
    wire [ 7:0] udp_dxy;
    udp_dxdy udp_dxdy(
        .clk     (clk_udp ),   // input        
        .udp_vs  (din_vs  ),   // input
        .udp_vld (data_vld),   // input 
        .hs_end  (hs_end  ),   // input        选择系数
        .udp_dx  (udp_dx  ),   // output[ 3:0] 系数 组合 没有打拍
        .udp_dy  (udp_dy  ),   // output[ 3:0] 系数 
        .udp_dxy (udp_dxy ),   // output[ 7:0] 系数 在vga_dx有效的后面第二拍有效
        .XY_vld  (XY_vld  )    // output
    );
    
    wire [ 4:0] pout_r;
    zoom445 zoom_vga_r(    // dx,dy 4bit; p 5bit
        .clk    (clk_udp        ) ,   // input
        .dx_in  (udp_dx         ) ,   // input [ 3:0] 系数 dx
        .dy_in  (udp_dy         ) ,   // input [ 3:0] 系数 dy
        .dx_dy  (udp_dxy        ) ,   // input [ 7:0] dx*dy   会在 dy_in 有效的第二拍有效
        .pixel_1(dout1_1[15:11] ) ,   // input [ 4:0] (1,1)位置像素
        .pixel_2(dout1_2[15:11] ) ,   // input [ 4:0] (1,2)位置像素
        .pixel_3(dout2_1[15:11] ) ,   // input [ 4:0] (2,1)位置像素
        .pixel_4(dout2_2[15:11] ) ,   // input [ 4:0] (2,2)位置像素
        .pout   (pout_r         )     // output[ 4:0] 缩放后的像素 第五拍输出
    );
    
    wire [ 5:0] pout_g;
    zoom446 zoom_vga_g(
        .clk    (clk_udp        ) ,   // input
        .dx_in  (udp_dx         ) ,   // input [ 3:0] 系数 dx
        .dy_in  (udp_dy         ) ,   // input [ 3:0] 系数 dy
        .dx_dy  (udp_dxy        ) ,   // input [ 7:0] dx*dy   会在 dy_in 有效的第二拍有效
        .pixel_1(dout1_1[10: 5] ) ,   // input [ 5:0] (1,1)位置像素
        .pixel_2(dout1_2[10: 5] ) ,   // input [ 5:0] (1,2)位置像素
        .pixel_3(dout2_1[10: 5] ) ,   // input [ 5:0] (2,1)位置像素
        .pixel_4(dout2_2[10: 5] ) ,   // input [ 5:0] (2,2)位置像素
        .pout   (pout_g         )     // output[ 5:0] 缩放后的像素 第五拍输出
    );
    
    wire [ 4:0] pout_b;
    zoom445 zoom_vga_b(    // dx,dy 4bit; p 5bit
        .clk    (clk_udp        ) ,   // input
        .dx_in  (udp_dx         ) ,   // input [ 3:0] 系数 dx
        .dy_in  (udp_dy         ) ,   // input [ 3:0] 系数 dy
        .dx_dy  (udp_dxy        ) ,   // input [ 7:0] dx*dy   会在 dy_in 有效的第二拍有效
        .pixel_1(dout1_1[ 4: 0] ) ,   // input [ 4:0] (1,1)位置像素
        .pixel_2(dout1_2[ 4: 0] ) ,   // input [ 4:0] (1,2)位置像素
        .pixel_3(dout2_1[ 4: 0] ) ,   // input [ 4:0] (2,1)位置像素
        .pixel_4(dout2_2[ 4: 0] ) ,   // input [ 4:0] (2,2)位置像素
        .pout   (pout_b         )     // output[ 4:0] 缩放后的像素 第五拍输出
    );
    
    assign pout = {pout_r,3'b0,pout_g,2'b0,pout_b,3'b0};
    
    reg pout_vld_d3, pout_vld_d4;
    always @(posedge clk_udp or negedge rst_n)begin		// 数据有效信号放在第五拍
        if(!rst_n)begin
            pout_vld_d3 <= 'd0;
            pout_vld_d4 <= 'd0;
            pout_vld    <= 'd0;
        end
        else begin
            pout_vld_d3 <= XY_vld;
            pout_vld_d4 <= pout_vld_d3;
            pout_vld    <= pout_vld_d4;
        end
    end
    
    zoom_addr #(
        .begin_addr(begin_addr)
    )
    zoom_vga_addr(
        .error_empty(error_empty),
        .rst_n     (rst_n    )  ,   // input        
        .clk_zoom  (clk_udp  )  ,   // input        
        .vga_vs    (din_vs   )  ,   // input        每过三张图片，在头复位, vga_vs==1为头
        .pout_vld  (pout_vld )  ,   // input        有效信号缩放后的数据
        .pout      (pout     )  ,   // input [23:0] 缩放后的数据
        .clk_100M  (clk_100M )  ,   // input        ddr3使用的时钟
        .frame     (udp_frame)  ,   // output[ 1:0] udp 正在写的帧 1,2,3
        .data_req  (udp_req  )  ,   // output       udp 的传输请求
        .data_vld  (udp_vld  )  ,   // output       udp 的数据有效信号
        .data_data (udp_data )  ,   // output[239:0]udp 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .data_addr (udp_addr )  ,   // output[15:0] udp 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .data_rden (udp_rden )      // input        一个周期 指示 HDMI 可以传输一组数据了
    );

endmodule
