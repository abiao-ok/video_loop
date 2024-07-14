`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: Will
// 
// Create Date: 2023-03-17  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//camera中寄存器的配置程序
 module reg_config(     
		  input clk_10M,
		  input camera_rstn,
		  input initial_en,
		  output reg_conf_done,
		  output i2c_sclk1,
          inout  i2c_sdat1,
          output i2c_sclk2,
          inout  i2c_sdat2,
		  output reg clock_20k,
		  output reg [8:0]reg_index
	  );

     reg [7:0]clock_20k_cnt;
     reg [1:0]config_step;	  
     reg [31:0]i2c_data;
     reg [23:0]reg_data;
     reg start;
	 reg reg_conf_done_reg;
	 reg camera1 , camera1_d0;
      
     i2c_com u1(.clock_i2c(clock_20k),
               .camera_rstn(camera_rstn),
               .camera1(camera1),
               .ack(     ),
               .i2c_data(i2c_data),
               .start(start),
               .tr_end(tr_end),
               .i2c_sclk1(i2c_sclk1)        ,   //FPGA与camera iic时钟接口
               .i2c_sdat1(i2c_sdat1)        ,   //FPGA与camera iic数据接口
               .i2c_sclk2(i2c_sclk2)        ,   //FPGA与camera iic时钟接口
               .i2c_sdat2(i2c_sdat2)            //FPGA与camera iic数据接口
     );
assign reg_conf_done=reg_conf_done_reg && camera1_d0;
// assign reg_conf_done=camera1;
//产生i2c控制时钟-20khz    

always@(posedge clk_10M)   
begin
   if(!initial_en) begin
        clock_20k<=0;
        clock_20k_cnt<=0;
   end
   else if(clock_20k_cnt<249)
      clock_20k_cnt<=clock_20k_cnt+1'b1;
   else begin
         clock_20k<=!clock_20k;
         clock_20k_cnt<=0;
   end
end

always@(posedge clock_20k)
if(!initial_en)
    camera1 <= 1'b0;
else if(reg_conf_done_reg)
    camera1 <= 1'b1;


always@(posedge clock_20k)
    camera1_d0 <= camera1;


wire change;
assign change = (camera1_d0 == 1'b0) && (camera1 == 1'b1);

////iic寄存器配置过程控制    
always@(posedge clock_20k)    
begin
   if(!initial_en) begin
       config_step<=0;
       start<=0;
       reg_index<=0;
	   reg_conf_done_reg<=0;
   end
   else if(change)begin
       reg_index <= 0;
       reg_conf_done_reg <= 1'b0;
   end
   else begin
      if(reg_conf_done_reg==1'b0) begin          //如果camera初始化未完成
			  if(reg_index<257) begin               //配置寄存器
					 case(config_step)
					 0:begin
						i2c_data<={8'h78,reg_data};       //OV5640 IIC Device address is 0x78   
						start<=1;                         //i2c写开始
						config_step<=1;                  
					 end
					 1:begin
						if(tr_end) begin                  //i2c写结束               					
							 start<=0;
							 config_step<=2;
						end
					 end
					 2:begin
						  reg_index<=reg_index+1'b1;       //配置下一个寄存器
						  config_step<=0;
					 end
					 endcase
				end
			 else 
				reg_conf_done_reg<=1'b1;                //OV5640寄存器初始化完成
      end
   end
 end
			
////iic需要配置的寄存器值  			
always@(reg_index)   
 begin
    case(reg_index)
	 0    :reg_data <=24'h310311 ;//      
	 1    :reg_data <=24'h300882 ;//      
	 2    :reg_data <=24'h300842 ;//      
	 3    :reg_data <=24'h310303 ;//      
	 4    :reg_data <=24'h3017ff ;//      
	 5    :reg_data <=24'h3018ff ;//      
	 6    :reg_data <=24'h30341A ;//      
	 7    :reg_data <=24'h303713 ;//      
	 8    :reg_data <=24'h310801 ;//      
	 9    :reg_data <=24'h363036 ;//      
	 10   :reg_data <=24'h36310e ;//       
	 11   :reg_data <=24'h3632e2 ;//       
	 12   :reg_data <=24'h363312 ;//       
	 13   :reg_data <=24'h3621e0 ;//       
	 14   :reg_data <=24'h3704a0 ;//       
	 15   :reg_data <=24'h37035a ;//       
	 16   :reg_data <=24'h371578 ;//       
	 17   :reg_data <=24'h371701 ;//       
	 18   :reg_data <=24'h370b60 ;//       
	 19   :reg_data <=24'h37051a ;//       
	 20   :reg_data <=24'h390502 ;//       
	 21   :reg_data <=24'h390610 ;//       
	 22   :reg_data <=24'h39010a ;//       
	 23   :reg_data <=24'h373112 ;//       
	 24   :reg_data <=24'h360008 ;//       
	 25   :reg_data <=24'h360133 ;//       
	 26   :reg_data <=24'h302d60 ;//       
	 27   :reg_data <=24'h362052 ;//       
	 28   :reg_data <=24'h371b20 ;//       
	 29   :reg_data <=24'h471c50 ;//       
	 30   :reg_data <=24'h3a1343 ;//       
	 31   :reg_data <=24'h3a1800 ;//       
	 32   :reg_data <=24'h3a19f8 ;//       
	 33   :reg_data <=24'h363513 ;//       
	 34   :reg_data <=24'h363603 ;//       
	 35   :reg_data <=24'h363440 ;//       
	 36   :reg_data <=24'h362201 ;//
	 37   :reg_data <=24'h3c0134 ;//       
	 38   :reg_data <=24'h3c0428 ;//       
	 39   :reg_data <=24'h3c0598 ;//       
	 40   :reg_data <=24'h3c0600 ;//       
     41   :reg_data <=24'h3c0708 ;//       
	 42   :reg_data <=24'h3c0800 ;//       
	 43   :reg_data <=24'h3c091c ;//       
	 44   :reg_data <=24'h3c0a9c ;//       
	 45   :reg_data <=24'h3c0b40 ;//       
	 46   :reg_data <=24'h381000 ;//       
	 47   :reg_data <=24'h381110 ;//       
	 48   :reg_data <=24'h381200 ;//       
	 49   :reg_data <=24'h370864 ;//       
	 50   :reg_data <=24'h400102 ;//       
	 51   :reg_data <=24'h40051a ;//       
	 52   :reg_data <=24'h300000 ;//       
	 53   :reg_data <=24'h3004ff ;//       
	 54   :reg_data <=24'h300e58 ;//       
	 55   :reg_data <=24'h302e00 ;//       
	 56   :reg_data <=24'h430060 ;//       
	 57   :reg_data <=24'h501f01 ;//       
	 58   :reg_data <=24'h440e00 ;//       
	 59   :reg_data <=24'h5000a7 ;//     
	 60   :reg_data <=24'h3a0f30 ;//       
	 61   :reg_data <=24'h3a1028 ;//       
	 62   :reg_data <=24'h3a1b30 ;//       
	 63   :reg_data <=24'h3a1e26 ;//       
	 64   :reg_data <=24'h3a1160 ;//       
	 65   :reg_data <=24'h3a1f14 ;//       
	 66   :reg_data <=24'h580023 ;//       
	 67   :reg_data <=24'h580114 ;//       
	 68   :reg_data <=24'h58020f ;//       
	 69   :reg_data <=24'h58030f ;//       
	 70   :reg_data <=24'h580412 ;//       
	 71   :reg_data <=24'h580526 ;//       
	 72   :reg_data <=24'h58060c ;//       
	 73   :reg_data <=24'h580708 ;//       
	 74   :reg_data <=24'h580805 ;//       
	 75   :reg_data <=24'h580905 ;//       
	 76   :reg_data <=24'h580a08 ;//       
	 77   :reg_data <=24'h580b0d ;//       
	 78   :reg_data <=24'h580c08 ;//       
	 79   :reg_data <=24'h580d03 ;//       
	 80   :reg_data <=24'h580e00 ;//       
	 81   :reg_data <=24'h580f00 ;//       
	 82   :reg_data <=24'h581003 ;//       
	 83   :reg_data <=24'h581109 ;//       
	 84   :reg_data <=24'h581207 ;//       
	 85   :reg_data <=24'h581303 ;//       
	 86   :reg_data <=24'h581400 ;//       
	 87   :reg_data <=24'h581501 ;//       
	 88   :reg_data <=24'h581603 ;//       
	 89   :reg_data <=24'h581708 ;//       
	 90   :reg_data <=24'h58180d ;//       
	 91   :reg_data <=24'h581908 ;//       
	 92   :reg_data <=24'h581a05 ;//       
	 93   :reg_data <=24'h581b06 ;//       
	 94   :reg_data <=24'h581c08 ;//       
	 95   :reg_data <=24'h581d0e ;//       
	 96   :reg_data <=24'h581e29 ;//       
	 97   :reg_data <=24'h581f17 ;//       
	 98   :reg_data <=24'h582011 ;//       
	 99   :reg_data <=24'h582111 ;//       
	 100  :reg_data <=24'h582215 ;//        
	 101  :reg_data <=24'h582328 ;//        
	 102  :reg_data <=24'h582446 ;//        
	 103  :reg_data <=24'h582526 ;//        
	 104  :reg_data <=24'h582608 ;//        
	 105  :reg_data <=24'h582726 ;//        
	 106  :reg_data <=24'h582864 ;//        
	 107  :reg_data <=24'h582926 ;//        
	 108  :reg_data <=24'h582a24 ;//        
	 109  :reg_data <=24'h582b22 ;//        
	 110  :reg_data <=24'h582c24 ;//        
	 111  :reg_data <=24'h582d24 ;//        
	 112  :reg_data <=24'h582e06 ;//        
	 113  :reg_data <=24'h582f22 ;//        
	 114  :reg_data <=24'h583040 ;//        
	 115  :reg_data <=24'h583142 ;//        
	 116  :reg_data <=24'h583224 ;//        
	 117  :reg_data <=24'h583326 ;//        
	 118  :reg_data <=24'h583424 ;//        
	 119  :reg_data <=24'h583522 ;//        
	 120  :reg_data <=24'h583622 ;//        
	 121  :reg_data <=24'h583726 ;//        
	 122  :reg_data <=24'h583844 ;//        
	 123  :reg_data <=24'h583924 ;//        
	 124  :reg_data <=24'h583a26 ;//        
	 125  :reg_data <=24'h583b28 ;//        
	 126  :reg_data <=24'h583c42 ;//        
	 127  :reg_data <=24'h583dce ;//        
	 128  :reg_data <=24'h5180ff ;//        
	 129  :reg_data <=24'h5181f2 ;//        
	 130  :reg_data <=24'h518200 ;//        
	 131  :reg_data <=24'h518314 ;//        
	 132  :reg_data <=24'h518425 ;//        
	 133  :reg_data <=24'h518524 ;//        
	 134  :reg_data <=24'h518609 ;//        
	 135  :reg_data <=24'h518709 ;//        
	 136  :reg_data <=24'h518809 ;//        
	 137  :reg_data <=24'h518975 ;//        
	 138  :reg_data <=24'h518a54 ;//        
	 139  :reg_data <=24'h518be0 ;//        
	 140  :reg_data <=24'h518cb2 ;//        
	 141  :reg_data <=24'h518d42 ;//        
	 142  :reg_data <=24'h518e3d ;//        
	 143  :reg_data <=24'h518f56 ;//        
	 144  :reg_data <=24'h519046 ;//        
	 145  :reg_data <=24'h5191f8 ;//        
	 146  :reg_data <=24'h519204 ;//        
	 147  :reg_data <=24'h519370 ;//        
	 148  :reg_data <=24'h5194f0 ;//        
	 149  :reg_data <=24'h5195f0 ;//        
	 150  :reg_data <=24'h519603 ;//        
	 151  :reg_data <=24'h519701 ;//        
	 152  :reg_data <=24'h519804 ;//        
	 153  :reg_data <=24'h519912 ;//        
	 154  :reg_data <=24'h519a04 ;//        
	 155  :reg_data <=24'h519b00 ;//        
	 156  :reg_data <=24'h519c06 ;//        
	 157  :reg_data <=24'h519d82 ;//        
	 158  :reg_data <=24'h519e38 ;//        
	 159  :reg_data <=24'h548001 ;//        
	 160  :reg_data <=24'h548108 ;//        
	 161  :reg_data <=24'h548214 ;//        
	 162  :reg_data <=24'h548328 ;//        
	 163  :reg_data <=24'h548451 ;//        
	 164  :reg_data <=24'h548565 ;//        
	 165  :reg_data <=24'h548671 ;//        
	 166  :reg_data <=24'h54877d ;//        
	 167  :reg_data <=24'h548887 ;//        
	 168  :reg_data <=24'h548991 ;//        
	 169  :reg_data <=24'h548a9a ;//        
	 170  :reg_data <=24'h548baa ;//        
	 171  :reg_data <=24'h548cb8 ;//        
	 172  :reg_data <=24'h548dcd ;//        
	 173  :reg_data <=24'h548edd ;//        
	 174  :reg_data <=24'h548fea ;//        
	 175  :reg_data <=24'h54901d ;//        
	 176  :reg_data <=24'h53811e ;//        
	 177  :reg_data <=24'h53825b ;//        
	 178  :reg_data <=24'h538308 ;//        
	 179  :reg_data <=24'h53840a ;//        
	 180  :reg_data <=24'h53857e ;//        
	 181  :reg_data <=24'h538688 ;//        
	 182  :reg_data <=24'h53877c ;//        
	 183  :reg_data <=24'h53886c ;//        
	 184  :reg_data <=24'h538910 ;//        
	 185  :reg_data <=24'h538a01 ;//        
	 186  :reg_data <=24'h538b98 ;//       
	 187  :reg_data <=24'h558006 ;//        
	 188  :reg_data <=24'h558340 ;//        
	 189  :reg_data <=24'h558410 ;//        
	 190  :reg_data <=24'h558910 ;//        
	 191  :reg_data <=24'h558a00 ;//        
	 192  :reg_data <=24'h558bf8 ;//        
	 193  :reg_data <=24'h501d40 ;//        
	 194  :reg_data <=24'h530008 ;//        
	 195  :reg_data <=24'h530130 ;//        
	 196  :reg_data <=24'h530210 ;//        
	 197  :reg_data <=24'h530300 ;//        
	 198  :reg_data <=24'h530408 ;//        
	 199  :reg_data <=24'h530530 ;//        
	 200  :reg_data <=24'h530608 ;//        
	 201  :reg_data <=24'h530716 ;//        
	 202  :reg_data <=24'h530908 ;//        
	 203  :reg_data <=24'h530a30 ;//        
	 204  :reg_data <=24'h530b04 ;//        
	 205  :reg_data <=24'h530c06 ;//        
	 206  :reg_data <=24'h502500 ;//        
	 207  :reg_data <=24'h300802 ;//       
  //720 30帧/秒, night mode 5fps ;//         
  //input clock=24Mhz,PCLK=Mhz ;//
	 208  :reg_data <=24'h303581 ;//PLL  21:30fps  41:15fps	81:7.5fps
	 209  :reg_data <=24'h303669 ;//PLL     
     210  :reg_data <=24'h3c0708 ;//        
	 211  :reg_data <=24'h382047 ;//        
	 212  :reg_data <=24'h382100 ;//        
	 213  :reg_data <=24'h381431 ;//        
	 214  :reg_data <=24'h381531 ;//        
	 215  :reg_data <=24'h380000 ;//      x 0 
	 216  :reg_data <=24'h380100 ;//        
	 217  :reg_data <=24'h380200 ;//      y 250
	 218  :reg_data <=24'h3803fa ;//        
	 219  :reg_data <=24'h38040a ;//       xmax=2623
	 220  :reg_data <=24'h38053f ;//        
	 221  :reg_data <=24'h380606 ;//       
	 222  :reg_data <=24'h3807a9 ;//    
     
	 // 223  :reg_data <=24'h380805 ;//        
	 // 224  :reg_data <=24'h380900 ;//        
	 // 225  :reg_data <=24'h380a02 ;//        
	 // 226  :reg_data <=24'h380bd0 ;//        
     223  :reg_data <=24'h380803; // DVPHO = 960
     224  :reg_data <=24'h3809c0; // DVP HO
     225  :reg_data <=24'h380a02; // DVPVO = 540
     226  :reg_data <=24'h380b1c; // DVPVO
	 
     227  :reg_data <=24'h380c07 ;//        
	 228  :reg_data <=24'h380d64 ;//        
	 229  :reg_data <=24'h380e02 ;//        
	 230  :reg_data <=24'h380fe4 ;//        
	 231  :reg_data <=24'h381304 ;//   
	 232  :reg_data <=24'h361800 ;//        
	 233  :reg_data <=24'h361229 ;//        
	 234  :reg_data <=24'h370952 ;//        
	 235  :reg_data <=24'h370c03 ;//        
	 236  :reg_data <=24'h3a0202 ;//        
	 237  :reg_data <=24'h3a03e0 ;//        
	 238  :reg_data <=24'h3a0800 ;//        
	 239  :reg_data <=24'h3a096f ;//        
	 240  :reg_data <=24'h3a0a00 ;//        
	 241  :reg_data <=24'h3a0b5c ;//        
	 242  :reg_data <=24'h3a0e06 ;//        
	 243  :reg_data <=24'h3a0d08 ;//        
	 244  :reg_data <=24'h3a1402 ;//         
	 245  :reg_data <=24'h3a15e0 ;//         
	 246  :reg_data <=24'h400402 ;//         
	 247  :reg_data <=24'h30021c ;//         
	 248  :reg_data <=24'h3006c3 ;//         
	 249  :reg_data <=24'h471303 ;//         
	 250  :reg_data <=24'h440704 ;//         
	 251  :reg_data <=24'h460b37 ;//           
     252  :reg_data <=24'h460c20 ;//          
	 253  :reg_data <=24'h483716 ;//         
	 254  :reg_data <=24'h382404 ;//         
	 255  :reg_data <=24'h500183 ;//         
	 256  :reg_data <=24'h350300 ;//   
     // 257  :reg_data	<=24'h503d80;   // 彩条测试
     
     // 258  :reg_data <=24'h340600 ;// 环境光模式：Auto 自动
	 // 259  :reg_data <=24'h340004 ;//         
	 // 260  :reg_data <=24'h340100 ;//         
	 // 261  :reg_data <=24'h340204 ;//         
	 // 262  :reg_data <=24'h340300 ;//         
     // 263  :reg_data <=24'h340404 ;//         
	 // 264  :reg_data <=24'h340500 ;//   
     
     // 265  :reg_data <=24'h558628 ;// 对比度 +2  
	 // 266  :reg_data <=24'h558518 ;// 
     
	 default:reg_data<=24'hffffff;//        
    endcase      
end	 



endmodule

