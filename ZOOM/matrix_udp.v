/*==============================================
Read before Write mode.jpg
当用户从 DRM 的一个端口写入数据时，
将首先读出该地址所引的原数据
并在写操作的下一个时钟周期输出到输出端口
conv_p = 0
输入图像大小固定为 1280*720
Fmax = 259Mhz
（还有一个优化版Fmax = 379Mhz）
==============================================*/
module matrix_udp (  // 为了时序最大化，舍弃了 matrix_busy 指示信号，务必保证，完成一张图片后才能进行第二张图片
    clk         ,   // input        
    rst_n       ,   // input         传输完一张图片，本模块最好要复位
    vga_vs      ,   // input
    din_vld     ,   // input         输入像素数据 有效信号
    din         ,   // input  [15:0] 输入像素数据
    data_vld    ,   // output        矩阵数据 有效信号
    dout1_1     ,   // output [15:0] 矩阵的(1,1)位
    dout1_2     ,   // output [15:0]       (1,2)
    dout2_1     ,   // output [15:0]       (2,1)
    dout2_2     ,   // output [15:0]       (2,2)
    hs_end          // output 
);
    input  wire         clk         ;   // input        
    input  wire         rst_n       ;   // input        
    input               vga_vs      ;
    input  wire         din_vld     ;   // input        输入像素数据 有效信号
    input  wire[15:0]   din         ;   // input  [15:0]输入像素数据
    output reg          data_vld    ;   // output       矩阵数据 有效信号
    output reg [15:0]   dout1_1     ;   // output [15:0]矩阵的(1,1)位
    output wire[15:0]   dout1_2     ;   // output [15:0]      (1,2)
    output reg [15:0]   dout2_1     ;   // output [15:0]      (2,1)
    output reg [15:0]   dout2_2     ;   // output [15:0]      (2,2)
    output reg          hs_end      ;   // output [ 1:0]像素 x 坐标(范围:0 ~ 1280-1       ); 插值比对有效范围 0 ~ (1280 - 2)
    reg         cv_vld              ;   // 
    reg         cv_vld_d0           ;   // 
    reg  [15:0] cv_din              ;   // 
    reg  [10:0] col_cnt             ;   // 
    reg  [ 1:0] row_cnt             ;   // 
    reg  [15:0] cv_din_d0           ;   // 
    reg         col_cnt_d0          ;   // 
    wire        col_cnt_add         ;   // 
    wire        col_cnt_end         ;   // 
    wire        row_cnt_add         ;   // 
    wire        row_cnt_end         ;   // 
    reg         cv_vld_d1           ;
    reg [ 1:0]  col_cnt_d1          ;
    reg [ 1:0]  row_cnt_d1          ;
    
    wire rstn;
    assign rstn = rst_n && (~vga_vs);
    
    always @(posedge clk or negedge rstn)begin		// 对输入的数据 和有效信号打拍，优化时序
        if(!rstn)begin
            cv_din <= 'd0;
            cv_vld <= 'd0;
        end
        else begin
            cv_din <= din;
            cv_vld <= din_vld;
        end
    end
    
    always @(posedge clk or negedge rstn)begin    // 列的计数范围: 0 ~ (1280 - 1)
        if(!rstn)begin
            col_cnt <= 'd0;
        end
        else if(col_cnt_add)begin
            if(col_cnt_end)begin
                col_cnt <= 'd0;
            end
            else begin
                col_cnt <= col_cnt + 1'b1;
            end
        end
    end
    assign col_cnt_add = cv_vld;            //  在 cv_vld == 1 才计数
    assign col_cnt_end = col_cnt_add && (col_cnt == 11'd1280 - 1);   // 列的结尾
    
    matrix_ram16 matrix_ram16_d0 (  // RAM 时序见: Read before Write mode.jpg
        .wr_en  (cv_vld ),   // input        
        .wr_data(cv_din ),   // input [15:0] 
        .addr   (col_cnt),   // input [10:0] 
        .clk    (clk    ),   // input        
        .rst    (!rstn ),   // input        
        .rd_data(dout1_2)    // output [15:0] 配置为寄存输出
    );
    
    always @(posedge clk or negedge rstn)begin		// 打两拍寄存，让输入对齐输出
        if(!rstn)begin
            cv_vld_d0 <= 'd0;
            data_vld  <= 'd0;       // 矩阵数据有效信号，与矩阵第二列数据对齐
            cv_din_d0 <= 'd0;
            dout2_2   <= 'd0;
            col_cnt_d0<= 'd0;
            hs_end    <= 'd0;
            data_vld  <= 'd0;
        end
        else begin
            cv_vld_d0 <= cv_vld;
            data_vld <= cv_vld_d0;
            cv_din_d0 <= cv_din;
            dout2_2   <= cv_din_d0;
            col_cnt_d0<= col_cnt_end;
            hs_end    <= col_cnt_d0;
        end
    end
    
    always @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            dout2_1 <= 'd0;
            dout1_1 <= 'd0;
        end
        else if(data_vld)begin  // 只在矩阵数据有效，把第二列数据放入第一列，获得2*2矩阵
            dout2_1 <= dout2_2;
            dout1_1 <= dout1_2;
        end
    end
    
endmodule
