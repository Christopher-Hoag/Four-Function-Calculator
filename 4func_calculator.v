`timescale 1ns / 1ps

module top(
     input clk, rst,
     input [3:0] BCD,
     input negative,
     input [2:0] function_sel,
     input equals,
     output wire[31:0] out,
     output [7:0]   SSC,
	 output [15:0]  SSA
    );
    
    wire[3:0] BCD_0, BCD_1, BCD_2, BCD_3, BCD_4, BCD_5, BCD_6, BCD_7, BCD_8, BCD_9;
    wire[39:0] outBCD;
    wire[31:0] bin;
    wire outneg;
    reg[31:0] a, b;
    reg[2:0] sel;
    reg rst2, neg, equ, display_value;
    wire[79:0] Pass;
	wire[15:0] DP;
	wire[1:0] sign;
	reg[4:0] equals_sign, neg_sign;
	reg[3:0] disp_seg[0:9];
	wire[3:0] outBCD_disp[0:9];
	wire[49:0] display_numbers;
	integer i;
    
    BCD_Sequence seq1(.clk (clk), .rst (rst2),
                      .BCD (BCD),
                      .BCD_9 (BCD_9), .BCD_8 (BCD_8), .BCD_7 (BCD_7), .BCD_6 (BCD_6), .BCD_5 (BCD_5), .BCD_4 (BCD_4), .BCD_3 (BCD_3), .BCD_2 (BCD_2), .BCD_1 (BCD_1), .BCD_0 (BCD_0)); //OUTPUT
    
    BCD_Binary   bcd1(.clk (clk),
                      .BCD_9 (BCD_9), .BCD_8 (BCD_8), .BCD_7 (BCD_7), .BCD_6 (BCD_6), .BCD_5 (BCD_5), .BCD_4 (BCD_4), .BCD_3 (BCD_3), .BCD_2 (BCD_2), .BCD_1 (BCD_1), .BCD_0 (BCD_0), //INPUT
                      .neg (neg),
                      .bin (bin));
                      
    calc_4_func  calc(.clk (clk),
                      .a (a), .b (b),
                      .sel (sel),
                      .out (out));
                      
    Binary_BCD  b2bcd(.bin_2s (out), 
                      .bcdo (outBCD),
                      .neg (outneg));
    
    Disp_7seg   Disp1(.Pd (Pass),
                      .DP (DP), 
                      .Clk (clk), 
                      .SSC (SSC), .SSA (SSA));
           
    assign                   {outBCD_disp[0], outBCD_disp[1], outBCD_disp[2],
                              outBCD_disp[3], outBCD_disp[4], outBCD_disp[5], 
                              outBCD_disp[6], outBCD_disp[7], outBCD_disp[8], outBCD_disp[9]} = outBCD;         //Unpacks binary to BCD values
    
    assign display_numbers = {{1'b1,disp_seg[0]}, {1'b1,disp_seg[1]}, {1'b1,disp_seg[2]}, 
                              {1'b1,disp_seg[3]}, {1'b1,disp_seg[4]}, {1'b1,disp_seg[5]}, 
                              {1'b1,disp_seg[6]}, {1'b1,disp_seg[7]}, {1'b1,disp_seg[8]}, {1'b1,disp_seg[9]}};                          
    assign sign = {equ, neg};
    assign Pass = {display_numbers, neg_sign, equals_sign, 5'b00000, 5'b00000, 5'b00000, 5'b00000};             //Sends values to display based on case statements on clock
    assign DP = 16'h0000;
    
    always@(posedge clk) begin
        case(display_value)
            2'b00: begin                                    //Displays current BCD Sequence from either a or b
                       disp_seg[0] <= BCD_0;
                       disp_seg[1] <= BCD_1;
                       disp_seg[2] <= BCD_2;
                       disp_seg[3] <= BCD_3;
                       disp_seg[4] <= BCD_4;
                       disp_seg[5] <= BCD_5;
                       disp_seg[6] <= BCD_6;
                       disp_seg[7] <= BCD_7;
                       disp_seg[8] <= BCD_8;
                       disp_seg[9] <= BCD_9;
                   end
            2'b01: begin                                    //Displays calculator BCD output
                       for(i = 0; i < 10; i = i + 1) begin
                           disp_seg[i] <= outBCD_disp[i];
                       end
                   end
        endcase
        
        case(sign)                                          //Changes negative sign and equals sign on display
            2'b00: begin
                   neg_sign = 5'b00000;
                   equals_sign = 5'b00000;
                   end
            2'b01: begin
                   neg_sign = 5'b11010;
                   equals_sign = 5'b00000;
                   end
            2'b10: begin
                   neg_sign = 5'b00000;
                   equals_sign = 5'b11011;
                   end
            2'b11: begin
                   neg_sign = 5'b11010;
                   equals_sign = 5'b11011;
                   end
        endcase
    end
    
    always @(rst) begin     //resets all important values
        a <= 0;
        b <= 0;
        neg <= 0;
        equ <= 0;
        rst2 <= rst;        
        display_value <= 0;
    end
    
    always @(negative) begin
        if(negative != 0) begin
            neg = 1;            //Tells display to show negative sign
        end
    end
    
    always @(function_sel) begin
        if(function_sel != 0) begin
            sel = function_sel;
            a = bin;            //Sets current bcd to binary output to input a
            neg = 0;
            rst2 = 1;           //resets bcd sequence
        end else
            rst2 = 0;           //resets rst2 after letting go of reset button
    end
        
    always @(equals) begin
        if(equals != 0) begin
            equ = 1;            //Tells display to show equals sign
            b = bin;            //Sets current bcd to binary output to input b
					
            display_value = 1;  //Tells display to show Calculator output
        end
    end
    
endmodule


module BCD_Binary(
     input clk,
     input [3:0] BCD_9, BCD_8, BCD_7, BCD_6, BCD_5, BCD_4, BCD_3, BCD_2, BCD_1, BCD_0,
     input neg,
     output reg[31:0] bin
    );
    
    reg[31:0] placeholder[9:0];
    integer i;
    
    always @(posedge clk) begin
        bin = 0;
        placeholder[9] = BCD_9 * 30'd1000000000;    //  Each row multiplies
        placeholder[8] = BCD_8 * 27'd100000000;     //  the BCD value
        placeholder[7] = BCD_7 * 24'd10000000;      //  by the appropriate
        placeholder[6] = BCD_6 * 20'd1000000;       //  power of 10
        placeholder[5] = BCD_5 * 17'd100000;        //  based on what
        placeholder[4] = BCD_4 * 14'd10000;         //  column the BCD
        placeholder[3] = BCD_3 * 10'd1000;          //  was in
        placeholder[2] = BCD_2 *  7'd100;           
        placeholder[1] = BCD_1 *  4'd10;            
        placeholder[0] = {27'h0000000, BCD_0};
    
        for(i = 0; i < 10; i = i + 1) begin     //loop to add all placeholders to binary output
            bin = bin + placeholder[i];
            
            if(neg && i == 9) begin  //Convert number into 2's complement when neg
                bin = ~bin + 1;
            end
        end
    end
endmodule


module Binary_BCD(
    input [31:0] bin_2s,       // 32 bit binary
    output wire[39:0] bcdo,   // 10 digit BCD
    output reg neg          //if the binary value was negative
    );
    reg[41:0] bcd;
    reg[31:0] bin;
    integer i, j;

    always @(bin_2s) begin
        if(bin_2s[31] == 1) begin       //check if number is supposed to be negative
            neg = 1;
            bin = ~bin_2s + 1;
        end
        else begin
            neg = 0;
            bin = bin_2s;
        end
        
        for(i = 0; i <= 41; i = i + 1)
            bcd[i] = 0;                 // initialize with zeros
    
        bcd[31:0] = bin;                                       
    
        for(i = 0; i <= 28; i = i + 1)
            for(j = 0; j <= i/3; j = j+1)
                if (bcd[32-i+4*j -: 4] > 4)                         // if > 4
                    bcd[32-i+4*j -: 4] = bcd[32-i+4*j -: 4] + 4'd3; // add 3
        
    end
    
    assign bcdo = bcd[39:0]; //Truncates bcd to required length for other modules
    
endmodule


module BCD_Sequence(
     input wire clk, rst,
     input wire[3:0] BCD,
     output reg[3:0] BCD_9, BCD_8, BCD_7, BCD_6, BCD_5, BCD_4, BCD_3, BCD_2, BCD_1, BCD_0
    );
    reg[3:0] temp[9:0];
    integer i;
    reg[3:0] d;
    wire[3:0] q;

    dff dff_0(d[0], clk, rst, q[0]);
    dff dff_1(d[1], clk, rst, q[1]);
    dff dff_2(d[2], clk, rst, q[2]);
    dff dff_3(d[3], clk, rst, q[3]);
    
    always @(BCD or rst) begin
        if(~rst) begin
            case(BCD)
                0   :   if(q > 0)
                            temp[q] = BCD;
                        else 
                            d = d - 1;
                1       :   temp[q] = BCD;
                2       :   temp[q] = BCD;
                3       :   temp[q] = BCD;
                4       :   temp[q] = BCD;
                5       :   temp[q] = BCD;
                6       :   temp[q] = BCD;
                7       :   temp[q] = BCD;
                8       :   temp[q] = BCD;
                9       :   temp[q] = BCD;
                default :   d = d - 1;
            endcase
            
            if(q < 10)
                d = d + 1;
            else
                d = d;
            
        end else begin
            for(i = 0; i < 10; i = i + 1) begin
                temp[i] = 4'h0;
								
            end
            
            d = 0;
        end
    end
    
    always @(posedge clk) begin				   
        BCD_0 <= temp[0];
        BCD_1 <= temp[1];
        BCD_2 <= temp[2];
        BCD_3 <= temp[3];
        BCD_4 <= temp[4];
        BCD_5 <= temp[5];
        BCD_6 <= temp[6];
        BCD_7 <= temp[7];
        BCD_8 <= temp[8];
        BCD_9 <= temp[9];
    end
endmodule


module calc_4_func(clk, a, b, sel, out);
    input clk;
    input wire [31:0] a;
    input wire [31:0] b;
    input wire [2:0] sel;
    output reg [31:0] out;
    
    always@(posedge clk) begin
        case(sel)
            3'b001:
                out = a + b;
            3'b010:
                out = a - b;
            3'b011:
                out = a * b;
            3'b100:
                out = a / b;
        endcase
    end
endmodule


module Disp_7seg(
	input     [0:79] Pd,
	input     [15:0] DP,
	input            Clk,
	output    [7:0]  SSC,   //The Segments
	output reg[15:0] SSA);  //The Digit
	
    wire    [4:0] Disp [0:15];
    reg     [3:0] Point;
    reg     [5:0] Point_Plus; 
    wire    [3:0] Digit_to_Show;

    initial begin
        Point <= 4'b0000;
    end
     
    assign {Disp[0], Disp[1], Disp[2], Disp[3],
            Disp[4], Disp[5], Disp[6], Disp[7],
            Disp[8], Disp[9], Disp[10],Disp[11],
            Disp[12],Disp[13],Disp[14],Disp[15]}= Pd;  //Unpack, cant put 2-d array in port 
    //assign Segments = SSC;  
    
    always @(posedge Clk) begin  //This increments the displayed digit
        Point <= Point + 4'b0001;
    end
    
    assign Digit_to_Show = Disp[Point][3:0];
    
    Hex_Dig Inst1 (Digit_to_Show, SSC, DP[Point]);
    
    always @* begin
        Point_Plus = {Disp[Point][4], Point};  //Adds the bit that selects for display or not
        case (Point_Plus)   
            5'b10000:SSA = ~(16'b0000000000000001);  //Note:  to lite digit, anode must = 0    
            5'b10001:SSA = ~(16'b0000000000000010);  //Display digit if lead bit is 1 else blank
            5'b10010:SSA = ~(16'b0000000000000100);
            5'b10011:SSA = ~(16'b0000000000001000);
            5'b10100:SSA = ~(16'b0000000000010000);
            5'b10101:SSA = ~(16'b0000000000100000);
            5'b10110:SSA = ~(16'b0000000001000000);
            5'b10111:SSA = ~(16'b0000000010000000);
            5'b11000:SSA = ~(16'b0000000100000000);
            5'b11001:SSA = ~(16'b0000001000000000);
            5'b11010:SSA = ~(16'b0000010000000000);
            5'b11011:SSA = ~(16'b0000100000000000);   
            5'b11100:SSA = ~(16'b0001000000000000);
            5'b11101:SSA = ~(16'b0010000000000000);
            5'b11110:SSA = ~(16'b0100000000000000);
            5'b11111:SSA = ~(16'b1000000000000000);
            default:SSA  = ~(16'b0000000000000000);
        endcase   
    end
endmodule         
          
          
module Hex_Dig (        //This module looks up the seven seg settings for each Hex digit
        input [3:0] Value,
        output reg [7:0] SS,
        input Decimal_Point);
        
        always @* begin
        case (Value) 
             4'h0:  SS[6:0] = ~(7'b0111111);    //Note:  to lite digit, cathode must = 0   
             4'h1:  SS[6:0] = ~(7'b0000110);    //Dummy blank decimal points are included
             4'h2:  SS[6:0] = ~(7'b1011011);   
             4'h3:  SS[6:0] = ~(7'b1001111);   
             4'h4:  SS[6:0] = ~(7'b1100110);   
             4'h5:  SS[6:0] = ~(7'b1101101);   
             4'h6:  SS[6:0] = ~(7'b1111101);   
             4'h7:  SS[6:0] = ~(7'b0000111);   
             4'h8:  SS[6:0] = ~(7'b1111111);   
             4'h9:  SS[6:0] = ~(7'b1100111);   //A through F for special cases
             4'hA:  SS[6:0] = ~(7'b1000000);   //A is minus sign
             4'hB:  SS[6:0] = ~(7'b1000001);   //B is equals sign
             4'hC:  SS[6:0] = ~(7'b0000000);   
             4'hD:  SS[6:0] = ~(7'b0000000);   
             4'hE:  SS[6:0] = ~(7'b0000000);   
             4'hF:  SS[6:0] = ~(7'b0000000);
          default:  SS[6:0] = ~(7'b0000000);
        endcase
        SS[7] = ~Decimal_Point;   
           end
endmodule


module dff(d, clk, rst, q); 
    input d, clk, rst; 
    output reg q; 
    
        always@(posedge clk or posedge rst) begin
            if(rst == 1)
                q <= 0;
            else 
                q <= d;
        end 
endmodule