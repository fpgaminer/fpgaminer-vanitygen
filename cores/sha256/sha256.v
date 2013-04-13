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


// Expects a compressed public key, which is 33 bytes.
module sha256 (
	input clk,
	input rx_reset,
	input [263:0] rx_public_key,
	output reg tx_done = 1'b0,
	output reg [255:0] tx_hash = 256'd0
);

	// Constants
	wire [247:0] padding = {8'h80, 176'h00, 64'h0000000000000108};

	reg [511:0] w;
	reg [255:0] state;
	reg [6:0] k_addr;

	// K constants
	wire [31:0] k_const;

	k_const_rom rom_blk (
		.clk (clk),
		.rx_address (k_addr[5:0]),
		.tx_k (k_const)
	);

	// W update
	wire [31:0] s0_w, s1_w, e0_w, e1_w, ch_w, maj_w;
	
	s0  s0_blk  (w[`IDX(1)], s0_w);
	s1  s1_blk  (w[`IDX(14)], s1_w);
	e0  e0_blk  (state[`IDX(0)], e0_w);
	e1  e1_blk  (state[`IDX(4)], e1_w);
	ch  ch_blk  (state[`IDX(4)], state[`IDX(5)], state[`IDX(6)], ch_w);
	maj maj_blk (state[`IDX(0)], state[`IDX(1)], state[`IDX(2)], maj_w);

	wire [31:0] t1 = state[`IDX(7)] + e1_w + ch_w + w[31:0] + k_const;
	wire [31:0] t2 = e0_w + maj_w;

	
	always @ (posedge clk)
	begin
		// W update
		w[`IDX(15)] <= w[`IDX(0)] + w[`IDX(9)] + s0_w + s1_w;
		w[479:0] <= w[511:32];

		// State update
		state[`IDX(7)] <= state[`IDX(6)];
		state[`IDX(6)] <= state[`IDX(5)];
		state[`IDX(5)] <= state[`IDX(4)];
		state[`IDX(4)] <= state[`IDX(3)] + t1;
		state[`IDX(3)] <= state[`IDX(2)];
		state[`IDX(2)] <= state[`IDX(1)];
		state[`IDX(1)] <= state[`IDX(0)];
		state[`IDX(0)] <= t1 + t2;

		if (k_addr < 64)
			k_addr <= k_addr + 7'd1;

		if (k_addr == 64 && !tx_done)
		begin
			tx_hash[`IDX(7)] <= 32'h6a09e667 + state[`IDX(0)];
			tx_hash[`IDX(6)] <= 32'hbb67ae85 + state[`IDX(1)];
			tx_hash[`IDX(5)] <= 32'h3c6ef372 + state[`IDX(2)];
			tx_hash[`IDX(4)] <= 32'ha54ff53a + state[`IDX(3)];
			tx_hash[`IDX(3)] <= 32'h510e527f + state[`IDX(4)];
			tx_hash[`IDX(2)] <= 32'h9b05688c + state[`IDX(5)];
			tx_hash[`IDX(1)] <= 32'h1f83d9ab + state[`IDX(6)];
			tx_hash[`IDX(0)] <= 32'h5be0cd19 + state[`IDX(7)];
			tx_done <= 1'b1;
		end

		if (rx_reset)
		begin
			tx_done <= 1'b0;
			state <= 256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667;
			k_addr <= 0;
			w[`IDX(0)] <= rx_public_key[263:232];
			w[`IDX(1)] <= rx_public_key[231:200];
			w[`IDX(2)] <= rx_public_key[199:168];
			w[`IDX(3)] <= rx_public_key[167:136];
			w[`IDX(4)] <= rx_public_key[135:104];
			w[`IDX(5)] <= rx_public_key[103:72];
			w[`IDX(6)] <= rx_public_key[71:40];
			w[`IDX(7)] <= rx_public_key[39:8];
			w[`IDX(8)] <= {rx_public_key[7:0], padding[247:224]};
			w[`IDX(9)] <= padding[223:192];
			w[`IDX(10)] <= padding[191:160];
			w[`IDX(11)] <= padding[159:128];
			w[`IDX(12)] <= padding[127:96];
			w[`IDX(13)] <= padding[95:64];
			w[`IDX(14)] <= padding[63:32];
			w[`IDX(15)] <= padding[31:0];
		end
	end

endmodule


module k_const_rom (
	input clk,
	input [5:0] rx_address,
	output [31:0] tx_k
);

	localparam Ks = {
		32'hC67178F2, 32'hBEF9A3F7, 32'hA4506CEB, 32'h90BEFFFA,
		32'h8CC70208, 32'h84C87814, 32'h78A5636F, 32'h748F82EE,
		32'h682E6FF3, 32'h5B9CCA4F, 32'h4ED8AA4A, 32'h391C0CB3,
		32'h34B0BCB5, 32'h2748774C, 32'h1E376C08, 32'h19A4C116,
		32'h106AA070, 32'hF40E3585, 32'hD6990624, 32'hD192E819,
		32'hC76C51A3, 32'hC24B8B70, 32'hA81A664B, 32'hA2BFE8A1,
		32'h92722C85, 32'h81C2C92E, 32'h766A0ABB, 32'h650A7354,
		32'h53380D13, 32'h4D2C6DFC, 32'h2E1B2138, 32'h27B70A85,
		32'h14292967, 32'h06CA6351, 32'hD5A79147, 32'hC6E00BF3,
		32'hBF597FC7, 32'hB00327C8, 32'hA831C66D, 32'h983E5152,
		32'h76F988DA, 32'h5CB0A9DC, 32'h4A7484AA, 32'h2DE92C6F,
		32'h240CA1CC, 32'h0FC19DC6, 32'hEFBE4786, 32'hE49B69C1,
		32'hC19BF174, 32'h9BDC06A7, 32'h80DEB1FE, 32'h72BE5D74,
		32'h550C7DC3, 32'h243185BE, 32'h12835B01, 32'hD807AA98,
		32'hAB1C5ED5, 32'h923F82A4, 32'h59F111F1, 32'h3956C25B,
		32'hE9B5DBA5, 32'hB5C0FBCF, 32'h71374491, 32'h428A2F98};

	assign tx_k = Ks >> {rx_address, 5'd0};

	/*altsyncram # (
		.address_aclr_a ("NONE"),
		.clock_enable_input_a ("BYPASS"),
		.clock_enable_output_a ("BYPASS"),
		.init_file ("k_const.mif"),
		.intended_device_family ("Cyclone III"),
		.lpm_hint ("ENABLE_RUNTIME_MOD=NO"),
		.lpm_type ("altsyncram"),
		.numwords_a (64),
		.operation_mode ("ROM"),
		.outdata_aclr_a ("NONE"),
		.outdata_reg_a ("CLOCK0"),
		.widthad_a (6),
		.width_a (32),
		.width_byteena_a (1)
	) rom_blk (
		.clock0 (clk),
		.address_a (rx_address),
		.q_a (tx_k),
		.aclr0 (1'b0),
		.aclr1 (1'b0),
		.address_b (1'b1),
		.addressstall_a (1'b0),
		.addressstall_b (1'b0),
		.byteena_a (1'b1),
		.byteena_b (1'b1),
		.clock1 (1'b1),
		.clocken0 (1'b1),
		.clocken1 (1'b1),
		.clocken2 (1'b1),
		.clocken3 (1'b1),
		.data_a ({32{1'b1}}),
		.data_b (1'b1),
		.eccstatus (),
		.q_b (),
		.rden_a (1'b1),
		.rden_b (1'b1),
		.wren_a (1'b0),
		.wren_b (1'b0)
	);*/

endmodule
