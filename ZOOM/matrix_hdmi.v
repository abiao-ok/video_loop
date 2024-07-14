/*==============================================
Read before Write mode.jpg
当用户从 DRM 的一个端口写入数据时，
将首先读出该地址所引的原数据
并在写操作的下一个时钟周期输出到输出端口
conv_p = 0
输入图像大小固定为 1960*1080

==============================================*/
module matrix_hdmi (  // 为了时序最大化，舍弃了 matrix_busy 指示信号，务必保证，完成一张图片后才能进行第二张图片
    clk         ,   // input        
    rst_n       ,   // input         传输完一张图片，本模块最好要复位
    din_vld     ,   // input         输入像素数据 有效信号
    din         ,   // input  [23:0] 输入像素数据
    data_vld    ,   // output        矩阵数据 有效信号
    dout1_1     ,   // output [23:0] 矩阵的(1,1)位
    dout1_2     ,   // output [23:0]       (1,2)
    dout2_1     ,   // output [23:0]       (2,1)
    dout2_2     ,   // output [23:0]       (2,2)
    data_X      ,   // output        像素 x 坐标的最低位 步长为2 
    data_Y          // output        像素 y 坐标的最低位
);
    input  wire         clk         ;   // input        
    input  wire         rst_n       ;   // input        
    input  wire         din_vld     ;   // input        输入像素数据 有效信号
    input  wire[23:0]   din         ;   // input  [23:0]输入像素数据
    output reg          data_vld    ;   // output       矩阵数据 有效信号
    output reg [23:0]   dout1_1     ;   // output [23:0]矩阵的(1,1)位
    output wire[23:0]   dout1_2     ;   // output [23:0]      (1,2)
    output reg [23:0]   dout2_1     ;   // output [23:0]      (2,1)
    output reg [23:0]   dout2_2     ;   // output [23:0]      (2,2)
    output reg          data_X      ;   // output       像素 x 坐标(范围:0 ~ 1920-1       ); 
    output reg          data_Y      ;   // output       像素 y 坐标(范围:2047, 0 ~ 1080-2  );
    reg         cv_vld              ;   // 
    reg         cv_vld_d0           ;   // 
    reg  [23:0] cv_din              ;   // 
    reg  [10:0] col_cnt             ;   // 
    reg         row_cnt             ;   // 
    reg  [23:0] cv_din_d0           ;   // 
    reg         col_cnt_d0          ;   // 
    reg         row_cnt_d0          ;   // 
    wire        col_cnt_add         ;   // 
    wire        col_cnt_end         ;   // 
    always @(posedge clk or negedge rst_n)begin		// 对输入的数据 和有效信号打拍，优化时序
        if(!rst_n)begin
            cv_din <= 'd0;
            cv_vld <= 'd0;
        end
        else begin
            cv_din <= din;
            cv_vld <= din_vld;
        end
    end
    
    always @(posedge clk or negedge rst_n)begin    // 列的计数范围: 0 ~ (1280 - 1)
        if(!rst_n)begin
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
    assign col_cnt_end = col_cnt_add && (col_cnt == 11'd1920 - 1);   // 列的结尾
    
    always @(posedge clk or negedge rst_n)begin		// 步长为2
        if(!rst_n)begin
            row_cnt <= 1'b0;
        end
        else if(col_cnt_end)begin
            row_cnt <= ~row_cnt;
        end
    end
    
    matrix_ram24_zoom_hdmi matrix_ram24_zoom_hdmi (  // RAM 时序见: Read before Write mode.jpg
        .wr_en  (cv_vld ),   // input        
        .wr_data(cv_din ),   // input [23:0] 
        .addr   (col_cnt),   // input [10:0] 
        .clk    (clk    ),   // input        
        .rst    (!rst_n ),   // input        
        .rd_data(dout1_2)    // output [23:0] 配置为寄存输出
    );
    
    always @(posedge clk or negedge rst_n)begin		// 打两拍寄存，让输入对齐输出
        if(!rst_n)begin
            cv_vld_d0 <= 'd0;
            data_vld  <= 'd0;       // 矩阵数据有效信号，与矩阵第二列数据对齐
            cv_din_d0 <= 'd0;
            dout2_2   <= 'd0;
            col_cnt_d0<= 'd0;
            data_X    <= 'd0;
            row_cnt_d0<= 'd0;
            data_Y    <= 'd0;
        end
        else begin
            cv_vld_d0   <= cv_vld;
            data_vld    <= cv_vld_d0;
            cv_din_d0   <= cv_din;
            dout2_2     <= cv_din_d0;
            col_cnt_d0  <= col_cnt[0];
            data_X      <= col_cnt_d0;
            row_cnt_d0  <= row_cnt;
            data_Y      <= row_cnt_d0;
        end
    end
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dout2_1 <= 'd0;
            dout1_1 <= 'd0;
        end
        else if(data_vld)begin  // 只在矩阵数据有效，把第二列数据放入第一列，获得2*2矩阵
            dout2_1 <= dout2_2;
            dout1_1 <= dout1_2;
        end
    end
    
endmodule
