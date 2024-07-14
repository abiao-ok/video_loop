/*==============================================
Total LUTs: 11206 of 42800 (26.18%)
	LUTs as dram: 1355 of 17000 (7.97%)
	LUTs as logic: 9851
Total Registers: 9861 of 64200 (15.36%)
Total Latches: 0

DRM18K:
Total DRM18K = 19.0 of 134 (14.18%)
==============================================*/
module video_loop (
    output led3, output led4, output led5, output led6, output led7,
    input           clk_50M     ,   // 50MHz
    input           rst_n       ,   // 
    
    input              eth_rxc       , //RGMII接收数据时钟
    input              eth_rx_ctl    , //RGMII输入数据有效信号
    input       [3:0]  eth_rxd       , //RGMII输入数据
    output             eth_txc       , //RGMII发送数据时钟    
    output             eth_tx_ctl    , //RGMII输出数据有效信号
    output      [3:0]  eth_txd       , //RGMII输出数据        
    output             eth_rst_n     , //以太网芯片复位信号，低电平有效   
    output             eth_led       ,
        
    output          cmos_init_done       ,//OV5640寄存器初始化完成
    inout           cmos1_scl            ,//cmos1 i2c 
    inout           cmos1_sda            ,//cmos1 i2c 
    input           cmos1_vsync          ,//cmos1 vsync
    input           cmos1_href           ,//cmos1 hsync refrence,data valid
    output          cmos1_clk24M         ,//cmos1 24MHz
    input           cmos1_pclk           ,//cmos1 pxiel clock
    input   [7:0]   cmos1_data           ,//cmos1 data
    output          cmos1_reset          ,//cmos1 reset
    output          cmos1_pwdn           ,//cmos1 power down
    inout           cmos2_scl            ,//cmos2 i2c 
    inout           cmos2_sda            ,//cmos2 i2c 
    input           cmos2_vsync          ,//cmos2 vsync
    input           cmos2_href           ,//cmos2 hsync refrence,data valid
    output          cmos2_clk24M         ,//cmos2 24MHz
    input           cmos2_pclk           ,//cmos2 pxiel clock
    input   [7:0]   cmos2_data           ,//cmos2 data
    output          cmos2_reset          ,//cmos2 reset
    output          cmos2_pwdn           ,//cmos2 power down
    output          rstn_out    ,   // 
    output          iic_scl     ,   // HDMI_IN 的 IIC 配置端口
    inout           iic_sda     ,   // 
    output          iic_tx_scl  ,   // HDMI_OUT 的 IIC 配置端口
    inout           iic_tx_sda  ,   // 
    input           pixclk_in   ,   // HDMI 输入像素时钟
    input           vs_in       ,   // 
    input           hs_in       ,   // 
    input           de_in       ,   // 
    input [7:0]     r_in        ,   // 
    input [7:0]     g_in        ,   // 
    input [7:0]     b_in        ,   // 
    output          pixclk_out  ,   // 输出给 HDMI_OUT 的像素时钟 148.500MHz;  1920 x 1080 @ 60Hz
    output          vs_out      ,   // 场同步
    output          hs_out      ,   // 行同步
    output          de_out      ,   // 数据有效信号
    output[7:0]     r_out       ,   // r
    output[7:0]     g_out       ,   // g
    output[7:0]     b_out       ,   // b
    output          led_int     ,   // 灯指示 HDMI 芯片初始化完成 LED1
    output          mem_rst_n   ,   // DDR 复位
    output          mem_ck      ,   // DDR 输入系统时钟
    output          mem_ck_n    ,   // DDR 输入系统时钟
    output          mem_cke     ,   // DDR 输入系统时钟有效。
    output          mem_cs_n    ,   // DDR 的片选
    output          mem_ras_n   ,   // 行地址使能
    output          mem_cas_n   ,   // 列地址使能
    output          mem_we_n    ,   // DDR 写使能信号
    output          mem_odt     ,   // DDR ODT
    output[14:0]    mem_a       ,   // DDR 行列地址总线   
    output[ 2:0]    mem_ba      ,   // DDR Bank 地址      
    inout [ 3:0]    mem_dqs     ,   // DDR 的数据随路时钟 
    inout [ 3:0]    mem_dqs_n   ,   // DDR 的数据随路时钟 
    inout [31:0]    mem_dq      ,   // DDR 的数据         
    output[ 3:0]    mem_dm      ,   // DDR 输入数据 Mask
    output          ddr_pll_lock    // led 指示DDR3工作
);
    wire        clk_hdmi      ;
    wire [23:0] din           ;
    wire        clk_100M      ;
    wire [1:0]  wrhdmi_frame  ;
    wire        wrhdmi_req    ;
    wire        wrhdmi_vld    ;
    wire [239:0]wrhdmi_data   ;
    wire [15:0] wrhdmi_addr   ;
    wire        wrhdmi_rden   ;
    
    wire [ 1:0]       udp_frame ;
    wire              udp_req   ;
    wire              udp_vld   ;
    wire [239:0]      udp_data  ;
    wire [15:0]       udp_addr  ;
    wire              udp_rden  ;
    
    wire [ 1:0] vgaa_frame    ;
    wire        vgaa_req      ;
    wire        vgaa_vld      ;
    wire [239:0]vgaa_data     ;
    wire [15:0] vgaa_addr     ;
    wire        vgaa_rden     ;
    
    wire [ 1:0] vgab_frame    ;
    wire        vgab_req      ;
    wire        vgab_vld      ;
    wire [239:0]vgab_data     ;
    wire [15:0] vgab_addr     ;
    wire        vgab_rden     ;
    
    wire        raddr1_req    ;
    wire [15:0] raddr1        ;
    wire        raddr1_ref    ;
    wire        rdata_vld     ;
    wire [255:0]rdata         ;
    wire [  3:0]rid           ;
    wire        rlast         ;
    wire        clk_10M       ;
    wire        cmos1_vs      ;
    wire        cmos1_de      ;
    wire [15:0] cmos1_rgb565  ;
    wire        cmos2_vs      ;
    wire        cmos2_de      ;
    wire [15:0] cmos2_rgb565  ;
    wire        cmos3_vs      ;
    wire        cmos3_de      ;
    wire [15:0] cmos3_rgb565  ;
    wire        clk_24M       ;
    
    reg rstn1, rstn2, rstn3, rstn4, rstn5, rstn6;
    always @(posedge clk_50M)begin		//
        rstn1 <= rst_n;
        rstn2 <= rst_n;
        rstn3 <= rst_n;
        rstn4 <= rst_n;
        rstn5 <= rst_n;
        rstn6 <= rst_n;
    end
    
    assign din = {r_in,g_in,b_in};
    
    zoom_hdmi zoom_hdmi(
        // .error_empty(led4),
        .rst_n        (rstn1       )   ,   // input        
        .clk_hdmi     (pixclk_in   )   ,   // input        HDMI 像素时钟
        .vga_vs       (vs_in       )   ,   // input        在图片头复位 注意 vs==1 会复位
        .din_vld      (de_in       )   ,   // input        数据有效信号
        .din          (din         )   ,   // input [23:0] 数据
        .clk_100M     (clk_100M    )   ,   // input        ddr3的工作时钟
        .wrhdmi_frame (wrhdmi_frame)   ,   // output[ 1:0] 写入ddr3的帧编号 1, 2, 3
        .wrhdmi_req   (wrhdmi_req  )   ,   // output       有 16*240bit 个数据了 申请写入ddr3
        .wrhdmi_vld   (wrhdmi_vld  )   ,   // output       数据有效信号
        .wrhdmi_data  (wrhdmi_data )   ,   // output[239:0]240bit数据
        .wrhdmi_addr  (wrhdmi_addr )   ,   // output[15:0] 需要写入的地址
        .wrhdmi_rden  (wrhdmi_rden )       // input        指示发送16个240bit数据
    );
    
    eth_udp eth_udp(
        .led4(led4),.led5(led5),.led6(led6),.led7(led7),
        //.error_empty(led7      )   ,
        .rst_n      (rstn6     )   ,
        .eth_rxc    (eth_rxc   )   , //RGMII接收数据时钟
        .eth_rx_ctl (eth_rx_ctl)   , //RGMII输入数据有效信号
        .eth_rxd    (eth_rxd   )   , //RGMII输入数据
        .eth_txc    (eth_txc   )   , //RGMII发送数据时钟    
        .eth_tx_ctl (eth_tx_ctl)   , //RGMII输出数据有效信号
        .eth_txd    (eth_txd   )   , //RGMII输出数据        
        .eth_rst_n  (eth_rst_n )   , //以太网芯片复位信号，低电平有效
        .pix_clk    (pixclk_out)   , // input      拼接后的图像 像素时钟
        .eth_tx_vs  (vs_out    )   , // input      拼接后的图像 帧头
        .eth_tx_de  (de_out    )   , // input      拼接后的图像 数据有效信号
        .eth_tx_r   (r_out     )   , // input [4:0]拼接后的图像 r
        .eth_tx_g   (g_out     )   , // input [5:0]拼接后的图像 g
        .eth_tx_b   (b_out     )   , // input [4:0]拼接后的图像 b
        .clk_100M   (clk_100M  )   ,
        .udp_frame  (udp_frame )   ,
        .udp_req    (udp_req   )   ,
        .udp_vld    (udp_vld   )   ,
        .udp_data   (udp_data  )   ,
        .udp_addr   (udp_addr  )   ,
        .udp_rden   (udp_rden  )   ,
        .eth_led    (eth_led   )
    );
    
    
    ov5640 ov5640(
        .rst_n           (rst_n         )     ,
        .clk_10M         (clk_10M       )     ,//10Mhz
        .cmos_init_done  (cmos_init_done)     ,//OV5640寄存器初始化完成
        .cmos1_scl       (cmos1_scl     )     ,//cmos1 i2c 
        .cmos1_sda       (cmos1_sda     )     ,//cmos1 i2c 
        .cmos1_vsync     (cmos1_vsync   )     ,//cmos1 vsync
        .cmos1_href      (cmos1_href    )     ,//cmos1 hsync refrence,data valid
        .cmos1_pclk      (cmos1_pclk    )     ,//cmos1 pxiel clock
        .cmos1_data      (cmos1_data    )     ,//cmos1 data
        .cmos1_reset     (cmos1_reset   )     ,//cmos1 reset
        .cmos1_pwdn      (cmos1_pwdn    )     ,//cmos1 power down
        .cmos2_scl       (cmos2_scl     )     ,//cmos2 i2c
        .cmos2_sda       (cmos2_sda     )     ,//cmos2 i2c
        .cmos2_vsync     (cmos2_vsync   )     ,//cmos2 vsync
        .cmos2_href      (cmos2_href    )     ,//cmos2 hsync refrence,data valid
        .cmos2_pclk      (cmos2_pclk    )     ,//cmos2 pxiel clock
        .cmos2_data      (cmos2_data    )     ,//cmos2 data
        .cmos2_reset     (cmos2_reset   )     ,//cmos2 reset
        .cmos2_pwdn      (cmos2_pwdn    )     ,//cmos2 power down
        .cmos1_vs        (cmos1_vs      )     ,//cmos1 
        .cmos1_de        (cmos1_de      )     ,//cmos1 
        .cmos1_rgb565    (cmos1_rgb565  )     ,//cmos1 
        .cmos2_vs        (cmos2_vs      )     ,//cmos2 
        .cmos2_de        (cmos2_de      )     ,//cmos2 
        .cmos2_rgb565    (cmos2_rgb565  )      //cmos2 
    );
    
    assign cmos1_clk24M = clk_24M;
    assign cmos2_clk24M = clk_24M;
    
    
    zoom_addr #(
        .begin_addr(16'd19_443)
    )
    zoom_vgaa_addr(
        // .error_empty(led5),
        .rst_n     (rstn3    )  ,   // input        
        .clk_zoom  (cmos1_pclk)  ,   // input        
        .vga_vs    (cmos1_vs    )  ,   // input        每过三张图片，在头复位, vga_vs==1为头
        .pout_vld  (cmos1_de    )  ,   // input        有效信号缩放后的数据
        .pout      ({cmos1_rgb565[15:11],3'b0,cmos1_rgb565[10:5],2'b0,cmos1_rgb565[4:0],3'b0})  ,   // input [23:0] 缩放后的数据
        .clk_100M  (clk_100M )  ,   // input        ddr3使用的时钟
        .frame     (vgaa_frame)  ,   // output[ 1:0] HDMI 正在写的帧 1,2,3
        .data_req  (vgaa_req  )  ,   // output       HDMI 的传输请求
        .data_vld  (vgaa_vld  )  ,   // output       HDMI 的数据有效信号
        .data_data (vgaa_data )  ,   // output[239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .data_addr (vgaa_addr )  ,   // output[15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .data_rden (vgaa_rden )      // input        一个周期 指示 HDMI 可以传输一组数据了
    );
    
    zoom_addr #(
        .begin_addr(16'd29_164)
    )
    zoom_vgab_addr(
        // .error_empty(led6),
        .rst_n     (rstn3    )  ,   // input        
        .clk_zoom  (cmos2_pclk)  ,   // input        
        .vga_vs    (cmos2_vs    )  ,   // input        每过三张图片，在头复位, vga_vs==1为头
        .pout_vld  (cmos2_de    )  ,   // input        有效信号缩放后的数据
        .pout      ({cmos2_rgb565[15:11],3'b0,cmos2_rgb565[10:5],2'b0,cmos2_rgb565[4:0],3'b0})  ,   // input [23:0] 缩放后的数据
        .clk_100M  (clk_100M )  ,   // input        ddr3使用的时钟
        .frame     (vgab_frame)  ,   // output[ 1:0] HDMI 正在写的帧 1,2,3
        .data_req  (vgab_req  )  ,   // output       HDMI 的传输请求
        .data_vld  (vgab_vld  )  ,   // output       HDMI 的数据有效信号
        .data_data (vgab_data )  ,   // output[239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .data_addr (vgab_addr )  ,   // output[15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .data_rden (vgab_rden )      // input        一个周期 指示 HDMI 可以传输一组数据了
    );
    
    ddr3_ctrl ddr3_ctrl(
        .clk_100M    (clk_100M    ) ,  // output       
        .clk_50M     (clk_50M     ) ,  // input        
        .rstn        (rstn4       ) ,  // input        
        .wdin1_req   (wrhdmi_req  ) ,  // input        HDMI 的传输请求
        .wdin1_vld   (wrhdmi_vld  ) ,  // input        HDMI 的数据有效信号
        .wdin1       (wrhdmi_data ) ,  // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .wdin1_addr  (wrhdmi_addr ) ,  // input [15:0] HDMI 数据包的地址
        .wdin1_rden  (wrhdmi_rden ) ,  // output       一个周期 指示 HDMI 可以传输一组数据了
        
        
        .wdin2_req   (vgaa_req  )  ,   // input        HDMI 的传输请求
        .wdin2_vld   (vgaa_vld  )  ,   // input        HDMI 的数据有效信号
        .wdin2       (vgaa_data )  ,   // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .wdin2_addr  (vgaa_addr )  ,   // input [15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .wdin2_rden  (vgaa_rden )  ,   // output       一个周期 指示 HDMI 可以传输一组数据了
        
        .wdin3_req   (vgab_req  )  ,   // input        HDMI 的传输请求
        .wdin3_vld   (vgab_vld  )  ,   // input        HDMI 的数据有效信号
        .wdin3       (vgab_data )  ,   // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .wdin3_addr  (vgab_addr )  ,   // input [15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .wdin3_rden  (vgab_rden )  ,   // output       一个周期 指示 HDMI 可以传输一组数据了
        
        .wdin4_req   (udp_req  )  ,   // input        HDMI 的传输请求
        .wdin4_vld   (udp_vld  )  ,   // input        HDMI 的数据有效信号
        .wdin4       (udp_data )  ,   // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .wdin4_addr  (udp_addr )  ,   // input [15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .wdin4_rden  (udp_rden )  ,   // output       一个周期 指示 HDMI 可以传输一组数据了
        
        .raddr1_req  (raddr1_req  ) ,  // input        要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
        .raddr1      (raddr1      ) ,  // input [15:0] rdata1 的地址 与 raddr1_need 对齐
        .raddr1_ref  (raddr1_ref  ) ,  // output       刷新下一个地址 
        .rdata_vld   (rdata_vld   ) ,  // output       ddr3输出的数据有效信号
        .rdata       (rdata       ) ,  // output[255:0]ddr3输出的数据
        .rid         (rid         ) ,  // output[  3:0]ddr3输出数据的 id
        .rlast       (rlast       ) ,  // output       ddr3 一次突发读的最后一个数据
        .ddr_pll_lock(ddr_pll_lock) ,  // output       ddr3的pll的锁
        .mem_rst_n   (mem_rst_n   ) ,  // output       DDR 复位
        .mem_ck      (mem_ck      ) ,  // output       DDR 输入系统时钟
        .mem_ck_n    (mem_ck_n    ) ,  // output       DDR 输入系统时钟
        .mem_cke     (mem_cke     ) ,  // output       DDR 输入系统时钟有效。
        .mem_cs_n    (mem_cs_n    ) ,  // output       DDR 的片选
        .mem_ras_n   (mem_ras_n   ) ,  // output       行地址使能
        .mem_cas_n   (mem_cas_n   ) ,  // output       列地址使能
        .mem_we_n    (mem_we_n    ) ,  // output       DDR 写使能信号
        .mem_odt     (mem_odt     ) ,  // output       DDR ODT
        .mem_a       (mem_a       ) ,  // output[14:0] DDR 行列地址总线   
        .mem_ba      (mem_ba      ) ,  // output[ 2:0] DDR Bank 地址      
        .mem_dqs     (mem_dqs     ) ,  // inout [ 3:0] DDR 的数据随路时钟 
        .mem_dqs_n   (mem_dqs_n   ) ,  // inout [ 3:0] DDR 的数据随路时钟 
        .mem_dq      (mem_dq      ) ,  // inout [31:0] DDR 的数据         
        .mem_dm      (mem_dm      )    // output[ 3:0] DDR 输入数据 Mask  
    );
    
    HDMI_out HDMI_out(
        .error_empty(led3),
        .cfg_clk      (clk_10M      ),   //10Mhz
        .clk_24M      (clk_24M      ),
        .sys_clk      (clk_50M      ),   // input        50Mhz
        .rstn_out     (rstn_out     ),   // output       
        .iic_scl      (iic_scl      ),   // output       HDMI_IN 的 IIC 配置端口
        .iic_sda      (iic_sda      ),   // inout        
        .iic_tx_scl   (iic_tx_scl   ),   // output       HDMI_OUT 的 IIC 配置端口
        .iic_tx_sda   (iic_tx_sda   ),   // inout        
        .pixclk_out   (pixclk_out   ),   // output       输出给 HDMI_OUT 的像素时钟 148.500MHz;  1920 x 1080 @ 60Hz
        .vs_out       (vs_out       ),   // output       场同步
        .hs_out       (hs_out       ),   // output       行同步
        .de_out       (de_out       ),   // output       数据有效信号
        .r_out        (r_out        ),   // output [7:0] r
        .g_out        (g_out        ),   // output [7:0] g
        .b_out        (b_out        ),   // output [7:0] b
        .led_int      (led_int      ),   // output       灯指示 HDMI 芯片初始化完成
        .rst_n        (rstn5        ),   // input        
        .clk_100M     (clk_100M     ),   // input        ddr3 工作时钟
        .wr_hdmi_frame(wrhdmi_frame ),   // input [ 1:0] HDMI 写入ddr3的帧编号 1, 2, 3
        .wr_udp_frame (udp_frame    ),   // input [ 1:0] UDP  写入ddr3的帧编号 1, 2, 3
        .wr_vgaa_frame(vgaa_frame   ),   // input [ 1:0] vga1 写入ddr3的帧编号 1, 2, 3
        .wr_vgab_frame(vgab_frame   ),   // input [ 1:0] vga2 写入ddr3的帧编号 1, 2, 3
        .rd_hdmi_req  (raddr1_req   ),   // output       要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
        .rd_hdmi_addr (raddr1       ),   // output[15:0] rdata1 的地址 与 raddr1_need 对齐
        .rd_hdmi_ref  (raddr1_ref   ),   // input        刷新下一个地址 
        .rdata_vld    (rdata_vld    ),   // input        ddr3输出的数据有效信号
        .rdata        (rdata        ),   // input[255:0] ddr3输出的数据
        .rid          (rid          ),   // input[  3:0] ddr3输出数据的 id
        .rlast        (rlast        )    // input        ddr3 一次突发读的最后一个数据
    );

endmodule
