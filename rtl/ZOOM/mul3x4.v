// 测试用
// module mul3x4 ( // unsigned
    // clk ,   // input        at next T
    // a_d0   ,   // input [ 2:0] unsigned
    // b_d0   ,   // input [ 3:0] unsigned
    // c        // output[ 6:0] unsigned
// );
    // input           clk;
    // input [ 2:0]    a_d0;
    // input [ 3:0]    b_d0;
    // output reg[ 6:0]c ;
    // wire z6,z5,z4,z3,z2,z1,z0;
    
    // reg [ 2:0]a;
    // reg [ 3:0]b;
    // always @(posedge clk)begin		//
        // a <= a_d0;
        // b <= b_d0;
    // end
    
// /* Total LUTs: 20 of 42800 (0.05%)
	// LUTs as dram: 0 of 17000 (0.00%)
	// LUTs as logic: 20
// Total Registers: 14 of 64200 (0.02%) 
// Fmax=690 Mhz */

module mul3x4 ( // unsigned
    clk ,   // input        at next T
    a   ,   // input [ 2:0] unsigned
    b   ,   // input [ 3:0] unsigned
    c       // output[ 6:0] unsigned
);
    input           clk;
    input [ 2:0]    a;
    input [ 3:0]    b;
    output reg[ 6:0]c;
    wire z6,z5,z4,z3,z2,z1,z0;
    
    GTP_LUT7#(.INIT(128'hFC00_F800_E000_0000_0000_0000_0000_0000))
    bit6(.Z(z6),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT7#(.INIT(128'hC3E0_07C0_1F80_FF00_F800_0000_0000_0000))
    bit5(.Z(z5),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT7#(.INIT(128'h3398_C738_1C70_F0F0_07C0_FF00_0000_0000))
    bit4(.Z(z4),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT7#(.INIT(128'hAB54_B4B4_936C_CCCC_C738_F0F0_FF00_0000))
    bit3(.Z(z3),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT7#(.INIT(128'h1E1E_6666_5A5A_AAAA_B4B4_CCCC_F0F0_0000))
    bit2(.Z(z2),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT7#(.INIT(128'h6666_AAAA_CCCC_0000_6666_AAAA_CCCC_0000))
    bit1(.Z(z1),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT7#(.INIT(128'hAAAA_0000_AAAA_0000_AAAA_0000_AAAA_0000))
    bit0(.Z(z0),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    always @(posedge clk)begin		//
        c <= {z6,z5,z4,z3,z2,z1,z0};
    end

    
    
endmodule

