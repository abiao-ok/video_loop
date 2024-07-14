/*==============================================
添加数据源时，把注释部分取消，修改相关参数，同时写下一个
一个数据源应该包括以下信息: 
X            : 数据源 id 编号 1 ~ 15
wdin1_req : 数据源 fifo 存了有 128 个数据后拉高 要求打一拍
wdinX_rden  : 指示 fifo 可以发送一个包的个数据了
wdin1_vld   :数据有效信号
wdinX       : 数据 fifo 寄存暑输出
wdinX_addr  : 数据的地址, 需要划分在ddr3中的存储地址, 地址 0 ~ 127 属于被舍弃的地址; 错误检查地址: 0
数据源的 fifo 需要设置输出寄存

如果传输少了拍数，如何判错？

==============================================*/
module wr_side (
    clk_100M       ,    // input        
    rstn           ,    // input        
    wdin1_req      ,    // input        HDMI 的传输请求
    wdin1_vld      ,    // input        HDMI 的数据有效信号
    wdin1          ,    // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
    wdin1_addr     ,    // input [15:0] HDMI 数据包的地址
    wdin1_rden     ,    // output       一个周期 指示 HDMI 可以传输一组数据了
    
    wdin2_req      ,  // input        
    wdin2_vld      ,  // input        
    wdin2          ,  // input [239:0]
    wdin2_addr     ,  // input [15:0] 
    wdin2_rden     ,  // output       
    
    wdin3_req      ,  // input        
    wdin3_vld      ,  // input        
    wdin3          ,  // input [239:0]
    wdin3_addr     ,  // input [15:0] 
    wdin3_rden     ,  // output       
    
    wdin4_req      ,  // input        
    wdin4_vld      ,  // input        
    wdin4          ,  // input [239:0]
    wdin4_addr     ,  // input [15:0] 
    wdin4_rden     ,  // output       
    
    awaddr_empty   ,    // output        
    awaddr_ref     ,    // input        
    axi_awaddr     ,    // output[27:0] 
    axi_awlen      ,    // output[ 3:0] 
    axi_wready     ,    // input        
    axi_wdata           // output[255:0]
);
    input           clk_100M    ;
    input           rstn        ;
    input           wdin1_req   ;
    input           wdin1_vld   ;
    input [239:0]   wdin1       ;
    input [15:0]    wdin1_addr  ;
    output reg      wdin1_rden  ;
    
    input           wdin2_req   ;   // input        
    input           wdin2_vld   ;   // input        
    input [239:0]   wdin2       ;   // input [255:0]
    input [15:0]    wdin2_addr  ;   // input [15:0] 
    output reg      wdin2_rden  ;   // output       
    
    input           wdin3_req   ;   // input        
    input           wdin3_vld   ;   // input        
    input [239:0]   wdin3       ;   // input [255:0]
    input [15:0]    wdin3_addr  ;   // input [15:0] 
    output reg      wdin3_rden  ;   // output       
    
    input           wdin4_req   ;   // input        
    input           wdin4_vld   ;   // input        
    input [239:0]   wdin4       ;   // input [255:0]
    input [15:0]    wdin4_addr  ;   // input [15:0] 
    output reg      wdin4_rden  ;   // output     
    
    output          awaddr_empty;
    input           awaddr_ref  ;   // 仅仅监测上升沿
    output [27:0]   axi_awaddr  ;
    output [ 3:0]   axi_awlen   ;
    input           axi_wready  ;
    output [255:0]  axi_wdata   ;
    wire        rst_n           ;
    reg         wdin1_ask       ;
    reg         wdata1_vld      ;
    reg [239:0] wdata1          ;
    reg [15:0]  wdata1_addr     ;
    
    reg        wdin2_ask        ;
    reg        wdata2_vld       ;
    reg [239:0]wdata2           ;
    reg [15:0] wdata2_addr      ;
    
    reg        wdin3_ask        ;
    reg        wdata3_vld       ;
    reg [239:0]wdata3           ;
    reg [15:0] wdata3_addr      ;
    
    reg        wdin4_ask        ;
    reg        wdata4_vld       ;
    reg [239:0]wdata4           ;
    reg [15:0] wdata4_addr      ;
    
    reg  [10:0] state_now/* synthesis syn_maxfan = 200 */;
    reg  [10:0] state_next/* synthesis syn_maxfan = 30 */;
    parameter   IDLE     = 10'b0000000001;
    parameter   ID1      = 10'b0000000010;
    parameter   ID2      = 10'b0000000100;
    parameter   ID3      = 10'b0000001000;
    parameter   ID4      = 10'b0000010000;
    parameter   ID5      = 10'b0000100000;
    parameter   ID6      = 10'b0001000000;
    parameter   ID7      = 10'b0010000000;
    parameter   ID8      = 10'b0100000000;
    parameter   ID9      = 10'b1000000000;
    reg [4:0]wrcnt          ;
    wire wrcnt_end_d0       ;
    reg wrcnt_end           ;
    reg [  4:0]wrcnt_max    ;
    reg [ 31:0]waddr_d0     ;
    reg        wdata_vld_d0 ;
    reg [255:0]wdata_d0     ;
    reg [ 31:0]waddr/* synthesis syn_preserve = 1 */;
    reg        wdata_vld    ;
    reg [255:0]wdata/* synthesis syn_preserve = 1 */;
    reg waddr_vld           ;
    reg waddr_14            ;
    wire almost_full        ;
    wire [31:0]rd_data      ;
    wire rd_en              ;
    wire rd_empty/* synthesis syn_maxfan = 20 */;
    reg [2:0]now_state;
    reg [2:0]next_state;
    
    // 把复位信号放到区域时钟，提高扇出能力
    // 需要复位管理模块控制
    /* GTP_CLKBUFR rstn_BUFR(
        .CLKOUT (rst_n),
        .CLKIN (rstn )
    ); */
    assign rst_n = rstn;
    
    always @(posedge clk_100M or negedge rst_n)begin // 对输入数据打拍优化时序
        if(!rst_n)begin
            wdin1_ask   <= 'd0      ;
            wdata1_vld  <= 'd0      ;
            wdata1      <= 'd0      ;
            wdata1_addr <= 'd0      ;
            wdin2_ask   <= 'd0      ;
            wdata2_vld  <= 'd0      ;
            wdata2      <= 'd0      ;
            wdata2_addr <= 'd0      ;
            wdin3_ask   <= 'd0      ;
            wdata3_vld  <= 'd0      ;
            wdata3      <= 'd0      ;
            wdata3_addr <= 'd0      ;
            wdin4_ask   <= 'd0      ;
            wdata4_vld  <= 'd0      ;
            wdata4      <= 'd0      ;
            wdata4_addr <= 'd0      ;
        end
        else begin
            wdin1_ask   <= wdin1_req ;
            wdata1_vld  <= wdin1_vld ;
            wdata1      <= wdin1     ;
            wdata1_addr <= wdin1_addr;
            wdin2_ask   <= wdin2_req ;
            wdata2_vld  <= wdin2_vld ;
            wdata2      <= wdin2     ;
            wdata2_addr <= wdin2_addr;
            wdin3_ask   <= wdin3_req ;
            wdata3_vld  <= wdin3_vld ;
            wdata3      <= wdin3     ;
            wdata3_addr <= wdin3_addr;
            wdin4_ask   <= wdin4_req ;
            wdata4_vld  <= wdin4_vld ;
            wdata4      <= wdin4     ;
            wdata4_addr <= wdin4_addr;
        end
    end
    
    always@(posedge clk_100M or negedge rst_n)begin  // 当前状态state_now切换
        if(!rst_n)begin
            state_now <= IDLE;
        end
        else begin
            state_now <= state_next;
        end
    end
    
    always@(*)begin      // 下一阶段state_next切换
        case(state_now)
            IDLE:begin
                if(waddr_14) // 写地址fifo里有14个地址 等一下再发数据
                    state_next = state_now;
                else if(wdin1_ask)
                    state_next = ID1;
                else if(wdin2_ask)
                    state_next = ID2;
                else if(wdin3_ask)
                    state_next = ID3;
                else if(wdin4_ask)
                    state_next = ID4;
                else
                    state_next = state_now;
            end
            ID1:begin                       // 每多一个数据源 重复该单元即可
                if(wrcnt_end)
                    state_next = IDLE;
                else
                    state_next = state_now;
            end
            ID2:begin                       // 每多一个数据源 重复该单元即可
                if(wrcnt_end)
                    state_next = IDLE;
                else
                    state_next = state_now;
            end
            ID3:begin                       // 每多一个数据源 重复该单元即可
                if(wrcnt_end)
                    state_next = IDLE;
                else
                    state_next = state_now;
            end
            ID4:begin                       // 每多一个数据源 重复该单元即可
                if(wrcnt_end)
                    state_next = IDLE;
                else
                    state_next = state_now;
            end
            default:state_next = IDLE;
        endcase
    end
    
    // 在数据有效时加计数器
    always @(posedge clk_100M)begin
        if(state_now != IDLE)begin
            wrcnt <= wrcnt + 1'b1;
        end
        else begin
            wrcnt <= 5'd0;
        end
    end
    
    // 留出足够的时间让数据通路选通，以及照顾数据的路径延迟
    // wrcnt 范围： 0 ~ wrcnt_max+1
    assign wrcnt_end_d0 = (wrcnt == wrcnt_max);     
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            wrcnt_end <= 1'd0;
        end
        else begin
            wrcnt_end <= wrcnt_end_d0;
        end
    end
    // 不考虑路径延迟，wrcnt == 5 时数据有效
    // wrcnt 值
    // 0:(wrcnt == 5'b0)&&(state_now == ID1)
    // 1:(wdin1_rden == 1) 用一个周期指示上游，发一组数据
    // 2:上游 fifo 读使能拉高
    // 3:数据寄存输出的 等一个周期
    // 4:wdin1_vld 拉高
    // 5:wdata1_vld 拉高
    always @(posedge clk_100M)begin
        if(wrcnt == 5'b0)begin
            wdin1_rden <= (state_now == ID1);
            wdin2_rden <= (state_now == ID2);
            wdin3_rden <= (state_now == ID3);
            wdin4_rden <= (state_now == ID4);
        end
        else begin
            wdin1_rden <= 1'b0;
            wdin2_rden <= 1'b0;
            wdin3_rden <= 1'b0;
            wdin4_rden <= 1'b0;
        end
    end
    
    // 数据通道的选通
    always @(*)begin
        case(state_now)
            ID1:begin   // 数据源 1
                wrcnt_max    = 5'd21;   // 根据突发长度决定 状态持续时长 len+10
                waddr_d0     = {4'd15,5'h0,wdata1_addr,7'h0};  // 高4位为突发长度 低28位为地址数据
                wdata_vld_d0 = wdata1_vld;
                wdata_d0     = {16'h0,wdata1};
            end
            ID2:begin   // 数据源 2
                wrcnt_max    = 5'd21;   // 根据突发长度决定 状态持续时长 len+10
                waddr_d0     = {4'd15,5'h0,wdata2_addr,7'h0};  // 高4位为突发长度 低28位为地址数据
                wdata_vld_d0 = wdata2_vld;
                wdata_d0     = {16'h0,wdata2};
            end
            ID3:begin   // 数据源 3
                wrcnt_max    = 5'd21;   // 根据突发长度决定 状态持续时长 len+10
                waddr_d0     = {4'd15,5'h0,wdata3_addr,7'h0};  // 高4位为突发长度 低28位为地址数据
                wdata_vld_d0 = wdata3_vld;
                wdata_d0     = {16'h0,wdata3};
            end
            ID4:begin   // 数据源 4
                wrcnt_max    = 5'd21;   // 根据突发长度决定 状态持续时长 len+10
                waddr_d0     = {4'd15,5'h0,wdata4_addr,7'h0};  // 高4位为突发长度 低28位为地址数据
                wdata_vld_d0 = wdata4_vld;
                wdata_d0     = {16'h0,wdata4};
            end
            default:begin
                wrcnt_max    = 5'd11;   // 配置1 + 10
                waddr_d0     = {4'd1,28'd0};
                wdata_vld_d0 = 1'd0;
                wdata_d0     = 256'd0;
            end
        endcase
    end
    
    // 多选一寄存器后接寄存器 优化时序
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            waddr     <= 32'd0  ;
            wdata_vld <= 1'd0   ;
            wdata     <= 256'd0 ;
        end
        else begin
            waddr     <= waddr_d0    ;
            wdata_vld <= wdata_vld_d0;
            wdata     <= wdata_d0    ;
        end
    end
    
    // 数据输入是连续传递的
    // 检测到数据有效信号上升沿，有效一次地址
    always @(posedge clk_100M)begin
        if(wrcnt == 5'd10)begin
            waddr_vld <= 1'b1;
        end
        else
            waddr_vld <= 1'b0;
    end
    
    // 写地址fifo有14个地址就暂停一下，否则写数据FIFO要满
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            waddr_14 <= 1'b0;
        end
        else begin  // 打一拍优化时序
            waddr_14 <= almost_full;
        end
    end
    
    reg awaddr_ref_d0;
    wire awaddr_ref_pose;
    always @(posedge clk_100M or negedge rst_n)begin		// 上升沿检查
        if(!rst_n)begin
            awaddr_ref_d0 <= 1'b0;
        end
        else begin
            awaddr_ref_d0 <= awaddr_ref;
        end
    end
    assign awaddr_ref_pose = (awaddr_ref_d0 == 0) && (awaddr_ref == 1);
    
    // 配置寄存输出
    DFIFO32 fifo_awaddr(
        .clk            (clk_100M   )   ,   // input        write clock
        .rst            (!rst_n     )   ,   // input        write reset
        .wr_en          (waddr_vld  )   ,   // input        write enable;
        .wr_data        (waddr      )   ,   // input [31:0] write data
        .full           (     		)   ,   // output       write full flag;
        .almost_full    (almost_full)   ,   // output
        .rd_en          (awaddr_ref_pose)   ,   // input        read enable
        .rd_data        (rd_data    )   ,   // output[31:0] read data
        .empty          (awaddr_empty)  ,   // output       read empty
        .almost_empty   (           )       // output       write almost empty 
    );
    assign axi_awaddr = rd_data[27:0]   ;
    assign axi_awlen  = rd_data[31:28]  ;
    
    // 只能放16组 16*256
    // 不配置寄存输出
    wfifo wfifo_d0(
        .clk            (clk_100M   )   ,   // input        write clock
        .rst            (!rst_n     )   ,   // input        write reset
        .wr_en          (wdata_vld  )   ,   // input        write enable;
        .wr_data        (wdata      )   ,   // input [255:0]write data
        .wr_full        (           )   ,   // output       write full flag;
        .almost_full    (           )   ,   // output       
        .rd_en          (rd_en      )   ,   // input        read enable
        .rd_data        (axi_wdata  )   ,   // output[255:0]read data
        .rd_empty       (rd_empty   )   ,   // output       read empty   写数据fifo与写地址fifo一一对应
        .almost_empty   (           )       // output       write almost empty 
    );
    // 如何限制发包?
    // 用状态机预读数据
    always@(posedge clk_100M or negedge rst_n)begin  // 当前状态state_now切换
        if(!rst_n)begin
            now_state <= 3'b001;
        end
        else begin
            now_state <= next_state;
        end
    end
    
    always@(*)begin
        case(now_state)
            3'b001:begin
                if(!rd_empty)   // 有数据就立刻预读
                    next_state = 3'b010;
                else
                    next_state = now_state;
            end
            3'b010:begin     // 预读数据
                next_state = 3'b100;
            end
            3'b100:begin // 因为预读了一个数据，要在空状态下读一次数据才回到初始状态
                if(rd_empty && axi_wready)
                    next_state = 3'b001;
                else
                    next_state = now_state;
            end
            default:next_state = 3'b100;
        endcase
    end
    
    
    // 有问题 需要再看看之前的设计
    assign rd_en = (now_state == 3'b010) || (!rd_empty && axi_wready);
    
endmodule
