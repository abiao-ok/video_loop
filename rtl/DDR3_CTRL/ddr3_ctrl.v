/*==============================================


==============================================*/
module ddr3_ctrl (
    clk_100M     ,  // output       
    clk_50M      ,  // input        
    rstn         ,  // input        
    wdin1_req    ,  // input        HDMI 的传输请求
    wdin1_vld    ,  // input        HDMI 的数据有效信号
    wdin1        ,  // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
    wdin1_addr   ,  // input [15:0] HDMI 数据包的地址
    wdin1_rden   ,  // output       一个周期 指示 HDMI 可以传输一组数据了
    
    wdin2_req    ,  // input        
    wdin2_vld    ,  // input        
    wdin2        ,  // input [239:0]
    wdin2_addr   ,  // input [15:0] 
    wdin2_rden   ,  // output       
    
    wdin3_req    ,  // input        
    wdin3_vld    ,  // input        
    wdin3        ,  // input [239:0]
    wdin3_addr   ,  // input [15:0] 
    wdin3_rden   ,  // output       
    
    wdin4_req    ,  // input        
    wdin4_vld    ,  // input        
    wdin4        ,  // input [239:0]
    wdin4_addr   ,  // input [15:0] 
    wdin4_rden   ,  // output       
    
    raddr1_req   ,  // input        要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
    raddr1       ,  // input [15:0] rdata1 的地址 与 raddr1_need 对齐
    raddr1_ref   ,  // output       刷新下一个地址 
    rdata_vld    ,  // output       ddr3输出的数据有效信号
    rdata        ,  // output[255:0]ddr3输出的数据
    rid          ,  // output[  3:0]ddr3输出数据的 id
    rlast        ,  // output       ddr3 一次突发读的最后一个数据
    ddr_pll_lock ,  // output       ddr3的pll的锁
    mem_rst_n    ,  // output       DDR 复位
    mem_ck       ,  // output       DDR 输入系统时钟
    mem_ck_n     ,  // output       DDR 输入系统时钟
    mem_cke      ,  // output       DDR 输入系统时钟有效。
    mem_cs_n     ,  // output       DDR 的片选
    mem_ras_n    ,  // output       行地址使能
    mem_cas_n    ,  // output       列地址使能
    mem_we_n     ,  // output       DDR 写使能信号
    mem_odt      ,  // output       DDR ODT
    mem_a        ,  // output[14:0] DDR 行列地址总线   
    mem_ba       ,  // output[ 2:0] DDR Bank 地址      
    mem_dqs      ,  // inout [ 3:0] DDR 的数据随路时钟 
    mem_dqs_n    ,  // inout [ 3:0] DDR 的数据随路时钟 
    mem_dq       ,  // inout [31:0] DDR 的数据         
    mem_dm          // output[ 3:0] DDR 输入数据 Mask  
);
    output          clk_100M    ;   // output       
    input           clk_50M     ;   // input        
    input           rstn        ;   // input        
    input           wdin1_req   ;   // input        HDMI 的传输请求
    input           wdin1_vld   ;   // input        HDMI 的数据有效信号
    input [239:0]   wdin1       ;   // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
    input [15:0]    wdin1_addr  ;   // input [13:0] HDMI 数据包的地址
    output          wdin1_rden  ;   // output       一个周期 指示 HDMI 可以传输一组数据了
    
    input           wdin2_req   ;   // input        
    input           wdin2_vld   ;   // input        
    input [239:0]   wdin2       ;   // input [239:0]
    input [15:0]    wdin2_addr  ;   // input [15:0] 
    output          wdin2_rden  ;   // output       
    
    input           wdin3_req   ;   // input        
    input           wdin3_vld   ;   // input        
    input [239:0]   wdin3       ;   // input [239:0]
    input [15:0]    wdin3_addr  ;   // input [15:0] 
    output          wdin3_rden  ;   // output       
    
    input           wdin4_req   ;   // input        
    input           wdin4_vld   ;   // input        
    input [239:0]   wdin4       ;   // input [255:0]
    input [15:0]    wdin4_addr  ;   // input [15:0] 
    output          wdin4_rden  ;   // output       
    
    input           raddr1_req  ;   // input        要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
    input [15:0]    raddr1      ;   // input [15:0] rdata1 的地址 与 raddr1_need 对齐
    output          raddr1_ref  ;   // output       刷新下一个地址 
    output reg       rdata_vld/* synthesis syn_maxfan = 200 */;   // output       ddr3输出的数据有效信号
    output reg[255:0]rdata/* synthesis syn_maxfan = 200 */;   // output[256:0]ddr3输出的数据
    output reg[  3:0]rid/* synthesis syn_maxfan = 200 */;   // output[  3:0]ddr3输出数据的 id
    output reg       rlast      ;
    output          ddr_pll_lock;   // output       ddr3的pll的锁
    output          mem_rst_n   ;   // output       DDR 复位
    output          mem_ck      ;   // output       DDR 输入系统时钟
    output          mem_ck_n    ;   // output       DDR 输入系统时钟
    output          mem_cke     ;   // output       DDR 输入系统时钟有效。
    output          mem_cs_n    ;   // output       DDR 的片选
    output          mem_ras_n   ;   // output       行地址使能
    output          mem_cas_n   ;   // output       列地址使能
    output          mem_we_n    ;   // output       DDR 写使能信号
    output          mem_odt     ;   // output       DDR ODT
    output[14:0]    mem_a       ;   // output[14:0] DDR 行列地址总线   
    output[ 2:0]    mem_ba      ;   // output[ 2:0] DDR Bank 地址      
    inout [ 3:0]    mem_dqs     ;   // inout [ 3:0] DDR 的数据随路时钟 
    inout [ 3:0]    mem_dqs_n   ;   // inout [ 3:0] DDR 的数据随路时钟 
    inout [31:0]    mem_dq      ;   // inout [31:0] DDR 的数据         
    output[ 3:0]    mem_dm      ;   // output[ 3:0] DDR 输入数据 Mask  
    
    wire            awaddr_empty;   // 放写地址的 fifo 空了
    wire            awaddr_ref  ;   // 刷放写地址的 fifo 开启输出寄存
    wire            araddr_empty;   // 放读地址的 fifo 空了
    wire            araddr_ref  ;   // 刷新放读地址的 fifo 开启输出寄存
    wire            ddr_init_done;
    
    wire [27:0]     axi_awaddr           ;
    wire [ 3:0]     axi_awlen            ;
    wire            axi_awready          ;
    wire            axi_awvalid          ;
    wire [255:0]    axi_wdata            ;
    wire            axi_wready           ;
    wire [27:0]     axi_araddr           ;
    wire [3:0]      axi_aruser_id        ;
    wire [3:0]      axi_arlen            ;
    wire            axi_arready          ;
    wire            axi_arvalid          ;
    wire [255:0]    axi_rdata            ;
    wire [3:0]      axi_rid              ;
    wire            axi_rvalid           ;
    wire            axi_rlast            ;
    
    wire            rst_n       ;
    assign rst_n = rstn;
    // 把复位信号放到区域时钟，提高扇出能力
    // 需要复位管理模块控制
    // GTP_CLKBUFR rstn_BUFR(
        // .CLKOUT (rst_n),
        // .CLKIN (rstn )
    // );
    
    // 打拍
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            rdata_vld <= 1'b0;
            rdata     <= 256'b0;
            rid       <= 4'd0;
            rlast     <= 1'b0;
        end
        else begin
            rdata_vld <= axi_rvalid;
            rdata     <= axi_rdata;
            rid       <= axi_rid;
            rlast     <= axi_rlast;
        end
    end
    
    rd_side ddr3_rd_side(
        .rstn          (rst_n        )  ,   // input
        .clk_100M      (clk_100M     )  ,   // input
        .raddr1_req    (raddr1_req   )  ,   // input        要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
        .raddr1        (raddr1       )  ,   // input [15:0] rdata1 的地址 与 raddr1_need 对齐
        .raddr1_ref    (raddr1_ref   )  ,   // output       刷新下一个地址 
        .araddr_ref    (araddr_ref   )  ,   // input        刷放读地址的 fifo
        .araddr_empty  (araddr_empty )  ,   // output       放读地址的 fifo 空了
        .axi_araddr    (axi_araddr   )  ,   // output[27:0] ddr3 读地址     already output register
        .axi_aruser_id (axi_aruser_id)  ,   // output[ 3:0] ddr3 读地址id号
        .axi_arlen     (axi_arlen    )      // output[ 3:0] ddr3 读突发长度
    );

    wr_side ddr3_wr_side(
        .clk_100M      (clk_100M    ) ,    // input        
        .rstn          (rst_n       ) ,    // input        
        .wdin1_req     (wdin1_req   ) ,    // input        HDMI 的传输请求
        .wdin1_vld     (wdin1_vld   ) ,    // input        HDMI 的数据有效信号
        .wdin1         (wdin1       ) ,    // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .wdin1_addr    (wdin1_addr  ) ,    // input [15:0] HDMI 数据包的地址
        .wdin1_rden    (wdin1_rden  ) ,    // output       一个周期 指示 HDMI 可以传输一组数据了

        .wdin2_req     (wdin2_req )  ,   // input        HDMI 的传输请求
        .wdin2_vld     (wdin2_vld )  ,   // input        HDMI 的数据有效信号
        .wdin2         (wdin2     )  ,   // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .wdin2_addr    (wdin2_addr)  ,   // input [15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .wdin2_rden    (wdin2_rden)  ,   // output       一个周期 指示 HDMI 可以传输一组数据了
        
        .wdin3_req     (wdin3_req )  ,   // input        HDMI 的传输请求
        .wdin3_vld     (wdin3_vld )  ,   // input        HDMI 的数据有效信号
        .wdin3         (wdin3     )  ,   // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .wdin3_addr    (wdin3_addr)  ,   // input [15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .wdin3_rden    (wdin3_rden)  ,   // output       一个周期 指示 HDMI 可以传输一组数据了
        
        .wdin4_req   (wdin4_req )  ,   // input        HDMI 的传输请求
        .wdin4_vld   (wdin4_vld )  ,   // input        HDMI 的数据有效信号
        .wdin4       (wdin4     )  ,   // input [239:0]HDMI 的数据 wdata1_rden 拉高的两拍后 输出有效数据
        .wdin4_addr  (wdin4_addr)  ,   // input [15:0] HDMI 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
        .wdin4_rden  (wdin4_rden)  ,   // output       一个周期 指示 HDMI 可以传输一组数据了
        
        .awaddr_empty  (awaddr_empty) ,    // output        
        .awaddr_ref    (awaddr_ref  ) ,    // input        
        .axi_awaddr    (axi_awaddr  ) ,    // output[27:0] 
        .axi_awlen     (axi_awlen   ) ,    // output[ 3:0] 
        .axi_wready    (axi_wready  ) ,    // input        
        .axi_wdata     (axi_wdata   )      // output[255:0]
    );
    
    DDR3_rw_ctrl DDR3_rw_ctrl(
        .clk_100M       (clk_100M       ),  // input  wire         
        .rstn           (rst_n          ),  // input  wire         
        .ddr_init_done  (ddr_init_done  ),  // input        
        .awaddr_empty   (awaddr_empty   ),  // input        放写地址的 fifo 空了
        .awaddr_ref     (awaddr_ref     ),  // output       刷放写地址的 fifo 开启输出寄存
        .araddr_empty   (araddr_empty   ),  // input        放读地址的 fifo 空
        .araddr_ref     (araddr_ref     ),  // output       刷新放读地址的 fifo 开启输出寄存
        .axi_awvalid    (axi_awvalid    ),  // output reg   AXI 写地址 valid 
        .axi_awready    (axi_awready    ),  // input        AXI 写地址 ready
        .axi_arvalid    (axi_arvalid    ),  // output reg   读地址有效信号
        .axi_arready    (axi_arready    )   // input        DDR3读地址指示信号
    );
    
    DDR3_ip DDR3_ip(
        .ref_clk             (clk_50M       )   ,   // input                         外部参考时钟输入 50MHz
        .resetn              (rst_n         )   ,   // input                         外部复位输入
        .ddr_init_done       (ddr_init_done )   ,   // output                        DDR3 初始化完成 标志 1:初始化完成
        .ddrphy_clkin        (clk_100M      )   ,   // output                        工作时钟100Mhz
        .pll_lock            (ddr_pll_lock  )   ,   // output                        DDR3 专用 PLL 的锁
        // AXI 与 MC 的 clock 相同
        .axi_awaddr          (axi_awaddr    )   ,   // input [CTRL_ADDR_WIDTH-1:0]   AXI 写地址                                      
        .axi_awuser_ap       (1'b1          )   ,   // input                         AXI 写并自动 precharge 1:有效                   
        .axi_awuser_id       (4'hf          )   ,   // input [3:0]                   AXI 写地址 ID                                   
        .axi_awlen           (axi_awlen     )   ,   // input [3:0]                   AXI 写突发长度                                  
        .axi_awready         (axi_awready   )   ,   // output                        AXI 写地址 ready                                
        .axi_awvalid         (axi_awvalid   )   ,   // input                         AXI 写地址 valid                                
        .axi_wdata           (axi_wdata     )   ,   // input [MEM_DQ_WIDTH*8-1:0]    AXI 写数据 8*MEM_DQ_WIDTH                       
        .axi_wstrb           (32'hffff_ffff )   ,   // input [MEM_DQ_WIDTH-1:0]      AXI 写数据掩码  1:对应位置的数据有效 全有效8'hff
        .axi_wready          (axi_wready    )   ,   // output                        AXI 写数据 ready                                
        .axi_wusero_id       (              )   ,   // output [3:0]                  AXI 写数据 ID                                   
        .axi_wusero_last     (              )   ,   // output                        AXI 写数据 last                                 
        .axi_araddr          (axi_araddr    )   ,   // input [CTRL_ADDR_WIDTH-1:0]   AXI 读地址                                      
        .axi_aruser_ap       (1'b1          )   ,   // input                         AXI 读并自动 precharge 1:有效                   
        .axi_aruser_id       (axi_aruser_id )   ,   // input [3:0]                   AXI 读地址 ID                                   
        .axi_arlen           (axi_arlen     )   ,   // input [3:0]                   AXI 读突发长度                                  
        .axi_arready         (axi_arready   )   ,   // output                        AXI 读地址 ready                                
        .axi_arvalid         (axi_arvalid   )   ,   // input                         AXI 读地址 valid                                
        .axi_rdata           (axi_rdata     )   ,   // output[8*MEM_DQ_WIDTH-1:0]    AXI 读数据                                      
        .axi_rid             (axi_rid       )   ,   // output[3:0]                   AXI 读数据 ID                                   
        .axi_rlast           (axi_rlast     )   ,   // output                        AXI 读数据 last 
        .axi_rvalid          (axi_rvalid    )   ,   // output                        AXI 读数据 valid
        
        // Config 接口 可读取 DDR SDRAM 的状态 实现低功耗和 MRS 的控制
        .apb_clk             (1'b0          )   ,   // input                        APB 时钟
        .apb_rst_n           (1'b1          )   ,   // input                        APB 低电平复位
        .apb_sel             (1'b0          )   ,   // input                        APB Select 高有效
        .apb_enable          (1'b0          )   ,   // input                        APB Select 高有效                 
        .apb_addr            (8'd0          )   ,   // input [7:0]                       APB 地址总线                      
        .apb_write           (1'b0          )   ,   // input                        APB 读写方向，高电平写，低电平读  
        .apb_ready           (              )   ,   // output                       APB 端口 Ready                    
        .apb_wdata           (16'd0         )   ,   // input [15:0]                 APB 写数据                        
        .apb_rdata           (              )   ,   // output [15:0]                APB 读数据
        .apb_int             (              )   ,   // output                         
        
        // 调试接口
        .debug_data           (             )   ,   // output [135:0]               每组 DDRPHY 的 Debug 数据，8bit DQ共用一个 DDRPHY
        .debug_slice_state    (             )   ,   // output [51:0]                training 状态
        .debug_calib_ctrl     (             )   ,   // output [21:0]                Tainning 状态的 Debug 数据
        .ck_dly_set_bin       (             )   ,   // output [7:0]           
        .force_ck_dly_en      (1'b0         )   ,   // input                        memory 接口的命令和地址信号输出delay 调整使能，高电平有效。0：命令和地址信号输出 delay 由training 过程产生。1：命令和地址信号输出 delay 不变，始终为 force_ck_dly_set_bin 的设置值
        .force_ck_dly_set_bin (8'd5         )   ,   // input [7:0]                  命令和地址信号输出的 delay step
        .dll_step             (             )   ,   // output [7:0]                 DLL 输出的 delay step
        .dll_lock             (             )   ,   // output                       DLL 输出的 lock 标志信号，高有效
        .init_read_clk_ctrl   (2'b0         )   ,   // input [1:0]                  dqs gate 细调位置的初始值
        .init_slip_step       (4'b0         )   ,   // input [3:0]                  dqs gate 粗调位置的初始值
        .force_read_clk_ctrl  (1'b0         )   ,   // input                        dqs gate 位置固定使能，高电平有效。0：dqs gate 位置在 training 过程中变化；1：dqs gate 位置不变，始终为初始值
        .ddrphy_gate_update_en(1'b0         )   ,   // input                        gate update 使能信号
        .update_com_val_err_flag(           )   ,   // output  [3:0]                drift 码值跳变异常指示信号
        .rd_fake_stop         (1'b0         )   ,   // input                        假读终止信号
        
        // 硬件端口
        .mem_rst_n           (mem_rst_n     )   ,   // output                        DDR 复位
        .mem_ck              (mem_ck        )   ,   // output                        DDR 输入系统时钟
        .mem_ck_n            (mem_ck_n      )   ,   // output                        DDR 输入系统时钟
        .mem_cke             (mem_cke       )   ,   // output                        DDR 输入系统时钟有效。
        .mem_cs_n            (mem_cs_n      )   ,   // output                        DDR 的片选
        .mem_ras_n           (mem_ras_n     )   ,   // output                        行地址使能
        .mem_cas_n           (mem_cas_n     )   ,   // output                        列地址使能
        .mem_we_n            (mem_we_n      )   ,   // output                        DDR 写使能信号
        .mem_odt             (mem_odt       )   ,   // output                        DDR ODT
        .mem_a               (mem_a         )   ,   // output [MEM_ROW_WIDTH-1:0]    DDR 行列地址总线   
        .mem_ba              (mem_ba        )   ,   // output [MEM_BANK_WIDTH-1:0]   DDR Bank 地址      
        .mem_dqs             (mem_dqs       )   ,   // inout [MEM_DQS_WIDTH-1:0]     DDR 的数据随路时钟 
        .mem_dqs_n           (mem_dqs_n     )   ,   // inout [MEM_DQS_WIDTH-1:0]     DDR 的数据随路时钟 
        .mem_dq              (mem_dq        )   ,   // inout [MEM_DQ_WIDTH-1:0]      DDR 的数据         
        .mem_dm              (mem_dm        )       // output [MEM_DM_WIDTH-1:0]     DDR 输入数据 Mask  
    );
    
    
endmodule
