/*==============================================
优化方向：把两个IIC改为1个

==============================================*/
module HDMI_out (
    error_empty  ,
    cfg_clk      ,   // output       10Mhz
    clk_24M      ,   // output
    sys_clk      ,   // input        50Mhz
    rstn_out     ,   // output       
    iic_scl      ,   // output       HDMI_IN 的 IIC 配置端口
    iic_sda      ,   // inout        
    iic_tx_scl   ,   // output       HDMI_OUT 的 IIC 配置端口
    iic_tx_sda   ,   // inout        
    pixclk_out   ,   // output       输出给 HDMI_OUT 的像素时钟 148.500MHz;  1920 x 1080 @ 60Hz
    vs_out       ,   // output       场同步
    hs_out       ,   // output       行同步
    de_out       ,   // output       数据有效信号
    r_out        ,   // output [7:0] r
    g_out        ,   // output [7:0] g
    b_out        ,   // output [7:0] b
    led_int      ,   // output       灯指示 HDMI 芯片初始化完成
    rst_n        ,   // input        
    clk_100M     ,   // input        ddr3 工作时钟
    wr_hdmi_frame,   // input [ 1:0] HDMI 写入ddr3的帧编号 1, 2, 3
    wr_udp_frame ,   // input [ 1:0] UDP  写入ddr3的帧编号 1, 2, 3
    wr_vgaa_frame,   // input [ 1:0] vga1 写入ddr3的帧编号 1, 2, 3
    wr_vgab_frame,   // input [ 1:0] vga2 写入ddr3的帧编号 1, 2, 3
    rd_hdmi_req  ,   // output       要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
    rd_hdmi_addr ,   // output[15:0] rdata1 的地址 与 raddr1_need 对齐
    rd_hdmi_ref  ,   // input        刷新下一个地址 
    rdata_vld    ,   // input        ddr3输出的数据有效信号
    rdata        ,   // input[255:0] ddr3输出的数据
    rid          ,   // input[  3:0] ddr3输出数据的 id
    rlast            // input        ddr3 一次突发读的最后一个数据
);
    output              cfg_clk     ;   // 
    output              clk_24M     ;
    input               sys_clk     ;   // 50Mhz
    //MS72xx
    output              rstn_out    ;   // 
    output              iic_scl     ;   // HDMI_IN 的 IIC 配置端口
    inout               iic_sda     ;   // 
    output              iic_tx_scl  ;   // HDMI_OUT 的 IIC 配置端口
    inout               iic_tx_sda  ;   // 
    //HDMI_OUT
    output              pixclk_out  ;   // 输出给 HDMI_OUT 的像素时钟 148.500MHz;  1920 x 1080 @ 60Hz
    output reg          vs_out      ;   // 场同步
    output reg          hs_out      ;   // 行同步
    output reg          de_out      ;   // 数据有效信号
    output reg    [7:0] r_out       ;   // r
    output reg    [7:0] g_out       ;   // g
    output reg    [7:0] b_out       ;   // b
    output              led_int     ;   // 灯指示 HDMI 芯片初始化完成
    input               rst_n           ;   // 
    input               clk_100M        ;   // ddr3 工作时钟
    input [ 1:0]        wr_hdmi_frame   ;   // HDMI 写入ddr3的帧编号 1, 2, 3
    input [ 1:0]        wr_udp_frame    ;   // UDP  写入ddr3的帧编号 1, 2, 3
    input [ 1:0]        wr_vgaa_frame   ;   // vga1 写入ddr3的帧编号 1, 2, 3
    input [ 1:0]        wr_vgab_frame   ;   // vga2 写入ddr3的帧编号 1, 2, 3
    output              rd_hdmi_req     ;   // 要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
    output[15:0]        rd_hdmi_addr    ;   // rdata1 的地址 与 raddr1_need 对齐
    input               rd_hdmi_ref     ;   // 刷新下一个地址 
    input               rdata_vld       ;   // ddr3输出的数据有效信号
    input[255:0]        rdata           ;   // ddr3输出的数据
    input[  3:0]        rid             ;   // ddr3输出数据的 id
    input               rlast           ;   // ddr3 一次突发读的最后一个数据
    output              error_empty     ;
    
    reg [15:0]  rstn_1ms       ;
    wire        locked         ;
    wire        init_over      ;
    wire        vs_o           ;
    wire        hs_o           ;
    wire        de_o           ;
    wire        de_re          ;
    wire [23:0] rgb_out        ;
/////////////////////////////////////////////////////////////////////////////////////
    //PLL
    pll u_pll (
        .clkin1   (  sys_clk    ),//50MHz
        .clkout0  (  pixclk_out ),//148.5Mhz
        .clkout1  (  clk_24M    ),//24.23Mhz
        .clkout2  (  cfg_clk    ),//10MHz
        .pll_lock (  locked     )
    );
    //配置7210
    ms72xx_ctl ms72xx_ctl(
        .clk         (  cfg_clk    ), //input       clk,
        .rst_n       (  rstn_out   ), //input       rstn,
                                
        .init_over   (  init_over  ), //output      init_over,
        .iic_tx_scl  (  iic_tx_scl ), //output      iic_scl,
        .iic_tx_sda  (  iic_tx_sda ), //inout       iic_sda
        .iic_scl     (  iic_scl    ), //output      iic_scl,
        .iic_sda     (  iic_sda    )  //inout       iic_sda
    );

    assign    led_int  =  init_over; 

    always @(posedge cfg_clk)
    begin
    	if(!locked)
    	    rstn_1ms <= 16'd0;
    	else
    	begin
    		if(rstn_1ms == 16'h2710)
    		    rstn_1ms <= rstn_1ms;
    		else
    		    rstn_1ms <= rstn_1ms + 1'b1;
    	end
    end
    
    assign rstn_out = (rstn_1ms == 16'h2710);
    
    always  @(posedge pixclk_out)begin
        if(!init_over)begin
    	    vs_out       <=  1'b0        ;
            hs_out       <=  1'b0        ;
            de_out       <=  1'b0        ;
            r_out        <=  8'b0        ;
            g_out        <=  8'b0        ;
            b_out        <=  8'b0        ;
        end
    	else begin
            vs_out       <=  vs_o           ;
            hs_out       <=  hs_o           ;
            de_out       <=  de_o           ;
            r_out        <=  rgb_out[23:16] ;
            g_out        <=  rgb_out[15:8]  ;
            b_out        <=  rgb_out[7:0]   ;
        end
    end
    
/////////////////////////////////////////////////////////////////////////////////////
//产生visa时序 1080p
    sync_vg sync_vg(                            
        .clk            (  pixclk_out           ),//input                   clk,                                 
        .rstn           (  rst_n                ),//input                   rstn,     ddr3 初始化 init_done 期间 不产生visa时序
        .vs_out         (  vs_o                 ),//output reg              vs_out,   提供给上游 fifo 刷新
        .hs_out         (  hs_o                 ),//output reg              hs_out,    
        .de_out         (  de_o                 ),//output reg              de_out, 
        .de_re          (  de_re                ) //output              比 de_out 提前了两个周期, 在 de_re 拉高后的第二个周期要加载像素数据
    );  
////////////////////////////////////////////////////////////////////////////////////////////
    HDMI_RD_DDR3 HDMI_RD_DDR3(
        .error_empty(error_empty),
        .rst_n         (rst_n        )  ,   // input        
        .clk_100M      (clk_100M     )  ,   // input        ddr3 工作时钟
        .wr_hdmi_frame (wr_hdmi_frame)  ,   // input [ 1:0] HDMI 写入ddr3的帧编号 1, 2, 3
        .wr_udp_frame  (wr_udp_frame )  ,   // input [ 1:0] UDP  写入ddr3的帧编号 1, 2, 3
        .wr_vgaa_frame (wr_vgaa_frame)  ,   // input [ 1:0] vga1 写入ddr3的帧编号 1, 2, 3
        .wr_vgab_frame (wr_vgab_frame)  ,   // input [ 1:0] vga2 写入ddr3的帧编号 1, 2, 3
        .rd_hdmi_req   (rd_hdmi_req  )  ,   // output       要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
        .rd_hdmi_addr  (rd_hdmi_addr )  ,   // output [15:0]rdata1 的地址 与 raddr1_need 对齐
        .rd_hdmi_ref   (rd_hdmi_ref  )  ,   // input        刷新下一个地址 
        .rdata_vld     (rdata_vld    )  ,   // input        ddr3输出的数据有效信号
        .rdata         (rdata        )  ,   // input[255:0] ddr3输出的数据
        .rid           (rid          )  ,   // input[  3:0] ddr3输出数据的 id
        .rlast         (rlast        )  ,   // input        ddr3 一次突发读的最后一个数据
        .pix_clk       (pixclk_out   )  ,   // input        读 ddr3 的像素时钟
        .vga_vs        (vs_o         )  ,   // input        帧头
        .de_re         (de_re        )  ,   // input        在 de_re 拉高后的第二个周期要加载像素数据, fifo 输出寄存
        .rgb_out       (rgb_out      )      // output[23:0] 
    );
    
endmodule
