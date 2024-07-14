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
//将两个8bit数据拼成一个16bit RGB565数据；
`timescale 1ns/1ns

module cmos_8_16bit(
	input 				   pclk 		,   
	input 				   rst_n		,
	input				   de_i	        ,
	input	[7:0]	       pdata_i	    ,
    input                  vs_i         ,

 	output	reg			   de_o         ,
	output  reg [15:0]	   pdata_o
); 

reg de_o_d0;
always @(posedge pclk or negedge rst_n)begin		//
	if(!rst_n)begin
		de_o_d0 <= 1'b0;
    end
	else if(vs_i)begin
		de_o_d0 <= 1'b0;
    end
	else if(de_i)begin
        de_o_d0 <= ~de_o_d0;
    end
end

reg [7:0] pdata_i_d0;
always @(posedge pclk or negedge rst_n)begin		//
	if(!rst_n)begin
		pdata_i_d0 <= 8'b0;
    end
	else if(de_o_d0 == 0)begin
		pdata_i_d0 <= pdata_i;
    end
end

always @(posedge pclk or negedge rst_n)begin		//
	if(!rst_n)begin
		pdata_o <= 16'b0;
    end
	else if((de_i == 1) && (de_o_d0 == 1))begin
		pdata_o <= {pdata_i_d0,pdata_i};
    end
end

always @(posedge pclk or negedge rst_n)begin		//
	if(!rst_n)begin
		de_o <= 1'b0;
    end
	else if((de_i == 1) && (de_o_d0 == 1))begin
		de_o <= 1'b1;
    end
    else begin
        de_o <= 1'b0;
    end
end

endmodule