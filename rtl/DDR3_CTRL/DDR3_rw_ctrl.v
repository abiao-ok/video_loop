/*==============================================
数据位宽 32bit*8 = 256
地址位宽 28bit
axi_awuser_ap = 1'b1 // 参考例程里衡为0 固定在写完后进行自动预充电
axi_awuser_id [3:0]  // 写地址与写数据有严格顺序，不关注ID号
axi_awlen     = 4'hf // 突发长度固定为16，最大程度节约时间，一次写入 8*16= 128 个 32bit 数据
axi_awaddr
axi_wdata
axi_wstrb     = 32'b1// 数据掩码全一即可，每一位都有效
axi_aruser_ap = 1'b1 // 参考例程里衡为0 固定在读完后进行自动预充电
axi_arlen     = 4'hf // 突发长度固定为16，最大程度节约时间，一次读出 8*16= 128 个 32bit 数据
axi_aruser_id [3:0]  // 读ID号
==============================================*/
module DDR3_rw_ctrl (
    clk_100M            ,  // input  wire         
    rstn                ,  // input  wire  
    ddr_init_done       ,  // input        
    // 接读写地址的fifo
    awaddr_empty        ,  // input        放写地址的 fifo 空了
    awaddr_ref          ,  // output       刷放写地址的 fifo 开启输出寄存
    araddr_empty        ,  // input        放读地址的 fifo 空了
    araddr_ref          ,  // output       刷新放读地址的 fifo 开启输出寄存
    // 接DDR3 IP
    axi_awvalid         ,  // output reg   AXI 写地址 valid 
    axi_awready         ,  // input        AXI 写地址 ready
    axi_arvalid         ,  // output reg   读地址有效信号
    axi_arready            // input        DDR3读地址指示信号
);
    input  wire         clk_100M       ;
    input  wire         rstn           ;
    // 接读写地址的fifo
    input               awaddr_empty   ;  // 放写地址的 fifo 空了
    output reg          awaddr_ref     ;  // 刷放写地址的 fifo 开启输出寄存
    input               araddr_empty   ;  // 放读地址的 fifo 空了
    output reg          araddr_ref     ;  // 刷新放读地址的 fifo 开启输出寄存
    // 接DDR3 IP 
    input               ddr_init_done  ;
    output reg          axi_awvalid    ;  // AXI 写地址 valid 
    input               axi_awready    ;  // AXI 写地址 ready
    output reg          axi_arvalid    ;   // 读地址有效信号
    input               axi_arready    ;   // DDR3读地址指示信号
    
    reg  [ 4:0]         state_now            ;
    reg  [ 4:0]         state_next           ;
    wire                IDLE_to_DDR3IDLE     ;
    wire                DDR3IDLE_to_priorWR  ;
    wire                DDR3IDLE_to_WRADDR   ;
    wire                DDR3IDLE_to_RDADDR   ;
    wire                WRADDR_to_Wait10T    ;
    wire                RDADDR_to_Wait10T    ;
    wire                Wait10T_to_DDR3IDLE  ;
    parameter           IDLE     = 5'b00001  ;
    parameter           DDR3IDLE = 5'b00010  ;
    parameter           WRADDR   = 5'b00100  ;
    parameter           RDADDR   = 5'b01000  ;
    parameter           Wait10T  = 5'b10000  ;
    reg                 priorWR              ;
    reg [9:0]           wait10               ;
    reg                 init_done            ;
    wire                rst_n                ;
    // 把复位信号放到区域时钟，提高扇出能力
    // 需要复位管理模块控制
    /* GTP_CLKBUFR rstn_BUFR(
        .CLKOUT (rst_n),
        .CLKIN (rstn )
    ); */
    assign rst_n = rstn;
    
    always @(posedge clk_100M or negedge rst_n)begin		//
        if(!rst_n)begin
            init_done <= 1'b0;
        end
        else begin
            init_done <= ddr_init_done;
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
                if(IDLE_to_DDR3IDLE)
                    state_next = DDR3IDLE;
                else
                    state_next = state_now;
            end
            DDR3IDLE:begin
                if(DDR3IDLE_to_priorWR)          // 优先级交替 先读
                    state_next = WRADDR;
                else if(DDR3IDLE_to_RDADDR)     // 跳转到 读地址
                    state_next = RDADDR;
                else if(DDR3IDLE_to_WRADDR)     // 跳转到 写地址
                    state_next = WRADDR;
                else
                    state_next = state_now;
            end
            WRADDR:begin
                if(WRADDR_to_Wait10T)            // 从写地址跳转到写数据
                    state_next = Wait10T;
                else
                    state_next = state_now;
            end
            RDADDR:begin
                if(RDADDR_to_Wait10T)            // 从读地址跳转到读数据
                    state_next = Wait10T;
                else
                    state_next = state_now;
            end
            Wait10T:begin
                if(Wait10T_to_DDR3IDLE)
                    state_next = DDR3IDLE;
                else
                    state_next = state_now;
            end
            default:state_next = IDLE;
        endcase
    end
    
    assign IDLE_to_DDR3IDLE    = (state_now == IDLE    ) && init_done;  // ddr初始化完成
    assign DDR3IDLE_to_priorWR = (state_now == DDR3IDLE) && priorWR && (!awaddr_empty);         // 带优先级判断 放写命令的 fifo 不空
    assign DDR3IDLE_to_WRADDR  = (state_now == DDR3IDLE) && (!priorWR) && (!awaddr_empty);      // 放写命令的 fifo 不空
    assign DDR3IDLE_to_RDADDR  = (state_now == DDR3IDLE) && (!araddr_empty);   // 放读命令的 fifo 不空
    assign WRADDR_to_Wait10T   = (state_now == WRADDR  ) && axi_awvalid && axi_awready;// 写地址 握手完成
    assign RDADDR_to_Wait10T   = (state_now == RDADDR  ) && axi_arvalid && axi_arready;// 读地址 握手完成
    assign Wait10T_to_DDR3IDLE = (state_now == Wait10T ) && wait10[9];                 // 等待 10 个周期
    
    always @(posedge clk_100M or negedge rst_n)begin // 读写优先级的交替
        if(!rst_n)begin
            priorWR <= 1'b1;
        end
        else if(state_now == RDADDR)begin   // 本次是读 调高写的优先级
            priorWR <= 1'b1;
        end
        else if(state_now == WRADDR)begin   // 本次是写 调低写的优先级
            priorWR <= 1'b0;
        end
        else begin
            priorWR <= priorWR;
        end
    end
    
    always @(posedge clk_100M)begin // 发送一次读写命令等待一段时间再发送 根据 debug 来调
        if(state_now == DDR3IDLE)begin
            wait10 <= 10'b1;
        end
        else if(state_now == Wait10T)begin
            wait10 <= {wait10[8:0],wait10[9]};
        end
        else begin
            wait10 <= wait10;
        end
    end
    
    // 写地址通道
    always @(posedge clk_100M)begin		// 刷新地址
        if(axi_awvalid && axi_awready)begin
            awaddr_ref <= 1'b1;
        end
        else begin
            awaddr_ref <= 1'b0;
        end
    end
    
    always @(posedge clk_100M)begin	// 写地址有效信号
        if(axi_awvalid && axi_awready)begin// 写地址有效信号和写地址准备信号都为1时
            axi_awvalid <= 1'b0;                // 拉低写地址有效信号
        end
        else if(state_now == WRADDR)begin       // 状态机处于写地址状态时
            axi_awvalid <= 1'b1;                // 拉高写地址有效信号, 等待写地址准备信号
        end
        else begin
            axi_awvalid <= 1'b0;
        end
    end
    
    // 读地址通道
    always @(posedge clk_100M)begin		// 控制提前刷新地址
        if(axi_arvalid && axi_arready)begin
            araddr_ref <= 1'b1;
        end
        else begin
            araddr_ref <= 1'b0;
        end
    end
    
    always @(posedge clk_100M)begin	// 读地址有效信号
        if(axi_arvalid && axi_arready)begin    // 读地址有效信号和读地址准备信号都为1时
            axi_arvalid <= 1'b0;
        end
        else if(state_now == RDADDR)begin           // 状态机处于读地址状态时
            axi_arvalid <= 1'b1;                    // 拉高读地址有效信号, 等待读地址准备信号
        end
        else begin
            axi_arvalid <= 1'b0;
        end
    end
    
endmodule
