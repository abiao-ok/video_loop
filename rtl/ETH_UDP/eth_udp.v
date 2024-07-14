/*==============================================


==============================================*/
module eth_udp (
    output led4,output led5,output led6,output reg led7,
    output              error_empty  ,
    input               rst_n        ,
    //PL以太网RGMII接口              
    input               eth_rxc      , //RGMII接收数据时钟
    input               eth_rx_ctl   , //RGMII输入数据有效信号
    input       [3:0]   eth_rxd      , //RGMII输入数据
    output              eth_txc      , //RGMII发送数据时钟    
    output              eth_tx_ctl   , //RGMII输出数据有效信号
    output      [3:0]   eth_txd      , //RGMII输出数据          
    output              eth_rst_n    , //以太网芯片复位信号，低电平有效   
    //用户接口
    input               pix_clk      ,   // 拼接后的图像 像素时钟
    input               eth_tx_vs    ,   // 拼接后的图像 帧头
    input               eth_tx_de    ,   // 拼接后的图像 数据有效信号
    input [4:0]         eth_tx_r     ,   // 拼接后的图像 r
    input [5:0]         eth_tx_g     ,   // 拼接后的图像 g
    input [4:0]         eth_tx_b     ,   // 拼接后的图像 b
    
    input               clk_100M   ,
    output[ 1:0]        udp_frame  ,
    output              udp_req    ,
    output              udp_vld    ,
    output[239:0]       udp_data   ,
    output[15:0]        udp_addr   ,
    input               udp_rden   ,
    output reg          eth_led
);
    parameter   begin_addr = 16'd9_722;
    //parameter define
    //开发板MAC地址 00-11-22-33-44-55
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
    //开发板IP地址 192.168.1.10
    parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};  
    //目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter  DES_MAC   = 48'h84_A9_3E_19_30_8A;    
    //目的IP地址 192.168.1.102     
    parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};  
      
    
    wire          gmii_rx_clk   ; //GMII接收时钟
    wire          gmii_rx_dv    ; //GMII接收数据有效信号
    wire  [7:0]   gmii_rxd      ; //GMII接收数据
    wire          gmii_tx_clk   ; //GMII发送时钟
    wire          gmii_tx_en    ; //GMII发送数据使能信号
    wire  [7:0]   gmii_txd      ; //GMII发送数据   
    
    wire          udp_gmii_tx_en; //UDP GMII输出数据有效信号 
    wire  [7:0]   udp_gmii_txd  ; //UDP GMII输出数据
    wire          rec_pkt_done  ; //UDP单包数据接收完成信号
    wire          rec_en        ; //UDP接收的数据使能信号
    wire  [23:0]  rec_data      ; //UDP接收的数据
    wire  [15:0]  rec_byte_num  ; //UDP接收的有效字节数 单位:byte 
    wire  [15:0]  tx_byte_num   ; //UDP发送的有效字节数 单位:byte 
    wire          udp_tx_done   ; //UDP发送完成信号
    wire          tx_req        ; //UDP读数据请求信号
    wire  [31:0]  tx_data       ; //UDP待发送数据
    wire          tx_start_en   ; //UDP发送开始使能信号
    
    assign tx_start_en = almost_empty;// 每当快存满一行数据就开始发送
    assign tx_byte_num = 16'd960;// 每次发送一行数据 1920个rgb565
    assign des_mac = DES_MAC;   // 没有arp更新地址，直接用固定好的地址
    assign des_ip = DES_IP;     // 没有arp更新地址，直接用固定好的地址
    assign eth_rst_n = rst_n;   //以太网芯片复位信号，低电平有效
    
    //GMII接口转RGMII接口
    gmii_to_rgmii u_gmii_to_rgmii(
        .gmii_rx_clk   (gmii_rx_clk ),
        .gmii_rx_dv    (gmii_rx_dv  ),
        .gmii_rxd      (gmii_rxd    ),
        .gmii_tx_clk   (gmii_tx_clk ),
        .gmii_tx_en    (gmii_tx_en  ),
        .gmii_txd      (gmii_txd    ),
        
        .rgmii_rxc     (eth_rxc     ),
        .rgmii_rx_ctl  (eth_rx_ctl  ),
        .rgmii_rxd     (eth_rxd     ),
        .rgmii_txc     (eth_txc     ),
        .rgmii_tx_ctl  (eth_tx_ctl  ),
        .rgmii_txd     (eth_txd     )
    );
    
    //UDP通信
    udp                                             
       #(
        .BOARD_MAC     (BOARD_MAC),      //参数例化
        .BOARD_IP      (BOARD_IP ),
        .DES_MAC       (DES_MAC  ),
        .DES_IP        (DES_IP   )
        )
       u_udp(
        
        .rst_n         (rst_n       ),  
        
        .gmii_rx_clk   (gmii_rx_clk ),           
        .gmii_rx_dv    (gmii_rx_dv  ),         
        .gmii_rxd      (gmii_rxd    ),                   
        .gmii_tx_clk   (gmii_tx_clk ), 
        .gmii_tx_en    (udp_gmii_tx_en),         
        .gmii_txd      (udp_gmii_txd),  

        .rec_pkt_done  (rec_pkt_done),    
        .rec_en        (rec_en      ),     
        .rec_data      (rec_data    ),
        .vs            (din_vs      ),
        .rec_byte_num  (rec_byte_num),      
        .tx_start_en   (tx_start_en ),
        .tx_data       (tx_data     ),
        .tx_byte_num   (tx_byte_num ),  
        .des_mac       (des_mac     ),
        .des_ip        (des_ip      ),    
        .tx_done       (udp_tx_done ),        
        .tx_req        (tx_req      )           
    ); 
    
    reg eth_tx_vs_D0;
    always @(posedge pix_clk or negedge rst_n)begin		//
        if(!rst_n)begin
            eth_tx_vs_D0 <= 1'b0;
        end
        else begin
            eth_tx_vs_D0 <= eth_tx_vs;
        end
    end
    
    reg vs_cnt;
    always @(posedge pix_clk or negedge rst_n)begin		// 根据帧头出现的次数，降帧 60Hz -> 30Hz
        if(!rst_n)begin
            vs_cnt <= 1'b0;
        end
        else if((~eth_tx_vs_D0) && eth_tx_vs)begin  // 监测场同步的上升沿，作为帧头
            vs_cnt <= ~vs_cnt;                      // vs_cnt==1 才是有效帧
        end
    end
    
    reg tx_cnt;
    always @(posedge pix_clk or negedge rst_n)begin		//
        if(!rst_n)begin
            tx_cnt <= 1'd0;
        end
        else if(eth_tx_vs)begin
            tx_cnt <= 1'd0;
        end
        else if(vs_cnt && eth_tx_de)begin   // 读取有效帧（vs_cnt==1）的数据
            tx_cnt <= ~tx_cnt;
        end
    end
    
    reg [31:0]wr_data;
    always @(posedge pix_clk or negedge rst_n)begin		//
        if(!rst_n)begin
            wr_data <= 32'd0;
        end
        else if(eth_tx_de)begin
            wr_data <= {wr_data[15:0],eth_tx_r,eth_tx_g,eth_tx_b};
        end
    end
    
    sync_fifo_2048x32b sync_fifo_2048x32b ( // 发送1920*1080数据
        .wr_clk     (pix_clk    ),      // input
        .wr_rst     ((~rst_n)||eth_tx_vs),      // input
        .wr_en      (tx_cnt && eth_tx_de &&(!wr_full)),      // input
        .wr_data    ({wr_data[15:0],eth_tx_r,eth_tx_g,eth_tx_b}),      // input [31:0]
        .wr_full    (wr_full),      // output
        .almost_full(),      // output
        .rd_clk     (gmii_tx_clk),      // input
        .rd_rst     (~rst_n     ),      // input
        .rd_en      (tx_req     ),      // input
        .rd_data    (tx_data    ),      // output [31:0]
        .rd_empty   (           ),      // output
        .almost_empty(almost_empty)     // output
    );
    
    assign led4 = almost_empty;
    assign led5 = wr_full;
    assign led6 = tx_req;
    
    always @(posedge gmii_tx_clk or negedge rst_n)begin		//
        if(!rst_n)begin
            led7 = 1'b0;
        end
        else if(udp_tx_done)begin
            led7 = ~led7;
        end
    end
    
    always @(posedge gmii_rx_clk or negedge rst_n)begin		//
        if(!rst_n)begin
            eth_led <= 1'b0;
        end
        else if(din_vs)begin
            eth_led <= ~eth_led;
        end
    end
    
    
    reg  [10:0] col		;	// 
    wire 		col_add	;
    wire 		col_end	;
    always @(posedge gmii_rx_clk or negedge rst_n)begin	// 
        if(!rst_n)begin
            col <= 'd0;
        end
        else if(din_vs)
            col <= 'd0;
        else if(col_add)begin
            if(col_end)begin
                col <= 'd0;
            end
            else begin
                col <= col + 1'b1;
            end
        end
    end
    assign col_add = rec_en;
    assign col_end = col_add && (col == 11'd1280 - 1'b1);
    
    reg  [10:0] row		;	// 
    wire 		row_add	;
    wire 		row_end	;
    always @(posedge gmii_rx_clk or negedge rst_n)begin	// 
        if(!rst_n)begin
            row <= 'd0;
        end
        else if(din_vs)
            row <= 'd0;
        else if(row_add)begin
            if(row_end)begin
                row <= 'd0;
            end
            else begin
                row <= row + 1'b1;
            end
        end
    end
    assign row_add = col_end;
    assign row_end = row_add && (row == 11'd960 - 1'b1);
    
    reg rec_data_en;
    always @(posedge gmii_rx_clk or negedge rst_n)begin		//
        if(!rst_n)begin
            rec_data_en <= 1'b0;
        end
        else if((col>=11'd160) && (col<11'd1120) && (row>=11'd210) && (row<11'd750))begin
            rec_data_en <= rec_en;
        end
        else begin
            rec_data_en <= 1'b0;
        end
    end
    
    reg [23:0] u_rec_data;
    always @(posedge gmii_rx_clk or negedge rst_n)begin		//
        if(!rst_n)begin
            u_rec_data <= 24'd0;
        end
        else begin
            // u_rec_data <= {rec_data[7:0],rec_data[15:8],rec_data[23:16]};
            u_rec_data <= {rec_data[15:11],3'b0,rec_data[10:5],2'b0,rec_data[4:0],3'b0};
        end
    end
    
    
    
    zoom_addr #(
        .begin_addr(begin_addr)
    )
    zoom_vga_addr(
        .error_empty(error_empty),
        .rst_n     (rst_n    )  ,   // input        
        .clk_zoom  (gmii_rx_clk)  ,   // input        
        .vga_vs    (din_vs   )  ,   // input        每过三张图片，在头复位, vga_vs==1为头
        .pout_vld  (rec_data_en)  ,   // input        有效信号缩放后的数据
        .pout      (u_rec_data)  ,   // input [23:0] 缩放后的数据
        .clk_100M  (clk_100M )  ,   // input        ddr3使用的时钟
        .frame     (udp_frame)  ,   // output[ 1:0] udp 正在写的帧 1,2,3
        .data_req  (udp_req  )  ,   // output       udp 的传输请求
        .data_vld  (udp_vld  )  ,   // output       udp 的数据有效信号
        .data_data (udp_data )  ,   // output[239:0]udp 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .data_addr (udp_addr )  ,   // output[15:0] udp 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .data_rden (udp_rden )      // input        一个周期 指示 HDMI 可以传输一组数据了
    );
    
    
    /* zoom_udp zoom_udp(
        .error_empty (error_empty   ),
        .rst_n       (rst_n         ),   // input        
        .clk_udp     (gmii_rx_clk   ),   // input        摄像头像素时钟
        .din_vs      (din_vs        ),   // input        在图片头复位 注意 vs==1 会复位
        .din_vld     (rec_en        ),   // input        输入像素数据 有效信号
        .din         (rec_data      ),   // input [15:0] 输入像素数据
        .clk_100M    (clk_100M      ),   // input        ddr3使用的时钟
        .udp_frame   (udp_frame     ),   // output[ 1:0] HDMI 正在写的帧 1,2,3
        .udp_req     (udp_req       ),   // output       HDMI 的传输请求
        .udp_vld     (udp_vld       ),   // output       HDMI 的数据有效信号
        .udp_data    (udp_data      ),   // output[239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .udp_addr    (udp_addr      ),   // output[15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .udp_rden    (udp_rden      )    // input        一个周期 指示 HDMI 可以传输一组数据了
    ); */
    
endmodule
