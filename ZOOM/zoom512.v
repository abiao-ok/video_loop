/*==============================================
960/512 = 15/8
SrcX * 16 = 30 * DstX + 7

==============================================*/
module zoom512 (
    rst_n      ,   // input        
    clk_100M   ,   // input        ddr3使用的时钟
    din1_vs    ,   // input        在图片头复位 注意 vs==1 会复位
    din1_vld   ,   // input        输入像素数据 有效信号
    din1       ,   // input [23:0] 输入像素数据
    din2_vs    ,   // input        在图片头复位 注意 vs==1 会复位
    din2_vld   ,   // input        输入像素数据 有效信号
    din2       ,   // input [23:0] 输入像素数据
    din3_vs    ,   // input        在图片头复位 注意 vs==1 会复位
    din3_vld   ,   // input        输入像素数据 有效信号
    din3       ,   // input [23:0] 输入像素数据
    din4_vs    ,   // input        在图片头复位 注意 vs==1 会复位
    din4_vld   ,   // input        输入像素数据 有效信号
    din4       ,   // input [23:0] 输入像素数据
    ai_frame   ,   // output[ 1:0] HDMI 正在写的帧 1,2,3
    ai_req     ,   // output       HDMI 的传输请求
    ai_vld     ,   // output       HDMI 的数据有效信号
    ai_data    ,   // output[255:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
    ai_addr    ,   // output[15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
    ai_rden        // input        一个周期 指示 HDMI 可以传输一组数据了
    
);
    
    
    
    
    
    
    
    
    
    
    
    
    
endmodule
