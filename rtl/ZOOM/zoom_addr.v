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
    hdmi_begin = 16'd1
    HDMI_first_frame  = hdmi_begin,
    HDMI_second_frame = HDMI_first_frame + a_frame,
    HDMI_third_frame  = HDMI_second_frame + a_frame;
    
    结束地址: hdmi_end   = 16'd9_721;
    
UDP: 
    UDP_begin  = 16'd9_722
    UDP_first_frame  = UDP_begin,
    UDP_second_frame = UDP_first_frame + a_frame,
    UDP_third_frame  = UDP_second_frame + a_frame;
    
    结束地址: UDP_end   = 16'd19_442;
    
VGA1: 
    VGA1_begin = 16'd19_443
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

// 如何进行合理复位
module zoom_addr (
    error_empty,
    rst_n       ,   // input        
    clk_zoom    ,   // input        
    vga_vs      ,   // input        每经过一张图片，本模块复位，在头复位, vga_vs==1为头
    pout_vld    ,   // input        有效信号缩放后的数据
    pout        ,   // input [23:0] 缩放后的数据
    clk_100M    ,   // input        ddr3使用的时钟
    // dout_vs     ,   // output       提供给zoom512x512模块
    // dout_vld    ,   // output       
    // dout        ,   // output[23:0] 
    frame       ,   // output[ 1:0] data 正在写的帧 1,2,3
    data_req    ,   // output       data 的传输请求
    data_vld    ,   // output       data 的数据有效信号
    data_data   ,   // output[239:0]data 的数据 wdata1_rden 拉高的两拍后 输出有效数据
    data_addr   ,   // output[15:0] data 数据包的存放地址 14'd1 ~ 14'd9_721-1, 不包含低7位(128)，突发长度 16
    data_rden       // input        一个周期 指示 data 可以传输一组数据了
);
    
    input           rst_n       ;   // 
    input           clk_zoom    ;   // 
    input           vga_vs      ;
    input           pout_vld    ;   // 有效信号缩放后的数据
    input [23:0]    pout        ;   // 缩放后的数据
    input           clk_100M    ;   // ddr3使用的时钟
    output reg[ 1:0]frame       ;   // data 正在写的帧
    output reg      data_req    ;   // data 的传输请求
    output reg      data_vld    ;   // data 的数据有效信号
    output[239:0]   data_data   ;   // data 的数据 wdata1_rden 拉高的两拍后 输出有效数据
    output reg[15:0]data_addr   ;   // data 数据包的存放地址 1 - 9_721
    input           data_rden   ;   // 一个周期 指示 data 可以传输一组数据了
    
    parameter   begin_addr = 16'd1;
    parameter   a_frame    = 16'd3240;
    
    parameter   first_frame  = begin_addr;
    parameter   second_frame = first_frame + a_frame;
    parameter   third_frame  = second_frame + a_frame;
    reg 			vga_vs_D0;		//链接异步信号，不可用
    reg 			vga_vs_D1;		//消除亚稳态后的信号，可用
    reg 			vga_vs_D2;		//保存上一个时钟的信号
    wire 			vga_vs_posedge;	//上升沿
    
    wire rstn;
    // 每经过一张图片，本模块复位
    assign rstn = rst_n && (~vga_vs);
    
    wire wr_full, rden, fifo24empty, full_16;
    wire [23:0] rd_data;
    fifo24_256_zoom_hdmi fifo24_256_zoom (
        
        .wr_en        (pout_vld&&(!wr_full) )   ,   // input
        .wr_data      (pout                 )   ,   // input [23:0]
        .wr_full      (wr_full              )   ,   // output
        .almost_full  (                     )   ,   // output
        .rd_en        (rden                 )   ,   // input
        .rd_data      (rd_data              )   ,   // output [23:0]    寄存输出
        .rd_empty     (fifo24empty          )   ,   // output
        .almost_empty (                     )   ,   // output
        .wr_clk       (clk_zoom             )   ,   // input
        .wr_rst       (!rstn                )   ,   // input
        .rd_clk       (clk_100M             )   ,   // input
        .rd_rst       (!rstn                )       // input
    );
    
    // 只要 fifo240_16 不满, fifo24_256 不空 就不断传输
    assign rden = (!full_16) && (!fifo24empty);
    
    reg wdata_vld_d0, wdata_vld;
    // 寄存输出，第二拍才是数据
    always @(posedge clk_100M or negedge rstn)begin		//
        if(!rstn)begin
            wdata_vld_d0 <= 1'b0;
            wdata_vld <= 1'b0;
        end
        else begin
            wdata_vld_d0 <= rden;
            wdata_vld <= wdata_vld_d0;
        end
    end
    
    reg [9:0] wr_cnt10;
    // 10 次计数
    always @(posedge clk_100M or negedge rstn)begin
        if(!rstn)begin
            wr_cnt10 <= 10'b1;
        end
        else if(wdata_vld)begin
            wr_cnt10 <= {wr_cnt10[8:0],wr_cnt10[9]};
        end
    end
    
    reg [239:0] wr_data;
    // 10 个 24bit 拼接
    generate
        genvar i;
        for(i=0; i<10; i=i+1)begin
            always @(posedge clk_100M or negedge rstn)begin
                if(!rstn)begin
                    wr_data[24*(i+1)-1:24*i] <= 24'd0;
                end
                else if(wr_cnt10[i] && wdata_vld)begin
                    wr_data[24*(i+1)-1:24*i] <= rd_data;
                end
            end
        end
    endgenerate
    
    // output          dout_vs    ;
    // output          dout_vld   ;
    // output [23:0]   dout       ;
    
    // assign dout_vs  = vga_vs_D2 ;
    // assign dout_vld = wdata_vld ;
    // assign dout     = rd_data   ;
    
    reg wr_en;
    // 只在数据拼接的最后一项，使能传输一下
    always @(posedge clk_100M or negedge rstn)begin
        if(!rstn)begin
            wr_en <= 'b0;
        end
        else if(wr_cnt10[9] && wdata_vld)begin
            wr_en <= 'b1;
        end
		else begin
			wr_en <= 'b0;
		end
    end
    
    wire [239:0]data_data1;
    wire rden_16, empty_16, empty_15;
    DFIFO240_16_zoom_hdmi DFIFO240_16_zoom_data (
        .wr_data      (~wr_data )   ,   // input [239:0]
        .wr_en        (wr_en    )   ,   // input
        .full         (full_16  )   ,   // output
        .almost_full  (         )   ,   // output
        .rd_data      (data_data1)  ,   // output [239:0]
        .rd_en        (rden_16  )   ,   // input
        .empty        (empty_16 )   ,   // output
        .almost_empty (empty_15 )   ,   // output lass 15 almost_empty will pull up
        .clk          (clk_100M )   ,   // input
        .rst          (!rstn    )       // input
        
    );
    assign data_data = ~data_data1;
    
    // 数据量大于 14 即可申请传输一次数据
    always @(posedge clk_100M or negedge rstn)begin
        if(!rstn)begin
            data_req <= 1'b0;
        end
        else begin
            data_req <= ~empty_15;
        end
    end
    
    wire cnt16_end	;
    reg cnt16_en;
    always @(posedge clk_100M or negedge rstn)begin
        if(!rstn)begin
            cnt16_en <= 1'b0;
        end
        else if(cnt16_end)begin // 传输了16个数据就结束
            cnt16_en <= 1'b0;
        end
        else if(data_rden)begin // 收到发数据的指令
            cnt16_en <= 1'b1;   // 开始读数据
        end
    end
    
    // 不空的时候读数据
    assign rden_16 = cnt16_en && (~empty_16);
    
    reg  [ 3:0] cnt16		;	// 
    wire 		cnt16_add	;
    always @(posedge clk_100M or negedge rstn)begin
        if(!rstn)begin
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
    assign cnt16_add = cnt16_en;
    assign cnt16_end = cnt16_add && (cnt16 == 4'hf);    // 发16个数据
    
    always @(posedge clk_100M or negedge rstn)begin // 寄存输出 但是 show ahead 模式
        if(!rstn)begin
            data_vld <= 'd0;
        end
        else begin
            data_vld <= cnt16_en;
        end
    end
    
    reg  [15:0] addr		;	// 
    wire 		addr_add	;
    wire 		addr_end	;
    always @(posedge clk_100M or negedge rstn)begin	// 
        if(!rstn)begin
            addr <= 'd0;
        end
        else if(addr_add)begin
            if(addr_end)begin
                addr <= 'd0;
            end
            else begin
                addr <= addr + 1'b1;
            end
        end
    end
    assign addr_add = cnt16_end;
    assign addr_end = addr_add && (addr == a_frame - 1'b1);
    
    always	@(posedge clk_100M or negedge rst_n)
        if(!rst_n)begin
            vga_vs_D0 <= 'd0;
            vga_vs_D1 <= 'd0;
            vga_vs_D2 <= 'd0;
        end
        else begin
            vga_vs_D0 <= vga_vs;	// 异步信号同步化
            vga_vs_D1 <= vga_vs_D0;	// 消除可能的亚稳态
            vga_vs_D2 <= vga_vs_D1;	// 保存上一个时钟的信号
        end
    
    assign vga_vs_posedge = (vga_vs_D2 == 0) && (vga_vs_D1 == 1);
    
    // 在帧头的上升沿，切换帧
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            frame <= 2'd3;
        end
        else if((frame == 2'd3) && vga_vs_posedge)begin
            frame <= 2'b1;
        end
        else if(vga_vs_posedge)begin
            frame <= frame + 1'b1;
        end
    end
    
    reg [15:0] addr_begin;
    always @(posedge clk_100M)begin  // 根据当前写的帧，切换首地址
        case(frame)
            2'd1:addr_begin <= first_frame ;
            2'd2:addr_begin <= second_frame;
            2'd3:addr_begin <= third_frame ;
            default:addr_begin <= first_frame ;
        endcase
    end
    
    always @(posedge clk_100M)begin		// 实际地址，还需要加上首地址
        data_addr <= addr_begin + addr;
    end
    
    output reg error_empty;
    always @(posedge clk_100M or negedge rstn)begin		//
        if(!rstn)begin
            error_empty <= 1'b0;
        end
        else if(cnt16_en && empty_16)begin
            error_empty <= 1'b1;
        end
    end
    
endmodule
