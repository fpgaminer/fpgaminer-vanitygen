/*
*
* Copyright (c) 2013 fpgaminer@bitcoin-mining.com
*
*
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

`define IDX(x) (((x)+1)*(32)-1):((x)*(32))

/* Sorry if this code is ugly. Go have a look at the RIPEMD-160 specification
* and you'll understand my pain.
*/
module ripemd160 (
	input clk,
	input rx_reset,
	input [255:0] rx_hash,
	output reg tx_done = 1'b0,
	output reg [159:0] tx_hash = 160'd0
);

	//
	reg [511:0] block;
	reg [31:0] A, B, C, D, E, AA, BB, CC, DD, EE;
	reg [6:0] round;

	// K constants
	wire [31:0] k0, k1;

	ripemd160_k_constant k_constant_blk (
		.clk (clk),
		.rx_round (rx_reset ? 7'd0 : round),
		.tx_k0 (k0),
		.tx_k1 (k1)
	);

	// Rotation amounts
	wire [3:0] first_rotate, second_rotate;

	ripemd160_rol_s rol_s_blk (
		.clk (clk),
		.rx_round (rx_reset ? 7'd0 : (round + 7'd1)),
		.tx_s0 (first_rotate),
		.tx_s1 (second_rotate)
	);

	// Message word selection
	wire [3:0] first_word, second_word;

	ripemd160_word_sel word_sel_blk (
		.clk (clk),
		.rx_round (rx_reset ? 7'd0 : (round + 7'd1)),
		.tx_s0 (first_word),
		.tx_s1 (second_word)
	);

	// Non-linear functions
	wire [31:0] nl_0, nl_1;
	ripemd160_nonlinear nonlinear_0 (round, B, C, D, nl_0);
	ripemd160_nonlinear nonlinear_1 (7'd79 - round, BB, CC, DD, nl_1);

	// Select words
	wire [31:0] x_0 = block >> {first_word, 5'd0};
	wire [31:0] x_1 = block >> {second_word, 5'd0};

	// Big calculations
	wire [31:0] partial_T = A + nl_0 + x_0 + k0;
	wire [31:0] partial_TT = AA + nl_1 + x_1 + k1;

	// Rotations
	wire [31:0] rotated_T, rotated_TT;

	ripemd160_rol first_rol_blk (first_rotate, partial_T, rotated_T);
	ripemd160_rol second_rol_blk (second_rotate, partial_TT, rotated_TT);


	always @ (posedge clk)
	begin
		A <= E;
		B <= rotated_T + E;
		C <= B;
		D <= {C[21:0], C[31:22]};
		E <= D;

		AA <= EE;
		BB <= rotated_TT + EE;
		CC <= BB;
		DD <= {CC[21:0], CC[31:22]};
		EE <= DD;

		round <= round + 7'd1;

		if (round == 80 && !tx_done)
		begin
			tx_done <= 1'b1;
			/*{tx_hash[31:24],tx_hash[23:16],tx_hash[15:8],tx_hash[7:0]} <= 32'hEFCDAB89 + C + DD;
			{tx_hash[63:56],tx_hash[55:48],tx_hash[47:40],tx_hash[39:32]} <= 32'h98BADCFE + D + EE;
			{tx_hash[95:88],tx_hash[87:80],tx_hash[79:72],tx_hash[71:64]} <= 32'h10325476 + E + AA;
			{tx_hash[127:120],tx_hash[119:112],tx_hash[111:104],tx_hash[103:96]} <= 32'hC3D2E1F0 + A + BB;
			{tx_hash[159:152],tx_hash[151:144],tx_hash[143:136],tx_hash[135:128]} <= 32'h67452301 + B + CC;*/
			{tx_hash[135:128],tx_hash[143:136],tx_hash[151:144],tx_hash[159:152]} <= 32'hEFCDAB89 + C + DD;
			{tx_hash[103:96],tx_hash[111:104],tx_hash[119:112],tx_hash[127:120]} <= 32'h98BADCFE + D + EE;
			{tx_hash[71:64],tx_hash[79:72],tx_hash[87:80],tx_hash[95:88]} <= 32'h10325476 + E + AA;
			{tx_hash[39:32],tx_hash[47:40],tx_hash[55:48],tx_hash[63:56]} <= 32'hC3D2E1F0 + A + BB;
			{tx_hash[7:0],tx_hash[15:8],tx_hash[23:16],tx_hash[31:24]} <= 32'h67452301 + B + CC;
		end

		if (rx_reset)
		begin
			{E, D, C, B, A} <= 160'hC3D2E1F01032547698BADCFEEFCDAB8967452301;
			{EE, DD, CC, BB, AA} <= 160'hC3D2E1F01032547698BADCFEEFCDAB8967452301;
			tx_done <= 1'b0;
			round <= 0;

			block[`IDX(0)] <= {rx_hash[231:224],rx_hash[239:232],rx_hash[247:240],rx_hash[255:248]};
			block[`IDX(1)] <= {rx_hash[199:192],rx_hash[207:200],rx_hash[215:208],rx_hash[223:216]};
			block[`IDX(2)] <= {rx_hash[167:160],rx_hash[175:168],rx_hash[183:176],rx_hash[191:184]};
			block[`IDX(3)] <= {rx_hash[135:128],rx_hash[143:136],rx_hash[151:144],rx_hash[159:152]};
			block[`IDX(4)] <= {rx_hash[103:96],rx_hash[111:104],rx_hash[119:112],rx_hash[127:120]};
			block[`IDX(5)] <= {rx_hash[71:64],rx_hash[79:72],rx_hash[87:80],rx_hash[95:88]};
			block[`IDX(6)] <= {rx_hash[39:32],rx_hash[47:40],rx_hash[55:48],rx_hash[63:56]};
			block[`IDX(7)] <= {rx_hash[7:0],rx_hash[15:8],rx_hash[23:16],rx_hash[31:24]};
			block[`IDX(8)] <= 32'h00000080;
			block[`IDX(9)] <= 32'h00000000;
			block[`IDX(10)] <= 32'h00000000;
			block[`IDX(11)] <= 32'h00000000;
			block[`IDX(12)] <= 32'h00000000;
			block[`IDX(13)] <= 32'h00000000;
			block[`IDX(14)] <= 32'h00000100;  // Message length
			block[`IDX(15)] <= 32'h00000000;
		end
	end

endmodule


module ripemd160_k_constant (
	input clk,
	input [6:0] rx_round,
	output reg [31:0] tx_k0 = 32'h0,
	output reg [31:0] tx_k1 = 32'h0
);

	always @ (posedge clk)
	begin
		// These are less than, instead of less-than-or-equal-to,
		// because we're calculating K for the next round.
		if (rx_round < 15)
			{tx_k1, tx_k0} <= {32'h50A28BE6, 32'h00000000};
		else if (rx_round < 31)
			{tx_k1, tx_k0} <= {32'h5C4DD124, 32'h5A827999};
		else if (rx_round < 47)
			{tx_k1, tx_k0} <= {32'h6D703EF3, 32'h6ED9EBA1};
		else if (rx_round < 63)
			{tx_k1, tx_k0} <= {32'h7A6D76E9, 32'h8F1BBCDC};
		else
			{tx_k1, tx_k0} <= {32'h00000000, 32'hA953FD4E};
	end

endmodule


module ripemd160_nonlinear (
	input [6:0] rx_round,
	input [31:0] rx_x,
	input [31:0] rx_y,
	input [31:0] rx_z,
	output reg [31:0] tx_f
);

	always @ (*)
	begin
		if (rx_round <= 15)
			tx_f = rx_x ^ rx_y ^ rx_z;
		else if (rx_round <= 31)
			tx_f = (rx_x & rx_y) | ((~rx_x) & rx_z);
		else if (rx_round <= 47)
			tx_f = (rx_x | (~rx_y)) ^ rx_z;
		else if (rx_round <= 63)
			tx_f = (rx_x & rx_z) | (rx_y & (~rx_z));
		else
			tx_f = rx_x ^ (rx_y | (~rx_z));
	end

endmodule


module ripemd160_rol (
	input [3:0] rx_s,
	input [31:0] rx_x,
	output [31:0] tx_x
);

	assign tx_x = (rx_x << rx_s) | (rx_x >> (32 - rx_s));

endmodule


// amount for rotate left
module ripemd160_rol_s (
	input clk,
	input [6:0] rx_round,
	output reg [3:0] tx_s0,
	output reg [3:0] tx_s1
);

	localparam [319:0] first_sequence = {4'd6,4'd5,4'd8,4'd11,4'd14,4'd13,4'd12,4'd5,4'd12,4'd13,4'd8,4'd6,4'd11,4'd5,4'd15,4'd9,4'd12,4'd5,4'd6,4'd8,4'd6,4'd5,4'd14,4'd9,4'd8,4'd9,4'd15,4'd14,4'd15,4'd14,4'd12,4'd11,4'd5,4'd7,4'd12,4'd5,4'd6,4'd13,4'd8,4'd14,4'd15,4'd13,4'd9,4'd14,4'd7,4'd6,4'd13,4'd11,4'd12,4'd13,4'd7,4'd11,4'd9,4'd15,4'd12,4'd7,4'd15,4'd7,4'd9,4'd11,4'd13,4'd8,4'd6,4'd7,4'd8,4'd9,4'd7,4'd6,4'd15,4'd14,4'd13,4'd11,4'd9,4'd7,4'd8,4'd5,4'd12,4'd15,4'd14,4'd11};
	localparam [319:0] second_sequence = {4'd11,4'd11,4'd13,4'd15,4'd5,4'd6,4'd13,4'd8,4'd6,4'd14,4'd5,4'd12,4'd9,4'd12,4'd5,4'd8,4'd8,4'd15,4'd5,4'd12,4'd9,4'd12,4'd9,4'd6,4'd14,4'd6,4'd14,4'd14,4'd11,4'd8,4'd5,4'd15,4'd5,4'd7,4'd13,4'd13,4'd14,4'd5,4'd13,4'd12,4'd14,4'd6,4'd6,4'd8,4'd11,4'd15,4'd7,4'd9,4'd11,4'd13,4'd15,4'd6,4'd7,4'd12,4'd7,4'd7,4'd11,4'd9,4'd8,4'd12,4'd7,4'd15,4'd13,4'd9,4'd6,4'd12,4'd14,4'd14,4'd11,4'd8,4'd7,4'd7,4'd5,4'd15,4'd15,4'd13,4'd11,4'd9,4'd9,4'd8};


	always @ (posedge clk)
	begin
		tx_s0 <= first_sequence >> {rx_round, 2'b00};
		tx_s1 <= second_sequence >> {rx_round, 2'b00};
	end

endmodule


module ripemd160_word_sel (
	input clk,
	input [6:0] rx_round,
	output reg [3:0] tx_s0,
	output reg [3:0] tx_s1
);

	localparam [319:0] first_sequence = {4'd13,4'd15,4'd6,4'd11,4'd8,4'd3,4'd1,4'd14,4'd10,4'd2,4'd12,4'd7,4'd9,4'd5,4'd0,4'd4,4'd2,4'd6,4'd5,4'd14,4'd15,4'd7,4'd3,4'd13,4'd4,4'd12,4'd8,4'd0,4'd10,4'd11,4'd9,4'd1,4'd12,4'd5,4'd11,4'd13,4'd6,4'd0,4'd7,4'd2,4'd1,4'd8,4'd15,4'd9,4'd4,4'd14,4'd10,4'd3,4'd8,4'd11,4'd14,4'd2,4'd5,4'd9,4'd0,4'd12,4'd3,4'd15,4'd6,4'd10,4'd1,4'd13,4'd4,4'd7,4'd15,4'd14,4'd13,4'd12,4'd11,4'd10,4'd9,4'd8,4'd7,4'd6,4'd5,4'd4,4'd3,4'd2,4'd1,4'd0};
	localparam [319:0] second_sequence = {4'd11,4'd9,4'd3,4'd0,4'd14,4'd13,4'd2,4'd6,4'd7,4'd8,4'd5,4'd1,4'd4,4'd10,4'd15,4'd12,4'd14,4'd10,4'd7,4'd9,4'd13,4'd2,4'd12,4'd5,4'd0,4'd15,4'd11,4'd3,4'd1,4'd4,4'd6,4'd8,4'd13,4'd4,4'd0,4'd10,4'd2,4'd12,4'd8,4'd11,4'd9,4'd6,4'd14,4'd7,4'd3,4'd1,4'd5,4'd15,4'd2,4'd1,4'd9,4'd4,4'd12,4'd8,4'd15,4'd14,4'd10,4'd5,4'd13,4'd0,4'd7,4'd3,4'd11,4'd6,4'd12,4'd3,4'd10,4'd1,4'd8,4'd15,4'd6,4'd13,4'd4,4'd11,4'd2,4'd9,4'd0,4'd7,4'd14,4'd5};

	
	always @ (posedge clk)
	begin
		tx_s0 <= first_sequence >> {rx_round, 2'b00};
		tx_s1 <= second_sequence >> {rx_round, 2'b00};
	end

endmodule
