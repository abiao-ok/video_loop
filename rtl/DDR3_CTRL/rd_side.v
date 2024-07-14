/*==============================================
添加数据源时，把注释部分取消，修改相关参数，同时写下一个
一个数据源应该包括以下信息: 
X            : 数据源 id 编号 1 ~ 15
raddr1_need  : 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
raddrX       : 数据的地址, 需要注意在ddr3中的存储地址, 地址 0 ~ 127 属于被舍弃的地址; 错误检查地址: 0
raddrX_ref   : 刷新下一个地址
==============================================*/
module rd_side (
    rstn            ,   // input
    clk_100M        ,   // input
    raddr1_req      ,   // input        要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
    raddr1          ,   // input [15:0] rdata1 的地址 与 raddr1_need 对齐
    raddr1_ref      ,   // output       刷新下一个地址 
    araddr_ref      ,   // input        刷放读地址的 fifo
    araddr_empty    ,   // output       放读地址的 fifo 空了
    axi_araddr      ,   // output[27:0] ddr3 读地址     already output register
    axi_aruser_id   ,   // output[ 3:0] ddr3 读地址id号
    axi_arlen           // output[ 3:0] ddr3 读突发长度
);
    input           rstn         ;
    input           clk_100M     ;
    input           raddr1_req   ;
    input [15:0]    raddr1       ;
    output          raddr1_ref   ;
    input           araddr_ref   ;  // 刷放写地址的 fifo 开启输出寄存
    output          araddr_empty ;  // 放写地址的 fifo 空了
    output[27:0]    axi_araddr   ;  // ddr3 读地址     already output register
    output[ 3:0]    axi_aruser_id;  // ddr3 读地址id号 
    output[ 3:0]    axi_arlen    ;  // ddr3 读突发长度
    wire            rst_n       ;
    reg [15:0]      raddr1_d0   ;
    reg             raddr1_ack  ;
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
    reg         rdcnt_end   ;
    reg         addr_ref    ;
    reg         raddr_vld   ;
    reg         raddr_14    ;
    reg  [ 3:0] rdcnt       ;
    reg  [31:0] raddr_d0    ;
    reg  [31:0] raddr/* synthesis syn_preserve = 1 */;
    wire [31:0] rd_data     ;
    wire        rdcnt_end_d0;
    wire        addr_ref_d0 ;
    wire        almost_full ;
    reg araddr_ref_d0;
    wire araddr_ref_pose;
    // 把复位信号放到区域时钟，提高扇出能力
    // 需要复位管理模块控制
    /* GTP_CLKBUFR rstn_rdBUFR(
        .CLKOUT (rst_n),
        .CLKIN (rstn )
    ); */
    assign rst_n = rstn;
    
    always @(posedge clk_100M or negedge rst_n)begin		//
        if(!rst_n)begin
            raddr1_ack <= 1'd0;
            raddr1_d0 <= 16'd0;
        end
        else begin
            raddr1_ack <= raddr1_req;
            raddr1_d0 <= raddr1;
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
    
    always@(*)begin             // 下一阶段state_next切换
        case(state_now)
            IDLE:begin
                if(raddr_14)
                    state_next = state_now;
                else if(raddr1_ack)
                    state_next = ID1;
                else
                    state_next = state_now;
            end
            ID1:begin                       // 每多一个数据源 重复该单元即可
                if(rdcnt_end)
                    state_next = IDLE;
                else
                    state_next = state_now;
            end
            default:state_next = IDLE;
        endcase
    end
    
    always @(posedge clk_100M)begin	// 在非 IDLE, Priority 状态计数 16 个周期 数量与时钟频率有关
        if(state_now != IDLE)begin
            rdcnt <= rdcnt + 1'b1;
        end
        else begin
            rdcnt <= 4'd0;
        end
    end
    assign rdcnt_end_d0 = &rdcnt;
    assign addr_ref_d0 = (rdcnt == 4'd8);
    always @(posedge clk_100M or negedge rst_n)begin // 连续计数的下一拍
        if(!rst_n)begin
            rdcnt_end <= 1'd0;
            addr_ref  <= 1'd0;
        end
        else begin
            rdcnt_end <= rdcnt_end_d0;  // 延缓一些时间再回归 IDLE
            addr_ref  <= addr_ref_d0;
        end
    end
    
    assign raddr1_ref = addr_ref;      // 隔 16 个周期后刷新地址
    
    always @(*)begin		// 每多一个数据源 重复该单元即可
        case(state_now)
            ID1:begin                       // 数据源 1
                raddr_d0 = {4'h1,5'd0,raddr1_d0,3'd0,4'hf};// 高四位id号 在ddr3中划分存储地址, 低四位为突发长度 突发长度尽量大于2
            end
            default:begin
                raddr_d0 = 32'h0;
            end
        endcase
    end
    
    always @(posedge clk_100M)begin		// 在结束前 拉高地址有效信号
        if(rdcnt == 4'd4)begin
            raddr_vld <= 1'd1;
        end
        else begin
            raddr_vld <= 1'd0;
        end
    end
    
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            raddr <= 32'h0;
        end
        else begin
            raddr <= raddr_d0 ;
        end
    end
    
    // 地址fifo有14个地址就暂停一下，否则数据FIFO要满
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            raddr_14 <= 1'b0;
        end
        else begin  // 打一拍优化时序
            raddr_14 <= almost_full;
        end
    end
    
    DFIFO32 fifo_araddr(
        .clk            (clk_100M   )   ,   // input        write clock
        .rst            (!rst_n      )   ,   // input        write reset
        .wr_en          (raddr_vld  )   ,   // input        write enable;
        .wr_data        (raddr      )   ,   // input [31:0] write data
        .full           (     		)   ,   // output       write full flag;
        .almost_full    (almost_full)   ,   // output
        .rd_en          (araddr_ref_pose )   ,   // input        read enable
        .rd_data        (rd_data    )   ,   // output[31:0] read data
        .empty          (araddr_empty)  ,   // output       read empty
        .almost_empty   (           )       // output       write almost empty 
    );
    
    always @(posedge clk_100M or negedge rst_n)begin		// 上升沿检查
        if(!rst_n)begin
            araddr_ref_d0 <= 1'b0;
        end
        else begin
            araddr_ref_d0 <= araddr_ref;
        end
    end
    assign araddr_ref_pose = (araddr_ref_d0 == 0) && (araddr_ref == 1);
    
    assign axi_arlen    = rd_data[ 3:0];
    assign axi_araddr   = {rd_data[27:4],4'b0};    // already output register
    assign axi_aruser_id= rd_data[31:28];
    
    
endmodule
