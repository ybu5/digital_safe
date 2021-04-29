// ELEX 7660 ELEX 7660 201710 Lab2 
//a decode for active low 7 segments
// Yanming Bu 2021-01
module decode7 (input logic [3:0] num,
		output logic [7:0] leds);
	always_comb
		//check all the case for the input num
		//turn on the active low bit accordingly  
		case(num)
			0 : leds = 8'b11000000;
			1 : leds = 8'b11111001;
			2 : leds = 8'b10100100;
			3 : leds = 8'b10110000;
			4 : leds = 8'b10011001;
			5 : leds = 8'b10010010;
			6 : leds = 8'b10000010;
			7 : leds = 8'b11111000;
			8 : leds = 8'b10000000;
			9 : leds = 8'b10010000;
			4'ha: leds = 8'b10001000;
			4'hb: leds = 8'b10000011;
			4'hc: leds = 8'b11000110;
			4'hd: leds = 8'b10100001;
			4'he: leds = 8'b10000110;
			4'hf: leds = 8'b10001110; 
		endcase
endmodule 
