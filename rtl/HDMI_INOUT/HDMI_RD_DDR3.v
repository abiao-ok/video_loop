/*==============================================
为规避 列地址回滚
突发长度设置为2的整数次幂(例如2、4、8、16)

把四个 960x540 拼接成 1920x1080
ddr3 一个周期写: 8*32bit = 256bit;
一次16的突发读写地址变化 8*16 = 128

V1.0 未完成对vga的处理，理论数据吞吐量 5Ghz

此次 V2.0 提高模块通用性，但数据吞吐量增加为 6GHz

为了方便，设计读写ddr3过程中，输入输出像素数据位宽扩展为24bit
数据吞吐量最大 1920*1080*24*60*2=6Gbit
ddr3 一共有超过15GBit

数据结构
    24bit 一个像素点; 256bit / 24bit = 10 余 16
    把 10 个像素点串联, 256的高16位赋值 区域编号 方便程序查错
    即: ddr3 一个周期传 10 个 HDMI 像素点，加一个编号信息
    ddr3 突发长度 16, 一次突发传输 160 个像素点
    960/160 = 6 次 16 的突发写存入一行，进行地址跳跃
    HDMI一行图像 地址变化: 6*128 = 768
    地址增长以128为单位, 则地址的低7位保持为0
    三帧缓存地址变化: 768*540*3/128 = 9_720
    一帧图像地址变化: a_frame       = 12'd3240;
    
画面分布为:
    左上角放 HDMI 画面; 右上角放 网口 画面
    左下角放 VGA 画面;右下角放 VGA 画面

a_frame     = 16'd3240;
three_frame = 16'd9720;

HDMI: 
    hdmi_begin = 16'd1,
    HDMI_first_frame  = hdmi_begin,
    HDMI_second_frame = HDMI_first_frame + a_frame,
    HDMI_third_frame  = HDMI_second_frame + a_frame;
    
    结束地址: hdmi_end   = 16'd9_721;
    
UDP: 
    UDP_begin  = 16'd9_722,
    UDP_first_frame  = UDP_begin,
    UDP_second_frame = UDP_first_frame + a_frame,
    UDP_third_frame  = UDP_second_frame + a_frame;
    
    结束地址: UDP_end   = 16'd19_442;
    
VGA1: 
    VGA1_begin = 16'd19_443,
    VGA1_first_frame  = VGA1_begin,
    VGA1_second_frame = VGA1_first_frame + a_frame,
    VGA1_third_frame  = VGA1_second_frame + a_frame;
    
    结束地址: VGA1_end   = 16'd29_163;
    
VGA2: 
    VGA2_begin = 16'd29_164
    VGA2_first_frame  = VGA2_begin,
    VGA2_second_frame = VGA2_first_frame + a_frame,
    VGA2_third_frame  = VGA2_second_frame + a_frame;
    
    结束地址: VGA2_end   = 16'd38_884;

==============================================*/
module HDMI_RD_DDR3 (
    error_empty     ,
    
    rst_n           ,   // input        
    clk_100M        ,   // input        ddr3 工作时钟
    wr_hdmi_frame   ,   // input [ 1:0] HDMI 写入ddr3的帧编号 1, 2, 3
    wr_udp_frame    ,   // input [ 1:0] UDP  写入ddr3的帧编号 1, 2, 3
    wr_vgaa_frame   ,   // input [ 1:0] vga1 写入ddr3的帧编号 1, 2, 3
    wr_vgab_frame   ,   // input [ 1:0] vga2 写入ddr3的帧编号 1, 2, 3
    rd_hdmi_req     ,   // output       要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
    rd_hdmi_addr    ,   // output [15:0]rdata1 的地址 与 raddr1_need 对齐
    rd_hdmi_ref     ,   // input        刷新下一个地址 
    rdata_vld       ,   // input        ddr3输出的数据有效信号
    rdata           ,   // input[255:0] ddr3输出的数据
    rid             ,   // input[  3:0] ddr3输出数据的 id
    rlast           ,   // input        ddr3 一次突发读的最后一个数据
    pix_clk         ,   // input        读 ddr3 的像素时钟
    vga_vs          ,   // input        帧头
    de_re           ,   // input        在 de_re 拉高后的第二个周期要加载像素数据, fifo 输出寄存
    rgb_out             // output[23:0] 
);
    input           rst_n           ;   // 
    input           clk_100M        ;   // ddr3 工作时钟
    input [ 1:0]    wr_hdmi_frame   ;   // HDMI 写入ddr3的帧编号 1, 2, 3
    input [ 1:0]    wr_udp_frame    ;   // UDP  写入ddr3的帧编号 1, 2, 3
    input [ 1:0]    wr_vgaa_frame   ;   // vga1 写入ddr3的帧编号 1, 2, 3
    input [ 1:0]    wr_vgab_frame   ;   // vga2 写入ddr3的帧编号 1, 2, 3
    output reg      rd_hdmi_req     ;   // 要打过拍 需要读这个地址 要求 rdata1 的 fifo 里有128个空位，足够够一次存入
    output reg[15:0]rd_hdmi_addr    ;   // rdata1 的地址 与 raddr1_need 对齐
    input           rd_hdmi_ref     ;   // 刷新下一个地址 
    input           rdata_vld       ;   // ddr3输出的数据有效信号
    input[255:0]    rdata           ;   // ddr3输出的数据
    input[  3:0]    rid             ;   // ddr3输出数据的 id
    input           rlast           ;   // ddr3 一次突发读的最后一个数据
    input           pix_clk         ;   // 读 ddr3 的像素时钟
    input           vga_vs          ;   // 帧头
    input           de_re           ;   // 在 de_re 拉高后的第二个周期要加载像素数据, fifo 输出寄存
    output    [23:0]rgb_out         ;   // 

    
    parameter   a_frame = 16'd3240;
    
    parameter   HDMI_begin = 16'd1,
                HDMI_first_frame  = HDMI_begin,
                HDMI_second_frame = HDMI_first_frame + a_frame,
                HDMI_third_frame  = HDMI_second_frame + a_frame;
    
    parameter   UDP_begin  = 16'd9_722,
                UDP_first_frame  = UDP_begin,
                UDP_second_frame = UDP_first_frame + a_frame,
                UDP_third_frame  = UDP_second_frame + a_frame;
                
    parameter   VGAa_begin = 16'd19_443,
                VGAa_first_frame  = VGAa_begin,
                VGAa_second_frame = VGAa_first_frame + a_frame,
                VGAa_third_frame  = VGAa_second_frame + a_frame;
    
    parameter   VGAb_begin = 16'd29_164,
                VGAb_first_frame  = VGAb_begin,
                VGAb_second_frame = VGAb_first_frame + a_frame,
                VGAb_third_frame  = VGAb_second_frame + a_frame;
    
    // 对输入信号处理===========================================================
    reg vga_vs_D0, vga_vs_D1, vga_vs_D2;
    always  @(posedge clk_100M or negedge rst_n)
        if(!rst_n)begin
            vga_vs_D0 <= 'd0;
            vga_vs_D1 <= 'd0;
            vga_vs_D2 <= 'd0;
        end
        else begin
            vga_vs_D0 <= vga_vs;        // 异步信号同步化
            vga_vs_D1 <= vga_vs_D0; // 消除可能的亚稳态
            vga_vs_D2 <= vga_vs_D1; // 保存上一个时钟的信号
        end
    
    reg [1:0] hdmi_frame, udp_frame, vgaa_frame, vgab_frame;
    reg       hdmi_ref, rd_last;
    always @(posedge clk_100M or negedge rst_n)begin // 打一拍优化时序
        if(!rst_n)begin
            hdmi_frame <= 'd0;
            udp_frame  <= 'd0;
            vgaa_frame <= 'd0;
            vgab_frame <= 'd0;
            hdmi_ref   <= 'd0;
            rd_last    <= 'd0;
        end
        else begin
            hdmi_frame <= wr_hdmi_frame;
            udp_frame  <= wr_udp_frame ;
            vgaa_frame <= wr_vgaa_frame;
            vgab_frame <= wr_vgab_frame;
            hdmi_ref   <= rd_hdmi_ref  ;
            rd_last    <= (rid == 4'h1) && rlast;   // 只关注 rid 为 1 的信号
        end
    end
    
    // 上升沿复位，下降沿开始工作=================================================
    wire rstn;
    assign rstn = rst_n && ~((vga_vs_D2 == 0) && (vga_vs_D1 == 1));
    
    // 图片相对地址计算====================================================================
    reg  [ 2:0] cnt6        ;
    wire cnt6_add, cnt6_end ;
    always @(posedge clk_100M or negedge rstn)begin // 6 次 16 的突发读表示存入一行
        if(!rstn)begin
            cnt6 <= 'd0;
        end
        else if(cnt6_add)begin
            if(cnt6_end)begin
                cnt6 <= 'd0;
            end
            else begin
                cnt6 <= cnt6 + 1'b1;    // cnt6 一行内第几次突发读
            end
        end
    end
    assign cnt6_add = rd_last; // 在一次突发读的最后一个数据, 加地址
    assign cnt6_end = cnt6_add && (cnt6 == 3'd5); // 6 次突发读换行
    
    reg  [10:0] cnt1080     ;
    wire cnt1080_add, cnt1080_end;
    always @(posedge clk_100M or negedge rstn)begin // HDMI 和 UDP 一共需要传输 1080 行; 同 VGAa 和 VGAb
        if(!rstn)begin
            cnt1080 <= 'd0;
        end
        else if(cnt1080_add)begin
            if(cnt1080_end)begin
                cnt1080 <= 'd0;
            end
            else begin
                cnt1080 <= cnt1080 + 1'b1;
            end
        end
    end
    assign cnt1080_add = cnt6_end;
    assign cnt1080_end = cnt1080_add && (cnt1080 == 11'd1080 - 1'b1);
    
    reg area_left;
    always @(posedge clk_100M or negedge rstn)begin // 换行时切换左右区域
        if(!rstn)begin
            area_left <= 1'b1;
        end
        else if(cnt6_end)begin
            area_left <= ~area_left;
        end
    end
    
    reg area_up;
    always @(posedge clk_100M or negedge rstn)begin // HDMI 和 UDP 传输完成 进入下半区域
        if(!rstn)begin
            area_up <= 1'b1;
        end
        else if(cnt1080_end)begin
            area_up <= ~area_up;
        end
    end
    
    wire [ 9:0]v_cnt;
    assign v_cnt = cnt1080[10:1];  // cnt1080/2 表示 1/4 区域的行数
    
    wire [11:0] virt_addr_down, virt_addr_up;
    assign virt_addr_down = v_cnt + cnt6[2];          // v_cnt*4 + cnt6;
    assign virt_addr_up   = {virt_addr_down,cnt6[1:0]} + {v_cnt, 1'b0};   // 相对地址 = v_cnt*6 + cnt6;
    
    reg [11:0] virt_addr;
    always @(posedge clk_100M)begin     // 虚拟地址计算
        virt_addr <= virt_addr_up;
    end
    
    // 只在图片头切换 首地址==============================================================================
    reg [15:0] hdmi_begin = HDMI_second_frame/* synthesis syn_preserve = 1 */;
    always @(posedge clk_100M)begin  // 切换 HDMI 的帧首地址
        if((vga_vs_D2 == 1) && (vga_vs_D1 == 0))begin
            case(hdmi_frame)
                2'd1:hdmi_begin <= HDMI_third_frame    ;
                2'd2:hdmi_begin <= HDMI_first_frame    ;
                2'd3:hdmi_begin <= HDMI_second_frame   ;
                default:hdmi_begin <= HDMI_second_frame;
            endcase
        end
    end
    reg [15:0] udp_begin = UDP_second_frame/* synthesis syn_preserve = 1 */;
    always @(posedge clk_100M)begin  // 切换 UDP 的帧首地址
        if((vga_vs_D2 == 1) && (vga_vs_D1 == 0))begin
            case(udp_frame)
                2'd1:udp_begin <= UDP_third_frame    ;
                2'd2:udp_begin <= UDP_first_frame    ;
                2'd3:udp_begin <= UDP_second_frame   ;
                default:udp_begin <= UDP_second_frame;
            endcase
        end
    end
    reg [15:0] vgaa_begin = VGAa_second_frame/* synthesis syn_preserve = 1 */;
    always @(posedge clk_100M)begin  // 切换 VGA1 的帧首地址
        if((vga_vs_D2 == 1) && (vga_vs_D1 == 0))begin
            case(vgaa_frame)
                2'd1:vgaa_begin <= VGAa_third_frame    ;
                2'd2:vgaa_begin <= VGAa_first_frame    ;
                2'd3:vgaa_begin <= VGAa_second_frame   ;
                default:vgaa_begin <= VGAa_second_frame;
            endcase
        end
    end
    reg [15:0] vgab_begin = VGAb_second_frame/* synthesis syn_preserve = 1 */;
    always @(posedge clk_100M)begin  // 切换 VGA2 的帧首地址
        if((vga_vs_D2 == 1) && (vga_vs_D1 == 0))begin
            case(vgab_frame)
                2'd1:vgab_begin <= VGAb_third_frame    ;
                2'd2:vgab_begin <= VGAb_first_frame    ;
                2'd3:vgab_begin <= VGAb_second_frame   ;
                default:vgab_begin <= VGAb_second_frame;
            endcase
        end
    end
    
    reg [15:0] area_rdaddr;
    always @(posedge clk_100M)begin     // 根据当前区域切换首地址
        case({area_up,area_left})
            2'b11:area_rdaddr <= hdmi_begin;
            2'b10:area_rdaddr <= udp_begin;
            2'b01:area_rdaddr <= vgaa_begin;
            2'b00:area_rdaddr <= vgab_begin;
            default:area_rdaddr <= hdmi_begin;
        endcase
    end
    
    // 实际读的地址=首地址+图片相对地址=====================================================
    always @(posedge clk_100M or negedge rstn)begin
        if(!rstn)begin
            rd_hdmi_addr = HDMI_begin;
        end
        else begin
            rd_hdmi_addr = virt_addr + area_rdaddr;
        end
    end
    
    // 读ddr3请求====================================================================================
    // 用状态机区分: 图片状态 申请读ddr3 等待DFIFO接收到数据  等待DFIFO将空
    
    reg [4:0]state_now, state_next;
    parameter   IDLE        = 5'b00001,
                Wait16      = 5'b00010,
                RDreq       = 5'b00100,
                WaitData    = 5'b01000,
                WaitEmpty   = 5'b10000;
    
    reg DFIFO_47, p_end;
    wire 		cnt16_end	;
    always@(posedge clk_100M or negedge rstn)begin  // 当前状态state_now切换
        if(!rstn)begin
            state_now <= IDLE;
        end
        else begin
            state_now <= state_next;
        end
    end
    
    always@(*)begin             // 下一阶段state_next切换
        case(state_now)
            IDLE:begin
                if((vga_vs_D2 == 1) && (vga_vs_D1 == 0))
                    state_next = Wait16;
                else
                    state_next = state_now;
            end
            Wait16:begin
                if(cnt16_end)
                    state_next = RDreq;
                else
                    state_next = state_now;
            end
            RDreq:begin     // 申请地址
                if(hdmi_ref)// 有响应就结束申请
                    state_next = WaitData;
                else
                    state_next = state_now;
            end
            WaitData:begin
                if(rd_last) // 等数据输入完
                    state_next = WaitEmpty;
                else
                    state_next = state_now;
            end
            WaitEmpty:begin // 地址在此阶段变化
                if(p_end)
                    state_next = IDLE;
                else if(DFIFO_47)    // DFIFO 内数据小于48个时, 开始请求数据
                    state_next = RDreq;
                else
                    state_next = state_now;
            end
            default:state_next = IDLE;
        endcase
    end
    
    reg  [ 3:0] cnt16		;	// 
    wire 		cnt16_add	;
    always @(posedge clk_100M or negedge rst_n)begin	// 
        if(!rst_n)begin
            cnt16 <= 'd0;
        end
        else if(cnt16_add)begin
            if(cnt16_end)begin
                cnt16 <= 'd0;
            end
            else begin
                cnt16 <= cnt16 + 1'b1;
            end
        end
    end
    assign cnt16_add = (state_now == Wait16);
    assign cnt16_end = cnt16_add && (cnt16 == 4'hf);
    
    always @(posedge clk_100M or negedge rstn)begin // 图片区域
        if(!rstn)begin
            p_end <= 1'b0;
        end
        else if((vga_vs_D2 == 1) && (vga_vs_D1 == 0))begin // vs的下降沿开启一张图片
            p_end <= 1'b0;
        end
        else if((area_up == 0) && cnt1080_end)begin // 下半区域地址结束时，结束一张图片
            p_end <= 1'b1;
        end
    end
    
    wire DFIFO_48;
    always @(posedge clk_100M or negedge rstn)begin // DFIFO 只小于15时 向ddr3申请数据
        if(!rstn)begin
            DFIFO_47 <= 1'b1;
        end
        else begin
            DFIFO_47 <= ~DFIFO_48;
        end
    end
    
    always @(posedge clk_100M)begin
        if(state_now == RDreq)begin   // 申请读ddr3
            rd_hdmi_req <= 1'b1;
        end
        else begin
            rd_hdmi_req <= 1'b0;
        end
    end
    
    // 接收数据============================================================================
    reg DFIFO_wren;
    always @(posedge clk_100M)begin // 只管 id号为 1 的数据
        if(rid == 4'h1)begin
            DFIFO_wren <= rdata_vld;
        end
        else begin
            DFIFO_wren <= 1'b0;
        end
    end
    
    reg [255:0]DFIFO_wdata;
    always @(posedge clk_100M)begin // 打一拍对齐数据有效信号
        if(rid == 4'h1)begin
            DFIFO_wdata <= rdata;
        end
        else begin
            DFIFO_wdata <= 256'd0;
        end
    end
    
    wire [255:0]DFIFO_rdata, DFIFO_rdata1;
    wire DFIFO_rden, DFIFO_empty, DFIFO_full;
    DFIFO_hdmi_out DFIFO256_64_hdmi_out (
        .wr_clk         (clk_100M                   )   ,   // input
        .wr_rst         (!rstn                      )   ,   // input
        .wr_data        (~DFIFO_wdata               )   ,   // input [255:0]  插入反相器 增加延迟
        .wr_en          (DFIFO_wren && (!DFIFO_full))   ,   // input
        .full           (DFIFO_full                 )   ,   // output
        .almost_full    (DFIFO_48                   )   ,   // output 
        .rd_data        (DFIFO_rdata1               )   ,   // output[255:0]寄存输出
        .rd_en          (DFIFO_rden                 )   ,   // input
        .empty          (DFIFO_empty                )   ,   // output
        .almost_empty   (                           )   ,   // output
        .rd_clk         (pix_clk                    )   ,   // input
        .rd_rst         (!rstn                      )       // input
    );
    assign DFIFO_rdata = ~DFIFO_rdata1;
    
    
    // 只要 DFIFO_empty 不空, FIFO_full 不满，就输出数据
    wire FIFO_full;
    reg [3:0]rd_cnt10;
    always @(posedge pix_clk or negedge rstn)begin
        if(!rstn)begin
            rd_cnt10 <= 4'b0;
        end
        else if((!FIFO_full) && (!DFIFO_empty))begin
            if(rd_cnt10 == 4'd10)
                rd_cnt10 <= 4'b0;
            else
                rd_cnt10 <= rd_cnt10 + 1'b1;
        end
    end
    
    reg [23:0] rgb888;
    always @(*)begin     // DFIFO_rdata 10个24bit的像素组成240bit data + 16bit 0
        case(rd_cnt10)
            4'd0:rgb888 <= DFIFO_rdata[23:0];
            4'd1:rgb888 <= DFIFO_rdata[47:24];
            4'd2:rgb888 <= DFIFO_rdata[71:48];
            4'd3:rgb888 <= DFIFO_rdata[95:72];
            4'd4:rgb888 <= DFIFO_rdata[119:96];
            4'd5:rgb888 <= DFIFO_rdata[143:120];
            4'd6:rgb888 <= DFIFO_rdata[167:144];
            4'd7:rgb888 <= DFIFO_rdata[191:168];
            4'd8:rgb888 <= DFIFO_rdata[215:192];
            4'd9:rgb888 <= DFIFO_rdata[239:216];
            default :rgb888 <= DFIFO_rdata[23:0];
        endcase
    end
    
    // DFIFO 输出寄存
    assign DFIFO_rden = (!FIFO_full) && (!DFIFO_empty) && (rd_cnt10==4'd9);
    
    wire rgb_vld;
    assign rgb_vld = (!FIFO_full) && (!DFIFO_empty) && (rd_cnt10!=4'd10);
    
    wire FIFO_empty;
    FIFO_hdmi_out FIFO24_256_hdmi_out (
        .clk        (pix_clk    )   ,   // input
        .rst        (!rstn      )   ,   // input
        .wr_en      (rgb_vld    )   ,   // input
        .wr_data    (rgb888     )   ,   // input [23:0]
        .wr_full    (FIFO_full  )   ,   // output
        .almost_full(           )   ,   // output
        .rd_en      (de_re && (!FIFO_empty))   ,   // input
        .rd_data    (rgb_out    )   ,   // output [23:0]
        .rd_empty   (FIFO_empty )   ,   // output
        .almost_empty(          )     // output
    );
    
    output reg error_empty;
    always @(posedge clk_100M or negedge rstn)begin		//
        if(!rstn)begin
            error_empty <= 1'b0;
        end
        else if(DFIFO_wren && DFIFO_full)begin
            error_empty <= 1'b1;
        end
    end
    
    
    
endmodule
